//
//  NemAPI.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import Foundation
import Moya

// MARK: - Networking Provider

/**
    The application uses the dependency 'Moya' for all network requests.
    See the official [documentation](https://github.com/Moya/Moya) on how it works.
 */
let NEMProvider = MoyaProvider<NEM>(endpointClosure: { (target: NEM) -> Endpoint<NEM> in
    let url = target.baseURL.appendingPathComponent(target.path).absoluteString
    let endpoint: Endpoint<NEM> = Endpoint<NEM>(url: url, sampleResponseClosure: { .networkResponse(200, target.sampleData)}, method: target.method, task: target.task, httpHeaderFields: target.headers)
    return endpoint
})

// MARK: - Networking Routes

enum NEM {
    case heartbeat(server: Server)
    case synchronizeTime
    case accountData(accountAddress: String)
    case ownedMosaics(accountAddress: String)
    case confirmedTransactions(accountAddress: String, server: Server?)
    case unconfirmedTransactions(accountAddress: String, server: Server?)
    case announceTransaction(requestAnnounce: RequestAnnounce)
    case harvestInfoData(accountAddress: String)
}

extension NEM: TargetType {
    
    var baseURL: URL {
        switch self {
        case .heartbeat(let server):
            return server.fullURL()
        case .confirmedTransactions(_, let server), .unconfirmedTransactions(_, let server):
            if server != nil {
                return server!.fullURL()
            } else {
                return SettingsManager.sharedInstance.activeServer().fullURL()
            }
        default:
            return SettingsManager.sharedInstance.activeServer().fullURL()
        }
    }
    var path: String {
        switch self {
        case .heartbeat(_):
            return "/heartbeat"
        case .synchronizeTime:
            return "/time-sync/network-time"
        case .accountData(_):
            return "/account/get"
        case .ownedMosaics(_):
            return "/account/mosaic/owned"
        case .confirmedTransactions(_, _):
            return "/account/transfers/all"
        case .unconfirmedTransactions(_, _):
            return "/account/unconfirmedTransactions"
        case .announceTransaction(_):
            return "/transaction/announce"
        case .harvestInfoData(_):
            return "/account/harvests"
        }
    }
    var method: Moya.Method {
        switch self {
        case .announceTransaction:
            return .post
        default:
            return .get
        }
    }
    var task: Task {
        switch self {
        case .accountData(let accountAddress), .ownedMosaics(let accountAddress), .confirmedTransactions(let accountAddress, _), .unconfirmedTransactions(let accountAddress, _):
            return .requestParameters(parameters: ["address": accountAddress as AnyObject], encoding: URLEncoding.default)
        case .announceTransaction(let requestAnnounce):
            return .requestParameters(parameters: ["data": requestAnnounce.data as AnyObject, "signature": requestAnnounce.signature as AnyObject], encoding: JSONEncoding.default)
        case .harvestInfoData(let accountAddress):
            return .requestParameters(parameters: ["address": accountAddress as AnyObject], encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }
    var headers: [String: String]? {
        switch self {
        case .announceTransaction:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
    var sampleData: Data {
        switch self {
        case .heartbeat:
            return "{\"code\":1,\"type\":2,\"message\":\"ok\"}".UTF8EncodedData as Data
        case .synchronizeTime:
            return "{\"sendTimeStamp\":43429428889,\"receiveTimeStamp\":43429428889}".UTF8EncodedData as Data
        case .accountData(let accountAddress):
            return "{\"meta\":{\"cosignatories\":[],\"cosignatoryOf\":[],\"status\":\"LOCKED\",\"remoteStatus\":\"ACTIVE\"},\"account\":{\"address\":\"\(accountAddress)\",\"harvestedBlocks\":122,\"balance\":818215057310,\"importance\":1.3788016685695084E-4,\"vestedBalance\":651859458228,\"publicKey\":\"0c93acfb4d5762f945312b46267b90f4bece9a4f33cd4577397e6d3a95b4095a\",\"label\":null,\"multisigInfo\":{}}}".UTF8EncodedData as Data
        case .confirmedTransactions(let accountAddress, _):
            return "{\"data\":[{\"meta\":{\"innerHash\":{\"data\":\"1ace288cae98149056157803f0f1eaec7f7947fb37fb18c47a9da956b6d0d7bd\"},\"id\":562794,\"hash\":{\"data\":\"10ac8961c2ec298407160370d84680ab9cd377b36e310d9b87be2c004ff9ab57\"},\"height\":70006},\"transaction\":{\"timeStamp\":42102977,\"signature\":\"ff63251ed17c129bfa3165beb3af1917235b693232c611052ab18012c871ff8c464c89281d18b5e21866e40f151a11090f5cdcf22179bf455d0d74bd22252705\",\"fee\":6000000,\"type\":4100,\"deadline\":42489377,\"version\":1744830465,\"signatures\":[{\"timeStamp\":42459459,\"otherHash\":{\"data\":\"1fce2a8cae98149056157803f0f1eaec7f7947fb37fb18c47a9da956b6d0d7bd\"},\"otherAccount\":\"NBVNAYADDGETVYJXWOIUVJZULRZG7OUOS7KHAPHM\",\"signature\":\"d5902a008705c82ba19ceadce3e9d14582bd1faaa517eb140d11cf71d072fed95904ce5775976f91f3643c19ef66a8c927f63b41d2e2935777f2d715956b0108\",\"fee\":6000000,\"type\":4098,\"deadline\":42745859,\"version\":1744830465,\"signer\":\"dd7d3ac741ce2a757311f88d9cebf63200ea34aebdd85917ce981c572312375f\"},{\"timeStamp\":42653976,\"otherHash\":{\"data\":\"1fce288cae98149056157803f0f1eaec7f7947fb37fb18c47a9da956b6d0d7bd\"},\"otherAccount\":\"NBVNAYBUDGETVYJXWOIAVJZULRZG7OUOS7KHAPHM\",\"signature\":\"2bbe1e93b23ca6ac6715c5961ed158312b6f94b354c8acb41ab60fbb351077f1e37fb73ce69abb8dea1e88e0b932fb3346369ddb4c06d8d426c8cfa1881beb02\",\"fee\":6000000,\"type\":4098,\"deadline\":42740376,\"version\":1744830465,\"signer\":\"719862cd7d0f4e875a6a0274c9a1738f38f40ad9944179006a54c34724c1274d\"}],\"signer\":\"f94e8702eb1943b23570b1b83ba1b81536df35538978820e98bfce8f999e2d37\",\"otherTrans\":{\"timeStamp\":42602977,\"amount\":300000000000,\"fee\":111000000,\"recipient\":\"\(accountAddress)\",\"type\":257,\"deadline\":42689377,\"message\":{\"payload\":\"694f53207072657020776f726b20\",\"type\":1},\"version\":1744830465,\"signer\":\"4dceb1cb700b1bc7a58a9c76b3e827d797d20caace5ab8e40b397fba5c81be9a\"}}]}".UTF8EncodedData as Data
        default:
            return "{\"data\":[]}".UTF8EncodedData as Data
        }
    }
}
