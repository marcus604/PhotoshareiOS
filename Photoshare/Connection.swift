//
//  ConnectionManager.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-16.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import Socket

class Connection {
    
    private var isConfigured: Bool?
    
    
    
    private let bufferSize = 16384
    private let timeout = 5000
    
    private var hostName: String?
    private var port: Int?
    private let allowSelfSignedCerts: Bool?
    private let compressionLevel: Int?
    private let userName: String?
    private let password: String?
    private var socket: Socket
    private var token = ""
    private let endian = "b"
    private let version = 1
    
    
    init(hostName: String, port: Int, allowSelfSignedCerts: Bool, compressionLevel: Int, userName: String, password: String) throws {
        self.hostName = hostName
        self.port = port
        self.allowSelfSignedCerts = allowSelfSignedCerts
        self.compressionLevel = compressionLevel
        self.userName = userName
        self.password = password
        
        socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        socket.readBufferSize = bufferSize
    }
    
    
    public func start() {
        
        //Allows self signed certificates
        var sslConfiguration = SSLService.Configuration(withCipherSuite: nil, clientAllowsSelfSignedCertificates: allowSelfSignedCerts!)
        sslConfiguration.cipherSuite = "ALL"
        
       
        do {
            let sslService = try SSLService(usingConfiguration: sslConfiguration)
            socket.delegate = sslService
            sslService?.verifyCallback = { _ in
                return (true, nil)
            }
            
            
            let timeout = UInt(max(0, self.timeout))
            try socket.connect(to: hostName!, port: Int32(port!), timeout: timeout)
            
            if socket.remoteHostname != hostName {
                print("man in the middle")
            }
            
            //token = handshake(sock: socket, userName: userName!, password: password!)
            //try socket.write(from: "b010007andy:hi")
            
        } catch {
            guard let socketError = error as? Socket.Error else {
                print("Unknown Error")
                return
            }
            print(socketError)
        }
        
    }
    
    public func disconnect() {
        socket.close()
    }
    
    public func run() throws {
        while true {
            do {
                //Have an authenticated connection to server
                //Am I out of sync with the server
                //Any changes happen on phon
                //Get changes from server
                //Merge changes
                print("Got a valid connection and handshake")
                sleep(4)
            } catch {
                print("some error after valid connection")
            }
        }
    }
    
    public func handshake() throws{
        
        guard let name = userName, let pass = password else {
            print("No username/password")
            return
        }
        var data = "\(name):\(pass)"
        var length = data.count
        
        var handshakeMsg = PSMessage(endian: endian, version: version, instruction: 0, length: length, data: data)
        do {
            try send(msg: handshakeMsg)
            var tokenMsg =  try receiveMessage()
            if tokenMsg.isError() {
                throw Photoshare.PhotoshareError.failedUserAuthentication
            }
            token = tokenMsg.getData()
            print(token)
        } catch {
            throw error
        }
        
    }
    
    private func receiveMessage() throws -> PSMessage{
        do {
            let stringRead = try socket.readString()
            return PSMessage.init(fromString: stringRead!)
        } catch {
            throw Photoshare.PhotoshareError.lostConnection
        }
        
    }
    private func send(msg: PSMessage) throws{
        let msgString = msg.getString()
        do {
            try socket.write(from: msgString)
        } catch {
            throw Photoshare.PhotoshareError.lostConnection
        }
    }
    
    
    
   
    
}
