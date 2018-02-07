//
//  TransactionOverviewCorrespondentTableViewCell.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    The table view cell that represents a correspondent in the
    transaction overview table view controller.
 */
class TransactionOverviewCorrespondentTableViewCell: UITableViewCell {
    
    // MARK: - Cell Properties
    
    var account: Account?
    var correspondent: Correspondent? {
        didSet {
            updateCell()
        }
    }
    
    // MARK: - Cell Outlets
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mostRecentMessageLabel: UILabel!
    @IBOutlet weak var mostRecentDateLabel: UILabel!
    @IBOutlet weak var mostRecentAmountLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateCellAppearance()
    }

    // MARK: - Cell Helper Methods
    
    /// Updates the table view cell with the provided correspondent data.
    fileprivate func updateCell() {
        
        let mostRecentTransferTransaction = correspondent!.mostRecentTransaction as! TransferTransaction
        nameLabel.text = correspondent!.name != nil ? correspondent!.name : correspondent!.accountAddress.nemAddressNormalised()
        mostRecentMessageLabel.text = mostRecentTransferTransaction.message?.message ?? String()
        mostRecentDateLabel.text = getDate(fromTransactionTimeStamp: correspondent!.mostRecentTransaction.timeStamp)
        mostRecentAmountLabel.attributedText = formatAmount(mostRecentTransferTransaction.amount)
    }
    
    /// Updates the appearance of the table view cell.
    fileprivate func updateCellAppearance() {
        
        containerView.layer.cornerRadius = 5
    }
    
    /**
        Converts the given transaction time stamp to a human readable date string.
        If the transaction was performed today, the time of the transaction gets returned.
     
        - Parameter timeStampe: The transaction time stamp that should get converted.
     
        - Returns: The human readable date or time the transaction was performed as a string.
     */
    fileprivate func getDate(fromTransactionTimeStamp timeStamp: Int) -> String {
        
        let timeStamp = Double(timeStamp) + Constants.genesisBlockTime
        var date = String()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if dateFormatter.string(from: Date(timeIntervalSince1970: timeStamp)) == dateFormatter.string(from: Date()) {
            dateFormatter.dateFormat = "HH:mm"
        }
        
        let mostRecentTransferTransaction = correspondent!.mostRecentTransaction as! TransferTransaction
        if mostRecentTransferTransaction.metaData!.id != nil {
            date = dateFormatter.string(from: Date(timeIntervalSince1970: timeStamp))
        } else {
            date = "UNCONFIRMED_DASHBOARD".localized()
        }
        
        return date
    }
    
    /**
        Creates an attributed string of the amount with coloring that indicates
        if the transaction was an incoming or an outgoing transaction and more.
     
        - Parameter amount: The transaction amount which should get turned into an formatted attributed string.
     
        - Returns: The amount as a formatted attributed string.
     */
    fileprivate func formatAmount(_ amount: Double) -> NSMutableAttributedString {
        
        var amountAttributedString = NSMutableAttributedString()
        var textColor = UIColor()
        var sign = String()
        
        let mostRecentTransferTransaction = correspondent!.mostRecentTransaction as! TransferTransaction
        if (mostRecentTransferTransaction.transferType == .outgoing && mostRecentTransferTransaction.recipient != account!.address) {
            sign = "-"
            textColor = UIColor.red
        } else if correspondent!.mostRecentTransaction.signer == account!.publicKey {
            sign = "±"
            textColor = UIColor(red: 142.0/255.0, green: 142.0/255.0, blue: 142.0/255.0, alpha: 1)
        } else {
            sign = "+"
            textColor = UIColor(red: 65.0/255.0, green: 206.0/255.0, blue: 123.0/255.0, alpha: 1)
        }
        
        amountAttributedString = NSMutableAttributedString(string: "\(sign)\((amount / 1000000).format()) XEM", attributes: [NSForegroundColorAttributeName: textColor])
        
        return amountAttributedString
    }
}
