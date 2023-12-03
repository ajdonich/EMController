//
//  ContentView.swift
//  EMController
//
//  Created by Alfred J Donich on 11/27/23.
//

import SwiftUI

struct ContentView: View {
    @State private var frequency: Double = 440.0
    private var ipcctrl: IPCController = IPCController()
    
    func toString(_ freq: Double) -> String {
        if freq < 1000 { return String(format: "%.1f", freq) }
        else { return String(format: "%.2fK", freq/1000) }
    }
    
    var body: some View {
        VStack {
            ZStack {
                CircularSlider(vbind: $frequency, in: (lo: 1.5, hi: 5000.0))
                    .padding([.horizontal, .vertical])
                    .onChange(of: frequency) {
                        ipcctrl.sendToESP32(frequency)
                    }
                
                Text(toString(frequency))
                    .font(Font.custom("CourierNewPSMT", size: 64))
                    .foregroundColor(.orange)
            }
            
            Divider()
                .frame(height: 5.0)
                .overlay(.blue)
                
            Rectangle()
                .fill(.black)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}

