import Foundation

/// Linux starting point for Apple's public `Metal` module.
///
/// This overlay reconstructs the Swift names from the pinned iPhoneOS 26.1
/// symbol graph. CPU-side types, descriptors, and shared-storage resources are
/// real. GPU families, shader compilation, capture, ray tracing, and
/// Apple-only hardware counters stay fail-closed.

public let MTLCommandBufferErrorDomain = "MTLCommandBufferErrorDomain"
public let MTLLibraryErrorDomain = "MTLLibraryErrorDomain"
public let MTLCaptureErrorDomain = "MTLCaptureErrorDomain"
public let MTLBinaryArchiveDomain = "MTLBinaryArchiveDomain"
public let MTLCounterErrorDomain = "MTLCounterErrorDomain"
public let MTLDynamicLibraryDomain = "MTLDynamicLibraryDomain"
public let MTLIOErrorDomain = "MTLIOErrorDomain"
public let MTLLogStateErrorDomain = "MTLLogStateErrorDomain"
public let MTLTensorDomain = "MTLTensorDomain"
public let MTL4CommandQueueErrorDomain = "MTL4CommandQueueErrorDomain"
public let MTLCommandBufferEncoderInfoErrorKey = "MTLCommandBufferEncoderInfoErrorKey"

public let MTLAttributeStrideStatic: Int = -1
public let MTLBufferLayoutStrideDynamic: Int = -1

public var MTLCounterDontSample: Int { -1 }
public var MTLCounterErrorValue: UInt64 { UInt64.max }
public var MTL_TENSOR_MAX_RANK: Int32 { 16 }

public var MTLResourceCPUCacheModeShift: Int32 { 0 }
public var MTLResourceCPUCacheModeMask: UInt { 0xF }
public var MTLResourceStorageModeShift: Int32 { 4 }
public var MTLResourceStorageModeMask: UInt { 0xF0 }
public var MTLResourceHazardTrackingModeShift: Int32 { 8 }
public var MTLResourceHazardTrackingModeMask: UInt { 0x300 }

public typealias MTLGPUAddress = UInt64
public typealias MTLTimestamp = UInt64
public typealias CFTimeInterval = TimeInterval
public typealias MTLCommandBufferHandler = (any MTLCommandBuffer) -> Void
public typealias MTLDrawablePresentedHandler = (any MTLDrawable) -> Void
public typealias MTLNewLibraryCompletionHandler = ((any MTLLibrary)?, (any Error)?) -> Void
public typealias MTLNewRenderPipelineStateCompletionHandler = ((any MTLRenderPipelineState)?, (any Error)?) -> Void
public typealias MTLNewComputePipelineStateCompletionHandler = ((any MTLComputePipelineState)?, (any Error)?) -> Void
public typealias MTLSharedEventNotificationBlock = (any MTLSharedEvent, UInt64) -> Void
public typealias MTLCoordinate2D = MTLSamplePosition
public typealias MTLPackedFloat3 = _MTLPackedFloat3
public typealias MTLArgumentAccess = MTLBindingAccess

public struct _MTLPackedFloat3: Equatable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float

    public init() {
        self.x = 0
        self.y = 0
        self.z = 0
    }

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(elements: (Float, Float, Float)) {
        self.x = elements.0
        self.y = elements.1
        self.z = elements.2
    }

    public var elements: (Float, Float, Float) {
        get { (x, y, z) }
        set {
            x = newValue.0
            y = newValue.1
            z = newValue.2
        }
    }
}

public func MTLPackedFloat3Make(_ x: Float, _ y: Float, _ z: Float) -> MTLPackedFloat3 {
    MTLPackedFloat3(x: x, y: y, z: z)
}

public struct MTLResourceID: Equatable, Hashable, Sendable {
    public var _impl: UInt64

    public init() {
        self._impl = 0
    }

    internal init(impl: UInt64) {
        self._impl = impl
    }
}

