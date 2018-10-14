//
//  PhotoAlbum.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-12.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import UIKit
import os.log

class PSAlbum {
    
    var photos: [PSPhoto]!
    var isCompressed: Bool!
    var dateCreated: Date!
    var dateUpdated: Date!
    var title: String!
    var userCreated: Bool!
    var coverPhoto: PSPhoto!
    
    init(title: String, isCompressed: Bool, lastUpdated: Date, userCreated: Bool, photos: [PSPhoto]) {
        self.title = title
        self.isCompressed = isCompressed
        self.dateUpdated = lastUpdated
        self.userCreated = userCreated
        self.photos = photos
    }
    
    private func photoExists(photo newPhoto: PSPhoto) -> Bool{
        for photo in photos {
            if newPhoto.photoHash == photo.photoHash{
                os_log(.info, log: OSLog.default, "Photo aleady exists in album")
                return false
            }
        }
        return true
    }
    
    public func loadCoverPhoto() {
        coverPhoto = photos[0]
        coverPhoto.loadLocalPhoto()
    }
    
    public func add(photo: PSPhoto) -> Bool{
        if photoExists(photo: photo){
            return false
        }
        photos.append(photo)
        return true
    }
    
    
}
