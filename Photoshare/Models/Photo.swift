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
    var fullSizePhoto : UIImage?
    var localPhoto : UIImage?
    var thumbnail : UIImage?
    var fullSizePath : URL?
    var localPath : URL
    var thumbnailPath : URL
    var fileName : String
    var photoHash : String
    var isCompressed : Bool
    
    
    
    init (fileName : String, thumbnailPath : URL, localPath : URL, photoHash : String, isCompressed: Bool) {
        self.fileName = fileName
        self.localPath = localPath
        self.photoHash = photoHash
        self.thumbnailPath = thumbnailPath
        self.isCompressed = isCompressed
    }
    
   
    func loadThumbnailPhoto() {
        do {
            self.thumbnail = UIImage(data : try Data(contentsOf: self.thumbnailPath))
        } catch {
            self.thumbnail = UIImage(named: "NO_IMAGE")
        }
        
    }
   
    func loadLocalPhoto() {
        do {
            self.localPhoto = UIImage(data : try Data(contentsOf: self.localPath))
        } catch {
            self.localPhoto = UIImage(named: "NO_IMAGE")
        }
    }
    
    func loadFullSizePhoto() {
        Photoshare.shared().getFullSizeImage(forPhoto: self)
    }
    
    func loadLocalPhoto(_ completion: @escaping (_ photo: PSPhoto, _ error: NSError?) -> Void) {
        
        self.localPhoto = UIImage(data : try! Data(contentsOf: self.localPath))
        DispatchQueue.main.async {
            completion(self, nil)
        }
        return
    }
    
    func loadfullSizePhoto(_ completion: @escaping (_ photo: PSPhoto, _ error: NSError?) -> Void) {
        
        Photoshare.shared().getFullSizeImage(forPhoto: self)
        DispatchQueue.main.async {
            completion(self, nil)
        }
        return
    }
    
    
    func sizeToFillWidthOfSize(_ size:CGSize) -> CGSize {
        
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