/// Linux has no Apple GPU. The system-default device is a CPU reference
/// adapter that allocates shared buffers/textures, executes blit/compute
/// kernels on the CPU, and refuses shader compilation.
public func MTLCreateSystemDefaultDevice() -> (any MTLDevice)? {
    LinuxMTLDevice.shared
}

public func MTLCopyAllDevices() -> [any MTLDevice] {
    [LinuxMTLDevice.shared]
}

open class MTLArchitecture: NSObject, @unchecked Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
        super.init()
    }
}

func metalUnsupportedLibraryError(
    _ code: MTLLibraryError.Code = .compileFailure,
    reason: String
) -> MTLLibraryError {
    MTLLibraryError(code, userInfo: [NSLocalizedDescriptionKey: reason])
}

func metalBytesPerPixel(_ format: MTLPixelFormat) -> Int? {
    switch format {
    case .invalid:
        return nil
    case .a8Unorm, .r8Unorm, .r8Unorm_srgb, .r8Snorm, .r8Uint, .r8Sint, .stencil8:
        return 1
    case .r16Unorm, .r16Snorm, .r16Uint, .r16Sint, .r16Float,
         .rg8Unorm, .rg8Unorm_srgb, .rg8Snorm, .rg8Uint, .rg8Sint,
         .b5g6r5Unorm, .a1bgr5Unorm, .abgr4Unorm, .bgr5A1Unorm, .depth16Unorm:
        return 2
    case .r32Uint, .r32Sint, .r32Float,
         .rg16Unorm, .rg16Snorm, .rg16Uint, .rg16Sint, .rg16Float,
         .rgba8Unorm, .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint, .rgba8Sint,
         .bgra8Unorm, .bgra8Unorm_srgb,
         .rgb10a2Unorm, .rgb10a2Uint, .rg11b10Float, .rgb9e5Float, .bgr10a2Unorm,
         .depth32Float, .bgr10_xr, .bgr10_xr_srgb:
        return 4
    case .rg32Uint, .rg32Sint, .rg32Float,
         .rgba16Unorm, .rgba16Snorm, .rgba16Uint, .rgba16Sint, .rgba16Float,
         .bgra10_xr, .bgra10_xr_srgb, .depth32Float_stencil8, .x32_stencil8:
        return 8
    case .rgba32Uint, .rgba32Sint, .rgba32Float:
        return 16
    default:
        return nil
    }
}

func metalPixelFormatsAreViewCompatible(_ lhs: MTLPixelFormat, _ rhs: MTLPixelFormat) -> Bool {
    guard let left = metalBytesPerPixel(lhs), let right = metalBytesPerPixel(rhs) else {
        return false
    }
    return left == right
}

func metalSliceCount(textureType: MTLTextureType, arrayLength: Int) -> Int {
    switch textureType {
    case .typeCube:
        return 6
    case .typeCubeArray:
        return 6 * max(arrayLength, 1)
    default:
        return max(arrayLength, 1)
    }
}

func metalArgumentEncodedLength(of type: MTLDataType) -> Int {
    switch type {
    case .none:
        return 0
    case .float, .int, .uint, .bool, .half, .short, .ushort, .char, .uchar,
         .r8Unorm, .r8Snorm:
        return 4
    case .float2, .int2, .uint2, .half2, .short2, .ushort2, .char2, .uchar2,
         .rg8Unorm, .rg8Snorm, .r16Unorm, .r16Snorm:
        return 8
    case .float3, .float4, .int3, .int4, .uint3, .uint4, .half3, .half4,
         .rgba8Unorm, .rgba8Unorm_srgb, .rgba8Snorm, .rgb10a2Unorm, .rg11b10Float,
         .rgb9e5Float, .pointer, .texture, .sampler, .renderPipeline,
         .computePipeline, .indirectCommandBuffer, .long:
        return 16
    default:
        return 16
    }
}
