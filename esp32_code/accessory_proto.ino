#include <WiFi.h>
#include <WiFiUdp.h>

const char* ssid = "ULink";
const char* pass = "zvvqkchxrblt";
unsigned int localPort = 1234;

char packetBuffer[6];

WiFiUDP Udp;

void setup() {
  Serial.begin(115200);
  delay(500);

  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }

  Serial.println("Connected to Wifi");
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
      String packet(packetBuffer);
      if (packet == "on") {

      } else if (packet == "off") {

      }

      Udp.beginPacket(Udp.remoteIP(), Udp.remotePort());
      Udp.print("on received");
      Udp.endPacket();
      Serial.println("Ack sent");
    }
    for (int i = 0; i < 6; i++) {
      packetBuffer[i] = 0;
    }
  }
}
