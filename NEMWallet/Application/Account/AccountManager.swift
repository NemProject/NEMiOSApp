//
//  AccountManager.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import Foundation
import CoreStore
import CryptoSwift

/**
    The account manager singleton used to perform all kinds of actions in relationship with an account. 
    Use this managers available methods instead of writing your own logic.
 */
final class AccountManager {
    
    // MARK: - Manager Properties
    
    /// The singleton for the account manager.
    static let sharedInstance = AccountManager()
    
    /// The currently active account.
    public var activeAccount: Account?
    
    // MARK: - Manager Lifecycle
    
    private init() {} // Prevents others from creating own instances of this manager and not using the singleton.
    
    // MARK: - Public Manager Methods
    
    /**
        All accounts that are stored on the device.
     
        - Returns: An array of accounts ordered by the user defined position (ascending).
     */
    public func accounts() -> [Account] {
        
        let accounts = DatabaseManager.sharedInstance.dataStack.fetchAll(From(Account.self), OrderBy(.ascending("position"))) ?? []
        return accounts
    }
    
    /**
        Creates a new account and stores it on the device.
        You can later fetch stored accounts with the 'accounts' method.
     
        - Parameter title: The title/name of the new account.
        - Parameter privateKey: The private key of the account (optional). If no private key is provided, a new one will be generated.
     
        - Returns: The result of the operation - success or failure as well as the newly created account.
     */
    public func create(account title: String, withPrivateKey privateKey: String? = AccountManager.sharedInstance.generatePrivateKey(), completion: @escaping (_ result: Result, _ account: Account?) -> Void) {

        
        DatabaseManager.sharedInstance.dataStack.perform(
            asynchronous: { (transaction) -> Account in
                
                let account = transaction.create(Into(Account.self))
                account.title = title
                account.publicKey = self.generatePublicKey(fromPrivateKey: privateKey!)
                account.privateKey = self.encryptPrivateKey(privateKey!)
                account.address = self.generateAddress(forPublicKey: account.publicKey)
                account.position = self.positionForNewAccount() as NSNumber
                
                return account
            },
            success: { (accountTransaction) in
                
                let account = DatabaseManager.sharedInstance.dataStack.fetchExisting(accountTransaction)!
                return completion(.success, account)
            },
            failure: { (error) in
                return completion(.failure, nil)
            }
        )
    }
    
    /**
        Deletes the provided account from the device.
        
        - Parameter account: The account that should get deleted.
     
        - Returns: The result of the operation.
     */
    public func delete(account: Account, completion: @escaping (_ result: Result) -> Void) {
        
        var accounts = self.accounts()
        accounts.remove(at: Int(account.position))
        
        DatabaseManager.sharedInstance.dataStack.perform(
            asynchronous: { (transaction) -> Void in
            
                transaction.delete(account)
            },
            success: {
                
                /// Update the position of all other accounts accordingly.
                self.updatePosition(ofAccounts: accounts, completion: { (result) in return completion(.success) })
            },
            failure: { (error) in
                return completion(.failure)
            }
        )
    }
    
    /**
        Updates the position of all accounts in the account list.
        Account positions will get updated in the database according to the positions of the accounts in the provided 'accounts' array.
     
        - Parameter accounts: An array containing all accounts where their new position in the account list is already represented.
     
        - Returns: The result of the operation.
     */
    public func updatePosition(ofAccounts accounts: [Account], completion: @escaping (_ result: Result) -> Void) {
        
        DatabaseManager.sharedInstance.dataStack.perform(
            asynchronous: { (transaction) -> Void in
            
                for account in accounts {
                    let editableAccount = transaction.edit(account)!
                    editableAccount.position = accounts.index(of: account)! as NSNumber
                }
            },
            success: {
                return completion(.success)
            },
            failure: { (error) in
                return completion(.failure)
            }
        )
    }
    
    /**
        Updates the encrypted private key for an account after the application
        password has changed.
     
        - Parameter account: The account for which the encrypted private key should get updated.
        - Parameter privateKey: The new encrypted private key with which the existing one should get updated.
     */
    public func updatePrivateKey(forAccount account: Account, withNewPrivateKey privateKey: String) {
        
        DatabaseManager.sharedInstance.dataStack.perform(
            asynchronous: { (transaction) -> Void in
            
                let editableAccount = transaction.edit(account)!
                editableAccount.privateKey = privateKey
            },
            completion: { _ in }
        )
    }
    
