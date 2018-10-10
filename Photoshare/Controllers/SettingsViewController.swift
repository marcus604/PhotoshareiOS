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
        PHPhotoLibrary.requestAuthorization({
            (newStatus) in
            if newStatus ==  PHAuthorizationStatus.authorized {
                self.imagePicker.sourceType = .photoLibrary
                self.imagePicker.allowsEditing = false
                
            }
        })
        

        //imagePicker.sourceType = .photoLibrary
        //imagePicker.allowsEditing = false
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
                if Photoshare.shared().isConnected {
                    Photoshare.shared().sync()
                }
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
    
   
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset else {
            print("couldnt get asset")
            return
        }
        
            //Prints out all metadata in photodata
//        if let imageURL = info[UIImagePickerController.InfoKey.imageURL] as? URL {
//            var fullImage = CIImage(contentsOf: imageURL)!
//            print(fullImage.properties)
//        }

        
        DispatchQueue.global(qos: .userInitiated).async {
            if Photoshare.shared().isConnected == false {
                Photoshare.shared().start()
            }
            Photoshare.shared().sendPhoto(asset: asset)
            Photoshare.shared().sync()
            DispatchQueue.main.async {
                self.connectionStatusLabel.text = Photoshare.shared().status
            }
        }
        
        
        dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

extension PHAsset {
    var originalFilename: String? {
        return PHAssetResource.assetResources(for: self).first?.originalFilename
    }
}

