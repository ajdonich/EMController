//
//  IPCController.swift
//  EMController
//
//  Created by Alfred J Donich on 11/30/23.
//

import Foundation
import Network


class IPCController : CustomStringConvertible {
    var ESP_HOST: NWEndpoint.Host = "192.168.0.16"
    var UDP_PORT: NWEndpoint.Port = 4645
    //var TCP_PORT: NWEndpoint.Port = 4647
    var status: Bool = false
    
    private static var fCount: UInt32 = 1
    private var sendconn: NWConnection? = nil
    private var recvconn: NWConnection? = nil
    private var listener: NWListener? = nil

    var description: String {
        if self.sendconn == nil { return "ERROR" }
        let parts =  self.sendconn!.parameters.debugDescription.split(separator: ",")
        return "\(parts[0])://\(self.sendconn!.endpoint.debugDescription)"
    }
    
    init() {
        self.start()
    }

    func start() {
        NSLog("IPCController::start connection")
        //self.sendconn = NWConnection(host: ESP_HOST, port: TCP_PORT, using: .tcp)
        self.sendconn = NWConnection(host: ESP_HOST, port: UDP_PORT, using: .udp)
        self.sendconn?.stateUpdateHandler = self.stateHandler(state:)
        self.sendconn?.start(queue: .global())

//        self.recvconn = NWConnection(host: "192.168.0.17", port: UDP_PORT, using: .udp)
//        self.recvconn?.stateUpdateHandler = self.recvStateHandler(state:)
//        self.awaitReceive(connection: self.recvconn!)
//        self.recvconn?.start(queue: .global())
        
        let params = NWParameters.udp
        params.requiredLocalEndpoint = .hostPort(host: "192.168.0.17", port: UDP_PORT)
        params.allowFastOpen = true

        self.listener = try? NWListener(using: params)
        self.listener = try? NWListener(using: .udp)
        self.listener?.newConnectionHandler = { recvconn in
            recvconn.start(queue: .global())
            self.awaitReceive(connection: recvconn)
        }
        self.listener?.start(queue: .global())
    }
    
    func cancel() {
        NSLog("IPCController::cancel connection")
        self.sendconn?.cancel()
        self.sendconn = nil
    }
    
    private func stateHandler(state: NWConnection.State) {
        switch state {
        case .setup, .preparing, .ready: 
            break
        case .waiting(let error):
            NSLog("stateHandler::waiting: %@", "\(error)")
        case .failed(let error):
            NSLog("stateHandler::failed: %@", "\(error)")
            self.cancel()
        case .cancelled:
            NSLog("stateHandler::cancelled")
            self.cancel()
        @unknown default:
            break
        }
    }

    private func recvStateHandler(state: NWConnection.State) {
        switch state {
        case .setup, .preparing, .ready:
            break
        case .waiting(let error):
            NSLog("stateHandler::waiting: %@", "\(error)")
        case .failed(let error):
            NSLog("stateHandler::failed: %@", "\(error)")
            self.cancel()
        case .cancelled:
            NSLog("stateHandler::cancelled")
            self.cancel()
        @unknown default:
            break
        }
    }
    
    private func awaitReceive(connection recvconn: NWConnection) {
        recvconn.receive(
            minimumIncompleteLength: 1, maximumLength: 65536,
            completion: { content, contentContext, isComplete, error in
                print("Got to here")
                if let data = content, !data.isEmpty {
                    //NSLog("did receive, data: %@", data as NSData)
                    NSLog(EMDriverMsg(data).description)
                }
                if let error = error {
                    NSLog("did receive, error: %@", "\(error)")
                    self.cancel()
                    return
                }
                if isComplete {
                    NSLog("did receive, EOF")
                    self.cancel()
                    return
                }
                self.awaitReceive(connection: recvconn)
            })
    }
            
    func sendEMDriverMsg(mHz_a freq_a: UInt32 = 0, ACK ackbit: Bool = false) {
        self.sendconn?.send(
            content: EMDriverMsg(mHz_a: freq_a, ACK: ackbit).toData(),
            completion: NWConnection.SendCompletion.contentProcessed({NWError in
                if (NWError != nil) { print("Network send error: \(NWError!)") }
            })
        )
    }
}

