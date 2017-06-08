//
//  NotificationManager.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import SwiftyJSON

/**
    The notification manager singleton used to perform all kinds of actions
    in relationship with notifications. Use this managers available methods
    instead of writing your own logic.
 */
open class NotificationManager {
    
    // MARK: - Manager Properties
    
    /// The singleton for the notification manager.
    open static let sharedInstance = NotificationManager()
    
    /// The completion handler that need to get called to finish the background fetch.
    fileprivate var completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil
    
    /// The server with which the networking requests will get performed.
    fileprivate var server: Server?
    
    fileprivate let heartbeatDispatchGroup = DispatchGroup()
    fileprivate let transactionsDispatchGroup = DispatchGroup()
    
    // MARK: - Public Manager Methods
    
    open func registerForNotifications(_ application: UIApplication) {
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let userNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(userNotificationSettings)
    }
    
    open func didReceiveLocalNotificaton(_ notification: UILocalNotification) {
        
        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
    }
    
    open func scheduleLocalNotificationAfter(_ title: String, body: String, interval: Double, userInfo: [AnyHashable: Any]?) {
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = Date(timeIntervalSinceNow: interval)
        localNotification.timeZone = TimeZone.current
        localNotification.alertTitle = title
        localNotification.alertBody = body
        localNotification.userInfo = userInfo
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }

    open func performFetch(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        self.completionHandler = completionHandler
        
        let servers = SettingsManager.sharedInstance.servers()
        
        for server in servers {
            getHeartbeatResponse(fromServer: server, completion: { [unowned self] (result) in
                
                switch result {
                case .success:
                    
                    if self.server == nil {
                        self.server = server
                    }
                    
                default:
                    break
                }
                
                self.heartbeatDispatchGroup.leave()
            })
        }
        
        heartbeatDispatchGroup.notify(queue: .main) {
            
            if self.server == nil {
                
                self.scheduleLocalNotificationAfter("", body: "NO_PRIMARY_SERVER".localized(), interval: 1, userInfo: nil)
                self.completionHandler?(.failed)
    
            } else {
                self.fetchNewTransactions()
            }
        }
    }

    open func fetchNewTransactions() {
        
        let accounts = AccountManager.sharedInstance.accounts()
        
        for account in accounts {
            fetchAllTransactions(forAccount: account, completion: { [unowned self] (result, transactions) in
                
                var newTransactionsCount = 0
                
                for transaction in transactions {
                    if transaction.type == TransactionType.transferTransaction {
                        
                        if (transaction as! TransferTransaction).metaData?.hash == account.latestTransactionHash {
                            break
                        }
                        
                    } else if transaction.type == TransactionType.multisigAggregateModificationTransaction {
                        
                        if (transaction as! MultisigAggregateModificationTransaction).metaData?.hash == account.latestTransactionHash {
                            break
                        }
                    }
                    
                    newTransactionsCount += 1
                }
                
                if newTransactionsCount > 0 {
                    self.scheduleLocalNotificationAfter("", body: String(format: "NOTIFICATION_MESSAGE".localized(), newTransactionsCount, account.title), interval: 1, userInfo: nil)
                    
                    let firstTransaction = transactions.first as! TransferTransaction
                    
                    if firstTransaction.metaData != nil && firstTransaction.metaData?.hash != nil {
                        AccountManager.sharedInstance.updateLatestTransactionHash(forAccount: account, withLatestTransactionHash: firstTransaction.metaData!.hash!)
                    }
                }
                
                self.transactionsDispatchGroup.leave()
            })
            
            fetchUnconfirmedTransactions(forAccount: account, completion: { [unowned self] (result, unconfirmedTransactions) in
                
                var unsignedTransactionsCount = 0
                
                for transaction in unconfirmedTransactions {
                    
                    switch transaction.type {
                    case .multisigTransaction:
                        
                        var foundSignature = false
                        
                        let multisigTransaction = transaction as! MultisigTransaction
                        
                        switch multisigTransaction.innerTransaction.type {
                        case TransactionType.transferTransaction:
                            
                            let transferTransaction = multisigTransaction.innerTransaction as! TransferTransaction
                            
                            if transferTransaction.recipient == account.address || transferTransaction.signer == account.publicKey {
                                foundSignature = true
                            }
                            
                        case TransactionType.multisigAggregateModificationTransaction:
                            
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
                            unsignedTransactionsCount += 1
                        }
                        
                    default:
                        break
                    }
                }
                
                if unsignedTransactionsCount > 0 {
                    self.scheduleLocalNotificationAfter("", body: "\(account.title): \("UNCONFIRMED_TRANSACTIONS_DETECTED".localized())", interval: 1, userInfo: nil)
                }
                
                self.transactionsDispatchGroup.leave()
            })
        }
        
        transactionsDispatchGroup.notify(queue: .main) {
            
            self.completionHandler?(.newData)
        }
    }
    
