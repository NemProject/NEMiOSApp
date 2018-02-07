//
//  Server+Additions.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import Foundation

extension Server {
    
    func fullURL() -> URL {
        return URL(string: "\(self.protocolType)://\(self.address):\(self.port)")!
    }
}