    /**
        Updates the latest transaction hash for an account.
     
        - Parameter account: The account for which the latest transaction hash should get updated.
        - Parameter latestTransactionHash: The latest transaction hash with which the existing one should get updated.
     */
    public func updateLatestTransactionHash(forAccount account: Account, withLatestTransactionHash latestTransactionHash: String) {
        
        DatabaseManager.sharedInstance.dataStack.perform(
            asynchronous: { (transaction) -> Void in
            
                let editableAccount = transaction.edit(account)!
                editableAccount.latestTransactionHash = latestTransactionHash
            },
            completion: { _ in }
        )
    }
    
    /**
        Updates the saved title/name for an account in the database.
     
        - Parameter account: The existing account that should get updated.
        - Parameter title: The new title for the account that should get updated.
     */
    public func updateTitle(forAccount account: Account, withNewTitle title: String) {
        
        DatabaseManager.sharedInstance.dataStack.perform(
            asynchronous: { (transaction) -> Void in
            
                let editableAccount = transaction.edit(account)!
                editableAccount.title = title
            },
            completion: { _ in }
        )
    }
    
    /**
        Searches for the title of an account with the provided account
        address. The account with the provided account address could already
        be present in the app or saved inside the address book.
     
        - Parameter accountAddress: The account address for which the account title should get fetched.
     
        - Returns: The title of the account with the provided account address. If no title was found the method will return nil.
     */
    public func titleForAccount(withAddress accountAddress: String) -> String? {
        
        let accountAddress = accountAddress.replacingOccurrences(of: "-", with: "")
        
        let accounts = self.accounts()
        
        for account in accounts where account.address == accountAddress {
            return account.title
        }
        
        return nil
    }
    
    /**
        Validates if an account with the provided private key already
        got added to the application or not.
     
        - Parameter privateKey: The private key of the account that should get checked for existence.
     
        - Throws:
            - AccountImportValidation.AccountAlreadyPresent if an account with the provided private key already got added to the application.
     
        - Returns: A bool indicating that no account with the provided private key was added to the application.
     */
    public func validateAccountExistence(forAccountWithPrivateKey privateKey: String) throws -> Bool {
        
        let accounts = self.accounts()
        
        for account in accounts {
            let accountPrivateKey = decryptPrivateKey(encryptedPrivateKey: account.privateKey)
            if privateKey == accountPrivateKey {
                throw AccountImportValidation.accountAlreadyPresent(accountTitle: account.title)
            }
        }
        
        return true
    }
    
    /**
        Validates a provided key (private key or public key) and checks
        if the key is made up of valid characters.
     
        - Parameter key: The key that shoud get validated.
        - Parameter length: The lenght of the key - will use the default length of 64 characters if this parameter isn't provided.
     
        - Returns: A bool indicating whether the key is valid or not.
     */
    public func validateKey(_ key: String, length: Int = 64) -> Bool {

        let validator = Array<UInt8>("0123456789abcdef".utf8)
        var keyArray = Array<UInt8>(key.utf8)
        
        if keyArray.count == length || keyArray.count == length + 2 {
            if keyArray.count == length + 2 {
                keyArray.remove(at: 0)
                keyArray.remove(at: 0)
            }
            
            for value in keyArray {
                var find = false
                for valueChecker in validator where valueChecker == value {
                    find = true
                    break
                }
                
                if !find {
                    return false
                }
            }
            
        } else {
            return false
        }
        
        return true
    }
    
