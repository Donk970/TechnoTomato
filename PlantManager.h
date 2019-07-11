
#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_ADS1015.h>

#ifndef _PLANT_MANAGER_H_
#define _PLANT_MANAGER_H_



//------------------------------------------------------------------------------
//--------        CONSTANTS     ------------------------------------------------
//------------------------------------------------------------------------------
const unsigned long k_thirty_minutes = 1800000;
const unsigned long k_fifteen_minutes = 900000;
const unsigned long k_ten_minutes = 600000;
const unsigned long k_five_minutes = 300000;
const unsigned long k_three_minutes = 180000;
const unsigned long k_two_minutes = 120000;
const unsigned long k_one_minute = 60000;
const unsigned long k_thirty_seconds = 30000;
const unsigned long k_twenty_seconds = 20000;
const unsigned long k_fifteen_seconds = 15000;
const unsigned long k_ten_seconds = 10000;
const unsigned long k_five_seconds = 5000;
const unsigned long k_three_seconds = 3000;
const unsigned long k_one_second = 1000;
const unsigned long k_half_second = 500;

// the range of values over which a leaf goes from
// fully hydrated to wilted.  low values can range from
// 2200 to 2280 or so.


//------------------------------------------------------------------------------
typedef double TimeValue;

class Plant;
typedef  void (Plant::*PlantStateFN)(void);
const int k_leafSensorMaxValues = 10;

const unsigned long k_valve_open_duration = 250;  // our default spay duration is one 250 ms 

struct LeafSensorBoundingValues {
    double sensorOffset = 0;
    double lowValue = 0;
    double highValue = 0;
};  


class SensorReading {
  public: 
    double value = 0;
    void appendReading(double reading);
    void resetReading(void);
    void clearReading(void);

  private:
    unsigned long _dt = 0;
    double _average = 0;
    double _count = 0;
};


class Plant {
  public:
    Plant( int adc_index ) { _adc_index = adc_index; }
    void initialize();    
    void perform();
    void setAmbientTemperature(double t);
    
    Adafruit_ADS1115 *_ads; // manager will set this up and pass it in during init
    uint8_t _valvePin;

    // running values calculated every 0.1 seconds
    LeafSensorBoundingValues bounds;

    // calculated every 10 seconds
    double leafRawSensorValue = 0;
    double leafSensorValue = 0;
    double leafSensorDeviation = 0;
    bool sprayTriggered = false;
    int sprayTriggeredCount = 0;
    bool calibrateButtonPressed = false;
     
    TimeValue defaultSprayInterval = 60.0; // interval measured in seconds
  
  private:
    int _adc_index;
    SensorReading _leafSensorReading;
    unsigned long _iterationCounter = 0;
    
    unsigned long _dt;
    unsigned long _sample_delay;

    
    
    
    
    

    /************************************************************************************************************
     ************************************************************************************************************
     *
     *  SENSOR FUNCTIONS
     *
     ************************************************************************************************************
     ************************************************************************************************************/
    void _appendValue( double value );
    double _readRawLeafSensor();
    double _readCalibratedLeafSensor();
    double _currentDeviation();
    void _testLeafThickness(void);
    bool _isSensorConnected();
    
    
    /************************************************************************************************************
     ************************************************************************************************************
     *
     *  PLANT FUNCTIONS
     *
     ************************************************************************************************************
     ************************************************************************************************************/
    void handleButtonPress(void);


    unsigned long _nextReadingTime = 0; //this is the next time to store an average of measurements
    unsigned long _nextEEPROMWrite = 0;
    bool _eepromNeedsWrite = false;
    void synchronizeEEPROM();
    void initializeBoundaryValues();
    void loadBoundaryValues();
    void storeBoundaryValues(bool imediate);
    
    
    
    /************************************************************************************************************
     ************************************************************************************************************
     *
     *  VALVE TIMING FUNCTIONS
     *
     ************************************************************************************************************
     ************************************************************************************************************/
    unsigned long _next_default_spray;
    double _defaultSprayIntervalAdjustment = 1.0; // number between 0 and 1 that is multiplied by defaultSprayInterval
    unsigned long _valveCloseTime;
    bool _attemptDefaultSpray();
    void _openValve(unsigned long duration = k_valve_open_duration);
    void _tryCloseValve();
    void _closeValve();
    
    
    
    /************************************************************************************************************
     ************************************************************************************************************
     *
     *  PLANT STATE FUNCTIONS
     *
     ************************************************************************************************************
     ************************************************************************************************************/
    void updateIntervalAdjustment();
    void calibrateLeaf(void);
    void normalHydrationState(void);
    
    PlantStateFN _state;
    PlantStateFN _default_state = NULL;  //&Plant::dynamicTimedSpray;
    void delay(unsigned long duration, PlantStateFN nextState);
    void waitDelay(void);
    
};





class PlantManager {
  public:
    PlantManager(const int callibratePin, const uint8_t valvePins[4]);
    void initialize(Adafruit_ADS1115 *ads);
    void perform();
    void setAmbientTemperature(double t);
    void updateSensorValues( double values[4], int triggers[4] );

  private:
    Adafruit_ADS1115 *_ads;
    Plant _plants[4] = {Plant(0), Plant(1), Plant(2), Plant(3)};
    
    bool _callibrateButtonClicked();
    int _callibrateButtonPin = 0;
    bool _callibrateButtonDown = false;
};











#endif
