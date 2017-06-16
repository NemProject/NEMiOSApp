//
//  MoreMenuViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The more menu view controller that shows more actions / options to choose from.
final class MoreMenuViewController: UITableViewController {
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var menuMultisigHeadingLabel: UILabel!
    @IBOutlet weak var menuHarvestingHeadingLabel: UILabel!
    @IBOutlet weak var menuExportingHeadingLabel: UILabel!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateViewControllerAppearanceOnViewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViewControllerAppearanceOnViewWillAppear()
        
        if (tableView.indexPathForSelectedRow != nil) {
            let indexPath = tableView.indexPathForSelectedRow!
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller on view did load.
    fileprivate func updateViewControllerAppearanceOnViewDidLoad() {
        
        tabBarController?.title = "MORE".localized()
        menuMultisigHeadingLabel.text = "MULTISIG".localized()
        menuHarvestingHeadingLabel.text = "HARVEST_DETAILS".localized()
        menuExportingHeadingLabel.text = "EXPORT_ACCOUNT".localized()
        
        tabBarController?.navigationItem.rightBarButtonItem = nil
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    /// Updates the appearance (coloring, titles) of the view controller on view will appear.
    fileprivate func updateViewControllerAppearanceOnViewWillAppear() {
        
        tabBarController?.title = "MORE".localized()
        tabBarController?.navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func unwindToMoreMenuViewController(_ sender: UIStoryboardSegue) {
        return
    }
}
