import CoreFoundation
import Foundation

/// Linux overlay of `CMReadySampleBuffer`. Wraps a data-ready `CMSampleBuffer`.
/// Pixel-buffer and tagged-buffer specializations stay deferred until CoreVideo
/// tagged groups exist on this isolated gate.

public struct CMReadySampleBuffer<Content: CMSampleBuffer.Content> {
    public var sampleBuffer: CMSampleBuffer

    public init(unsafeBuffer: CMSampleBuffer) {
        self.sampleBuffer = unsafeBuffer
    }

    public init?(_ other: CMSampleBuffer) {
        guard other.dataIsReady, other.isValid else { return nil }
        self.sampleBuffer = other
    }

    public var formatDescription: CMFormatDescription? {
        sampleBuffer.formatDescription
    }

    public var duration: CMTime {
        get { sampleBuffer.duration }
        set { sampleBuffer.replaceTimingField(\.duration, with: newValue) }
    }

    public var presentationTimeStamp: CMTime {
        get { sampleBuffer.presentationTimeStamp }
        set { sampleBuffer.replaceTimingField(\.presentationTimeStamp, with: newValue) }
    }

    public var decodeTimeStamp: CMTime {
        get { sampleBuffer.decodeTimeStamp }
        set { sampleBuffer.replaceTimingField(\.decodeTimeStamp, with: newValue) }
    }

    public var outputDecodeTimeStamp: CMTime {
        get { sampleBuffer.outputDecodeTimeStamp }
        set { sampleBuffer.replaceTimingField(\.decodeTimeStamp, with: newValue) }
    }

    public var outputPresentationTimeStamp: CMTime {
        get { sampleBuffer.outputPresentationTimeStamp }
        set { sampleBuffer.outputPresentationTimeStamp = newValue }
    }

    public var sampleCount: Int { sampleBuffer.numSamples }
    public var totalSampleSize: Int { sampleBuffer.totalSampleSize }

    public var sampleAttachments: CMSampleBuffer.SampleAttachments {
        get {
            let first = sampleBuffer.sampleAttachments.first ?? [:]
            var mapped: [String: any Sendable] = [:]
            for (key, value) in first {
                if let flag = value as? Bool {
                    mapped[key] = flag
                } else if let number = value as? Int {
                    mapped[key] = number
                } else if let text = value as? String {
                    mapped[key] = text
                } else if let data = value as? Data {
                    mapped[key] = data
                }
            }
            return CMSampleBuffer.SampleAttachments(mapped)
        }
        set {
            if sampleBuffer.sampleAttachments.isEmpty {
                sampleBuffer.sampleAttachments = [newValue.dictionaryRepresentation]
            } else {
                sampleBuffer.sampleAttachments[0] = newValue.dictionaryRepresentation
            }
        }
    }

    public var sampleProperties: CMSampleBuffer.SamplePropertiesCollection {
        get {
            let count = sampleBuffer.numSamples
            let sizes = (0..<count).map { (try? sampleBuffer.sampleSize(at: $0)) ?? 0 }
            let timings = (0..<count).map { (try? sampleBuffer.sampleTimingInfo(at: $0)) ?? .invalid }
            return CMSampleBuffer.SamplePropertiesCollection(
                sampleCount: count,
                sizes: .distinct(sizes),
                timings: .distinct(timings)
            )
        }
        set {
            _ = newValue
        }
    }

    public func splitSamples() -> [CMReadySampleBuffer<Content>] {
        [self]
    }
}

extension CMReadySampleBuffer where Content == CMReadOnlyDataBlockBuffer {
    public init(
        dataBuffer: CMReadOnlyDataBlockBuffer,
        formatDescription: CMFormatDescription?,
        sampleProperties: CMSampleBuffer.SamplePropertiesCollection
    ) throws {
        let sizes: [Int]
        switch sampleProperties.sizes {
        case .uniform(let size):
            sizes = [size]
        case .distinct(let values):
            sizes = values
        case nil:
            sizes = [dataBuffer.count]
        }
        let timings: [CMSampleTimingInfo]
        switch sampleProperties.timings {
        case .sequential(let start):
            timings = [start]
        case .distinct(let values):
            timings = values
        case nil:
            timings = [.invalid]
        }
        let block = CMBlockBuffer(data: Data(dataBuffer.storage.bytes))
        self.sampleBuffer = try CMSampleBuffer(
            dataBuffer: block,
            formatDescription: formatDescription,
            numSamples: Swift.max(1, sampleProperties.sampleCount),
            sampleTimings: timings,
            sampleSizes: sizes,
            dataReady: true
        )
    }

    public init(unsafeWithDataBuffer unsafeBuffer: CMSampleBuffer) {
        self.sampleBuffer = unsafeBuffer
    }

    public var content: CMReadOnlyDataBlockBuffer {
        get {
            if let data = sampleBuffer.dataBuffer, let bytes = try? data.dataBytes() {
                return CMReadOnlyDataBlockBuffer(bytes)
            }
            return CMReadOnlyDataBlockBuffer(Data())
        }
        set {
            _ = newValue
        }
    }
}

extension CMReadySampleBuffer {
    public init(markerAt timeStamp: CMTime, duration: CMTime) throws {
        self.sampleBuffer = try CMSampleBuffer(
            dataBuffer: nil,
            formatDescription: nil,
            numSamples: 0,
            sampleTimings: [
                CMSampleTimingInfo(
                    duration: duration,
                    presentationTimeStamp: timeStamp,
                    decodeTimeStamp: .invalid
                )
            ],
            sampleSizes: [],
            dataReady: true
        )
    }

    public var markerTimeStamp: CMTime { presentationTimeStamp }
}
