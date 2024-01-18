//
//  PlayButtons.swift
//  EMController
//
//  Created by Alfred J Donich on 1/17/24.
//

import SwiftUI

enum ButtonType { case BWD, STOP, FWD}

struct PlayButtons: View {
    private var buttonColors: (bwd: Color, stp: Color, fwd: Color)
    private var buttonPushCb: (ButtonType) -> Void
    
    init(colors: (bwd: Color, stp: Color, fwd: Color), pushCb: @escaping (ButtonType) -> Void) {
        buttonColors = colors
        buttonPushCb = pushCb
    }
        
    var body: some View {
        HStack {
            Button(action: { buttonPushCb(ButtonType.BWD) }) {
                Image(systemName: "backward.circle")
                    .foregroundColor(buttonColors.bwd)
                    .font(.system(size: 64))
            }
            
            Button(action: { buttonPushCb(ButtonType.STOP) }) {
                Image(systemName: "stop.circle")
                    .foregroundColor(buttonColors.stp)
                    .font(.system(size: 64))
            }
            .padding(.horizontal)
            
            Button(action: { buttonPushCb(ButtonType.FWD) }) {
                Image(systemName: "forward.circle")
                    .foregroundColor(buttonColors.fwd)
                    .font(.system(size: 64))
            }
        }
    }
}
