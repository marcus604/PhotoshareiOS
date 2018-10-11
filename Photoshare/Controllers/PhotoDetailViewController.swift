//
//  PhotoDetailViewController.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-10.
//  Copyright © 2018 Marcus. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {

    var hideNavItems = false
    
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage!
    var photo: PSPhoto!
    var indexPath: IndexPath!
    
    var editButton: UIBarButtonItem!
   
    @IBOutlet var toggleViewGesture: UITapGestureRecognizer!
    
    @IBAction func tapAnywhere(_ sender: Any) {
        hideNavItems = !hideNavItems
        if hideNavItems {
            view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        } else {
            view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        setNeedsStatusBarAppearanceUpdate()
        toggleNavItems()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(image != nil, "Image not set; required to use view controller")
        imageView.image = image
        editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))
        editButton.isEnabled = false

        navigationItem.rightBarButtonItem = editButton
        //Fullsize photo is available
        guard photo.fullSizePhoto == nil else {
            imageView.image = photo.fullSizePhoto
            return
        }

        let loadFullSizeWorkItem = DispatchWorkItem {
            if !Photoshare.shared().isConnected {
                Photoshare.shared().start()
            }
            self.photo.loadfullSizePhoto { loadedPhoto, error in

                guard loadedPhoto.fullSizePhoto != nil && error == nil else {
                    return
                }

                DispatchQueue.main.async {
                    self.imageView.image = loadedPhoto.fullSizePhoto
                    self.editButton.isEnabled = true
                }
                
            }
        }

        DispatchQueue.global().async(execute: loadFullSizeWorkItem)
    }
    
    @objc private func editTapped() {
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        navigationController?.navigationBar.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        let cropButton = UIBarButtonItem(title: "Crop", style: .plain, target: self, action: #selector(cropTapped))
        let rotateButton = UIBarButtonItem(title: "Rotate", style: .plain, target: self, action: #selector(rotateTapped))
        
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.leftBarButtonItems = [cropButton, rotateButton]
        
        hideNavItems = !hideNavItems
        setNeedsStatusBarAppearanceUpdate()
        toggleViewGesture.isEnabled = false
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    @objc private func saveTapped() {
        print("save")
        Photoshare.shared().updatePhoto(forPhoto: photo, image: self.imageView.image!)
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        navigationController?.navigationBar.tintColor = UIView().tintColor!
        self.tabBarController?.tabBar.isHidden = false
        
        navigationItem.rightBarButtonItem = editButton
        navigationItem.leftBarButtonItems = nil
        toggleViewGesture.isEnabled = true
        
        hideNavItems = !hideNavItems
        setNeedsStatusBarAppearanceUpdate()
        
    }
    
    @objc private func cropTapped() {
        print("crop")
    }
    
    @objc private func rotateTapped() {
        print("hi")
        image = imageView.image
        let rotatedImage = image.fixedOrientation().imageRotatedByDegrees(degrees: 90.0)
        imageView.image = rotatedImage
    }
    
    
    
    private func toggleNavItems() {
        self.tabBarController?.tabBar.isHidden = hideNavItems
        self.navigationController?.setNavigationBarHidden(hideNavItems, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        navigationController?.navigationBar.tintColor = UIView().tintColor!
        hideNavItems = false
        toggleNavItems()
        setNeedsStatusBarAppearanceUpdate()
    }
    //Default is show everything
    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        super.viewWillAppear(animated)
        toggleNavItems()
    }
    
    override var prefersStatusBarHidden: Bool {
        return hideNavItems
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }


    public func fixedOrientation() -> UIImage {
        if imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImage.Orientation.down, UIImage.Orientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi/2)
            break
        case UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat.pi/2)
            break
        case UIImage.Orientation.up, UIImage.Orientation.upMirrored:
            break
        }
        
        switch imageOrientation {
        case UIImage.Orientation.upMirrored, UIImage.Orientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImage.Orientation.leftMirrored, UIImage.Orientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImage.Orientation.up, UIImage.Orientation.down, UIImage.Orientation.left, UIImage.Orientation.right:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil,
                                       width: Int(size.width),
                                       height: Int(size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored, UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
}
