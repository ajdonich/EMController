//
//  BSDController.swift
//  EMController
//
//  Created by Alfred J Donich on 12/26/23.
//

import Foundation

// This class performs the same UDP IPC exchange with the ESP32 as
// IPCController does, but using the POSIX level network system calls

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
    
    func sendEMDriverMsg(mHz freqs: [Int32] = [-1,-1,-1], ACK ackbit: Bool = false) {
        let msg = EMDriverMsg(mHz: freqs, ACK: ackbit)
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
        let msg = EMDriverMsg(buffer, nbytes)
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
