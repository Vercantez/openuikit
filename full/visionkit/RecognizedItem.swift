import Foundation

/// An item that a data scanner recognizes in camera video.
public enum RecognizedItem: Identifiable {
    public typealias ID = UUID

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

    /// The four corners of a recognized item.
    public struct Bounds: Sendable {
        public var topLeft: CGPoint
        public var topRight: CGPoint
        public var bottomLeft: CGPoint
        public var bottomRight: CGPoint

        public init(
            topLeft: CGPoint,
            topRight: CGPoint,
            bottomLeft: CGPoint,
            bottomRight: CGPoint
        ) {
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomLeft = bottomLeft
            self.bottomRight = bottomRight
        }

        public static let zero = Bounds(
            topLeft: .zero,
            topRight: .zero,
            bottomLeft: .zero,
            bottomRight: .zero
        )
    }

    /// Recognized text.
    public struct Text: Identifiable {
        public typealias ID = UUID

        public let id: UUID
        public let bounds: Bounds
        public let transcript: String
        public let observation: VNRecognizedTextObservation

        @_spi(OpenUIKitHost)
        public init(
            id: UUID = UUID(),
            bounds: Bounds = .zero,
            transcript: String,
            observation: VNRecognizedTextObservation = VNRecognizedTextObservation()
        ) {
            self.id = id
            self.bounds = bounds
            self.transcript = transcript
            self.observation = observation
        }
    }

    /// A recognized machine-readable code.
    public struct Barcode: Identifiable {
        public typealias ID = UUID

        public let id: UUID
        public let bounds: Bounds
        public let observation: VNBarcodeObservation

        public var payloadStringValue: String? {
            observation.payloadStringValue
        }

        @_spi(OpenUIKitHost)
        public init(
            id: UUID = UUID(),
            bounds: Bounds = .zero,
            observation: VNBarcodeObservation
        ) {
            self.id = id
            self.bounds = bounds
            self.observation = observation
        }
    }
}
