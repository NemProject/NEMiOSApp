import UIKit
import CryptoSwift

extension String {
    
    var URLEscapedString: String {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
    }
    
    var UTF8EncodedData: Data {
        return self.data(using: String.Encoding.utf8)!
    }
    
    func accountTitle() -> String {
        
        let accountTitle = AccountManager.sharedInstance.titleForAccount(withAddress: self)
        
        return accountTitle ?? self
    }
    
    func path() -> String
    {
        let _documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        
        let path = (_documentsPath as NSString).appendingPathComponent(self)
        
        return path
    }
    
    func hexadecimalStringUsingEncoding(_ encoding: String.Encoding) -> String? {
        let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false)
        return data?.toHexadecimalString()
    }
    
    func asByteArray()-> Array<UInt8> {
        var arrayLength :Int = self.utf16.count
        var hexString = self
        
        if arrayLength % 2 != 0 {
            hexString  = "0" + hexString
            arrayLength += 1
        }
        
        arrayLength = arrayLength / 2
        
        var buffer : Array<UInt8> = Array(repeating: 0 , count: arrayLength)
        for index :Int in 0  ..< arrayLength  {
            let substring :String = (hexString as NSString).substring(with: NSRange(location: 2 * index, length: 2))
            buffer[index] = UInt8(substring, radix: 16)!
        }
        return buffer
    }
    
    func asByteArray(_ length: Int)-> Array<UInt8> {
        var arrayLength :Int = self.utf16.count
        var hexString = self
        
        if arrayLength % 2 != 0 {
            hexString  = "0" + hexString
            arrayLength += 1
        }
        
        arrayLength = arrayLength / 2
        
        var buffer : Array<UInt8> = Array(repeating: 0 , count: length)
        for index :Int in 0  ..< arrayLength  {
            let substring :String = (hexString as NSString).substring(with: NSRange(location: 2 * index, length: 2))
            buffer[index] = UInt8(substring, radix: 16)!
        }
        
        return buffer
    }
    
    func asByteArrayEndian(_ length: Int)-> Array<UInt8> {
        var arrayLength :Int = self.utf16.count
        var hexString = self
        
        if arrayLength % 2 != 0 {
            hexString  = "0" + hexString
            arrayLength += 1
        }
        
        arrayLength = arrayLength / 2
        
        var buffer : Array<UInt8> = Array(repeating: 0 , count: length)
        for index :Int in 0  ..< arrayLength  {
            let substring :String = (hexString as NSString).substring(with: NSRange(location: 2 * index, length: 2))
            buffer[arrayLength - index - 1] = UInt8(substring, radix: 16)!
        }
        
        return buffer
    }
    
    func nemAddressNormalised() -> String {
        var newString = ""
        
        for i in stride(from: 0, to: self.characters.count, by: 6) {
            let substring = (self as NSString).substring(with: NSRange(location: i, length: ((self.characters.count - i) >= 6) ? 6 : self.characters.count - i))
            newString += substring + "-"
        }
        let length :Int = newString.characters.count - 1
        return (newString as NSString).substring(with: NSRange(location: 0, length: length))
    }
    
    func nemKeyNormalized() -> String? {
        if AccountManager.sharedInstance.validateKey(self) {
            if self.asByteArray().count > 32 {
                return (self as NSString).substring(with: NSRange(location: 2, length: 64))
            } else {
                return self
            }
        } else {
            return nil
        }
    }
    
    func localized(_ defaultValue: String? = nil) -> String {
        return NSLocalizedString(self, comment: defaultValue ?? self) 
    }
}
