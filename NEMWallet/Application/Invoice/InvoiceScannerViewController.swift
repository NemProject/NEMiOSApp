//
//  InvoiceScannerViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import AVFoundation
import SwiftyJSON
import Contacts

/// The view controller that lets the user scan an invoice.
final class InvoiceScannerViewController: UIViewController {
    
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
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var qrCodeScannerView: QRScannerView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        guard captureResult[QRKeys.dataType.rawValue].intValue == QRType.userData.rawValue || captureResult[QRKeys.dataType.rawValue].intValue == QRType.invoice.rawValue else { throw AccountImportValidation.dataTypeNotMatching }
        
        return true
    }
    
    /**
        Shows the add contact view controller with the received
        contact information already filled in.
     
        - Parameter jsonData: The contact information as a JSON array.
     */
    fileprivate func addContact(withJsonData jsonData: JSON) {
        
        let firstName = jsonData[QRKeys.name.rawValue].stringValue
        let lastName = jsonData["surname"].stringValue
        let accountAddress = jsonData[QRKeys.address.rawValue].stringValue
        
        let contact = CNMutableContact()
        contact.givenName = firstName
        contact.familyName = lastName
        let contactAccountAddress = CNLabeledValue(label: "NEM", value: accountAddress as NSString)
        contact.emailAddresses = [contactAccountAddress]
        
        InvoiceManager.sharedInstance.contactToCreate = contact
        
        performSegue(withIdentifier: "showAddressBookAddContactViewController", sender: nil)
    }
}

extension InvoiceScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
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
                    
                    switch captureResultJSON[QRKeys.dataType.rawValue].intValue {
                    case QRType.userData.rawValue:
                        
                        print("scanned contact")
                        let contactJsonData = captureResultJSON[QRKeys.data.rawValue]
                        addContact(withJsonData: contactJsonData)
                        
                    case QRType.invoice.rawValue:
                        
                        print("scanned invoice")
                        let invoiceJsonData = captureResultJSON[QRKeys.data.rawValue]
                        performSegue(withIdentifier: "showTransactionSendViewController", sender: invoiceJsonData)
                        
                    default:
                        throw AccountImportValidation.versionNotMatching
                    }
                    
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
