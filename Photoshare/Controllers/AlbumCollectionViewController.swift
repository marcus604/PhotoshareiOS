//
//  AlbumCollectionViewController.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-12.
//  Copyright © 2018 Marcus. All rights reserved.
//

import UIKit
import os.log

private let reuseIdentifier = "Cell"

class AlbumCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "AlbumCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 1.0, right: 10.0)
    
    private var userAlbums =  [PSAlbum]()
    private var smartAlbums = [PSAlbum]()
    
    private var albums = [PSAlbum]()
    
    fileprivate let itemsPerRow: CGFloat = 2
    
    var coverPhotoIndexPath: IndexPath? {
        didSet {
            
            var indexPaths = [IndexPath]()
            if let coverPhotoIndexPath = coverPhotoIndexPath {
                indexPaths.append(coverPhotoIndexPath)
            }
            if let oldValue = oldValue {
                indexPaths.append(oldValue)
            }
            
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadItems(at: indexPaths)
            }) { completed in
                
                if let coverPhotoIndexPath = self.coverPhotoIndexPath {
                    self.collectionView?.scrollToItem(
                        at: coverPhotoIndexPath,
                        at: .centeredVertically,
                        animated: true)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        albums = Photoshare.shared().getAlbums()
        if albums.count == 0 {
            print("No Albums")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        os_log(.debug, log: OSLog.default, "viewWillAppear: AlbumCollection")
        albums = Photoshare.shared().getAlbums()
        collectionView?.reloadData()
    }

    

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1    
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        os_log(.debug, log: OSLog.default, "Collection view has %d albums", albums.count)
        return albums.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumCell
        
        cell.contentView.layer.cornerRadius = 30
        cell.contentView.layer.borderWidth = 1.0

        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true

        cell.layer.shadowColor = UIColor.gray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 1.0
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath
        
        let album = albumForIndexPath(indexPath: indexPath)
        
        //If album is blank, only show the text
        if album.photos.count == 0 {
            cell.albumNameLabel.text = album.title
            cell.imageView.image = nil
            return cell
        }
        album.loadCoverPhoto()
        
        cell.imageView.image = album.coverPhoto.localPhoto
        cell.albumNameLabel.text = album.title
        
        
        
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath == coverPhotoIndexPath {
            let album = albumForIndexPath(indexPath: indexPath)
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return album.coverPhoto.sizeToFillWidthOfSize(size)
        }
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = albumForIndexPath(indexPath: indexPath)
        if album.photos.count == 0 {
            return  //Cant open empty album
        }
        let viewController = storyboard?.instantiateViewController(withIdentifier: "PhotosCollectionController") as? PhotosCollectionController
               
        if let viewController = viewController {
            let album = albumForIndexPath(indexPath: indexPath)
            viewController.collectionView?.refreshControl = nil     //Dont allow pull down to refresh in album view
            viewController.photos = album.photos
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }

    
}

private extension AlbumCollectionViewController {
    func albumForIndexPath(indexPath: IndexPath) -> PSAlbum {
        let index = (indexPath as IndexPath).row
        return albums[index]
    }
}
