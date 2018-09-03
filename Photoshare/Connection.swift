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
    private var socket: Socket
    
    
    init(hostName: String, port: Int, allowSelfSignedCerts: Bool) throws {
        self.hostName = hostName
        self.port = port
        self.allowSelfSignedCerts = allowSelfSignedCerts
        
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
            print("wait")
            
            try socket.write(from: "b010007andy:hi")
            print("wait")
            
//            sleep(4)
//
            
            
        } catch {
            print("hi")
        }
        
    }
    
    public func disconnect() {
        socket.close()
    }
    
    
    
   
    
}
