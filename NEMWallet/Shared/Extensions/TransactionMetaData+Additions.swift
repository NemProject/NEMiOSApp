//
//  TransactionMetaData+Additions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

// MARK: - Model Equatable Extension

extension TransactionMetaData: Equatable { }

public func == (lhs: TransactionMetaData, rhs: TransactionMetaData) -> Bool {
    return lhs.id == rhs.id &&
        lhs.height == rhs.height
}
