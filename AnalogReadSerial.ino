#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// Pin for connection to the soil moisture sensor
#define SENSOR_PIN 33  

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = true;

// Define UUIDs for BLE service and characteristic
#define SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define CHARACTERISTIC_UUID "abcd1234-ab12-cd34-ef56-1234567890ab"

void setup() {
  // Change the default Baud from 921600 to 115200
  Serial.begin(115200);

  // Initialize BLE with a custom name
  BLEDevice::init("ESP32_Sensor");
  pServer = BLEDevice::createServer();

  // Create a new BLE 
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Create READ and NOTIFY properties
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  // Start point of the BLE service
  pService->start();

  // Start point of advertising the BLE service
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
  Serial.println("BLE initialized and is waiting for connections ...");
}

void loop() {
  // Read moisture sensor value (Range is between 0-4095)
  int sensorValue = analogRead(SENSOR_PIN);
  int moisturePercent = 100 - map(sensorValue, 0, 4095, 0, 100);

  // Format the JSON
  String jsonData = "{ \"sensorValue\": " + String(sensorValue) + 
                    ", \"moisturePercent\": " + String(moisturePercent) + " }";

  // Send data via BLE if a device is connected
  if (deviceConnected) {
    pCharacteristic->setValue(jsonData.c_str()); 
    pCharacteristic->notify();  
    Serial.println("Data sent: " + jsonData);
  }

  // 10 seconds delay before reading again
  delay(10000);  
}
