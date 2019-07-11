
#include "PlantManager.h"
#include "Arduino.h"
#include <EEPROM.h>


#define LOGGING 0



const double k_leaf_sensor_dv = 0.125; //mV


// we want to calibrate sensor when not on a leaf and then
// set the value where we say sensor is not connected at something
// less than that
const double k_sensor_normal_range = 30; // maximum of 30 mv between typical high and low readings
const double k_disconnected_sensor_value = 2290; //mV
const double k_sensor_target_calibration_value = 2300; //mV
const unsigned long k_minute_to_milliseconds = 60000;
const unsigned long k_second_to_milliseconds = 1000;

const double k_no_value = 1000000;

// return a time in seconds for a spray interval as a function
// of time
TimeValue linearTemperatureToTimeFunction(double t) {
    // this function is used to produce a max spray interval in minutes that 
    // is a function of the ambient air temperature.  As the temperature 
    // increases the max spray interval decreases linearely.
    // at t = 45c (113f) v = 0
    // at t = 21c (70f) v = 15
    double v = 0.5 - ((t - 46.0)/1.6);
    
    // pin value between zero and thirty minutes
    if( v < 0 ) { v = 0; }
    else if( v > 30.0 ) { v = 30.0; }
    
    // convert value to seconds and return
    return v * 60.0;
}

TimeValue sqrtTemperatureToTimeFunction(double temp) {
    // this function is used to produce a max spray interval in minutes that 
    // is a function of the ambient air temperature.  As the temperature 
    // increases the max spray interval decreases linearely.
    // pin temp between 20 ℃ and 37 ℃
    double t = temp;
    if( t > 37 ) { t = 37; }
    if( t < 20 ) { t = 20; }
    
    // gives a non linear output between ~30 at 20 ℃ and ~0 at 37 ℃
    double v = 45 * sqrt(1 - (t/37));
    
    // pin output value between zero and thirty minutes
    if( v < 0 ) { v = 0; }
    else if( v > 30.0 ) { v = 30.0; }
    
    // convert value to seconds and return
    return v * 60.0;
}

double scaleFactor( double v ) {
    // v is a fraction ranging from 0 to 1, where 0 is a fully hydrated leaf, 
    // and 1 is completely dehydrated.
    double res = 1.0 - v;

    //pin result between zero and one
    if( res < 0 ) { return 0; }
    else if( res > 1 ) { return 1; }
    return res;
}

// return a time value in seconds
TimeValue defaultInterval( TimeValue i, double a ) {
    TimeValue interval = i * a;
    if( interval > 1800 ) { interval = 1800; } // make sure we don't go longer than thirty minutes (in seconds)
    if( interval < 60 ) { interval = 60; } // less than one minute is overkill
    return interval;
}

unsigned long defaultIntervalMillis( TimeValue i, double a ) {
    TimeValue t = defaultInterval(i, a);
    return ((unsigned long)(t * 1000)); //convert seconds to milliseconds
}




/************************************************************************************************************
 ************************************************************************************************************
 *
 *  PLANT PUBLIC FUNCTIONS
 *
 ************************************************************************************************************
 ************************************************************************************************************/
void Plant:: initialize() {
#if LOGGING
    if( _adc_index == 0 ) { Serial.println("initialize"); }
#endif
    pinMode(_valvePin, OUTPUT);
    _closeValve();
    _next_default_spray = 0;
    
    // get the calibration data from EEPROM
    loadBoundaryValues();    
    _iterationCounter = 0;
    _state = &Plant::normalHydrationState;
    _default_state = &Plant::normalHydrationState;
}

void Plant:: initializeBoundaryValues() {
#if LOGGING
    if( _adc_index == 0 ) { Serial.println("    initializeBoundaryValues"); }
#endif
    bounds.sensorOffset = 0;
    bounds.lowValue = k_no_value; 
    bounds.highValue = 0;
}

void Plant:: loadBoundaryValues() {
    int addr = sizeof(bounds) * _adc_index;
    EEPROM.get(addr, bounds);
}

void Plant:: storeBoundaryValues(bool imediate) {
    _eepromNeedsWrite = true;        
    if( imediate ) {
        _nextEEPROMWrite = 0; //force a write on next call to synchronizeEEPROM
    }
}

void Plant:: synchronizeEEPROM() {
    if( _eepromNeedsWrite && (millis() > _nextEEPROMWrite)) {
        int addr = sizeof(bounds) * _adc_index;
        EEPROM.put(addr, bounds);
        _nextEEPROMWrite = millis() + 14400000; //regular writes no more than every four hours
        _eepromNeedsWrite = false;
    }
}

void Plant:: setAmbientTemperature(double t) {
    defaultSprayInterval = linearTemperatureToTimeFunction(t);
}






/************************************************************************************************************
 ************************************************************************************************************
 *
 *  MAIN LOOP
 *
 ************************************************************************************************************
 ************************************************************************************************************/
