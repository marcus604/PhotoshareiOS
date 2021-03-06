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
import CoreData
import os.log


class Photoshare {
    
    private var connection: NetworkConnection?
    private var changedPhotos: [String]? //Need to create a class/struct for photo class
    
    private var photos: [PSPhoto]!
    private var albums: [PSAlbum]!
    private var globalIndex: Int!
    
    //Settings
    public var compressionEnabled: Bool?
    private var allowSelfSignedCerts: Bool?
    
    private var hostName: String?
    private var port: Int?
    private var userName: String?
    private var password: String?
    
    
    static var realDelegate: AppDelegate?
    
    static var appDelegate: AppDelegate {
        if Thread.isMainThread{
            return UIApplication.shared.delegate as! AppDelegate;
        }
        let dg = DispatchGroup();
        dg.enter()
        DispatchQueue.main.async{
            realDelegate = UIApplication.shared.delegate as? AppDelegate;
            dg.leave();
        }
        dg.wait();
        return realDelegate!;
    }
    
    
    public var settings = [String: Any]()
    public var settingsValid = [String: Bool]()
    public var allSettingsValid = false
    
    public var isConnected = false
    public var status: String
    public var lastOperationSuccess = false
    
    
    private static var sharedPhotoshare: Photoshare = {
        os_log(.debug, log: OSLog.default, "Accessing shared Photoshare instance")
        let photoshare = Photoshare()
        photoshare.validateSettings()
        photoshare.generatePhotos()
        photoshare.generateAlbums()
        if photoshare.photos.count == 0{    //If no photos then directories might not. Silent return if directory creation fails
            photoshare.createDirectory(withName: "Library/Photos/")
            photoshare.createDirectory(withName: "Library/Thumbnails/")
        }
        
        return photoshare
    }()
    
    init() {
        status = "Not Connected"
        os_log("Starting Photoshare", log: OSLog.default, type: .debug)
    }
    
    
    private func generateSettings() {
        settings["hostName"] = getUserSetting(asStringfor: "hostName")
        settings["port"] = getUserSetting(asIntFor: "port")
        settings["userName"] = getUserSetting(asStringfor: "userName")
        settings["password"] = getPassword()
        
        settings["allowSelfSignedCerts"] = getUserSetting(asBoolFor: "allowSelfSignedCerts")
        settings["compressionEnabled"] = getUserSetting(asBoolFor: "compressionEnabled")
    }
   
    
    //Sets individual setting status
    //Can help tell user which setting is wrong
    public func validateSettings(){
        generateSettings()
        for setting in settings {
            settingsValid[setting.key] = false      //Everything starts invalid
            switch setting.key {
            case "port":
                guard let port = setting.value as? Int else { continue }
                if port > 1024 && port < 49151 { settingsValid[setting.key] = true }    //Could restric
            case "allowSelfSignedCerts", "compressionEnabled":
                guard let _ = setting.value as? Bool else { continue }
                settingsValid[setting.key] = true
            default:    //Is one of the strings
                guard let stringValue = setting.value as? String else { continue }
                if stringValue.count > 0 && stringValue.count < 140 { settingsValid[setting.key] = true }
            }
        }
        
        for settings in settingsValid {
            
            if !settings.value {
                allSettingsValid = false
                os_log(.debug, log: OSLog.default, "Settings Valid = %@", allSettingsValid.description)
                break
            }
            allSettingsValid = true
        }
        os_log(.debug, log: OSLog.default, "Settings Valid = %@", allSettingsValid.description)
        
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
        if isConnected {
            os_log(.debug, log: OSLog.default, "Already connected")
            return
        }
        do {
            try connection = connect(withSettings: settings)
            os_log(.debug, log: OSLog.default, "TCP/TLS Handshake Success")
            status = "Authenticating"
            try connection?.handshake()
            os_log(.debug, log: OSLog.default, "Photoshare Handshake Success")
            isConnected = true
        } catch PhotoshareError.failedConnection{
            status = "TCP/TLS Connection Failed"
            os_log(.info, log: OSLog.default, "TCP/TLS Handshake Failure")
            connection?.stop()
        } catch PhotoshareError.failedUserAuthentication{
            status = "Invalid Credentials"
            os_log(.info, log: OSLog.default, "Photoshare Handshake Failure")
            connection?.stop()
        } catch PhotoshareError.lostConnection{
            print("Lost Connection")
            os_log(.info, log: OSLog.default, "Lost Connection")
            connection?.stop()
        } catch PhotoshareError.invalidSettings{
            print("Invalid Settings")
        } catch PhotoshareError.connectionTimeout{
            print("Connection Timeout")
            os_log(.info, log: OSLog.default, "Connection timed out")
            connection?.stop()
        } catch {
            print("Unknown Error")
            os_log(.info, log: OSLog.default, "Unknown Error")
            connection?.stop()
        }
    
    }
    
