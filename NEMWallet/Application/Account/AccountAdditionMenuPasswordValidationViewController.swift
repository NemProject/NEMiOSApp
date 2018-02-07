//
//  AccountAdditionMenuPasswordValidationViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    Lets the user verify his password in order to import an
    existing account via QR code. Imports the account and unwinds
    to the account list once the user provided password was verified
    successfully.
 */
class AccountAdditionMenuPasswordValidationViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    var accountTitle = String()
    var accountEncryptedPrivateKey = String()
    var accountSalt = String()
    fileprivate var accountPrivateKey = String()
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmationButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
        
        self.navigationBar.delegate = self
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        customNavigationItem.title = "ENTET_PASSWORD".localized()
        passwordTextField.placeholder = "PASSWORD_PLACEHOLDER".localized()
        confirmationButton.setTitle("CONFIRM".localized(), for: UIControlState())
        
        containerView.layer.cornerRadius = 5
        containerView.clipsToBounds = true
    }
    
    /**
        Verifies that the entered password is valid and therefore
        able to decrypt the imported and encrypted private key.
     
        - Throws: 
            - AccountImportValidation.NoPasswordProvided if no password was provided.
            - AccountImportValidation.WrongPasswordProvided if the provided password is invalid.
            - AccountImportValidation.AccountAlreadyPresent if an account with the same private key already is present in the application.
            - AccountImportValidation.Other if generating a hash failed.

        - Returns: A bool indicating that the verification was successful.
     */
    fileprivate func verifyPassword() throws -> Bool {
        
        guard let enteredPassword = passwordTextField.text else { throw AccountImportValidation.noPasswordProvided }
        
        let accountSaltBytes = accountSalt.asByteArray()
        let accountSaltData = NSData(bytes: accountSaltBytes, length: accountSaltBytes.count)

        guard let passwordHash = try? HashManager.generateAesKeyForString(enteredPassword, salt: accountSaltData, roundCount:2000) else { throw AccountImportValidation.other }
        guard let accountPrivateKey = HashManager.AES256Decrypt(inputText: accountEncryptedPrivateKey, key: passwordHash!.toHexString())?.nemKeyNormalized() else { throw AccountImportValidation.wrongPasswordProvided }
                                
        do {
            let _ = try AccountManager.sharedInstance.validateAccountExistence(forAccountWithPrivateKey: accountPrivateKey)
            self.accountPrivateKey = accountPrivateKey
            
            return true
            
        } catch AccountImportValidation.accountAlreadyPresent(let existingAccountTitle) {
            throw AccountImportValidation.accountAlreadyPresent(accountTitle: existingAccountTitle)
        }
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func verifyPassword(_ sender: UIButton) {
        
        passwordTextField.endEditing(true)
        
        do {
            let _ = try verifyPassword()
            
            AccountManager.sharedInstance.create(account: accountTitle, withPrivateKey: accountPrivateKey, completion: { [unowned self] (result, _) in
                
                switch result {
                case .success:
                    self.performSegue(withIdentifier: "unwindToWalletOverviewViewController", sender: nil)
                    
                case .failure:
                    let accountCreationFailureAlert = UIAlertController(title: "Error", message: "Couldn't create account", preferredStyle: .alert)
                    
                    accountCreationFailureAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
                    
                    self.present(accountCreationFailureAlert, animated: true, completion: nil)
                }
            })
            
        } catch AccountImportValidation.accountAlreadyPresent(let existingAccountTitle) {
            
            let accountAlreadyPresentAlert = UIAlertController(title: "VALIDATION".localized(), message: String(format: "VIDATION_ACCOUNT_EXIST".localized(), arguments:[existingAccountTitle]), preferredStyle: .alert)
            
            accountAlreadyPresentAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
            
            self.present(accountAlreadyPresentAlert, animated: true, completion: nil)
            
        } catch AccountImportValidation.wrongPasswordProvided {
            
            let verificationFailureAlert = UIAlertController(title: "Error", message: "Wrong password provided", preferredStyle: .alert)
            
            verificationFailureAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
            
            present(verificationFailureAlert, animated: true, completion: nil)
            
        } catch {
            
            let accountCreationFailureAlert = UIAlertController(title: "Error", message: "Couldn't create account", preferredStyle: .alert)
            
            accountCreationFailureAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
            
            present(accountCreationFailureAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Navigation Bar Delegate

extension AccountAdditionMenuPasswordValidationViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
