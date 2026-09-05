import Foundation

/// Compact JWS (RFC 7515) used by StoreKit 2 transaction and
/// App Transaction payloads.
///
/// Linux has no Apple root store and CryptoKit is not a seed dependency.
/// Parsing is real (three base64url segments, JSON header/payload, `x5c`
/// chain present). Signature verification is fail-closed:
/// `VerificationResult.unverified(_, .invalidSignature)` unless a testing
/// store configuration sets `_treatTransactionsAsVerified`.
public struct StoreKitJWS: Hashable, Sendable {
    public let compactSerialization: String
    public let headerData: Data
    public let payloadData: Data
    public let signatureData: Data
    public let x5cChain: [Data]

    public var headerJSON: [String: Any]? {
        (try? JSONSerialization.jsonObject(with: headerData)) as? [String: Any]
    }

    public var payloadJSON: [String: Any]? {
        (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any]
    }

    public var algorithm: String? {
        headerJSON?["alg"] as? String
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(compactSerialization)
    }

    public static func == (lhs: StoreKitJWS, rhs: StoreKitJWS) -> Bool {
        lhs.compactSerialization == rhs.compactSerialization
    }
}

enum StoreKitJWSCodec {
    /// Placeholder leaf certificate bytes. Not an Apple certificate; the
    /// chain is present so compact JWS matches the documented x5c layout.
    static let placeholderCertificate = Data(
        "OPENUIKIT-STOREKIT-X5C-PLACEHOLDER".utf8
    )

    static func encode(payload: [String: Any]) -> StoreKitJWS {
        let x5c = [placeholderCertificate.base64EncodedString()]
        let headerObject: [String: Any] = [
            "alg": "ES256",
            "typ": "JWS",
            "x5c": x5c,
        ]
        let headerData = (try? JSONSerialization.data(withJSONObject: headerObject)) ?? Data()
        let payloadData = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
        // ES256 signatures are 64 bytes. These bytes are not a valid ECDSA
        // signature over the payload; verification is fail-closed.
        var signatureBytes = [UInt8](repeating: 0xA5, count: 64)
        if let identifier = payload["transactionId"] as? NSNumber {
            let value = identifier.uint64Value
            for index in 0..<8 {
                signatureBytes[index] = UInt8((value >> (8 * index)) & 0xFF)
            }
        }
        let signatureData = Data(signatureBytes)
        let compact =
            base64url(headerData) + "." + base64url(payloadData) + "."
            + base64url(signatureData)
        return StoreKitJWS(
            compactSerialization: compact,
            headerData: headerData,
            payloadData: payloadData,
            signatureData: signatureData,
            x5cChain: [placeholderCertificate]
        )
    }

    static func parse(_ compact: String) throws -> StoreKitJWS {
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw VerificationResult<Transaction>.VerificationError.invalidEncoding
        }
        guard
            let headerData = base64urlDecode(String(parts[0])),
            let payloadData = base64urlDecode(String(parts[1])),
            let signatureData = base64urlDecode(String(parts[2]))
        else {
            throw VerificationResult<Transaction>.VerificationError.invalidEncoding
        }
        guard let header = (try? JSONSerialization.jsonObject(with: headerData)) as? [String: Any] else {
            throw VerificationResult<Transaction>.VerificationError.invalidEncoding
        }
        guard (try? JSONSerialization.jsonObject(with: payloadData)) != nil else {
            throw VerificationResult<Transaction>.VerificationError.invalidEncoding
        }
        let x5c = extractX5C(from: header)
        if x5c.isEmpty {
            throw VerificationResult<Transaction>.VerificationError.invalidCertificateChain
        }
        return StoreKitJWS(
            compactSerialization: compact,
            headerData: headerData,
            payloadData: payloadData,
            signatureData: signatureData,
            x5cChain: x5c
        )
    }

    /// Fail-closed signature check. Linux cannot validate Apple's ES256
    /// chain: CryptoKit is not a seed dependency and no Apple root is
    /// present. A well-formed JWS with x5c still returns `.invalidSignature`.
    static func signatureCheck(
        _ compact: String
    ) -> VerificationResult<Transaction>.VerificationError {
        do {
            let parsed = try parse(compact)
            _ = parsed.algorithm
            _ = parsed.x5cChain
            return .invalidSignature
        } catch let error as VerificationResult<Transaction>.VerificationError {
            return error
        } catch {
            return .invalidEncoding
        }
    }

    static func base64url(_ data: Data) -> String {
        var output = ""
        for character in data.base64EncodedString() {
            if character == "+" {
                output.append("-")
            } else if character == "/" {
                output.append("_")
            } else if character == "=" {
                continue
            } else {
                output.append(character)
            }
        }
        return output
    }

    static func base64urlDecode(_ string: String) -> Data? {
        var base64 = ""
        for character in string {
            if character == "-" {
                base64.append("+")
            } else if character == "_" {
                base64.append("/")
            } else {
                base64.append(character)
            }
        }
        let remainder = base64.count % 4
        if remainder == 2 {
            base64 += "=="
        } else if remainder == 3 {
            base64 += "="
        } else if remainder == 1 {
            return nil
        }
        return Data(base64Encoded: base64)
    }

    private static func extractX5C(from header: [String: Any]) -> [Data] {
        guard let values = header["x5c"] as? [Any] else { return [] }
        var chain: [Data] = []
        for value in values {
            guard let encoded = value as? String else { continue }
            if let data = Data(base64Encoded: encoded) {
                chain.append(data)
            } else if let data = base64urlDecode(encoded) {
                chain.append(data)
            }
        }
        return chain
    }
}
