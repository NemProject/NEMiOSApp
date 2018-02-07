//
//  MultisigSignatureTransaction+Additions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

// MARK: - Model Equatable Extension

extension MultisigSignatureTransaction: Equatable { }

public func == (lhs: MultisigSignatureTransaction, rhs: MultisigSignatureTransaction) -> Bool {
    return lhs.type == rhs.type &&
        lhs.timeStamp == rhs.timeStamp &&
        lhs.fee == rhs.fee &&
        lhs.deadline == rhs.deadline &&
        lhs.signature == rhs.signature &&
        lhs.signer == rhs.signer &&
        lhs.otherAccount == rhs.otherAccount
}

// MARK: - Model Custom String Convertible Extension

extension MultisigSignatureTransaction: CustomStringConvertible {
    
    public var description: String {
        return "NemIOSClient.MultisigSignatureTransaction(type: \(type), timeStamp: \(timeStamp), fee: \(fee), deadline: \(deadline), signature: \(signature), signer: \(signer), otherAccount: \(otherAccount))"
    }
}
