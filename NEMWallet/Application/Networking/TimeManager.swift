//
//  TimeManager.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/**
    The time manager that synchronizes the time of the application 
    with the NIS time.
 */
open class TimeManager {
    
    // MARK: - Manager Properties
    
    /// The singleton for the time manager.
    open static let sharedInstance = TimeManager()
    
    /// The time of the NEM network.
    fileprivate var nisTime = 0.0 {
        didSet {
            localTime = Date()
        }
    }
    
    /// The local time of the device.
    fileprivate var localTime = Date()
    
    /// The current time stamp synchronized with the NEM network.
    open var timeStamp: Double {
        get {
            return nisTime + Date().timeIntervalSince(localTime)
        }
    }
    
    // MARK: - Manager Methods
    
    /// Synchronizes the application time with the NEM network time.
    open func synchronizeTime() {
        
        nisProvider.request(NIS.synchronizeTime) { [unowned self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    let responseJSON = JSON(data: response.data)
                    
                    DispatchQueue.main.async {
                        
                        self.nisTime = responseJSON["receiveTimeStamp"].doubleValue / 1000
                    }
                    
                } catch {
                    
                    DispatchQueue.main.async {
                        
                        print("Failure: \(response.statusCode)")
                    }
                }
                
            case let .failure(error):
                
                DispatchQueue.main.async {
                    
                    print(error)
                }
            }
        }
    }
}
