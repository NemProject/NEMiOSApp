//
//  AccountTests.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import Quick
import Nimble
@testable import NEMWallet

final class AccountTests: QuickSpec {
    override func spec() {
        
        describe("account creation") {
            
            context("when generating a new account") {
                
                var accounts: [Account]!
                var generatedAccount: Account!
                var generatedAccountIndex: Array<Any>.Index!
                
                beforeSuite {
                    waitUntil { done in
                        AccountManager.sharedInstance.create(account: "Newly generated account", completion: { (result, createdAccount) in
                            
                            accounts = AccountManager.sharedInstance.accounts()
                            generatedAccount = createdAccount!
                            generatedAccountIndex = accounts.index(of: createdAccount!)!
                            
                            done()
                        })
                    }
                }
                
                it("saves the new account") {
                    expect(accounts).to(contain(generatedAccount))
                }
                
                it("sets the right title") {
                    expect(accounts[generatedAccountIndex].title).to(equal("Newly generated account"))
                }
                
                it("generates a valid account address") {
                    
                    let networkPrefix = Constants.activeNetwork == Constants.testNetwork ? "T" : "N"
                    expect(accounts[generatedAccountIndex].address).to(beginWith(networkPrefix))
                    expect(accounts[generatedAccountIndex].address.characters.count).to(equal(40))
                }
                
                it("generates a valid public and private key") {
                    /// A valid public key implies that the private key is also valid.
                    expect(AccountManager.sharedInstance.validateKey(accounts[generatedAccountIndex].publicKey)).to(beTruthy())
                }
                
                it("positions the account correctly") {
                    
                    let maxPosition = accounts.max { a, b in Int(a.position) < Int(b.position) }
                    expect(accounts[generatedAccountIndex].position).to(equal(maxPosition!.position))
                }
            }
            
            context("when importing an existing account") {
                
                var accounts: [Account]!
                var importedAccount: Account!
                var importedAccountIndex: Array<Any>.Index!
                
                beforeSuite {
                    waitUntil { done in
                        AccountManager.sharedInstance.create(account: "Newly imported account", withPrivateKey: "4846c7752fe1f4ce151224d2ca9b9d38411631cea1a3a87169b35e9058bc729a", completion: { (result, createdAccount) in
                            
                            accounts = AccountManager.sharedInstance.accounts()
                            importedAccount = createdAccount!
                            importedAccountIndex = accounts.index(of: createdAccount!)!
                            
                            done()
                        })
                    }
                }
                
                it("saves the existing account") {
                    expect(accounts).to(contain(importedAccount))
                }
                
                it("sets the right title") {
                    expect(accounts[importedAccountIndex].title).to(equal("Newly imported account"))
                }
                
                it("generates the valid account address") {
                    
                    let accountAddress = Constants.activeNetwork == Constants.testNetwork ? "TB2DA2KFAM4GE2JU4XIPRGO72KBRMJUYS7CUXGLD" : "NB2DA2KFAM4GE2JU4XIPRGO72KBRMJUYS7LHNEUB"
                    expect(accounts[importedAccountIndex].address).to(equal(accountAddress))
                }
                
                it("generates the valid public key") {
                    expect(accounts[importedAccountIndex].publicKey).to(equal("4e312ef765e2916e4012a5290ae24b3806bdcbffda9560250749789c7bd35b50"))
                }
                
                it("positions the account correctly") {
                    
                    let maxPosition = accounts.max { a, b in Int(a.position) < Int(b.position) }
                    expect(accounts[importedAccountIndex].position).to(equal(maxPosition!.position))
                }
            }
        }
        
        describe("account deletion") {
            
            var accounts: [Account]!
            var deletedAccount: Account!
            
            beforeSuite {
                
                accounts = AccountManager.sharedInstance.accounts()
                deletedAccount = accounts[Int(arc4random_uniform(UInt32(accounts.count)) + UInt32(0))]
                
                waitUntil { done in
                    AccountManager.sharedInstance.delete(account: deletedAccount, completion: { (result) in
                        accounts = AccountManager.sharedInstance.accounts()
                        done()
                    })
                }
            }
            
            it("deletes the account from the device") {
                expect(accounts).notTo(contain(deletedAccount))
            }
            
            it("updates the position of all remaining accounts") {
                
                let maxPosition = accounts.max { a, b in Int(a.position) < Int(b.position) }
                var positionIncrement = 0
                
                for account in accounts {
                    if Int(account.position) == positionIncrement && positionIncrement < (accounts.count - 1)  {
                        positionIncrement += 1
                    }
                }
                
                expect(positionIncrement).to(equal(Int(maxPosition!.position)))
            }
        }
        
        describe("account position move") {
            
            it("saves the position move") {
                
                var accounts: [Account]!
                accounts = AccountManager.sharedInstance.accounts()
                
                var movedAccounts = accounts!
                let movedAccount = movedAccounts[Int(arc4random_uniform(UInt32(movedAccounts.count)) + UInt32(0))]
                let movedAccountIndexBefore = movedAccounts.index(of: movedAccount)!
                let movedAccountIndexAfter = Int(arc4random_uniform(UInt32(accounts.count)) + UInt32(0))
                
                movedAccounts.remove(at: movedAccountIndexBefore)
                movedAccounts.insert(movedAccount, at: movedAccountIndexAfter)
                
                waitUntil { done in
                    
                    AccountManager.sharedInstance.updatePosition(ofAccounts: movedAccounts, completion: { (result) in
                        accounts = AccountManager.sharedInstance.accounts()
                        done()
                    })
                }
                
                expect(accounts.index(of: movedAccount)).to(equal(movedAccountIndexAfter))
            }
        }
    }
}
