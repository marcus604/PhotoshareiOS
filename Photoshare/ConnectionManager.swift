//
//  ConnectionManager.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-16.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import Socket

class ConnectionManager {
    
    private var isConfigured: Bool?
    
    //Allows self signed certificates
    private var SSLConfig = SSLService.Configuration(withCipherSuite: nil, clientAllowsSelfSignedCertificates: true)
    
    private var bufferSize = 16384
    private var ip = "youwontbelieveme.duckdns.org"
    private var port = 1428
    
    public func connect() {
        SSLConfig.cipherSuite = "ALL"
        do {
            var socket = try Socket.create()
            socket.readBufferSize = bufferSize
            socket.delegate = try SSLService(usingConfiguration: SSLConfig)
            try socket.connect(to: ip, port: Int32(port))
            
            
//            sleep(4)
//            try socket.write(from: "b010007andy:hi")
            
            
        } catch {
            print("hi")
        }
        
    }
    
    init(ipAddress: String, serverPort: Int){
        ip = ipAddress
        port = serverPort
    }
    
    
}
