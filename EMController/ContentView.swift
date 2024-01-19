//
//  ContentView.swift
//  EMController
//
//  Created by Alfred J Donich on 11/27/23.
//

import SwiftUI

struct ContentView: View {
    @State private var mHzFreq: UInt32 = 250
    @State private var freqText: String = "0.25"
    @State private var freqColor: Color = .gray
    @State private var mHzAck_a: UInt32 = 0
    @State private var uiEnabled: Bool = false
    
    private var mHzRange: (lo: UInt32, hi: UInt32) = (lo: 250, hi: 880000)
    private let hbTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    private var ipcCtrl = IPCController()
    
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
                CircularSlider(value: $mHzFreq, in: mHzRange, text: freqText,
                    color: freqColor, enabled: uiEnabled, expscale: true)
                    .padding([.horizontal, .vertical])
                    .onChange(of: mHzFreq) {     // onSliderDragging
                        ipcCtrl.sendEMDriverMsg(mHz_a: mHzFreq)
                        freqText = toString(mHzFreq)
                        freqColor = .orange
                    }
                    .onChange(of: mHzAck_a) {    // onHBRespsonse
                        if !uiEnabled { mHzFreq = mHzAck_a; mHzAck_a = 0 }
                        else if mHzAck_a == mHzFreq { freqColor = .green }
                        else { ipcCtrl.sendEMDriverMsg(mHz_a: mHzFreq) }
                        uiEnabled = true
                    }
                    .onReceive(hbTimer) { _ in   // onHB
                        ipcCtrl.sendEMDriverMsg(ACK: true)
                    }
            }
            
            Divider()
                .frame(height: 5.0)
                .overlay(.blue)
            
            Rectangle()
                .fill(.black)
                .frame(height: 250)
            
            Text(ipcCtrl.description)
                .font(Font.custom("CourierNewPSMT", size: 20))
                .foregroundColor(ipcCtrl.status ? .green : .red)
        }
        .preferredColorScheme(.dark)
        .task {
            ipcCtrl.bindAckRsp(to: $mHzAck_a)
        }
    }
}

#Preview {
    ContentView()
}
