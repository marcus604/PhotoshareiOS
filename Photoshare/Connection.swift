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
    private var hostName = "10.10.1.67"
    private var port = 1428
    private let timeout = 5000
    private var socket: Socket
    //private var sslConfiguration: SSLService.Configuration
    
    init(hostName: String, port: Int) throws {
        self.hostName = hostName
        self.port = port
        
        
        socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        socket.readBufferSize = bufferSize
    }
    
    
    public func start() {
        
        //Allows self signed certificates
        var sslConfiguration = SSLService.Configuration(withCipherSuite: nil, clientAllowsSelfSignedCertificates: true)
        sslConfiguration.cipherSuite = "ALL"
        
       
        do {
            let sslService = try SSLService(usingConfiguration: sslConfiguration)
            socket.delegate = sslService
            sslService?.verifyCallback = { _ in
                return (true, nil)
                
            }
            
            usleep(10000)
            let timeout = UInt(max(0, self.timeout))
            try socket.connect(to: hostName, port: Int32(port), timeout: timeout)
            
            
            
//            sleep(4)
//            try socket.write(from: "b010007andy:hi")
            
            
        } catch {
            print("hi")
        }
        
    }
    
    
    
   
    
}
