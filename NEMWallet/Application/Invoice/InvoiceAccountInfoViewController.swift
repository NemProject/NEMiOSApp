//
//  InvoiceAccountInfoViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    The view controller that lets the user look up information
    about his account and also share that information with others.
 */
class InvoiceAccountInfoViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    var account: Account!
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var accountAddressHeadingLabel: UILabel!
    @IBOutlet weak var accountTitleHeadingLabel: UILabel!
    @IBOutlet weak var accountAddressLabel: UILabel!
    @IBOutlet weak var accountTitleTextField: UITextField!
    @IBOutlet weak var accountQRCodeImageView: UIImageView!
    @IBOutlet weak var saveAccountQRCodeButton: UIButton!
    @IBOutlet weak var shareAccountQRCodeButton: UIButton!
    @IBOutlet weak var copyAccountAddressButton: UIButton!
    @IBOutlet weak var shareAccountAddressButton: UIButton!
    @IBOutlet weak var editAccountTitleButton: UIButton!
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        account = AccountManager.sharedInstance.activeAccount
        
        guard account != nil else {
            print("Critical: Account not available!")
            return
        }

        updateViewControllerAppearance()
        
        accountAddressLabel.text = account.address.nemAddressNormalised()
        accountTitleTextField.placeholder = account.title
        generateQRCode(forAccount: account)
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller on view did load.
    fileprivate func updateViewControllerAppearance() {
        
        accountAddressHeadingLabel.text = "\("MY_ADDRESS".localized()):"
        accountTitleHeadingLabel.text = "\("MY_NAME".localized()):"
        accountTitleTextField.placeholder = "YOUR_NAME".localized()
        saveAccountQRCodeButton.setTitle("SAVE_QR".localized(), for: UIControlState())
        shareAccountQRCodeButton.setTitle("SHARE_QR".localized(), for: UIControlState())
        copyAccountAddressButton.setTitle("COPY_ADDRESS".localized(), for: UIControlState())
        shareAccountAddressButton.setTitle("SHARE_ADDRESS".localized(), for: UIControlState())
        editAccountTitleButton.setImage(#imageLiteral(resourceName: "Edit").imageWithColor(UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)), for: UIControlState())
    }
    
    /**
        Generates the QR code image for the provided account.
     
        - Parameter account: The account for which the QR code image should get genererated.
     */
    fileprivate func generateQRCode(forAccount account: Account) {
        
        let accountDictionary: [String: String] = [
            QRKeys.address.rawValue: account.address,
            QRKeys.name.rawValue: accountTitleTextField.text != "" ? accountTitleTextField.text! : account.title
        ]
        
        let jsonDictionary = NSDictionary(objects: [QRType.userData.rawValue, accountDictionary, Constants.qrVersion], forKeys: [QRKeys.dataType.rawValue as NSCopying, QRKeys.data.rawValue as NSCopying, QRKeys.version.rawValue as NSCopying])
        
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        accountQRCodeImageView.image = String(data: jsonData, encoding: String.Encoding.utf8)!.createQRCodeImage()
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func editAccountTitleButtonPressed(_ sender: UIButton) {
        
        accountTitleTextField.becomeFirstResponder()
    }
    
    @IBAction func accountTitleHasChanged(_ sender: UITextField) {
        
        guard sender.text != nil else { return }
        
        generateQRCode(forAccount: account)
    }
    
    @IBAction func copyAccountAddress(_ sender: AnyObject) {
        
        let pasteBoard: UIPasteboard = UIPasteboard.general
        pasteBoard.string = account.address.nemAddressNormalised()

        showAlertCopied()
    }
    
    @IBAction func shareAccountAddress(_ sender: UIButton) {
        
        let shareActivityViewController = UIActivityViewController(activityItems: [account.address], applicationActivities: [])
        
        present(shareActivityViewController, animated: true)
    }
    
    @IBAction func saveAccountQRCodeImage(_ sender: UIButton) {
        
        guard accountQRCodeImageView.image != nil else { return }
        
        UIImageWriteToSavedPhotosAlbum(accountQRCodeImageView.image!, nil, nil, nil)

        showAlertSaved()
    }
    
    @IBAction func shareAccountQRCodeImage(_ sender: UIButton) {
        
        guard let accountTitle = accountTitleTextField.text else { return }
        if let qrCodeImage = accountQRCodeImageView.image {
            
            let message = "\(accountTitle != "" ? accountTitle : account.title): \(account.address)"
            
            let shareActivityViewController = UIActivityViewController(activityItems: [message, qrCodeImage], applicationActivities: [])
            
            present(shareActivityViewController, animated: true)
        }
    }
}
