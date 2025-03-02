import SwiftUI
import CoreBluetooth
import WebKit

// An enum for specific error types
enum BluetoothError: Error {
    case bluetoothIsOff
    case connectionFailed(String)
    case serviceDiscoveryFailed(String)
    case characteristicDiscoveryFailed(String)
    case readCharacteristicFailed(String)
    case invalidSensorData(String)
    case peripheralNotFound
    
    var localizedDescription: String {
        switch self {
        case .bluetoothIsOff:
            return "Bluetooth is off"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .serviceDiscoveryFailed(let reason):
            return "Failed to discover services: \(reason)"
        case .characteristicDiscoveryFailed(let reason):
            return "Failed to discover characteristics: \(reason)"
        case .readCharacteristicFailed(let reason):
            return "Failed to read data: \(reason)"
        case .invalidSensorData(let details):
            return "Received invalid data: \(details)"
        case .peripheralNotFound:
            return "No device found"
        }
    }
}

// The Bluetooth view model handles Bluetooth connection
class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var currentPeripheral: CBPeripheral?
    private var characteristics: [CBCharacteristic] = []
    
    @Published var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var moistureStatus: String = "Waiting for revceiving data..."
    @Published var backgroundColor: Color = .white
    @Published var moisturePercent: Int?
    @Published var showGif: Bool = false
    @Published var error: BluetoothError? {
        didSet {
            if let error = error {
                print("BLUETOOTH ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager?.stopScan()
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }
    
    private func discoverServices() {
        guard let peripheral = currentPeripheral else {
            self.error = .peripheralNotFound
            return
        }
        peripheral.discoverServices(nil)  // Discover all services
    }
    
    private func discoverCharacteristics(for service: CBService) {
        currentPeripheral?.discoverCharacteristics(nil, for: service)
    }
    
    private func parseReceivedData(_ data: String) {
        // Parse the JSON string
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let jsonObject = json as? [String: Any],
              let moisturePercent = jsonObject["moisturePercent"] as? Int else {
            self.error = .invalidSensorData("Invalid JSON format or missing moisture data.")
            return
        }
        
        DispatchQueue.main.async {
            self.moisturePercent = moisturePercent
            
            if moisturePercent < 44 {
                self.moistureStatus = "The plant is underwatered! Please water it soon."
                self.backgroundColor = Color.red
                self.showGif = false
            } else if moisturePercent <= 60 {
                self.moistureStatus = "This is the best condition for your plant! Keep it up."
                self.showGif = true
                self.backgroundColor = Color.white
            } else {
                self.moistureStatus = "The plant is overwatered! Reduce watering to avoid root rot."
                self.backgroundColor = Color.yellow
                self.showGif = false
            }
        }
    }
    
    // Attempt to recover from errors
    func recoverFromError() {
        guard let error = error else { return }
        
        switch error {
        case .bluetoothIsOff:
            // Maybe show settings instructions
            break
        case .connectionFailed:
            // Retry connection after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.centralManager?.scanForPeripherals(withServices: nil)
                self.error = nil
            }
        case .peripheralNotFound:
            // Restart scanning
            self.centralManager?.scanForPeripherals(withServices: nil)
            self.error = nil
        default:
            // For other errors, just clear and continue
            self.error = nil
        }
    }
}

// The Bluetooth central manager view model delegate methods
extension BluetoothViewModel: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        } else {
            self.error = .bluetoothIsOff
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)
            self.peripheralNames.append(peripheral.name ?? "Unnamed device")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.connectedPeripheral = peripheral
            self.peripheralNames = []
            self.currentPeripheral = peripheral
            peripheral.delegate = self
            self.discoverServices()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorDescription = error?.localizedDescription ?? "Unknown error"
        self.error = .connectionFailed(errorDescription)
    }
}

// The Bluetooth peripheral delegate methods
extension BluetoothViewModel: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            self.error = .serviceDiscoveryFailed(error.localizedDescription)
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                self.discoverCharacteristics(for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            self.error = .characteristicDiscoveryFailed(error.localizedDescription)
            return
        }
        
        if let characteristics = service.characteristics {
            self.characteristics = characteristics
            for characteristic in characteristics {
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("Subscribed to notifications for characteristic: \(characteristic.uuid)")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            self.error = .readCharacteristicFailed(error.localizedDescription)
            return
        }
        
        if let value = characteristic.value,
           let receivedString = String(data: value, encoding: .utf8) {
            self.parseReceivedData(receivedString)
        }
    }
}

// For displaying the GIF
struct GifView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif") {
            let gifData = try? Data(contentsOf: URL(fileURLWithPath: path))
            webView.load(gifData!, mimeType: "image/gif", characterEncodingName: "", baseURL: URL(fileURLWithPath: path))
        } else {
            webView.loadHTMLString("<p>Gif not found!</p>", baseURL: nil)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// Main view
struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if let connectedPeripheral = bluetoothViewModel.connectedPeripheral {
                    VStack {
                        if bluetoothViewModel.showGif {
                            GifView(gifName: "BestCondition") // Display the GIF
                                .frame(width: 200, height: 200) // Adjust size as needed
                                .padding()
                        } else {
                            Text(bluetoothViewModel.moistureStatus)
                                .font(.title2)
                                .bold()
                                .padding()
                                .foregroundColor(.white)
                        }
                        
                        if let moisturePercent = bluetoothViewModel.moisturePercent {
                            Text("Moisture Level: \(moisturePercent)%")
                                .font(.title3)
                                .padding()
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(bluetoothViewModel.showGif ? Color.clear : bluetoothViewModel.backgroundColor) // Clear background when GIF is shown
                    .edgesIgnoringSafeArea(.all)
                } else {
                    if let error = bluetoothViewModel.error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        List(bluetoothViewModel.peripheralNames.indices, id: \.self) { index in
                            let peripheralName = bluetoothViewModel.peripheralNames[index]
                            Text(peripheralName)
                                .onTapGesture {
                                    let peripheral = bluetoothViewModel.peripherals[index]
                                    bluetoothViewModel.connect(to: peripheral)
                                }
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
