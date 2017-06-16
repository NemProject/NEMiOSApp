//
//  MultisigCosignatoryTableViewCell.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The table view cell that represents a multisig cosignatory.
final class MultisigCosignatoryTableViewCell: UITableViewCell {
    
    // MARK: - Cell Properties
    
    var cosignatoryAccountData: AccountData? {
        didSet {
            updateCellWithAccountData()
        }
    }
    var cosignatoryIdentifier: String? {
        didSet {
            updateCellWithIdentifier()
        }
    }
    
    // MARK: - Cell Outlets
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateCellAppearance()
    }
    
    // MARK: - Cell Helper Methods
    
    /// Updates the table view cell with the provided account data.
    fileprivate func updateCellWithAccountData() {
        
        titleLabel.text = cosignatoryAccountData!.title ?? cosignatoryAccountData!.address.accountTitle()
    }
    
    /// Updates the table view cell with the provided identifier.
    fileprivate func updateCellWithIdentifier() {
        
        if AccountManager.sharedInstance.validateKey(cosignatoryIdentifier!) == true {
            
            titleLabel.text = AccountManager.sharedInstance.generateAddress(forPublicKey: cosignatoryIdentifier!).nemAddressNormalised().accountTitle()
            
        } else if TransactionManager.sharedInstance.validateAccountAddress(cosignatoryIdentifier!) {
            
            titleLabel.text = cosignatoryIdentifier!.nemAddressNormalised().accountTitle()
        
        } else {
            
            titleLabel.text = cosignatoryIdentifier!
        }
    }
    
    /// Updates the appearance of the table view cell.
    fileprivate func updateCellAppearance() {
        
        preservesSuperviewLayoutMargins = false
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
    }
}
