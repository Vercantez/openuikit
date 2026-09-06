import Foundation

public class MDLVertexBufferLayout: NSObject, NSCopying {
    public var stride: UInt

    public init(stride: UInt) {
        self.stride = stride
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MDLVertexBufferLayout(stride: stride)
    }
}

public class MDLVertexAttribute: NSObject, NSCopying {
    public var name: String
    public var format: MDLVertexFormat
    public var offset: UInt
    public var bufferIndex: UInt
    public var time: TimeInterval
    public var initializationValue: SIMD4<Float>

    public init(name: String, format: MDLVertexFormat, offset: UInt, bufferIndex: UInt) {
        self.name = name
        self.format = format
        self.offset = offset
        self.bufferIndex = bufferIndex
        self.time = 0
        self.initializationValue = SIMD4<Float>(repeating: 0)
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = MDLVertexAttribute(name: name, format: format, offset: offset, bufferIndex: bufferIndex)
        clone.time = time
        clone.initializationValue = initializationValue
        return clone
    }
}

public class MDLVertexDescriptor: NSObject, NSCopying {
    public var attributes: NSMutableArray
    public var layouts: NSMutableArray

    public override init() {
        attributes = NSMutableArray()
        layouts = NSMutableArray()
        super.init()
    }

    public init(vertexDescriptor: MDLVertexDescriptor) {
        attributes = NSMutableArray()
        layouts = NSMutableArray()
        super.init()
        for case let attribute as MDLVertexAttribute in vertexDescriptor.attributes {
            attributes.add(attribute.copy() as Any)
        }
        for case let layout as MDLVertexBufferLayout in vertexDescriptor.layouts {
            layouts.add(layout.copy() as Any)
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MDLVertexDescriptor(vertexDescriptor: self)
    }

    public func attributeNamed(_ name: String) -> MDLVertexAttribute? {
        for case let attribute as MDLVertexAttribute in attributes where attribute.name == name {
            return attribute
        }
        return nil
    }

    public func addOrReplaceAttribute(_ attribute: MDLVertexAttribute) {
        if let existing = attributeNamed(attribute.name) {
            let index = attributes.index(of: existing)
            if index != NSNotFound {
                attributes[index] = attribute
                return
            }
        }
        attributes.add(attribute)
    }

    public func removeAttributeNamed(_ name: String) {
        if let existing = attributeNamed(name) {
            attributes.remove(existing)
        }
    }

    public func reset() {
        attributes.removeAllObjects()
        layouts.removeAllObjects()
    }

    public func setPackedOffsets() {
        var cursor: [UInt: UInt] = [:]
        for case let attribute as MDLVertexAttribute in attributes {
            let start = cursor[attribute.bufferIndex, default: 0]
            attribute.offset = start
            cursor[attribute.bufferIndex] = start + UInt(modelIOVertexFormatStride(attribute.format))
        }
    }

    public func setPackedStrides() {
        var widths: [UInt: UInt] = [:]
        for case let attribute as MDLVertexAttribute in attributes {
            let end = attribute.offset + UInt(modelIOVertexFormatStride(attribute.format))
            widths[attribute.bufferIndex] = max(widths[attribute.bufferIndex, default: 0], end)
        }
        let needed = (widths.keys.max() ?? 0) + 1
        while UInt(layouts.count) < needed {
            layouts.add(MDLVertexBufferLayout(stride: 0))
        }
        for (index, stride) in widths {
            if Int(index) < layouts.count, let layout = layouts[Int(index)] as? MDLVertexBufferLayout {
                layout.stride = stride
            }
        }
    }
}

public class MDLVertexAttributeData: NSObject {
    public var dataStart: UnsafeMutableRawPointer
    public var stride: UInt
    public var format: MDLVertexFormat
    public var bufferSize: UInt
    public var map: MDLMeshBufferMap

    public override init() {
        let empty = MDLMeshBufferMap(copying: Data())
        self.map = empty
        self.dataStart = empty.bytes
        self.stride = 0
        self.format = .invalid
        self.bufferSize = 0
        super.init()
    }

    init(map: MDLMeshBufferMap, stride: UInt, format: MDLVertexFormat, bufferSize: UInt) {
        self.map = map
        self.dataStart = map.bytes
        self.stride = stride
        self.format = format
        self.bufferSize = bufferSize
        super.init()
    }
}
