//
//  Photoshare.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-16.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation


class Photoshare {
    
    private var connection: Connection?
    private var serverHostName: String?
    private var allowSelfSignedCerts = true
    private var port: Int?
    
    init() {
        //Do I have settings required to initiate a connection
        set(hostName: "youwontbelieveme.duckdns.org")
        set(port: "1428")
        set(allowSelfSignedCerts: true)
        getHostName()
        getPort()
        getAllowSelfSignedCerts()
        if let serverHostName = serverHostName, let port = port{
            connection = connect()
        } else {
            print("No server hostname and/or port")
        }
        
        
    }
    
    private func connect() -> Connection {
        
        do {
            connection = try Connection(
                hostName: serverHostName!,
                port: port!,
                allowSelfSignedCerts: allowSelfSignedCerts)
            connection?.start()
            sleep(4)
            
        } catch {
            
        }
        return connection!
        
    }
    
    public func set(hostName: String){
        UserDefaults.standard.set(hostName, forKey: "hostName")
    }
    
    public func set(port: String){                      //Stores as Int
        UserDefaults.standard.set(Int(port), forKey: "port")
    }
    
    public func set(allowSelfSignedCerts: Bool){
        UserDefaults.standard.set(allowSelfSignedCerts, forKey: "allowSelfSignedCerts")
    }
    
    public func set(setting: String, to value: String){
        UserDefaults.standard.set(value, forKey: setting)
    }
    
    private func getHostName(){
       serverHostName = UserDefaults.standard.string(forKey: "hostName")
    }
    
    private func getPort(){
        port = UserDefaults.standard.integer(forKey: "port")
    }
    
    private func getAllowSelfSignedCerts(){
        allowSelfSignedCerts = UserDefaults.standard.bool(forKey: "allowSelfSignedCerts")
    }
    
    private func receive(message msg: PSMessage){
        
    }
    
    private func send(message msg: PSMessage){
        
    }
    

    
    
}
