//
//  TransactionSendViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import Contacts
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
    The view controller that lets the user send transactions from
    the current account or the accounts the current account is a 
    cosignatory of.
 */
class TransactionSendViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - View Controller Properties
    
    var recipientAddress: String?
    var amount: Double?
    var userSetFee: Double?
    var message: String?
    fileprivate var account: Account?
    fileprivate var accountData: AccountData?
    fileprivate var activeAccountData: AccountData?
    fileprivate var willEncrypt = false
    fileprivate var accountChooserViewController: UIViewController?
    fileprivate var preparedTransaction: Transaction?
    fileprivate var sendingTransaction = false
    fileprivate var suggestions = [String: String]()
    fileprivate var contacts = [CNContact]()
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var customScrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var transactionAccountChooserButton: AccountChooserButton!
    @IBOutlet weak var transactionSenderHeadingLabel: UILabel!
    @IBOutlet weak var transactionSenderLabel: UILabel!
    @IBOutlet weak var transactionRecipientHeadingLabel: UILabel!
    @IBOutlet weak var transactionRecipientTextField: AutoCompleteTextField!
    @IBOutlet weak var transactionAmountHeadingLabel: UILabel!
    @IBOutlet weak var transactionAmountTextField: UITextField!
    @IBOutlet weak var transactionMessageHeadingLabel: UILabel!
    @IBOutlet weak var transactionMessageTextField: UITextField!
    @IBOutlet weak var transactionEncryptionButton: UIButton!
    @IBOutlet weak var transactionFeeHeadingLabel: UILabel!
    @IBOutlet weak var transactionFeeTextField: UITextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var transactionSendButton: UIBarButtonItem!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.delegate = self
        
        transactionSendButton.isEnabled = false
        transactionFeeTextField.isEnabled = Constants.activeNetwork == Constants.testNetwork ? true : false
        account = AccountManager.sharedInstance.activeAccount
        
        guard account != nil else {
            print("Critical: Account not available!")
            return
        }
        
        updateViewControllerAppearance()
        fetchAccountData(forAccount: account!)
                
        if recipientAddress != nil {
            transactionRecipientTextField.text = recipientAddress
        }
        if amount != nil {
            transactionAmountTextField.text = "\(amount!)"
        }
        if message != nil {
            transactionMessageTextField.text = message
        }
        
        calculateTransactionFee()
        handleTextFieldInterfaces()
        fetchContacts()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        viewTopConstraint.constant = self.navigationBar.frame.height
    }
    
    private func handleTextFieldInterfaces() {
        
        transactionRecipientTextField.onTextChange = { [weak self] text in
            if !text.isEmpty {
                self?.setSuggestions()
            }
        }
        
        transactionRecipientTextField.onSelect = { [weak self] text, indexpath in
            self?.transactionRecipientTextField.text = self?.suggestions[text]
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        customNavigationItem.title = "NEW_TRANSACTION".localized()
        transactionSenderHeadingLabel.text = "FROM".localized() + ":"
        transactionRecipientHeadingLabel.text = "TO".localized() + ":"
        transactionAmountHeadingLabel.text = "AMOUNT".localized() + ":"
        transactionMessageHeadingLabel.text = "MESSAGE".localized() + ":"
        transactionFeeHeadingLabel.text = "FEE".localized() + ":"
        transactionSendButton.title = "SEND".localized()
        transactionRecipientTextField.placeholder = "ENTER_ADDRESS".localized()
        transactionAmountTextField.placeholder = "ENTER_AMOUNT".localized()
        transactionMessageTextField.placeholder = "EMPTY_MESSAGE".localized()
        transactionFeeTextField.placeholder = "ENTER_FEE".localized()
        transactionAccountChooserButton.setImage(#imageLiteral(resourceName: "DropDown").imageWithColor(UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)), for: UIControlState())
        
        transactionRecipientTextField.autoCompleteTextFont = UIFont.systemFont(ofSize: 14)
        transactionRecipientTextField.autoCompleteCellHeight = 35.0
        transactionRecipientTextField.maximumAutoCompleteCount = 20
        transactionRecipientTextField.hidesWhenSelected = true
        transactionRecipientTextField.hidesWhenEmpty = true
        transactionRecipientTextField.enableAttributedText = false
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
        Updates the form with the fetched account details.
     
        - Parameter accountData: The account data with which the form should get updated.
     */
    fileprivate func updateForm(withAccountData accountData: AccountData, forMultisigAccount: Bool = false) {
        
        if accountData.cosignatoryOf.count > 0 || forMultisigAccount == true {
            transactionAccountChooserButton.isHidden = false
            transactionSenderLabel.isHidden = true
            transactionAccountChooserButton.setTitle(accountData.title ?? accountData.address, for: UIControlState())
        } else {
            transactionAccountChooserButton.isHidden = true
            transactionSenderLabel.isHidden = false
            transactionSenderLabel.text = accountData.title ?? accountData.address
        }

        let amountAttributedString = NSMutableAttributedString(string: "\("AMOUNT".localized()) (\("BALANCE".localized()): ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17, weight: UIFontWeightLight)])
        amountAttributedString.append(NSMutableAttributedString(string: "\((accountData.balance / 1000000).format())", attributes: [NSForegroundColorAttributeName: UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1), NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
        amountAttributedString.append(NSMutableAttributedString(string: " XEM):", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17, weight: UIFontWeightLight)]))
        transactionAmountHeadingLabel.attributedText = amountAttributedString
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
                    var accountData = try json.mapObject(AccountData.self)
                    
                    if accountData.publicKey == "" {
                        accountData.publicKey = account.publicKey
                    }
                    
                    DispatchQueue.main.async {
                        
                        self?.accountData = accountData
                        self?.updateForm(withAccountData: accountData)
                        
                        self?.transactionSendButton.isEnabled = true
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
        Fetches the account data (balance, cosignatories, etc.) for the account from the active NIS.
     
        - Parameter accountAddress: The address of the account for which the account data should get fetched.
     */
    fileprivate func fetchAccountData(forAccountWithAddress accountAddress: String) {
        
        NEMProvider.request(NEM.accountData(accountAddress: accountAddress)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    let accountData = try json.mapObject(AccountData.self)
                    
                    DispatchQueue.main.async {
                        
                        self?.finishPreparingTransaction(withRecipientPublicKey: accountData.publicKey)
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        self?.showAlert(withMessage: "TRANSACTION_ANOUNCE_FAILED".localized())
                        self?.sendingTransaction = false
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    
                    self?.showAlert(withMessage: "TRANSACTION_ANOUNCE_FAILED".localized())
                    self?.sendingTransaction = false
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
                        self?.calculateTransactionFee()
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
            
            self?.sendingTransaction = false
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
    
    /// Calculates the fee for the transaction and updates the transaction fee text field accordingly.
    fileprivate func calculateTransactionFee() {
        
        var transactionAmountString = transactionAmountTextField.text!.replacingOccurrences(of: " ", with: "")
        var transactionAmount = Double(transactionAmountString) ?? 0.0

        if transactionAmount < 0.000001 && transactionAmount != 0 {
            transactionAmountTextField.text = "0"
            transactionAmount = 0
        }

        var transactionFee = 0.0
        transactionFee = TransactionManager.sharedInstance.calculateFee(forTransactionWithAmount: transactionAmount)

        let transactionMessageByteArray = transactionMessageTextField.text!.hexadecimalStringUsingEncoding(String.Encoding.utf8)!.asByteArray()
        let transactionMessageLength = transactionMessageTextField.text!.hexadecimalStringUsingEncoding(String.Encoding.utf8)!.asByteArray().count
        if transactionMessageLength != 0 {
            transactionFee += TransactionManager.sharedInstance.calculateFee(forTransactionWithMessage: transactionMessageByteArray, isEncrypted: willEncrypt)
        }

        let transactionFeeAttributedString = NSMutableAttributedString(string: "\("FEE".localized()): (\("MIN".localized()) ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17, weight: UIFontWeightLight)])
        transactionFeeAttributedString.append(NSMutableAttributedString(string: "\(transactionFee)", attributes: [
            NSForegroundColorAttributeName: UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1),
            NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
        transactionFeeAttributedString.append(NSMutableAttributedString(string: " XEM)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17, weight: UIFontWeightLight)]))
        transactionFeeHeadingLabel.attributedText = transactionFeeAttributedString
        
        if userSetFee == nil || Constants.activeNetwork == Constants.mainNetwork {
            transactionFeeTextField.text = "\(transactionFee)"
        }
    }
    
    /**
        Finishes preparing the transaction and initiates the announcement of the final transaction.
     
        - Parameter recipientPublicKey: The public key of the transaction recipient.
     */
    fileprivate func finishPreparingTransaction(withRecipientPublicKey recipientPublicKey: String) {
        
        let transactionMessageText = transactionMessageTextField.text!.hexadecimalStringUsingEncoding(String.Encoding.utf8) ?? String()
        var transactionMessageByteArray: [UInt8] = transactionMessageText.asByteArray()
        
        if willEncrypt {
            var transactionEncryptedMessageByteArray: [UInt8] = Array(repeating: 0, count: 32)
            transactionEncryptedMessageByteArray = TransactionManager.sharedInstance.encryptMessage(transactionMessageByteArray, senderEncryptedPrivateKey: account!.privateKey, recipientPublicKey: recipientPublicKey)
            transactionMessageByteArray = transactionEncryptedMessageByteArray
        }
        
        let transactionMessage = Message(type: willEncrypt ? MessageType.encrypted : MessageType.unencrypted, payload: transactionMessageByteArray, message: transactionMessageTextField.text!)
        
        (preparedTransaction as! TransferTransaction).message = transactionMessage
        
        // Check if the transaction is a multisig transaction
        if activeAccountData!.publicKey != account!.publicKey {
            
            let multisigTransaction = MultisigTransaction(version: (preparedTransaction as! TransferTransaction).version, timeStamp: (preparedTransaction as! TransferTransaction).timeStamp, fee: Int(0.15 * 1000000), deadline: (preparedTransaction as! TransferTransaction).deadline, signer: account!.publicKey, innerTransaction: (preparedTransaction as! TransferTransaction))
            
            announceTransaction(multisigTransaction!)
            return
        }
        
        announceTransaction((preparedTransaction as! TransferTransaction))
    }
    
    /// Fetches all contacts and reloads the table view with the fetched content.
    fileprivate func fetchContacts() {
        
        AddressBookManager.sharedInstance.contacts { [weak self] (contacts) in
            self?.contacts = contacts
        }
    }
    
    /// Filters all contacts with an account address from the contacts.
    open func filterContacts() -> [String: String] {
        
        var filteredContacts = [String: String]()
        
        for contact in contacts {
            for emailAddress in contact.emailAddresses where emailAddress.label == "NEM" {
                filteredContacts["\(contact.givenName) \(contact.familyName)"] = emailAddress.value as String
            }
        }
        
        return filteredContacts
    }
    
    /// Sets all suggestions for the recipient text field.
    fileprivate func setSuggestions() {
        
        guard transactionRecipientTextField.text != nil else { return }
        
        let searchText = transactionRecipientTextField.text!.lowercased()
        var autoCompleteStrings = [String]()
        
        let accounts = AccountManager.sharedInstance.accounts()
        for account in accounts {
            suggestions[account.title] = account.address
        }
        
        let contacts = filterContacts()
        for contact in contacts {
            suggestions[contact.key] = contact.value
        }
        
        let filteredSuggestions = suggestions.filter {
            let fullName = "\($0.key) \($0.value)".lowercased()
            return fullName.contains(searchText)
        }
        
        for filteredSuggestion in filteredSuggestions {
            autoCompleteStrings.append(filteredSuggestion.key)
        }

        if autoCompleteStrings.count == 0 {
            transactionRecipientTextField.autoCompleteTableView?.isHidden = true
            transactionRecipientTextField.autoCompleteStrings = nil
        } else {
            transactionRecipientTextField.autoCompleteStrings = autoCompleteStrings
        }
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func chooseAccount(_ sender: UIButton) {
        
        if accountChooserViewController == nil {
            
            var accounts = accountData!.cosignatoryOf ?? []
            accounts.append(accountData!)
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let accountChooserViewController = mainStoryboard.instantiateViewController(withIdentifier: "AccountChooserViewController") as! AccountChooserViewController
            accountChooserViewController.view.frame = CGRect(x: contentView.frame.origin.x, y: customScrollView.frame.origin.y + 60, width: contentView.frame.width, height: contentView.frame.height - 60)
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
    
    @IBAction func toggleEncryptionSetting(_ sender: UIButton) {
        
        willEncrypt = !willEncrypt
        sender.backgroundColor = (willEncrypt) ? UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1) : UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
        calculateTransactionFee()
    }
    
    @IBAction func createTransaction(_ sender: UIBarButtonItem) {
        
        guard sendingTransaction == false else { return }
        
        guard transactionRecipientTextField.text != nil else { return }
        guard transactionAmountTextField.text != nil else { return }
        guard transactionMessageTextField.text != nil else { return }
        guard transactionFeeTextField.text != nil else { return }
        if activeAccountData == nil { activeAccountData = accountData }
        
        sendingTransaction = true
        
        let transactionVersion = 1
        let transactionTimeStamp = Int(TimeManager.sharedInstance.currentNetworkTime)
        let transactionAmount = Double(transactionAmountTextField.text!) ?? 0.0
        var transactionFee = Double(transactionFeeTextField.text!) ?? 0.0
        let transactionRecipient = transactionRecipientTextField.text!.replacingOccurrences(of: "-", with: "")
        let transactionMessageText = transactionMessageTextField.text!.hexadecimalStringUsingEncoding(String.Encoding.utf8) ?? String()
        let transactionMessageByteArray: [UInt8] = transactionMessageText.asByteArray()
        let transactionDeadline = Int(TimeManager.sharedInstance.currentNetworkTime + Constants.transactionDeadline)
        let transactionSigner = activeAccountData!.publicKey
        
        calculateTransactionFee()
        
        if transactionAmount < 0.000001 && transactionAmount != 0 {
            transactionAmountTextField!.text = "0"
            sendingTransaction = false
            return
        }
        if transactionFee < Double(transactionFeeTextField.text!) {
            transactionFee = Double(transactionFeeTextField.text!)!
        }
        guard TransactionManager.sharedInstance.validateAccountAddress(transactionRecipient) else {
            showAlert(withMessage: "ACCOUNT_ADDRESS_INVALID".localized())
            sendingTransaction = false
            return
        }
        guard (activeAccountData!.balance / 1000000) > transactionAmount else {
            showAlert(withMessage: "ACCOUNT_NOT_ENOUGHT_MONEY".localized())
            sendingTransaction = false
            return
        }
        guard TransactionManager.sharedInstance.validateHexadecimalString(transactionMessageText) == true else {
            showAlert(withMessage: "NOT_A_HEX_STRING".localized())
            sendingTransaction = false
            return
        }
        if willEncrypt {
            if transactionMessageByteArray.count > 976 {
                showAlert(withMessage: "VALIDAATION_MESSAGE_LEANGTH".localized())
                sendingTransaction = false
                return
            }
        } else {
            if transactionMessageByteArray.count > 1024 {
                showAlert(withMessage: "VALIDAATION_MESSAGE_LEANGTH".localized())
                sendingTransaction = false
                return
            }
        }
        
        let transaction = TransferTransaction(version: transactionVersion, timeStamp: transactionTimeStamp, amount: transactionAmount * 1000000, fee: Int(transactionFee * 1000000), recipient: transactionRecipient, message: nil, deadline: transactionDeadline, signer: transactionSigner!)

        let alert = UIAlertController(title: "INFO".localized(), message: "Are you sure you want to send this transaction to \(transactionRecipient.nemAddressNormalised())?", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.destructive, handler: { [weak self] (action) -> Void in
            alert.dismiss(animated: true, completion: nil)
            
            if self != nil {
                
                self!.preparedTransaction = transaction
                
                self?.fetchAccountData(forAccountWithAddress: transactionRecipient)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (action) in
            self?.sendingTransaction = false
            return
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        calculateTransactionFee()
    }
    
    @IBAction func userDefinedFee(_ sender: UITextField) {
        
        if Constants.activeNetwork == Constants.testNetwork {
            userSetFee = Double(transactionFeeTextField.text!) ?? nil
        }
    }
    
    @IBAction func textFieldReturnKeyToched(_ sender: UITextField) {
        
        switch sender {
        case transactionRecipientTextField:
            transactionAmountTextField.becomeFirstResponder()
        case transactionAmountTextField :
            transactionMessageTextField.becomeFirstResponder()
        case transactionMessageTextField :
            transactionFeeTextField.becomeFirstResponder()
        default :
            sender.becomeFirstResponder()
        }
        
        calculateTransactionFee()
    }
    
    @IBAction func textFieldEditingEnd(_ sender: UITextField) {
        calculateTransactionFee()
    }
    
    @IBAction func endTyping(_ sender: AutoCompleteTextField) {
        
        calculateTransactionFee()
        sender.becomeFirstResponder()
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Account Chooser Delegate

extension TransactionSendViewController: AccountChooserDelegate {
    
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
        
        updateForm(withAccountData: accountData, forMultisigAccount: true)
    }
}

// MARK: - Navigation Bar Delegate

extension TransactionSendViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
