import Foundation

#if canImport(Vision)
import Vision
#endif

/// An item recognized by `DataScannerViewController`. Public construction of
/// associated values is not in the canonical graph; Linux tests use
/// `@_spi(OpenUIKitHost)` fixtures only.
public enum RecognizedItem: Sendable {
    public typealias ID = UUID

    public struct Bounds: Sendable {
        public var topLeft: CGPoint
        public var topRight: CGPoint
        public var bottomRight: CGPoint
        public var bottomLeft: CGPoint

        public init(
            topLeft: CGPoint,
            topRight: CGPoint,
            bottomRight: CGPoint,
            bottomLeft: CGPoint
        ) {
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomRight = bottomRight
            self.bottomLeft = bottomLeft
        }
    }

    public struct Text: Sendable {
        public typealias ID = UUID

        public let id: UUID
        public let transcript: String
        public let bounds: Bounds

#if canImport(Vision)
        public var observation: VNRecognizedTextObservation {
            fatalError("Vision observation identity is unavailable without a real VNRecognizedTextObservation")
        }
#endif

        fileprivate init(id: UUID, transcript: String, bounds: Bounds) {
            self.id = id
            self.transcript = transcript
            self.bounds = bounds
        }
    }

    public struct Barcode: Sendable {
        public typealias ID = UUID

        public let id: UUID
        public let payloadStringValue: String?
        public let bounds: Bounds

#if canImport(Vision)
        public var observation: VNBarcodeObservation {
            fatalError("Vision observation identity is unavailable without a real VNBarcodeObservation")
        }
#endif

        fileprivate init(id: UUID, payloadStringValue: String?, bounds: Bounds) {
            self.id = id
            self.payloadStringValue = payloadStringValue
            self.bounds = bounds
        }
    }

    case text(Text)
    case barcode(Barcode)

    public var id: UUID {
        switch self {
        case .text(let value):
            return value.id
        case .barcode(let value):
            return value.id
        }
    }

    public var bounds: Bounds {
        switch self {
        case .text(let value):
            return value.bounds
        case .barcode(let value):
            return value.bounds
        }
    }
}

extension RecognizedItem.Text {
    @_spi(OpenUIKitHost)
    public static func hostFixture(
        transcript: String,
        bounds: RecognizedItem.Bounds,
        id: UUID = UUID()
    ) -> RecognizedItem.Text {
        RecognizedItem.Text(id: id, transcript: transcript, bounds: bounds)
    }
}

extension RecognizedItem.Barcode {
    @_spi(OpenUIKitHost)
    public static func hostFixture(
        payloadStringValue: String?,
        bounds: RecognizedItem.Bounds,
        id: UUID = UUID()
    ) -> RecognizedItem.Barcode {
        RecognizedItem.Barcode(
            id: id,
            payloadStringValue: payloadStringValue,
            bounds: bounds
        )
    }
}