    // MARK: - Private Manager Methods
    
    /**
        Sends a heartbeat request to the selected server to see if the server is a valid NIS.
     
        - Parameter server: The server that should get checked.
     
        - Returns: The result of the operation.
     */
    fileprivate func getHeartbeatResponse(fromServer server: Server, completion: @escaping (_ result: Result) -> Void) {
        
        heartbeatDispatchGroup.enter()
        
        nisProvider.request(NIS.heartbeat(server: server)) { (result) in
            
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
    
    /**
        Fetches the last 25 transactions for the current account from the active NIS.
     
        - Parameter account: The current account for which the transactions should get fetched.
     */
    fileprivate func fetchAllTransactions(forAccount account: Account, completion: @escaping (_ result: Result, _ transactions: [Transaction]) -> Void) {
        
        transactionsDispatchGroup.enter()
        
        nisProvider.request(NIS.allTransactions(accountAddress: account.address, server: self.server)) { (result) in
            
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
                            
                            let multisigTransaction = try subJson.mapObject(MultisigTransaction.self)
                            
                            switch subJson["transaction"]["otherTrans"]["type"].intValue {
                            case TransactionType.transferTransaction.rawValue:
                                
                                let transferTransaction = multisigTransaction.innerTransaction as! TransferTransaction
                                allTransactions.append(transferTransaction)
                                
                            case TransactionType.multisigAggregateModificationTransaction.rawValue:
                                
                                let multisigAggregateModificationTransaction = multisigTransaction.innerTransaction as! MultisigAggregateModificationTransaction
                                allTransactions.append(multisigAggregateModificationTransaction)
                                
                            default:
                                break
                            }
                            
                        default:
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        return completion(.success, allTransactions)
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        return completion(.failure, [Transaction]())
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    
                    return completion(.failure, [Transaction]())
                }
            }
        }
    }
    
    /**
        Fetches all unconfirmed transactions for the current account from the active NIS.
     
        - Parameter account: The current account for which the unconfirmed transactions should get fetched.
     */
    fileprivate func fetchUnconfirmedTransactions(forAccount account: Account, completion: @escaping (_ result: Result, _ unconfirmedTransactions: [Transaction]) -> Void) {
        
        transactionsDispatchGroup.enter()
        
        nisProvider.request(NIS.unconfirmedTransactions(accountAddress: account.address, server: self.server)) { (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    var allTransactions = [Transaction]()
                    
                    for (_, subJson) in json["data"] {
                        
                        switch subJson["transaction"]["type"].intValue {
                        case TransactionType.multisigTransaction.rawValue:
                            
                            let multisigTransaction = try subJson.mapObject(MultisigTransaction.self)
                            
                            allTransactions.append(multisigTransaction)
                            
                        default:
                            break
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        return completion(.success, allTransactions)
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        return completion(.failure, [Transaction]())
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    
                    return completion(.failure, [Transaction]())
                }
            }
        }
    }
}
