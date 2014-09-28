#include <OneWire.h>
#include <DallasTemperature.h>

// Data wire is plugged into port 2 on the Arduino
#define ONE_WIRE_BUS 2


/***********************/
/* Interval Definitions*/
#define INTERVAL 180000 //Define ms INTERVAL in between trigerring
#define SENSOR_INTERVAL 500 // SENSOR INTERVAL 

/*******/
/*Define array size to be used for averaging. */
/*In The array, the max value and min value are taken out and the rest averaged*/
/* If 2 or less, it is just averaged*/
#define ARRAY_SIZE 10


/**********************/
/*Hysterisis Intervals*/
#define TEMP_LO 1
#define TEMP_HI 1

/**********************/
/*Define output  Pins */
//Digital
#define RELAY1  3      // Relay to start the first heater

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);
// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

/*****************************/
/*set Triggers *************/
int cook_trigger  = 63; //For perfect steak in case arduino resets


/***************************/
/* Sensor Value initialize */
long  temp1 = 0; 

long therm1[ARRAY_SIZE];


/************************/
/*Set time check ms     */
long last_check = millis();
long sensor_check = millis();
int timing = millis();



void setup()
{
  
    //Setup averaging arrays
  int i;
  for(i=0; i< ARRAY_SIZE; i++)
  {
    therm1[i] = 75.00;
  }
  
    // Start up the library for one wire
  sensors.begin();

  Serial.begin(115200);
}

void loop() {
    //reset sensor_check if millis() has overflowed
  if( millis() < sensor_check ){ sensor_check = millis();  }


 /*Read sensor only after delay of sensor_check*/
  if(millis() - sensor_check > SENSOR_INTERVAL )
  {
    sensor_check = millis();
    int i;

    for (i=0; i < ARRAY_SIZE -1 ; i++) {  
      therm1[i] = therm1[i+1];
    }

sensors.requestTemperatures(); // Send the command to get temperatures

    therm1[ARRAY_SIZE -1] = sensors.getTempCByIndex(0); 
    long temp1 = mov_avg(therm1);   
  }

/*******************************************************/
/*RELAY Changes and value checks, after time INTERVAL***/
  if( millis() < last_check ) { last_check = millis(); }

  if (millis() - last_check > INTERVAL) 
  {
    Serial.print("Relay Change");
    last_check = millis(); 
    
    //TOO HIGH TEMPERATURE
    if ( temp1 > (cook_trigger + TEMP_HI))
      {
        digitalWrite(RELAY1, LOW);
      }

    //TOO LOW TEMPERATURE
    if ( temp1 < (cook_trigger - TEMP_LOW))
      {
        digitalWrite(RELAY1,HIGH);
      }
      
  }
  
  
  
  
  
  
  
  
  
  
  }























