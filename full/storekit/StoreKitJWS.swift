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

    /// Parses the compact JWS representation used by StoreKit signed data.
    ///
    /// This initializer validates the envelope rather than its trust: the
    /// protected header must select ES256 and contain a nonempty, decodable
    /// `x5c` chain, the payload must be a JSON object, and the raw ECDSA
    /// signature must contain the 64-byte `r || s` representation required by
    /// ES256. Apple certificate-chain trust is deliberately not inferred from
    /// those structural checks on Linux.
    public init(compactSerialization: String) throws {
        self = try StoreKitJWSCodec.parse(compactSerialization)
    }

    /// The result of the Linux trust boundary for this signed value.
    ///
    /// A structurally valid envelope is still reported as `invalidSignature`:
    /// the Foundation-only build has neither Apple's StoreKit trust roots nor
    /// a supported ES256 verification dependency.
    public var signatureVerificationError: VerificationResult<Transaction>.VerificationError {
        StoreKitJWSCodec.signatureCheck(compactSerialization)
    }

    init(
        compactSerialization: String,
        headerData: Data,
        payloadData: Data,
        signatureData: Data,
        x5cChain: [Data]
    ) {
        self.compactSerialization = compactSerialization
        self.headerData = headerData
        self.payloadData = payloadData
        self.signatureData = signatureData
        self.x5cChain = x5cChain
    }

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
        guard (try? JSONSerialization.jsonObject(with: payloadData)) is [String: Any] else {
            throw VerificationResult<Transaction>.VerificationError.invalidEncoding
        }
        guard header["alg"] as? String == "ES256" else {
            throw VerificationResult<Transaction>.VerificationError.invalidSignature
        }
        // StoreKit signed values use a protected JWS header.  Accept an absent
        // `typ` for forward compatibility, but never accept a value claiming a
        // different envelope type.
        if let type = header["typ"] as? String, type != "JWS" {
            throw VerificationResult<Transaction>.VerificationError.invalidEncoding
        }
        guard signatureData.count == 64 else {
            throw VerificationResult<Transaction>.VerificationError.invalidSignature
        }
        guard let x5c = extractX5C(from: header), !x5c.isEmpty else {
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
        // RFC 7515 compact serialization uses the URL-safe, unpadded alphabet.
        // Foundation's base64 decoder is intentionally permissive in some
        // configurations, so validate the wire representation before padding.
        guard !string.contains("=") else { return nil }
        var base64 = ""
        for character in string {
            if character == "-" {
                base64.append("+")
            } else if character == "_" {
                base64.append("/")
            } else if character.isASCII,
                      character.isLetter || character.isNumber {
                base64.append(character)
            } else {
                return nil
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

    private static func extractX5C(from header: [String: Any]) -> [Data]? {
        guard let values = header["x5c"] as? [Any], !values.isEmpty else { return nil }
        var chain: [Data] = []
        for value in values {
            guard let encoded = value as? String, !encoded.isEmpty else { return nil }
            if let data = Data(base64Encoded: encoded) {
                chain.append(data)
            } else if let data = base64urlDecode(encoded) {
                chain.append(data)
            } else {
                return nil
            }
        }
        return chain
    }
}
