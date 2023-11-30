//
//  WeatherView.swift
//  CE_Final
//
//  Created by Isaac Stagg on 11/13/23.
//

import SwiftUI

struct SensorDataRow: View {
    let label: String
    let value: String
    let color: Color
    let image: String
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: image)
                        .foregroundColor(.white)
                        .font(.title)
                )
            VStack(alignment: .leading) {
                Text(label)
                    .font(.headline)
                Text(value)
                    .font(.title2)
                    .fontWeight(.light)
            }
        }
        .padding(.vertical, 8)
    }
}

struct WeatherView: View {
    @Binding var refreshWeather: Bool
    @Binding var lum: Decimal
    
    var body: some View {
        List {
            SensorDataRow(label: "Ambient Light", value: "\(Int(truncating: NSDecimalNumber(decimal: lum))) lumens", color: .red, image: "rays")
            
            SensorDataRow(label: "Temperature", value: "69 ºF", color: .blue, image: "heat.waves")
            
            SensorDataRow(label: "Pressure", value: "1023 hPa", color: .green, image: "icloud.and.arrow.down")
            
            SensorDataRow(label: "CO₂ Concentration", value: "816 ppm", color: .yellow, image: "air.purifier")
            
            SensorDataRow(label: "Humidity", value: "36%", color: .purple, image: "humidity")
        }
        .scrollContentBackground(.hidden)
        .background(LinearGradient(colors: [Color(red: 77/255, green: 160/255, blue: 176/255), Color(red: 211/255, green: 211/255, blue: 211/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .refreshable {
            refreshWeather.toggle()
        }
    }
}

#Preview {
    WeatherView(refreshWeather: Binding.constant(false), lum: Binding.constant(Decimal(5577.8)))
}
