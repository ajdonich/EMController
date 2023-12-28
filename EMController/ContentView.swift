//
//  ContentView.swift
//  EMController
//
//  Created by Alfred J Donich on 11/27/23.
//

import SwiftUI

struct ContentView: View {
    @State private var frequency: Double = 440.0
    @State private var freqcolor: Color = .orange
    @State private var mHzAck_a: UInt32 = 0
    private let hbtimer = Timer.publish(every: 3, on: .main, in: .common)
    private var ipcctrl: IPCController = IPCController()

    init() {
        _ = hbtimer.connect()
    }
    
    func toString(_ freq: Double) -> String {
        if freq < 1000 { return String(format: "%.1f", freq) }
        else { return String(format: "%.2fK", freq/1000) }
    }
    
    func mHz(_ hz: Double) -> UInt32 {
        return UInt32(hz * 1e3)
    }
    
    var body: some View {
        VStack {
            ZStack {
                CircularSlider(value: $frequency, in: (lo: 0.25, hi: 740.0))
                    .padding([.horizontal, .vertical])
                    .onChange(of: frequency) {
                        ipcctrl.sendEMDriverMsg(mHz_a: mHz(frequency))
                        freqcolor = .orange
                    }
                    .onChange(of: mHzAck_a) {
                        if mHzAck_a == mHz(frequency) { freqcolor = .green }
                        else { ipcctrl.sendEMDriverMsg(mHz_a: mHz(frequency)) }
                    }
                    .onReceive(hbtimer) { _ in
                        ipcctrl.sendEMDriverMsg(ACK: true)
                    }
                
                Text(toString(frequency))
                    .font(Font.custom("CourierNewPSMT", size: 64))
                    .foregroundColor(freqcolor)
            }
            
            Divider()
                .frame(height: 5.0)
                .overlay(.blue)
            
            Rectangle()
                .fill(.black)
            
            Text(ipcctrl.description)
                .font(Font.custom("CourierNewPSMT", size: 20))
                .foregroundColor(ipcctrl.status ? .green : .red)
        }
        .preferredColorScheme(.dark)
        .task {
            ipcctrl.start(feedback_a: $mHzAck_a)
            ipcctrl.receiveEMDriverMsg()
        }
    }
}

#Preview {
    ContentView()
}

