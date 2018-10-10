//
//  Photoshare.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-16.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import Photos


class Photoshare {
    
    private var connection: NetworkConnection?
    private var changedPhotos: [String]? //Need to create a class/struct for photo class
    private var photoLibrary: [String]?
    
    public var isConnected = false
    public var status: String
    
    
    private static var sharedPhotoshare: Photoshare = {
        let photoshare = Photoshare()
        
        return photoshare
    }()
    
   
    
    
    init() {
        status = "Not Connected"
    }
    
    class func shared() -> Photoshare {
        return sharedPhotoshare
    }
    
    public func isConfigured() -> Bool {
        return false
    }
    
    public func start() {
        //Do I have settings required to initiate a connection
        //Make the initial TCP and TLS handshake
        //let settingsValid = settingsValid()
        do {
            createDirectory(withName: "Library/Photos/")
            createDirectory(withName: "Library/Thumbnails/")
            try connection = connect()
            status = "Authenticating"
            try connection?.handshake()
            isConnected = true
        } catch PhotoshareError.failedConnection{
            status = "TCP/TLS Connection Failed"
            connection?.stop()
        } catch PhotoshareError.failedUserAuthentication{
            status = "Invalid Credentials"
            connection?.stop()
        } catch PhotoshareError.lostConnection{
            print("Lost Connection")
            connection?.stop()
        } catch PhotoshareError.invalidSettings{
            print("Invalid Settings")
        } catch PhotoshareError.connectionTimeout{
            print("Connection Timeout")
            connection?.stop()
        } catch {
            print("Unknown Error")
            connection?.stop()
        }
    
    }
    
    public func sync() {
        if isConnected {
            status = "Syncing"
            do {
                try connection?.sync(compressionEnabled: getUserSetting(asBoolFor: "compressionEnabled"))
            } catch {
                print("Failed to Sync")
            }
        }
        
        
    }
    public func getFullSizeImage(forPhoto photo: PSPhoto) {
        if !getUserSetting(asBoolFor: "compressionEnabled") {
            photo.fullSizePhoto = nil
            return
        }
        guard let connected = connection?.isConnected() else {
            self.start()
            return
        }
        do {
            try photo.fullSizePhoto = connection?.getImage(withHash: photo.photoHash)
        } catch {
            photo.fullSizePhoto = nil
        }
        
    }
    
    public func sendPhoto(asset: PHAsset) {
        var rawData = Data()
        
        let timeStamp = DateFormatter.localizedString(from: asset.creationDate!, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short)
        var name = asset.originalFilename
        var imageSize = Int()
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .exact
        requestOptions.deliveryMode = .highQualityFormat;
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.isSynchronous = true
        
        let nameComponents = name?.components(separatedBy: ".")
        let fileExtension = nameComponents![1].uppercased()
        
        if fileExtension == "HEIC" || fileExtension == "PNG"{
            manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: requestOptions, resultHandler: {
                (image, info) in
                rawData = image!.jpegData(compressionQuality: 0.9)!
                name = nameComponents![0] + ".jpg"
                
                })
            
        } else {
            manager.requestImageData(for: asset, options: requestOptions, resultHandler: { (data, str, orientation, info) in
                rawData = data!
            })
            
        }
        
        imageSize = rawData.count
        
        status = "Uploading Photo"
        guard let connected = connection?.isConnected() else {
            self.start()
            return
        }
        let result = connection?.sendPhoto(fileName: name!, timeStamp: timeStamp, data: rawData)
        
