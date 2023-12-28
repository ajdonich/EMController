//
//  BSDController.swift
//  EMController
//
//  Created by Alfred J Donich on 12/26/23.
//

import Foundation


class BSDController : CustomStringConvertible {
    private let ESP_HOST: String = "192.168.0.16"
    private let UDP_PORT: UInt16 = 4645
    
    private var espaddr: sockaddr_in = sockaddr_in()
    private var clientSockFd: Int32 = -1
    var status: Bool = false
    
    init() {
        self.inetInit()
    }

    var description: String {
        if self.clientSockFd == -1 { return "ERROR" }
        return "udp://\(ESP_HOST):\(UDP_PORT)"        
    }
    
    func sendEMDriverMsg(mHz_a freq_a: UInt32 = 0, ACK ackbit: Bool = false) {
        let msg = EMDriverMsg(mHz_a: freq_a, ACK: ackbit)
        let msglen = MemoryLayout<EMDriverMsg.DataPacket>.size
        let nbytes = withUnsafePointer(to: msg.datapacket) { pdata in
            withUnsafePointer(to: &espaddr) { (espaddr_p1: UnsafePointer<sockaddr_in>) in
                espaddr_p1.withMemoryRebound(to: sockaddr.self, capacity: 1) { (p2: UnsafePointer<sockaddr>) in
                    return sendto(clientSockFd, pdata, msglen, 0, p2, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
        
        status = (nbytes == msglen)
        if (!status) {
            let desr = String(describing: strerror(errno))
            NSLog("sendto ERRNO %d: %s\n", "\(errno), \(desr)")
        }
    }

    func receiveEMDriverMsg() async {
        let msglen = MemoryLayout<EMDriverMsg.DataPacket>.size
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: msglen, alignment: 2)
        let nbytes = recvfrom(self.clientSockFd, buffer, msglen, 0, nil, nil)
        
        if (nbytes != msglen) {
            let desr = String(describing: strerror(errno))
            NSLog("sendto ERRNO %d: %s\n", "\(errno), \(desr)")
            return
        }
        
        let msg = EMDriverMsg()
        NSLog("%@\n", msg.description)
        
        await receiveEMDriverMsg()
    }
    
    private func inetInit() {
        // Create IPv4 UDP/datagram socket
        clientSockFd = socket(AF_INET , SOCK_DGRAM, 0)
        if (clientSockFd == -1) {
            let desr = String(describing: strerror(errno))
            NSLog("socket ERRNO %d: %s\n", "\(errno), \(desr)")
        }

        // Init the ESP address structure
        espaddr.sin_family = sa_family_t(AF_INET) // IPv4
        espaddr.sin_port = UDP_PORT.bigEndian     // Port in network byte order
        let aresult = ESP_HOST.withCString() { (esp_host: UnsafePointer<Int8>) in
            withUnsafeMutablePointer(to: &espaddr.sin_addr) { (psin_addr: UnsafeMutablePointer<in_addr>) in
                return inet_pton(AF_INET, esp_host, psin_addr)
            }
        }
        
        if (aresult == -1) {
            let desr = String(describing: strerror(errno))
            NSLog("inet_pton ERRNO %d: %s\n", "\(errno), \(desr)")
            close(self.clientSockFd);
            self.clientSockFd = -1
        }

        // Setup for nonblocking recvfrom calls
        //if (fcntl(cfd, F_SETFL, O_NONBLOCK) == -1) {
        //    let desr = String(describing: strerror(errno))
        //    NSLog("fcntl ERRNO %d: %s\n", "\(errno), \(desr)")
        //}
        
//        var claddr: sockaddr_in
//        claddr.sin_family = sa_family_t(AF_INET) // IPv4
//        claddr.sin_port = port.bigEndian         // Port in network byte order
//        claddr.sin_addr.s_addr = INADDR_ANY      // Wildcard address: 0.0.0.0

        // Bind to an explicitly chosen port
//        let bresult = withUnsafePointer(to: &espaddr) { (claddr_p1: UnsafePointer<sockaddr_in>) in
//            claddr_p1.withMemoryRebound(to: sockaddr.self, capacity: 1) { (p2: UnsafePointer<sockaddr>) in
//                return bind(clientSockFd, p2, socklen_t(MemoryLayout<sockaddr_in>.size))
//            }
//        }
//        
//        if (bresult == -1) {
//            let desr = String(describing: strerror(errno))
//            NSLog("bind ERRNO %d: %s\n", "\(errno), \(desr)")
//            close(clientSockFd);
//            self.clientSockFd = -1
//        }
    }
}

struct EMDriverMsg : CustomStringConvertible {
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
            self.freq_a = 0; self.freq_b = 0; self.freq_c = 0
            self.ackbit = false; self.msgid = 0
            withUnsafeMutablePointer(to: &self) { ptr in
                data.copyBytes(
                    to: UnsafeMutableBufferPointer(start: ptr, count: 1),
                    from: 0..<MemoryLayout<DataPacket>.size)
            }
        }

        init(_ buffer: UnsafeMutableRawPointer, _ msglen: Int) {
            self.init(Data(bytesNoCopy: buffer, count: msglen, deallocator: .none))
        }

        func toData() -> Data {
            var data = Data(capacity: MemoryLayout<DataPacket>.size)
            withUnsafePointer(to: self) { ptr in
                data.append(UnsafeBufferPointer(start: ptr, count: 1))
            }
            return data
        }
        
        var description: String {
            return "(\(self.ackbit), \(self.freq_a), \(self.freq_b), \(self.freq_c), \(self.msgid))"
        }
    }
    
    private static var _msgcounter: UInt32 = 0
    let datapacket: DataPacket

    init(mHz_a freq_a: UInt32 = 0, mHz_b freq_b: UInt32 = 0,
         mHz_c freq_c: UInt32 = 0, ACK ackbit: Bool = false) {
        let msgid = UInt16(EMDriverMsg._msgcounter + 1)
        EMDriverMsg._msgcounter = (EMDriverMsg._msgcounter + 1) % 65535
        self.datapacket = DataPacket(ackbit, msgid, freq_a, freq_b, freq_c)
    }

    init(_ data: Data) {
        self.datapacket = DataPacket(data)
    }

    func toData() -> Data {
        return self.datapacket.toData()
    }
    
    var description: String {
        return self.datapacket.description
    }
}
