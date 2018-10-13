//
//  ManageModeSwipeCard.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-11.
//  Copyright © 2018 Marcus. All rights reserved.
//

import UIKit

class ManageModeSwipeCard: MGSwipeCard {

    
    var model: PhotoCardModel? {
        didSet {
            configureCard()
        }
    }
    
    
    private func configureCard() {
        swipeDirections = [.left, .up, .right]
        
        model!.photo.loadLocalPhoto()
        let localPhoto = model!.photo.localPhoto
        let imageView = UIImageView(image: localPhoto)
        imageView.contentMode = .scaleAspectFit
        self.setContentView(imageView)
        swipeDirections.forEach { direction in
        setOverlay(forDirection: direction, overlay: overlay(forDirection: direction))
        }
    }
    
}
    
struct PhotoCardModel {
    var photo: PSPhoto
}


