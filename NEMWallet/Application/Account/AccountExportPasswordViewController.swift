//
//  AccountExportPasswordViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import SwiftyJSON

/// The view controller that lets the user choose a password which will get used to encrypt the backup.
class AccountExportPasswordViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    fileprivate var account: Account?
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var defaultPasswordDescriptionLabel: UILabel!
    @IBOutlet weak var defaultPasswordSwitch: UISwitch!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var confirmationButton: UIButton!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.delegate = self
        
        account = AccountManager.sharedInstance.activeAccount
        
        guard account != nil else {
            print("Critical: Account not available!")
            return
        }
        
        updateViewControllerAppearance()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        viewTopConstraint.constant = self.navigationBar.frame.height + 70
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showAccountExportViewController":
            
            let destinationViewController = segue.destination as! AccountExportViewController
            let accountJsonString = sender as! String
            destinationViewController.accountJsonString = accountJsonString
            
        default:
            return
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        customNavigationItem.title = "EXPORT_ACCOUNT".localized()
        descriptionLabel.text = "ENTET_PASSWORD_EXPORT".localized()
        descriptionLabel.text = "PASSWORD_PLACEHOLDER_EXPORT".localized()
        passwordTextField.placeholder = "PASSWORD_PLACEHOLDER".localized()
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
    
    /// Validates the input password and prepares for the account export.
    fileprivate func prepareForExport() {
        
        guard passwordTextField.text != nil else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        if defaultPasswordSwitch.isOn == false && passwordTextField.text! == "" {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        if defaultPasswordSwitch.isOn == false && passwordTextField.text!.characters.count < 6 {
            showAlert(withMessage: "PASSOWORD_LENGTH_ERROR".localized())
            return
        }
        
        let accountTitle = account!.title
        let salt = SettingsManager.sharedInstance.authenticationSalt()
        var encryptedPrivateKey = account!.privateKey
        
        if passwordTextField.text != String() {
            let privateKey = AccountManager.sharedInstance.decryptPrivateKey(encryptedPrivateKey: encryptedPrivateKey)
            let saltData = NSData(bytes: salt!.asByteArray(), length: salt!.asByteArray().count)
            let passwordHash = try! HashManager.generateAesKeyForString(passwordTextField.text!, salt: saltData, roundCount: 2000)
            encryptedPrivateKey = HashManager.AES256Encrypt(inputText: privateKey, key: passwordHash!.hexadecimalString())
        }
        
        let jsonData = JSON([QRKeys.dataType.rawValue: QRType.accountData.rawValue, QRKeys.version.rawValue: Constants.qrVersion, QRKeys.data.rawValue: [ QRKeys.name.rawValue: accountTitle, QRKeys.salt.rawValue: salt!, QRKeys.privateKey.rawValue: encryptedPrivateKey ]])
        let jsonString = jsonData.rawString()
        
        performSegue(withIdentifier: "showAccountExportViewController", sender: jsonString)
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func defaultPasswordSwitchChanged(_ sender: UISwitch) {
        
        var height: CGFloat = 0
        
        if sender.isOn {
            height = 100
            passwordTextField.text = String()
            passwordTextField.endEditing(true)
        } else {
            height = 152
        }
        
        for constraint in containerView.constraints {
            if constraint.identifier == "height" {
                constraint.constant = height
                break
            }
        }
        
        UIView.animate(withDuration: 0.2, animations: { [unowned self] () -> Void in
            self.view.layoutIfNeeded()
        }) 
    }
    
    @IBAction func confirmationButtonPressed(_ sender: UIButton) {
        
        passwordTextField.endEditing(true)
        prepareForExport()
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Navigation Bar Delegate

extension AccountExportPasswordViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
