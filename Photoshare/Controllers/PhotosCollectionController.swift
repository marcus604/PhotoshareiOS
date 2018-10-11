//
//  PhotosCollectionController.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-03.
//  Copyright © 2018 Marcus. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "Cell"

class PhotosCollectionController: UICollectionViewController {

    // MARK: - Properties
    fileprivate let reuseIdentifier = "PhotoCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)

    //fileprivate var months = [Date]()
    fileprivate var photos = [PSPhoto]()
    
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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = Photoshare.shared().getSettings()
        
        
        if Photoshare.shared().settingsValid(with: settings) {
            DispatchQueue.global(qos: .userInitiated).async {
                Photoshare.shared().start()
                if Photoshare.shared().isConnected {
                    Photoshare.shared().sync()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        do {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
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
                    let thumbnail = UIImage(data : try! Data(contentsOf: thumbnailPath))
                    let hash = (data.value(forKey: "photohash") as! String)
                    let photo = PSPhoto(fileName: fileName, thumbnail: thumbnail!, localPath: localPath, photoHash: hash, isCompressed: Photoshare.shared().compressionEnabled!)
                    photos.append(photo)
                }
                
            } catch {
                
                print("Failed")
            }
        } catch {
            print(error)
        }
        collectionView?.reloadData()
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
        return photos[(indexPath as IndexPath).row]
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
        return photos.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! PhotoCell
        
        let photo = photoForIndexPath(indexPath: indexPath)
    
        
        //Not viewing an individual photo, everything is a thumbnail
        guard indexPath == fullSizePhotoIndexPath else {
            cell.imageView.image = photo.thumbnail
            photo.localPhoto = nil
            photo.fullSizePhoto = nil
            return cell
        }
        
        
        return cell
    }
}

extension PhotosCollectionController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("pressed")
        let viewController = storyboard?.instantiateViewController(withIdentifier: "PhotoDetailStoryboard") as? PhotoDetailViewController
        if let viewController = viewController {
            let photo = photoForIndexPath(indexPath: indexPath)
            
            viewController.photo = photo
            viewController.indexPath = indexPath
            viewController.image = photo.thumbnail
            photo.loadLocalPhoto()
            viewController.image = photo.localPhoto
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


