//
//  AddressBookContactTableViewCell.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import Contacts

/// The table view cell that represents a contact in the address book.
final class AddressBookContactTableViewCell: UITableViewCell {
    
    // MARK: - Cell Properties
    
    var contact: CNContact! {
        didSet {
            updateCell()
        }
    }
    
    // MARK: - Cell Outlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var accessoryImageView: UIImageView!
    
    // MARK: - Cell Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateCellAppearance()
    }
    
    // MARK: - Cell Helper Methods
    
    /// Updates the table view cell with the provided contact data.
    fileprivate func updateCell() {
        
        titleLabel.text = "\(contact.givenName) \(contact.familyName)"
        
        accessoryImageView.isHidden = true
        for emailAddress in contact.emailAddresses where emailAddress.label == "NEM" {
            accessoryImageView.isHidden = false
        }
    }
    
    /// Updates the appearance of the table view cell.
    fileprivate func updateCellAppearance() {
        
        titleLabel.text = String()
    }
}
