//
//  AccountTableViewCell.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The table view cell that represents an account.
final class AccountTableViewCell: UITableViewCell {
    
    // MARK: - Cell Properties
    
    /**
        The account title that will get shown as the
        title label of the table view cell.
     */
    var title: String? {
        didSet {
            updateCell()
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
    
    /// Updates the table view cell with the provided title.
    fileprivate func updateCell() {
        
        titleLabel.text = title ?? String()
    }
    
    /// Updates the appearance of the table view cell.
    fileprivate func updateCellAppearance() {
        
        preservesSuperviewLayoutMargins = false
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
    }
}
