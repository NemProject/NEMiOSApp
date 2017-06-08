//
//  SettingsAddServerViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The view controller that lets the user add a new server.
class SettingsAddServerViewController: UITableViewController {
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var protocolTypeTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            protocolTypeTextField.becomeFirstResponder()
            
        case 1:
            addressTextField.becomeFirstResponder()
            
        case 2:
            portTextField.becomeFirstResponder()
            
        default:
            break
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "ADD_SERVER".localized()
        protocolTypeTextField.placeholder = "http"
        addressTextField.placeholder = "10.10.100.1"
        portTextField.placeholder = "7890"
        
        protocolTypeTextField.text = "http"
        portTextField.text = "7890"
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
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToServerViewController", sender: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        
        guard protocolTypeTextField.text != nil else {
            showAlert(withMessage: NSLocalizedString("FIELDS_EMPTY_ERROR", comment: "Description"))
            return
        }
        guard addressTextField.text != nil else {
            showAlert(withMessage: NSLocalizedString("FIELDS_EMPTY_ERROR", comment: "Description"))
            return
        }
        guard portTextField.text != nil else {
            showAlert(withMessage: NSLocalizedString("FIELDS_EMPTY_ERROR", comment: "Description"))
            return
        }
        guard protocolTypeTextField.text! != "" && addressTextField.text! != "" && portTextField.text! != "" else {
            showAlert(withMessage: NSLocalizedString("FIELDS_EMPTY_ERROR", comment: "Description"))
            return
        }
        guard protocolTypeTextField.text!.lowercased() == "http" || protocolTypeTextField.text!.lowercased() == "https" else {
            showAlert(withMessage: NSLocalizedString("SERVER_PROTOCOL_NOT_AVAILABLE", comment: "Description"))
            return
        }
        
        let protocolType = protocolTypeTextField.text!
        let address = addressTextField.text!
        let port = portTextField.text!
        
        do {
            let _ = try SettingsManager.sharedInstance.validateServerExistence(forServerWithAddress: address)
            
            SettingsManager.sharedInstance.create(server: address, withProtocolType: protocolType, andPort: port, completion: { [unowned self] (result) in
                
                switch result {
                case .success:
                    self.performSegue(withIdentifier: "unwindToServerViewController", sender: nil)
                    
                case .failure:
                    self.showAlert(withMessage: "Couldn't create server")
                }
            })
            
        } catch ServerAdditionValidation.serverAlreadyPresent(let serverAddress) {
            
            showAlert(withMessage: "Server with address \(serverAddress) already exists")
            
        } catch {
            return
        }
    }
    
    @IBAction func textFieldDidEndOnExit(_ sender: UITextField) {
        
        switch sender {
        case protocolTypeTextField:
            addressTextField.becomeFirstResponder()
            
        case addressTextField:
            portTextField.becomeFirstResponder()
            
        case portTextField:
            portTextField.endEditing(true)
            
        default:
            break
        }
    }
}
