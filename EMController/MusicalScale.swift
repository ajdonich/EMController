//
//  MusicalScale.swift
//  EMController
//
//  Created by Alfred J Donich on 2/14/24.
//

import Foundation

let SCALERANGE : (nlo: String, nhi: String) = (nlo: "-C4", nhi: "C7")

struct MusicalScale : Slidable {
    // Uses 12 TET freq ratio based on A440, see: (https://en.wikipedia.org/wiki/Equal_temperament)
    let notes : [String]  = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"]
    let ratio : Double = 1.0594630943592953

    var scale : [(mHz: Int32, name: String)] = [(mHz: 440000, name: "A4")]
    var degreemap : [Int] = Array(repeating: -1, count: 721)
    var scalemap : [Int32: Int] = [:]

    init() {
        var j: Int = 8
        var octave: Int = 4
        var freqHz: Double = 440.0
        while (scale.last!.name != SCALERANGE.nlo) {
            freqHz /= ratio
            let note = octave < 0 ? "-\(notes[j])\(-octave)" : "\(notes[j])\(octave)"
            scale.append((mHz: Int32(round(freqHz * 1e3)), name: note))
            
            if (j > 0) {
                j = (j-1) % notes.count
            } else {
                j = notes.count-1
                octave -= 1
            }
        }
        scale.append((mHz: 0, name: ""))

        j = 10
        octave = 4
        freqHz = 440.0
        scale.reverse()
        while (scale.last!.name != SCALERANGE.nhi) {
            freqHz *= ratio
            scale.append((mHz: Int32(round(freqHz * 1e3)), name: "\(notes[j])\(octave)"))
            j = (j+1) % notes.count
            if j == 0 { octave += 1 }
        }
        
        var prev: Int = -1
        for i in 0..<scale.count {
            scalemap[scale[i].mHz] = i
            let j = Int(round(Double(i) / Double(scale.count-1) * 720.0))
            degreemap[j] = i
            
            if i == 0 { continue }
            for jj in (prev+1)..<j {
                let t = Double(jj-prev) / Double(j-prev)
                degreemap[jj] = ilerp(i-1, i, t)
            }
            prev = j
        }
    }
    
    func ilerp(_ v0: Int, _ v1: Int, _ t: Double) -> Int {
        return Int(round((1.0 - t) * Double(v0) + t * Double(v1)))
    }
    
    func toHz(_ mHz: Int32) -> Double {
        return Double(mHz) * 1e-3
    }
    
    func tokHz(_ hz: Double) -> Double {
        return hz * 1e-3
    }
    
    func findSlot(mHz: Int32) -> Int {
        var lo = 0, hi = scale.count-1
        while lo < hi {
            let mid = Int(ceil(Float(lo+hi) / 2))
            if scale[mid].mHz == mHz { return mid }
            else if scale[mid].mHz < mHz { lo = mid }
            else { hi = mid-1 }
        }
        
        return lo
    }

    // Slidable protocol implementation
    public func getText(at value: Int32) -> String {
        if value < 0 { return "OFF" }

        let freq = toHz(value)
        if freq < 10.0 { return String(format: "%.2f", freq) }
        else if freq < 1000.0 { return String(format: "%.1f", freq) }
        else { return String(format: "%.2fK", tokHz(freq)) }
    }
    
    public func getAngle(at value: Int32) -> Double {
        if value < 0 { return TAU }
        if let ii = scalemap[value] { return Double(ii) * TAU / Double(scale.count-1) }
        else {  return Double(findSlot(mHz: value)) * TAU / Double(scale.count-1) }
    }
    
    public func getValue(at angle: Double) -> Int32 {
        let dslot = Int(round(angle * DEG_PER_RAD * 2.0))
        return scale[degreemap[dslot]].mHz
    }
    
    func nextValue(after value: Int32) -> Int32 {
        let ii = scalemap[value] != nil ? scalemap[value]! : findSlot(mHz: value)
        return scale[min(ii+1, scale.count-1)].mHz
    }
    
    func prevValue(before value: Int32) -> Int32 {
        let ii = scalemap[value] != nil ? scalemap[value]! - 1 : findSlot(mHz: value)
        return scale[max(ii, 0)].mHz
    }
}
