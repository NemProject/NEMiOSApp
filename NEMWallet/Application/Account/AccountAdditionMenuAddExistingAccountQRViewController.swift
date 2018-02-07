//
//  AccountAdditionMenuAddExistingAccountQRViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import AVFoundation
import SwiftyJSON

/**
    The account addition view controller that lets the user add an existing
    account through scanning the qr code for the account.
 */
final class AccountAdditionMenuAddExistingAccountQRViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
    private var setupResult: SessionSetupResult = .success
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var metaDataOutput = AVCaptureMetadataOutput()
    
    /// The title of the account that should get imported.
    fileprivate var accountTitle = String()
    
    /// The encrypted private key of the account that should get imported.
    fileprivate var accountEncryptedPrivateKey = String()
    
    /// The salt of the account that should get imported.
    fileprivate var accountSalt = String()
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var qrCodeScannerView: QRScannerView!

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    
        updateViewControllerAppearance()
        
        qrCodeScannerView.session = session
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            break
            
        case .notDetermined:
            
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            setupResult = .notAuthorized
        }
        
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                
                DispatchQueue.main.async { [unowned self] in
                    let alertController = UIAlertController(title: "Warning", message: "NEM Wallet doesn't have permission to use the camera, please change privacy settings", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .default, handler: { _ in
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                        }
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                
                DispatchQueue.main.async { [unowned self] in
                    let alertController = UIAlertController(title: "Error", message: "Something went wrong when accessing the device camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        sessionQueue.async { [weak self] in
            if self?.setupResult == .success {
                self?.session.stopRunning()
                self?.isSessionRunning = false
                self?.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
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
    
    ///
    private func configureSession() {
        
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            defaultVideoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    let initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    self.qrCodeScannerView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                    self.qrCodeScannerView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                }
            } else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add meta data output.
        if session.canAddOutput(metaDataOutput) {
            session.addOutput(metaDataOutput)
            metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metaDataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError, object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func sessionRuntimeError(notification: NSNotification) {
        
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        if error.code == .mediaServicesWereReset {
            sessionQueue.async { [unowned self] in
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    
                }
            }
        }
    }
    
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
        guard captureResult[QRKeys.version.rawValue].intValue == Constants.qrVersion else { throw AccountImportValidation.versionNotMatching }
        guard captureResult[QRKeys.dataType.rawValue].intValue == QRType.accountData.rawValue else { throw AccountImportValidation.dataTypeNotMatching }
        guard captureResult["data"][QRKeys.name.rawValue].string != nil else { throw AccountImportValidation.valueMissing }
        guard captureResult["data"][QRKeys.privateKey.rawValue].string != nil else { throw AccountImportValidation.valueMissing }
        guard captureResult["data"][QRKeys.salt.rawValue].string != nil else { throw AccountImportValidation.valueMissing }
        
        return true
    }
}

extension AccountAdditionMenuAddExistingAccountQRViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - Capture Output Delegate
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        for item in metadataObjects {
            if let metadataObject = item as? AVMetadataMachineReadableCodeObject , metadataObject.type == AVMetadataObjectTypeQRCode {
                
                guard let encodedCaptureResult = metadataObject.stringValue.data(using: String.Encoding.utf8) else {
                    return
                }
                
                let captureResultJSON = JSON(data: encodedCaptureResult)
                
                do {
                    let _ = try validate(captureResult: captureResultJSON)
                    
                    self.accountTitle = captureResultJSON["data"][QRKeys.name.rawValue].string!
                    self.accountEncryptedPrivateKey = captureResultJSON["data"][QRKeys.privateKey.rawValue].string!
                    self.accountSalt = captureResultJSON["data"][QRKeys.salt.rawValue].string!
                    
                    performSegue(withIdentifier: "showAccountAdditionMenuPasswordValidationViewController", sender: nil)
        
                } catch AccountImportValidation.versionNotMatching {
        
                    failedDetectingQRCode(withError: "WRONG_QR_VERSION".localized())
                    return
        
                } catch AccountImportValidation.dataTypeNotMatching {
                    
                    failedDetectingQRCode(withError: "Wrong QR code type")
                    return
                    
                } catch {
                    return
                }
            }
        }
    }
    
    func failedDetectingQRCode(withError errorMessage: String) {
        
        let qrCodeDetectionFailureAlert: UIAlertController = UIAlertController(title: "INFO".localized(), message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        qrCodeDetectionFailureAlert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: nil))
        
        DispatchQueue.main.async {
            self.present(qrCodeDetectionFailureAlert, animated: true, completion: nil)
        }
    }
}
