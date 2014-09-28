#include <LiquidCrystal.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <stdlib.h>	// for ltoa() call

// Data wire is plugged into port 2 on the Arduino
#define ONE_WIRE_BUS 2

/***********************/
/* Interval Definitions*/
#define INTERVAL 15000 //Define ms INTERVAL in between trigerring
#define SENSOR_INTERVAL 500 // SENSOR INTERVAL 

/*******/
/*Define array size to be used for averaging. */
/*In The array, the max value and min value are taken out and the rest averaged*/
/* If 2 or less, it is just averaged*/
#define ARRAY_SIZE 10

/**********************/
/*Hysterisis Intervals*/
#define TEMP_LOW 0
#define TEMP_HIGH 0

/**********************/
/*Define output  Pins */
//Digital
#define RELAY1  3      // Relay to start the first heater
#define BACKLIGHT 10

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);
// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

/*****************************/
/*set Triggers *************/
long cook_trigger  = 61; //For perfect steak in case arduino resets

/***************************/
/* Sensor Value initialize */
long  temp1 = 62; 
long therm1[ARRAY_SIZE];


/************************/
/*Set time check ms     */
long last_check = millis();
long sensor_check = millis();

/**************************/
/** LCD Shield            */
// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

//Keys configuration
char buf[5]; //used in conversion of int to char for lcd
int adc_key_in = 1024; //Start with -1 key value
int adc_key_val[5] = {
  100, 160, 360, 770, 800 }; //Analog values from Keys on keypad shield
int NUM_KEYS = 5;
int key= -1;

/*************************************/
// Count number of minutes
int start = 0;
int current =0;
int trig_minutes = 0;


void setup()
{
  //Setup averaging arrays
  int i;
  for(i=0; i< ARRAY_SIZE; i++)
  {
    therm1[i] = 62.00;
  }

  // Start up the library for one wire
  sensors.begin();

//Define outputs
  pinMode(RELAY1,OUTPUT);
  
  // set up the LCD's number of columns and rows: 
  lcd.begin(16, 2);
  
  /**** Write first line of Display which is static*/
  lcd.setCursor(0, 0);
  lcd.print("T-set:T-cur");
  lcd.setCursor(0,1);
  
  // print hasn't reaching cooking temp
    lcd.setCursor(13,0);
    lcd.print("Wait");


  Serial.begin(115200);
  
}

void loop() {
    
  //reset sensor_check if millis() has overflowed
  if( millis() < sensor_check ){ 
    sensor_check = millis();  
  }

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
    
    temp1 = mov_avg(therm1);  
    
    /////Debug Data///
    /*Serial.print(temp1);
    Serial.print(":");
    Serial.print(cook_trigger);    
    Serial.println(":");*/
    //Print Temperature
    ltoa(temp1, buf, 10);
    lcd.setCursor(7,1);
    lcd.print(buf);
  }

  /*******************************************************/
  /*RELAY Changes and value checks, after time INTERVAL***/
  if( millis() < last_check ) { 
    last_check = millis(); 
  }
  
  
if (millis() - last_check > INTERVAL) 
 {    
    //////////////////////////////////////////
    // print how many minutes has been cooking
    if ( trig_minutes == 1) {
    current = millis() - start;
    current = current/60000; 
    ltoa(current, buf, 10);
    lcd.setCursor(13,0);
    lcd.print("    ");
    lcd.print(buf);
    }
    /////////////////////////////////////////
    
    Serial.print("Relay Change");
    last_check = millis(); 

  Serial.println(temp1);
    //TOO HIGH TEMPERATURE
    if ( temp1 > (cook_trigger + TEMP_HIGH))
    {
      digitalWrite(RELAY1, LOW);
      lcd.setCursor(14,1);
      lcd.print(":)");
          Serial.print("Relay LOW");
      
      //Start the timer
      if ( trig_minutes == 0) {
      start = millis();
      trig_minutes = 1;
      }
      
    }

    //TOO LOW TEMPERATURE
    if ( temp1 < (cook_trigger - TEMP_LOW))
    {
      digitalWrite(RELAY1,HIGH);
      lcd.setCursor(14,1);
      lcd.print(":(");
      Serial.print("Relay HIGH");     
    }
  }



  /******************************/
  /* Code for Keypad  ***********/

  adc_key_in = analogRead(0);
  delay(20); //debounce
  key = get_key(adc_key_in); //convert into key press. key = 1-5. -1 for none

  //Keypress UP
  if (key ==1) {
    cook_trigger++;
    delay(100);
    Serial.print("Keypress UP");
  }

  //Keypress DOWN
  if (key ==2) {
    cook_trigger--;
    delay(100);
    Serial.print("Keypress Down");
  }

  //Keypress Right 
  if (key ==0) {
    cook_trigger = cook_trigger +5;
    delay(100);
    Serial.print("Keypress RIGHT");
  }

  //Keypress Left
  if (key == 3) {
    cook_trigger = cook_trigger -5;
    delay(100);
    Serial.print("Keypress LEFT");
  }      

  /* update screen with new Trigger */
  lcd.setCursor(0,1);
  ltoa(cook_trigger, buf, 10); 
  lcd.print(buf);  

}





long mov_avg(long averages[ARRAY_SIZE])
{
  long summation = averages[0];
  int i=1;
  for( i=1; i < ARRAY_SIZE; i++)
  {
    summation = averages[i] + summation;
  }
  if(ARRAY_SIZE >2)
  {
    summation = summation - max_array(averages) - min_array(averages);
    summation = summation/(ARRAY_SIZE -2);
  }
  else
  {
    summation = summation/ARRAY_SIZE;
  }
  return summation;
}


long max_array(long array[ARRAY_SIZE])
{
  int i=0;
  long current= array[0];
  for( i=1; i<ARRAY_SIZE; i++)
  {
    if (array[i] > current)
    {
      current = array[i];
    }
  }
  return current;
}

long min_array(long array[ARRAY_SIZE])
{
  int i=0;
  long current= array[0];
  for( i=1; i<ARRAY_SIZE; i++)
  {
    if (array[i] < current)
    {
      current = array[i];
    }
  }
  return current;
}

int get_key(unsigned int input)
{
  int k;

  for ( k=0; k < NUM_KEYS; k++)
  {
    if (input < adc_key_val[k] )
    { 
      return k; 
    }
  }

  if ( k >= NUM_KEYS)
  {
    k = -1;
  }
  return k;
}


















