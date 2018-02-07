//
//  DatabaseManager.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import CoreStore

/**
    The database manager singleton used to interact with the core data database.
    This manager is utilizing the CoreStore framework.
    Only use this manager to interact with the database.
 */
open class DatabaseManager: NSObject {
    
    // MARK: - Manager Properties
    
    /// The singleton for the database manager.
    open static let sharedInstance = DatabaseManager()
    
    /// The data stack that manages all available stores.
    open let dataStack = DataStack(xcodeModelName: "NEMWallet")
    
    // MARK: - Manager Lifecycle
    
    fileprivate override init() {
        super.init()
        synthesizeDatabaseManager()
    }
    
    // MARK: - Manager Helper Methods
    
    /// Synthesizes the database manager and adds all stores to the data stack.
    fileprivate func synthesizeDatabaseManager() {
        
        try! dataStack.addStorageAndWait(
            SQLiteStore(
                fileName: "NEMWallet.sqlite",
                localStorageOptions: .recreateStoreOnModelMismatch
            )
        )
    }
}
