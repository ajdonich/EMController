//
//  IPCController.swift
//  EMController
//
//  Created by Alfred J Donich on 11/30/23.
//

import Foundation
import Network

struct UdpFreqMsg : CustomStringConvertible {
    var freq: Double
    var emid: UInt32
    var fcnt: UInt32

    init(_ freq: Double, _ emid: UInt32, _ fcnt: UInt32) {
        self.freq = freq
        self.emid = emid
        self.fcnt = fcnt
    }

    var description: String {
        return "(\(self.freq), \(self.emid), \(self.fcnt))"
    }

    func toData() -> Data {
        var data = Data(capacity: 16)
        withUnsafePointer(to: self.freq) { ptr in
            data.append(UnsafeBufferPointer(start: ptr, count: 1))
        }
        withUnsafePointer(to: self.emid) { ptr in
            data.append(UnsafeBufferPointer(start: ptr, count: 1))
        }
        withUnsafePointer(to: self.fcnt) { ptr in
            data.append(UnsafeBufferPointer(start: ptr, count: 1))
        }
        return data
    }
}

class IPCController : CustomStringConvertible {
    var UDP_HOST: NWEndpoint.Host = "192.168.0.16"
    var UDP_PORT: NWEndpoint.Port = 4645
    var status: Bool = true
    
    private static var fCount: UInt32 = 1
    private var connection: NWConnection? = nil
    
    init() {
        self.connection = NWConnection(host: UDP_HOST, port: UDP_PORT, using: .udp)
        self.connection?.start(queue: .global())
    }

    var description: String {
        if self.connection == nil { return "ERROR" }
        let parts =  self.connection!.parameters.debugDescription.split(separator: ",")
        return "\(parts[0])://\(self.connection!.endpoint.debugDescription)"
    }
    
    func sendToESP32(_ frequency: Double, emid: UInt32 = 1) {
        if self.connection == nil || self.connection?.state != NWConnection.State.ready {
            print("Dropping msg, UDP connection not ready, state: \(self.connection!.state)")
            status = false
            return
        }
        
        self.connection?.send(
            content: UdpFreqMsg(frequency, emid, IPCController.fCount).toData(),
            completion: NWConnection.SendCompletion.contentProcessed({ NWError in
                if (NWError == nil) { IPCController.fCount += 1; self.status = true }
                else { print("UDP send: \(frequency) Hz, error: \(NWError!)"); self.status = false }
            })
        )
    }
}
