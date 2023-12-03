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
    
    static func *(_ a: CGPoint, _ b: Double) -> CGPoint {
        return CGPoint(x: a.x * b, y: a.y * b)
    }
    
    static func /(_ a: CGPoint, _ b: Double) -> CGPoint {
        return CGPoint(x: a.x / b, y: a.y / b)
    }
    
    func mag() -> CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }
    
    func normalized() -> CGPoint {
        return self / self.mag()
    }
    
    func toCGSize() -> CGSize {
        return CGSize(width: self.x, height: self.y)
    }
}

struct DragArc: Shape {
    var angle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        let rayhandle = center + CGPoint(x: 0.0, y: -radius)
        
        path.move(to: center)
        path.addLine(to: rayhandle)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle.radians(-Double.pi * 0.5),
            endAngle: Angle.radians(R270 + angle),
            clockwise: true
        )
        path.addLine(to: center)
        return path
    }
}

struct CircularSlider: View {
    @State private var angle: Double
    private var vbind: Binding<Double>
    private var range: (lo: Double, hi: Double)

    init(vbind: Binding<Double>, in range: (lo: Double, hi: Double)) {
        self.angle = (vbind.wrappedValue - range.lo) * TAU / (range.hi - range.lo)
        self.vbind = vbind
        self.range = range
    }
                        
    private enum Quadrant { case Q1, Q2, Q3, Q4 }
    private func getQuad(at theta: Double) -> Quadrant{
        switch theta {
        case 0..<R90: return Quadrant.Q1
        case R90..<Double.pi: return Quadrant.Q2
        case Double.pi..<R270: return Quadrant.Q3
        default: return Quadrant.Q4
        }
    }
    
    // Note: radius scale of 0.95 works in tandem w/scales 0.9 and 0.15 below
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
                
                Circle()              // Solid inner FG color
                    .scale(0.9)
                    .fill(.black)
                
                Circle()              // Draggable slider handle
                    .scale(0.15)
                    .fill(.white.opacity(0.9))
                    .offset(hoffset(radius))
                    .gesture(DragGesture()
                        .onChanged({value in
                            let ray = value.location - CGPoint(x: rect.midX, y: rect.midY)
                            var drangle = atan2(ray.y, ray.x) + (CGFloat.pi * 0.5)
                            drangle = drangle < 0 ? drangle + TAU : drangle
                            let qfromto = (getQuad(at: angle), getQuad(at: drangle))
                            
                            switch qfromto {
                            case (Quadrant.Q1, Quadrant.Q4): angle = 0.0
                            case (Quadrant.Q4, Quadrant.Q1): angle = TAU
                            default: angle = drangle
                            }
                            
                            vbind.wrappedValue = (angle * (range.hi - range.lo) / TAU) + range.lo
                        }))

            }
        })
    }
}

