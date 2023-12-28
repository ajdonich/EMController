//
//  CircularSlider.swift
//  EMController
//
//  Created by Alfred J Donich on 12/3/23.
//

import SwiftUI

let R90 = 0.5 * CGFloat.pi
let R270 = 1.5 * CGFloat.pi
let TAU = 2.0 * CGFloat.pi

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
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        let rayhandle = center + CGPoint(x: 0.0, y: -radius)
        
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
    private var value: Binding<Double>
    private var range: (lo: Double, hi: Double)
    
    init(value: Binding<Double>, in range: (lo: Double, hi: Double)) {
        self.angle = (value.wrappedValue - range.lo) * TAU / (range.hi - range.lo)
        self.value = value
        self.range = range
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
    
    var body: some View {
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
                            // Get angle to touch location in local coords
                            let vtouch = drag.location - CGPoint(x: rect.midX, y: rect.midY)
                            var drangle = atan2(vtouch.y, vtouch.x) + R90
                            if drangle < 0  { drangle += TAU }
                            
                            // Update angle state, prevent drag across Q1 <-> Q4
                            switch (getQuad(at: angle), getQuad(at: drangle)) {
                            case (Quadrant.Q1, Quadrant.Q4): angle = 0.0
                            case (Quadrant.Q4, Quadrant.Q1): angle = TAU
                            default: angle = drangle
                            }
                            
                            // Assign slider bound value (e.g. frequency) based on angle and range
                            value.wrappedValue = (angle * (range.hi - range.lo) / TAU) + range.lo
                        })
                    )
            }
        })
    }
}

