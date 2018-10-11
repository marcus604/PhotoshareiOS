//
//  Photo.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-03.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import UIKit


class PSPhoto {
    var fullSizePhoto : UIImage?
    var localPhoto : UIImage?
    var thumbnail : UIImage?
    var localPath : URL
    var fileName : String
    var photoHash : String
    var isCompressed : Bool
    
    
    
    init (fileName : String, thumbnail : UIImage, localPath : URL, photoHash : String, isCompressed: Bool) {
        self.fileName = fileName
        self.thumbnail = thumbnail
        self.localPath = localPath
        self.photoHash = photoHash
        self.isCompressed = isCompressed
    }
    
   
    func loadLocalPhoto() {
        self.localPhoto = UIImage(data : try! Data(contentsOf: self.localPath))
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
