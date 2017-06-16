//
//  AccountAdditionMenuButton.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    The account addition menu button that is present in the
    account addition menu view controller and lets the user
    choose an action to perform.
 */
final class AccountAdditionMenuButton: UIButton {
    
    // MARK: - Button Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutImageView()
        layoutTitleLabel()
    }
    
    // MARK: - Button Helper Methods
    
    /**
        Calculates the frame size of the button image view and
        layouts the frame accordingly.
     */
    fileprivate func layoutImageView() {
        
        if let imageView = self.imageView {
            imageView.frame = CGRect(x: (self.frame.width / 2) - 12, y: (self.frame.height / 3) - 8, width: 24, height: 24)
        }
    }
    
    /**
        Calculates the frame size of the title label and layouts
        the frame accordingly.
     */
    fileprivate func layoutTitleLabel() {
        
        if let titleLabel = self.titleLabel {
            titleLabel.sizeToFit()
            titleLabel.center.x = self.frame.width / 2
            titleLabel.center.y = (self.frame.height * 2) / 3
        }
    }
}
