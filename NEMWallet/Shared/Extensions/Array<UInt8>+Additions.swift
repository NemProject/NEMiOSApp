//
//  Array<UInt8>+Additions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

extension Sequence where Iterator.Element == UInt8 {
    
    func toHexadecimalString() -> String {
        
        var byteArrayHexadecimalString = String()
        
        for value in self {
            byteArrayHexadecimalString = byteArrayHexadecimalString + (NSString(format: "%02x", value) as String)
        }
        
        return byteArrayHexadecimalString
    }
}
