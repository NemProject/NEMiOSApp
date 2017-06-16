//
//  SettingsInvoiceMessageViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The view controller that lets the user set a prefix, postfix and default message for new transactions.
final class SettingsInvoiceMessageViewController: UITableViewController {
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var prefixTextField: UITextField!
    @IBOutlet weak var postfixTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
        
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
        
        prefixTextField.text = SettingsManager.sharedInstance.invoiceMessagePrefix()
        postfixTextField.text = SettingsManager.sharedInstance.invoiceMessagePostfix()
        messageTextField.text = SettingsManager.sharedInstance.invoiceDefaultMessage()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            prefixTextField.becomeFirstResponder()
            
        case 1:
            postfixTextField.becomeFirstResponder()
            
        case 2:
            messageTextField.becomeFirstResponder()
            
        default:
            break
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "INVOICE_MESSAGE_CONFIG".localized()
        prefixTextField.placeholder = "PREFIX".localized()
        postfixTextField.placeholder = "POSTFIX".localized()
        messageTextField.placeholder = "MESSAGE".localized()
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        
        guard prefixTextField.text != nil else { return }
        guard postfixTextField.text != nil else { return }
        guard messageTextField.text != nil else { return }
        
        SettingsManager.sharedInstance.setInvoiceMessagePrefix(invoiceMessagePrefix: prefixTextField.text!)
        SettingsManager.sharedInstance.setInvoiceMessagePostfix(invoiceMessagePostfix: postfixTextField.text!)
        SettingsManager.sharedInstance.setInvoiceDefaultMessage(invoiceDefaultMessage: messageTextField.text!)
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func textFieldDidEndOnExit(_ sender: UITextField) {
        
        switch sender {
        case prefixTextField:
            postfixTextField.becomeFirstResponder()
            
        case postfixTextField:
            messageTextField.becomeFirstResponder()
            
        case messageTextField:
            messageTextField.endEditing(true)
            
        default:
            break
        }
    }
}
