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
    private var port: Int?
    
    init() {
        getHostName()
        getPort()
        if let serverHostName = serverHostName, let port = port{
            connection = connect()
        } else {
            print("No server hostname and/or port")
        }
        
        
    }
    
    private func connect() -> Connection {
        
        do {
            connection = try Connection(
                hostName: "10.10.1.67",
                port: 1428)
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
    
    private func getHostName(){
       serverHostName = UserDefaults.standard.string(forKey: "hostName")
    }
    
    private func getPort(){
        port = UserDefaults.standard.integer(forKey: "port")
    }
    
    private func receive(message msg: PSMessage){
        
    }
    
    private func send(message msg: PSMessage){
        
    }
    

    
    
}
