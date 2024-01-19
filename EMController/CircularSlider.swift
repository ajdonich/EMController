//
//  CircularSlider.swift
//  EMController
//
//  Created by Alfred J Donich on 12/3/23.
//

import SwiftUI
import Combine

let R90 = 0.5 * CGFloat.pi
let R270 = 1.5 * CGFloat.pi
let TAU = 2.0 * CGFloat.pi
let TAUEXP = TAU / (exp(TAU) - 1.0)
let RAD_PER_DEG = CGFloat.pi / 180.0

extension CGPoint {
    static func +(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x + b.x, y: a.y + b.y)
    }
    
    static func -(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x - b.x, y: a.y - b.y)
    }
            
    func toCGSize() -> CGSize {
        return CGSize(width: self.x, height: self.y)
    }
}

struct DragArc: Shape {
    var angle: Double

    // Hides angle (measured from 12 o'oclock) of circular arc.
    // Note: addArc counterintuitive due to LH system rotated R90
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        let rayhandle = center + CGPoint(x: 0.0, y: -radius)
        
        var path = Path()
        path.move(to: center)
        path.addLine(to: rayhandle)
        path.addArc(
            center: center, radius: radius,
            startAngle: Angle.radians(-R90),
            endAngle: Angle.radians(R270 + angle),
            clockwise: true
        )
        path.addLine(to: center)
        return path
    }
}

struct CircularSlider: View {
    @State private var angle: Double
    @State private var dtheta: Double
    @State private var buttonColors: (bwd: Color, stp: Color, fwd: Color)
    @State private var sweepTimer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    private var value: Binding<UInt32>
    private var range: (lo: UInt32, hi: UInt32)
    private var scalefcn: (Double) -> Double
    private var valuetext: String
    private var textcolor: Color
    private var expscale: Bool
    private var enabled: Bool
    
    init(value: Binding<UInt32>, in range: (lo: UInt32, hi: UInt32), text: String, color: Color, enabled: Bool, expscale: Bool=false) {
        let ratio = Double(value.wrappedValue - range.lo) / Double(range.hi - range.lo)
        self.value = value
        self.range = range
        self.valuetext = text
        self.textcolor = color
        self.enabled = enabled
        self.expscale = expscale
        
        if expscale {
            self.angle = log(ratio * TAU / TAUEXP + 1.0)
            self.scalefcn = { (exp($0) - 1.0) * TAUEXP }
        } else {
            self.angle = ratio * TAU
            self.scalefcn = {$0}
        }
        
        dtheta = 0.0
        buttonColors = (bwd: .gray, stp: .gray, fwd: .gray)
        sweepTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    }
    
    private enum Quadrant { case Q1, Q2, Q3, Q4 }
    private func getQuad(at theta: Double) -> Quadrant{
        switch theta {
        case 0..<R90: return Quadrant.Q1
        case R90..<CGFloat.pi: return Quadrant.Q2
        case CGFloat.pi..<R270: return Quadrant.Q3
        default: return Quadrant.Q4
        }
    }
    
    // Return offset to draggable slider handle. Note: radius
    // scale of 0.95 works in tandem w/scales 0.9 and 0.15 below
    private func hoffset(_ radius: CGFloat) -> CGSize {
        return CGPoint(x: 0.0, y: -radius * 0.95).applying(
            CGAffineTransform(rotationAngle: angle)).toCGSize()
    }
    
    private func buttonPushed(_ btype: ButtonType) {
        sweepTimer.upstream.connect().cancel()
        
        if !enabled { return }
        else if btype == ButtonType.BWD { dtheta -= RAD_PER_DEG * 0.1 }
        else if btype == ButtonType.FWD { dtheta += RAD_PER_DEG * 0.1 }
        else { dtheta = 0.0 }
        
        if abs(dtheta) < 0.000001 {
            UIApplication.shared.isIdleTimerDisabled = false
            buttonColors = (bwd: .blue, stp: .blue, fwd: .blue)
            dtheta = 0.0
        }
        else {
            UIApplication.shared.isIdleTimerDisabled = true
            sweepTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            buttonColors = dtheta < 0
                ? (bwd: .orange, stp: .blue, fwd: .blue)
                : (bwd: .blue, stp: .blue, fwd: .orange)
        }
    }
    
    // Update angle state, prevent update across Q1 <-> Q4
    private func updateAngle(to theta: CGFloat) -> Bool {
        var nxtangle = theta.truncatingRemainder(dividingBy: TAU)
        if theta < 0.0 { nxtangle += TAU }
        
        var status = false
        switch (getQuad(at: angle), getQuad(at: nxtangle)) {
        case (Quadrant.Q1, Quadrant.Q4): angle = 0.0
        case (Quadrant.Q4, Quadrant.Q1): angle = TAU
        default: angle = nxtangle; status = true
        }
        
        // Assign slider bound value (e.g. frequency) based on angle and range
        value.wrappedValue =  UInt32((scalefcn(angle) * Double(range.hi - range.lo) / TAU)) + range.lo
        return status
    }
    
    var body: some View {
        VStack {
            GeometryReader(content: { geometry in
                let rect = geometry.frame(in: .local)
                let radius = min(rect.width, rect.height) * 0.5
                
                ZStack {
                    Circle()              // Revealed BG color on drag
                        .fill(.blue)
                    
                    DragArc(angle: angle) // Removed FG color on drag
                        .fill(.gray)
                    
                    Circle()              // Solid inner/center FG color
                        .scale(0.9)
                        .fill(.black)
                    
                    Circle()              // Draggable slider handle
                        .scale(0.15)
                        .fill(.white.opacity(0.9))
                        .offset(hoffset(radius))
                        .gesture(DragGesture()
                            .onChanged({drag in
                                if !enabled { return }
                                buttonPushed(ButtonType.STOP) // Drag stops any auto sweep
                                
                                // Get angle to touch location in local coords
                                let vtouch = drag.location - CGPoint(x: rect.midX, y: rect.midY)
                                let drangle = atan2(vtouch.y, vtouch.x) + R90
                                _ = updateAngle(to: drangle)
                            })
                        )
                    
                    Text(valuetext)
                        .font(Font.custom("CourierNewPSMT", size: 64))
                        .foregroundColor(textcolor)
                }
            })
            
            PlayButtons(colors: buttonColors, pushCb: buttonPushed)
                .padding(.top)
                .onReceive(sweepTimer) { _ in
                    if abs(dtheta) < 0.000001 || !updateAngle(to: angle+dtheta) {
                        buttonPushed(ButtonType.STOP)
                    }
                }
                .onChange(of: enabled) {
                    buttonColors = (bwd: .blue, stp: .blue, fwd: .blue)
                    let ratio = Double(value.wrappedValue - range.lo) / Double(range.hi - range.lo)
                    if expscale { angle = log(ratio * TAU / TAUEXP + 1.0)
                    } else { angle = ratio * TAU }
                }
        }
    }
}

