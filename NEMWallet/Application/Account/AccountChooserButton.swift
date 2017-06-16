//
//  AccountChooserButton.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// The button that shows the account chooser view controller when pressed.
final class AccountChooserButton: UIButton {
    
    // MARK: - Button Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateButtonAppearance()
    }
    
    // MARK: - Button Helper Methods
    
    /// Updates the appearance of the button.
    fileprivate func updateButtonAppearance() {
        
        layer.borderColor = UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1.0).cgColor
        layer.borderWidth = 1
        
        if let imageView = self.imageView {
            imageView.contentMode =  UIViewContentMode.scaleAspectFit
            imageView.frame = CGRect(x: frame.width - frame.height * 0.75 - 5, y: frame.height * 0.125, width: frame.height * 0.75, height: frame.height * 0.75)
        }
        
        if let titleLabel = self.titleLabel {
            titleLabel.sizeToFit()
            titleLabel.frame.origin.x = 0
            titleLabel.frame.origin.y = 0
            titleLabel.frame = CGRect(x: 10, y: 0, width: frame.width - frame.height - 10, height: frame.height)
        }
    }
}
