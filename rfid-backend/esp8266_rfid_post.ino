/*
  esp8266_rfid_post.ino

  Reads RFID UIDs from an MFRC522 module and POSTs them as JSON to
  http://<server-ip>:5000/rfid/card with body: {"cardUID": "<UID>"}

  Hardware:
  - ESP8266 (NodeMCU, Wemos D1 mini, etc.)
  - RC522 MFRC522 (SPI)

  Libraries required:
  - ESP8266WiFi
  - ESP8266HTTPClient
  - SPI
  - MFRC522

  Configure WiFi credentials and SERVER_IP below.
*/

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>

// ===== Configuration =====
// Credentials taken from user's Firebase sketch
const char* SSID = "espwifi";
const char* PASSWORD = "pass@786";
const char* SERVER_IP = "192.168.1.100"; // change to your PC / server IP
const int SERVER_PORT = 5000;
const char* SERVER_PATH = "/rfid/card";

// MFRC522 pins (from user's Firebase sketch)
#define SS_PIN D4
#define RST_PIN D3
#define ON_BOARD_LED D2

MFRC522 mfrc522(SS_PIN, RST_PIN);

// Debounce: avoid sending the same UID continuously
String lastUID = "";
unsigned long lastSendMillis = 0;
const unsigned long sendCooldown = 5000; // ms between identical UID sends

void setup() {
  Serial.begin(115200);
  SPI.begin();
  mfrc522.PCD_Init();
  delay(100);

  pinMode(ON_BOARD_LED, OUTPUT);
  digitalWrite(ON_BOARD_LED, HIGH); // LED off

  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, PASSWORD);
  Serial.println();
  Serial.print("Connecting to WiFi");
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print('.');
    if (millis() - start > 20000) {
      Serial.println("\nFailed to connect to WiFi");
      break;
    }
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print("Connected! IP: ");
    Serial.println(WiFi.localIP());
  }
}

String uidToString(MFRC522::Uid uid) {
  String s = "";
  for (byte i = 0; i < uid.size; i++) {
    if (uid.uidByte[i] < 0x10) s += "0";
    s += String(uid.uidByte[i], HEX);
  }
  s.toUpperCase();
  return s;
}

void sendUID(const String &uid) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected, skipping send");
    return;
  }

  HTTPClient http;
  WiFiClient client;
  String url = String("http://") + SERVER_IP + ":" + String(SERVER_PORT) + SERVER_PATH;
  Serial.print("POST URL: "); Serial.println(url);
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");

  String body = "{\"cardUID\": \"" + uid + "\"}";
  int httpCode = http.POST(body);

  if (httpCode > 0) {
    String payload = http.getString();
    Serial.printf("POST %s -> %d\n", url.c_str(), httpCode);
    Serial.println(payload);
  } else {
    Serial.printf("POST failed, error: %s\n", http.errorToString(httpCode).c_str());
  }

  http.end();
}

void loop() {
  // Look for new cards
  if ( ! mfrc522.PICC_IsNewCardPresent()) {
    delay(50);
    return;
  }
  if ( ! mfrc522.PICC_ReadCardSerial()) {
    delay(50);
    return;
  }

  String uid = uidToString(mfrc522.uid);
  Serial.print("Card UID: ");
  Serial.println(uid);

  // Send every detection immediately (no cooldown on duplicate UIDs)
  sendUID(uid);
  lastUID = uid;

  mfrc522.PICC_HaltA();
  delay(200);
}
