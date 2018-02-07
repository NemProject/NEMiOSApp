//
//  Constants.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

/**
    Holds all constants of the application.
    Change these values to tweak the application.
 */
struct Constants {
    
    // MARK: - Network Version

    /**
        Change this constant to switch between the mainnet and testnet.
        The application only supports one network at a time.
     
        Available options:
        - mainNetwork
        - testNetwork
     */
    static let activeNetwork = mainNetwork

    static let testNetwork: UInt8 = 152
    static let mainNetwork: UInt8 = 104

    // MARK: - Timing

    /**
        The unix timestamp for the creation of the genesis block, used to calculate the 
        right timestamps for blocks, transactions, etc.
     */
    static let genesisBlockTime = 1427587585.0

    /// The deadline for new transactions after which they will get invalidated, if their not yet included in a block.
    static let transactionDeadline = 21600.0

    /// The interval at which content (transactions, account balance, etc.) should get refreshed.
    static let updateInterval: TimeInterval = 30

    // MARK: - QR Structure

    /**
        The versions of QR codes, which the application supports.
        Testnet QR codes are of version 1, mainnet QR codes of version 2.
     */
    static let qrVersion = activeNetwork == testNetwork ? 1 : 2
}
