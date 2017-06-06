//
//  UIViewController+Additions.swift
//  NEMWallet
//
//  Created by Fujiki Takeshi on 2017/06/06.
//  Copyright © 2017年 NEM. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlertCopied() {
        let alert: UIAlertController = UIAlertController(title: "ADDRESS_COPIED".localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func showAlertSaved() {
        let alert: UIAlertController = UIAlertController(title: "QR_SAVED".localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
