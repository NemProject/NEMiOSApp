//
//  NotificationManager.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import UIKit
import SwiftyJSON

/**
    The notification manager singleton used to perform all kinds of actions
    in relationship with notifications. Use this managers available methods
    instead of writing your own logic.
 */
final class NotificationManager {
    
    // MARK: - Manager Properties
    
    /// The singleton for the notification manager.
    static let sharedInstance = NotificationManager()
    
    /// The server with which new transactions get fetched.
    private var respondingServer: Server?
    
    /// The dispatch group for the server discovery.
    private let discoverRespondingServerDispatchGroup = DispatchGroup()
    
    /// The dispatch group for fetching new transactions.
    private let fetchNewTransactionsDispatchGroup = DispatchGroup()
    
    // MARK: - Manager Lifecycle
    
    private init() {} // Prevents others from creating own instances of this manager and not using the singleton.
    
    // MARK: - Public Manager Methods
    
    /**
        Registers the application to receive notifications.
        This method has to be called on application launch to enable notifications.
     */
    public func registerForNotifications() {
        
        let application = UIApplication.shared
        let userNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        
        application.registerUserNotificationSettings(userNotificationSettings)
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        clearApplicationIconBadge()
    }
    
    /**
        Fetches new transactions for every acccount on the device and notifies the user about those new transactions
        via a local notification. This polling happens on background fetch because remote notifications aren't an
        option because of decentralization.
     
        - Parameter backgroundFetchCompletionHandler: The completion handler of the background fetch, which needs to get called when the process finishes.
     */
    public func notifyAboutNewTransactions(withCompletionHandler backgroundFetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        fetchNewTransactionsDispatchGroup.enter()
        discoverRespondingServer()
        
        discoverRespondingServerDispatchGroup.notify(queue: .main) {
            
            if self.respondingServer == nil {
                
                self.displayNotification(withTitle: "", andBody: "NO_PRIMARY_SERVER".localized())
                return backgroundFetchCompletionHandler(.failed)
                
            } else {
                self.fetchNewTransactions()
            }
        }
        
        fetchNewTransactionsDispatchGroup.notify(queue: .main) {
            return backgroundFetchCompletionHandler(.newData)
        }
    }
    
    /// Clears the application icon badge.
    public func clearApplicationIconBadge() {
        
        let application = UIApplication.shared
        application.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Private Manager Methods
    
    /**
        Displays a local notification to the user with a given title and body.
     
        - Parameter title: The title of the notification.
        - Parameter body: The body of the notification.
     */
    private func displayNotification(withTitle title: String, andBody body: String) {
        
        let application = UIApplication.shared
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = Date(timeIntervalSinceNow: 1)
        localNotification.timeZone = TimeZone.current
        localNotification.applicationIconBadgeNumber = application.applicationIconBadgeNumber + 1
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.alertTitle = title
        localNotification.alertBody = body
        
        application.scheduleLocalNotification(localNotification)
    }
    
    /**
        Goes through all locally saved servers, requests a heartbeat response from them and selects a
        responding server to look for new transactions later on. Stores the discovered responding server
        in the 'respondingServer' property.
     */
    private func discoverRespondingServer() {
        
        let servers = SettingsManager.sharedInstance.servers()
        
        for server in servers {
            getHeartbeatResponse(fromServer: server, completion: { [unowned self] (result) in
                
                switch result {
                case .success:
                    
                    if self.respondingServer == nil {
                        self.respondingServer = server
                    }
                    
                default:
                    break
                }
                
                self.discoverRespondingServerDispatchGroup.leave()
            })
        }
    }
    
    /**
        Sends a heartbeat request to the selected server to see if the server responds and is a valid NIS.
     
        - Parameter server: The server that should get checked.
     
        - Returns: The result of the operation.
     */
    private func getHeartbeatResponse(fromServer server: Server, completion: @escaping (_ result: Result) -> Void) {
        
        discoverRespondingServerDispatchGroup.enter()
        
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
    
    /**
        Fetches new transactions for all accounts on the device, counts them and displays a local 
        notification accordingly.
     */
    private func fetchNewTransactions() {
        
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
                    
                    self.displayNotification(withTitle: "", andBody: String(format: "NOTIFICATION_MESSAGE".localized(), newTransactionsCount, account.title))
                    
                    if let latestTransaction = transactions.first as? TransferTransaction {
                        if latestTransaction.metaData != nil && latestTransaction.metaData?.hash != nil {
                            AccountManager.sharedInstance.updateLatestTransactionHash(forAccount: account, withLatestTransactionHash: latestTransaction.metaData!.hash!)
                        }
                        
                    } else if let latestTransaction = transactions.first as? MultisigAggregateModificationTransaction {
                        if latestTransaction.metaData != nil && latestTransaction.metaData?.hash != nil {
                            AccountManager.sharedInstance.updateLatestTransactionHash(forAccount: account, withLatestTransactionHash: latestTransaction.metaData!.hash!)
                        }
                    }
                }
                
                self.fetchNewTransactionsDispatchGroup.leave()
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
                    self.displayNotification(withTitle: "", andBody: "\(account.title): \("UNCONFIRMED_TRANSACTIONS_DETECTED".localized())")
                }
                
                self.fetchNewTransactionsDispatchGroup.leave()
            })
        }
        
        fetchNewTransactionsDispatchGroup.leave()
    }
    
    /**
        Fetches the last 25 transactions for the account from the specified server.
     
        - Parameter account: The account for which transactions should get fetched.
     */
    private func fetchAllTransactions(forAccount account: Account, completion: @escaping (_ result: Result, _ transactions: [Transaction]) -> Void) {
        
        fetchNewTransactionsDispatchGroup.enter()
        
        NEMProvider.request(NEM.confirmedTransactions(accountAddress: account.address, server: self.respondingServer)) { (result) in
            
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
        Fetches all unconfirmed transactions for the account from the specified server.
     
        - Parameter account: The account for which unconfirmed transactions should get fetched.
     */
    private func fetchUnconfirmedTransactions(forAccount account: Account, completion: @escaping (_ result: Result, _ unconfirmedTransactions: [Transaction]) -> Void) {
        
        fetchNewTransactionsDispatchGroup.enter()
        
        NEMProvider.request(NEM.unconfirmedTransactions(accountAddress: account.address, server: self.respondingServer)) { (result) in
            
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