        switch result {
        case 0: //Could optimizie this as its throwing away the data and then requesting it
            status = "Imported Photo"
        case 1:
            status = "Duplicate Photo"
        case 2:
            status = "Unsupported File"
        default:
            status = "Unknown Error"
            
        }
        
        
    }
    
    
    public func getSettings() -> ([String: Any]){
        var settings = [String: Any]()
        settings["hostName"] = getUserSetting(asStringfor: "hostName")
        settings["port"] = getUserSetting(asIntFor: "port")
        settings["userName"] = getUserSetting(asStringfor: "userName")
        settings["password"] = getPassword()
        
        settings["allowSelfSignedCerts"] = getUserSetting(asBoolFor: "allowSelfSignedCerts")
        settings["compressionEnabled"] = getUserSetting(asBoolFor: "compressionEnabled")
        
        return settings
    }
    
    //Ensure all settings are valid
    //Read as value type and check if valid
    //Toggles have two states dont need to check if its valid
    public func settingsValid(with settings: ([String: Any])) -> Bool {
        
        for setting in settings {
            guard let stringValue = setting.value as? String else {
                guard let intValue = setting.value as? Int else {
                    continue
                }
                if intValue == 0 {      //Port cant be 0
                    return false
                }
                continue
            }
            if stringValue == "" {
                return false
            }
            
        }
        return true
    }
    
    public func connect() throws -> NetworkConnection {
        let settings = getSettings()
        
        if !settingsValid(with: settings)  {
            throw PhotoshareError.invalidSettings
        }
        
        do {
            connection = try NetworkConnection(
                hostName: settings["hostName"] as! String,
                port: settings["port"] as! Int,
                allowSelfSignedCerts: settings["allowSelfSignedCerts"] as! Bool,
                compressionEnabled: settings["compressionEnabled"] as! Bool,
                userName: settings["userName"] as! String,
                password: settings["password"] as! String
                )
            try connection?.start()
        } catch {
            throw PhotoshareError.failedConnection
        }
        return connection!
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
  
    
    func createDirectory(withName name: String) {
        let fileManager = FileManager()
        let dirURL = getDocumentsDirectory().appendingPathComponent(name)
        do {
            try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error)
        }
        
    }
    
    enum PhotoshareError: Error {
        case failedConnection
        case failedUserAuthentication
        case lostConnection
        case invalidSettings
        case connectionTimeout
    }
    
    //Set settings
    //If newSetting != previousSetting
    //  Create new connection
    //else
    //  do nothing
    public func set(userName: String){
        UserDefaults.standard.set(userName, forKey: "userName")
    }
    
    
   
    
    public func set(hostName: String){
        UserDefaults.standard.set(hostName, forKey: "hostName")
    }
    
    public func set(port: Int){                      //Stores as Int
        UserDefaults.standard.set(port, forKey: "port")
    }
    
    //Toggles
    public func set(allowSelfSignedCerts: Bool){
        UserDefaults.standard.set(allowSelfSignedCerts, forKey: "allowSelfSignedCerts")
    }
    
    public func set(compressionEnabled: Bool){
        UserDefaults.standard.set(compressionEnabled, forKey: "enabledCompression")
    }
    
    //SETTERS
    public func set(settingAsString key: String, to value: String){
        UserDefaults.standard.set(value, forKey: key)
    }
    
    public func set(settingAsBool key: String, to value: Bool){
        UserDefaults.standard.set(value, forKey: key)
    }
    
    public func set(settingAsInt key: String, to value: Int){
        UserDefaults.standard.set(value, forKey: key)
    }
    
    //GETTERS
    private func getUserSetting(asStringfor key: String) -> String{
        return UserDefaults.standard.object(forKey: key) as? String ?? ""
    }
    
    private func getUserSetting(asBoolFor key: String) -> Bool{
        return UserDefaults.standard.bool(forKey: key)
    }
    private func getUserSetting(asIntFor key: String) -> Int{
        return UserDefaults.standard.integer(forKey: key)
    }
    

    
    
    //Password
    public func set(password: String){
        KeychainWrapper.standard.set(password, forKey: "userPassword")
    }
    
    private func getPassword() -> String{
        return KeychainWrapper.standard.string(forKey: "userPassword") ?? ""
        
    }
    
    
    
    
    private func receive(message msg: PSMessage){
        
    }
    
    private func send(message msg: PSMessage){
        
    }
    

    
    
}
