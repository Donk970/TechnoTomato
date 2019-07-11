
#ifndef _SENSOR_H_ 
#define _SENSOR_H_ 

#include <Adafruit_Sensor.h>
#include "Adafruit_BME680.h"
//#include "LocalConstants.h"

Adafruit_BME680 bme; // I2C


const int BME680SensorDataArraySize = 10;
int BME680SensorDataArrayCount = 0;
struct _BME680_SENSOR_DATA_ {
  double temperature;
  double humidity;
} BME680SensorDataArray[BME680SensorDataArraySize]; 
_BME680_SENSOR_DATA_ currentBME680SensorData;

bool BME680HasCompleteSensorData() {
  return BME680SensorDataArrayCount == BME680SensorDataArraySize;
}

void enterSensorReading( double temperature, double humidity ) {
  currentBME680SensorData.temperature = temperature;
  currentBME680SensorData.humidity = humidity;
  
  if( BME680SensorDataArrayCount < BME680SensorDataArraySize ) {
    BME680SensorDataArray[BME680SensorDataArrayCount] = currentBME680SensorData;
    BME680SensorDataArrayCount += 1;
  } else {
    // shift all the entries down one
    void *dst = (void*)(BME680SensorDataArray);
    void *src = (void*)(BME680SensorDataArray + 1);
    size_t cnt = sizeof(_BME680_SENSOR_DATA_)*(BME680SensorDataArraySize-1);
    memmove( dst, src, cnt);
    // put current reading at the end
    BME680SensorDataArray[BME680SensorDataArraySize-1] = currentBME680SensorData;
  }
}


double instantaniousTemperature() {
  return currentBME680SensorData.temperature; 
}
double averageTemperature() {
  if( BME680SensorDataArrayCount < 1 ) { return currentBME680SensorData.temperature; }
  double readingSum = 0;
  for( int i = 0; i < BME680SensorDataArrayCount; i++ ) {
    readingSum += BME680SensorDataArray[i].temperature;
  }
  return readingSum/BME680SensorDataArrayCount;
}
double weightedTemperature() {
  return (instantaniousTemperature() + averageTemperature())/2;
}


double instantaniousHumidity() {
  return currentBME680SensorData.humidity; 
}
double averageHumidity() {
  if( BME680SensorDataArrayCount < 1 ) { return currentBME680SensorData.humidity; }
  double readingSum = 0;
  for( int i = 0; i < BME680SensorDataArrayCount; i++ ) {
    readingSum += BME680SensorDataArray[i].humidity;
  }
  return readingSum/BME680SensorDataArrayCount;
}
double weightedHumidity() {
  return (instantaniousHumidity() + averageHumidity())/2;
}


void logValues() {
//  Serial.printf("\n\n--------------------------------------------------\n");
//  for( int i = 0; i < BME680SensorDataArrayCount; i++ ) {
//    Serial.printf("{ temp: %0.1f,  hum: %0.1f }\n", BME680SensorDataArray[i].temperature, BME680SensorDataArray[i].humidity);
//  }
//  Serial.printf("--------------------------------------------------\n\n");
}

#define SEALEVELPRESSURE_HPA (1013.25)



float altitued = 0.0; // pascals
float airQuality;

/*
 * Burn in function and base line data for calculating air quality
 * https://github.com/pimoroni/bme680-python/blob/master/examples/indoor-air-quality.py
 * 
 * average Fort Collins humidity is 53%
 */
//Set the humidity baseline to 40%.
const double hum_baseline = 40.0;

//This sets the balance between humidity and gas reading in the
//calculation of air_quality_score (25:75, humidity:gas)
double hum_weighting = 0.25;


/********************************************************************************
 * 
 * Since we are running this in the context of a task scheduler we will
 * use a state machine to handle asynchronous reading of the BME680 sensor.
 * 
 ********************************************************************************/
const unsigned long sensorReadingInterval = 60000; //one minute intervals
unsigned long nextSensorReadingTime = 0; 
void setNextSensorReadingTime( unsigned long interval = sensorReadingInterval ) {
  unsigned long t = millis() + sensorReadingInterval;
  nextSensorReadingTime = t > nextSensorReadingTime ? t : sensorReadingInterval; //millis can roll over to 0 so check
}

unsigned long finishReadingSensorTime = 0;

// The sensor reading states.
void beginReadingSensor();
void waitForSensor();
void finishReadingSensor();
void idleSensorFunction();
void nilSensorFunction();  //if we failed to init the sensor use this
void (*currentSensorFunction)(void) = nilSensorFunction;


void BME680AirSensorTask();



