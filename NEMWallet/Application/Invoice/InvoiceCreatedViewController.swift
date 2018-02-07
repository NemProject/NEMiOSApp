//
//  InvoiceCreatedViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    The view controller that shows the newly created invoice and lets
    the user share that invoice.
 */
class InvoiceCreatedViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    var invoice: Invoice!
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var invoiceQRCodeImageView: UIImageView!
    @IBOutlet weak var invoiceAccountTitleLabel: UILabel!
    @IBOutlet weak var invoiceAmountLabel: UILabel!
    @IBOutlet weak var invoiceMessageLabel: UILabel!
    @IBOutlet weak var invoiceDataHeadingLabel: UILabel!
    @IBOutlet weak var saveQRCodeImageButton: UIButton!
    @IBOutlet weak var shareQRCodeImageButton: UIButton!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.delegate = self
        
        updateViewControllerAppearance()
        
        generateQRCode(forInvoice: invoice)
        
        let invoiceAccountTitleHeading = NSMutableAttributedString(string: "\("NAME".localized()): ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13)])
        let invoiceAccountTitle = NSMutableAttributedString(string: invoice.accountTitle, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)])
        invoiceAccountTitleHeading.append(invoiceAccountTitle)
        invoiceAccountTitleLabel.attributedText = invoiceAccountTitleHeading
        
        let invoiceAmountHeading = NSMutableAttributedString(string: "\("AMOUNT".localized()): ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13)])
        let invoiceAmount = NSMutableAttributedString(string: "\((Double(invoice.amount) / 1000000).format()) XEM" , attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)])
        invoiceAmountHeading.append(invoiceAmount)
        invoiceAmountLabel.attributedText = invoiceAmountHeading
        
        let invoiceMessageHeading = NSMutableAttributedString(string: "\("MESSAGE".localized()): ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13)])
        let invoiceMessage = NSMutableAttributedString(string: invoice.message, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)])
        invoiceMessageHeading.append(invoiceMessage)
        invoiceMessageLabel.attributedText = invoiceMessageHeading
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        viewTopConstraint.constant = self.navigationBar.frame.height
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        invoiceDataHeadingLabel.text = "INVOICE_DATA".localized()
        saveQRCodeImageButton.setTitle("SAVE_QR".localized(), for: UIControlState())
        shareQRCodeImageButton.setTitle("SHARE_QR".localized(), for: UIControlState())
    }
    
    /**
        Generates the QR code image for the invoice.
     
        - Parameter invoice: The invoice for which the QR code image should get genererated.
     */
    fileprivate func generateQRCode(forInvoice invoice: Invoice) {
        
        let invoiceDictionary: [String: Any] = [
            QRKeys.address.rawValue : invoice.accountAddress,
            QRKeys.name.rawValue : invoice.accountTitle,
            QRKeys.amount.rawValue : invoice.amount,
            QRKeys.message.rawValue : invoice.message
        ]
        
        let jsonDictionary = NSDictionary(objects: [QRType.invoice.rawValue, invoiceDictionary, Constants.qrVersion], forKeys: [QRKeys.dataType.rawValue as NSCopying, QRKeys.data.rawValue as NSCopying, QRKeys.version.rawValue as NSCopying])
        
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        invoiceQRCodeImageView.image = String(data: jsonData, encoding: String.Encoding.utf8)!.createQRCodeImage()
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func saveInvoiceQRCodeImage(_ sender: UIButton) {
        
        guard invoiceQRCodeImageView.image != nil else { return }
        
        UIImageWriteToSavedPhotosAlbum(invoiceQRCodeImageView.image!, nil, nil, nil)
    }
    
    @IBAction func shareInvoiceQRCodeImage(_ sender: UIButton) {
        
        if let qrCodeImage = invoiceQRCodeImageView.image {
            
            let message = "INVOICE_HEADER".localized()
            
            let shareActivityViewController = UIActivityViewController(activityItems: [message, qrCodeImage], applicationActivities: [])
            
            present(shareActivityViewController, animated: true)
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Navigation Bar Delegate

extension InvoiceCreatedViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
