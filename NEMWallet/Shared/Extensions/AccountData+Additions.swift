//
//  AccountData+Additions.swift
//  NemIOSClient
//
//  Created by Thomas Oehri on 24.09.16.
//  Copyright © 2016 Artygeek. All rights reserved.
//

import Foundation

// MARK: - Model Equatable Extension

extension AccountData: Equatable { }

public func == (lhs: AccountData, rhs: AccountData) -> Bool {
    return lhs.address == rhs.address &&
        lhs.publicKey == rhs.publicKey
}
