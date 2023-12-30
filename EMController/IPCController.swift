//
//  IPCController.swift
//  EMController
//
//  Created by Alfred J Donich on 11/30/23.
//

import Foundation
import Network
import SwiftUI


class IPCController : CustomStringConvertible {
    private var mHzAck_a: Binding<UInt32>? = nil

    var ESP_HOST: NWEndpoint.Host = "192.168.0.16"
    var UDP_PORT: NWEndpoint.Port = 4645
    var status: Bool = false
    
    private static var fCount: UInt32 = 1
    private var connection: NWConnection? = nil
    
    var description: String {
        if connection == nil { return "ERROR" }
        let parts =  connection!.parameters.debugDescription.split(separator: ",")
        return "\(parts[0])://\(connection!.endpoint.debugDescription)"
    }
    
    func start(feedback_a: Binding<UInt32>) {
        NSLog("IPCController::start")
        connection = NWConnection(host: ESP_HOST, port: UDP_PORT, using: .udp)
        connection?.stateUpdateHandler = self.stateHandler(state:)
        connection?.start(queue: .global())
        mHzAck_a = feedback_a
    }
    
    func cancel() {
        NSLog("IPCController::cancel")
        connection?.cancel()
        connection = nil
        status = false
    }
    
    private func stateHandler(state: NWConnection.State) {
        switch state {
        case .setup, .preparing, .ready:
            status = true
            break
        case .waiting(let error):
            NSLog("IPCController::stateHandler::waiting: %@", "\(error)")
        case .failed(let error):
            NSLog("IPCController::stateHandler::failed: %@", "\(error)")
            cancel()
        case .cancelled:
            NSLog("IPCController::stateHandler::cancelled")
            cancel()
        @unknown default:
            break
        }
    }
    
    func receiveEMDriverMsg() {
        connection?.receiveMessage(completion: { content, _, _, error in
            if let data = content, !data.isEmpty {
                let rsp = EMDriverMsg(data)
                NSLog("Received EMDriverMsg: %@", rsp.description)
                self.mHzAck_a?.wrappedValue = rsp.datapacket.freq_a
            }
            if let error = error {
                NSLog("IPCController::receiveEMDriverMsg error: %@", "\(error)")
                self.cancel()
                return
            }
            
            self.receiveEMDriverMsg()
        })
    }
    
    func sendEMDriverMsg(mHz_a freq_a: UInt32 = 0, ACK ackbit: Bool = false) {
        let req = EMDriverMsg(mHz_a: freq_a, ACK: ackbit)
        self.connection?.send(content: req.toData(),
            completion: NWConnection.SendCompletion.contentProcessed( { error in
                if (error == nil) {
                    if req.datapacket.freq_a == 0 { return }
                    NSLog("Sent EMDriverMsg: %@", req.description)
                } else {
                    NSLog("IPCController::sendEMDriverMsg error: %@", "\(error!)")
                    self.cancel()
                }
            })
        )
    }
}
