//
//  AccountExceptions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

public enum Result: Error {
    case success
    case failure
}

public enum AccountImportValidation: Error {
    case valueMissing
    case versionNotMatching
    case dataTypeNotMatching
    case noPasswordProvided
    case wrongPasswordProvided
    case accountAlreadyPresent(accountTitle: String)
    case invalidPrivateKey
    case other
}
