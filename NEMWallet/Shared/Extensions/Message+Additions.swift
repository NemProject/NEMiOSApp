//
//  Message+Additions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

// MARK: - Model Equatable Extension

extension Message: Equatable { }

public func == (lhs: Message, rhs: Message) -> Bool {
    return lhs.type == rhs.type &&
        lhs.type == rhs.type &&
        lhs.payload == rhs.payload
}
