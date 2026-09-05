import Foundation

/// An opaque audio signature used as a query or custom-catalog reference.
///
/// This host does not decode Apple's signature codec. Public construction
/// stores the caller-supplied bytes and reports `duration == 0`. Empty data
/// is ``SHError/Code-swift.enum/signatureInvalid``. Time-window slicing
/// throws ``SHError/Code-swift.enum/signatureDurationInvalid``.
public class SHSignature: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { false }

    public let dataRepresentation: Data
    public let duration: TimeInterval

    public init(dataRepresentation: Data) throws {
        guard !dataRepresentation.isEmpty else {
            throw SHError(.signatureInvalid)
        }
        self.dataRepresentation = dataRepresentation
        self.duration = 0
        super.init()
    }

    internal init(uncheckedData: Data, duration: TimeInterval) {
        self.dataRepresentation = uncheckedData
        self.duration = duration
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    /// Apple's signature codec can emit overlapping windows. This host cannot
    /// decode that format, so any non-empty window request fails closed.
    public func slices(
        from start: TimeInterval,
        duration: TimeInterval,
        stride: TimeInterval? = nil
    ) throws -> SHSignature.Slices {
        _ = stride
        if start == 0 && duration == 0 && self.duration == 0 {
            return Slices(signatures: [])
        }
        throw SHError(.signatureDurationInvalid)
    }

    /// An async sequence of sub-signatures. Empty on this host unless slicing
    /// a zero-duration signature at `(0, 0)`, which yields nothing.
    public struct Slices: AsyncSequence {
        public typealias Element = SHSignature
        public typealias AsyncIterator = Iterator

        internal let signatures: [SHSignature]

        public func makeAsyncIterator() -> Iterator {
            Iterator(signatures: signatures)
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = SHSignature.Slices.Element

            private let signatures: [SHSignature]
            private var index = 0

            internal init(signatures: [SHSignature]) {
                self.signatures = signatures
            }

            public mutating func next() async throws -> SHSignature.Slices.Element? {
                guard index < signatures.count else { return nil }
                let value = signatures[index]
                index += 1
                return value
            }
        }
    }
}

/// Builds a signature from PCM buffers or an `AVAsset`.
///
/// Buffer/asset ingest requires AVFoundation, which this seed does not
/// import. `signature()` returns the locally accumulated bytes, which stay
/// empty until a future integration build feeds real audio.
public class SHSignatureGenerator: NSObject {
    private var accumulated = Data()
    private var accumulatedDuration: TimeInterval = 0

    public override init() {
        super.init()
    }

    public func signature() -> SHSignature {
        SHSignature(uncheckedData: accumulated, duration: accumulatedDuration)
    }
}
