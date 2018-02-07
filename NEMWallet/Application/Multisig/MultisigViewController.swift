//
//  MultisigViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import SwiftyJSON

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

/// The view controller that lets the user manage multisig for the account.
class MultisigViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    fileprivate var account: Account?
    fileprivate var accountData: AccountData?
    fileprivate var activeAccountData: AccountData?
    fileprivate var addedCosignatories = [String]()
    fileprivate var removedCosignatories = [String]()
    fileprivate var accountChooserViewController: UIViewController?
    fileprivate var minCosignatoriesUserPreference: Int?
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var multisigAccountChooserButton: AccountChooserButton!
    @IBOutlet weak var infoHeaderLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        account = AccountManager.sharedInstance.activeAccount
        
        guard account != nil else {
            print("Critical: Account not available!")
            return
        }
        
        showLoadingView()
        updateViewControllerAppearance()
        
        fetchAccountData(forAccount: account!)
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "MULTISIG".localized()
        multisigAccountChooserButton.setImage(#imageLiteral(resourceName: "DropDown").imageWithColor(UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)), for: UIControlState())
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    /**
        Updates the info header label with the fetched account data.
     
        - Parameter accountData: The fetched account data for the account.
     */
    fileprivate func updateInfoHeaderLabel(withAccountData accountData: AccountData?) {
        
        guard accountData != nil else {
            infoHeaderLabel.attributedText = NSMutableAttributedString(string: "LOST_CONNECTION".localized(), attributes: [NSForegroundColorAttributeName : UIColor.red])
            return
        }
        
        let accountTitle = accountData!.title != nil ? accountData!.title! : accountData!.address.nemAddressNormalised()
        let infoHeaderText = NSMutableAttributedString(string: "\(accountTitle)")
        infoHeaderLabel.attributedText = infoHeaderText
    }
    
    /**
        Updates the multisig account chooser button title with the fetched account data.
     
        - Parameter accountData: The fetched account data for the account.
     */
    fileprivate func updateAccountChooserButtonTitle(withAccountData accountData: AccountData?) {
        
        guard accountData != nil else {
            multisigAccountChooserButton.setTitle("LOST_CONNECTION".localized(), for: .normal)
            return
        }
        
        let accountTitle = accountData!.title != nil ? accountData!.title! : accountData!.address.nemAddressNormalised()
        multisigAccountChooserButton.setTitle(accountTitle, for: .normal)
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
        Shows the loading view above the table view which shows
        an spinning activity indicator.
     */
    fileprivate func showLoadingView() {
        
        loadingActivityIndicator.startAnimating()
        loadingView.isHidden = false
    }
    
    /// Hides the loading view.
    fileprivate func hideLoadingView() {
        
        loadingView.isHidden = true
        loadingActivityIndicator.stopAnimating()
    }
    
    /**
        Fetches the account data (balance, cosignatories, etc.) for the current account from the active NIS.
     
        - Parameter account: The current account for which the account data should get fetched.
     */
    fileprivate func fetchAccountData(forAccount account: Account) {
        
        NEMProvider.request(NEM.accountData(accountAddress: account.address)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    let accountData = try json.mapObject(AccountData.self)
                    
                    DispatchQueue.main.async {
                        
                        self?.accountData = accountData
                        self?.activeAccountData = accountData
                        
                        if self?.accountData?.cosignatoryOf.count > 0 {
                            
                            self?.multisigAccountChooserButton.isHidden = false
                            self?.infoHeaderLabel.isHidden = true
                            
                            self?.updateAccountChooserButtonTitle(withAccountData: accountData)
                            
                        } else {
                            
                            self?.multisigAccountChooserButton.isHidden = true
                            self?.infoHeaderLabel.isHidden = false
                            
                            self?.updateInfoHeaderLabel(withAccountData: accountData)
                        }
                        
                        self?.tableView.reloadData()
                        self?.hideLoadingView()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                }
            }
        }
    }
    
    /**
        Fetches the account data (balance, cosignatories, etc.) for the current account from the active NIS.
     
        - Parameter accountData: The current account for which the account data should get fetched.
     */
    fileprivate func fetchAccountData(forAccount accountData: AccountData) {
        
        addedCosignatories = [String]()
        removedCosignatories = [String]()
        
        NEMProvider.request(NEM.accountData(accountAddress: accountData.address)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    let accountData = try json.mapObject(AccountData.self)
                    
                    DispatchQueue.main.async {
                        
                        self?.activeAccountData = accountData
                        
                        if self?.accountData?.cosignatoryOf.count > 0 {
                            
                            self?.multisigAccountChooserButton.isHidden = false
                            self?.infoHeaderLabel.isHidden = true
                            
                            self?.updateAccountChooserButtonTitle(withAccountData: accountData)
                            
                        } else {
                            
                            self?.multisigAccountChooserButton.isHidden = true
                            self?.infoHeaderLabel.isHidden = false
                            
                            self?.updateInfoHeaderLabel(withAccountData: accountData)
                        }
                        
                        self?.tableView.reloadData()
                        self?.hideLoadingView()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                }
            }
        }
    }
    
    /**
        Signs and announces a new transaction to the NIS.
     
        - Parameter transaction: The transaction object that should get signed and announced.
     */
    fileprivate func announceTransaction(_ transaction: Transaction) {
        
        let requestAnnounce = TransactionManager.sharedInstance.signTransaction(transaction, account: account!)
        
        NEMProvider.request(NEM.announceTransaction(requestAnnounce: requestAnnounce)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    let responseJSON = JSON(data: response.data)

                    try self?.validateAnnounceTransactionResult(responseJSON)
                    
                    DispatchQueue.main.async {
                        
                        self?.showAlert(withMessage: "TRANSACTION_ANOUNCE_SUCCESS".localized())
                        
                        self?.minCosignatoriesUserPreference = nil
                    }
                    
                } catch TransactionAnnounceValidation.failure(let errorMessage) {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        self?.showAlert(withMessage: errorMessage)
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        self?.showAlert(withMessage: "TRANSACTION_ANOUNCE_FAILED".localized())
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    self?.showAlert(withMessage: "TRANSACTION_ANOUNCE_FAILED".localized())
                }
            }
        }
    }
    
    /**
        Validates the response (announce transaction result object) of the NIS
        regarding the announcement of the transaction.
     
        - Parameter responseJSON: The response of the NIS JSON formatted.
     
        - Throws:
        - TransactionAnnounceValidation.Failure if the announcement of the transaction wasn't successful.
     */
    fileprivate func validateAnnounceTransactionResult(_ responseJSON: JSON) throws {
        
        guard let responseCode = responseJSON["code"].int else { throw TransactionAnnounceValidation.failure(errorMessage: "TRANSACTION_ANOUNCE_FAILED".localized()) }
        let responseMessage = responseJSON["message"].stringValue
        
        switch responseCode {
        case 1:
            return
        default:
            throw TransactionAnnounceValidation.failure(errorMessage: responseMessage)
        }
    }
    
    /**
        Removes the cosignatory from the table view.
     
        - Parameter indexPath: The index path of the cosignatory that should get removed.
     */
    fileprivate func deleteCosignatory(atIndexPath indexPath: IndexPath) {
        
        if indexPath.row < activeAccountData!.cosignatories.count {
            
            removedCosignatories.append(activeAccountData!.cosignatories[indexPath.row].publicKey)
            activeAccountData!.cosignatories.remove(at: indexPath.row)
            
        } else {
            
            addedCosignatories.remove(at: indexPath.row - activeAccountData!.cosignatories.count)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func chooseAccount(_ sender: UIButton) {
        
        if accountChooserViewController == nil {
            
            var accounts = accountData!.cosignatoryOf ?? []
            accounts.append(accountData!)
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let accountChooserViewController = mainStoryboard.instantiateViewController(withIdentifier: "AccountChooserViewController") as! AccountChooserViewController
            accountChooserViewController.view.frame = CGRect(x: tableView.frame.origin.x, y:  tableView.frame.origin.y, width: tableView.frame.width, height: tableView.frame.height)
            accountChooserViewController.view.layer.opacity = 0
            accountChooserViewController.delegate = self
            accountChooserViewController.accounts = accounts
            
            self.accountChooserViewController = accountChooserViewController
            
            if accounts.count > 0 {
                view.addSubview(accountChooserViewController.view)
                
                UIView.animate(withDuration: 0.2, animations: {
                    accountChooserViewController.view.layer.opacity = 1
                })
            }
            
        } else {
            
            accountChooserViewController!.view.removeFromSuperview()
            accountChooserViewController!.removeFromParentViewController()
            accountChooserViewController = nil
        }
    }
    
    @IBAction func unwindToMultisigViewController(_ sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.source as? MultisigAddCosignatoryViewController {
            let newCosignatoryPublicKey = sourceViewController.newCosignatoryPublicKey
            
            addedCosignatories.append(newCosignatoryPublicKey!)
            tableView.reloadData()
        }
    }
    
    @IBAction func saveMultisigChanges(_ sender: UIButton) {
        
        guard removedCosignatories.count <= 1 else {
            showAlert(withMessage: "MULTISIG_REMOVE_COUNT_ERROR".localized())
            return
        }
        guard (activeAccountData!.cosignatories.count + addedCosignatories.count) <= 16 else {
            showAlert(withMessage: "MULTISIG_COSIGNATORIES_COUNT_ERROR".localized())
            return
        }
        
        // TODO:
        let originalMinCosignatories = (activeAccountData!.minCosignatories == 0 || activeAccountData!.minCosignatories == activeAccountData!.cosignatories.count) ? activeAccountData!.cosignatories.count : activeAccountData!.minCosignatories ?? 0

        var relativeChange = 0

        if let minCosignatoriesUserPreference = minCosignatoriesUserPreference {
            
            if minCosignatoriesUserPreference > originalMinCosignatories {
                relativeChange = minCosignatoriesUserPreference - originalMinCosignatories
            } else if minCosignatoriesUserPreference == originalMinCosignatories {
                relativeChange = 0
            } else {
                relativeChange = minCosignatoriesUserPreference - originalMinCosignatories
            }
            
            print("USER PREFERRED!: \(minCosignatoriesUserPreference) RELCHANGE: \(relativeChange)")
            
        } else {
            
            for _ in addedCosignatories {
                relativeChange += 1
            }
            for _ in removedCosignatories {
                relativeChange -= 1
            }
            
            print("NO USER PREF: RELCHANGE:\(relativeChange)")
            
        }
        
        let transactionVersion = 2
        let transactionTimeStamp = Int(TimeManager.sharedInstance.currentNetworkTime)
        var transactionFee = 0.5
        let transactionRelativeChange = relativeChange
        let transactionDeadline = Int(TimeManager.sharedInstance.currentNetworkTime + Constants.transactionDeadline)
                
        var transactionSigner = activeAccountData!.publicKey
        if activeAccountData!.cosignatories.count == 0 {
            transactionSigner = account!.publicKey
        }
        
        let transaction = MultisigAggregateModificationTransaction(version: transactionVersion, timeStamp: transactionTimeStamp, fee: Int(transactionFee * 1000000), relativeChange: transactionRelativeChange, deadline: transactionDeadline, signer: transactionSigner!)
        
        for cosignatoryAccount in addedCosignatories {
            transaction!.addModification(.addCosignatory, cosignatoryAccount: cosignatoryAccount)
        }
        
        for cosignatoryAccount in removedCosignatories {
            transaction!.addModification(.deleteCosignatory, cosignatoryAccount: cosignatoryAccount)
        }
        
        // Check if the transaction is a multisig transaction
        if activeAccountData!.publicKey != account!.publicKey {
            
            let multisigTransaction = MultisigTransaction(version: 1, timeStamp: transactionTimeStamp, fee: Int(0.15 * 1000000), deadline: transactionDeadline, signer: account!.publicKey, innerTransaction: transaction!)
            
            announceTransaction(multisigTransaction!)
            return
        }

        announceTransaction(transaction!)
    }
    
    @IBAction func minCosignatoriesChanged(_ sender: UITextField) {
        
        guard let minCosignatories = Int(sender.text!) else {
            sender.text = ""
            minCosignatoriesUserPreference = nil
            tableView.reloadData()
            return
        }
        
        let originalMinCosignatories = (activeAccountData!.minCosignatories == 0 || activeAccountData!.minCosignatories == activeAccountData!.cosignatories.count) ? activeAccountData!.cosignatories.count : activeAccountData!.minCosignatories ?? 0
        
        if activeAccountData!.cosignatories.count <= minCosignatories {
            minCosignatoriesUserPreference = activeAccountData!.cosignatories.count
        } else if minCosignatories < 0 {
            minCosignatoriesUserPreference = originalMinCosignatories
        } else {
            minCosignatoriesUserPreference = minCosignatories
        }
        
        if minCosignatoriesUserPreference == originalMinCosignatories {
            sender.text = ""
            minCosignatoriesUserPreference = nil
            tableView.reloadData()
            return
        }
        
        print(minCosignatoriesUserPreference!)
        
        sender.text = ""
        sender.placeholder = "\(String(format: "MIN_COSIG_PLACEHOLDER_CHANGED".localized(), "\(minCosignatoriesUserPreference!)"))"
        
        tableView.reloadData()
    }
}

// MARK: - Table View Delegate

extension MultisigViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let activeAccountData = activeAccountData {
            if activeAccountData.cosignatories.count > 0 {
                if accountData == activeAccountData {
                    
                    return activeAccountData.cosignatories.count
                    
                } else {
                    
                    if addedCosignatories.count > 0 || removedCosignatories.count > 0 || minCosignatoriesUserPreference != nil {
                        
                        return activeAccountData.cosignatories.count + addedCosignatories.count + 3

                    } else {
                        
                        return activeAccountData.cosignatories.count + addedCosignatories.count + 2
                    }
                }
                
            } else {
                
                if addedCosignatories.count > 0 || removedCosignatories.count > 0 {
                    
                    return addedCosignatories.count + 3

                } else {
                    
                    return addedCosignatories.count + 1
                }
            }
            
        } else {
            
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if activeAccountData?.cosignatories.count > 0 {
            if accountData == activeAccountData {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigCosignatoryTableViewCell") as! MultisigCosignatoryTableViewCell
                cell.cosignatoryAccountData = activeAccountData!.cosignatories[indexPath.row]
                
                return cell
                
            } else {
                
                if indexPath.row < activeAccountData!.cosignatories.count {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigCosignatoryTableViewCell") as! MultisigCosignatoryTableViewCell
                    cell.cosignatoryAccountData = activeAccountData!.cosignatories[indexPath.row]
                    
                    return cell
                    
                } else if indexPath.row >= activeAccountData!.cosignatories.count && indexPath.row < activeAccountData!.cosignatories.count + addedCosignatories.count {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigCosignatoryTableViewCell") as! MultisigCosignatoryTableViewCell
                    cell.cosignatoryIdentifier = addedCosignatories[indexPath.row - activeAccountData!.cosignatories.count]
                    
                    return cell
                    
                } else if indexPath.row == activeAccountData!.cosignatories.count + addedCosignatories.count {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigAddCosignatoryTableViewCell") as! MultisigAddCosignatoryTableViewCell
                    
                    return cell
                    
                } else if indexPath.row == activeAccountData!.cosignatories.count + addedCosignatories.count + 1 {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigMinimumCosignatoriesTableViewCell") as! MultisigMinimumCosignatoriesTableViewCell
                    
                    let minCosignatories = (activeAccountData!.minCosignatories == 0 || activeAccountData!.minCosignatories == activeAccountData!.cosignatories.count) ? activeAccountData!.cosignatories.count : activeAccountData!.minCosignatories
                    
                    if minCosignatoriesUserPreference == nil {
                        cell.textField.placeholder = String(format: ("MIN_COSIG_PLACEHOLDER".localized()), "\(minCosignatories!)")
                    }
                    
                    return cell
                    
                } else {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigSaveChangesTableViewCell") as! MultisigSaveChangesTableViewCell
                    
                    return cell
                }
            }
            
        } else {
            
            if indexPath.row < addedCosignatories.count {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigCosignatoryTableViewCell") as! MultisigCosignatoryTableViewCell
                cell.cosignatoryIdentifier = addedCosignatories[indexPath.row]
                
                return cell
                
            } else if indexPath.row == addedCosignatories.count {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigAddCosignatoryTableViewCell") as! MultisigAddCosignatoryTableViewCell
                
                return cell
                
            } else if indexPath.row == addedCosignatories.count + 1 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigMinimumCosignatoriesTableViewCell") as! MultisigMinimumCosignatoriesTableViewCell
                
                let minCosignatories = addedCosignatories.count
                
                cell.textField.placeholder = String(format: ("MIN_COSIG_PLACEHOLDER".localized()), "\(minCosignatories)")
                
                return cell
                
            } else {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "MultisigSaveChangesTableViewCell") as! MultisigSaveChangesTableViewCell
                
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        switch editingStyle {
        case .delete:
            
            deleteCosignatory(atIndexPath: indexPath)
            
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            
        if activeAccountData?.cosignatories.count > 0 {
            if accountData == activeAccountData {
                
                return false
                
            } else {
                
                if indexPath.row < activeAccountData!.cosignatories.count {
                    
                    if removedCosignatories.count == 0 {
                        return true
                    } else {
                        return false
                    }
                    
                } else if indexPath.row >= activeAccountData!.cosignatories.count && indexPath.row < activeAccountData!.cosignatories.count + addedCosignatories.count {
                    
                    return true
                    
                } else {
                    
                    return false
                }
            }
            
        } else {
            
            if indexPath.row < addedCosignatories.count {
                
                return true
                
            } else {
                
                return false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == addedCosignatories.count + activeAccountData!.cosignatories.count {
            
            performSegue(withIdentifier: "showMultisigAddCosignatoryViewController", sender: nil)
        }
    }
}

// MARK: - Account Chooser Delegate

extension MultisigViewController: AccountChooserDelegate {
    
    func didChooseAccount(_ accountData: AccountData) {
        
        activeAccountData = accountData
        
        accountChooserViewController?.view.removeFromSuperview()
        accountChooserViewController?.removeFromParentViewController()
        accountChooserViewController = nil
        
        fetchAccountData(forAccount: accountData)
    }
}
