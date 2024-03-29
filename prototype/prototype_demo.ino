#include <ESP8266WiFi.h>

const char* ssid = "Isaac_iPhone";
const char* password = "igs2002!";

int LED = 12;
int MOTOR = 14;
WiFiServer server(80);

int led_value;
int motor_value;

void setup() {
  Serial.begin(115200);
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  pinMode(MOTOR, OUTPUT);
  digitalWrite(MOTOR, LOW);

  Serial.print("Connecting to the Network");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");
  server.begin();
  Serial.println("Server started");

  Serial.print("IP Address of network: ");
  Serial.println(WiFi.localIP());
  Serial.print("Copy and paste the following URL: https://");
  Serial.print(WiFi.localIP());
  Serial.println("/");
}

void loop() {
  WiFiClient client = server.available();
  if (!client) {
    return;
  }
  Serial.println("Waiting for new client");
  while (!client.available()) {
    delay(1);
  }

  String request = client.readStringUntil('\r');
  Serial.println(request);
  client.flush();

  led_value = LOW;
  if (request.indexOf("/LED=ON") != -1) {
    digitalWrite(LED, HIGH);
    led_value = HIGH;
  }
  if (request.indexOf("/LED=OFF") != -1) {
    digitalWrite(LED, LOW);
    led_value = LOW;
  }

  motor_value = LOW;
  if (request.indexOf("/MOTOR=ON") != -1) {
    digitalWrite(MOTOR, HIGH);
    motor_value = HIGH;
  }
  if (request.indexOf("/MOTOR=OFF") != -1) {
    digitalWrite(MOTOR, LOW);
    motor_value = LOW;
  }

  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/html");
  client.println("");
  client.println("<!DOCTYPE HTML>");
  client.println("<html>");

  client.print("LED: ");

  if (led_value == HIGH) {
    client.print("ON");
  } else {
    client.print("OFF");
  }
  client.println("<br><br>");
  client.println("<a href=\"/LED=ON\"\"><button>ON</button></a>");
  client.println("<a href=\"/LED=OFF\"\"><button>OFF</button></a><br />");

  client.println("<br><br>");
  client.print("MOTOR: ");

  if (motor_value == HIGH) {
    client.print("ON");
  } else {
    client.print("OFF");
  }
  client.println("<br><br>");
  client.println("<a href=\"/MOTOR=ON\"\"><button>ON</button></a>");
  client.println("<a href=\"/MOTOR=OFF\"\"><button>OFF</button></a><br />");
  
  client.println("</html>");

  delay(1);
  Serial.println("Client disconnected");
  Serial.println("");
}
