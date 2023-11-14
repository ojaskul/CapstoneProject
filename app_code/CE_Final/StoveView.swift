//
//  StoveView.swift
//  CE_Final
//
//  Created by Isaac Stagg on 11/13/23.
//

import SwiftUI

struct Config {
    let minimumValue: CGFloat
    let maximumValue: CGFloat
    let totalValue: CGFloat
    let knobRadius: CGFloat
    let radius: CGFloat
}

struct StoveView: View {
    @State var stoveValue: CGFloat = 0.0
    @State var angleValue: CGFloat = 0.0
    let config = Config(minimumValue: 0.0, maximumValue: 40.0, totalValue: 40.0, knobRadius: 15.0, radius: 125.0)
    
    private func change(location: CGPoint) {
        let vector = CGVector(dx: location.x, dy: location.y)
        let angle = atan2(vector.dy - (config.knobRadius + 10), vector.dx - (config.knobRadius + 10)) + .pi/2.0
        
        let fixedAngle = angle < 0.0 ? angle + 2.0 * .pi : angle
        let value = fixedAngle / (2.0 * .pi) * config.totalValue
        
        if value >= config.minimumValue && value <= config.maximumValue {
            stoveValue = value
            g_stoveVal = value
            angleValue = fixedAngle * 180 / .pi
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.init(red: 34/255, green: 30/255, blue: 47/255))
                .edgesIgnoringSafeArea(.all)
            
            Circle()
                .frame(width: config.radius * 2, height: config.radius * 2)
                .scaleEffect(1.2)
                .foregroundColor(.primary)
                .colorInvert()
            
            Circle()
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [3, 23.18]))
                .frame(width: config.radius * 2, height: config.radius * 2)
            
            Circle()
                .trim(from: 0.0, to: stoveValue / config.totalValue)
                .stroke(stoveValue < config.maximumValue / 2 ? Color.blue : Color.red, lineWidth: 4)
                .frame(width: config.radius * 2, height: config.radius * 2)
                .rotationEffect(.degrees(-90))
            
            Circle()
                .fill(stoveValue < config.maximumValue / 2 ? Color.blue : Color.red)
                .frame(width: config.knobRadius * 2, height: config.knobRadius * 2)
                .padding(10)
                .offset(y: -config.radius)
                .rotationEffect(Angle.degrees(Double(angleValue)))
                .gesture(DragGesture(minimumDistance: 0.0)
                    .onChanged({ value in
                        change(location: value.location)
                    }))
            
            Text("\(String.init(format: "%.0f", stoveValue)) º")
                .font(.system(size: 60))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    StoveView()
}
