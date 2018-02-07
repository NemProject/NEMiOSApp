//
//  TransactionMessagesViewController.swift
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
    The view controller that shows all messages/transactions with the
    correspondent in detail.
 */
class TransactionMessagesViewController: UIViewController, UIAlertViewDelegate {
    
    // MARK: - View Controller Properties
    
    var account: Account?
    var correspondent: Correspondent?
    var accountData: AccountData?
    fileprivate var activeAccountData: AccountData?
    fileprivate var correspondentAccountData: AccountData?
    fileprivate var transactions = [Transaction]()
    fileprivate var unconfirmedTransactions = [Transaction]()
    fileprivate var rowHeight = [CGFloat]()
    fileprivate var willEncrypt = false
    fileprivate var accountChooserViewController: UIViewController?
    fileprivate var reloadingTableView = false
    
    fileprivate var refreshTimer: Timer? = nil
    fileprivate let correspondentTransactionsDispatchGroup = DispatchGroup()

    // MARK: - View Controller Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoHeaderLabel: UILabel!
    @IBOutlet weak var transactionAmountTextField: UITextField!
    @IBOutlet weak var transactionMessageTextField: UITextField!
    @IBOutlet weak var transactionEncryptionButton: UIButton!
    @IBOutlet weak var transactionSendButton: UIButton!
    @IBOutlet weak var transactionAccountChooserButton: UIButton!
    @IBOutlet weak var transactionAmountContainerView: UIView!
    @IBOutlet weak var transactionMessageContainerView: UIView!
    @IBOutlet weak var transactionEncryptionButtonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var transactionSendBarView: UIView!
    @IBOutlet weak var transactionSendBarBorderView: UIView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layoutIfNeeded()
        
        guard account != nil else {
            print("Fatal error: Account nil")
            return
        }
        guard correspondent != nil else {
            print("Fatal error: Correspondent nil")
            return
        }
        if accountData != nil {
            
            updateInfoHeaderLabel(withAccountData: accountData)
            
        } else {
            
            showLoadingView()
            refreshCorrespondentTransactions(shouldUpdateViewControllerAppearance: true)
            return
        }
        if correspondent!.accountPublicKey == nil {
            
            showLoadingView()
            fetchPublicKey(forCorrespondentWithAddress: correspondent!.accountAddress)
            
        } else {
            
            showCorrespondentTransactions()
            fetchPublicKey(forCorrespondentWithAddress: correspondent!.accountAddress)
            startRefreshing()
        }
        
        updateViewControllerAppearance()
        createBarButtonItem()
        
        NotificationCenter.default.addObserver(self, selector: #selector(TransactionMessagesViewController.keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        view.endEditing(true)
        stopRefreshing()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        view.layoutIfNeeded()
        
        title = correspondent!.name != nil ? correspondent!.name : correspondent!.accountAddress.nemAddressNormalised()
        transactionAmountTextField.placeholder = "AMOUNT".localized()
        transactionMessageTextField.placeholder = "MESSAGE".localized()
        transactionSendButton.setTitle("SEND".localized(), for: UIControlState())
        transactionAccountChooserButton.setTitle("ACCOUNTS".localized(), for: UIControlState())
        
        transactionAccountChooserButton.layer.cornerRadius = 5
        transactionSendButton.layer.cornerRadius = 5
        transactionAmountContainerView.layer.cornerRadius = 5
        transactionAmountContainerView.clipsToBounds = true
        transactionMessageContainerView.layer.cornerRadius = 5
        transactionMessageContainerView.clipsToBounds = true
        
        if accountData!.cosignatories?.count > 0 {
            transactionSendBarView.isHidden = true
            transactionSendBarBorderView.isHidden = true
            
            tableViewBottomConstraint.constant = 0
        }
        
        if accountData!.cosignatoryOf?.count > 0 {
            transactionAccountChooserButton.isHidden = false

            transactionEncryptionButtonTrailingConstraint.constant = transactionAccountChooserButton.frame.width + 5 + 8
        }
    }
    
    /// Creates and adds the compose bar button item to the view controller.
    fileprivate func createBarButtonItem() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Copy", style: UIBarButtonItemStyle.plain, target: self, action: #selector(copyCorrespondentAddress(_:)))
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
        
