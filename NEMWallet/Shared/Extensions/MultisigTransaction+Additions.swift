//
//  MultisigTransaction+Additions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

// MARK: - Model Equatable Extension

extension MultisigTransaction: Equatable { }

public func == (lhs: MultisigTransaction, rhs: MultisigTransaction) -> Bool {
    return lhs.type == rhs.type &&
        lhs.timeStamp == rhs.timeStamp &&
        lhs.metaData == rhs.metaData &&
        lhs.fee == rhs.fee &&
        lhs.deadline == rhs.deadline &&
        lhs.signature == rhs.signature &&
        lhs.signer == rhs.signer
}

// MARK: - Model Custom String Convertible Extension

extension MultisigTransaction: CustomStringConvertible {
    
    public var description: String {
        return "NemIOSClient.MultisigTransaction(type: \(type), timeStamp: \(timeStamp), metaData: \(metaData), fee: \(fee),, deadline: \(deadline), signature: \(signature), signatures: \(signatures), signer: \(signer), innerTransaction: \(innerTransaction))"
    }
}
