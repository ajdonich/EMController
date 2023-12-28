//
//  ContentView.swift
//  EMController
//
//  Created by Alfred J Donich on 11/27/23.
//

import SwiftUI

struct ContentView: View {
    @State private var frequency: Double = 440.0
//    private var ipcctrl: IPCController = IPCController()
    private var ipcctrl: BSDController = BSDController()
    private let statimer: Timer.TimerPublisher

    init() {
        statimer = Timer.publish(every: 3, on: .main, in: .common)
        _ = statimer.connect()
    }
    
    func toString(_ freq: Double) -> String {
        if freq < 1000 { return String(format: "%.1f", freq) }
        else { return String(format: "%.2fK", freq/1000) }
    }
    
    var body: some View {
        VStack {
            ZStack {
                CircularSlider(value: $frequency, in: (lo: 0.25, hi: 740.0))
                    .padding([.horizontal, .vertical])
                    .onChange(of: frequency) {
                        ipcctrl.sendEMDriverMsg(mHz_a: UInt32(frequency * 1e3))
                    }
                    .onReceive(statimer) { puboutput in
                        ipcctrl.sendEMDriverMsg(ACK: true)
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
            
            Text(ipcctrl.description)
                .font(Font.custom("CourierNewPSMT", size: 20))
                .foregroundColor(ipcctrl.status ? .green : .red)
//                .onTapGesture(count: 2) { ipcctrl.start() }
        }
        .preferredColorScheme(.dark)
        .task {
            await ipcctrl.receiveEMDriverMsg()
        }
    }
}

#Preview {
    ContentView()
}

