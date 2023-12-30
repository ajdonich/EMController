//
//  ContentView.swift
//  EMController
//
//  Created by Alfred J Donich on 11/27/23.
//

import SwiftUI

struct ContentView: View {
    @State private var mHzFreq: UInt32 = 440000
    @State private var freqColor: Color = .orange
    @State private var mHzAck_a: UInt32 = 0
    private let hbTimer = Timer.publish(every: 3, on: .main, in: .common)
    private var ipcCtrl: IPCController = IPCController()

    init() {
        _ = hbTimer.connect()
    }
    
    func toString(_ mHz: UInt32) -> String {
        let freq = toHz(mHz)
        if freq < 10.0 { return String(format: "%.2f", freq) }
        else if freq < 1000.0 { return String(format: "%.1f", freq) }
        else { return String(format: "%.2fK", tokHz(freq)) }
    }
        
    func toHz(_ mHz: UInt32) -> Double {
        return Double(mHz) * 1e-3
    }
    
    func tokHz(_ hz: Double) -> Double {
        return hz * 1e-3
    }
    
    var body: some View {
        VStack {
            ZStack {
                CircularSlider(value: $mHzFreq, in: (lo: 250, hi: 880000), expscale: true)
                    .padding([.horizontal, .vertical])
                    .onChange(of: mHzFreq) {     // onSliderDragging
                        ipcCtrl.sendEMDriverMsg(mHz_a: mHzFreq)
                        freqColor = .orange
                    }
                    .onChange(of: mHzAck_a) {    // onHBFreqRsps
                        if mHzAck_a == mHzFreq { freqColor = .green }
                        else { ipcCtrl.sendEMDriverMsg(mHz_a: mHzFreq) }
                    }
                    .onReceive(hbTimer) { _ in   // onHB
                        ipcCtrl.sendEMDriverMsg(ACK: true)
                    }
                
                Text(toString(mHzFreq))
                    .font(Font.custom("CourierNewPSMT", size: 64))
                    .foregroundColor(freqColor)
            }
            
            Divider()
                .frame(height: 5.0)
                .overlay(.blue)
            
            Rectangle()
                .fill(.black)
            
            Text(ipcCtrl.description)
                .font(Font.custom("CourierNewPSMT", size: 20))
                .foregroundColor(ipcCtrl.status ? .green : .red)
        }
        .preferredColorScheme(.dark)
        .task {
            ipcCtrl.start(feedback_a: $mHzAck_a)
            ipcCtrl.receiveEMDriverMsg()
        }
    }
}

#Preview {
    ContentView()
}

