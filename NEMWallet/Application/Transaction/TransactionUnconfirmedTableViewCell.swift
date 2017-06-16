//
//  TransactionUnconfirmedTableViewCell.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The table view cell that represents an unconfirmed multisig transaction.
final class TransactionUnconfirmedTableViewCell: UITableViewCell {
    
    // MARK: - Cell Properties
    
    var transferTransaction: TransferTransaction? {
        didSet {
            updateCellTransferTransaction()
        }
    }
    var multisigAggregateModificationTransaction: MultisigAggregateModificationTransaction? {
        didSet {
            updateCellMultisigAggregateModificationTransaction()
        }
    }
    weak var delegate: TransactionUnconfirmedViewController? = nil
    
    // MARK: - Cell Outlets
    
    @IBOutlet weak var senderHeadingLabel: UILabel!
    @IBOutlet weak var senderValueLabel: UILabel!
    @IBOutlet weak var recipientHeadingLabel: UILabel!
    @IBOutlet weak var recipientValueLabel: UILabel!
    @IBOutlet weak var messageHeadingLabel: UILabel?
    @IBOutlet weak var messageValueLabel: UILabel?
    @IBOutlet weak var amountValueLabel: UILabel?
    @IBOutlet weak var confirmationButton: UIButton!
    @IBOutlet weak var showChangesButton: UIButton?
    
    // MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateCellAppearance()
    }
    
    // MARK: - Cell Helper Methods
    
    /// Updates the table view cell with the provided title.
    fileprivate func updateCellTransferTransaction() {
        
        senderValueLabel.text = AccountManager.sharedInstance.generateAddress(forPublicKey: transferTransaction!.signer).accountTitle()
        recipientValueLabel.text = transferTransaction!.recipient.accountTitle()
        messageValueLabel!.text = transferTransaction!.message?.message ?? String()
        amountValueLabel!.text = "\(transferTransaction!.amount / 1000000) XEM"
    }
    
    /// Updates the table view cell with the provided title.
    fileprivate func updateCellMultisigAggregateModificationTransaction() {
        
        senderValueLabel.text = AccountManager.sharedInstance.generateAddress(forPublicKey: multisigAggregateModificationTransaction!.signer).accountTitle()
        recipientValueLabel.text = AccountManager.sharedInstance.generateAddress(forPublicKey: multisigAggregateModificationTransaction!.signer).accountTitle()
    }
    
    /// Updates the appearance of the table view cell.
    fileprivate func updateCellAppearance() {
        
        senderHeadingLabel.text = "\("FROM".localized()):"
        recipientHeadingLabel.text = "\("TO".localized()):"
        confirmationButton.setTitle("CONFIRM".localized(), for: UIControlState())
        showChangesButton?.setTitle("SHOW_CHANGES".localized(), for: UIControlState())
        
        senderValueLabel.text = ""
        recipientValueLabel.text = ""
        messageHeadingLabel?.text = "\("MESSAGE".localized()):"
        messageValueLabel?.text = ""
        amountValueLabel?.text = "0 XEM"
        
        confirmationButton.layer.cornerRadius = 5
        showChangesButton?.layer.cornerRadius = 5
        layer.cornerRadius = 10
        preservesSuperviewLayoutMargins = false
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
    }

    @IBAction func confirmTransaction(_ sender: UIButton) {
        
        delegate?.confirmTransaction(atIndex: tag)
    }

    @IBAction func showChanges(_ sender: UIButton) {
        
        delegate?.showChanges(forTransactionAtIndex: tag)
    }
}
