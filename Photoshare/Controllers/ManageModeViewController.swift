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



class ManageModeViewController: UIViewController, MGCardStackViewDelegate, MGCardStackViewDataSource{
    
    

    
    var photos: [PSPhoto]!
    var indexPath: IndexPath!
    var fullIndex: Int!
    var photo: PSPhoto!
    var deleteWorkStack = DeleteWorkStack()
    
    
    
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
    
    
    @objc private func doneTapped() {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "PhotosCollectionController") as? PhotosCollectionController
        if let viewController = viewController {
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
        var currentFullIndex = self.fullIndex
        self.fullIndex += 1
        switch direction {
            //Delete Photo
            case SwipeDirection.left:
                self.fullIndex -= 1     //If delete is successful than we're back one space
                let photo = photos[index]
                let deletePhotoWorkItem = DispatchWorkItem {
                    if !Photoshare.shared().isConnected {
                        Photoshare.shared().start()
                    }
                    let deleteResult = Photoshare.shared().delete(photo: photo, index: currentFullIndex!)
                    self.deleteWorkStack.complete()
                }
                deleteWorkStack.push(deletePhotoWorkItem)
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(5000),
                                                  execute: deletePhotoWorkItem)
            case SwipeDirection.up:
                print("add to album")
            default:    //Swipe is right, dont need to do anything
                break
        }
    }
    
    
    //Undo
    func cardStack(_ cardStack: MGCardStackView, didUndoSwipeOnCardAt index: Int, from direction: SwipeDirection) {
        fullIndex -= 1
        if direction == SwipeDirection.left {   //If deleted
            if !deleteWorkStack.isEmpty {
                deleteWorkStack.pop()!.cancel()
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

