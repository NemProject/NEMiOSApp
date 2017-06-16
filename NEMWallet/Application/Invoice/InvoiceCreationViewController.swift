//
//  InvoiceCreationViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

/// The view controller that lets the user create a new invoice.
final class InvoiceCreationViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    var account: Account!
    var invoice: Invoice?
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var invoiceAccountTitleTextField: UITextField!
    @IBOutlet weak var invoiceAmountTextField: UITextField!
    @IBOutlet weak var invoiceMessageTextField: UITextField!
    @IBOutlet weak var createInvoiceButton: UIButton!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        account = AccountManager.sharedInstance.activeAccount
        
        guard account != nil else {
            print("Critical: Account not available!")
            return
        }

        updateViewControllerAppearance()
        
        let invoiceMessagePrefix = SettingsManager.sharedInstance.invoiceMessagePrefix()
        let invoiceMessagePostfix = SettingsManager.sharedInstance.invoiceMessagePostfix()
        let invoiceDefaultMessage = SettingsManager.sharedInstance.invoiceDefaultMessage()
        
        invoiceAccountTitleTextField.text = account.title
        
        var defaultInvoiceMessage = String()
        if invoiceMessagePrefix != "" {
            defaultInvoiceMessage += "\(invoiceMessagePrefix)/"
        }
        
        defaultInvoiceMessage += "\(InvoiceManager.sharedInstance.invoices().count)"
        
        if invoiceMessagePostfix != "" {
            defaultInvoiceMessage += "/\(invoiceMessagePostfix)"
        }
        
        defaultInvoiceMessage += ": "
        
        if invoiceDefaultMessage != "" {
            defaultInvoiceMessage += "\(invoiceDefaultMessage)"
        }
        
        invoiceMessageTextField.text = defaultInvoiceMessage
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showInvoiceCreatedViewController":
            
            let destinationViewController = segue.destination as! InvoiceCreatedViewController
            destinationViewController.invoice = invoice
            
        default:
            return
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller on view did load.
    fileprivate func updateViewControllerAppearance() {
        
        invoiceAccountTitleTextField.placeholder = "ENTER_NAME".localized()
        invoiceAmountTextField.placeholder = "ENTER_AMOUNT".localized()
        invoiceMessageTextField.placeholder = "ENTER_MESSAGE".localized()
        createInvoiceButton.setTitle("CREATE".localized(), for: UIControlState())
        
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
    }
    
    // MARK: - View Controller Outlet Actions

    @IBAction func didEndOnExit(_ sender: UITextField) {
        
        switch sender {
        case invoiceAccountTitleTextField:
            invoiceAmountTextField.becomeFirstResponder()
            
        case invoiceAmountTextField:
            invoiceMessageTextField.becomeFirstResponder()
            
        case invoiceMessageTextField:
            invoiceMessageTextField.resignFirstResponder()
            
        default:
            break
        }
    }
    
    @IBAction func createInvoiceButtonPressed(_ sender: UIButton) {
        
        guard invoiceAccountTitleTextField.text != nil else { return }
        guard invoiceAmountTextField.text != nil else { return }
        guard invoiceMessageTextField.text != nil else { return }
        
        let invoiceAccountTitle = invoiceAccountTitleTextField.text!
        let invoiceAccountAddress = account.address
        let invoiceAmount = Double(invoiceAmountTextField.text!.replacingOccurrences(of: " ", with: "")) ?? 0.0
        let invoiceMessage = invoiceMessageTextField.text!
        
        if invoiceAmount < 0.000001 && invoiceAmount != 0 {
            invoiceAmountTextField.text = "0"
            return
        }
        if invoiceAccountTitle == "" {
            return
        }
        if invoiceMessage.hexadecimalStringUsingEncoding(String.Encoding.utf8)?.asByteArray().count > 255 {
            
            let messageLengthAlert = UIAlertController(title: "INFO".localized(), message: "MESSAGE_LENGTH".localized(), preferredStyle: UIAlertControllerStyle.alert)
            
            messageLengthAlert.addAction(UIAlertAction(title: "OK".localized(), style: .cancel, handler: nil))
            
            present(messageLengthAlert, animated: true, completion: nil)
            
            return
        }
        
        InvoiceManager.sharedInstance.createInvoice(withAccountTitle: invoiceAccountTitle, andAccountAddress: invoiceAccountAddress, andAmount: Int(invoiceAmount * 1000000), andMessage: invoiceMessage) { [unowned self] (result, invoice) in
            
            switch result {
            case .success:
                
                self.invoice = invoice
                self.performSegue(withIdentifier: "showInvoiceCreatedViewController", sender: nil)
                
            case .failure:
                
                let invoiceCreationFailureAlert = UIAlertController(title: "Error", message: "Couldn't create invoice", preferredStyle: .alert)
                
                invoiceCreationFailureAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
                
                self.present(invoiceCreationFailureAlert, animated: true, completion: nil)
            }
        }
    }
}
