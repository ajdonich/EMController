//
//  EMDriverMsg.swift
//  EMController
//
//  Created by Alfred J Donich on 12/28/23.
//

import Foundation


struct EMDriverMsg : CustomStringConvertible {
    private static var _msgcounter: UInt32 = 0
    let datapacket: DataPacket

    init(mHz_a freq_a: UInt32 = 0, mHz_b freq_b: UInt32 = 0,
         mHz_c freq_c: UInt32 = 0, ACK ackbit: Bool = false) {
        let msgid = UInt16(EMDriverMsg._msgcounter + 1)
        EMDriverMsg._msgcounter = (EMDriverMsg._msgcounter + 1) % 65535
        datapacket = DataPacket(ackbit, msgid, freq_a, freq_b, freq_c)
    }

    init(_ data: Data) {
        datapacket = DataPacket(data)
    }

    init(_ buffer: UnsafeMutableRawPointer, _ msglen: Int) {
        datapacket = DataPacket(Data(bytesNoCopy: buffer, count: msglen, deallocator: .none))
    }
    
    func toData() -> Data {
        return datapacket.toData()
    }
    
    var description: String {
        return datapacket.description
    }
    
    struct DataPacket {
        let ackbit: Bool
        let msgid: UInt16
        let freq_a, freq_b, freq_c: UInt32 // Millihertz

        init(_ ackbit: Bool, _ msgid: UInt16 = 0, _ freq_a: UInt32,
             _ freq_b: UInt32, _ freq_c: UInt32) {
            self.ackbit = ackbit; self.msgid = msgid
            self.freq_a = freq_a; self.freq_b = freq_b
            self.freq_c = freq_c;
        }
        
        init(_ data: Data) {
            self.ackbit = false; self.msgid = 0
            self.freq_a = 0; self.freq_b = 0; self.freq_c = 0
            withUnsafeMutablePointer(to: &self) { ptr in
                data.copyBytes(
                    to: UnsafeMutableBufferPointer(start: ptr, count: 1),
                    from: 0..<MemoryLayout<DataPacket>.size)
            }
        }

        func toData() -> Data {
            var data = Data(capacity: MemoryLayout<DataPacket>.size)
            withUnsafePointer(to: self) { ptr in
                data.append(UnsafeBufferPointer(start: ptr, count: 1))
            }
            return data
        }
        
        var description: String {
            return "(\(self.ackbit), \(self.msgid), \(self.freq_a), \(self.freq_b), \(self.freq_c))"
        }
    }
}
