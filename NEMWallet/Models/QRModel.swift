//
//  QRModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

/**
    All available keys for the QR code JSON array.
    DataType corresponds to the QRType beneath and version to the qrVersion.
 */
enum QRKeys: String {
    case address = "addr"
    case name = "name"
    case amount = "amount"
    case message = "msg"
    case dataType = "type"
    case data = "data"
    case privateKey = "priv_key"
    case salt = "salt"
    case version = "v"
}

/// All the different types of QR codes.
enum QRType: Int {
    case userData = 1
    case invoice = 2
    case accountData = 3
}
