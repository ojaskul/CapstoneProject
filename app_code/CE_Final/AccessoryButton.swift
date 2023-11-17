//
//  AccessoryButton.swift
//  CE_Final
//
//  Created by Isaac Stagg on 11/13/23.
//

import SwiftUI

struct AccessoryButton: View {
    var accessory: String
    var systemImage: String
    var toggleState: Bool
    var loading: Bool
    var onTapAction: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation {
                onTapAction()
                print("Tapped \(accessory)")
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if (loading) {
                        ProgressView()
                            .accentColor(Color.black)
                    } else {
                        Image(systemName: systemImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.primary)
                            .padding(.leading, 0)
                            .padding(.top, 5)
                    }
                    Spacer()
                }
                
                Spacer()
                
                Text(accessory)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerSize: CGSize(width: 12, height: 12))
                    .foregroundColor(toggleState ? Color.yellow.opacity(0.84) : Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.33))
                    .frame(height: 112)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(loading ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1))
        .padding(0)
    }
}