        let accountTitle = accountData!.title != nil ? accountData!.title! : accountData!.address.nemAddressNormalised()
        let infoHeaderText = NSMutableAttributedString(string: "\(accountTitle) ·")
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
    
    /// Scrolls to the table view bottom as soon as the keyboard appears.
    func keyboardWillShowNotification(_ notification: Notification) {
        scrollToTableBottom(true)
    }
    
    /// Starts refreshing the transaction overview in the defined interval.
    fileprivate func startRefreshing() {
        
        refreshTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Constants.updateInterval), target: self, selector: #selector(TransactionMessagesViewController.refreshCorrespondentTransactions), userInfo: nil, repeats: true)
    }
    
    /// Stops refreshing the transaction overview.
    fileprivate func stopRefreshing() {
        refreshTimer?.invalidate()
    }
    
    /**
        Updates the correspondent transactions table view with the provided
        transactions from the correspondent. Shows the already fetched transactions
        instantly upon view did load. Use this function only on view did load.
     */
    func showCorrespondentTransactions() {
        
        transactions = correspondent!.transactions
        unconfirmedTransactions = correspondent!.unconfirmedTransactions
        
        getTransactionsForCorrespondent(fromTransactions: &self.transactions)
        getTransactionsForCorrespondent(fromTransactions: &self.unconfirmedTransactions)
        
        calculateCellHeights()
        
        tableView.reloadData()
        hideLoadingView()
    }

    /**
        Updates the correspondent transactions table view in an asynchronous manner.
        Fires off all necessary network calls to get the information needed.
        Use only this method to update the displayed information.
     */
    func refreshCorrespondentTransactions(shouldUpdateViewControllerAppearance: Bool = false) {
                
        fetchAccountData(forAccount: account!, shouldUpdateViewControllerAppearance: shouldUpdateViewControllerAppearance)
        fetchAllTransactions(forAccount: account!)
        fetchUnconfirmedTransactions(forAccount: account!)
        
        correspondentTransactionsDispatchGroup.notify(queue: .main) {
            self.getTransactionsForCorrespondent(fromTransactions: &self.transactions)
            self.getTransactionsForCorrespondent(fromTransactions: &self.unconfirmedTransactions)
            
            self.rowHeight = [CGFloat]()
            self.calculateCellHeights()
            
            if self.reloadingTableView == false {
                self.tableView.reloadData()
            }
            
            if shouldUpdateViewControllerAppearance {
                self.updateViewControllerAppearance()
                self.hideLoadingView()
            }
        }
    }
    
    /**
        Fetches the account data (balance, cosignatories, etc.) for the current account from the active NIS.
        After a successful fetch the info header label gets updated with the account balance. The function
        also checks if the account is a multisig account and disables the compose bar button item accordingly.
        Do not call this function directly. Use the method refreshCorrespondentTransactions.
     
        - Parameter account: The current account for which the account data should get fetched.
     */
    fileprivate func fetchAccountData(forAccount account: Account, shouldUpdateViewControllerAppearance: Bool = false) {
        
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
                        
                        if self?.activeAccountData?.address == self?.account?.address {
                            self?.updateInfoHeaderLabel(withAccountData: accountData)
                        }
                        
                        self?.accountData = accountData
                        
                        if shouldUpdateViewControllerAppearance {
                            self?.updateInfoHeaderLabel(withAccountData: accountData)
                        }
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    self?.updateInfoHeaderLabel(withAccountData: nil)
                }
            }
        }
    }
    
    /**
        Fetches the public key for the current correspondent from the active NIS.
     
        - Parameter accountAddress: The account address of the current correspondent for which the public key should get fetched.
     */
    fileprivate func fetchPublicKey(forCorrespondentWithAddress accountAddress: String) {
        
        NEMProvider.request(NEM.accountData(accountAddress: accountAddress)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    let accountData = try json.mapObject(AccountData.self)
                    
                    DispatchQueue.main.async {
                        
                        self?.correspondent?.accountPublicKey = accountData.publicKey
                        self?.correspondentAccountData = accountData
                        self?.showCorrespondentTransactions()
                        self?.startRefreshing()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    self?.updateInfoHeaderLabel(withAccountData: nil)
                }
            }
        }
    }
    
    /**
        Fetches the last 25 transactions for the current account from the active NIS.
        Do not call this function directly. Use the method refreshCorrespondentTransactions.
     
        - Parameter account: The current account for which the transactions should get fetched.
     */
    fileprivate func fetchAllTransactions(forAccount account: Account) {
        
        correspondentTransactionsDispatchGroup.enter()
        
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
                                allTransactions.append(multisigTransaction)
                                
                            default:
                                break
                            }
                            
                        default:
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        self?.transactions = allTransactions
                        
                        self?.correspondentTransactionsDispatchGroup.leave()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        self?.correspondentTransactionsDispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    self?.updateInfoHeaderLabel(withAccountData: nil)
                    
                    self?.correspondentTransactionsDispatchGroup.leave()
                }
            }
        }
    }
    
    /**
        Fetches all unconfirmed transactions for the provided account.
        Do not call this function directly. Use the method refreshCorrespondentTransactions.
     
        - Parameter account: The account for which all unconfirmed transaction should get fetched.
     */
    fileprivate func fetchUnconfirmedTransactions(forAccount account: Account) {
        
        correspondentTransactionsDispatchGroup.enter()
        
        NEMProvider.request(NEM.unconfirmedTransactions(accountAddress: account.address, server: nil)) { [weak self] (result) in
            
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
                            
                            switch subJson["transaction"]["otherTrans"]["type"].intValue {
                            case TransactionType.transferTransaction.rawValue:
                                
                                let multisigTransaction = try subJson.mapObject(MultisigTransaction.self)
                                unconfirmedTransactions.append(multisigTransaction)
                                
                            default:
                                break
                            }
                            
                        default:
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        self?.unconfirmedTransactions = unconfirmedTransactions
                        
                        self?.correspondentTransactionsDispatchGroup.leave()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        self?.correspondentTransactionsDispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    self?.updateInfoHeaderLabel(withAccountData: nil)
                    
                    self?.correspondentTransactionsDispatchGroup.leave()
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
                        
                        self?.transactionAmountTextField.text = ""
                        self?.transactionMessageTextField.text = ""
                        self?.willEncrypt = false
                        self?.transactionEncryptionButton.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
                        self?.transactionEncryptionButton.isEnabled = self?.activeAccountData?.address == self?.accountData?.address
                        
                        if self != nil && transaction.type == .transferTransaction {
                            
                            self!.reloadingTableView = true
                            
                            self!.unconfirmedTransactions.append(transaction)
                            self!.getCellHeights(forTransactions: [transaction], withViewWidth: self!.tableView.frame.width - 120)
                            self!.tableView.reloadData()
                            self!.scrollToTableBottom(false)
                            
                            self!.reloadingTableView = false
                        }
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
                    self?.updateInfoHeaderLabel(withAccountData: nil)
                    self?.showAlert(withMessage: "TRANSACTION_ANOUNCE_FAILED".localized())
                }
            }
            
            self?.transactionSendButton.isEnabled = true
        }
    }
    
    /**
        Filters out all transaction in connection with the current correspondent and populates the
        table view with that information. Do not call this function directly. Use the method refreshTransactionOverview.
     
        - Parameter transactions: The transactions which should get fitered.
     */
    fileprivate func getTransactionsForCorrespondent(fromTransactions transactions: inout [Transaction]) {
        
        var correspondentTransactions: [Transaction] = [Transaction]()
        
        for transaction in transactions {
            
            switch transaction.type {
            case .transferTransaction:
                
                let transaction: TransferTransaction = transaction as! TransferTransaction
                
                // needed to decrypt messages where the current account was the sender.
                if transaction.message?.payload != nil {
                    transaction.message!.signer = correspondent?.accountPublicKey
                    transaction.message!.getMessageFromPayload()
                }
                
                if correspondent?.accountAddress != account?.address {
                    
                    if AccountManager.sharedInstance.generateAddress(forPublicKey: transaction.signer) == correspondent?.accountAddress && transaction.recipient == account!.address {
                        transaction.transferType = .incoming
                        correspondentTransactions.append(transaction)
                    } else if transaction.recipient == correspondent?.accountAddress && transaction.signer == account!.publicKey {
                        transaction.transferType = .outgoing
                        correspondentTransactions.append(transaction)
                    }
                    
                } else {
                    
                    if transaction.recipient == account?.address && transaction.recipient == AccountManager.sharedInstance.generateAddress(forPublicKey: transaction.signer) {
                        
                        transaction.transferType = .incoming
                        correspondentTransactions.append(transaction)
                    }
                }
                
            case .multisigTransaction:
                
                let multisigTransaction = transaction as! MultisigTransaction
                let transaction: TransferTransaction = multisigTransaction.innerTransaction as! TransferTransaction
                
                // needed to decrypt messages where the current account was the sender.
                if transaction.message?.payload != nil {
                    transaction.message!.signer = correspondent?.accountPublicKey
                    transaction.message!.getMessageFromPayload()
                }
                
                if correspondent?.accountAddress != account?.address {
                    
                    if AccountManager.sharedInstance.generateAddress(forPublicKey: transaction.signer) == correspondent?.accountAddress && transaction.recipient == account!.address {
                        transaction.transferType = .incoming
                        correspondentTransactions.append(multisigTransaction)
                    } else if transaction.recipient == correspondent?.accountAddress && transaction.signer == account!.publicKey {
                        transaction.transferType = .outgoing
                        correspondentTransactions.append(multisigTransaction)
                    }
                    
                } else {
                    
                    if transaction.recipient == account?.address && transaction.recipient == AccountManager.sharedInstance.generateAddress(forPublicKey: transaction.signer) {
                        
                        transaction.transferType = .incoming
                        correspondentTransactions.append(multisigTransaction)
                    }
                }

            default:
                break
            }
        }
        
        correspondentTransactions.sort(by: { $0.timeStamp < $1.timeStamp })
        
        transactions = correspondentTransactions
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
    
    /// Calculates the heights for all transaction table view cells.
    fileprivate func calculateCellHeights() {
        
        getCellHeights(forTransactions: transactions, withViewWidth: tableView.frame.width - 120)
        rowHeight.append(CGFloat())
        getCellHeights(forTransactions: unconfirmedTransactions, withViewWidth: tableView.frame.width - 120)
    }
    
    /**
        Calculates the height for all table view cells. The calculated heights get stored
        in the array rowHeight and will get applied to the cells.
     
        - Parameter transactions: The transactions for which the cell heights should get calculated.
        - Parameter width: The width of the table view.
     */
    fileprivate func getCellHeights(forTransactions transactions: [Transaction], withViewWidth width: CGFloat) {
        
        for transaction in transactions {
            
            var multisigTransaction: MultisigTransaction?
            var transferTransaction: TransferTransaction?
            
            switch transaction.type {
            case .transferTransaction:
                
                transferTransaction = transaction as! TransferTransaction
                
            case .multisigTransaction:
                
                multisigTransaction = transaction as! MultisigTransaction
                transferTransaction = multisigTransaction!.innerTransaction as! TransferTransaction
                
            default:
                break
            }
            
            var message = transferTransaction!.message?.message == String() || transferTransaction!.message?.message == nil ? "" : transferTransaction!.message?.message
            var amount = String()
            
            if (transferTransaction!.amount > 0) {
                
                var symbol = String()
                if transferTransaction!.transferType == .incoming {
                    symbol = "+"
                } else {
                    symbol = "-"
                }
                
                amount = "\(symbol)\((transferTransaction!.amount / 1000000).format()) XEM"
                
                if message != "" {
                    amount = "\n" + amount
                }
                
            } else {
                
                if message == "" {
                    message = "EMPTY_MESSAGE".localized()
                }
            }
            
            let messageAttributedString = NSMutableAttributedString(string: message!, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightRegular)])
            let amountAttributedString = NSMutableAttributedString(string: amount, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightRegular)])
            messageAttributedString.append(amountAttributedString)
            
            let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
            label.numberOfLines = 10
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.attributedText = messageAttributedString
            label.sizeToFit()
            
            rowHeight.append(label.frame.height + 50)
        }
    }
    
    /**
        Scrolls to the bottom of the table view.
     
        - Parameter animated: Bool whether the scrolling should get animated or not.
     */
    fileprivate func scrollToTableBottom(_ animated: Bool = false) {
        
        if tableView.contentSize.height > tableView.frame.size.height {
            let offset = CGPoint(x: 0, y: tableView.contentSize.height - tableView.frame.size.height)
            tableView.setContentOffset(offset, animated: animated)
        }
    }
    
    /// Copies the correspondent address to the pasteboard.
    func copyCorrespondentAddress(_ sender: AnyObject) {
        
        guard correspondent != nil else { return }
        
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = correspondent!.accountAddress
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

    // MARK: - View Controller Outlet Actions
    
    @IBAction func toggleEncryptionSetting(_ sender: UIButton) {
        
        willEncrypt = !willEncrypt
        sender.backgroundColor = (willEncrypt) ? UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1) : UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
    }
    
    @IBAction func didEndOnExit(_ sender: UITextField) {
        
        switch sender {
        case transactionAmountTextField:
            
            if Double(sender.text!) == nil {
                sender.text = "0"
            }
            
            transactionMessageTextField.becomeFirstResponder()
            
        case transactionMessageTextField:
            
            transactionMessageTextField.resignFirstResponder()
            
        default:
            break
        }
    }
    
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
                transactionSendButton.isEnabled = false
                view.addSubview(accountChooserViewController.view)
                
                UIView.animate(withDuration: 0.2, animations: {
                    accountChooserViewController.view.layer.opacity = 1
                })
            }
            
        } else {
            
            accountChooserViewController!.view.removeFromSuperview()
            accountChooserViewController!.removeFromParentViewController()
            accountChooserViewController = nil
            
            transactionSendButton.isEnabled = true
        }
    }
    
    @IBAction func createTransaction(_ sender: AnyObject) {
        
        guard transactionAmountTextField.text != nil else { return }
        guard transactionMessageTextField.text != nil else { return }
        if activeAccountData == nil { activeAccountData = accountData }
        
        transactionSendButton.isEnabled = false
        
        let transactionVersion = 1
        let transactionTimeStamp = Int(TimeManager.sharedInstance.currentNetworkTime)
        let transactionAmount = Double(transactionAmountTextField.text!) ?? 0.0
        var transactionFee = 0.0
        let transactionRecipient = correspondent!.accountAddress
        let transactionMessageText = transactionMessageTextField.text!.hexadecimalStringUsingEncoding(String.Encoding.utf8) ?? String()
        var transactionMessageByteArray: [UInt8] = transactionMessageText.asByteArray()
        let transactionDeadline = Int(TimeManager.sharedInstance.currentNetworkTime + Constants.transactionDeadline)
        let transactionSigner = activeAccountData!.publicKey
        
        if transactionAmount < 0.000001 && transactionAmount != 0 {
            transactionAmountTextField!.text = "0"
            transactionSendButton.isEnabled = true
            return
        }
        guard (activeAccountData!.balance / 1000000) > transactionAmount else {
            showAlert(withMessage: "ACCOUNT_NOT_ENOUGHT_MONEY".localized())
            transactionSendButton.isEnabled = true
            return
        }
        guard TransactionManager.sharedInstance.validateHexadecimalString(transactionMessageText) == true else {
            showAlert(withMessage: "NOT_A_HEX_STRING".localized())
            transactionSendButton.isEnabled = true
            return
        }
        
        if willEncrypt {
            guard let recipientPublicKey = correspondent?.accountPublicKey else {
                showAlert(withMessage: "NO_PUBLIC_KEY_FOR_ENC".localized())
                transactionSendButton.isEnabled = true
                return
            }
            
            var transactionEncryptedMessageByteArray: [UInt8] = Array(repeating: 0, count: 32)
            transactionEncryptedMessageByteArray = TransactionManager.sharedInstance.encryptMessage(transactionMessageByteArray, senderEncryptedPrivateKey: account!.privateKey, recipientPublicKey: recipientPublicKey)
            transactionMessageByteArray = transactionEncryptedMessageByteArray
        }
        
        if transactionMessageByteArray.count > 1024 {
            showAlert(withMessage: "VALIDAATION_MESSAGE_LEANGTH".localized())
            transactionSendButton.isEnabled = true
            return
        }
        
        transactionFee = TransactionManager.sharedInstance.calculateFee(forTransactionWithAmount: transactionAmount)
        transactionFee += TransactionManager.sharedInstance.calculateFee(forTransactionWithMessage: transactionMessageByteArray, isEncrypted: willEncrypt)
                
        let transactionMessage = Message(type: willEncrypt ? MessageType.encrypted : MessageType.unencrypted, payload: transactionMessageByteArray, message: transactionMessageTextField.text!)
        let transaction = TransferTransaction(version: transactionVersion, timeStamp: transactionTimeStamp, amount: transactionAmount * 1000000, fee: Int(transactionFee * 1000000), recipient: transactionRecipient!, message: transactionMessage, deadline: transactionDeadline, signer: transactionSigner!)
        
        let alert = UIAlertController(title: "INFO".localized(), message: "Are you sure you want to send this transaction to \(transactionRecipient!.nemAddressNormalised())?", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.destructive, handler: { [weak self] (action) -> Void in
            alert.dismiss(animated: true, completion: nil)
            
            if self != nil {
                
                // Check if the transaction is a multisig transaction
                if self!.activeAccountData!.publicKey != self!.account!.publicKey {
                    
                    let multisigTransaction = MultisigTransaction(version: transactionVersion, timeStamp: transactionTimeStamp, fee: Int(0.15 * 1000000), deadline: transactionDeadline, signer: self!.account!.publicKey, innerTransaction: transaction!)
                    
                    self?.announceTransaction(multisigTransaction!)
                    return
                }
                
                self?.announceTransaction(transaction!)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (action) in
            self?.transactionSendButton.isEnabled = true
            return
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Table View Delegate

extension TransactionMessagesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if unconfirmedTransactions.count > 0 {
            return transactions.count + unconfirmedTransactions.count + 1
        } else {
            return transactions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == transactions.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionMessageGroupSeparatorTableViewCell")!
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionMessageTableViewCell") as! TransactionMessageTableViewCell
        
        if indexPath.row < transactions.count {
            
            var multisigTransaction: MultisigTransaction?
            var transaction: TransferTransaction?
            
            switch transactions[indexPath.row].type {
            case .transferTransaction:
                
                transaction = transactions[indexPath.row] as! TransferTransaction
                
            case .multisigTransaction:
                
                multisigTransaction = transactions[indexPath.row] as! MultisigTransaction
                transaction = multisigTransaction!.innerTransaction as! TransferTransaction
                
            default:
                break
            }
            
            if transaction!.transferType == .incoming {
                cell.cellType = .incoming
            } else {
                cell.cellType = .outgoing
            }
            
            cell.transaction = transaction
            
            let detailBlockHeight = NSMutableAttributedString(string: "\("BLOCK".localized()): ", attributes: nil)
            detailBlockHeight.append(NSMutableAttributedString(string: "\(transaction!.metaData!.height!)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)]))
            let detailFee = NSMutableAttributedString(string: "\("FEE".localized()): ", attributes: nil)
            detailFee.append(NSMutableAttributedString(string: "\(Double(transaction!.fee) / Double(1000000))", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)]))
            
            cell.setDetails(detailBlockHeight, centerInformation: detailFee, bottomInformation: nil)
            
        } else {
            
            var multisigTransaction: MultisigTransaction?
            var transaction: TransferTransaction?
            
            switch unconfirmedTransactions[indexPath.row - transactions.count - 1].type {
            case .transferTransaction:
                
                transaction = unconfirmedTransactions[indexPath.row - transactions.count - 1] as! TransferTransaction
                
            case .multisigTransaction:
                
                multisigTransaction = unconfirmedTransactions[indexPath.row - transactions.count - 1] as! MultisigTransaction
                transaction = multisigTransaction!.innerTransaction as! TransferTransaction
                
            default:
                break
            }
            
            cell.cellType = .processing
            cell.transaction = transaction
            
            if multisigTransaction != nil {
                if correspondentAccountData != nil {
                    
                    let minCosignatories = multisigTransaction!.innerTransaction.signer == accountData!.publicKey ? ((accountData!.minCosignatories == 0 || accountData!.minCosignatories == accountData!.cosignatories.count) ? accountData!.cosignatories.count : accountData!.minCosignatories) : ((correspondentAccountData!.minCosignatories == 0 || correspondentAccountData!.minCosignatories == correspondentAccountData!.cosignatories.count) ? correspondentAccountData!.cosignatories.count : correspondentAccountData!.minCosignatories)
                    
                    let detailCosignatoriesSigned = NSMutableAttributedString(string: "\(multisigTransaction!.signatures!.count + 1)", attributes: [NSForegroundColorAttributeName: UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 10, weight: UIFontWeightBold)])
                    detailCosignatoriesSigned.append(NSMutableAttributedString(string: " \("OF".localized())", attributes: nil))
                    detailCosignatoriesSigned.append(NSMutableAttributedString(string: " \(multisigTransaction!.innerTransaction.signer == accountData!.publicKey ? accountData!.cosignatories.count : correspondentAccountData!.cosignatories.count) " , attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)]))
                    detailCosignatoriesSigned.append(NSMutableAttributedString(string: "SIGNERS".localized(), attributes: nil))
                    let detailMinCosignatories = NSMutableAttributedString(string: "\("MIN".localized()) ", attributes: nil)
                    detailMinCosignatories.append(NSMutableAttributedString(string: "\(minCosignatories!)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)]))
                    detailMinCosignatories.append(NSMutableAttributedString(string: " \("SIGNERS".localized())", attributes: nil))
                    let detailFee = NSMutableAttributedString(string: "\("FEE".localized()): ", attributes: nil)
                    detailFee.append(NSMutableAttributedString(string: "\(Double(transaction!.fee) / Double(1000000))", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)]))
                    
                    cell.setDetails(detailCosignatoriesSigned, centerInformation: detailMinCosignatories, bottomInformation: detailFee)
                    
                } else {
                    
                    let detailFee = NSMutableAttributedString(string: "\("FEE".localized()): ", attributes: nil)
                    detailFee.append(NSMutableAttributedString(string: "\(Double(transaction!.fee) / Double(1000000))", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)]))
                    
                    cell.setDetails(nil, centerInformation: detailFee, bottomInformation: nil)
                }
                
            } else {
                
                let detailFee = NSMutableAttributedString(string: "\("FEE".localized()): ", attributes: nil)
                detailFee.append(NSMutableAttributedString(string: "\(Double(transaction!.fee) / Double(1000000))", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)]))
                
                cell.setDetails(nil, centerInformation: detailFee, bottomInformation: nil)
            }
        }
        
        cell.detailDelegate = self
        cell.detailsIsShown = false
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == transactions.count {
            return 60.0
        }
        
        return rowHeight[indexPath.row]
    }
}

// MARK: - Detail Delegate

extension TransactionMessagesViewController: DetailedTableViewCellDelegate {
    
    func showDetailsForCell(_ cell: DetailedTableViewCell) {
        cell.detailsIsShown = true
    }
    
    func hideDetailsForCell(_ cell: DetailedTableViewCell) {
        cell.detailsIsShown = false
    }
}

// MARK: - Account Chooser Delegate

extension TransactionMessagesViewController: AccountChooserDelegate {
    
    func didChooseAccount(_ accountData: AccountData) {
        
        activeAccountData = accountData
        
        accountChooserViewController?.view.removeFromSuperview()
        accountChooserViewController?.removeFromParentViewController()
        accountChooserViewController = nil
        
        transactionSendButton.isEnabled = true
        transactionEncryptionButton.isEnabled = activeAccountData?.address == self.accountData?.address
        
        if activeAccountData?.address != self.accountData?.address {
            willEncrypt = false
            transactionEncryptionButton.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
        }
        
        updateInfoHeaderLabel(withAccountData: activeAccountData)
    }
}
