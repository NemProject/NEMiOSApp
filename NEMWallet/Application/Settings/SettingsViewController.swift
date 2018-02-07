//
//  SettingsViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The view controller that lets the user perform settings changes.
class SettingsViewController: UITableViewController {
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var generalInvoiceMessageHeadingLabel: UILabel!
    @IBOutlet weak var generalAboutHeadingLabel: UILabel!
    @IBOutlet weak var securityChangePasswordHeadingLabel: UILabel!
    @IBOutlet weak var securityTouchIDHeadingLabel: UILabel!
    @IBOutlet weak var securityTouchIDValueLabel: UILabel!
    @IBOutlet weak var serverHeadingLabel: UILabel!
    @IBOutlet weak var serverValueLabel: UILabel!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (tableView.indexPathForSelectedRow != nil) {
            let path = tableView.indexPathForSelectedRow!
            tableView.deselectRow(at: path, animated: true)
        }
        
        handleAllSettings()
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return "GENERAL".localized()
        case 1:
            return "SECURITY".localized()
        case 2:
            return "SERVER_SETTINGS".localized()
        default:
            return String()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.section {
        case 0:
            
            switch indexPath.row {
            case 1:
                
                let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
                let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String

                showAlert(withMessage: "\(Constants.activeNetwork == Constants.testNetwork ? "Testnet " : "")\("VERSION".localized()) \(versionNumber) \("BUILD".localized()) \(buildNumber)")
                tableView.deselectRow(at: indexPath, animated: true)
                
            default:
                break
            }
            
        case 1:
            
            switch indexPath.row {
            case 1:
                
                var authenticationTouchIDStatus = SettingsManager.sharedInstance.touchIDAuthenticationIsActivated()
                authenticationTouchIDStatus = !authenticationTouchIDStatus
                
                SettingsManager.sharedInstance.setAuthenticationTouchIDStatus(authenticationTouchIDStatus: authenticationTouchIDStatus)
                
                handleAuthenticationTouchIDSetting()
                tableView.deselectRow(at: indexPath, animated: true)
                
            default:
                break
            }
            
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "SETTINGS".localized()
        generalInvoiceMessageHeadingLabel.text = "INVOICE_MESSAGE_CONFIG".localized()
        generalAboutHeadingLabel.text = "ABOUT".localized()
        securityChangePasswordHeadingLabel.text = "PASSWORD_CHANGE_CONFIG".localized()
        securityTouchIDHeadingLabel.text = "TOUCH_ID".localized()
        serverHeadingLabel.text = "SERVER".localized()
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
    
    /**
        Handles displaying informations in the settings view controller.
        For example handles what gets displayed in all detail labels etc.
     */
    fileprivate func handleAllSettings() {
        
        handleAuthenticationTouchIDSetting()
        handleActiveServerSetting()
    }
    
    /// Displays the current touch id setting status.
    fileprivate func handleAuthenticationTouchIDSetting() {

        let authenticationTouchIDStatus = SettingsManager.sharedInstance.touchIDAuthenticationIsActivated()
        
        securityTouchIDValueLabel.text = authenticationTouchIDStatus ? "ON".localized() : "OFF".localized()
    }
    
    /// Displays the currently active server.
    fileprivate func handleActiveServerSetting() {
        
        let activeServer = SettingsManager.sharedInstance.activeServer()
        
        serverValueLabel.text = activeServer.address 
    }
}
