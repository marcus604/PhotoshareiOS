//
//  ConnectionManager.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-16.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import UIKit
import Socket
import CoreData


class NetworkConnection {
    
    private var isConfigured: Bool?
    
    
    
    private let bufferSize = 16384
    private let timeout = 0
    
    private var hostName: String?
    private var port: Int?
    private let allowSelfSignedCerts: Bool?
    private let compressionEnabled: Bool?
    private let userName: String?
    private let password: String?
    private var socket: Socket
    private var token = ""
    private let endian = "b"
    private let version = 1
    private var connected = false
    
    private var currentlyReceiving = false
    
    private let SYNC_INSTRUCTION = 1
    
   
    
    init(hostName: String, port: Int, allowSelfSignedCerts: Bool, compressionEnabled: Bool, userName: String, password: String) throws {
        self.hostName = hostName
        self.port = port
        self.allowSelfSignedCerts = allowSelfSignedCerts
        self.compressionEnabled = compressionEnabled
        self.userName = userName
        self.password = password

        socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        socket.readBufferSize = bufferSize
    }
    
    
    public func start() throws{
        
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
            //try socket.connect(to: hostName!, port: Int32(port!), timeout: timeout)
            try socket.connect(to: hostName!, port: Int32(port!))
            try socket.setReadTimeout(value: timeout)
            if socket.remoteHostname != hostName {
                print("man in the middle")
            }
            
        
            
        } catch {
            guard let socketError = error as? Socket.Error else {
                throw error
            }
            throw socketError
        }
        
    }
    
    public func isConnected() -> Bool{
        return connected
    }
    
    public func getImage(withHash hash: String) throws -> UIImage {
        let requestImgMsg = PSMessage(endian: endian, version: version, instruction: 10, data: hash, token: token)
        
        var image = UIImage()
        do {
            while currentlyReceiving {
                //do nothing
            }
            if (try socket.isReadableOrWritable().writable) {
                currentlyReceiving = true
                try send(msg: requestImgMsg)
                
                let sizeOfPhotoMsg = try receiveMessage()
                let sizeOfPhoto = Int(sizeOfPhotoMsg.getData())
                
                image = UIImage(data: (try receiveImage(ofSize: sizeOfPhoto!))) ?? UIImage()
                currentlyReceiving = false
            }
        } catch {
            throw error
        }
        
        return image
    }
    
    public func stop() {
        connected = false
        socket.close()
    }
    
    private func getUserSetting(of key: String) -> String{
        return UserDefaults.standard.object(forKey: "\(key)") as? String ?? String()
    }
    
    public func sync(compressionEnabled: Bool) throws{
        var compressionFlag: String
        if compressionEnabled {
            compressionFlag = "1"
        } else {
            compressionFlag = "0"
        }
        let syncMsg = PSMessage(endian: endian, version: version, instruction: SYNC_INSTRUCTION, data: compressionFlag, token: token)
        do {
            try send(msg: syncMsg)
            let numOfPhotosMsg = try receiveMessage()
            let numOfPhotos = Int(numOfPhotosMsg.getData())
            for index in 0..<numOfPhotos!{
                
                let sizeOfPhotoMsg = try receiveMessage()
                var sizeOfPhoto = Int(sizeOfPhotoMsg.getData())
                
                let photoNameMsg = try receiveMessage()
                var photoName = photoNameMsg.getData()
                
                let hashOfPhotoMsg = try receiveMessage()
                var hashOfPhoto = hashOfPhotoMsg.getData()
                
                let timeStampMsg = try receiveMessage()
                var timeStampString = timeStampMsg.getData()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy':'MM':'dd' 'HH':'mm':'ss"
                var timeStampOfPhoto = dateFormatter.date(from: timeStampString)
                
                let image = try receiveImage(ofSize: sizeOfPhoto!)
                
                //let fullPath = getDocumentsDirectory().appendingPathComponent(photoName)
                let fullPath = getDirectory(withName: "Library/Photos").appendingPathComponent(photoName)
                //let thumbnailPath = getDocumentsDirectory().appendingPathComponent(<#T##pathComponent: String##String#>, isDirectory: <#T##Bool#>)
                let size = image.count
                do {
                    try image.write(to: fullPath)
                    var imageUIImage = UIImage(data: image)
                    let fullPath = getDirectory(withName: "Library/Thumbnails").appendingPathComponent(photoName)
                    imageUIImage = resizeImage(image: imageUIImage!, newWidth: 200)
                    if let data = UIImageJPEGRepresentation(imageUIImage!, 1) {
                        try? data.write(to: fullPath)
                    }
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let context = appDelegate.persistentContainer.viewContext
                    let entity = NSEntityDescription.entity(forEntityName: "Photos", in: context)
                    let newPhoto = NSManagedObject(entity: entity!, insertInto: context)
                    newPhoto.setValue(photoName, forKey: "fileName")
                    newPhoto.setValue(hashOfPhoto, forKey: "photohash")
                    newPhoto.setValue(timeStampOfPhoto, forKey: "timestamp")
                    do {
                        try context.save()
                    } catch {
                        print("Failed saving")
                    }
                } catch {
                    print("Couldn't write file")
                }
            }
            print("Synced \(numOfPhotos) photos")
        } catch {
            throw error
        }
        
        
        
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
        
    }
    
    func savePhoto(image: Data, fileName: String) {
        
        let fullPath = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try image.write(to: fullPath)
        } catch {
            print("Couldn't write file")
        }
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
    
    func getDirectory(withName name: String) -> URL {
        let path = getDocumentsDirectory().appendingPathComponent(name, isDirectory: true)
        return path
    }
    

    
    //Cant convert byte data to string
    //need to look at socket class and find different method for receiving
    public func receiveImage(ofSize size: Int) throws -> Data{
        do {
            var readable: Bool = false
            var amountRead = 0
            var image = Data()
            while amountRead < size {
                try socket.read(into: &image)
                amountRead = image.count
            }
            return image
        } catch {
            print("failed in receiveImage")
            throw error
        }
        
        
    }
    public func handshake() throws{
        
        guard let name = userName, let pass = password else {
            print("No username/password")
            return
        }
        let data = "\(name):\(pass)"
        let length = data.count
        
        let handshakeMsg = PSMessage(endian: endian, version: version, instruction: 0, length: length, data: data)
        do {
            try send(msg: handshakeMsg)
            let tokenMsg =  try receiveMessage()
            if tokenMsg.isError() {
                throw Photoshare.PhotoshareError.failedUserAuthentication
            }
            token = tokenMsg.getData()
            connected = true
        } catch {
            throw error
        }
        
    }
    
    private func receiveMessage() throws -> PSMessage{
        do {
            var stringRead = ""
            stringRead = (try socket.readString())!
            return PSMessage.init(fromString: stringRead)
        } catch let error as Socket.Error{
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

