//
//  HarvestingViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import SwiftyJSON

/// The harvesting view controller that shows infos about harvesting for the current account.
class HarvestingViewController: UIViewController {
    
    // MARK: - View Controller Properties
    
    fileprivate var account: Account?
    fileprivate var accountData: AccountData?
    fileprivate var harvestedBlocks = [Block]()
    
    fileprivate let harvestingDispatchGroup = DispatchGroup()
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var harvestingInfoView: UIView!
    @IBOutlet weak var accountImportanceLabel: UILabel!
    @IBOutlet weak var accountBalanceLabel: UILabel!
    @IBOutlet weak var accountVestedBalanceLabel: UILabel!
    @IBOutlet weak var accountHarvestingStatusLabel: UILabel!
    @IBOutlet weak var accountHarvestedBlocksLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
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
        updateViewControllerAppearance()
        refreshHarvestingInfo()
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "HARVEST_DETAILS".localized()
        
        harvestingInfoView.clipsToBounds = true
        harvestingInfoView.isHidden = true
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
    
    /**
        Updates the harvesting info table view in an asynchronous manner.
        Fires off all necessary network calls to get the information needed.
        Use only this method to update the displayed information.
     */
    func refreshHarvestingInfo() {
        
        fetchHarvestInfoData(forAccount: account!)
        fetchAccountData(forAccount: account!)
        
        harvestingDispatchGroup.notify(queue: .main) {
            self.updateHarvestingInfoView()
            self.tableView.reloadData()
            self.hideLoadingView()
        }
    }
    
    /**
        Fetches information about harvested blocks for the provided account.
     
        - Parameter account: The account for which information about harvested blocks should get fetched.
     */
    fileprivate func fetchHarvestInfoData(forAccount account: Account) {
        
        harvestingDispatchGroup.enter()
        
        NEMProvider.request(NEM.harvestInfoData(accountAddress: account.address)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    
                    let harvestedBlocks = try json["data"].mapArray(Block.self)
                    
                    DispatchQueue.main.async {
                        
                        self?.harvestedBlocks = harvestedBlocks
                        
                        self?.harvestingDispatchGroup.leave()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        self?.harvestingDispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    
                    self?.harvestingDispatchGroup.leave()
                }
            }
        }
    }
    
    /**
        Fetches the account data (balance, cosignatories, etc.) for the current account from the active NIS.
     
        - Parameter account: The current account for which the account data should get fetched.
     */
    fileprivate func fetchAccountData(forAccount account: Account) {
        
        harvestingDispatchGroup.enter()
        
        NEMProvider.request(NEM.accountData(accountAddress: account.address)) { [weak self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    
                    let json = JSON(data: response.data)
                    
                    let accountData = try json.mapObject(AccountData.self)
                    
                    DispatchQueue.main.async {
                        
                        self?.accountData = accountData
                        
                        self?.harvestingDispatchGroup.leave()
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                        
                        self?.harvestingDispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                    
                    self?.harvestingDispatchGroup.leave()
                }
            }
        }
    }
    
    /// Updates the info view with the fetched harvesting information.
    fileprivate func updateHarvestingInfoView() {
        
        let importance = "\("POI".localized()): \((accountData!.importance! * 10000).format(maximumFractionDigits: 2)) ‱"
        let balance = "\("BALANCE".localized()): \(accountData!.balance / 1000000) XEM"
        let vestedBalance = "\("VASTED_BALANCE".localized()): \(accountData!.vestedBalance / 1000000) XEM"
        let remoteStatus = "\("DELEGATED_HARVESTING".localized()): \(accountData!.remoteStatus == "ACTIVE" ? "UNLOCKED".localized() : "LOCKED".localized())"
        let harvestedBlocks = accountData!.harvestedBlocks > 0 ? String(format: "LAST_HARVESTED_BLOCK".localized(), accountData!.harvestedBlocks > 25 ? 25 : accountData!.harvestedBlocks) : "NO_HARVESTED_BLOCK".localized()
        
        accountImportanceLabel.text = importance
        accountBalanceLabel.text = balance
        accountVestedBalanceLabel.text = vestedBalance
        accountHarvestingStatusLabel.text = remoteStatus
        accountHarvestedBlocksLabel.text = harvestedBlocks
        
        if accountData!.status == "LOCKED" {
            for constraint in harvestingInfoView.constraints {
                if constraint.identifier == "InfoHeight" {
                    constraint.constant = 155
                }
            }
        }
        
        harvestingInfoView.isHidden = false
    }
}

// MARK: - Table View Delegate

extension HarvestingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return harvestedBlocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HarvestingBlockTableViewCell") as! HarvestingBlockTableViewCell
        cell.block = harvestedBlocks[indexPath.row]
        
        return cell
    }
}
