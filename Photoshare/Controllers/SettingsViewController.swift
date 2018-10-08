//
//  SettingsViewController.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-03.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation
import UIKit
import Photos


class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    //All Text Fields
    @IBOutlet var settingFields: [UITextField]!
    
    //Network
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var selfSignedCertSwitch: UISwitch!
    
    //User
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //Storage
    @IBOutlet weak var compressionSwitch: UISwitch!
    
    var imagePicker = UIImagePickerController()
    
    @IBAction func importButton(_ sender: UIButton) {
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func connectButton(_ sender: UIButton) {
        var fieldsValid = true
        for textField in settingFields {
            if !checkForTextIn(textField: textField){
                fieldsValid = false
            } else {
                let text = textField.text!
                switch textField {
                case hostnameTextField:
                    Photoshare.shared().set(settingAsString: "hostName", to: text)
                case portTextField:
                    var int = Int(text) ?? 0
                    if int > 65535 || int < 1024 {
                        int = 0
                    }
                    Photoshare.shared().set(settingAsInt: "port", to: int)
                case userNameTextField:
                    Photoshare.shared().set(settingAsString: "userName", to: text)
                case passwordTextField:
                    Photoshare.shared().set(password: text)
                default:
                    break
                }
            }
        }
        
        Photoshare.shared().set(settingAsBool: "allowSelfSignedCerts", to: selfSignedCertSwitch.isOn)
        Photoshare.shared().set(settingAsBool: "compressionEnabled", to: compressionSwitch.isOn)
        
        if fieldsValid {
            connectionStatusLabel.text = Photoshare.shared().status
            DispatchQueue.global(qos: .userInitiated).async {
                Photoshare.shared().start()
                
                DispatchQueue.main.async {
                    self.connectionStatusLabel.text = Photoshare.shared().status
                }
            }
        }
    }
    
    //Verifies that textfield has text in it, if not sets border to red
    private func checkForTextIn(textField : UITextField) -> Bool{
        if textField.text?.isEmpty ?? true {
            textField.layer.borderColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            textField.layer.borderWidth = 1.0
            return false
        } else {
            textField.layer.borderWidth = 0
            return true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Photoshare.shared().getSettings()
        imagePicker.delegate = self
            
        if Photoshare.shared().settingsValid(with: settings) {
            hostnameTextField.insertText(settings["hostName"] as! String)
            portTextField.insertText("\(settings["port"] as! Int)")
            userNameTextField.insertText(settings["userName"] as! String)
            passwordTextField.insertText(settings["password"] as! String)
            
            selfSignedCertSwitch.setOn(settings["allowSelfSignedCerts"] as! Bool, animated: false)
            compressionSwitch.setOn(settings["compressionEnabled"] as! Bool, animated: false)
        }
        
        
        
        
    }
}

extension SettingsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case hostnameTextField:
            portTextField.becomeFirstResponder()
        case portTextField:
            userNameTextField.becomeFirstResponder()
        case userNameTextField:
            passwordTextField.becomeFirstResponder()
        default:
            passwordTextField.resignFirstResponder()
        }
        
        return true
    }
    
}

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
   
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageURL = info[UIImagePickerControllerImageURL] as? URL {
            print("ok")
            
            //print(asset?.value(forKey: "filename"))
        }
        var asset: PHAsset?
        //asset = info[.phAsset] as? PHAsset
        
        if let imagerefurl = info[UIImagePickerControllerReferenceURL] as? URL {
            print("ok")
        }
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            //img.image = image
            
            print("got image")
        }
        
        dismiss(animated: true, completion: nil)
    }
}
