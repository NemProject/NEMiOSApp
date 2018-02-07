//
//  AccountAdditionMenuAddExistingAccountPrivateKeyViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    The view controller that lets the user add an existing account by
    importing a private key.
 */
class AccountAdditionMenuAddExistingAccountPrivateKeyViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    fileprivate var accountTitle = String()
    fileprivate var accountPrivateKey = String()
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var accountPrivateKeyTextField: UITextField!
    @IBOutlet weak var accountTitleTextField: UITextField!
    @IBOutlet weak var addAccountButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
        addKeyboardObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "IMPORT_FROM_KEY".localized()
        accountPrivateKeyTextField.placeholder = "PRIVATE_KEY".localized()
        accountTitleTextField.placeholder = "NAME".localized()
        addAccountButton.setTitle("ADD_ACCOUNT".localized(), for: UIControlState())
        
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
    }
    
    /// Adds all needed keyboard observers to the view controller.
    fileprivate func addKeyboardObserver() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(AccountAdditionMenuAddExistingAccountPrivateKeyViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AccountAdditionMenuAddExistingAccountPrivateKeyViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /// Makes the scroll view scrollable as soon as the keyboard shows.
    func keyboardWillShow(_ notification: Notification) {
        
        let info: NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        var keyboardHeight:CGFloat = keyboardSize.height
        keyboardHeight -= self.view.frame.height - self.scrollView.frame.height
        
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight - 10, 0)
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight + 15, 0)
    }
    
    /// Resets the scroll view as soon as the keyboard hides.
    func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    /**
        Validates entered information.
     
        - Throws:
            - AccountImportValidation.ValueMissing if a value wasn't provided.
            - AccountImportValidation.InvalidPrivateKey if the provided private key isn't valid.
            - AccountImportValidation.AccountAlreadyPresent if an account with the provided private key was already added to the application.
     
        - Returns: A bool indicating that the validation was successful.
     */
    fileprivate func validateEntries() throws -> Bool {
        
        guard let accountTitle = accountTitleTextField.text else { throw AccountImportValidation.valueMissing }
        guard let accountPrivateKey = accountPrivateKeyTextField.text else { throw AccountImportValidation.valueMissing }
        guard accountTitle != String() else { throw AccountImportValidation.valueMissing }
        guard accountPrivateKey != String() else { throw AccountImportValidation.valueMissing }
        guard let accountPrivateKeyNormalized = accountPrivateKey.nemKeyNormalized() else { throw AccountImportValidation.invalidPrivateKey }
        
        do {
            let _ = try AccountManager.sharedInstance.validateAccountExistence(forAccountWithPrivateKey: accountPrivateKeyNormalized)
            
            self.accountTitle = accountTitle
            self.accountPrivateKey = accountPrivateKeyNormalized
            
        } catch AccountImportValidation.accountAlreadyPresent(let existingAccountTitle) {
            throw AccountImportValidation.accountAlreadyPresent(accountTitle: existingAccountTitle)
        }
        
        return true
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func importAccount(_ sender: UIButton) {
        
        do {
            let _ = try validateEntries()
            
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
            
        } catch AccountImportValidation.valueMissing {
            
            let importAccountValueMissingAlert: UIAlertController = UIAlertController(title: "VALIDATION".localized(), message: "FIELDS_EMPTY_ERROR".localized(), preferredStyle: UIAlertControllerStyle.alert)
            
            importAccountValueMissingAlert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: nil))
            
            present(importAccountValueMissingAlert, animated: true, completion: nil)
            
        } catch AccountImportValidation.invalidPrivateKey {
            
            let importAccountInvalidPrivateKeyAlert: UIAlertController = UIAlertController(title: "VALIDATION".localized(), message: "PRIVATE_KEY_ERROR_1".localized(), preferredStyle: UIAlertControllerStyle.alert)
            
            importAccountInvalidPrivateKeyAlert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: nil))
            
            present(importAccountInvalidPrivateKeyAlert, animated: true, completion: nil)
            
        } catch AccountImportValidation.accountAlreadyPresent(let existingAccountTitle) {
            
            let importAccountAlreadyPresentAlert: UIAlertController = UIAlertController(title: "VALIDATION".localized(), message: String(format: "VIDATION_ACCOUNT_EXIST".localized(), arguments:[existingAccountTitle]), preferredStyle: UIAlertControllerStyle.alert)
            
            importAccountAlreadyPresentAlert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: nil))
            
            present(importAccountAlreadyPresentAlert, animated: true, completion: nil)
            
        } catch {
            
            let importAccountOtherAlert: UIAlertController = UIAlertController(title: "VALIDATION".localized(), message: "Couldn't add account", preferredStyle: UIAlertControllerStyle.alert)
            
            importAccountOtherAlert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: nil))
            
            present(importAccountOtherAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func textFieldFocused(_ sender: UITextField) {
        validateTextField(sender)
        scrollView.scrollRectToVisible(sender.convert(sender.frame, to: self.view), animated: true)
    }
    
    @IBAction func validateTextField(_ sender: UITextField){
        
        switch sender {
        case accountPrivateKeyTextField:
            
            if AccountManager.sharedInstance.validateKey(accountPrivateKeyTextField.text!) {
                sender.textColor = UIColor.green
            } else {
                sender.textColor = UIColor.red
            }
            
        default:
            return
        }
    }
    
    @IBAction func changeTextField(_ sender: UITextField) {
        
        switch sender {
        case accountPrivateKeyTextField:
            
            accountTitleTextField.becomeFirstResponder()
            textFieldFocused(accountTitleTextField)
            
        case accountTitleTextField:
            
            if accountPrivateKeyTextField.text == "" {
                accountPrivateKeyTextField.becomeFirstResponder()
                textFieldFocused(accountPrivateKeyTextField)
            }
            
        default :
            break
        }
    }
}
