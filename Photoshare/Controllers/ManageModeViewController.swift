//
//  ManageModeViewController.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-11.
//  Copyright © 2018 Marcus. All rights reserved.
//

import UIKit
import CoreData
import os.log



class ManageModeViewController: UIViewController, MGCardStackViewDelegate, MGCardStackViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate{
    
    
    
    

    
    var photos: [PSPhoto]!
    var indexPath: IndexPath!
    var fullIndex: Int!
    var currentPhoto: PSPhoto!
    var deleteWorkStack = DeleteWorkStack()
    private var deletedPhotos = 0
    
    
    @IBOutlet weak var cardStackView: MGCardStackView!
    
    
    
    var cardModels: [PhotoCardModel] {
        var models = [PhotoCardModel]()
        
        for index in 0..<photos.count {
            let photo = photos[index]
            let model = PhotoCardModel(photo: photo)
            models.append(model)
        }
        
        return models
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        os_log(.debug, log: OSLog.default, "viewDidLoad: ManageMode")
        view.backgroundColor = .white
        fullIndex = indexPath[1]
        createViews()
        cardStackView.delegate = self
        cardStackView.dataSource = self
        
    }
    
    private func createViews() {
        let backButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        let undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undoTapped))
        
        
        navigationItem.leftItemsSupplementBackButton = false
        navigationItem.rightBarButtonItem = undoButton
        navigationItem.leftBarButtonItem = backButton
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        os_log(.debug, log: OSLog.default, "viewWillDissapear: ManageMode")
        Photoshare.shared().generatePhotos()
        Photoshare.shared().generateAlbums()
    }
    
    @objc private func doneTapped() {
        Photoshare.shared().generatePhotos()
        Photoshare.shared().generateAlbums()
        var viewControllerToLoad: UIViewController!
        if let navController = self.navigationController, navController.viewControllers.count >= 4 {
            print("number of navs  \(navController.viewControllers.count)")
            for vc in navController.viewControllers {
                print(vc)
            }
            let viewController = navController.viewControllers[navController.viewControllers.count - 4]
            if viewController.isKind(of: AlbumCollectionViewController.self) {
                viewControllerToLoad = storyboard?.instantiateViewController(withIdentifier: "AlbumCollectionViewController") as? AlbumCollectionViewController
                viewControllerToLoad.navigationItem.hidesBackButton = true
            } else {
                viewControllerToLoad = storyboard?.instantiateViewController(withIdentifier: "PhotosCollectionController") as? PhotosCollectionController
            }
        } else {
            viewControllerToLoad = storyboard?.instantiateViewController(withIdentifier: "PhotosCollectionController") as? PhotosCollectionController
        }
        
        if let viewController = viewControllerToLoad {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    @objc private func undoTapped() {
        cardStackView.undoLastSwipe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        os_log(.debug, log: OSLog.default, "viewWillAppear: ManageMode")

    }
    
    //Delegates
    func didSwipeAllCards(_ cardStack: MGCardStackView) {
        print("Swiped all cards!")
    }
    
    
    //Handle Swipe actions
    //Card index is relative and cant be used to alter the larger dataset
    //Keep track of full index
    //Every Swipe moves forward
    //Upon deleting, entire size shrinks, so index stays in same space
    //Waits 5 seconds before committing to delete
    //Gives user plenty of time to undo an accidental deletion
    func cardStack(_ cardStack: MGCardStackView, didSwipeCardAt index: Int, with direction: SwipeDirection) {
        //Photoshare.shared().formatPhotos()
        let currentFullIndex = self.fullIndex
        self.fullIndex += 1
        //print("Interacting with index:  \(currentFullIndex)")
        currentPhoto = photos[index]
        print(currentPhoto.fileName)
        
        switch direction {

            //DELETE PHOTO
            case SwipeDirection.left:
                
                
                let photoToDelete = self.currentPhoto
                let deletePhotoWorkItem = DispatchWorkItem {
                    if !Photoshare.shared().isConnected {
                        Photoshare.shared().start()
                    }
                    let deleteResult = Photoshare.shared().delete(photo: photoToDelete!, index: currentFullIndex!)
                    self.deleteWorkStack.complete()
                    
                }
                deleteWorkStack.push(deletePhotoWorkItem)
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(5000),
                                                  execute: deletePhotoWorkItem)


            //Add photo to album
            case SwipeDirection.up:
                presentAlbumPicker()
            default:    //Swipe is right, dont need to do anything
                break
        }
        
    }
    
    public func formatPhotos(photos: [PSPhoto]) {
        var index = 0
        for photo in photos {
            print("Local Photo:   \(index) Name: \(photo.fileName) Hash: \(photo.photoHash)")
            index += 1
        }
    }
    
    
    
    //Presents user with existing albums or option create a new album
    //
    func presentAlbumPicker(){
        let alertController = UIAlertController(title: nil, message: "Select an Album", preferredStyle: .actionSheet)
        
        //Generate list of albums
        for album in Photoshare.shared().getAlbums() {
            let albumAction = UIAlertAction(title: album.title, style: .default, handler: { (action) in
                if !Photoshare.shared().add(photo: self.currentPhoto, toAlbum: action.title!) {
                    let alert = UIAlertController(title: "Error", message: "Photo already exists in album", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                    
                }
                Photoshare.shared().generateAlbums()
            })
            alertController.addAction(albumAction)
        }
        
        //Create new album
        let createNewAlbumActionSheet = UIAlertAction(title: "New Album", style: .destructive) { (action) in
            
            
            let requestAlbumAlert = UIAlertController(title: "Album Name", message: nil, preferredStyle: .alert)
            requestAlbumAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            //Only enabled text field if there is text
            requestAlbumAlert.addTextField(configurationHandler: { textField in
                textField.addTarget(self, action: #selector(self.textChanged(_:)), for: UIControl.Event.editingChanged)
            })
            
            
            let okButton = UIAlertAction(title: "OK", style: .default, handler: { action in
                if let name = requestAlbumAlert.textFields?.first?.text {
                    if !Photoshare.shared().createNewAlbum(withName: name, userCreated: true) {       //Photos generated through UI will always be user created
                        let alert = UIAlertController(title: "Album already exists", message: "Photo has not been added", preferredStyle: .alert)
                       
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        
                        self.present(alert, animated: true)
                        return
                    }
                    Photoshare.shared().add(photo: self.currentPhoto, toAlbum: name)
                    Photoshare.shared().generateAlbums()
                }
            })
            okButton.isEnabled = false  //Dont enable button until there is text
            
            requestAlbumAlert.addAction(okButton)
            
            self.present(requestAlbumAlert, animated: true)
        }
        
        
        alertController.addAction(createNewAlbumActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            //No required action
        }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
    
  
    
    
    //Undo
    func cardStack(_ cardStack: MGCardStackView, didUndoSwipeOnCardAt index: Int, from direction: SwipeDirection) {
        fullIndex -= 1
        if direction == SwipeDirection.left {   //If deleted
            if !deleteWorkStack.isEmpty {
                deleteWorkStack.pop()!.cancel()
                fullIndex += 1
                os_log(.debug, log: OSLog.default, "Cancelled Deletion of Photo")
            } else {
                os_log(.debug, log: OSLog.default, "Delete already processed")
            }
        }//Adding to album is 2 presses, less accident prone
        
    }
    
    
    
    func additionalOptions(_ cardStack: MGCardStackView) -> MGCardStackViewOptions {
        let options = MGCardStackViewOptions()
        options.numberOfVisibleCards = 1
        options.cardStackInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        options.cardSwipeAnimationMaximumDuration = 0.3
        options.backgroundCardScaleAnimationDuration = 0.1
        return options
    }
    
    //Data Sources
    func numberOfCards(in cardStack: MGCardStackView) -> Int {
        return photos.count
    }
    
    func cardStack(_ cardStack: MGCardStackView, cardForIndexAt index: Int) -> MGSwipeCard {
        let card = ManageModeSwipeCard()
        card.model = cardModels[index]
        return card
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getDirectory(withName name: String) -> URL {
        let path = getDocumentsDirectory().appendingPathComponent(name, isDirectory: true)
        return path
    }
    
    //UIPicker Datasource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    //UIPicker Delegate
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }
    
    @objc func textChanged(_ sender:UITextField) {
        let alertController:UIAlertController = self.presentedViewController as! UIAlertController
        let textField :UITextField  = alertController.textFields![0]
        let okAction: UIAlertAction = alertController.actions[1]
        okAction.isEnabled = (textField.text?.count != 0)
    }
}

struct DeleteWorkStack {
    private var workItems: [DispatchWorkItem] = []
    
    mutating func push(_ element: DispatchWorkItem) {
        workItems.append(element)
    }
    
    mutating func pop() -> DispatchWorkItem? {
        return workItems.popLast()
    }
    
    mutating func complete() {
        if !workItems.isEmpty { workItems.remove(at: 0) }
    }
    
    var isEmpty: Bool {
        return workItems.isEmpty
    }
}

