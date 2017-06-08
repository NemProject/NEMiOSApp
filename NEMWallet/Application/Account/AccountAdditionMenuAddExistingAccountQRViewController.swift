//
//  AccountAdditionMenuAddExistingAccountQRViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import SwiftyJSON

/**
    The account addition view controller that lets the user add an existing
    account through scanning the qr code for the account.
 */
class AccountAdditionMenuAddExistingAccountQRViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    /// Bool that indicates whether the QR code scanner view is already scanning.
    fileprivate var isScanning = false
    
    /// The title of the account that should get imported.
    fileprivate var accountTitle = String()
    
    /// The encrypted private key of the account that should get imported.
    fileprivate var accountEncryptedPrivateKey = String()
    
    /// The salt of the account that should get imported.
    fileprivate var accountSalt = String()
    
    fileprivate var cameraNotAvailable = false
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var qrCodeScannerView: QRCodeScannerView!

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    
        updateViewControllerAppearance()
        
        qrCodeScannerView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard cameraNotAvailable == false else { return }
        
        if !isScanning {
            isScanning = true
            qrCodeScannerView.scanQRCode(qrCodeScannerView.frame.width , height: qrCodeScannerView.frame.height)
        } else {
            qrCodeScannerView.captureSession.startRunning()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showAccountAdditionMenuPasswordValidationViewController":
            
            let destinationViewController = segue.destination as! AccountAdditionMenuPasswordValidationViewController
            destinationViewController.accountTitle = accountTitle
            destinationViewController.accountEncryptedPrivateKey = accountEncryptedPrivateKey
            destinationViewController.accountSalt = accountSalt
            
        default:
            return
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "SCAN_QR_CODE".localized()
    }
    
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
        guard captureResult[QRKeys.DataType.rawValue].intValue == QRType.accountData.rawValue else { throw AccountImportValidation.dataTypeNotMatching }
        guard captureResult["data"][QRKeys.Name.rawValue].string != nil else { throw AccountImportValidation.valueMissing }
        guard captureResult["data"][QRKeys.PrivateKey.rawValue].string != nil else { throw AccountImportValidation.valueMissing }
        guard captureResult["data"][QRKeys.Salt.rawValue].string != nil else { throw AccountImportValidation.valueMissing }
        
        return true
    }
}

// MARK: - QR Code Scanner Delegate

extension AccountAdditionMenuAddExistingAccountQRViewController: QRCodeScannerDelegate {
    
    func detectedQRCode(withCaptureResult captureResult: String) {
        
        guard let encodedCaptureResult = captureResult.data(using: String.Encoding.utf8) else {
            qrCodeScannerView.captureSession.startRunning()
            return
        }
                
        let captureResultJSON = JSON(data: encodedCaptureResult)
        
        do {
            let _ = try validate(captureResult: captureResultJSON)
            
        } catch AccountImportValidation.versionNotMatching {
            
            failedDetectingQRCode(withError: "WRONG_QR_VERSION".localized())
            qrCodeScannerView.captureSession.startRunning()
            return
            
        } catch {
            
            qrCodeScannerView.captureSession.startRunning()
            return
        }
        
        self.accountTitle = captureResultJSON["data"][QRKeys.Name.rawValue].string!
        self.accountEncryptedPrivateKey = captureResultJSON["data"][QRKeys.PrivateKey.rawValue].string!
        self.accountSalt = captureResultJSON["data"][QRKeys.Salt.rawValue].string!
        
        performSegue(withIdentifier: "showAccountAdditionMenuPasswordValidationViewController", sender: nil)
    }
    
    func failedDetectingQRCode(withError errorMessage: String) {
        
        cameraNotAvailable = true
        
        let qrCodeDetectionFailureAlert: UIAlertController = UIAlertController(title: "INFO".localized(), message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        qrCodeDetectionFailureAlert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: nil))
        
        present(qrCodeDetectionFailureAlert, animated: true, completion: nil)
    }
}
