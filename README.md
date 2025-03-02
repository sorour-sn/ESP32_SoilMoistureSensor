# Soil Moisture Monitoring System

This project involves using an ESP32 microcontroller to monitor soil moisture levels and send the data to a Swift-based iOS application via Bluetooth. The iOS app connects to the ESP32 via Bluetooth, displays the soil moisture percentage, and provides recommendations for the best time to water the plant based on the moisture level.

## Components Used
- **ESP32 Microcontroller**
- **Soil Moisture Sensor**
- **Bluetooth LE (Low Energy) Communication**

## Project Structure

This repository is divided into two main parts:
1. **Arduino Code for ESP32**: This code runs on the ESP32 and reads the soil moisture sensor data. It then transmits the data over Bluetooth using the Bluetooth Low Energy (BLE) protocol.
2. **Swift Code for iOS App**: This code allows an iOS app to connect to the ESP32 via Bluetooth, display the moisture level, and notify the user when it’s time to water the plant.

---

## 1. Arduino Code for ESP32

### Overview
The Arduino code for the ESP32 reads the soil moisture level from a connected soil moisture sensor. The data is then sent to a paired iOS device via Bluetooth LE. 

### Installation
1. **Set up the ESP32 in Arduino IDE**:
   - Open the Arduino IDE.
   - Go to **File > Preferences**, and in the **Additional Boards Manager URLs** field, add `https://dl.espressif.com/dl/package_esp32_index.json`.
   - Go to **Tools > Board > Boards Manager**, search for `ESP32`, and install it.

2. **Code Overview**:
   - The code initializes the Bluetooth Low Energy (BLE) and sets up the soil moisture sensor to send data over Bluetooth.
   - It sends a JSON object containing the moisture level to the connected iOS device.


## 2. Swift Code for iOS App

### Overview
The Swift code for the iOS app manages the Bluetooth connection with the ESP32 device. It scans for nearby Bluetooth devices, connects to the ESP32, and retrieves the soil moisture data sent by the microcontroller. The app then evaluates the moisture percentage and provides recommendations for watering the plant.

1. **Key Features**:
  - Bluetooth Device Discovery: The app scans for nearby Bluetooth devices and displays a list of available peripherals.
  - Connection Management: Once a device is selected, the app connects to the ESP32 over Bluetooth LE and establishes a communication channel.
  - Data Retrieval: The app reads the soil moisture percentage sent by the ESP32 and displays it to the user.
  - Watering Recommendation: Based on the moisture percentage, the app provides advice on whether the plant needs watering.

2. **Code Overview**:
  - Bluetooth Setup: The CBCentralManager is used to scan for available Bluetooth devices. The app automatically connects to the ESP32 when found.
  - Service and Characteristic Discovery: Once the ESP32 is connected, the app discovers the services and characteristics offered by the ESP32, including the one that sends the moisture data.
  - Data Parsing and Display: The app receives the moisture data in JSON format, parses it, and uses it to update the user interface with relevant messages, such as whether the plant needs watering.
