import Foundation

public struct _GLKVector2: Equatable, Hashable, Sendable {
    public var x: Float
    public var y: Float

    public var s: Float {
        get { x }
        set { x = newValue }
    }

    public var t: Float {
        get { y }
        set { y = newValue }
    }

    public init(x: Float = 0, y: Float = 0) {
        self.x = x
        self.y = y
    }
}

public struct _GLKVector3: Equatable, Hashable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float

    public var r: Float {
        get { x }
        set { x = newValue }
    }

    public var g: Float {
        get { y }
        set { y = newValue }
    }

    public var b: Float {
        get { z }
        set { z = newValue }
    }

    public var s: Float {
        get { x }
        set { x = newValue }
    }

    public var t: Float {
        get { y }
        set { y = newValue }
    }

    public var p: Float {
        get { z }
        set { z = newValue }
    }

    public init(x: Float = 0, y: Float = 0, z: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct _GLKVector4: Equatable, Hashable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float

    public var r: Float {
        get { x }
        set { x = newValue }
    }

    public var g: Float {
        get { y }
        set { y = newValue }
    }

    public var b: Float {
        get { z }
        set { z = newValue }
    }

    public var a: Float {
        get { w }
        set { w = newValue }
    }

    public init(x: Float = 0, y: Float = 0, z: Float = 0, w: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

public struct _GLKMatrix2: Equatable, Hashable, Sendable {
    public var m00: Float
    public var m01: Float
    public var m10: Float
    public var m11: Float

    public init(m00: Float = 0, m01: Float = 0, m10: Float = 0, m11: Float = 0) {
        self.m00 = m00
        self.m01 = m01
        self.m10 = m10
        self.m11 = m11
    }
}

public struct _GLKMatrix3: Equatable, Hashable, Sendable {
    public var m00: Float
    public var m01: Float
    public var m02: Float
    public var m10: Float
    public var m11: Float
    public var m12: Float
    public var m20: Float
    public var m21: Float
    public var m22: Float

    public init(
        m00: Float = 0, m01: Float = 0, m02: Float = 0,
        m10: Float = 0, m11: Float = 0, m12: Float = 0,
        m20: Float = 0, m21: Float = 0, m22: Float = 0
    ) {
        self.m00 = m00
        self.m01 = m01
        self.m02 = m02
        self.m10 = m10
        self.m11 = m11
        self.m12 = m12
        self.m20 = m20
        self.m21 = m21
        self.m22 = m22
    }
}

public struct _GLKMatrix4: Equatable, Hashable, Sendable {
    public var m00: Float
    public var m01: Float
    public var m02: Float
    public var m03: Float
    public var m10: Float
    public var m11: Float
    public var m12: Float
    public var m13: Float
    public var m20: Float
    public var m21: Float
    public var m22: Float
    public var m23: Float
    public var m30: Float
    public var m31: Float
    public var m32: Float
    public var m33: Float

    public init(
        m00: Float = 0, m01: Float = 0, m02: Float = 0, m03: Float = 0,
        m10: Float = 0, m11: Float = 0, m12: Float = 0, m13: Float = 0,
        m20: Float = 0, m21: Float = 0, m22: Float = 0, m23: Float = 0,
        m30: Float = 0, m31: Float = 0, m32: Float = 0, m33: Float = 0
    ) {
        self.m00 = m00
        self.m01 = m01
        self.m02 = m02
        self.m03 = m03
        self.m10 = m10
        self.m11 = m11
        self.m12 = m12
        self.m13 = m13
        self.m20 = m20
        self.m21 = m21
        self.m22 = m22
        self.m23 = m23
        self.m30 = m30
        self.m31 = m31
        self.m32 = m32
        self.m33 = m33
    }
}

public struct _GLKQuaternion: Equatable, Hashable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float

    public init(x: Float = 0, y: Float = 0, z: Float = 0, w: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

public struct _GLKVertexAttributeParameters: Equatable, Hashable, Sendable {
    /// GLES `GLenum` width. Named GLES aliases come from OpenGLES when that module is imported.
    public var type: UInt32
    /// GLES `GLint` width.
    public var size: Int32
    /// GLES `GLboolean` width.
    public var normalized: UInt8

    public init(type: UInt32 = 0, size: Int32 = 0, normalized: UInt8 = 0) {
        self.type = type
        self.size = size
        self.normalized = normalized
    }
}

public typealias GLKVector2 = _GLKVector2
public typealias GLKVector3 = _GLKVector3
public typealias GLKVector4 = _GLKVector4
public typealias GLKMatrix2 = _GLKMatrix2
public typealias GLKMatrix3 = _GLKMatrix3
public typealias GLKMatrix4 = _GLKMatrix4
public typealias GLKQuaternion = _GLKQuaternion
public typealias GLKVertexAttributeParameters = _GLKVertexAttributeParameters

extension _GLKMatrix3 {
    subscript(_ index: Int) -> Float {
        get {
            switch index {
            case 0: return m00
            case 1: return m01
            case 2: return m02
            case 3: return m10
            case 4: return m11
            case 5: return m12
            case 6: return m20
            case 7: return m21
            case 8: return m22
            default: return 0
            }
        }
        set {
            switch index {
            case 0: m00 = newValue
            case 1: m01 = newValue
            case 2: m02 = newValue
            case 3: m10 = newValue
            case 4: m11 = newValue
            case 5: m12 = newValue
            case 6: m20 = newValue
            case 7: m21 = newValue
            case 8: m22 = newValue
            default: break
            }
        }
    }
}

extension _GLKMatrix4 {
    subscript(_ index: Int) -> Float {
        get {
            switch index {
            case 0: return m00
            case 1: return m01
            case 2: return m02
            case 3: return m03
            case 4: return m10
            case 5: return m11
            case 6: return m12
            case 7: return m13
            case 8: return m20
            case 9: return m21
            case 10: return m22
            case 11: return m23
            case 12: return m30
            case 13: return m31
            case 14: return m32
            case 15: return m33
            default: return 0
            }
        }
        set {
            switch index {
            case 0: m00 = newValue
            case 1: m01 = newValue
            case 2: m02 = newValue
            case 3: m03 = newValue
            case 4: m10 = newValue
            case 5: m11 = newValue
            case 6: m12 = newValue
            case 7: m13 = newValue
            case 8: m20 = newValue
            case 9: m21 = newValue
            case 10: m22 = newValue
            case 11: m23 = newValue
            case 12: m30 = newValue
            case 13: m31 = newValue
            case 14: m32 = newValue
            case 15: m33 = newValue
            default: break
            }
        }
    }
}
