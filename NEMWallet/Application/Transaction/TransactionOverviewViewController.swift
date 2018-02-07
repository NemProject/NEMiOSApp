//
//  TransactionOverviewViewController.swift
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

/**
    The view controller that shows an overview of all transactions
    for the account that the user has chosen on the account list view
    controller.
 */
class TransactionOverviewViewController: UIViewController {
    
    // MARK: - View Controller Properties

    var account: Account?
    fileprivate var accountData: AccountData?
    fileprivate var transactions = [Transaction]()
    fileprivate var correspondents = [Correspondent]()
    fileprivate var showSignTransactionsAlert = true
    
    fileprivate var refreshTimer: Timer? = nil
    fileprivate let transactionOverviewDispatchGroup = DispatchGroup()
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoHeaderLabel: UILabel!
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
        updateViewControllerAppearanceOnViewDidLoad()
        refreshTransactionOverview(updateStatusBarButton: true)
        startRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViewControllerAppearanceOnViewWillAppear()
        createBarButtonItem()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        guard let navigationViewControllers = navigationController?.viewControllers else { return }
        
        // Needed to invalidate the refresh timer. Otherwise the view controller wouldn't get deinitialized.
        if navigationViewControllers.contains(where: { NSStringFromClass($0.classForCoder).components(separatedBy: ".").last! == "\(AccountDetailTabBarController.self)" }) != true {
            stopRefreshing()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showTransactionMessagesViewController":
            
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationViewController = segue.destination as! TransactionMessagesViewController
                destinationViewController.account = account
                destinationViewController.accountData = accountData
                destinationViewController.correspondent = correspondents[indexPath.row]
            }
            
        default:
            return
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller on view did load.
    fileprivate func updateViewControllerAppearanceOnViewDidLoad() {
        
        tabBarController?.title = "MESSAGES".localized()
        infoHeaderLabel.text = "NO_INTERNET_CONNECTION".localized()
    }
    
    /// Updates the appearance (coloring, titles) of the view controller on view will appear.
    fileprivate func updateViewControllerAppearanceOnViewWillAppear() {
        
        tabBarController?.title = "MESSAGES".localized()
    }
    
    /// Creates and adds the compose bar button item to the view controller.
    fileprivate func createBarButtonItem() {
        
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(segueToTransactionSendViewController))
        rightBarButtonItem.tintColor = UIColor.white
        
        tabBarController?.navigationItem.rightBarButtonItem = rightBarButtonItem
        