    public func getPhotos() -> [PSPhoto]{
        return photos
    }
    
    public func getAlbums() -> [PSAlbum] {
        return albums
    }
    
   
    public func sync() {
        var numOfPhotosSynced = 0
        //Get most recent photo to determine sync
        var lastSyncedPhotoHash: String
        if photos.isEmpty {
            lastSyncedPhotoHash = "0"
        } else {
            lastSyncedPhotoHash = getMostRecentlyAddedPhoto()
        }
        if isConnected {
            status = "Syncing"
            do {
                numOfPhotosSynced = try (connection?.sync(compressionEnabled: compressionEnabled ?? true, lastSyncedPhotoHash: lastSyncedPhotoHash))!
            } catch {
                isConnected = false
                os_log(.error, log: OSLog.default, "Failed Sync")
            }
            if numOfPhotosSynced != 0 {
                generatePhotos()
            }
            os_log(.debug, log: OSLog.default, "Synced %d Photos", numOfPhotosSynced)
        }
        
        
    }
    
    public func getFullSizeImage(forPhoto photo: PSPhoto) {
        if !getUserSetting(asBoolFor: "compressionEnabled") {
            photo.fullSizePhoto = photo.localPhoto
            return
        }
        guard (connection?.isConnected()) != nil else {
            self.start()
            return
        }
        do {
            try photo.fullSizePhoto = connection?.getImage(withHash: photo.photoHash)
        } catch {
            photo.fullSizePhoto = nil
        }
        
    }
    
    public func updatePhoto(forPhoto photo: PSPhoto) {
        guard (connection?.isConnected()) != nil else {
            self.start()
            return
        }
        let imageData = photo.fullSizePhoto!.jpegData(compressionQuality: 1.0)
        let result = connection?.updateImage(withHash: photo.photoHash, data: imageData!)
       
        switch result {
        case 0: //Could optimizie this as its throwing away the data and then requesting it
            status = "Updated Photo"
            let fullPath = getDirectory(withName: "Library/Photos").appendingPathComponent(photo.fileName)
            do {
                try imageData!.write(to: fullPath)
                var imageUIImage = UIImage(data: imageData!)
                let fullPath = getDirectory(withName: "Library/Thumbnails").appendingPathComponent(photo.fileName)
                imageUIImage = resizeImage(image: imageUIImage!, newWidth: 200)
                if let data = imageUIImage!.jpegData(compressionQuality: 1) {
                    try? data.write(to: fullPath)
                }
            } catch {
                print("failed")
            }
        case 1:
            status = "Failed to update photo"
        default:
            status = "Unknown Error"
            
        }

    }
    
    public func generateSmartAlbums() {
        //Create albums for each year
        //--- TO DO
        //--- Inspect Library for what years it has rather than generating and checking
        //--- Only look at photos that were added since last update
        let calendar = Calendar.current
        for photo in self.photos {
            let photoYear = calendar.component(.year, from: photo.timestamp)
            var doesAlbumExist = false
            for album in albums {
                if album.title == "\(photoYear)" {
                    doesAlbumExist = true
                }
            }
            if !doesAlbumExist {
                createNewAlbum(withName: "\(photoYear)", userCreated: false)
            }
            add(photo: photo, toAlbum: "\(photoYear)")
            }
        
        
        
    }
    
    
    public func createNewAlbum(withName name: String, userCreated: Bool) -> Bool{
        let appDelegate = AppDelegate.appDelegate
        let context = appDelegate!.persistentContainer.viewContext
        
        let albumEntity = NSEntityDescription.entity(forEntityName: "Albums", in: context)
        var fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Albums")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        if let result = try? context.fetch(fetchRequest) {
            if result.count == 1 {
                os_log(.error, log: OSLog.default, "Album already exists")
                return false
            }
        }
        
