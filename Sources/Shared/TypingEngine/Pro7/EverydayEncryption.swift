import Foundation
import CryptoKit

enum EverydayEncryption {
    static func makeKey()->String { SymmetricKey(size:.bits256).withUnsafeBytes{Data($0).base64EncodedString()} }
    static func key(_ input:String)->SymmetricKey? {
        guard let data=Data(base64Encoded:input.trimmingCharacters(in:.whitespacesAndNewlines)),data.count==32 else{return nil}
        return SymmetricKey(data:data)
    }
    static func seal(_ data:Data,using key:SymmetricKey)throws->Data {
        guard data.count<=900_000,let result=try AES.GCM.seal(data,using:key).combined else{throw CocoaError(.fileWriteUnknown)}
        return result
    }
    static func open(_ data:Data,using key:SymmetricKey)throws->Data {
        guard data.count<=1_000_000 else{throw CocoaError(.fileReadCorruptFile)}
        return try AES.GCM.open(AES.GCM.SealedBox(combined:data),using:key)
    }
}
