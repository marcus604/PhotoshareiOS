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
    let compressionLevels = [String](arrayLiteral: "None", "Low", "Medium", "High")
    
    @IBOutlet var settingFields: [UITextField]!
    @IBOutlet weak var hostNameTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var allowSelfSignedCertSwich: UISwitch!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var compressionText: UILabel!
    @IBOutlet weak var compressionSlider: UISlider!
    
    
    //Updates label
    //Look at updating this slider so it snaps into place
    @IBAction func compressionSliderChanged(_ sender: UISlider) {
        let level = Int(round(sender.value))
        compressionText.text = compressionLevels[level]
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
        
        //DEBUGGING, so I dont have to fill in fields
        if !fieldsValid {
            //need to set the self signed certs
            photoshare.set(compressionLevel: compressionSlider.value)
            photoshare.set(allowSelfSignedCerts: allowSelfSignedCertSwich.isOn)
            
            
            print("ready to go")
        }
        
        
        
        
        
    }
    
}
