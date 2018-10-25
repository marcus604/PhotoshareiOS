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
    private let timeout = 10000
    
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
    
    private var instructions = Instructions()
    
    
   
    
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
    
    //Create config for TLS
    //Attempt to make TCP and TLS handshake
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
            try socket.connect(to: hostName!, port: Int32(port!))
            try socket.setReadTimeout(value: timeout)
        } catch {
            guard let socketError = error as? Socket.Error else {
                throw error
            }
            throw socketError
        }
        
    }
    
    //Close connection
    public func stop() {
        connected = false
        socket.close()
    }
    
    public func isConnected() -> Bool{
        return connected
    }
    
    public func getImage(withHash hash: String) throws -> UIImage {
        let requestImgMsg = PSMessage(endian: endian, version: version, instruction: instructions.PHOTO_REQUEST, data: hash, token: token)
        
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
    
    public func updateImage(withHash hash: String, data: Data) -> Int {
        let updateImageMsg = PSMessage(endian: endian, version: version, instruction: instructions.PHOTO_EDIT, data: hash, token: token)
        var result: Int?
        do {
            try send(msg: updateImageMsg)
            
            let imageSize = data.count
            let imageSizeMsg = PSMessage(endian: endian, version: version, instruction: instructions.PHOTO_EDIT, data: "\(imageSize)", token: token)
            try send(msg: imageSizeMsg)
            try socket.write(from: data)
            try socket.setReadTimeout(value: 20000)     //Gives 20 seconds to send entire photo
            let importResultMsg = try receiveMessage()
            try socket.setReadTimeout(value: 1000)
            result = Int(importResultMsg.getData()) ?? 1
        } catch {
            result = 1       //Update failed
        }
        return result ?? 1
    }
    
    public func sendPhoto(fileName name: String, timeStamp: String, data: Data) -> Int {
        
        let sendPhotoMsg = PSMessage(endian: endian, version: version, instruction: instructions.PHOTO_UPLOAD, data: name, token: token)
        let timeStampMsg = PSMessage(endian: endian, version: version, instruction: instructions.PHOTO_UPLOAD, data: timeStamp, token: token)
        var result = Int()
        do {
            try send(msg: sendPhotoMsg)
            try send(msg: timeStampMsg)
            let imageSize = data.count
            let imageSizeMsg = PSMessage(endian: endian, version: version, instruction: instructions.PHOTO_UPLOAD, data: "\(imageSize)", token: token)
            try send(msg: imageSizeMsg)
            try socket.write(from: data)
            try socket.setReadTimeout(value: 20000)     //Gives 20 seconds to send entire photo
            let importResultMsg = try receiveMessage()
            try socket.setReadTimeout(value: 1000)
            result = Int(importResultMsg.getData()) ?? 3  //If cant get error code send generic 3
        } catch {
            result = 3
        }
        return result
    
        
    }
    
    
    
    private func getUserSetting(of key: String) -> String{
        return UserDefaults.standard.object(forKey: "\(key)") as? String ?? String()
    }
    
    public func sync(compressionEnabled: Bool, lastSyncedPhotoHash: String) throws -> Int{
        var compressionFlag: String
        if compressionEnabled {
            compressionFlag = "1"
        } else {
            compressionFlag = "0"
        }
        let syncMsg = PSMessage(endian: endian, version: version, instruction: instructions.SYNC, data: compressionFlag, token: token)
        let lastSyncedPhotoMsg = PSMessage(endian: endian, version: version, instruction: instructions.SYNC, data: lastSyncedPhotoHash, token: token)
        do {
            try send(msg: syncMsg)
            try send(msg: lastSyncedPhotoMsg)
            let numOfPhotosMsg = try receiveMessage()
            let numOfPhotos = Int(numOfPhotosMsg.getData()) ?? 0
            for _ in 0..<numOfPhotos{
                
                let sizeOfPhotoMsg = try receiveMessage()
                let sizeOfPhoto = Int(sizeOfPhotoMsg.getData())
                
                let photoNameMsg = try receiveMessage()
                let photoName = photoNameMsg.getData()
                
                let hashOfPhotoMsg = try receiveMessage()
                let hashOfPhoto = hashOfPhotoMsg.getData()
                
                let timeStampMsg = try receiveMessage()
                let timeStampString = timeStampMsg.getData()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy':'MM':'dd' 'HH':'mm':'ss"
                let timeStampOfPhoto = dateFormatter.date(from: timeStampString)
                let currentTime = Date()
                
                let image = try receiveImage(ofSize: sizeOfPhoto!)
                
                let fullPath = getDirectory(withName: "Library/Photos").appendingPathComponent(photoName)

                do {
                    try image.write(to: fullPath)
                    var imageUIImage = UIImage(data: image)
                    let fullPath = getDirectory(withName: "Library/Thumbnails").appendingPathComponent(photoName)
                    imageUIImage = resizeImage(image: imageUIImage!, newWidth: 400)
                    if let data = imageUIImage!.jpegData(compressionQuality: 1) {
                        try? data.write(to: fullPath)
                    }
                    
                    let appDelegate = AppDelegate.appDelegate
                    let context = appDelegate!.persistentContainer.viewContext
                    let entity = NSEntityDescription.entity(forEntityName: "Photos", in: context)
                    let newPhoto = NSManagedObject(entity: entity!, insertInto: context)
                    newPhoto.setValue(photoName, forKey: "fileName")
                    newPhoto.setValue(hashOfPhoto, forKey: "photohash")
                    newPhoto.setValue(timeStampOfPhoto, forKey: "timestamp")
                    newPhoto.setValue(currentTime, forKey: "dateAdded")
                    do {
                        try context.save()
                    } catch {
                        print("Failed saving")
                    }
                    
                    
                } catch {
                    print(error)
                    print("Couldn't write file")
                }
            }
            return numOfPhotos ?? 0
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
    
    //Provide server with working album
    //Request photo be added to working album
    func add(photo hash: String, toAlbum album: String) -> Bool {
        let addToAlbumMsg = PSMessage(endian: endian, version: version, instruction: instructions.ADD_TO_ALBUM , data: album, token: token)
        let addPhotoAlbumMsg = PSMessage(endian: endian, version: version, instruction: instructions.ADD_TO_ALBUM , data: hash, token: token)
        do {
            try send(msg: addToAlbumMsg)
            try send(msg: addPhotoAlbumMsg)
            try socket.setReadTimeout(value: 10000)
            let addPhotoToAlbumMsg = try receiveMessage()
            try socket.setReadTimeout(value: 1000)
            let result = addPhotoToAlbumMsg.getData()
            if result == "0" {
                return true
            }
            
        } catch {}
        return false
    }
    
    func createAlbum(album: PSAlbum) -> Bool {
        let createAlbumMsg = PSMessage(endian: endian, version: version, instruction: instructions.CREATE_ALBUM, data: album.title, token: token)
        let userCreatedString = (album.userCreated ? "1" : "0")
        let userCreatedMsg = PSMessage(endian: endian, version: version, instruction: instructions.CREATE_ALBUM, data: userCreatedString, token: token)
        do {
            try send(msg: createAlbumMsg)
            try send(msg: userCreatedMsg)
            try socket.setReadTimeout(value: 10000)
            let createAlbumResultMsg = try receiveMessage()
            try socket.setReadTimeout(value: 1000)
            let result = createAlbumResultMsg.getData()
            if result == "0" {
                return true
            }
        } catch {}
        return false
    }
    
    func delete(photo hash: String) -> Bool{
        let deleteMsg = PSMessage(endian: endian, version: version, instruction: instructions.PHOTO_DELETE, data: hash, token: token)
        do {
            try send(msg: deleteMsg)
            try socket.setReadTimeout(value: 10000)
            let importResultMsg = try receiveMessage()
            try socket.setReadTimeout(value: 1000)
            let result = importResultMsg.getData()
            if result == "0" {
                return true
            }
        } catch {}
        return false
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
            
            var amountRead = 0
            var image = Data()
            while amountRead < size {
                _ = try socket.read(into: &image)
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
        
        let handshakeMsg = PSMessage(endian: endian, version: version, instruction: instructions.HANDSHAKE, length: length, data: data)
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
    
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
   
    
}

extension Int {
    var boolValue: Bool { return self != 0 }
}

struct Instructions {
    let HANDSHAKE = 0
    let SYNC = 1
    let PHOTO_REQUEST = 10
    let PHOTO_UPLOAD = 20
    let PHOTO_EDIT = 30
    let CREATE_ALBUM = 40
    let ADD_TO_ALBUM = 45
    let PHOTO_DELETE = 50
    let ERROR = 99
}

