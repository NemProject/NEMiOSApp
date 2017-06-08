//
//  AccountDataModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/// The meta data for an account.
public struct AccountData: SwiftyJSONMappable {
    
    // MARK: - Model Properties
    
    /// The title of the account.
    public var title: String?
    
    /// The address of the account.
    public var address: String!
    
    /// The public key of the account.
    public var publicKey: String!
    
    /// The current balance of the account.
    public var balance: Double!
    
    /// The vested part of the balance of the account in micro NEM.
    public var vestedBalance: Double!
    
    /// The importance of the account.
    public var importance: Double!
    
    /// The number blocks that the account already harvested.
    public var harvestedBlocks: Int!
    
    /// All cosignatories of the account.
    public var cosignatories: [AccountData]!
    
    /// All accounts for which the account acts as a cosignatory.
    public var cosignatoryOf: [AccountData]!
    
    /// The minimum number of cosignatories that need to sign a transaction.
    public var minCosignatories: Int?
    
    /// The harvesting status of a queried account.
    public var status: String!
    
    /// The status of remote harvesting of a queried account.
    public var remoteStatus: String!
    
    // MARK: - Model Lifecycle
    
    public init?(jsonData: JSON) {
        
        if jsonData["meta"] == nil {
            address = jsonData["address"].stringValue
            publicKey = jsonData["publicKey"].stringValue
            balance = jsonData["balance"].doubleValue
            vestedBalance = jsonData["vestedBalance"].doubleValue
            importance = jsonData["importance"].doubleValue
            harvestedBlocks = jsonData["harvestedBlocks"].intValue
            cosignatories = [AccountData]()
            cosignatoryOf = [AccountData]()
            minCosignatories = nil
            status = String()
            remoteStatus = String()
        } else {
            address = jsonData["account"]["address"].stringValue
            publicKey = jsonData["account"]["publicKey"].stringValue
            balance = jsonData["account"]["balance"].doubleValue
            vestedBalance = jsonData["account"]["vestedBalance"].doubleValue
            importance = jsonData["account"]["importance"].doubleValue
            harvestedBlocks = jsonData["account"]["harvestedBlocks"].intValue
            cosignatories = try! jsonData["meta"]["cosignatories"].mapArray(AccountData.self)
            cosignatoryOf = try! jsonData["meta"]["cosignatoryOf"].mapArray(AccountData.self)
            minCosignatories = jsonData["account"]["multisigInfo"]["minCosignatories"].intValue
            status = jsonData["meta"]["status"].stringValue
            remoteStatus = jsonData["meta"]["remoteStatus"].stringValue
        }
    
        title = AccountManager.sharedInstance.titleForAccount(withAddress: address)
    }
}