    /**
        Generates the address for the provided public key.
     
        - Parameter publicKey: The public key for which the address should get generated.
     
        - Returns: The generated address as a string.
     */
    public func generateAddress(forPublicKey publicKey: String) -> String {
        
        var inBuffer = publicKey.asByteArray()
        var stepOneSHA256: Array<UInt8> = Array(repeating: 0, count: 64)
        
        SHA256_hash(&stepOneSHA256, &inBuffer, 32)
        
        let stepOneSHA256Text = NSString(bytes: stepOneSHA256, length: stepOneSHA256.count, encoding: String.Encoding.utf8.rawValue) as! String
        let stepTwoRIPEMD160Text = RIPEMD.hexStringDigest(stepOneSHA256Text) as String
        let stepTwoRIPEMD160Buffer = stepTwoRIPEMD160Text.asByteArray()
        
        var version = Array<UInt8>()
        version.append(Constants.activeNetwork)
        
        var stepThreeVersionPrefixedRipemd160Buffer = version + stepTwoRIPEMD160Buffer
        var checksumHash: Array<UInt8> = Array(repeating: 0, count: 64)
        
        SHA256_hash(&checksumHash, &stepThreeVersionPrefixedRipemd160Buffer, 21)
        
        let checksumText = NSString(bytes: checksumHash, length: checksumHash.count, encoding: String.Encoding.utf8.rawValue) as! String
        var checksumBuffer = checksumText.asByteArray()
        var checksum = Array<UInt8>()
        checksum.append(checksumBuffer[0])
        checksum.append(checksumBuffer[1])
        checksum.append(checksumBuffer[2])
        checksum.append(checksumBuffer[3])
        
        let stepFourResultBuffer = stepThreeVersionPrefixedRipemd160Buffer + checksum
        let address = Base32Encode(Data(bytes: stepFourResultBuffer, count: stepFourResultBuffer.count))
        
        return address
    }
    
    /**
        Generates the address for the provided private key.
     
        - Parameter privateKey: The private key for which the address should get generated.
     
        - Returns: The generated address as a string.
     */
    public func generateAddress(forPrivateKey privateKey: String) -> String {
        
        let publicKey = generatePublicKey(fromPrivateKey: privateKey)
        return generateAddress(forPublicKey: publicKey)
    }
    
    /**
        Encrypts the provided private key with the application password.
     
        - Parameter privateKey: The private key that should get encrypted.
        - Parameter applicationPassword: (optional) The application password with which the private key should get encrypted.
     
        - Returns: The encrypted private key as a string.
     */
    public func encryptPrivateKey(_ privateKey: String, withApplicationPassword applicationPassword: String? = nil) -> String {
        
        let defaultApplicationPassword = SettingsManager.sharedInstance.applicationPassword()
        let encryptedPrivateKey = HashManager.AES256Encrypt(inputText: privateKey, key: applicationPassword != nil ? applicationPassword! : defaultApplicationPassword)
        
        return encryptedPrivateKey
    }
    
    /**
        Decrypts the provided encrypted private key with the application password.
     
        - Parameter encryptedPrivateKey: The encrypted private key that should get decrypted.
     
        - Returns: The decrypted private key as a string.
     */
    public func decryptPrivateKey(encryptedPrivateKey: String) -> String {
        
        let applicationPassword = SettingsManager.sharedInstance.applicationPassword()
        let privateKey = HashManager.AES256Decrypt(inputText: encryptedPrivateKey, key: applicationPassword)
        
        return privateKey!
    }
    
    // MARK: - Private Manager Methods
    
    /**
        Determines the position for a new account.
     
        - Returns: The position for a new account in the account list as an integer.
     */
    private func positionForNewAccount() -> Int {
        
        if let maxPosition = DatabaseManager.sharedInstance.dataStack.queryValue(From(Account.self), Select<Int>(.maximum(#keyPath(Account.position)))) {
            if (maxPosition == 0) {
                return maxPosition
            } else {
                return maxPosition + 1
            }
        } else {
            return 0
        }
    }
    
    /// Generates a new and unique private key.
    private func generatePrivateKey() -> String {
        
        var privateKeyBytes: Array<UInt8> = Array(repeating: 0, count: 32)
        createPrivateKey(&privateKeyBytes)
        
        let privateKey = Data(bytes: privateKeyBytes).toHexadecimalString()

        return privateKey.nemKeyNormalized()!
    }
    
    /**
        Generates the public key from the provided private key.
     
        - Parameter privateKey: The private key for which the public key should get generated.
     
        - Returns: The generated public key as a hex string.
     */
    private func generatePublicKey(fromPrivateKey privateKey: String) -> String {
        
        var publicKeyBytes: Array<UInt8> = Array(repeating: 0, count: 32)
        var privateKeyBytes: Array<UInt8> = privateKey.asByteArrayEndian(privateKey.asByteArray().count)
        createPublicKey(&publicKeyBytes, &privateKeyBytes)
        
        let publicKey = Data(bytes: publicKeyBytes).toHexadecimalString()
        
        return publicKey.nemKeyNormalized()!
    }
}