void Plant:: perform() {    
    //this takes a reading every 10ms no matter what
    this->_testLeafThickness();

    if( this->_state == NULL ) {
        _state = &Plant::normalHydrationState;
        _default_state = &Plant::normalHydrationState;
    }
    
    handleButtonPress(); // do this before executing state function
    (this->*_state)();
    
    //having this here guarantees that the default interval will be executed
    _attemptDefaultSpray();
    _tryCloseValve(); // we keep trying this until valve duration is exceeded
    synchronizeEEPROM();
}


void Plant:: handleButtonPress(void) {
    // button pressed is true after a button click (pressed and released)
    if( calibrateButtonPressed ) {
        calibrateButtonPressed = false; // reset this
        _iterationCounter = 0;
        
        // reset all the stored values and then go straight to calibrate leaf
        if( _isSensorConnected() ) {
            _leafSensorReading.clearReading();
            initializeBoundaryValues();
            delay(k_one_minute, &Plant::calibrateLeaf);
        }
    }
}






/************************************************************************************************************
 ************************************************************************************************************
 *
 *  PLANT SENSOR FUNCTIONS
 *
 ************************************************************************************************************
 ************************************************************************************************************/
void Plant:: _appendValue( double value ) {
    _leafSensorReading.appendReading( value );
    leafRawSensorValue = _leafSensorReading.value;
    leafSensorValue = leafRawSensorValue + bounds.sensorOffset;
    leafSensorDeviation = leafSensorValue - bounds.lowValue;
}


double Plant:: _readRawLeafSensor() {
    int16_t raw = _ads->readADC_SingleEnded(_adc_index);
    return k_leaf_sensor_dv * double(raw);
}


double Plant:: _readCalibratedLeafSensor() {
    double raw = _readRawLeafSensor();
    return raw + bounds.sensorOffset;
}


double Plant:: _currentDeviation() {
    double maxDiff = fabs(bounds.highValue - bounds.lowValue);
    double diff = leafSensorDeviation;
    if( maxDiff > 0.0001 ) {
        // make sure we never divide by zero
        // and pin result between minus one and one
        double d = (diff/maxDiff);
        if( d > 1 ) { return 1; }
        if( d < -1 ) { return -1; }
        return d;
    } 
    return 1.0;
}


void Plant:: _testLeafThickness(void) {
    unsigned long now = millis();
    if( now > _nextReadingTime ) {
        _appendValue( _readRawLeafSensor() );        
        _nextReadingTime = now + 10; // read sensor every 10 milliseconds
    }
}

bool Plant:: _isSensorConnected() {
    // if the sensor isn't connected to the cable or the cable isn't plugged into
    // the controller board the value on this adc channel will be around 500mv
    return leafSensorValue > 1000;
}










/************************************************************************************************************
 ************************************************************************************************************
 *
 *  VALVE TIMING FUNCTIONS
 *
 ************************************************************************************************************
 ************************************************************************************************************/
bool Plant:: _attemptDefaultSpray() {
    if( _next_default_spray == 0 || millis() > _next_default_spray ) {
        // we've exceeded the default spray interval so trigger a spray
        _next_default_spray = millis() + defaultIntervalMillis(defaultSprayInterval, _defaultSprayIntervalAdjustment);
        _openValve();
        return true;
    }
    return false;
}


void Plant:: _openValve(unsigned long duration) {
#if LOGGING
    if( _adc_index == 0 ) { Serial.print(" + "); }
#endif
//    #if defined(__AVR_ATmega2560__)
//        //there's a wierd bug in mega 2560 that reverses digital write 
//        digitalWrite(_valvePin, LOW);
//    #else
        digitalWrite(_valvePin, LOW);
 //   #endif
    sprayTriggeredCount += 1;
    _valveCloseTime = millis() + duration;
}


void Plant:: _tryCloseValve() {
    if( _valveCloseTime > 0 && millis() >= _valveCloseTime ) {
        _valveCloseTime = 0;
        _closeValve();
    }
}



void Plant:: _closeValve() {    
#if LOGGING
    if( _adc_index == 0 ) { Serial.print(" - "); }
#endif
//#if defined(__AVR_ATmega2560__)
//    //there's a wierd bug in mega 2560 that reverses digital write 
//    digitalWrite(_valvePin, HIGH);
//#else
    digitalWrite(_valvePin, HIGH);
//#endif
    
    _next_default_spray = millis() + defaultIntervalMillis(defaultSprayInterval, _defaultSprayIntervalAdjustment);
}








/************************************************************************************************************
 ************************************************************************************************************
 *
 *  PLANT STATE FUNCTIONS
 *
 ************************************************************************************************************
 ************************************************************************************************************/
