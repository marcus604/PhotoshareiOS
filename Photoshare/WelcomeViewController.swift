//
//  WelcomeViewController.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-21.
//  Copyright © 2018 Marcus. All rights reserved.
//

import UIKit


class WelcomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    private var photoshare = Photoshare()
    
    
    @IBAction func hostNameFieldDidChange(_ sender: UITextField) {
        print("host changed")
        if let text = sender.text {
            photoshare.set(hostName: text)
        }
        
    }
    
    //Updates port, checks if empty and converts to int
    @IBAction func portFieldDidChange(_ sender: UITextField) {
        print("port changed")
        if let text = sender.text {
            photoshare.set(port: text)
        }
    }
    @IBAction func connectButton(_ sender: UIButton) {
        
    }
    
}
