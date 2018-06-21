import UIKit
import CryptoSwift

extension NSData
{
    func hexadecimalString() -> String {
        let string = NSMutableString(capacity: length * 2)
        var byte: UInt8 = UInt8()
        
        for i in 0 ..< length {
            getBytes(&byte, range: NSMakeRange(i, 1))
            string.appendFormat("%02x", byte)
        }
        
        return string as NSString as String
    }
    
    func aesEncrypt(key: [UInt8], iv: [UInt8]) -> NSData? {
        let enc = try! AES(key: key, blockMode: CBC(iv: iv)).encrypt(self.arrayOfBytes())
        let encData = NSData(bytes: enc, length: enc.count)

        return encData
    }
    
    func aesDecrypt(key: [UInt8], iv: [UInt8]) -> NSData? {
        let dec = try! AES(key: key, blockMode: CBC(iv: iv)).decrypt(self.arrayOfBytes())
        let decData = NSData(bytes: dec, length: dec.count)
        
        return decData
    }
    
    public func arrayOfBytes() -> Array<UInt8> {
        let count = self.length / MemoryLayout<UInt8>.size
        var bytesArray = Array<UInt8>(repeating: 0, count: count)
        self.getBytes(&bytesArray, length:count * MemoryLayout<UInt8>.size)
        return bytesArray
    }
}
