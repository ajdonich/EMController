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
let TAUINV = 1.0 / TAU
let TAUEXP = TAU / (exp(TAU) - 1.0)
let RAD_PER_DEG = CGFloat.pi / 180.0
let DEG_PER_RAD = 180.0 / CGFloat.pi

protocol Slidable {
    func getText(at value: Int32) -> String
    func getAngle(at value: Int32) -> Double
    func getValue(at angle: Double) -> Int32
    
    func nextValue(after value: Int32) -> Int32
    func prevValue(before value: Int32) -> Int32
}

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
    @State private var angle: Double = 0.0
    @State private var buttonColors: (bwd: Color, stp: Color, fwd: Color) = (bwd: .blue, stp: .blue, fwd: .blue)
    @State private var sweepTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var sweepTicks: Int = 0
    @State private var nticks: Int = 0

    private var value: Binding<Int32>
    private var slidable: Slidable
    private var textcolor: Color
    private var enabled: Bool

    init(value: Binding<Int32>, in slidable: Slidable, color: Color, enabled: Bool) {
        self.value = value
        self.slidable = slidable
        self.textcolor = color
        self.enabled = enabled
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
        else if btype == ButtonType.FWD { sweepTicks += 1 }
        else if btype == ButtonType.BWD { sweepTicks -= 1 }
        else { sweepTicks = 0 }
                
        if sweepTicks == 0 {
            UIApplication.shared.isIdleTimerDisabled = false
            buttonColors = (bwd: .blue, stp: .blue, fwd: .blue)
        }
        else {
            UIApplication.shared.isIdleTimerDisabled = true
            sweepTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            buttonColors = sweepTicks < 0 
                ? (bwd: .orange, stp: .blue, fwd: .blue)
                : (bwd: .blue, stp: .blue, fwd: .orange)
        }
    }
    
    // Update angle state, prevent update across Q1 <-> Q4
    private func updateAngle(to theta: CGFloat) {
        var nxtangle = theta.truncatingRemainder(dividingBy: TAU)
        if theta < 0.0 { nxtangle += TAU }
        
        switch (getQuad(at: angle), getQuad(at: nxtangle)) {
        case (Quadrant.Q1, Quadrant.Q4): angle = 0.0
        case (Quadrant.Q4, Quadrant.Q1): angle = TAU
        default: angle = nxtangle
        }
                
        // Assign slider bound value (e.g. frequency) based on angle and range
        value.wrappedValue = slidable.getValue(at: angle)
    }
    
    var body: some View {
        VStack {
            GeometryReader(content: { geometry in
                let rect = geometry.frame(in: .local)
                let radius = min(rect.width, rect.height) * 0.5
                
                ZStack {
                    if enabled {
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
                                    updateAngle(to: drangle)
                                })
                            )
                    }
                    
                    Text(slidable.getText(at: value.wrappedValue))
                        .font(Font.custom("CourierNewPSMT", size: 64))
                        .foregroundColor(textcolor)
                }
            })
            .onChange(of: value.wrappedValue) {
                updateAngle(to: slidable.getAngle(at: value.wrappedValue))
            }

            if enabled {
                PlayButtons(colors: buttonColors, pushCb: buttonPushed)
                    .padding(.top)
                    .onReceive(sweepTimer) { _ in
                        if sweepTicks != 0 {
                            nticks += 1
                            if Double(nticks) * 0.1 > 1.0 / Double(abs(sweepTicks)) {
                                let vcurr = value.wrappedValue
                                value.wrappedValue = sweepTicks > 0
                                    ? slidable.nextValue(after: value.wrappedValue)
                                    : slidable.prevValue(before: value.wrappedValue)
                                
                                if vcurr == value.wrappedValue { buttonPushed(ButtonType.STOP) }
                                nticks = 0
                            }
                        }
                        else { buttonPushed(ButtonType.STOP) }
                    }
            }
        }
    }
}

