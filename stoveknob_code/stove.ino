#include <AccelStepper.h>
#include <MultiStepper.h>

#include <WiFi.h>
#include <WiFiUdp.h>


// const char* ssid = "ULink";
// const char* pass = "zvvqkchxrblt";

// const char* ssid = "Googleballz";
// const char* pass = "8015450181";

const char* ssid = "IsaaciPhone";
const char* pass = "igs2002!";

unsigned int localPort = 1235;

#define HALFSTEP 8
#define motorPin1 4
#define motorPin2 5
#define motorPin3 6
#define motorPin4 7

char packetBuffer[6];
bool motorTurning = false;
int fullRev = 4076;

WiFiUDP Udp;

AccelStepper stepper1(HALFSTEP, motorPin1, motorPin3, motorPin2, motorPin4);

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

  stepper1.setMaxSpeed(1000.0);
  stepper1.setAcceleration(200.0);
  stepper1.setSpeed(600);
}

void loop() {
  if (motorTurning) {
    if (stepper1.distanceToGo() != 0) {
      stepper1.run();
    } else {
      stepper1.disableOutputs();
      motorTurning = false;
    }
  }

  int packetSize = Udp.parsePacket();

  if (packetSize) {
    int len = Udp.read(packetBuffer, packetSize);
    Udp.flush();
    if (len > 0) {
      packetBuffer[len] = '\0';
      Serial.printf("[%lu] Received from %s:%d - %s\n", millis(), Udp.remoteIP().toString().c_str(), Udp.remotePort(), packetBuffer);
      String packet(packetBuffer);

      if (packet == "status") {
        long position = stepper1.currentPosition();
        Serial.printf("status: %d\n", position);

        Udp.beginPacket(Udp.remoteIP(), Udp.remotePort());
        Udp.printf("status %ld", position);
        Udp.endPacket();
        Serial.println("Sent status");
      } else if (packet.startsWith("rotate")) {
        long percentage = packet.substring(packet.indexOf(" ") + 1).toInt();
        long stepAmt = (percentage * fullRev) / 100;
        stepper1.moveTo(stepAmt);
        motorTurning = true;
        Serial.printf("rotate to %d\n", stepAmt);

        Udp.beginPacket(Udp.remoteIP(), Udp.remotePort());
        Udp.print("received");
        Udp.endPacket();
        Serial.println("Ack sent");
      }
    }

    for (int i = 0; i < 6; i++) {
      packetBuffer[i] = 0;
    }
  }
}
