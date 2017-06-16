//
//  SettingsNotificationIntervalViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The view controller that lets the user change the notification update interval.
final class SettingsNotificationIntervalViewController: UITableViewController {
    
    // MARK: - View Controller Properties

    fileprivate let intervals = [0, 90, 180, 360, 720, 1440, 2880, 4320, 8640]
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
    }
    
    // MARK: - Table View Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return intervals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsOptionTableViewCell") as! SettingsOptionTableViewCell
        
        switch intervals[indexPath.row] {
        case 0:
            cell.title = "NEVER".localized()
        case 90:
            cell.title = "30 " + "MINUTES".localized()
        case 180:
            cell.title = "60 " + "MINUTES".localized()
        case 360:
            cell.title = "1 " + "HOURS".localized()
        case 720:
            cell.title = "2 " + "HOURS".localized()
        case 1440:
            cell.title = "4 " + "HOURS".localized()
        case 2880:
            cell.title = "8 " + "HOURS".localized()
        case 4320:
            cell.title = "12 " + "HOURS".localized()
        case 8640:
            cell.title = "24 " + "HOURS".localized()
        default :
            break
        }
        
        if intervals[indexPath.row] == SettingsManager.sharedInstance.notificationUpdateInterval() {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(intervals[indexPath.row]))
        }
        
        SettingsManager.sharedInstance.setNotificationUpdateInterval(notificationUpdateInterval: intervals[indexPath.row])
        
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "UPDATE_INTERVAL".localized()
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        
        navigationController?.popViewController(animated: true)
    }
}
