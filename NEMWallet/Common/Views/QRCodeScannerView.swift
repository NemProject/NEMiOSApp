//
//  QRCodeScannerView.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import AVFoundation

// MARK: - QR Code Scanner Delegate Protocol

protocol QRCodeScannerDelegate {
    func detectedQRCode(withCaptureResult captureResult: String)
    func failedDetectingQRCode(withError errorMessage: String)
}

/**
    The view that is able to scan and detect a QR code and show a
    camera preview in the process. Once the view detected a QR code
    the view will show the detected qr code as an image instead of
    showing the camera preview.
 */
final class QRCodeScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - View Properties

    var delegate: QRCodeScannerDelegate?
    
    var captureSession :AVCaptureSession = AVCaptureSession()
    let capturePreviewLayer = AVCaptureVideoPreviewLayer()
    let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    var captureResult = String()

    // MARK: - View Helper Methods
    
    /**
        Starts scanning for a QR code. Shows the camera preview
        in this view while scanning. Once a QR code was detected 
        the delegate method captureOutput will get called.
     
        - Parameter width: The width of the qr scanner view.
        - Parameter height: The height of the qr scanner view.
     */
    func scanQRCode(_ width: CGFloat, height: CGFloat) {
        
        guard device != nil else {
            let errorMessage = "Failed to access device camera"
            delegate?.failedDetectingQRCode(withError: errorMessage)
            return
        }
        
        let captureInput = try? AVCaptureDeviceInput(device: device)
        let captureOutput = AVCaptureMetadataOutput()
        
        guard captureInput != nil else {
            let errorMessage = "Failed to access device camera"
            delegate?.failedDetectingQRCode(withError: errorMessage)
            return
        }
        
        captureSession.addInput(captureInput)
        captureOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(captureOutput)
        captureOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        let bounds: CGRect = CGRect(x: width / 2, y: height / 2, width: width, height: height)
        capturePreviewLayer.session = captureSession
        capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        capturePreviewLayer.bounds = bounds
        capturePreviewLayer.position = bounds.origin
        layer.addSublayer(capturePreviewLayer)
        
        captureSession.startRunning()
    }
    
    /**
        This delegate method will get called once a QR code got 
        detected.
     */
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        for item in metadataObjects {
            if let metadataObject = item as? AVMetadataMachineReadableCodeObject , metadataObject.type == AVMetadataObjectTypeQRCode {
                
                captureResult = metadataObject.stringValue
                captureSession.stopRunning()
                
                delegate?.detectedQRCode(withCaptureResult: captureResult)
            }
        }
    }
    
    /**
        Creates an image from the captured QR code.
     
        - Parameter captureResult: The capture result from the scanned QR code that should get turned into an image.
     
        - Returns: The scanned QR code as an image.
     */
    func createQRCodeImage(fromCaptureResult captureResult: String) -> UIImage {
        
        let qrCodeCIImage: CIImage = createQRCodeCIImage(fromCaptureResult: captureResult as NSString)
        let qrCodeUIImage: UIImage = createNonInterpolatedUIImage(fromCIImage: qrCodeCIImage, scale: 10)
        
        return UIImage(cgImage: qrCodeUIImage.cgImage!, scale: 1.0, orientation: .downMirrored)
    }
    
    /**
        Creates a CI image from the captured QR code.
     
        - Parameter captureResult: The capture result from the scanned QR code that should get turned into a CI image.
     
        - Returns: The scanned QR code as a CI image.
     */
    fileprivate func createQRCodeCIImage(fromCaptureResult captureResult: NSString) -> CIImage {
        
        let stringData: Data = captureResult.data(using: String.Encoding.utf8.rawValue)!
        let qrCodeFilter: CIFilter = CIFilter(name: "CIQRCodeGenerator")!
        qrCodeFilter.setValue(stringData, forKey: "inputMessage")
        qrCodeFilter.setValue("M", forKey: "inputCorrectionLevel")
        
        return qrCodeFilter.outputImage!
    }
    
    /**
        Creates a UI image from a provided CI image.
     
        - Parameter image: The CI image that should get converted into a UI image.
        - Parameter scale: The scale of the new UI image.
     
        - Returns: The converted UI image.
     */
    fileprivate func createNonInterpolatedUIImage(fromCIImage image: CIImage, scale: CGFloat) -> UIImage {
        
        let cgImage: CGImage = CIContext(options: nil).createCGImage(image, from: image.extent)!
        
        UIGraphicsBeginImageContext(CGSize(width: image.extent.size.width * scale, height: image.extent.size.height * scale ))
        let context: CGContext = UIGraphicsGetCurrentContext()!
        
        context.interpolationQuality = CGInterpolationQuality.none
        context.draw(cgImage, in: context.boundingBoxOfClipPath)
        
        let scaledImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}