void initBME680() {
  Serial.println(F("INITIALIZING BME680!"));

  if (!bme.begin()) {
    Serial.println(F("Could not find a valid BME680 sensor, check wiring!"));
    currentSensorFunction = nilSensorFunction;
    return;
  }

  // Set up oversampling and filter initialization
  bme.setTemperatureOversampling(BME680_OS_8X);
  bme.setHumidityOversampling(BME680_OS_2X);
  bme.setPressureOversampling(BME680_OS_4X);
  bme.setIIRFilterSize(BME680_FILTER_SIZE_3);
  bme.setGasHeater(320, 150); // 320*C for 150 ms
  setNextSensorReadingTime( 10000 ); //take first reading in one second
  currentSensorFunction = idleSensorFunction;
  
  Serial.println(F("BME680 INITIALIZED!"));
}

//void BME680AirSensorLoggingTask( JsonObject *json ) {
//  (*json)[MESH_SENSOR_TYPE_KEY] = MESH_SENSOR_TYPE_BME680;
//  (*json)[MESH_VALUE_MEDIUM_KEY] = MESH_VALUE_MEDIUM_AIR;
//  (*json)[MESH_TEMPERATURE_VALUE_KEY] = instantaniousTemperature();
//  (*json)[MESH_AVERAGE_TEMPERATURE_VALUE_KEY] = averageTemperature();
//  (*json)[MESH_HUMIDITY_VALUE_KEY] = instantaniousHumidity();
//  (*json)[MESH_AVERAGE_HUMIDITY_VALUE_KEY] = averageHumidity();
//  (*json)[MESH_PRESSURE_VALUE_KEY] = instantaniousPressure();
//  (*json)[MESH_AVERAGE_PRESSURE_VALUE_KEY] = averagePressure();
//  (*json)[MESH_GAS_VALUE_KEY] = instantaniousGas();
//  (*json)[MESH_AVERAGE_GAS_VALUE_KEY] = averageGas();
//  (*json)[MESH_AIR_QUALITY_VALUE_KEY] = airQuality;
//  (*json)[MESH_TIMESTAMP_KEY] = time_offset + (millis()/1000);
//}



void BME680AirSensorTask() {
  currentSensorFunction();
}


const double gas_lower_limit = 5000.0;   // Bad air quality limit
const double gas_upper_limit = 50000.0;  // Good air quality limit 
const double gas_delta = 45000.0;
const double scaled_gas_delta = 75.0/gas_delta;

double lowHumidityScore( double hum ) {
  return (25/hum_baseline)*hum;
}

double highHumidityScore( double hum ) {
  return ((-25/(100-hum_baseline)*hum) + +41.6666); //41.6666 might be too high, try 26
}

double humidityScore( double hum ) {
  if( hum < 38 ) {
    return lowHumidityScore(hum);
  } else if( hum > 42 ) {
    return highHumidityScore(hum);
  }
  return 25;
}

double computeAirQualityScore( double hum, double gas ) { 
  //Calculate humidity contribution to IAQ index
  double hum_score = humidityScore(hum);
  
  //Calculate gas contribution to IAQ index
  double gas_value = gas;
  if( gas_value > gas_upper_limit ) gas_value = gas_upper_limit; 
  if( gas_value < gas_lower_limit ) gas_value = gas_lower_limit;

  double gas_score = scaled_gas_delta * (gas_value - gas_lower_limit);
  
  //Combine results for the final IAQ index value (0-100% where 100% is good quality air)
  double air_quality_score = (100 - (hum_score + gas_score)) * 5;
  
  return air_quality_score; 
}

void beginReadingSensor() { 
  //-- we are in the begin reading state.
  finishReadingSensorTime = bme.beginReading();
  if( finishReadingSensorTime == 0 ) {
    //-- failed to start the sensor so go back to idle with a shortened interval
    Serial.println(F("Failed to begin reading :("));
    setNextSensorReadingTime( 1000 );
    currentSensorFunction = idleSensorFunction;
    return;
  }

  //-- set state to waiting for sensor
  currentSensorFunction = waitForSensor;
}

void waitForSensor() {
  //-- we are in the waiting for sensor state.
  if( millis() >= finishReadingSensorTime ) {
    //-- set state to finish reading
    currentSensorFunction = finishReadingSensor;
  }
}

void finishReadingSensor() {
  //-- we are in the finish reading state.
  if( !bme.endReading() ) {
    Serial.println(F("Failed to complete reading :("));
    setNextSensorReadingTime( 1000 );
    currentSensorFunction = idleSensorFunction;
    return;
  }  

  double temperature = bme.temperature;

  double pressure = bme.pressure;

  double humidity = bme.humidity;  //average humidity in fc is 53.0% +- 5
 
  double gas = bme.gas_resistance;

  enterSensorReading(temperature, humidity );
  
  //-- set next time to take a reading and go back to the idle state
  setNextSensorReadingTime( BME680HasCompleteSensorData() ? sensorReadingInterval : 10000 );
  currentSensorFunction = idleSensorFunction;

  //logValues();
}

void idleSensorFunction() {
  //-- we are in the idle state and waiting until it's time to take another reading.
  unsigned long t = millis();
  if( millis() >= nextSensorReadingTime ) {
    currentSensorFunction = beginReadingSensor;
  }
}

void nilSensorFunction() {
  //-- do nothing
}




#endif
