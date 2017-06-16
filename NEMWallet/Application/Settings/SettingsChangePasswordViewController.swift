//
//  SettingsChangePasswordViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The view controller that lets the user change the current application password.
final class SettingsChangePasswordViewController: UITableViewController {
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmNewPasswordTextField: UITextField!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateViewControllerAppearance()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            currentPasswordTextField.becomeFirstResponder()
            
        case 1:
            newPasswordTextField.becomeFirstResponder()
            
        case 2:
            confirmNewPasswordTextField.becomeFirstResponder()
            
        default:
            break
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "PASSWORD_CHANGE_CONFIG".localized()
        currentPasswordTextField.placeholder = "OLD_PASSWORD_PLACEHOLDER".localized()
        newPasswordTextField.placeholder = "PASSWORD_PLACEHOLDER".localized()
        confirmNewPasswordTextField.placeholder = "REPEAT_PASSWORD_PLACEHOLDER".localized()
    }
    
    /**
        Shows an alert view controller with the provided alert message.
     
        - Parameter message: The message that should get shown.
        - Parameter completion: An optional action that should get performed on completion.
     */
    fileprivate func showAlert(withMessage message: String, completion: ((Void) -> Void)? = nil) {
        
        let alert = UIAlertController(title: "INFO".localized(), message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            alert.dismiss(animated: true, completion: nil)
            completion?()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    /// Validates and changes the new application password.
    fileprivate func changeApplicationPassword() {
        
        guard currentPasswordTextField.text != nil else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        guard newPasswordTextField.text != nil else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        guard confirmNewPasswordTextField.text != nil else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        guard currentPasswordTextField.text! != "" && newPasswordTextField.text! != "" && confirmNewPasswordTextField.text! != "" else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        guard newPasswordTextField.text!.characters.count >= 6 else {
            showAlert(withMessage: "PASSOWORD_LENGTH_ERROR".localized())
            confirmNewPasswordTextField.text = ""
            return
        }
        guard newPasswordTextField.text! == confirmNewPasswordTextField.text! else {
            showAlert(withMessage: "PASSOWORD_DIFERENCE_ERROR".localized())
            confirmNewPasswordTextField.text = ""
            return
        }
        
        let salt = SettingsManager.sharedInstance.authenticationSalt()
        let saltData = NSData.fromHexString(salt!)
        let encryptedPassword = SettingsManager.sharedInstance.applicationPassword()
        
        let passwordData: NSData? = try! HashManager.generateAesKeyForString(currentPasswordTextField.text!, salt: saltData, roundCount: 2000)!
        
        guard passwordData?.toHexString() == encryptedPassword else {
            showAlert(withMessage: "WRONG_OLD_PASSWORD".localized())
            currentPasswordTextField.text = ""
            return
        }
        
        let newApplicationPassword = newPasswordTextField.text!
        let newSaltData = salt != nil ? NSData(bytes: salt!.asByteArray(), length: salt!.asByteArray().count) : NSData().generateRandomIV(32) as NSData
        let newPasswordHash = try! HashManager.generateAesKeyForString(newApplicationPassword, salt: newSaltData, roundCount: 2000)!
        
        let accounts = AccountManager.sharedInstance.accounts()
        for account in accounts {
            
            let accountPrivateKey = AccountManager.sharedInstance.decryptPrivateKey(encryptedPrivateKey: account.privateKey)
            let newEncryptedAccountPrivateKey = AccountManager.sharedInstance.encryptPrivateKey(accountPrivateKey, withApplicationPassword: newPasswordHash.hexadecimalString())
            AccountManager.sharedInstance.updatePrivateKey(forAccount: account, withNewPrivateKey: newEncryptedAccountPrivateKey)
        }
        
        SettingsManager.sharedInstance.setApplicationPassword(applicationPassword: newApplicationPassword)
        
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func validateTextFieldInput(_ sender: UITextField) {
                
        guard newPasswordTextField.text != nil else { return }
        guard confirmNewPasswordTextField.text != nil else { return }
        
        if confirmNewPasswordTextField.text == newPasswordTextField.text {
            confirmNewPasswordTextField.textColor = UIColor.green
        } else {
            confirmNewPasswordTextField.textColor = UIColor.red
        }
        
        if newPasswordTextField.text!.characters.count >= 6 {
            newPasswordTextField.textColor = UIColor.green
        } else {
            confirmNewPasswordTextField.textColor = UIColor.red
            newPasswordTextField.textColor = UIColor.red
        }
    }
    
    @IBAction func textFieldDidEndOnExit(_ sender: UITextField) {
        
        switch sender {
        case currentPasswordTextField:
            newPasswordTextField.becomeFirstResponder()
            
        case newPasswordTextField:
            confirmNewPasswordTextField.becomeFirstResponder()
            
        case confirmNewPasswordTextField:
            confirmNewPasswordTextField.endEditing(true)
            
        default:
            break
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        
        changeApplicationPassword()
    }
}
