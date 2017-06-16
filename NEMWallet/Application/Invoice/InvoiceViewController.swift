//
//  InvoiceViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The view controller that lets the user create and scan invoices.
final class InvoiceViewController: UIViewController {
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var infoContainerView: UIView!
    @IBOutlet weak var createInvoiceContainerView: UIView!
    @IBOutlet weak var scanInvoiceContainerView: UIView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearanceOnViewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViewControllerAppearanceOnViewWillAppear()
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller on view did load.
    fileprivate func updateViewControllerAppearanceOnViewDidLoad() {
        
        tabBarController?.title = "MY_INFO".localized()
        
        segmentedControl.setTitle("MY_INFO".localized(), forSegmentAt: 0)
        segmentedControl.setTitle("NEW_INVOICE".localized(), forSegmentAt: 1)
        segmentedControl.setTitle("SCAN_QR".localized(), forSegmentAt: 2)
        
        infoContainerView.isHidden = false
        createInvoiceContainerView.isHidden = true
        scanInvoiceContainerView.isHidden = true
    }
    
    /// Updates the appearance (coloring, titles) of the view controller on view will appear.
    fileprivate func updateViewControllerAppearanceOnViewWillAppear() {
        
        tabBarController?.navigationItem.rightBarButtonItem = nil
        handleSegmentChange(segmentedControl)
    }
    
    // MARK: - View Controller Outlet Actions

    @IBAction func handleSegmentChange(_ sender: UISegmentedControl) {
        
        switch segmentedControl.selectedSegmentIndex {
        case 0 :
            
            NotificationCenter.default.post(name: Notification.Name("stopCaptureSession"), object: nil)
            
            infoContainerView.isHidden = false
            createInvoiceContainerView.isHidden = true
            scanInvoiceContainerView.isHidden = true
            
            tabBarController?.title = "MY_INFO".localized()
            
        case 1 :
            
            NotificationCenter.default.post(name: Notification.Name("stopCaptureSession"), object: nil)
            
            createInvoiceContainerView.isHidden = false
            infoContainerView.isHidden = true
            scanInvoiceContainerView.isHidden = true

            tabBarController?.title = "NEW_INVOICE".localized()
            
        case 2 :
            
            NotificationCenter.default.post(name: Notification.Name("resumeCaptureSession"), object: nil)
            
            scanInvoiceContainerView.isHidden = false
            infoContainerView.isHidden = true
            createInvoiceContainerView.isHidden = true
            
            tabBarController?.title = "SCAN_QR".localized()

        default:
            break
        }
    }
}
