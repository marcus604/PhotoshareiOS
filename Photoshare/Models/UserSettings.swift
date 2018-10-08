//
//  UserSettings.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-03.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper


class UserSettings {
    
    private var hostname: String?
    private var port: Int?
    private var allowingSelfSignedCertificates: Bool?
    private var username: String?
    private var password: String?
    private var compressionEnabled: Bool?
    
    
    private var isValid: Bool?
    
    
    
    init() {
        isValid = false
        
    }
    
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
    
    
}
