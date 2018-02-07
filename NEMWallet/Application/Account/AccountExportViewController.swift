//
//  AccountExportViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    The view controller that shows the export account QR code and lets 
    the user show the public- and private key of the account.
 */
class AccountExportViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    public var accountJsonString: String!
    private var account: Account?
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var exportQRCodeImageView: UIImageView!
    @IBOutlet weak var saveQRCodeImageButton: UIButton!
    @IBOutlet weak var shareQRCodeImageButton: UIButton!
    @IBOutlet weak var publicKeyHeadingLabel: UILabel!
    @IBOutlet weak var publicKeyTextView: UITextView!
    @IBOutlet weak var showPrivateKeyButton: UIButton!
    @IBOutlet weak var privateKeyTextView: UITextView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!
    
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
        generateQRCode(forAccount: accountJsonString)
        
        publicKeyTextView.text = account!.publicKey
        privateKeyTextView.text = AccountManager.sharedInstance.decryptPrivateKey(encryptedPrivateKey: account!.privateKey)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        viewTopConstraint.constant = self.navigationBar.frame.height + 8
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        customNavigationItem.title = "EXPORT_ACCOUNT".localized()
        saveQRCodeImageButton.setTitle("SAVE_QR".localized(), for: UIControlState())
        shareQRCodeImageButton.setTitle("SHARE_QR".localized(), for: UIControlState())
        publicKeyHeadingLabel.text = "PUBLIC_KEY".localized()
        showPrivateKeyButton.setTitle("VIEW_PRIVATE_KEY".localized(), for: UIControlState())
    }
    
    /**
        Generates the QR code image for the account export.
     
        - Parameter accountJsonString: The account export json string for which the QR code should get generated.
     */
    fileprivate func generateQRCode(forAccount accountJsonString: String) {
        exportQRCodeImageView.image = accountJsonString.createQRCodeImage()
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func showPrivateKeyButtonPressed(_ sender: UIButton) {
        
        view.endEditing(true)
        
        if privateKeyTextView.isHidden == false {
            
            showPrivateKeyButton.setTitle("VIEW_PRIVATE_KEY".localized(), for: UIControlState())
            privateKeyTextView.isHidden = true
            
        } else {
            
            let accountExportingAlert = UIAlertController(title: "WARNING".localized(), message: "\("PRIVATE_KEY_SECURITY_WARNING_PART_ONE".localized()) \("PRIVATE_KEY_SECURITY_WARNING_PART_TWO".localized()) \("PRIVATE_KEY_SECURITY_WARNING_PART_THREE".localized()) \("PRIVATE_KEY_SECURITY_WARNING_PART_FOUR".localized())", preferredStyle: .alert)
            
            accountExportingAlert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil))
            
            accountExportingAlert.addAction(UIAlertAction(title: "SHOW_PRIVATE_KEY".localized(), style: .destructive, handler: { [unowned self] (action) in
                
                self.showPrivateKeyButton.setTitle("HIDE_PRIVATE_KEY".localized(), for: UIControlState())
                self.privateKeyTextView.isHidden = false
            }))
            
            present(accountExportingAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func saveExportQRCodeImage(_ sender: UIButton) {
        
        guard exportQRCodeImageView.image != nil else { return }
        
        UIImageWriteToSavedPhotosAlbum(exportQRCodeImageView.image!, nil, nil, nil)
        
        showAlertSaved()
    }
    
    @IBAction func shareExportQRCodeImage(_ sender: UIButton) {
        
        if let qrCodeImage = exportQRCodeImageView.image {
            
            let shareActivityViewController = UIActivityViewController(activityItems: [qrCodeImage], applicationActivities: [])
            
            present(shareActivityViewController, animated: true)
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToMoreMenuViewController", sender: nil)
    }
}

// MARK: - Navigation Bar Delegate

extension AccountExportViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
