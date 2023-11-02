//
//  ContentView.swift
//  CE_Final
//
//  Created by Isaac Stagg on 7/6/23.
//

import SwiftUI
import Network

struct ContentView: View {
    
    @State var connection: NWConnection?
    @State private var featherIsEnabled = false
    @State private var featherLoading = false
    
    @State private var tinyIsEnabled = false
    @State private var tinyLoading = false
    
    @State private var noResponse = false
    
    // 0 is 8266
    // 1 is 32
    
    var body: some View {
        VStack {
            HStack {
                Label("Kitchen Light", systemImage: "lightbulb.circle")
                    .font(.system(size: 23))
                if featherLoading {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                } else {
                    Toggle(isOn: $featherIsEnabled) {}
                        .alert("Device Unresponsive", isPresented: $noResponse) {
                            Button("Dismiss", role: .cancel) {}
                        }
                        .onChange(of: featherIsEnabled) { newValue in
                            sendMessage(msg: featherIsEnabled ? "tinys2 on" : "tinys2 off", device: 0)
                        }
                }
            }
            .padding(25)
        }
    }
    
    func createUDPConnection() {
        let hostStr = "192.168.1.237"
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
    
    func sendMessage(msg: String, device: Int) {
        if device == 0 {
            featherLoading = true
        } else if device == 1 {
            tinyLoading = true
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
                if device == 0 {
                    featherLoading = false
                    featherIsEnabled = !featherIsEnabled
                } else if device == 1 {
                    tinyLoading = false
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
                            if device == 0 {
                                featherLoading = false
                            } else if device == 1 {
                                tinyLoading = false
                            }
                        }
                        connection?.cancel()
                        connection = nil
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