void Plant:: updateIntervalAdjustment() {
#if LOGGING
    if( _adc_index == 0 ) { Serial.println("                updateIntervalAdjustment"); }
#endif
    // figure the spray interval adjustment
    // the spray cycle works like a heart beat where the spray pulses are delivered
    // independently of anything we do here.  All we do here is up or down 
    // regulate the interval between pulses.
    // current deviation is fraction of (v - low)/(high - low) giving a percentage
    // of the deviation of max deviation
    double p = scaleFactor(_currentDeviation());
    _defaultSprayIntervalAdjustment = p;
    
    // if the current leaf sensor reading is less than the current
    // low value set a new low value.
    double value = _leafSensorReading.value;
    if( _isSensorConnected() && value < bounds.lowValue ) {
        bounds.lowValue = value;
        bounds.highValue = bounds.lowValue + k_sensor_normal_range; // high value starts at 30 mv higher than low value
        storeBoundaryValues(false); 
    }
    
    _leafSensorReading.resetReading();
}

void Plant:: calibrateLeaf(void) {
#if LOGGING
    if( _adc_index == 0 ) { Serial.println("            calibrateLeaf"); }
#endif
    double value = _leafSensorReading.value;
    _leafSensorReading.resetReading();
    if( value < bounds.lowValue ) {
        bounds.lowValue = value;
        bounds.highValue = bounds.lowValue + k_sensor_normal_range; // high value starts at 30 mv higher than low value
        storeBoundaryValues(true); //this is intentional so force a store
    }
    delay(k_one_minute, &Plant::normalHydrationState);
}

void Plant:: normalHydrationState(void) {
#if LOGGING
    if( _adc_index == 0 ) { Serial.println("            normalHydrationState"); }
#endif
    updateIntervalAdjustment();
    delay(k_one_minute, &Plant::normalHydrationState);
}


void Plant:: delay(unsigned long duration, PlantStateFN nextState) {
#if LOGGING
    if( _adc_index == 0 ) { Serial.println("    delay"); }
#endif
    _state = &Plant::waitDelay;
    _default_state = nextState;
    _dt = millis() + duration;
}

void Plant:: waitDelay(void) {
    if( millis() >= _dt ) {
#if LOGGING
        if( _adc_index == 0 ) { Serial.println("        wait delay done"); }
#endif
        // just delaying
        _state = _default_state;
    }
}









/************************************************************************************************************
 ************************************************************************************************************
 *
 *  PLANT MANAGER 
 *
 ************************************************************************************************************
 ************************************************************************************************************/
PlantManager:: PlantManager( const int callibratePin, const uint8_t valvePins[4] ) {
    for( int i = 0; i < 4; i++ ) {
        _plants[i]._valvePin = valvePins[i];
        _callibrateButtonPin = callibratePin;
    }
}


void PlantManager:: initialize(Adafruit_ADS1115 *ads) {
    _ads = ads;
    pinMode(_callibrateButtonPin, INPUT);
    for( int i = 0; i < 4; i++ ) {
        _plants[i]._ads = _ads;
        _plants[i].initialize();
    }
}


bool PlantManager:: _callibrateButtonClicked() {
    int buttonState = digitalRead(_callibrateButtonPin);
    bool buttonDown = (buttonState == HIGH);
    bool rtn = false;
    if( _callibrateButtonDown && !buttonDown ) {
        // button was down but now it's not which means it was clicked
        rtn = true;
    }
    _callibrateButtonDown = buttonDown;
    return rtn;
}


void PlantManager:: perform() {
    bool buttonClicked = _callibrateButtonClicked();
    for( int i = 0; i < 4; i++ ) {
        if( buttonClicked ) {  
            _plants[i].calibrateButtonPressed = true; //latch button state high
        }
        _plants[i].perform();
    }
}

void PlantManager:: setAmbientTemperature(double t) {
    for( int i = 0; i < 4; i++ ) {
        _plants[i].setAmbientTemperature(t);
    }
}

void PlantManager:: updateSensorValues( double values[4], int triggers[4] ) {
    for( int i = 0; i < 4; i++ ) {
        //if( i == 0 ) { Serial.print("v: "); Serial.print(_plants[i].leafSensorValue); Serial.print("  d: "); Serial.println(_plants[i].leafSensorDeviation); }
        if( _plants[i].leafSensorValue > 1000 ) {
            double v = _plants[i].leafSensorDeviation;  // leafSensorValue;
            values[i] = v;
            triggers[i] = _plants[i].sprayTriggeredCount;
        } else {
            values[i] = 0;
            triggers[i] = 0;
        }
        _plants[i].sprayTriggeredCount = 0;
    }
}









/*
 * The SensorReading class
 */

void SensorReading:: appendReading(double reading) {
    _average = ((_average * _count) + reading)/(_count + 1);
    unsigned long now = millis();
    if( now > _dt ) {
        value = _average;
        _count = 1;
        _dt = now + 1000; //update value every second
    }
    _count += 1.0;
}

void SensorReading:: resetReading(void) {
    _count = 1;
}

void SensorReading:: clearReading(void) {
    _average = 0;
    value = 0;
    _count = 0;
    _dt = 0;
}
