#include <ESP8266WiFi.h>
#include <WiFiUdp.h>

const char* ssid = "ULink";        // Replace with your WiFi network SSID
const char* password = "xwswxxcvnbzr";  // Replace with your WiFi network password
unsigned int localPort = 1234;         // Change this to the desired port number
const int pinNum = 0;

char packetBuffer[6];

WiFiUDP Udp;

void setup() {
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
    }
    for (int i = 0; i < 6; i++) {
      packetBuffer[i] = 0;
    }
  }
}
