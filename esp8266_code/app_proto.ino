#include <ScioSense_ENS210.h>

#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <Wire.h>
#include <Adafruit_DPS310.h>

const char* ssid = "ULink";
const char* password = "xwswxxcvnbzr";

// const char* ssid = "Googleballz";
// const char* password = "8015450181";

// const char* ssid = "IsaaciPhone";
// const char* password = "igs2002!";

unsigned int localPort = 1234;         // Change this to the desired port number
const int pinNum = 0;

char packetBuffer[6];

unsigned long lastSensorTime = 0;
bool lightOn = false;
int previousLux = 0;

const int OPT4001_ADDRESS = 70;
const int REG_CONFIGURATION = 0;
const int REG_RESULT = 1;

Adafruit_DPS310 dps310;
Adafruit_Sensor* dps_temp = dps310.getTemperatureSensor();
Adafruit_Sensor* dps_pressure = dps310.getPressureSensor();
float temperature = 0.0;
float pressure = 0.0;
float lux = -1;

ScioSense_ENS210 ens210;

WiFiUDP Udp;
IPAddress phoneIP;
int phonePort;

void setup() {
  previousLux = analogRead(A0);

  Serial.begin(115200);
  delay(500);
  pinMode(pinNum, OUTPUT);
  digitalWrite(pinNum, LOW);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  
  Serial.println("Connected to WiFi");
  
  Udp.begin(localPort);
  Serial.printf("Listening on IP %s, port %d\n", WiFi.localIP().toString().c_str(), localPort);

  Wire.begin();
  Wire.beginTransmission(OPT4001_ADDRESS);
  Wire.write(REG_CONFIGURATION);
  Wire.write(0x00); // Set integration time to 800ms
  Wire.endTransmission();

  dps310.begin_I2C();
  dps310.configurePressure(DPS310_64HZ, DPS310_64SAMPLES);
  dps310.configureTemperature(DPS310_64HZ, DPS310_64SAMPLES);
  dps_temp->printSensorDetails();
  dps_pressure->printSensorDetails();

  ens210.begin();
  ens210.setSingleMode(false);

  Serial.println("Finished setup");
}

void loop() {
  int packetSize = Udp.parsePacket();
  if (packetSize) {
    int len = Udp.read(packetBuffer, packetSize);
    Udp.flush();
    if (len > 0) {
      packetBuffer[len] = '\0';
      Serial.printf("[%lu] Received from %s:%d - %s\n", millis(), Udp.remoteIP().toString().c_str(), Udp.remotePort(), packetBuffer);
      digitalWrite(pinNum, !digitalRead(pinNum));
      String packet = String(packetBuffer);

      int spaceIndex = packet.indexOf(' ');
      String device = packet.substring(0, spaceIndex);
      if (device == "tinys2") {
        auto lightState = packet.substring(spaceIndex + 1);
        if (lightState == "on" && !lightOn) {
          lightOn = true;
          Udp.beginPacket("10.120.38.226", 1235);
          Udp.write("on");
          Udp.endPacket();
          Serial.println("Sent request to tinys2");
        } else if (lightState == "off" && lightOn) {
          lightOn = false;
          Udp.beginPacket("10.120.38.226", 1235);
          Udp.write("off");
          Udp.endPacket();
          Serial.println("Sent request to tinys2");
        } else {
          Udp.beginPacket(Udp.remoteIP(), Udp.remotePort());
          Udp.write(lightOn ? "on" : "off");
          Udp.endPacket();
        }

        phoneIP = Udp.remoteIP();
        phonePort = Udp.remotePort();
      } else if (device == "stove") {
        Udp.beginPacket("10.120.38.149", 1235);
        Udp.write(packet.substring(spaceIndex + 1).c_str());
        Udp.endPacket();
        Serial.println("Sent request to stove");

        phoneIP = Udp.remoteIP();
        phonePort = Udp.remotePort();
      } else if (packet.substring(spaceIndex + 1) == "received") {
        Udp.beginPacket(phoneIP, phonePort);
        Udp.write("received");
        Udp.endPacket();
        Serial.printf("Ack sent to %s : %d\n", phoneIP.toString().c_str(), phonePort);
      } else if (packet.startsWith("stove")) { // reconfigure all of this if / else if / else if to be light / stove / weather and then inside that do other logic for sending to esp and waiting etc
        phoneIP = Udp.remoteIP();
        phonePort = Udp.remotePort();
        delay(500);
        Udp.beginPacket(phoneIP, phonePort);
        Udp.write("received");
        Udp.endPacket();
        Serial.printf("Ack sent to %s : %d\n", phoneIP.toString().c_str(), phonePort);
      } else if (packet.startsWith("weather")) {
        phoneIP = Udp.remoteIP();
        phonePort = Udp.remotePort();

        /*
        sensors_event_t temp_event, pressure_event;
        if (dps310.temperatureAvailable()) {
          dps_temp->getEvent(&temp_event);
          temperature = temp_event.temperature;
        }

        if (dps310.pressureAvailable()) {
          dps_pressure->getEvent(&pressure_event);
          pressure = pressure_event.pressure;
        }

        if (ens210.available()) {
          ens210.measure();
        }

        Wire.beginTransmission(OPT4001_ADDRESS);
        Wire.write(REG_RESULT);
        Wire.endTransmission();
        Wire.requestFrom(OPT4001_ADDRESS, 2);
        if (Wire.available() == 2) {
          // Convert the raw data to lux
          unsigned int rawData = Wire.read() << 8 | Wire.read();
          lux = (float)rawData / 400.0;
        }
        */

        // String luxSt = "temperature: " + String(temperature) + ", pressure:" + String(pressure) + ", temperature: " + String(ens210.getTempCelsius()) + ", humidity: " + String(ens210.getHumidityPercent());
        String tempLux = "weather: " + String(analogRead(A0));
        Udp.beginPacket(phoneIP, phonePort);
        Udp.write(tempLux.c_str());
        Udp.endPacket();
        Serial.printf("Ack sent to %s : %d\n", phoneIP.toString().c_str(), phonePort);
      } else if (packet.startsWith("status")) {
        Udp.beginPacket(phoneIP, phonePort);
        Udp.write(packet.c_str());
        Udp.endPacket();
        Serial.printf("Ack sent to %s : %d\n", phoneIP.toString().c_str(), phonePort);
      } else {
        Serial.println("passing");
      }
    }
    for (int i = 0; i < 6; i++) {
      packetBuffer[i] = 0;
    }
  }

  unsigned long currentMillis = millis();
  if (currentMillis - lastSensorTime >= 1000) {
    if ((previousLux < 350 && analogRead(A0) >= 350) || previousLux >= 350 && analogRead(A0) < 350) {
      if (analogRead(A0) < 350 && !lightOn) {
        Udp.beginPacket("10.120.38.226", 1235);
        Udp.write("on");
        Udp.endPacket();
        Serial.println("Sent request to tinys2");
        lightOn = true;
      } else if (analogRead(A0) >= 350 && lightOn) {
        Udp.beginPacket("10.120.38.226", 1235);
        Udp.write("off");
        Udp.endPacket();
        Serial.println("Sent request to tinys2");
        lightOn = false;
      }
    }
    previousLux = analogRead(A0);
    lastSensorTime = currentMillis;
  }
}
