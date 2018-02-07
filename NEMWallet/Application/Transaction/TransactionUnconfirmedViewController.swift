//
//  TransactionUnconfirmedViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import SwiftyJSON

/// The view controller that lets the user sign unconfirmed transactions.
class TransactionUnconfirmedViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    fileprivate var account: Account?
    fileprivate var unconfirmedTransactions = [Transaction]()
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.delegate = self
        
        account = AccountManager.sharedInstance.activeAccount
        
        guard account != nil else {
            print("Critical: Account not available!")
            return
        }
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        account = AccountManager.sharedInstance.activeAccount
        
        guard account != nil else {
            print("Critical: Account not available!")
            return
        }
        
        fetchUnconfirmedTransactions(forAccount: account!)
    }
    
    // MARK: - View Controller Helper Methods
    
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
        Fetches all unconfirmed transactions for the provided account.
     
        - Parameter account: The account for which all unconfirmed transaction should get fetched.
     */
    fileprivate func fetchUnconfirmedTransactions(forAccount account: Account) {
        
        unconfirmedTransactions = [Transaction]()
        
        NEMProvider.request(NEM.unconfirmedTransactions(accountAddress: account.address, server: nil)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    var unconfirmedTransactions = [Transaction]()
                    
                    for (_, subJson) in json["data"] {
                        
                        switch subJson["transaction"]["type"].intValue {
                        case TransactionType.multisigTransaction.rawValue:
                            
                            var foundSignature = false
                            
                            let multisigTransaction = try subJson.mapObject(MultisigTransaction.self)
                            
                            switch multisigTransaction.innerTransaction.type {
                            case .transferTransaction:
                                
                                let transferTransaction = multisigTransaction.innerTransaction as! TransferTransaction
                                
                                if transferTransaction.recipient == account.address || transferTransaction.signer == account.publicKey {
                                    foundSignature = true
                                }
                                
                            case .multisigAggregateModificationTransaction:
                                
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
                                unconfirmedTransactions.append(multisigTransaction)
                            }
                            
                        default:
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        self?.unconfirmedTransactions += unconfirmedTransactions
                        self?.tableView.reloadData()
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
        Shows details about the changes that will get performed
        when the user confirms the transaction.
     
        - Parameter index: The index of the transaction in the unconfirmed transactions array for which more details should get shown.
     */
    open func showChanges(forTransactionAtIndex index: Int) {
        
        let multisigAggregateModificationTransaction = (unconfirmedTransactions[index] as! MultisigTransaction).innerTransaction as! MultisigAggregateModificationTransaction
        
        var modificationsDescription = "\("ACCOUNT".localized()): "
        modificationsDescription += "\(AccountManager.sharedInstance.generateAddress(forPublicKey: multisigAggregateModificationTransaction.signer).accountTitle())\n"
        
        for modification in multisigAggregateModificationTransaction.modifications {
            let cosignatoryAccount = AccountManager.sharedInstance.generateAddress(forPublicKey: modification.cosignatoryAccount).accountTitle()
            
            if modification.modificationType == .addCosignatory {
                
                modificationsDescription += "\("ADD".localized()):\n"
                modificationsDescription += "\(cosignatoryAccount)\n"
                
            } else {
                
                modificationsDescription += "\("DELETE".localized()):\n"
                modificationsDescription += "\(cosignatoryAccount)\n"
            }
        }
        
        let changesAlert = UIAlertController(title: "INFO".localized(), message: modificationsDescription, preferredStyle: UIAlertControllerStyle.alert)
        
        let confirmAction = UIAlertAction(title: "OK".localized(), style: .default, handler: nil)
        changesAlert.addAction(confirmAction)
        
        present(changesAlert, animated: true, completion: nil)
    }
    
    /**
        Confirms and therefore signs the transaction with a multisig signature transaction
        that gets sent to the network.
     
        - Parameter index: The index of the transaction that should get signed.
     */
    open func confirmTransaction(atIndex index: Int) {
        
        let multisigTransaction = unconfirmedTransactions[index] as! MultisigTransaction

        switch multisigTransaction.innerTransaction.type {
        case .transferTransaction:

            let transferTransaction = multisigTransaction.innerTransaction as! TransferTransaction
            
            let transactionVersion = 1
            let transactionTimeStamp = Int(TimeManager.sharedInstance.currentNetworkTime)
            let transactionFee = Int(0.15 * 1000000)
            let transactionDeadline = Int(TimeManager.sharedInstance.currentNetworkTime + Constants.transactionDeadline)
            let transactionSigner = account!.publicKey
            let transactionHash = multisigTransaction.metaData!.data!
            let transactionMultisigAccountAddress = AccountManager.sharedInstance.generateAddress(forPublicKey: transferTransaction.signer)
            
            let multisigSignatureTransaction = MultisigSignatureTransaction(version: transactionVersion, timeStamp: transactionTimeStamp, fee: transactionFee, deadline: transactionDeadline, signer: transactionSigner, otherHash: transactionHash, otherAccount: transactionMultisigAccountAddress)

            announceTransaction(multisigSignatureTransaction!)

        case .multisigAggregateModificationTransaction:
            
            let multisigAggregateModificationTransaction = multisigTransaction.innerTransaction as! MultisigAggregateModificationTransaction
            
            let transactionVersion = 1
            let transactionTimeStamp = Int(TimeManager.sharedInstance.currentNetworkTime)
            let transactionFee = Int(0.15 * 1000000)
            let transactionDeadline = Int(TimeManager.sharedInstance.currentNetworkTime + Constants.transactionDeadline)
            let transactionSigner = account!.publicKey
            let transactionHash = multisigTransaction.metaData!.data!
            let transactionMultisigAccountAddress = AccountManager.sharedInstance.generateAddress(forPublicKey: multisigAggregateModificationTransaction.signer)
            
            let multisigSignatureTransaction = MultisigSignatureTransaction(version: transactionVersion, timeStamp: transactionTimeStamp, fee: transactionFee, deadline: transactionDeadline, signer: transactionSigner, otherHash: transactionHash, otherAccount: transactionMultisigAccountAddress)
            
            announceTransaction(multisigSignatureTransaction!)
            
        default :
            break
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
                        
                        let alert = UIAlertController(title: "INFO".localized(), message: "TRANSACTION_ANOUNCE_SUCCESS".localized(), preferredStyle: UIAlertControllerStyle.alert)
                        
                        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: { (action) -> Void in
                            alert.dismiss(animated: true, completion: nil)
                            
                            if self?.unconfirmedTransactions.count == 1 {
                                
                                self?.dismiss(animated: true, completion: nil)
                                
                            } else {
                                
                                if self != nil {
                                    self!.fetchUnconfirmedTransactions(forAccount: self!.account!)
                                }
                            }
                        }))
                        
                        self?.present(alert, animated: true, completion: nil)
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
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Table View Data Source

extension TransactionUnconfirmedViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return unconfirmedTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let multisigTransaction = unconfirmedTransactions[indexPath.row] as! MultisigTransaction
        
        switch multisigTransaction.innerTransaction.type {
        case TransactionType.transferTransaction:
            
            let transferTransaction = multisigTransaction.innerTransaction as! TransferTransaction
            let cell = tableView.dequeueReusableCell(withIdentifier: "UnconfirmedTransferTransactionTableViewCell") as! TransactionUnconfirmedTableViewCell
            cell.delegate = self
            cell.tag = indexPath.row
            cell.transferTransaction = transferTransaction
            
            return cell
            
        case TransactionType.multisigAggregateModificationTransaction:
            
            let multisigAggregateModificationTransaction = multisigTransaction.innerTransaction as! MultisigAggregateModificationTransaction
            let cell = tableView.dequeueReusableCell(withIdentifier: "UnconfirmedMultisigAggregateModificationTransactionTableViewCell") as! TransactionUnconfirmedTableViewCell
            cell.delegate = self
            cell.tag = indexPath.row
            cell.multisigAggregateModificationTransaction = multisigAggregateModificationTransaction
            
            return cell
            
        default :
            break
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 344.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }
}

// MARK: - Navigation Bar Delegate

extension TransactionUnconfirmedViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
