//
//  InvoiceScannerViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import SwiftyJSON
import Contacts

/// The view controller that lets the user scan an invoice.
class InvoiceScannerViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    /// Bool that indicates whether the QR code scanner view is already scanning.
    fileprivate var isScanning = false
    
    fileprivate var cameraNotAvailable = false
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var qrCodeScannerView: QRCodeScannerView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layoutIfNeeded()
        
        qrCodeScannerView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(resumeScanning), name: Notification.Name("resumeCaptureSession"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopScanning), name: Notification.Name("stopCaptureSession"), object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        resumeScanning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopScanning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showTransactionSendViewController":
            
            let destinationViewController = segue.destination as! TransactionSendViewController
            let invoiceJsonData = sender as! JSON
            destinationViewController.recipientAddress = invoiceJsonData["addr"].stringValue
            destinationViewController.amount = Double(invoiceJsonData["amount"].intValue) / Double(1000000)
            destinationViewController.message = invoiceJsonData["msg"].stringValue

        default:
            return
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Controller Helper Methods
    
    /**
        Validates the capture result of the QR code scan.
     
        - Parameter captureResult: The capture result of the QR code scan a JSON array/dictionary.
     
        - Throws:
        - AccountImportValidation.ValueMissing if the capture result is missing a value.
        - AccountImportValidation.VersionNotMatching if the version value of the captured QR code doesn't match with the currently supported version by the application.
        - AccountImportValidation.DataTypeNotMatching if the data type value of the captured QR code doesn't match with the account data type supported by this view controller.
     
        - Returns: A bool indicating that the validation was successful.
     */
    fileprivate func validate(captureResult: JSON) throws -> Bool {
        
        guard captureResult != nil else { throw AccountImportValidation.valueMissing }
        guard captureResult[QRKeys.Version.rawValue].intValue == QR_VERSION else { throw AccountImportValidation.versionNotMatching }
        guard captureResult[QRKeys.DataType.rawValue].intValue == QRType.userData.rawValue || captureResult[QRKeys.DataType.rawValue].intValue == QRType.invoice.rawValue else { throw AccountImportValidation.dataTypeNotMatching }
        
        return true
    }
    
    /**
        Shows the add contact view controller with the received
        contact information already filled in.
     
        - Parameter jsonData: The contact information as a JSON array.
     */
    fileprivate func addContact(withJsonData jsonData: JSON) {
        
        let firstName = jsonData[QRKeys.Name.rawValue].stringValue
        let lastName = jsonData["surname"].stringValue
        let accountAddress = jsonData[QRKeys.Address.rawValue].stringValue
        
        let contact = CNMutableContact()
        contact.givenName = firstName
        contact.familyName = lastName
        let contactAccountAddress = CNLabeledValue(label: "NEM", value: accountAddress as NSString)
        contact.emailAddresses = [contactAccountAddress]
        
        InvoiceManager.sharedInstance.contactToCreate = contact
        
        performSegue(withIdentifier: "showAddressBookAddContactViewController", sender: nil)
    }
    
    /// Stops the capture session.
    func stopScanning() {
        
        DispatchQueue.global(qos: .userInitiated).async {
            if self.isScanning {
                self.qrCodeScannerView.captureSession.stopRunning()
            }
        }
    }
    
    /// Resumes the capture session.
    func resumeScanning() {
        
        guard cameraNotAvailable == false else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            if !self.isScanning {
                self.isScanning = true
                self.qrCodeScannerView.scanQRCode(self.qrCodeScannerView.frame.width , height: self.qrCodeScannerView.frame.height)
            } else {
                self.qrCodeScannerView.captureSession.startRunning()
            }
        }
    }
}

// MARK: - QR Code Scanner Delegate

extension InvoiceScannerViewController: QRCodeScannerDelegate {
    
    func detectedQRCode(withCaptureResult captureResult: String) {
        
        guard let encodedCaptureResult = captureResult.data(using: String.Encoding.utf8) else {
            qrCodeScannerView.captureSession.startRunning()
            return
        }
        
        let captureResultJSON = JSON(data: encodedCaptureResult)
        
        do {
            try validate(captureResult: captureResultJSON)
            
            switch captureResultJSON[QRKeys.DataType.rawValue].intValue {
            case QRType.userData.rawValue:
                
                print("scanned contact")
                let contactJsonData = captureResultJSON[QRKeys.Data.rawValue]
                addContact(withJsonData: contactJsonData)
                
            case QRType.invoice.rawValue:
                
                print("scanned invoice")
                let invoiceJsonData = captureResultJSON[QRKeys.Data.rawValue]
                performSegue(withIdentifier: "showTransactionSendViewController", sender: invoiceJsonData)
                
            default:
                throw AccountImportValidation.versionNotMatching
            }
            
        } catch AccountImportValidation.versionNotMatching {
            
            failedDetectingQRCode(withError: "WRONG_QR_VERSION".localized())
            qrCodeScannerView.captureSession.startRunning()
            return
            
        } catch {
            
            qrCodeScannerView.captureSession.startRunning()
            return
        }
    }
    
    func failedDetectingQRCode(withError errorMessage: String) {
        
        cameraNotAvailable = true
        
        let qrCodeDetectionFailureAlert: UIAlertController = UIAlertController(title: "INFO".localized(), message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        qrCodeDetectionFailureAlert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: nil))
        
        DispatchQueue.main.async {
            
            self.present(qrCodeDetectionFailureAlert, animated: true, completion: nil)
        }
    }
}
