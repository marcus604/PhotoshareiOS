//
//  Photo.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-03.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class PSPhoto {
    public var fullSizePhoto : UIImage?
    public var localPhoto : UIImage?
    public var thumbnail : UIImage?
    public var fullSizePath : URL?
    public var localPath : URL
    public var thumbnailPath : URL
    public var fileName : String
    public var photoHash : String
    public var isCompressed : Bool
    public var timestamp : Date
    
    
    
    init (fileName : String, thumbnailPath : URL, localPath : URL, photoHash : String, isCompressed: Bool, timestamp: Date) {
        self.fileName = fileName
        self.localPath = localPath
        self.photoHash = photoHash
        self.thumbnailPath = thumbnailPath
        self.isCompressed = isCompressed
        self.timestamp = timestamp
    }
    
   
    public func loadThumbnailPhoto() {
        do {
            self.thumbnail = UIImage(data : try Data(contentsOf: self.thumbnailPath))
        } catch {
            self.thumbnail = UIImage(named: "NO_IMAGE")
        }
        
    }
   
    public func loadLocalPhoto() {
        do {
            self.localPhoto = UIImage(data : try Data(contentsOf: self.localPath))
        } catch {
            self.localPhoto = UIImage(named: "NO_IMAGE")
        }
    }
    
    public func loadFullSizePhoto() {
        Photoshare.shared().getFullSizeImage(forPhoto: self)
    }
    
    func loadLocalPhoto(_ completion: @escaping (_ photo: PSPhoto, _ error: NSError?) -> Void) {
        
        self.localPhoto = UIImage(data : try! Data(contentsOf: self.localPath))
        DispatchQueue.main.async {
            completion(self, nil)
        }
        return
    }
    
    public func loadfullSizePhoto(_ completion: @escaping (_ photo: PSPhoto, _ error: NSError?) -> Void) {
        
        Photoshare.shared().getFullSizeImage(forPhoto: self)
        DispatchQueue.main.async {
            completion(self, nil)
        }
        return
    }
    
    
    public func sizeToFillWidthOfSize(_ size:CGSize) -> CGSize {
        
        guard let thumbnail = thumbnail else {
            return size
        }
        
        let imageSize = thumbnail.size
        var returnSize = size
        
        let aspectRatio = imageSize.width / imageSize.height
        
        returnSize.height = returnSize.width / aspectRatio
        
        if returnSize.height > size.height {
            returnSize.height = size.height
            returnSize.width = size.height * aspectRatio
        }
        
        return returnSize
    }
    
}