        if accountData != nil {
            updateBarButtonItemStatus(withAccountData: accountData!)
        } else {
            self.tabBarController?.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    /// Segues to the transaction send view controller.
    func segueToTransactionSendViewController() {
        performSegue(withIdentifier: "showTransactionSendViewController", sender: nil)
    }
    
    /**
        Updates the status of the compose bar button item according to the fetched
        account data. Enables the compose bar button item if the account isn't a 
        multisig account and disables the button if the account is a multisig account.
     
        - Parameter accountData: The fetched account data. Used to determine if the account is a multisig account.
     */
    fileprivate func updateBarButtonItemStatus(withAccountData accountData: AccountData) {
        
        if accountData.cosignatories?.count > 0 {
            self.tabBarController?.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            self.tabBarController?.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    /**
        Updates the info header label with the fetched account data (balance). Provide nil 
        as the account data to show a error message inside the info header label.
     
        - Parameter accountData: The fetched account data including the balance for the account. If this parameter doesn't get provided, the info header label will be updated with an error message.
     */
    fileprivate func updateInfoHeaderLabel(withAccountData accountData: AccountData?) {
        
        guard accountData != nil else {
            infoHeaderLabel.attributedText = NSMutableAttributedString(string: "LOST_CONNECTION".localized(), attributes: [NSForegroundColorAttributeName : UIColor.red])
            return
        }
        
        let infoHeaderText = NSMutableAttributedString(string: "\(self.account!.title) ·")
        let infoHeaderTextBalance = " \((accountData!.balance / 1000000).format()) XEM"
        infoHeaderText.append(NSMutableAttributedString(string: infoHeaderTextBalance, attributes: [NSForegroundColorAttributeName: UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: infoHeaderLabel.font.pointSize, weight: UIFontWeightRegular)]))
        
        infoHeaderLabel.attributedText = infoHeaderText
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
    
    /// Starts refreshing the transaction overview in the defined interval.
    fileprivate func startRefreshing() {
        
        refreshTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Constants.updateInterval), target: self, selector: #selector(TransactionOverviewViewController.refreshTransactionOverview), userInfo: nil, repeats: true)
    }
    
    /// Stops refreshing the transaction overview.
    fileprivate func stopRefreshing() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    /**
        Updates the transaction overview table view in an asynchronous manner.
        Fires off all necessary network calls to get the information needed.
        Use only this method to update the displayed information.
     
        - Parameter updateStatusBarButton: Bool whether the status bar button status should get updated or not.
    */
    func refreshTransactionOverview(updateStatusBarButton: Bool = false) {
        
        transactions = [Transaction]()
        
        fetchAccountData(forAccount: account!, updateStatusBarButton: updateStatusBarButton)
        fetchAllTransactions(forAccount: account!)
        fetchUnconfirmedTransactions(forAccount: account!)
        
        transactionOverviewDispatchGroup.notify(queue: .main) { 
            self.transactions.sort(by: { $0.timeStamp < $1.timeStamp })
            self.getCorrespondents(forTransactions: self.transactions)
        }
    }
    
    /**
        Fetches the account data (balance, cosignatories, etc.) for the current account from the active NIS.
        After a successful fetch the info header label gets updated with the account balance. The function
        also checks if the account is a multisig account and disables the compose bar button item accordingly.
        Do not call this function directly. Use the method refreshTransactionOverview.
     
        - Parameter account: The current account for which the account data should get fetched.
        - Parameter updateStatusBarButton: Bool whether the status bar button status should get updated or not.
     */
    fileprivate func fetchAccountData(forAccount account: Account, updateStatusBarButton: Bool = true) {

        transactionOverviewDispatchGroup.enter()
        
        NEMProvider.request(NEM.accountData(accountAddress: account.address)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    var accountData = try json.mapObject(AccountData.self)
                    
                    if accountData.publicKey == "" {
                        accountData.publicKey = account.publicKey
                    }
                    
                    DispatchQueue.main.async {
                        
                        if updateStatusBarButton {
                            self?.updateBarButtonItemStatus(withAccountData: accountData)
                        }
                        self?.updateInfoHeaderLabel(withAccountData: accountData)
                        
                        self?.accountData = accountData
                        
                        self?.transactionOverviewDispatchGroup.leave()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        self?.transactionOverviewDispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    self?.updateInfoHeaderLabel(withAccountData: nil)
                    
                    self?.transactionOverviewDispatchGroup.leave()
                }
            }
        }
    }
    
    /**
        Fetches the last 25 transactions for the current account from the active NIS.
        Do not call this function directly. Use the method refreshTransactionOverview.
     
        - Parameter account: The current account for which the transactions should get fetched.
     */
    fileprivate func fetchAllTransactions(forAccount account: Account) {
        
        transactionOverviewDispatchGroup.enter()
        
        NEMProvider.request(NEM.confirmedTransactions(accountAddress: account.address, server: nil)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    var allTransactions = [Transaction]()
                    
                    for (_, subJson) in json["data"] {
                        
                        switch subJson["transaction"]["type"].intValue {
                        case TransactionType.transferTransaction.rawValue:
                            
                            let transferTransaction = try subJson.mapObject(TransferTransaction.self)
                            allTransactions.append(transferTransaction)
                            
                        case TransactionType.multisigTransaction.rawValue:
                            
                            switch subJson["transaction"]["otherTrans"]["type"].intValue {
                            case TransactionType.transferTransaction.rawValue:
                                
                                let multisigTransaction = try subJson.mapObject(MultisigTransaction.self)
                                let transferTransaction = multisigTransaction.innerTransaction as! TransferTransaction
                                allTransactions.append(transferTransaction)
                                
                            default:
                                break
                            }
                            
                        default:
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {

                        self?.transactions += allTransactions
                        
                        if allTransactions.count > 0 {
                            
                            AccountManager.sharedInstance.updateLatestTransactionHash(forAccount: account, withLatestTransactionHash: (allTransactions.first as! TransferTransaction).metaData!.hash!)
                        }

                        self?.transactionOverviewDispatchGroup.leave()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")

                        self?.transactionOverviewDispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    self?.updateInfoHeaderLabel(withAccountData: nil)
                    
                    self?.transactionOverviewDispatchGroup.leave()
                }
            }
        }
    }
    
    /**
        Fetches all unconfirmed transactions for the provided account.
        Do not call this function directly. Use the method refreshTransactionOverview.
     
        - Parameter account: The account for which all unconfirmed transaction should get fetched.
     */
    fileprivate func fetchUnconfirmedTransactions(forAccount account: Account) {
        
        transactionOverviewDispatchGroup.enter()
        
        NEMProvider.request(NEM.unconfirmedTransactions(accountAddress: account.address, server: nil)) { [weak self] (result) in
            
            var needToSign = false
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    var unconfirmedTransactions = [Transaction]()
                    
                    for (_, subJson) in json["data"] {
                        
                        switch subJson["transaction"]["type"].intValue {
                        case TransactionType.transferTransaction.rawValue:
                            
                            let transferTransaction = try subJson.mapObject(TransferTransaction.self)
                            unconfirmedTransactions.append(transferTransaction)
                            
                        case TransactionType.multisigTransaction.rawValue:
                            
                            var foundSignature = false
                            
                            let multisigTransaction = try subJson.mapObject(MultisigTransaction.self)
                            
                            switch subJson["transaction"]["otherTrans"]["type"].intValue {
                            case TransactionType.transferTransaction.rawValue:
                                
                                let transferTransaction = multisigTransaction.innerTransaction as! TransferTransaction
                                unconfirmedTransactions.append(transferTransaction)
                                
                                if transferTransaction.recipient == account.address || transferTransaction.signer == account.publicKey {
                                    foundSignature = true
                                }
                                
                            case TransactionType.multisigAggregateModificationTransaction.rawValue:
                                
                                let multisigAggregateModificationTransaction = multisigTransaction.innerTransaction as! MultisigAggregateModificationTransaction
                                
                                for modification in multisigAggregateModificationTransaction.modifications where modification.cosignatoryAccount == account.publicKey {
                                    foundSignature = true
                                }
                                
                                if multisigAggregateModificationTransaction.signer == account.publicKey {
                                    foundSignature = true
                                }

                            default:
                                
                                foundSignature = true
                                break
                            }
                            
                            if multisigTransaction.signer == account.publicKey {
                                foundSignature = true
                            }
                            for signature in multisigTransaction.signatures! where signature.signer == account.publicKey {
                                foundSignature = true
                            }
                            
                            if foundSignature == false {
                                needToSign = true
                            }
                            
                        default:
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        self?.transactions += unconfirmedTransactions
                        
                        self?.transactionOverviewDispatchGroup.leave()
                        
                        if self != nil {
                            if needToSign && self!.showSignTransactionsAlert {
                                
                                let alert = UIAlertController(title: "INFO".localized(), message: "UNCONFIRMED_TRANSACTIONS_DETECTED".localized(), preferredStyle: UIAlertControllerStyle.alert)
                                
                                let alertCancelAction = UIAlertAction(title: "REMIND_LATER".localized(), style: UIAlertActionStyle.default, handler: { (action) in
                                    
                                    self?.showSignTransactionsAlert = false
                                })
                                alert.addAction(alertCancelAction)
                                
                                let alertShowUnsignedTransactionsAction = UIAlertAction(title: "SHOW_TRANSACTIONS".localized(), style: UIAlertActionStyle.default, handler: { (action) in
                                    
                                    self?.showSignTransactionsAlert = false
                                    self?.performSegue(withIdentifier: "showTransactionUnconfirmedViewController", sender: nil)
                                })
                                alert.addAction(alertShowUnsignedTransactionsAction)
                                
                                self?.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        self?.transactionOverviewDispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    self?.updateInfoHeaderLabel(withAccountData: nil)
                    
                    self?.transactionOverviewDispatchGroup.leave()
                }
            }
        }
    }
    
    /**
        Determines all correspondents for the provided transactions. Updates the table view with the
        correspondents once finished. Do not call this function directly. Use the method refreshTransactionOverview.
     
        - Parameter transactions: The transactions for which the correspondents should get determined.
     */
    fileprivate func getCorrespondents(forTransactions transactions: [Transaction]) {
        
        var correspondents = [Correspondent]()
        
        for transaction in transactions {
            
            switch transaction.type {
            case .transferTransaction:
                            
                let transaction = transaction as! TransferTransaction
                var correspondent: Correspondent? = nil
                
                if transaction.signer == account!.publicKey {
                    correspondent = Correspondent()
                    correspondent!.accountAddress = transaction.recipient
                    transaction.transferType = .outgoing
                } else if transaction.recipient == account!.address {
                    correspondent = Correspondent()
                    correspondent!.accountAddress = AccountManager.sharedInstance.generateAddress(forPublicKey: transaction.signer)
                    correspondent!.accountPublicKey = transaction.signer
                    transaction.transferType = .incoming
                }
                
                if correspondent != nil {
                    
                    // needed to decrypt messages where the current account was the sender.
                    if transaction.message?.payload != nil {
                        
                        transaction.message!.signer = correspondent!.accountPublicKey
                        transaction.message!.getMessageFromPayload()
                        
                        if transaction.message!.message == nil {
                            transaction.message!.message = "ENCRYPTED_MESSAGE".localized()
                        }
                    }
                    
                    if correspondents.contains(correspondent!) {
                        if let index = correspondents.index(of: correspondent!) {
                            if transaction.metaData?.id != nil {
                                correspondents[index].transactions.append(transaction)
                            } else {
                                correspondents[index].unconfirmedTransactions.append(transaction)
                            }
                            correspondents[index].mostRecentTransaction = transaction
                        }
                    } else {
                        if transaction.metaData?.id != nil {
                            correspondent!.transactions.append(transaction)
                        } else {
                            correspondent!.unconfirmedTransactions.append(transaction)
                        }
                        correspondent!.mostRecentTransaction = transaction
                        correspondents.append(correspondent!)
                    }
                }
                
            default:
                break
            }
        }
        
        correspondents.sort(by: { $0.mostRecentTransaction.timeStamp > $1.mostRecentTransaction.timeStamp })
        searchNames(forCorrespondents: &correspondents)

        self.correspondents = correspondents
        
        tableView.reloadData()
        hideLoadingView()
    }
    
    /**
        Searches the names for the provided correspondents if available. Checks if the
        correspondent is an account on the device and otherwise searches in the address
        book for a matching address. If the name for a correspondent couldn't be found,
        the account address of the correspondent will get shown in the transaction overview.
     
        - Parameter correspondents: The correspondents for which the names should get searched. This is a inout parameter and will write the names directly to the provided correspondent array.
     */
    fileprivate func searchNames(forCorrespondents correspondents: inout [Correspondent]) {
        
        let accounts = AccountManager.sharedInstance.accounts()
        
        for correspondent in correspondents {
            for account in accounts where account.address == correspondent.accountAddress {
                correspondent.name = account.title
            }
        }
    }
}

// MARK: - Table View Data Source

extension TransactionOverviewViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return correspondents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionOverviewCorrespondentTableViewCell") as! TransactionOverviewCorrespondentTableViewCell
        cell.account = account
        cell.correspondent = correspondents[indexPath.row]
        
        return cell
    }
}

// MARK: - Table View Delegate

extension TransactionOverviewViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
        performSegue(withIdentifier: "showTransactionMessagesViewController", sender: nil)
    }
}
