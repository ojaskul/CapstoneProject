#include <WiFi.h>
#include <WiFiUdp.h>


const char* ssid = "ULink";
const char* pass = "zvvqkchxrblt";

// const char* ssid = "Googleballz";
// const char* pass = "8015450181";

// const char* ssid = "Doneraille";
// const char* pass = "8015450181";

unsigned int localPort = 1235;

const int ON_PIN = 8;
const int OFF_PIN = 9;

const int BTN_PIN = 4;
bool on = false;

char packetBuffer[6];

WiFiUDP Udp;

void setup() {
  pinMode(ON_PIN, OUTPUT);
  pinMode(OFF_PIN, OUTPUT);
  pinMode(BTN_PIN, INPUT);

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
      if (packet == "on" && !on) {
        on = true;
        digitalWrite(ON_PIN, HIGH);
        delay(2000); // ms
        digitalWrite(ON_PIN, LOW);
      } else if (packet == "off" && on) {
        on = false;
        digitalWrite(OFF_PIN, HIGH);
        delay(2000);
        digitalWrite(OFF_PIN, LOW);
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

  if (digitalRead(BTN_PIN) == HIGH) {
    Serial.println("pressed");
    if (on) {
      on = false;
      digitalWrite(OFF_PIN, HIGH);
      delay(2000);
      digitalWrite(OFF_PIN, LOW);
    } else {
      on = true;
      digitalWrite(ON_PIN, HIGH);
      delay(2000); // ms
      digitalWrite(ON_PIN, LOW);
    }
  }
  delay(100);
}
