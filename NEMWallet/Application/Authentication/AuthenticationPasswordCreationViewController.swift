//
//  AuthenticationPasswordCreationViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The view controller that lets the user set/create the application password.
class AuthenticationPasswordCreationViewController: UIViewController {
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var passwordHeadingLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var confirmationButton: UIButton!

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
        
        if SettingsManager.sharedInstance.defaultServerStatus() == false {
            SettingsManager.sharedInstance.createDefaultServers { (result) in
                TimeManager.sharedInstance.synchronizeTime()
            }
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        passwordHeadingLabel.text = "CREATE_PASSWORD".localized()
        passwordTextField.placeholder = "PASSWORD_PLACEHOLDER".localized()
        confirmPasswordTextField.placeholder = "REPEAT_PASSWORD_PLACEHOLDER".localized()
        confirmationButton.setTitle("CONFIRM".localized(), for: UIControlState())
        
        containerView.layer.cornerRadius = 5
        containerView.clipsToBounds = true
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
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func confirm(_ sender: UIButton) {
        
        sender.endEditing(true)
        
        guard let password = passwordTextField.text else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        guard let confirmationPassword = confirmPasswordTextField.text else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        guard password != "" && confirmationPassword != "" else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        guard password.characters.count >= 6 else {
            showAlert(withMessage: "PASSOWORD_LENGTH_ERROR".localized())
            return
        }
        guard password == confirmationPassword else {
            showAlert(withMessage: "PASSOWORD_DIFERENCE_ERROR".localized())
            return
        }
        
        SettingsManager.sharedInstance.setApplicationPassword(applicationPassword: password)
        
        TimeManager.sharedInstance.synchronizeTime()        
        NotificationManager.sharedInstance.registerForNotifications()
        
        performSegue(withIdentifier: "showRootNavigationController", sender: nil)
    }
    
    @IBAction func didEndOnExit(_ sender: UITextField) {
        
        switch sender {
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
            
        case confirmPasswordTextField:
            confirm(confirmationButton)
            
        default:
            break
        }
    }
    
    @IBAction func validateTextField(_ sender: UITextField) {
        
        guard passwordTextField.text != nil else { return }
        guard confirmPasswordTextField.text != nil else { return }
        
        if confirmPasswordTextField.text == passwordTextField.text {
            confirmPasswordTextField.textColor = UIColor.green
        } else {
            confirmPasswordTextField.textColor = UIColor.red
        }
        
        if passwordTextField.text!.characters.count >= 6 {
            passwordTextField.textColor = UIColor.green
        } else {
            confirmPasswordTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
        }
    }
}
