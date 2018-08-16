//
//  ViewController.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-16.
//  Copyright © 2018 Marcus. All rights reserved.
//

import UIKit



class ViewController: UIViewController {

    
    @IBAction func connectButton(_ sender: UIButton) {
        let connectionManager = ConnectionManager(
            ipAddress: "youwontbelieveme.duckdns.org",
            serverPort: 1428
        )
        connectionManager.connect()
    }
    

}

