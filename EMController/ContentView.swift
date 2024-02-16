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
    @State private var mHzFreqs: [Int32] = [-1, -1, -1]
    @State private var mHzAcks_a: [Int32] = [-1, -1, -1]
    @State private var freqColors: [Color] = [.gray, .gray, .gray]
    @State private var active: [Bool] = [true, false, false]
    
    private let hbTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    private let slidable = MusicalScale()
    private var ipcCtrl = IPCController()
    
        
    var body: some View {
        GeometryReader { gp in
            VStack {
                ZStack {
                    CircularSlider(value: $mHzFreqs[0], in: slidable, color: freqColors[0], enabled: active[0])
                    .padding([.horizontal, .vertical])
                    .onChange(of: mHzFreqs[0]) {     // onSliderDragging
                        if mHzAcks_a[0] != mHzFreqs[0] {
                            ipcCtrl.sendEMDriverMsg(mHz: mHzFreqs)
                            freqColors[0] = .orange
                        }
                    }
                    
                    TapGlass(index: 0, enable: $active)
                }
                .frame(height: gp.size.height * (active[0] ? BGRATIO : LTRATIO))
                .animation(.easeInOut, value: active)
                
                Divider()
                    .frame(height: 5.0)
                    .overlay(.blue)
                
                ZStack {
                    CircularSlider(value: $mHzFreqs[1], in: slidable, color: freqColors[1], enabled: active[1])
                    .padding([.horizontal, .vertical])
                    .onChange(of: mHzFreqs[1]) {     // onSliderDragging
                        if mHzAcks_a[1] != mHzFreqs[1] {
                            ipcCtrl.sendEMDriverMsg(mHz: mHzFreqs)
                            freqColors[1] = .orange
                        }
                    }
                    
                    TapGlass(index: 1, enable: $active)
                }
                .frame(height: gp.size.height * (active[1] ? BGRATIO : LTRATIO))
                .animation(.easeInOut, value: active)
                
                Divider()
                    .frame(height: 5.0)
                    .overlay(.blue)
                
                ZStack {
                    CircularSlider(value: $mHzFreqs[2], in: slidable, color: freqColors[2], enabled: active[2])
                    .padding([.horizontal, .vertical])
                    .onChange(of: mHzFreqs[2]) {     // onSliderDragging
                        if mHzAcks_a[2] != mHzFreqs[2] {
                            ipcCtrl.sendEMDriverMsg(mHz: mHzFreqs)
                            freqColors[2] = .orange
                        }
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
                if mHzFreqs[0] == -1 {
                    for i in 0..<mHzAcks_a.count {
                        mHzFreqs[i] = mHzAcks_a[i]
                    }
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
