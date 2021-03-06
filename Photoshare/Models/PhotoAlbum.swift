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
    
    var photos =  [PSPhoto]()
    var isCompressed: Bool!
    var dateCreated: Date!
    var dateUpdated: Date!
    var title: String!
    var userCreated: Bool!
    var coverPhoto: PSPhoto!
    
    //Create instance of new album
    init(title: String, isCompressed: Bool, lastUpdated: Date, userCreated: Bool) {
        self.title = title
        self.isCompressed = isCompressed
        self.dateUpdated = lastUpdated
        self.userCreated = userCreated
    }
    
    //Create instance of existing album
    init(title: String, isCompressed: Bool, lastUpdated: Date, userCreated: Bool, photos: [PSPhoto]) {
        self.title = title
        self.isCompressed = isCompressed
        self.dateUpdated = lastUpdated
        self.userCreated = userCreated
        self.photos = photos
        
    }
    

    
    //Doesnt get called unless [photos] is non zero
    public func loadCoverPhoto() {
        coverPhoto = photos[0]
        coverPhoto.loadLocalPhoto()
    }
    

    
}
