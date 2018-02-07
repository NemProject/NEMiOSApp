//
//  SettingsServerViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import SwiftyJSON

/// The view controller that lets the user handle all available settings in correspondence with servers/NIS.
class SettingsServerViewController: UIViewController {
    
    // MARK: - View Controller Properties

    var servers = [Server]()
    fileprivate var loadingIndexPath: IndexPath?
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addServerButton: UIButton!

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        servers = SettingsManager.sharedInstance.servers()
        
        updateViewControllerAppearance()
        createEditButtonItemIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (tableView.indexPathForSelectedRow != nil) {
            let indexPath = tableView.indexPathForSelectedRow!
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    /// Needed for a smooth appearance of the alert view controller.
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    /// Needed for a smooth appearance of the alert view controller.
    override var canResignFirstResponder: Bool {
        return true
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        navigationItem.title = "SERVER".localized()
        addServerButton.setTitle("ADD_SERVER".localized(), for: UIControlState())
        addServerButton.setImage(#imageLiteral(resourceName: "Add").imageWithColor(UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)), for: UIControlState())
        addServerButton.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    /**
        Checks if there are any servers to show and creates an edit button
        item on the right of the navigation bar if that's the case.
     */
    fileprivate func createEditButtonItemIfNeeded() {
        
        if (servers.count > 0) {
            navigationItem.rightBarButtonItem = editButtonItem
        }
    }
    
    /**
        Shows an alert view controller with the provided alert message.
     
        - Parameter message: The message that should get shown.
        - Parameter completion: An optional action that should get performed on completion.
     */
    fileprivate func showAlert(withMessage message: String, completion: ((Void) -> Void)? = nil) {
        
        let alert = UIAlertController(title: "INFO".localized(), message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            alert.dismiss(animated: true, completion: nil)
            completion?()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    /**
        Asks the user for confirmation of the deletion of a server and deletes
        the server accordingly from both the table view and the database.
     
        - Parameter indexPath: The index path of the server that should get removed and deleted.
     */
    fileprivate func deleteServer(atIndexPath indexPath: IndexPath) {
        
        let server = servers[indexPath.row]
        
        let serverDeletionAlert = UIAlertController(title: "INFO".localized(), message: String(format: "DELETE_CONFIRMATION_MASSAGE_SERVERS".localized(), server.address), preferredStyle: .alert)
        
        serverDeletionAlert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil))
        
        serverDeletionAlert.addAction(UIAlertAction(title: "OK".localized(), style: .destructive, handler: { [unowned self] (action) in
            
            self.servers.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .bottom)
            
            SettingsManager.sharedInstance.delete(server: server)
            self.tableView.reloadData()
        }))
        
        present(serverDeletionAlert, animated: true, completion: nil)
    }
    
    /**
        Asks the user to update the server properties for an existing server and makes
        the change accordingly.
     
        - Parameter indexPath: The index path of the server that should get updated.
     */
    fileprivate func updateServerProperties(forServerAtIndexPath indexPath: IndexPath) {
        
        let server = servers[indexPath.row]
        
        let serverPropertiesUpdaterAlert = UIAlertController(title: "CHANGE".localized(), message: "CHANGE_SERVER".localized(), preferredStyle: .alert)
        
        serverPropertiesUpdaterAlert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil))
        
        serverPropertiesUpdaterAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: { [unowned self] (action) in
            
            let protocolTextField = serverPropertiesUpdaterAlert.textFields![0] as UITextField
            let addressTextField = serverPropertiesUpdaterAlert.textFields![1] as UITextField
            let portTextField = serverPropertiesUpdaterAlert.textFields![2] as UITextField
            
            guard let newProtocolType = protocolTextField.text else { return }
            guard let newAddress = addressTextField.text else { return }
            guard let newPort = portTextField.text else { return }
            
            SettingsManager.sharedInstance.updateProperties(forServer: server, withNewProtocolType: newProtocolType, andNewAddress: newAddress, andNewPort: newPort, completion: { [weak self] (result) in
                
                self?.servers[indexPath.row].protocolType = newProtocolType
                self?.servers[indexPath.row].address = newAddress
                self?.servers[indexPath.row].port = newPort
                
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            })
        }))
        
        serverPropertiesUpdaterAlert.addTextField { (textField) in
            textField.text = server.protocolType
        }
        
        serverPropertiesUpdaterAlert.addTextField { (textField) in
            textField.text = server.address
        }
        
        serverPropertiesUpdaterAlert.addTextField { (textField) in
            textField.text = server.port
        }
        
        present(serverPropertiesUpdaterAlert, animated: true, completion: nil)
    }
    
    /**
        Tries to change the currently active server. If the server is reachable by a
        heartbeat call the change will get performed.
     
        - Parameter indexPath: The index path of the new server.
     */
    fileprivate func changeActiveServer(withServerAtIndexPath indexPath: IndexPath) {
        
        guard loadingIndexPath == nil else { return }
        
        let server = servers[indexPath.row]
        loadingIndexPath = indexPath
        tableView.reloadRows(at: [indexPath], with: .none)
        
        getHeartbeatResponse(fromServer: server) { [weak self] (result) in
            
            switch result {
            case .success:
                
                SettingsManager.sharedInstance.setActiveServer(server: server)
                self?.loadingIndexPath = nil
                self?.tableView.reloadData()
                TimeManager.sharedInstance.synchronizeTime()
                
            case .failure:
                
                self?.loadingIndexPath = nil
                self?.tableView.reloadData()
                self?.showAlert(withMessage: "SERVER_UNAVAILABLE".localized())
            }
        }
    }
    
    /**
        Sends a heartbeat request to the selected server to see if the server is a valid NIS.
     
        - Parameter server: The server that should get checked.
        
        - Returns: The result of the operation.
     */
    fileprivate func getHeartbeatResponse(fromServer server: Server, completion: @escaping (_ result: Result) -> Void) {
        
        NEMProvider.request(NEM.heartbeat(server: server)) { (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    DispatchQueue.main.async {
                        
                        return completion(.success)
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        return completion(.failure)
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    return completion(.failure)
                }
            }
        }
    }
    
    // MARK: - View Controller Outlet Actions
    
    /**
        Unwinds to the server view controller and reloads all
        servers to show.
     */
    @IBAction func unwindToServerViewController(_ segue: UIStoryboardSegue) {
        
        servers = SettingsManager.sharedInstance.servers()
        tableView.reloadData()
    }
}

// MARK: - Table View Data Source

extension SettingsServerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let server = servers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsServerTableViewCell") as! SettingsServerTableViewCell
        cell.title = server.fullURL().absoluteString
        
        if server == SettingsManager.sharedInstance.activeServer() {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        if let loadingIndexPath = loadingIndexPath {
            if indexPath.row == loadingIndexPath.row {
                cell.activityIndicator.startAnimating()
                cell.activityIndicator.isHidden = false
            }
        } else {
            cell.activityIndicator.isHidden = true
            cell.activityIndicator.stopAnimating()
        }
        
        return cell
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        switch editingStyle {
        case .delete:
            
            if servers.count > 1 {
                deleteServer(atIndexPath: indexPath)
            }
            
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if servers.count > 1 {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - Table View Delegate

extension SettingsServerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            updateServerProperties(forServerAtIndexPath: indexPath)
        } else {
            changeActiveServer(withServerAtIndexPath: indexPath)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
}
