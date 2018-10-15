//
//  PhotosCollectionController.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-03.
//  Copyright © 2018 Marcus. All rights reserved.
//

import UIKit
import CoreData
import os.log

private let reuseIdentifier = "Cell"

class PhotosCollectionController: UICollectionViewController {

    // MARK: - Properties
    fileprivate let reuseIdentifier = "PhotoCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)

    private let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    public var photos = [PSPhoto]()
    
    fileprivate let itemsPerRow: CGFloat = 4
    
    var fullSizePhotoIndexPath: IndexPath? {
        didSet {
            
            var indexPaths = [IndexPath]()
            if let fullSizePhotoIndexPath = fullSizePhotoIndexPath {
                indexPaths.append(fullSizePhotoIndexPath)
            }
            if let oldValue = oldValue {
                indexPaths.append(oldValue)
            }
            
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadItems(at: indexPaths)
            }) { completed in
                
                if let fullSizePhotoIndexPath = self.fullSizePhotoIndexPath {
                    self.collectionView?.scrollToItem(
                        at: fullSizePhotoIndexPath,
                        at: .centeredVertically,
                        animated: true)
                }
            }
        }
    }
    
    
    //First entry
    override func viewDidLoad() {
        super.viewDidLoad()
        os_log(.debug, log: OSLog.default, "viewDidLoad: PhotosCollection")
        if photos.count == 0 {
            photos = Photoshare.shared().getPhotos()
        }
        
        collectionView?.refreshControl = refreshControl
        setupActivityIndicatorView()
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshPhotoLibraryData(_:)), for: .valueChanged)
        
        if Photoshare.shared().allSettingsValid {
            DispatchQueue.global().async {
                Photoshare.shared().start()
                if Photoshare.shared().isConnected {
                    Photoshare.shared().sync()
                }
            }
        }
    }
    
    @objc private func refreshPhotoLibraryData(_ sender: Any) {
        fetchPhotoLibraryData()
    }
    
    private func fetchPhotoLibraryData() {
        let loadPhotoLibraryWorkItem = DispatchWorkItem {
            if !Photoshare.shared().isConnected {
                Photoshare.shared().start()
            }
            Photoshare.shared().generatePhotos()
            Photoshare.shared().generateAlbums()
            self.photos = Photoshare.shared().getPhotos()
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.refreshControl.endRefreshing()
                self.activityIndicatorView.stopAnimating()
            }
        }
        
        
        DispatchQueue.global(qos: .utility).async(execute: loadPhotoLibraryWorkItem)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        os_log(.debug, log: OSLog.default, "viewWillAppear: PhotosCollection")
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        if photos.count == 0 {
            photos = Photoshare.shared().getPhotos()
        }
        
        collectionView?.reloadData()
    }
    
    private func setupActivityIndicatorView() {
        //activityIndicatorView.startAnimating()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getDirectory(withName name: String) -> URL {
        let path = getDocumentsDirectory().appendingPathComponent(name, isDirectory: true)
        return path
    }
    
}

// MARK: - Private
private extension PhotosCollectionController {
    func photoForIndexPath(indexPath: IndexPath) -> PSPhoto {
        let index = (indexPath as IndexPath).row
        return photos[index]
    }
}


extension PhotosCollectionController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath == fullSizePhotoIndexPath {
            let photo = photoForIndexPath(indexPath: indexPath)
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return photo.sizeToFillWidthOfSize(size)
        }
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
   
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

// MARK: - UICollectionViewDataSource
extension PhotosCollectionController {

//           If I want to split up by month
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return months.count
//    }
    
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        os_log(.debug, log: OSLog.default, "Collection view has %d photos", photos.count)
        return photos.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! PhotoCell
        
        let photo = photoForIndexPath(indexPath: indexPath)
    
        photo.loadThumbnailPhoto()
        cell.imageView.image = photo.thumbnail
        
        
        return cell
    }
}


//Photo Selected
extension PhotosCollectionController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "PhotoDetailStoryboard") as? PhotoDetailViewController
        if let viewController = viewController {
            let photo = photoForIndexPath(indexPath: indexPath)
            photo.loadLocalPhoto()
            viewController.photos = photos
            viewController.photo = photo
            viewController.indexPath = indexPath
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: - UICollectionViewDelegate
//extension PhotosCollectionController {
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 shouldSelectItemAt indexPath: IndexPath) -> Bool {
//
//        fullSizePhotoIndexPath = fullSizePhotoIndexPath == indexPath ? nil : indexPath
//        print("selected")
//        return false
//    }
//}


