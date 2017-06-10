//
//  AddressBookAddContactViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import Contacts

/// The view controller that lets the user add a new contact to the address book.
class AddressBookAddContactViewController: UITableViewController {

    // MARK: - View Controller Outlets
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var accountAddressTextField: UITextField!
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
        
        if InvoiceManager.sharedInstance.contactToCreate != nil {
            firstNameTextField.text = InvoiceManager.sharedInstance.contactToCreate!.givenName
            lastNameTextField.text = InvoiceManager.sharedInstance.contactToCreate!.familyName
            accountAddressTextField.text = InvoiceManager.sharedInstance.contactToCreate!.emailAddresses.first!.value as String
            
            InvoiceManager.sharedInstance.contactToCreate = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            firstNameTextField.becomeFirstResponder()
            
        case 1:
            lastNameTextField.becomeFirstResponder()
            
        case 2:
            accountAddressTextField.becomeFirstResponder()
            
        default:
            break
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "ADD_CONTACT".localized()
        firstNameTextField.placeholder = "FIRST_NAME".localized()
        lastNameTextField.placeholder = "LAST_NAME".localized()
        accountAddressTextField.placeholder = "ADDRESS".localized()
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
    
    /// Validates the user input and creates a new contact.
    fileprivate func addContact() {
        
        guard firstNameTextField.text != nil else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        guard accountAddressTextField.text != nil else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        
        let firstName = firstNameTextField.text!
        let lastName = lastNameTextField.text!
        let accountAddress = accountAddressTextField.text!
        
        guard firstName != "" && accountAddress != "" else {
            showAlert(withMessage: "FIELDS_EMPTY_ERROR".localized())
            return
        }
        
        AddressBookManager.sharedInstance.createContact(withFirstName: firstName, andLastName: lastName, andAccountAddress: accountAddress) { [weak self] (result) in
            
            switch result {
            case .success:
                
                self?.performSegue(withIdentifier: "unwindToAddressBookViewController", sender: nil)
                
            case .failure:
                
                self?.showAlert(withMessage: "CANNOT_ACCESS_CONTACTS".localized(), completion: { () in
                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                })
            }
        }
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func textFieldDidEndOnExit(_ sender: UITextField) {
        
        switch sender {
        case firstNameTextField:
            lastNameTextField.becomeFirstResponder()
            
        case lastNameTextField:
            accountAddressTextField.becomeFirstResponder()
            
        case accountAddressTextField:
            accountAddressTextField.endEditing(true)
            
        default:
            break
        }
    }

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        performSegue(withIdentifier: "unwindToAddressBookViewController", sender: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        
        addContact()
    }
}
