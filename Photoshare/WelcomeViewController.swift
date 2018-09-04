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
    
    @IBOutlet var settingFields: [UITextField]!
    @IBOutlet weak var hostNameTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var allowSelfSignedCertSwich: UISwitch!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
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
    
    @IBAction func allowSelfSignedCertSwitch(_ sender: UISwitch) {

        if sender.isOn {
            photoshare.set(allowSelfSignedCerts: true)
        } else {
            photoshare.set(allowSelfSignedCerts: false)
        }
    }
    
    //Verifies that textfield has text in it, if not sets border to red
    private func checkForTextIn(textField : UITextField) -> Bool{
        if textField.text?.isEmpty ?? true {
            textField.layer.borderColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
            textField.layer.borderWidth = 1.0
            return false
        } else {
            textField.layer.borderWidth = 0
            return true
        }
    }
    
    @IBAction func connectButton(_ sender: UIButton) {
        //Check if all fields are valid
        var fieldsValid = true
        for textField in settingFields {
            if !checkForTextIn(textField: textField){
                fieldsValid = false
            } else {
                let text = textField.text!
                switch textField {
                case hostNameTextField:
                    photoshare.set(hostName: text)
                case portTextField:
                    photoshare.set(port: text)
                case userNameTextField:
                    photoshare.set(hostName: text)
                case passwordTextField:
                    photoshare.set(password: text)
                default:
                    break
                }
            }
        }
        
        if fieldsValid {
            //need to set the self signed certs
            
            print("ready to go")
        }
        
        
        
        
        
    }
    
}
