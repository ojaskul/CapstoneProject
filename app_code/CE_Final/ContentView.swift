//
//  ContentView.swift
//  CE_Final
//
//  Created by Isaac Stagg on 7/6/23.
//

import SwiftUI
import Network

var g_stoveVal = 0.0

struct ContentView: View {
    
    init() {
      UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }
    
    @State var connection: NWConnection?
    @State private var featherIsEnabled = false
    @State private var featherLoading = false
    
    @State private var tinyIsEnabled = false
    
    @State private var noResponse = false
    
    @State private var showingStoveDetails = false
    @State private var stoveIsEnabled = false
    @State private var stoveEspLoading = false
    @State private var stoveNoResponse = false
    
    @State private var refresh: Bool = false
    @State private var lumens: Decimal = 0
    
    // 0 is 8266 (brain)
    // 1 is 32 (light)
    // 2 is stove
    
    var body: some View {
        TabView {
            ZStack {
                LinearGradient(colors: [
                    Color(red: 77/255, green: 160/255, blue: 176/255),
                    Color(red: 211/255, green: 211/255, blue: 211/255)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.top)
                .edgesIgnoringSafeArea(.bottom)
                
                VStack(alignment: .leading) {
                    Text("Accessories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                        .padding(.leading, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), alignment: .leading, spacing: 16) {
                        AccessoryButton(accessory: "Kitchen", systemImage: "lightbulb", toggleState: featherIsEnabled, loading: featherLoading) {
                            featherIsEnabled.toggle()
                            sendMessage(msg: featherIsEnabled ? "tinys2 on" : "tinys2 off", targetDevice: 1)
                        }
                        .alert("Device Unresponsive", isPresented: $noResponse) {
                            Button("Dismiss", role: .cancel) {}
                        }
                        
                        AccessoryButton(accessory: "Stove", systemImage: "dial", toggleState: stoveIsEnabled, loading: stoveEspLoading) {
                            stoveIsEnabled = true
                            sendMessage(msg: "stove status", targetDevice: 2)
                        }
                        .alert("Device Not Responding", isPresented: $stoveNoResponse) {
                            Button("Dismiss", role: .cancel) {}
                        }
                        .popover(isPresented: $showingStoveDetails, content: {
                            StoveView(stoveValue: g_stoveVal, angleValue: (g_stoveVal / 100) * 360)
                                .onDisappear() {
                                    sendMessage(msg: "stove rotate \(g_stoveVal)")
                                    stoveIsEnabled = g_stoveVal > 1 ? true : false
                                }
                        })
                    }
                    .padding(15)
                    
                    Spacer()
                }
            }
            .colorScheme(.light)
            .tabItem() {
                Image(systemName: "lightbulb")
                Text("Accessories")
            }
            
            WeatherView(refreshWeather: $refresh, lum: $lumens)
                .tabItem() {
                    Image(systemName: "cloud")
                    Text("Weather")
                }
                .onAppear(perform: {
                    sendMessage(msg: "weather fetch")
                })
                .onChange(of: refresh) { oldValue, newValue in
                    print("refreshing...")
                    sendMessage(msg: "weather fetch")
                }
            
            AutomationView()
                .tabItem() {
                    Image(systemName: "bolt.badge.automatic.fill")
                    Text("Automations")
                }
        }
    }
    
    func createUDPConnection() {
        let hostStr = "10.120.38.225"
        let portInt = 1234

        let host: NWEndpoint.Host = .init(hostStr)
        let port: NWEndpoint.Port = .init(integerLiteral: UInt16(portInt))

        connection = NWConnection(host: host, port: port, using: .udp)
        
        connection!.stateUpdateHandler = { (newState) in
            switch (newState) {
                case .preparing:
                    print("Entered state: preparing")
                case .ready:
                    print("Entered state: ready")
                case .setup:
                    print("Entered state: setup")
                case .cancelled:
                    print("Entered state: cancelled")
                case .waiting:
                    print("Entered state: waiting")
                case .failed:
                    print("Entered state: failed")
                default:
                    print("Entered an unknown state")
            }
        }

        connection!.viabilityUpdateHandler = { (isViable) in
            if (isViable) {
                print("Connection is viable")
            } else {
                print("Connection is not viable")
            }
        }

        connection!.betterPathUpdateHandler = { (betterPathAvailable) in
            if (betterPathAvailable) {
                print("A better path is available")
            } else {
                print("No better path is available")
            }
        }

        connection!.start(queue: .global())
    }
    
    func sendMessage(msg: String, targetDevice: Int = 0) {
        if (targetDevice == 1) {
            featherLoading = true
        } else if (targetDevice == 2) {
            stoveEspLoading = true
        }
        
        // Check if the UDP connection is already created
        if connection == nil {
            createUDPConnection()
        }
        
        var timeoutTimer: DispatchSourceTimer? = nil
        timeoutTimer = DispatchSource.makeTimerSource(queue: .global())
        timeoutTimer!.schedule(deadline: .now() + 4)
        timeoutTimer?.setEventHandler {
            DispatchQueue.main.async {
                print("Timeout: No acknowledgment received")
                noResponse = true
                if (targetDevice == 1) {
                    featherLoading = false
                    featherIsEnabled = !featherIsEnabled
                } else if (targetDevice == 2) {
                    stoveEspLoading = false
                    stoveIsEnabled = !stoveIsEnabled
                }
            }
            connection?.cancel()
            connection = nil
            timeoutTimer = nil
        }
        timeoutTimer!.resume()

        // Send the message
        connection!.send(content: msg.data(using: .utf8)!, completion: .contentProcessed { sendError in
            if let error = sendError {
                print("Unable to process and send the data: \(error)")
            } else {
                print("Data has been sent")
                connection!.receiveMessage { (data, context, isComplete, error) in
                    timeoutTimer?.cancel()
                    timeoutTimer = nil
                    if let receiveError = error {
                        print("Error while receiving data: \(receiveError)")
                    } else if let receivedData = data {
                        let receivedString = String(decoding: receivedData, as: UTF8.self)
                        print("Received message: \(receivedString)")
                        DispatchQueue.main.async { // need a timeout
                            if (targetDevice == 1) {
                                featherLoading = false
                            } else if (targetDevice == 2) {
                                stoveEspLoading = false
                            }
                        }
                        connection?.cancel()
                        connection = nil
                        
                        if (receivedString.starts(with: "weather: ")) {
                            print(receivedString)
                            let temp = receivedString[receivedString.firstIndex(of: " ")!...]
                            lumens = pow(Decimal(Int(temp.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 225) - 225, 2) * 0.2
                        }
                        
                        if (targetDevice == 2) {
                            showingStoveDetails = true
                            if (receivedString.starts(with: "status")) {
                                let amt = Double(receivedString[receivedString.firstIndex(of: " ")!...].trimmingCharacters(in: .whitespacesAndNewlines))
                                g_stoveVal = (amt ?? 0) * 100 / 4076
                                print(g_stoveVal)
                            }
                        }
                    }
                }
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
