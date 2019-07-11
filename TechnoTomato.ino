
#define QUICK_TESTING 1


#include <OneWire.h>
#include "PlantManager.h"
#include "Sensor_BME680.h"


/*
 * Rather than drag Arduino JSON into this already big sketch I'm just producing a JSON string directly.  
 * TechnoTomato.ini is not the actual working sketch and has had all the private information such as 
 * my ThingSpeak keys removed.
 * This is the fixed json for sending to the thingspeak portal for a controller.  ThingSpeakPortal is an
 * ESP8266-01 connected through a serial port to the Arduino.  ThingSpeakPortal reads the json on it's serial
 * port, translates it to a ThingSpeak message and sends it.  
 */
const String prefix = "{\"destination\": \"thingspeak\", \"api_key\": \"16_CHAR_APIKEY\", \"channel\": 123456, \"status\": \"\", \"fields\": [";
const String suffix = "]}";


// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(22); // TechnoTomato 1 is the Mega version, where I'm using pin 22 for OneWire

#include "Sensor_DS18B20.h"

//Adafruit_ADS1115 is included in PlantManager.h so we can use it there
Adafruit_ADS1115 ads;  /* Use this for the 16-bit version */

// PlantManager
//                                                holding mega with usb and power on left side
const uint8_t valvePins[4] = {31, 33, 35, 37}; // top outside set of digital pins
PlantManager plants(2, valvePins);

unsigned long logTimer = 0;
void loggingTask();

unsigned long sampleTimer = 0;
void samplingTask();

double sampleAverages[4] = {};
int sampleTriggers[4] = {};
int sampleAirTemp = 0;
int sampleRootTemp = 0;
int sampleCount = 0;


void setup() {
  Serial.begin(115200);
  delay(2000);

#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
  Serial2.begin(115200);
#endif

  //Serial.println("Starting");
  
  // The ADC input range (or gain) can be changed via the following
  // functions, but be careful never to exceed VDD +0.3V max, or to
  // exceed the upper and lower limits if you adjust the input range!
  // Setting these values incorrectly may destroy your ADC!
  //                                                                ADS1015  ADS1115
  //                                                                -------  -------
  // ads.setGain(GAIN_TWOTHIRDS);  // 2/3x gain +/- 6.144V  1 bit = 3mV      0.1875mV (default)
  // ads.setGain(GAIN_ONE);        // 1x gain   +/- 4.096V  1 bit = 2mV      0.125mV
  // ads.setGain(GAIN_TWO);        // 2x gain   +/- 2.048V  1 bit = 1mV      0.0625mV
  // ads.setGain(GAIN_FOUR);       // 4x gain   +/- 1.024V  1 bit = 0.5mV    0.03125mV
  // ads.setGain(GAIN_EIGHT);      // 8x gain   +/- 0.512V  1 bit = 0.25mV   0.015625mV
  // ads.setGain(GAIN_SIXTEEN);    // 16x gain  +/- 0.256V  1 bit = 0.125mV  0.0078125mV
  ads.setGain(GAIN_ONE);
  ads.begin();
  plants.initialize(&ads);

  initBME680();
  initDS18B20();

  logTimer = millis() + 60000; //give the esp time to start up before sending things to it
}


bool isOutput = false;
void loop() {
  plants.perform();

  BME680AirSensorTask();
  DS18B20SensorTask();

  samplingTask();
  loggingTask();
}


void samplingTask() {
  unsigned long now = millis();
  if( now > sampleTimer ) {
    int c = sampleCount + 1;
    float airTemp = averageTemperature();
    float airHumidity = averageHumidity();
    float rootTemp = getRootZoneTemperature();
    sampleAirTemp = ((sampleAirTemp * sampleCount) + airTemp)/c;
    sampleRootTemp = ((sampleRootTemp * sampleCount) + rootTemp)/c;      
    
    double values[4];
    int triggers[4];
    plants.updateSensorValues( values, triggers );
    plants.setAmbientTemperature(sampleAirTemp);
    
    for( int i = 0; i < 4; i++ ) {
      sampleAverages[i] = ((sampleAverages[i] * sampleCount) + values[i])/c;
      sampleTriggers[i] += triggers[i];
    }
    sampleCount += 1;
    sampleTimer = now + 10000;
  }
}

void loggingTask() {
  unsigned long now = millis();
  if( now > logTimer ) {
     // log air temperature and humidity sensor data
 
    float data[8] = {sampleAverages[0], sampleTriggers[0], sampleAverages[1], sampleTriggers[1], sampleAverages[2], sampleTriggers[2], sampleAirTemp, sampleRootTemp };
    String json = prefix;
    for( int i = 0; i < 8; i++ ) {
      if( i > 0 ) { json += ", " + String(data[i]); }
      else { json += String(data[i]); }
    }
    json += suffix;
    
#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
    Serial2.println(json);
#endif
     Serial.println(json);

    sampleCount = 0;
    for( int i = 0; i < 4; i++ ) {
      sampleAverages[i] = 0;
      sampleTriggers[i] = 0;
    }
    sampleAirTemp = 0;
    sampleRootTemp = 0;     

    logTimer = now + 60000;
  }
}
