//
//  Correspondent+Additions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

// MARK: - Model Equatable Extension

extension Correspondent: Equatable { }

public func == (lhs: Correspondent, rhs: Correspondent) -> Bool {
    return lhs.accountAddress == rhs.accountAddress
}
