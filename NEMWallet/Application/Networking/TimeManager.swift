//
//  TimeManager.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import Foundation
import SwiftyJSON

/**
    The time manager that synchronizes the application time with the time of the NEM network. 
    Those timestamps have to match in order to announce valid transactions to the NEM network. 
    Use the property 'currentNetworkTime' to get the synchronized, valid NEM network time.
 */
final class TimeManager {
    
    // MARK: - Manager Properties
    
    /// The singleton for the time manager.
    static let sharedInstance = TimeManager()
    
    /**
        The current NEM network time.
        Calculates the current network time by adding the elapsed time since fetching the network
        time to the then fetched network time.
     */
    public var currentNetworkTime: Double {
        get {
            return networkTimestamp + Date().timeIntervalSince(localTimestamp)
        }
    }
    
    /**
        Stores the timestamp of the NEM network when synchronizing the time.
        This property will be used to calculate the current network time.
        Don't use this property directly as this is only a static timestamp that doesn't reflect 
        the current network time.
     */
    private var networkTimestamp = 0.0 {
        didSet {
            localTimestamp = Date()
        }
    }
    
    /**
        Captures the timestamp for the local device, when the network time gets fetched.
        This property will be used to calculate the current network time.
        Don't use this property directly as this is only a static timestamp that doesn't reflect
        the current network time.
     */
    private var localTimestamp = Date()
    
    // MARK: - Manager Lifecycle
    
    private init() {} // Prevents others from creating own instances of this manager and not using the singleton.
    
    // MARK: - Manager Methods
    
    /// Synchronizes the application time with the NEM network time.
    public func synchronizeTime() {
        
        NEMProvider.request(NEM.synchronizeTime) { [unowned self] (result) in
            
            switch result {
            case let .success(response):
                
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    let responseJSON = JSON(data: response.data)
                    
                    self.networkTimestamp = responseJSON["receiveTimeStamp"].doubleValue / 1000
                    
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
