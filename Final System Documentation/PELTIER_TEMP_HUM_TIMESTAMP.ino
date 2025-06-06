//---------------------------------------LIBRARIES:---------------------------------------
#include <Adafruit_AHT10.h>

// INITIAL VARIABLES
int relayPin = 7;                                               // Relay module IN pin
bool relayState = false;  // Relay state (OFF initially)
Adafruit_AHT10 aht;

//-----------------------------------------SETUP:-----------------------------------------
void setup() {
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, LOW);                                 // Ensure relay starts OFF
  Serial.begin(115200);
  delay(1000);
  Serial.println("Timestamp,Temperature,Humidity");            // CSV header

  // Error catching
  if (!aht.begin()) {
    Serial.println("Could not find AHT10? Check wiring");
    while (1) delay(10);
  }
}

//---------------------------------------MAIN LOOP:---------------------------------------
void loop() {
  unsigned long timestamp = millis();                          // Get current time in ms

  // Check for serial input to toggle relay
  if (Serial.available()) {
    char input = Serial.read();
    if (input == '\n') {                                       // Detect Enter key
      relayState = !relayState;                                // Toggle relay state
      digitalWrite(relayPin, relayState ? LOW : HIGH);         // Relay is active LOW
      //Serial.println(relayState ? "Relay ON" : "Relay OFF"); // To debug
    }
  }

  // Read temperature and humidity
  sensors_event_t humidity, temp;
  aht.getEvent(&humidity, &temp);

  // Print timestamp, sensor data
  Serial.print(timestamp);
  Serial.print(",");
  Serial.print(temp.temperature);
  Serial.print(",");
  Serial.println(humidity.relative_humidity);
  //Serial.print(",");                                         // To debug
  //Serial.println(relayState ? "ON" : "OFF");                 // To debug

  delay(500);                                                  //delay for stable readings
}
