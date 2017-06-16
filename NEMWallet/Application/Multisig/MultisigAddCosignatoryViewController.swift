//
//  MultisigAddCosignatoryViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The view controller that lets the user add a new multisig cosigner.
final class MultisigAddCosignatoryViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    var newCosignatoryPublicKey: String?
    fileprivate var suggestions = [String: String]()
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cosignatoryIdentifierTextField: AutoCompleteTextField!
    @IBOutlet weak var addCosignatoryButton: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layoutIfNeeded()
        
        self.navigationBar.delegate = self
        
        updateViewControllerAppearance()
        
        handleTextFieldInterfaces()
    }
    
    private func handleTextFieldInterfaces() {
        
        cosignatoryIdentifierTextField.onTextChange = { [weak self] text in
            if !text.isEmpty {
                self?.setSuggestions()
            }
        }
        
        cosignatoryIdentifierTextField.onSelect = { [weak self] text, indexpath in
            self?.cosignatoryIdentifierTextField.text = self?.suggestions[text]
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        customNavigationItem.title = "ADD_COSIGNATORY".localized()
        cosignatoryIdentifierTextField.placeholder = "INPUT_PUBLIC_KEY".localized()
        
        cosignatoryIdentifierTextField.layer.cornerRadius = 5
        cosignatoryIdentifierTextField.clipsToBounds = true
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
    
    /// Sets all suggestions for the cosignatory identifier text field.
    fileprivate func setSuggestions() {
        
        guard cosignatoryIdentifierTextField.text != nil else { return }
        
        let searchText = cosignatoryIdentifierTextField.text!.lowercased()
        var autoCompleteStrings = [String]()
        
        let accounts = AccountManager.sharedInstance.accounts()
        for account in accounts {
            suggestions[account.title] = account.publicKey
        }
        
        let filteredSuggestions = suggestions.filter {
            let fullName = "\($0.key) \($0.value)".lowercased()
            return fullName.contains(searchText)
        }
        
        for filteredSuggestion in filteredSuggestions {
            autoCompleteStrings.append(filteredSuggestion.key)
        }
        
        cosignatoryIdentifierTextField.autoCompleteStrings = autoCompleteStrings
    }
    
    // MARK: View Controller Outlet Actions
    
    @IBAction func addCosignatoryButtonPressed(_ sender: UIBarButtonItem) {
        
        guard let cosignatoryIdentifier = cosignatoryIdentifierTextField.text else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            cosignatoryIdentifierTextField.endEditing(true)
            return
        }
        guard cosignatoryIdentifier != "" else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            cosignatoryIdentifierTextField.endEditing(true)
            return
        }
        
        if TransactionManager.sharedInstance.validateHexadecimalString(cosignatoryIdentifier) == true {
            
            newCosignatoryPublicKey = cosignatoryIdentifier
            performSegue(withIdentifier: "unwindToMultisigViewController", sender: nil)
            
        } else {
                
            showAlert(withMessage: "UNKNOWN_TEXT".localized())
            cosignatoryIdentifierTextField.endEditing(true)
            return
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Navigation Bar Delegate

extension MultisigAddCosignatoryViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
