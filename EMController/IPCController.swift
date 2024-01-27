//
//  IPCController.swift
//  EMController
//
//  Created by Alfred J Donich on 11/30/23.
//

import Foundation
import Network
import SwiftUI


let ESP_HOST: NWEndpoint.Host = "192.168.0.16"
let ESP_PORT: NWEndpoint.Port = 4645


class IPCController : CustomStringConvertible {
    var status: Bool = false
    private var mHzAcks_a: Binding<[Int32]>? = nil
    private var connection: NWConnection? = nil
    
    var description: String {
        let descr = connection?.endpoint.debugDescription
        let parts = connection?.parameters.debugDescription.split(separator: ",")
        return (descr != nil && parts != nil) ? "\(parts![0])://\(descr!)" : "ERROR"
    }
    
    func bindAckRsp(to value: Binding<[Int32]>) {
        mHzAcks_a = value
    }
    
    private func start() {
        NSLog("IPCController::start")
        connection = NWConnection(host: ESP_HOST, port: ESP_PORT, using: .udp)
        connection?.stateUpdateHandler = stateHandler(state:)
        connection?.start(queue: .global())
    }
    
    private func cancel() {
        NSLog("IPCController::cancel")
        connection?.cancel()
        connection = nil
        status = false
    }
    
    private func validate() {
        if connection == nil {
            start()
            receiveEMDriverMsg()
        }
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
                self.mHzAcks_a?.wrappedValue[0] = rsp.datapacket.freq_a
                self.mHzAcks_a?.wrappedValue[1] = rsp.datapacket.freq_b
                self.mHzAcks_a?.wrappedValue[2] = rsp.datapacket.freq_c
            }
            if let error = error {
                NSLog("IPCController::receiveEMDriverMsg error: %@", "\(error)")
                self.cancel()
                return
            }
            
            self.receiveEMDriverMsg()
        })
    }
    
    func sendEMDriverMsg(mHz freqs: [Int32] = [-1,-1,-1], ACK ackbit: Bool = false) {
        validate()
        let req = EMDriverMsg(mHz: freqs, ACK: ackbit)
        connection?.send(content: req.toData(),
            completion: NWConnection.SendCompletion.contentProcessed( { error in
                if (error == nil) {
                    if req.datapacket.freq_a == -1 { return }
                    NSLog("Sent EMDriverMsg: %@", req.description)
                } else {
                    NSLog("IPCController::sendEMDriverMsg error: %@", "\(error!)")
                    self.cancel()
                }
            })
        )
    }
}