//struct EMDriverMsg : CustomStringConvertible {
//    struct DataPacket {
//        let ackbit: Bool
//        let msgid: UInt16
//        let freq_a, freq_b, freq_c: UInt32 // Millihertz
//
//        init(_ ackbit: Bool, _ msgid: UInt16 = 0, _ freq_a: UInt32,
//             _ freq_b: UInt32, _ freq_c: UInt32) {
//            self.ackbit = ackbit; self.msgid = msgid
//            self.freq_a = freq_a; self.freq_b = freq_b
//            self.freq_c = freq_c;
//        }
//        
//        init(_ data: Data) {
//            self.freq_a = 0; self.freq_b = 0; self.freq_c = 0
//            self.ackbit = false; self.msgid = 0
//            withUnsafeMutablePointer(to: &self) { ptr in
//                data.copyBytes(
//                    to: UnsafeMutableBufferPointer(start: ptr, count: 1),
//                    from: 0..<MemoryLayout<DataPacket>.size)
//            }
//        }
//
//        func toData() -> Data {
//            var data = Data(capacity: MemoryLayout<DataPacket>.size)
//            withUnsafePointer(to: self) { ptr in
//                data.append(UnsafeBufferPointer(start: ptr, count: 1))
//            }
//            return data
//        }
//        
//        var description: String {
//            return "(\(self.ackbit), \(self.freq_a), \(self.freq_b), \(self.freq_c), \(self.msgid))"
//        }
//    }
//    
//    private static var _msgcounter: UInt32 = 0
//    let datapacket: DataPacket
//
//    init(mHz_a freq_a: UInt32 = 0, mHz_b freq_b: UInt32 = 0,
//         mHz_c freq_c: UInt32 = 0, ACK ackbit: Bool = false) {
//        let msgid = UInt16(EMDriverMsg._msgcounter + 1)
//        EMDriverMsg._msgcounter = (EMDriverMsg._msgcounter + 1) % 65535
//        self.datapacket = DataPacket(ackbit, msgid, freq_a, freq_b, freq_c)
//    }
//
//    init(_ data: Data) {
//        self.datapacket = DataPacket(data)
//    }
//
//    func toData() -> Data {
//        return self.datapacket.toData()
//    }
//    
//    var description: String {
//        return self.datapacket.description
//    }
//}

//protocol SendableMsg {
//    func toData() -> Data
//}
//
//enum MsgType: Int32 {
//    case STATUSREQ = 1, STATUSRESP, FREQUPDATE
//}
//
//struct StatusReqMsg : CustomStringConvertible, SendableMsg {
//    private static var _msgcounter: UInt32 = 1
//    private var msgtype: MsgType
//    private var msgcnt: UInt32
//
//    var description: String {
//        return "(\(self.msgtype), \(self.msgcnt))"
//    }
//    
//    init() {
//        self.msgtype = MsgType.STATUSREQ
//        self.msgcnt = StatusReqMsg._msgcounter
//        StatusReqMsg._msgcounter += 1
//    }
//
//    func toData() -> Data {
//        var data = Data(capacity: MemoryLayout<StatusReqMsg>.size)
//        withUnsafePointer(to: self.msgtype.rawValue) { ptr in
//            data.append(UnsafeBufferPointer(start: ptr, count: 1))
//        }
//        withUnsafePointer(to: self.msgcnt) { ptr in
//            data.append(UnsafeBufferPointer(start: ptr, count: 1))
//        }
//        return data
//    }
//}
//
//struct StatusRespMsg : CustomStringConvertible {
//    private var msgtype: MsgType = MsgType.STATUSRESP
//    var freq_a: Float32 = 0.0
//    var freq_b: Float32 = 0.0
//    var freq_c: Float32 = 0.0
//    
//    init(_ data: Data) {
//        withUnsafeMutablePointer(to: &self) { ptr in
//            data.copyBytes(
//                to: UnsafeMutableBufferPointer(start: ptr, count: 1),
//                from: 0..<MemoryLayout<StatusRespMsg>.size)
//        }
//    }
//    
//    var description: String {
//        return "(\(self.msgtype), \(self.freq_a), \(self.freq_b), \(self.freq_b))"
//    }
//}
//
//struct FreqUpdateMsg : CustomStringConvertible, SendableMsg {
//    private var msgtype: MsgType
//    var freq: Double
//    var emid: UInt32
//    var fcnt: UInt32
//
//    init(_ freq: Double, _ emid: UInt32, _ fcnt: UInt32) {
//        self.msgtype = MsgType.FREQUPDATE
//        self.freq = freq
//        self.emid = emid
//        self.fcnt = fcnt
//    }
//
//    var description: String {
//        return "(\(self.msgtype), \(self.freq), \(self.emid), \(self.fcnt))"
//    }
//
//    func toData() -> Data {
//        var data = Data(capacity: MemoryLayout<FreqUpdateMsg>.size)
//        withUnsafePointer(to: self.msgtype.rawValue) { ptr in
//            data.append(UnsafeBufferPointer(start: ptr, count: 1))
//        }
//        withUnsafePointer(to: self.freq) { ptr in
//            data.append(UnsafeBufferPointer(start: ptr, count: 1))
//        }
//        withUnsafePointer(to: self.emid) { ptr in
//            data.append(UnsafeBufferPointer(start: ptr, count: 1))
//        }
//        withUnsafePointer(to: self.fcnt) { ptr in
//            data.append(UnsafeBufferPointer(start: ptr, count: 1))
//        }
//        return data
//    }
//}
