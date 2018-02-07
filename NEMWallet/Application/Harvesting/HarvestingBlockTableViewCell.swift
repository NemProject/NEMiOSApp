//
//  HarvestingBlockTableViewCell.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The table view cell that represents a block.
class HarvestingBlockTableViewCell: UITableViewCell {
    
    // MARK: - Cell Properties
    
    var block: Block? {
        didSet {
            updateCell()
        }
    }
    
    // MARK: - Cell Outlets
    
    @IBOutlet weak var blockIDLabel: UILabel!
    @IBOutlet weak var blockTimeStampLabel: UILabel!
    @IBOutlet weak var blockTotalFeeLabel: UILabel!
    
    // MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateCellAppearance()
    }
    
    // MARK: - Cell Helper Methods
    
    /// Updates the table view cell with the provided title.
    fileprivate func updateCell() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, YYYY H:mm:ss"

        var blockTimeStamp = Double(block!.timeStamp)
        blockTimeStamp += Constants.genesisBlockTime

        blockTimeStampLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: blockTimeStamp))
        blockIDLabel.text = "\("BLOCK".localized()) #\(block!.id!)"
        blockTotalFeeLabel.text = "\("FEE".localized()): \(block!.totalFee / 1000000)"
    }
    
    /// Updates the appearance of the table view cell.
    fileprivate func updateCellAppearance() {
        
        preservesSuperviewLayoutMargins = false
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
    }
}
