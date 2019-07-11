#include <DallasTemperature.h>


#ifndef _Sensor_DS18B20_H_ 
#define _Sensor_DS18B20_H_ 

// The sensor reading states.
void beginReadingOneWireSensors();
void waitForOneWireSensors();
void finishReadingOneWireSensors();
void (*currentOneWireSensorFunction)(void) = beginReadingOneWireSensors;
unsigned long nextOneWireTime = 0;

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature oneWireSensors(&oneWire);

void initDS18B20() {
  oneWireSensors.begin();
  currentOneWireSensorFunction = beginReadingOneWireSensors;
}

void DS18B20SensorTask() {
  currentOneWireSensorFunction();
}

double getRootZoneTemperature() {
  return oneWireSensors.getTempCByIndex(0);
}


void beginReadingOneWireSensors() {
  oneWireSensors.requestTemperatures();
  nextOneWireTime = millis() + 10000;
  currentOneWireSensorFunction = beginReadingOneWireSensors;
}

void waitForOneWireSensors() {
  if( millis() > nextOneWireTime ) {
    currentOneWireSensorFunction = beginReadingOneWireSensors;
  }
}















#endif
