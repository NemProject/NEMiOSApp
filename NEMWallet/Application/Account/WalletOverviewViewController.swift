//
//  WalletOverviewViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import UIKit

/**
    The wallet overview gives the user an overview about his whole wallet.
    It lists all his accounts and gives the ability to add new accounts to the wallet.
 */
final class WalletOverviewViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    /// All accounts that are stored on the device, which will get listed in the table view.
    fileprivate var accounts = [Account]()
    
    /// This timer is used to keep the application time synchronized with the network time.
    private var networkTimeRefreshTimer: Timer?
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addAccountButton: UIButton!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        accounts = AccountManager.sharedInstance.accounts()
        updateViewControllerAppearance()
        startRefreshingNetworkTime()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if tableView.indexPathForSelectedRow != nil {
            let indexPath = tableView.indexPathForSelectedRow!
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showAccountDetailTabBarController":
            
            if let indexPath = tableView.indexPathForSelectedRow {
                AccountManager.sharedInstance.activeAccount = accounts[indexPath.row]
            }
            
        default:
            return
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
    
    /**
        Shows a confirmation alert for the account deletion and deletes the account if the user confirms the deletion
        or cancels the action if not.
     
        - Parameter indexPath: The index path of the account in the accounts array, that should get deleted.
     */
    fileprivate func deleteAccount(atIndexPath indexPath: IndexPath) {
        
        let accountToDelete = accounts[indexPath.row]
        
        let accountDeletionAlert = UIAlertController(title: "INFO".localized(), message: String(format: "DELETE_CONFIRMATION_MASSAGE_ACCOUNTS".localized(), accountToDelete.title), preferredStyle: .alert)
        accountDeletionAlert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil))
        accountDeletionAlert.addAction(UIAlertAction(title: "OK".localized(), style: .destructive, handler: { [unowned self] (action) in
            
            self.accounts.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .bottom)
            self.createEditButtonItemIfNeeded()
            AccountManager.sharedInstance.delete(account: accountToDelete, completion: { _ in })
        }))
        
        present(accountDeletionAlert, animated: true, completion: nil)
    }
    
    /**
        Moves an account from its previous position in the array to the new position and saves that change in the database.
     
        - Parameter sourceIndexPath: The previous index path of the account in the accounts array (before the move).
        - Parameter destinationIndexPath: The new index path of the account in the accounts array (after the move)
     */
    fileprivate func moveAccount(fromPosition sourceIndexPath: IndexPath, toPosition destinationIndexPath: IndexPath) {
        
        if sourceIndexPath == destinationIndexPath { return }
        
        let accountToMove = accounts[sourceIndexPath.row]
        accounts.remove(at: sourceIndexPath.row)
        accounts.insert(accountToMove, at: destinationIndexPath.row)
        
        AccountManager.sharedInstance.updatePosition(ofAccounts: accounts, completion: { _ in })
    }
    
    /**
        Asks the user to change the title for an account and makes the change accordingly.
     
        - Parameter indexPath: The index path of the account in the accounts array for which the title should get updated.
     */
    fileprivate func changeTitle(forAccountAtIndexPath indexPath: IndexPath) {
        
        let account = accounts[indexPath.row]
        
        let accountTitleChangerAlert = UIAlertController(title: "CHANGE".localized(), message: "INPUT_NEW_ACCOUNT_NAME".localized(), preferredStyle: .alert)
        accountTitleChangerAlert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil))
        accountTitleChangerAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: { [unowned self] (action) in
            
            let titleTextField = accountTitleChangerAlert.textFields![0] as UITextField
            if let newTitle = titleTextField.text {
                
                self.accounts[indexPath.row].title = newTitle
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                AccountManager.sharedInstance.updateTitle(forAccount: self.accounts[indexPath.row], withNewTitle: newTitle)
            }
        }))
        
        accountTitleChangerAlert.addTextField { (textField) in
            textField.text = account.title
        }
        
        present(accountTitleChangerAlert, animated: true, completion: nil)
    }
    
    /// Updates the appearance (coloring, titles) of the view controller.
    private func updateViewControllerAppearance() {
        
        navigationItem.title = "ACCOUNTS".localized()
        addAccountButton.setTitle("ADD_ACCOUNT".localized(), for: UIControlState())
        addAccountButton.setImage(#imageLiteral(resourceName: "Add").imageWithColor(UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)), for: UIControlState())
        addAccountButton.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        createEditButtonItemIfNeeded()
    }
    
    /**
        Checks if there are any accounts to show and creates an edit button item on the right of the 
        navigation bar if that's the case.
     */
    private func createEditButtonItemIfNeeded() {
        
        if (accounts.count > 0) {
            navigationItem.rightBarButtonItem = editButtonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    /// Starts refreshing the network time in a defined interval.
    private func startRefreshingNetworkTime() {
        
        networkTimeRefreshTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Constants.updateInterval), target: self, selector: #selector(WalletOverviewViewController.refreshNetworkTime), userInfo: nil, repeats: true)
    }
    
    /// Stops refreshing the network time.
    private func stopRefreshingNetworkTime() {
        
        networkTimeRefreshTimer?.invalidate()
        networkTimeRefreshTimer = nil
    }
    
    /// Synchronizes the application time with the network time.
    internal func refreshNetworkTime() {
        TimeManager.sharedInstance.synchronizeTime()
    }
    
    // MARK: - View Controller Outlet Actions
    
    /// Unwinds to the wallet overview view controller and reloads all accounts to show.
    @IBAction func unwindToWalletOverviewViewController(_ segue: UIStoryboardSegue) {
        
        accounts = AccountManager.sharedInstance.accounts()
        tableView.reloadData()
        createEditButtonItemIfNeeded()
    }
}

// MARK: - Table View Delegate

extension WalletOverviewViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell") as! AccountTableViewCell
        cell.title = accounts[indexPath.row].title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            changeTitle(forAccountAtIndexPath: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            performSegue(withIdentifier: "showAccountDetailTabBarController", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        switch editingStyle {
        case .delete:
            deleteAccount(atIndexPath: indexPath)
            
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        moveAccount(fromPosition: sourceIndexPath, toPosition: destinationIndexPath)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
