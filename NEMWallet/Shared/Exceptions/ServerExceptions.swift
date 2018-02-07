//
//  ServerExceptions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

public enum ServerAdditionValidation: Error {
    case serverAlreadyPresent(serverAddress: String)
}