        //Request server to create album
        //Create local if server successfull
        let album = PSAlbum(title: name, isCompressed: compressionEnabled!, lastUpdated: Date(), userCreated: userCreated)
        let success = connection?.createAlbum(album: album) ?? false
        if success {
            let newAlbum = NSManagedObject(entity: albumEntity!, insertInto: context)
            
            newAlbum.setValue(name, forKey: "name")
            newAlbum.setValue(compressionEnabled, forKey: "isCompressed")
            newAlbum.setValue(Date(), forKey: "dateCreated")
            newAlbum.setValue(Date(), forKey: "dateUpdated")
            newAlbum.setValue(userCreated, forKey: "userCreated")
            
            do {
                try context.save()
                os_log(.debug, log: OSLog.default, "Created Album: %@", name)
                albums.append(album)
                //generateAlbums()
                return true
            } catch {
                os_log(.error, log: OSLog.default, "Failed to create album")
                return false
            }
        }
        
        os_log(.error, log: OSLog.default, "Server failed to create album")
        return false
    }
    
    public func add(photo: PSPhoto, toAlbum album: String) -> Bool{
            
        var albumObject: NSManagedObject!
        var photoObject: NSManagedObject!
        
        let appDelegate = AppDelegate.appDelegate
        let context = appDelegate!.persistentContainer.viewContext
//        let albumEntity = NSEntityDescription.entity(forEntityName: "Albums", in: context)
//        let photoEntity = NSEntityDescription.entity(forEntityName: "Photos", in: context)
        var fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Albums")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "name == %@", album)
        if let result = try? context.fetch(fetchRequest) {
            if result.count == 0 {
                os_log(.info, log: OSLog.default, "Photo could not be added")
                return false
            }
            albumObject = result[0] as? NSManagedObject
        }
        let success = connection?.add(photo: photo.photoHash, toAlbum: album) ?? false
       
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photos")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "photohash == %@", photo.photoHash)
        if let result = try? context.fetch(fetchRequest) {
            photoObject = result[0] as? NSManagedObject
        }
        let albumPhotos = albumObject.mutableSetValue(forKey: "photos")
        
        //Determine if photo already contained in album
        for photoInAlbum in albumPhotos {
            let hash = (photoInAlbum as AnyObject).value(forKey: "photohash") as! String
            if hash == photo.photoHash {
                os_log(.info, log: OSLog.default, "Photo already in album")
                return false
            }
        }
        albumPhotos.add(photoObject)
        albumObject.setValue(Date(), forKey: "dateUpdated")
        
        do {
            try context.save()
            os_log(.debug, log: OSLog.default, "Added photo to album: %@", album)
            
        } catch {
            os_log(.error, log: OSLog.default, "Failed to add photo to album")
            return false
        }
        return true
        
    }
    
    public func generateAlbums() {
        let appDelegate = AppDelegate.appDelegate
        let context = appDelegate!.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Albums")
        let sortDescriptor = NSSortDescriptor(key: "dateUpdated", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        do {
            albums = [PSAlbum]()
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                let albumName = (data.value(forKey: "name") as! String)
                let isCompressed = (data.value(forKey: "isCompressed") as! Bool)
                let lastUpdated = (data.value(forKey: "dateUpdated") as! Date)
                let userCreated = (data.value(forKey: "userCreated") as! Bool)
                
                var photos = [PSPhoto]()
                let albumPhotos = data.mutableSetValue(forKey: "photos")
                
                for photoObject in albumPhotos {
                    let photoInAlbum = photoObject as AnyObject
                    let fileName = (photoInAlbum.value(forKey: "fileName") as! String)
                    let thumbnailPath = getDirectory(withName: "Library/Thumbnails").appendingPathComponent(fileName)
                    let localPath = getDirectory(withName: "Library/Photos").appendingPathComponent(fileName)
                    let hash = (photoInAlbum.value(forKey: "photohash") as! String)
                    let compressionEnabled = settings["compressionEnabled"] as? Bool
                    let timestamp = (photoInAlbum.value(forKey: "timestamp") as! Date)
                    let photo = PSPhoto(fileName: fileName, thumbnailPath: thumbnailPath, localPath: localPath, photoHash: hash, isCompressed: compressionEnabled ?? true, timestamp: timestamp)
                    photos.append(photo)
                    
                }
        
                let album = PSAlbum(title: albumName, isCompressed: isCompressed, lastUpdated: lastUpdated, userCreated: userCreated, photos: photos)
                albums.append(album)
            }
            os_log(.debug, log: OSLog.default, "Generated %d albums for view", albums.count)
        } catch {
            os_log(.error, log: OSLog.default, "Failed to generate albums")
        }
    }

    public func generatePhotos() {
        let appDelegate = AppDelegate.appDelegate
        let context = appDelegate!.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Photos")
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        do {
            let result = try context.fetch(request)
            photos = [PSPhoto]()
            for data in result as! [NSManagedObject] {
                let fileName = (data.value(forKey: "fileName") as! String)
                let thumbnailPath = getDirectory(withName: "Library/Thumbnails").appendingPathComponent(fileName)
                let localPath = getDirectory(withName: "Library/Photos").appendingPathComponent(fileName)
                let hash = (data.value(forKey: "photohash") as! String)
                let compressionEnabled = settings["compressionEnabled"] as? Bool
                let timestamp = (data.value(forKey: "timestamp") as! Date)
                let photo = PSPhoto(fileName: fileName, thumbnailPath: thumbnailPath, localPath: localPath, photoHash: hash, isCompressed: compressionEnabled ?? true, timestamp: timestamp)
                photos.append(photo)
            }
            os_log(.debug, log: OSLog.default, "Generated %d photos for view", photos.count)
        } catch {
            os_log(.error, log: OSLog.default, "Failed to generate photos")
        }
    }
    
    private func getMostRecentlyAddedPhoto() -> String{
        let appDelegate = AppDelegate.appDelegate
        let context = appDelegate!.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Photos")
        let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: false)
        request.fetchLimit = 1
        request.sortDescriptors = [sortDescriptor]
        var hash: String
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                hash = (data.value(forKey: "photohash") as! String)
                os_log(.debug, log: OSLog.default, "Most Recent photo hash: %@", hash)
                return hash
            }
        } catch {
            os_log(.error, log: OSLog.default, "Failed to grab most recent photo")
            
        }
        return ""
    }
    
    public func formatPhotos() {
        var index = 0
        for photo in photos {
            print("Global Photo:   \(index) Name: \(photo.fileName) Hash: \(photo.photoHash)")
            index += 1
        }
    }
    

    public func delete(photo: PSPhoto, index: Int) -> Bool{
        guard (connection?.isConnected()) != nil else {
            self.start()
            return false
        }
        os_log(.debug, log: OSLog.default, "Attempting to delete photo with hash %@ and name %@", photo.photoHash, photo.fileName)
        let success = connection?.delete(photo: photo.photoHash) ?? false
        if success {
            os_log(.debug, log: OSLog.default, "Server deleted photo with hash %@", photo.photoHash)
            let fileManager = FileManager.default
            let fullPath = getDirectory(withName: "Library/Photos").appendingPathComponent(photo.fileName)
            let thumbnailPath = getDirectory(withName: "Library/Thumbnails").appendingPathComponent(photo.fileName)
            do {
                
                let appDelegate = AppDelegate.appDelegate
                let context = appDelegate!.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Photos", in: context)
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photos")
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "photohash == %@", photo.photoHash)
                if let result = try? context.fetch(fetchRequest) {
                    let resultData = result[0] as! NSManagedObject
                    //let name = resultData.value(forKey: "fileName") as? String
                    //print("Deleting core data with name: \(name)")
                    context.delete(resultData)
                    try fileManager.removeItem(at: fullPath)
                    try fileManager.removeItem(at: thumbnailPath)
                    
                   
                    //print(photos[index].fileName)
                    //photos.remove(at: index)
                    os_log(.debug, log: OSLog.default, "Client deleted photo with hash %@ and at index %d", photo.photoHash, index)
                }
                do {
                    try context.save()
                    
                } catch {
                    print("Failed saving")
                }
                return true
            } catch {}
        }
        return false
        
    }
    
    public func sendPhoto(asset: PHAsset) {
        var rawData = Data()
        
        let timeStamp = DateFormatter.localizedString(from: asset.creationDate!, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short)
        var name = asset.originalFilename
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
        
       
        
        status = "Uploading Photo"
        guard (connection?.isConnected()) != nil else {
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
    

    
    
    public func connect(withSettings settings: [String : Any]) throws -> NetworkConnection {
        let settings = settings
        
        
        compressionEnabled = settings["compressionEnabled"] as? Bool
        do {
            connection = try NetworkConnection(
                hostName: settings["hostName"] as! String,
                port: settings["port"] as! Int,
                allowSelfSignedCerts: settings["allowSelfSignedCerts"] as! Bool,
                compressionEnabled: compressionEnabled!,
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
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
        
    }
    
    func getDirectory(withName name: String) -> URL {
        let path = getDocumentsDirectory().appendingPathComponent(name, isDirectory: true)
        return path
    }
    
   
    
    
    
}



//Logger
struct Log {
    static var general = OSLog(subsystem: "com.photoshare", category: "general")
    static var file = OSLog(subsystem: "com.photoshare", category: "file")
    static var network = OSLog(subsystem: "com.photoshare", category: "network")
}


