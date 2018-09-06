//
//  Photoshare.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-16.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper


class Photoshare {
    
    private var connection: Connection?
    
    init() {
        //Do I have settings required to initiate a connection
        //Make the initial TCP and TLS handshake
        do {
            try connection = connect()
            try connection!.handshake()
            try connection!.run()
        } catch PhotoshareError.failedConnection{   //TCP|TLS Connection Failed
            print("TCP/TLS Connection Failed")
            //Need to display message to user that connection failed and return them to settings
            //Should highlight hostname and port number
        } catch PhotoshareError.failedUserAuthentication{ //Inc
            print("failed user auth")
            //should highlight username and password
        } catch PhotoshareError.lostConnection{
            print("Lost Connection")
        } catch {
            print("unknown error")
        }
        
    }
    
    public func connect() throws -> Connection {
        set(hostName: "youwontbelieveme.duckdns.org")
        set(port: "1428")
        set(allowSelfSignedCerts: true)
        set(compressionLevel: 0.0)
        set(userName: "andy")
        set(password: "hi")
        do {
            connection = try Connection(
                hostName: getHostName(),
                port: getPort(),
                allowSelfSignedCerts: getAllowSelfSignedCerts(),
                compressionLevel: getCompressionLevel(),
                userName: getUserName(),
                password: getPassword()
                )
            connection!.start()
            
            
        } catch {
            print(error)
            throw PhotoshareError.failedConnection
        }
        return connection!
        
    }
    
    enum PhotoshareError: Error {
        case failedConnection
        case failedUserAuthentication
        case lostConnection
    }
    
    //Set settings
    //If newSetting != previousSetting
    //  Create new connection
    //else
    //  do nothing
    public func set(userName: String){
        UserDefaults.standard.set(userName, forKey: "userName")
    }
    
    
    private func getUserName() -> String{
        return UserDefaults.standard.string(forKey: "userName")!
    }
    
    public func set(compressionLevel: Float){
        let roundedLevel = Int(round(compressionLevel))
        UserDefaults.standard.set(roundedLevel, forKey: "compressionLevel")
    }
    
    private func getCompressionLevel() -> Int{
        return UserDefaults.standard.integer(forKey: "compressionLevel")
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
    
    private func getHostName() -> String{
        return UserDefaults.standard.string(forKey: "hostName")!
    }
    
    private func getPort() -> Int{
        return UserDefaults.standard.integer(forKey: "port")
    }
    
    private func getAllowSelfSignedCerts() -> Bool{
        return UserDefaults.standard.bool(forKey: "allowSelfSignedCerts")
    }
    
    public func set(password: String){
        KeychainWrapper.standard.set(password, forKey: "userPassword")
    }
    
    private func getPassword() -> String{
        return KeychainWrapper.standard.string(forKey: "userPassword")!
    }
    
    private func receive(message msg: PSMessage){
        
    }
    
    private func send(message msg: PSMessage){
        
    }
    

    
    
}
