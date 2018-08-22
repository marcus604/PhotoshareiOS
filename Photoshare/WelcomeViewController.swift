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
    @IBAction func connectButton(_ sender: UIButton) {
        do {
            let connection = try Connection(
                hostName: "10.10.1.67",
                port: 1428
            )
            connection.start()
            sleep(4)
        } catch {
            print("failed")
        }
    }
    
}
