import Foundation
import CommonCrypto

/// HMAC-SHA256 signing for the stats API.
enum PusherHmac {
  static func signature(
    method: String,
    pathAndQuery: String,
    unixSeconds: Int64,
    body: String,
    key: String
  ) -> String {
    let canonical = [
      method.uppercased(),
      pathAndQuery,
      "\(unixSeconds)",
      body,
    ].joined(separator: "\n")

    let keyData = Data(key.utf8)
    let messageData = Data(canonical.utf8)
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    keyData.withUnsafeBytes { keyBytes in
      messageData.withUnsafeBytes { messageBytes in
        CCHmac(
          CCHmacAlgorithm(kCCHmacAlgSHA256),
          keyBytes.baseAddress,
          keyData.count,
          messageBytes.baseAddress,
          messageData.count,
          &digest
        )
      }
    }

    return Data(digest).base64EncodedString()
  }
}
