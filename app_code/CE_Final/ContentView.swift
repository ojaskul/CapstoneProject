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
    @State private var isEnabled = false
    
    var host: NWEndpoint.Host = "10.120.36.101"
    var port: NWEndpoint.Port = 1234
    
    var body: some View {
        //Button("button", action: initConnect).buttonStyle(.borderedProminent)
        Toggle(isOn: $isEnabled) {
            Label("Kitchen Light", systemImage: "lightbulb.circle")
        }
        .padding()
        .font(.system(size: 30))
        .frame(width: 350, height: 100)
        .onChange(of: isEnabled) { newValue in
            initConnect()
        }
    }
    
    func initConnect() {
        print("pressed")
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
        
        connection!.send(content:"hello".data(using: .utf8)!, completion: .contentProcessed({sendError in
            if let error = sendError {
                print("Unable to process and send the data: \(error)")
            } else {
                print("Data has been sent")
//                connection!.receiveMessage { (data, context, isComplete, error) in
//                    guard let myData = data else { return }
//                    print("Received message: " + String(decoding: myData, as: UTF8.self))
//                }
            }
        }))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
