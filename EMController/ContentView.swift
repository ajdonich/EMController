//
//  ContentView.swift
//  EMController
//
//  Created by Alfred J Donich on 11/27/23.
//

import SwiftUI

let BGRATIO = 0.6
let LTRATIO = 0.15

struct ContentView: View {
    @State private var uiEnabled: Bool = true
    @State private var mHzFreqs: [Int32] = [4400, 3300, 250]
    @State private var mHzAcks_a: [Int32] = [-1, -1, -1]
    @State private var freqTexts: [String]  = ["4.40", "3.30", "0.25"]
    @State private var freqColors: [Color] = [.gray, .gray, .gray]
    @State private var active: [Bool] = [true, false, false]
    
    private var mHzRange: (lo: Int32, hi: Int32) = (lo: 0, hi: 2093000)
    private let hbTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    private var ipcCtrl = IPCController()
    
    func toString(_ mHz: Int32) -> String {
        let freq = toHz(mHz)
        if freq < 10.0 { return String(format: "%.2f", freq) }
        else if freq < 1000.0 { return String(format: "%.1f", freq) }
        else { return String(format: "%.2fK", tokHz(freq)) }
    }
    
    func toHz(_ mHz: Int32) -> Double {
        return Double(mHz) * 1e-3
    }
    
    func tokHz(_ hz: Double) -> Double {
        return hz * 1e-3
    }
    
    var body: some View {
        GeometryReader { gp in
            VStack {
                ZStack {
                    CircularSlider(value: $mHzFreqs[0], in: mHzRange, text: freqTexts[0],
                                   color: freqColors[0], enabled: active[0], expscale: true)
                    .padding([.horizontal, .vertical])
                    .onChange(of: mHzFreqs[0]) {     // onSliderDragging
                        ipcCtrl.sendEMDriverMsg(mHz: mHzFreqs)
                        freqTexts[0] = toString(mHzFreqs[0])
                        freqColors[0] = .orange
                    }
                    
                    TapGlass(index: 0, enable: $active)
                }
                .frame(height: gp.size.height * (active[0] ? BGRATIO : LTRATIO))
                .animation(.easeInOut, value: active)
                
                Divider()
                    .frame(height: 5.0)
                    .overlay(.blue)
                
                ZStack {
                    CircularSlider(value: $mHzFreqs[1], in: mHzRange, text: freqTexts[1],
                                   color: freqColors[1], enabled: active[1], expscale: true)
                    .padding([.horizontal, .vertical])
                    .onChange(of: mHzFreqs[1]) {     // onSliderDragging
                        ipcCtrl.sendEMDriverMsg(mHz: mHzFreqs)
                        freqTexts[1] = toString(mHzFreqs[1])
                        freqColors[1] = .orange
                    }
                    
                    TapGlass(index: 1, enable: $active)
                }
                .frame(height: gp.size.height * (active[1] ? BGRATIO : LTRATIO))
                .animation(.easeInOut, value: active)
                
                Divider()
                    .frame(height: 5.0)
                    .overlay(.blue)
                
                ZStack {
                    CircularSlider(value: $mHzFreqs[2], in: mHzRange, text: freqTexts[2],
                                   color: freqColors[2], enabled: active[2], expscale: true)
                    .padding([.horizontal, .vertical])
                    .onChange(of: mHzFreqs[2]) {     // onSliderDragging
                        ipcCtrl.sendEMDriverMsg(mHz: mHzFreqs)
                        freqTexts[2] = toString(mHzFreqs[2])
                        freqColors[2] = .orange
                    }
                    
                    TapGlass(index: 2, enable: $active)
                }
                .frame(height: gp.size.height * (active[2] ? BGRATIO : LTRATIO))
                .animation(.easeInOut, value: active)
                                
                Text(ipcCtrl.description)
                    .font(Font.custom("CourierNewPSMT", size: 20))
                    .foregroundColor(ipcCtrl.status ? .green : .red)
            }
            .preferredColorScheme(.dark)
            .task {
                ipcCtrl.bindAckRsp(to: $mHzAcks_a)
            }
            .onReceive(hbTimer) { _ in    // heartbeat timer
                ipcCtrl.sendEMDriverMsg(ACK: true)
            }
            .onChange(of: mHzAcks_a) {    // heartbeat ack
                if !uiEnabled {
                    mHzFreqs = mHzAcks_a
                    mHzAcks_a = [-1, -1, -1]
                    freqColors = [.orange, .orange, .orange]
                    uiEnabled = true
                    return
                }
                
                var ackmatch = true
                for i in 0..<mHzAcks_a.count {
                    if mHzAcks_a[i] == mHzFreqs[i] { freqColors[i] = .green }
                    else { ackmatch = false }
                }
                if !ackmatch { ipcCtrl.sendEMDriverMsg(mHz: mHzFreqs) }
            }
        }
    }
}

struct TapGlass: View {
    private let index: Int
    private let enable: Binding<[Bool]>

    init(index: Int, enable: Binding<[Bool]>) {
        self.index = index
        self.enable = enable
    }
    
    var body: some View {
        if !enable.wrappedValue[index] {
            Rectangle()
                .fill(.black.opacity(0.15))
                .onTapGesture {
                    for i in 0..<enable.wrappedValue.count {
                        enable.wrappedValue[i] = (i == index)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
