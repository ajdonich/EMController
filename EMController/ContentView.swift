//
//  ContentView.swift
//  EMController
//
//  Created by Alfred J Donich on 11/27/23.
//

import SwiftUI

let TAU = 2.0 * CGFloat.pi
let R270 = 1.5 * CGFloat.pi

extension CGPoint {
    static func +(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x + b.x, y: a.y + b.y)
    }

    static func -(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x - b.x, y: a.y - b.y)
    }
}

func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    return a + (t * (b - a))
}

func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
    return CGPoint(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t))
}

func linspace(start: Double, stop: Double, num: UInt16, endpoint: Bool = true) -> [Double] {
    var array: [Double] = []
    let dist = endpoint ? Double(num-1) : Double(num)
    for n in 0...(endpoint ? num : num-1) {
        array.append(lerp(start, stop, Double(n) / dist))
    }
    return array
}

struct RegPolygon: Shape {
    let startAngle = Angle.radians(-Double.pi * 0.5)
    
    var nsteps: UInt16
    var angle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        
        path.move(to: center)
        path.addLine(to: center + CGPoint(x: 0.0, y: -radius))
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: Angle.radians(R270 + angle),
            clockwise: true
        )
        path.addLine(to: center)
        return path
    }
}

struct ContentView: View {
    @State private var frequency: Double = 0.0
    @State private var angle: Double = 0.0
    
    var ipcctrl: IPCController = IPCController()
    
    func toString(_ freq: Double) -> String {
        if freq < 1000 { return String(format: "%.1f", freq) }
        else { return String(format: "%.2fK", freq/1000) }
    }
    
    var body: some View {
        VStack {
            GeometryReader(content: { geometry in
                ZStack {
                    Circle()
                        .fill(.blue)
                        .padding([.horizontal, .vertical])

                    RegPolygon(nsteps: 12, angle: angle)
                        .fill(.gray)
                        .padding([.horizontal, .vertical])
                        .gesture(DragGesture()
                            .onChanged({value in
                                let rect = geometry.frame(in: .local)
                                let ray = value.location - CGPoint(x: rect.midX, y: rect.midY)
                                let drangle = atan2(ray.y, ray.x) + (CGFloat.pi * 0.5)
                                if drangle < 0 && angle < Double.pi { angle = 0.0 }
                                else if drangle > 0 && drangle < CGFloat.pi && angle > R270 { angle = TAU }
                                else { angle = drangle < 0 ? drangle + TAU : drangle }
                                frequency = angle * 5000 / TAU
                                ipcctrl.sendToESP32(frequency)
                                //print(angle * 180 / CGFloat.pi, ":", drangle * 180 / CGFloat.pi, ":", ray)
                            }))
                    
                    Circle()
                        .scale(0.8)
                        .fill(.black)
                    
                    Text(toString(frequency))
                        .font(Font.custom("CourierNewPSMT", size: 64))
                        .foregroundColor(.orange)
                }
            })
            
            Divider()
                .frame(height: 5.0)
                .overlay(.blue)
                
            Rectangle()
                .fill(.black)
        }
        .preferredColorScheme(.dark)
        .foregroundColor(.black)
    }
    
//    var body: some View {
//        VStack {
//            GeometryReader(content: { geometry in
//                ZStack {
//                    Rectangle()
//                        .fill(.teal)
//                    RegPolygon(nsteps: 12, angle: angle)
//                        .scaledToFit()
//                        .padding([.horizontal, .vertical])
//                        .gesture(DragGesture()
//                            .onChanged({value in
//                                let rect = geometry.frame(in: .local)
//                                let center = CGPoint(x: rect.midX, y: rect.midY)
//                                print(value.location - center)
//                            }))
//                }
//            })
//            
//            Text("angle: \(Int(angle))")
////                .padding(.vertical)
//            Slider(value: $angle, in: 0...360)
//                .onChange(of: deg) { angle = deg * Double.pi / 180 }
//                .padding(.horizontal)
//            Rectangle()
//        }
//    }

//    var body: some View {
//        VStack {
//            ZStack {
//                Circle()
//                    .padding(.horizontal)
//                Circle()
//                    .scale(0.95)
//                    .padding(.horizontal)
//                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
//                Circle()
//                    .scale(0.8)
//                    .padding(.horizontal)
//            }
//            RoundedRectangle(cornerRadius: 10)
//                .padding(.horizontal)
//        }
//        
//    }
    
//    var body: some View {
//        Form {
//            Section(header: Text("EMController")) {
//                Text("Frequency: \(frequency, specifier: "%.2f") Hz")
//                    .font(.body)
//                HStack {
//                    Slider(value: $frequency, in: 1...100, step: 0.25)
//                    .onChange(of: frequency) { ipcctrl.sendToESP32(frequency) }
//                }
//            }
//        }
//    }
}

#Preview {
    ContentView()
}


//for i in 0..<thetas.count {
//    let ctheta: Double = cos(thetas[i])
//    let stheta: Double = sin(thetas[i])
//    
//    let x0 = 0.0
//    let y0 = -5.0
//    
//    let x = x0 * ctheta - y0 * stheta
//    let y = x0 * stheta + y0 * ctheta
//    
//    print("\(thetas[i] * 180.0 / Double.pi) : (\(ctheta), \(stheta)) : (\(x), \(y))")
//}

//struct RectTest: Shape {
//    var grect: CGRect?
//      
//    func path(in rect: CGRect) -> Path {
//        if grect != nil {
//            print("RectTest: \(grect!)")
//            return Path(roundedRect: grect!, cornerRadius: 2.0)
//        }
//        return Path(roundedRect: rect, cornerRadius: 2.0)
//    }
//}
