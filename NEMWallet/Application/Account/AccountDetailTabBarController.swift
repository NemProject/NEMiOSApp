//
//  AccountDetailTabBarController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    The account detail tab bar controller that gets shown when the
    user chooses to see more details about a certain account from
    the account list view controller. This tab bar controller lets
    the user choose from different specific informations to show.
 */
final class AccountDetailTabBarController: UITabBarController {
    
    // MARK: - Tab Bar Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTabBarControllerAppearance()
    }
    
    // MARK: - Tab Bar Conroller Helper Methods
    
    /// Updates the appearance (coloring, etc) of the tab bar controller.
    fileprivate func updateTabBarControllerAppearance() {
        
        tabBar.items?[0].title = "MESSAGES".localized()
        tabBar.items?[1].title = "ADDRESS_BOOK".localized()
        tabBar.items?[2].title = "QR".localized()
        tabBar.items?[3].title = "MORE".localized()
        
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(white: 0.64, alpha: 1.0)], for: UIControlState())
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)], for: .selected)
        
        for item in tabBar.items! as [UITabBarItem] {
            if let normalImage = item.image {
                item.image = normalImage.imageWithColor(UIColor(white:0.64, alpha:1.0)).withRenderingMode(.alwaysOriginal)
            }
            
            if let selectedImage = item.selectedImage {
                item.selectedImage = selectedImage.imageWithColor(UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)).withRenderingMode(.alwaysOriginal)
            }
        }
    }
}
