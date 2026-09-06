import Foundation
import Metal

func testMetalEnumOptionSetAndConstantValues() {
    _ = MTLArgumentBuffersTier.tier1
    precondition(MTLArgumentBuffersTier.tier1.rawValue == 0)
    precondition(MTLArgumentBuffersTier(rawValue: 0) == MTLArgumentBuffersTier.tier1)
    precondition(MTLArgumentBuffersTier.tier2.rawValue == 1)
    precondition(MTLArgumentBuffersTier(rawValue: 1) == MTLArgumentBuffersTier.tier2)
    precondition(MTLArgumentBuffersTier.tier1 != MTLArgumentBuffersTier.tier2)
    var MTLArgumentBuffersTierSet: Set<MTLArgumentBuffersTier> = [.tier1]
    MTLArgumentBuffersTierSet.insert(.tier2)
    precondition(MTLArgumentBuffersTierSet.count == 2)

    _ = MTLArgumentType.buffer
    precondition(MTLArgumentType.buffer.rawValue == 0)
    precondition(MTLArgumentType(rawValue: 0) == MTLArgumentType.buffer)
    precondition(MTLArgumentType.threadgroupMemory.rawValue == 1)
    precondition(MTLArgumentType(rawValue: 1) == MTLArgumentType.threadgroupMemory)
    precondition(MTLArgumentType.texture.rawValue == 2)
    precondition(MTLArgumentType(rawValue: 2) == MTLArgumentType.texture)
    precondition(MTLArgumentType.sampler.rawValue == 3)
    precondition(MTLArgumentType(rawValue: 3) == MTLArgumentType.sampler)
    precondition(MTLArgumentType.imageblockData.rawValue == 16)
    precondition(MTLArgumentType(rawValue: 16) == MTLArgumentType.imageblockData)
    precondition(MTLArgumentType.imageblock.rawValue == 17)
    precondition(MTLArgumentType(rawValue: 17) == MTLArgumentType.imageblock)
    precondition(MTLArgumentType.visibleFunctionTable.rawValue == 24)
    precondition(MTLArgumentType(rawValue: 24) == MTLArgumentType.visibleFunctionTable)
    precondition(MTLArgumentType.primitiveAccelerationStructure.rawValue == 25)
    precondition(MTLArgumentType(rawValue: 25) == MTLArgumentType.primitiveAccelerationStructure)
    precondition(MTLArgumentType.instanceAccelerationStructure.rawValue == 26)
    precondition(MTLArgumentType(rawValue: 26) == MTLArgumentType.instanceAccelerationStructure)
    precondition(MTLArgumentType.intersectionFunctionTable.rawValue == 27)
    precondition(MTLArgumentType(rawValue: 27) == MTLArgumentType.intersectionFunctionTable)
    precondition(MTLArgumentType.buffer != MTLArgumentType.threadgroupMemory)
    var MTLArgumentTypeSet: Set<MTLArgumentType> = [.buffer]
    MTLArgumentTypeSet.insert(.threadgroupMemory)
    precondition(MTLArgumentTypeSet.count == 2)

    _ = MTLAttributeFormat.invalid
    precondition(MTLAttributeFormat.invalid.rawValue == 0)
    precondition(MTLAttributeFormat(rawValue: 0) == MTLAttributeFormat.invalid)
    precondition(MTLAttributeFormat.uchar2.rawValue == 1)
    precondition(MTLAttributeFormat(rawValue: 1) == MTLAttributeFormat.uchar2)
    precondition(MTLAttributeFormat.uchar3.rawValue == 2)
    precondition(MTLAttributeFormat(rawValue: 2) == MTLAttributeFormat.uchar3)
    precondition(MTLAttributeFormat.uchar4.rawValue == 3)
    precondition(MTLAttributeFormat(rawValue: 3) == MTLAttributeFormat.uchar4)
    precondition(MTLAttributeFormat.char2.rawValue == 4)
    precondition(MTLAttributeFormat(rawValue: 4) == MTLAttributeFormat.char2)
    precondition(MTLAttributeFormat.char3.rawValue == 5)
    precondition(MTLAttributeFormat(rawValue: 5) == MTLAttributeFormat.char3)
    precondition(MTLAttributeFormat.char4.rawValue == 6)
    precondition(MTLAttributeFormat(rawValue: 6) == MTLAttributeFormat.char4)
    precondition(MTLAttributeFormat.uchar2Normalized.rawValue == 7)
    precondition(MTLAttributeFormat(rawValue: 7) == MTLAttributeFormat.uchar2Normalized)
    precondition(MTLAttributeFormat.uchar3Normalized.rawValue == 8)
    precondition(MTLAttributeFormat(rawValue: 8) == MTLAttributeFormat.uchar3Normalized)
    precondition(MTLAttributeFormat.uchar4Normalized.rawValue == 9)
    precondition(MTLAttributeFormat(rawValue: 9) == MTLAttributeFormat.uchar4Normalized)
    precondition(MTLAttributeFormat.char2Normalized.rawValue == 10)
    precondition(MTLAttributeFormat(rawValue: 10) == MTLAttributeFormat.char2Normalized)
    precondition(MTLAttributeFormat.char3Normalized.rawValue == 11)
    precondition(MTLAttributeFormat(rawValue: 11) == MTLAttributeFormat.char3Normalized)
    precondition(MTLAttributeFormat.char4Normalized.rawValue == 12)
    precondition(MTLAttributeFormat(rawValue: 12) == MTLAttributeFormat.char4Normalized)
    precondition(MTLAttributeFormat.ushort2.rawValue == 13)
    precondition(MTLAttributeFormat(rawValue: 13) == MTLAttributeFormat.ushort2)
    precondition(MTLAttributeFormat.ushort3.rawValue == 14)
    precondition(MTLAttributeFormat(rawValue: 14) == MTLAttributeFormat.ushort3)
    precondition(MTLAttributeFormat.ushort4.rawValue == 15)
    precondition(MTLAttributeFormat(rawValue: 15) == MTLAttributeFormat.ushort4)
    precondition(MTLAttributeFormat.short2.rawValue == 16)
    precondition(MTLAttributeFormat(rawValue: 16) == MTLAttributeFormat.short2)
    precondition(MTLAttributeFormat.short3.rawValue == 17)
    precondition(MTLAttributeFormat(rawValue: 17) == MTLAttributeFormat.short3)
    precondition(MTLAttributeFormat.short4.rawValue == 18)
    precondition(MTLAttributeFormat(rawValue: 18) == MTLAttributeFormat.short4)
    precondition(MTLAttributeFormat.ushort2Normalized.rawValue == 19)
    precondition(MTLAttributeFormat(rawValue: 19) == MTLAttributeFormat.ushort2Normalized)
    precondition(MTLAttributeFormat.ushort3Normalized.rawValue == 20)
    precondition(MTLAttributeFormat(rawValue: 20) == MTLAttributeFormat.ushort3Normalized)
    precondition(MTLAttributeFormat.ushort4Normalized.rawValue == 21)
    precondition(MTLAttributeFormat(rawValue: 21) == MTLAttributeFormat.ushort4Normalized)
    precondition(MTLAttributeFormat.short2Normalized.rawValue == 22)
    precondition(MTLAttributeFormat(rawValue: 22) == MTLAttributeFormat.short2Normalized)
    precondition(MTLAttributeFormat.short3Normalized.rawValue == 23)
    precondition(MTLAttributeFormat(rawValue: 23) == MTLAttributeFormat.short3Normalized)
    precondition(MTLAttributeFormat.short4Normalized.rawValue == 24)
    precondition(MTLAttributeFormat(rawValue: 24) == MTLAttributeFormat.short4Normalized)
    precondition(MTLAttributeFormat.half2.rawValue == 25)
    precondition(MTLAttributeFormat(rawValue: 25) == MTLAttributeFormat.half2)
    precondition(MTLAttributeFormat.half3.rawValue == 26)
    precondition(MTLAttributeFormat(rawValue: 26) == MTLAttributeFormat.half3)
    precondition(MTLAttributeFormat.half4.rawValue == 27)
    precondition(MTLAttributeFormat(rawValue: 27) == MTLAttributeFormat.half4)
    precondition(MTLAttributeFormat.float.rawValue == 28)
    precondition(MTLAttributeFormat(rawValue: 28) == MTLAttributeFormat.float)
    precondition(MTLAttributeFormat.float2.rawValue == 29)
    precondition(MTLAttributeFormat(rawValue: 29) == MTLAttributeFormat.float2)
    precondition(MTLAttributeFormat.float3.rawValue == 30)
    precondition(MTLAttributeFormat(rawValue: 30) == MTLAttributeFormat.float3)
    precondition(MTLAttributeFormat.float4.rawValue == 31)
    precondition(MTLAttributeFormat(rawValue: 31) == MTLAttributeFormat.float4)
    precondition(MTLAttributeFormat.int.rawValue == 32)
    precondition(MTLAttributeFormat(rawValue: 32) == MTLAttributeFormat.int)
    precondition(MTLAttributeFormat.int2.rawValue == 33)
    precondition(MTLAttributeFormat(rawValue: 33) == MTLAttributeFormat.int2)
    precondition(MTLAttributeFormat.int3.rawValue == 34)
    precondition(MTLAttributeFormat(rawValue: 34) == MTLAttributeFormat.int3)
    precondition(MTLAttributeFormat.int4.rawValue == 35)
    precondition(MTLAttributeFormat(rawValue: 35) == MTLAttributeFormat.int4)
    precondition(MTLAttributeFormat.uint.rawValue == 36)
    precondition(MTLAttributeFormat(rawValue: 36) == MTLAttributeFormat.uint)
    precondition(MTLAttributeFormat.uint2.rawValue == 37)
    precondition(MTLAttributeFormat(rawValue: 37) == MTLAttributeFormat.uint2)
    precondition(MTLAttributeFormat.uint3.rawValue == 38)
    precondition(MTLAttributeFormat(rawValue: 38) == MTLAttributeFormat.uint3)
    precondition(MTLAttributeFormat.uint4.rawValue == 39)
    precondition(MTLAttributeFormat(rawValue: 39) == MTLAttributeFormat.uint4)
    precondition(MTLAttributeFormat.int1010102Normalized.rawValue == 40)
    precondition(MTLAttributeFormat(rawValue: 40) == MTLAttributeFormat.int1010102Normalized)
    precondition(MTLAttributeFormat.uint1010102Normalized.rawValue == 41)
    precondition(MTLAttributeFormat(rawValue: 41) == MTLAttributeFormat.uint1010102Normalized)
    precondition(MTLAttributeFormat.uchar4Normalized_bgra.rawValue == 42)
    precondition(MTLAttributeFormat(rawValue: 42) == MTLAttributeFormat.uchar4Normalized_bgra)
    precondition(MTLAttributeFormat.uchar.rawValue == 45)
    precondition(MTLAttributeFormat(rawValue: 45) == MTLAttributeFormat.uchar)
    precondition(MTLAttributeFormat.char.rawValue == 46)
    precondition(MTLAttributeFormat(rawValue: 46) == MTLAttributeFormat.char)
    precondition(MTLAttributeFormat.ucharNormalized.rawValue == 47)
    precondition(MTLAttributeFormat(rawValue: 47) == MTLAttributeFormat.ucharNormalized)
    precondition(MTLAttributeFormat.charNormalized.rawValue == 48)
    precondition(MTLAttributeFormat(rawValue: 48) == MTLAttributeFormat.charNormalized)
    precondition(MTLAttributeFormat.ushort.rawValue == 49)
    precondition(MTLAttributeFormat(rawValue: 49) == MTLAttributeFormat.ushort)
    precondition(MTLAttributeFormat.short.rawValue == 50)
    precondition(MTLAttributeFormat(rawValue: 50) == MTLAttributeFormat.short)
    precondition(MTLAttributeFormat.ushortNormalized.rawValue == 51)
    precondition(MTLAttributeFormat(rawValue: 51) == MTLAttributeFormat.ushortNormalized)
    precondition(MTLAttributeFormat.shortNormalized.rawValue == 52)
    precondition(MTLAttributeFormat(rawValue: 52) == MTLAttributeFormat.shortNormalized)
    precondition(MTLAttributeFormat.half.rawValue == 53)
    precondition(MTLAttributeFormat(rawValue: 53) == MTLAttributeFormat.half)
    precondition(MTLAttributeFormat.floatRG11B10.rawValue == 54)
    precondition(MTLAttributeFormat(rawValue: 54) == MTLAttributeFormat.floatRG11B10)
    precondition(MTLAttributeFormat.floatRGB9E5.rawValue == 55)
    precondition(MTLAttributeFormat(rawValue: 55) == MTLAttributeFormat.floatRGB9E5)
    precondition(MTLAttributeFormat.invalid != MTLAttributeFormat.uchar2)
    var MTLAttributeFormatSet: Set<MTLAttributeFormat> = [.invalid]
    MTLAttributeFormatSet.insert(.uchar2)
    precondition(MTLAttributeFormatSet.count == 2)

    _ = MTLBindingAccess.readOnly
    precondition(MTLBindingAccess.readOnly.rawValue == 0)
    precondition(MTLBindingAccess(rawValue: 0) == MTLBindingAccess.readOnly)
    precondition(MTLBindingAccess.readWrite.rawValue == 1)
    precondition(MTLBindingAccess(rawValue: 1) == MTLBindingAccess.readWrite)
    precondition(MTLBindingAccess.writeOnly.rawValue == 2)
    precondition(MTLBindingAccess(rawValue: 2) == MTLBindingAccess.writeOnly)
    precondition(MTLBindingAccess.readOnly != MTLBindingAccess.readWrite)
    var MTLBindingAccessSet: Set<MTLBindingAccess> = [.readOnly]
    MTLBindingAccessSet.insert(.readWrite)
    precondition(MTLBindingAccessSet.count == 2)

    _ = MTLBindingType.buffer
    precondition(MTLBindingType.buffer.rawValue == 0)
    precondition(MTLBindingType(rawValue: 0) == MTLBindingType.buffer)
    precondition(MTLBindingType.threadgroupMemory.rawValue == 1)
    precondition(MTLBindingType(rawValue: 1) == MTLBindingType.threadgroupMemory)
    precondition(MTLBindingType.texture.rawValue == 2)
    precondition(MTLBindingType(rawValue: 2) == MTLBindingType.texture)
    precondition(MTLBindingType.sampler.rawValue == 3)
    precondition(MTLBindingType(rawValue: 3) == MTLBindingType.sampler)
    precondition(MTLBindingType.imageblockData.rawValue == 4)
    precondition(MTLBindingType(rawValue: 4) == MTLBindingType.imageblockData)
    precondition(MTLBindingType.imageblock.rawValue == 5)
    precondition(MTLBindingType(rawValue: 5) == MTLBindingType.imageblock)
    precondition(MTLBindingType.visibleFunctionTable.rawValue == 6)
    precondition(MTLBindingType(rawValue: 6) == MTLBindingType.visibleFunctionTable)
    precondition(MTLBindingType.primitiveAccelerationStructure.rawValue == 7)
    precondition(MTLBindingType(rawValue: 7) == MTLBindingType.primitiveAccelerationStructure)
    precondition(MTLBindingType.instanceAccelerationStructure.rawValue == 8)
    precondition(MTLBindingType(rawValue: 8) == MTLBindingType.instanceAccelerationStructure)
    precondition(MTLBindingType.intersectionFunctionTable.rawValue == 9)
    precondition(MTLBindingType(rawValue: 9) == MTLBindingType.intersectionFunctionTable)
    precondition(MTLBindingType.objectPayload.rawValue == 10)
    precondition(MTLBindingType(rawValue: 10) == MTLBindingType.objectPayload)
    precondition(MTLBindingType.tensor.rawValue == 11)
    precondition(MTLBindingType(rawValue: 11) == MTLBindingType.tensor)
    precondition(MTLBindingType.buffer != MTLBindingType.threadgroupMemory)
    var MTLBindingTypeSet: Set<MTLBindingType> = [.buffer]
    MTLBindingTypeSet.insert(.threadgroupMemory)
    precondition(MTLBindingTypeSet.count == 2)

    _ = MTLBlendFactor.zero
    precondition(MTLBlendFactor.zero.rawValue == 0)
    precondition(MTLBlendFactor(rawValue: 0) == MTLBlendFactor.zero)
    precondition(MTLBlendFactor.one.rawValue == 1)
    precondition(MTLBlendFactor(rawValue: 1) == MTLBlendFactor.one)
    precondition(MTLBlendFactor.sourceColor.rawValue == 2)
    precondition(MTLBlendFactor(rawValue: 2) == MTLBlendFactor.sourceColor)
    precondition(MTLBlendFactor.oneMinusSourceColor.rawValue == 3)
    precondition(MTLBlendFactor(rawValue: 3) == MTLBlendFactor.oneMinusSourceColor)
    precondition(MTLBlendFactor.sourceAlpha.rawValue == 4)
    precondition(MTLBlendFactor(rawValue: 4) == MTLBlendFactor.sourceAlpha)
    precondition(MTLBlendFactor.oneMinusSourceAlpha.rawValue == 5)
    precondition(MTLBlendFactor(rawValue: 5) == MTLBlendFactor.oneMinusSourceAlpha)
    precondition(MTLBlendFactor.destinationColor.rawValue == 6)
    precondition(MTLBlendFactor(rawValue: 6) == MTLBlendFactor.destinationColor)
    precondition(MTLBlendFactor.oneMinusDestinationColor.rawValue == 7)
    precondition(MTLBlendFactor(rawValue: 7) == MTLBlendFactor.oneMinusDestinationColor)
    precondition(MTLBlendFactor.destinationAlpha.rawValue == 8)
    precondition(MTLBlendFactor(rawValue: 8) == MTLBlendFactor.destinationAlpha)
    precondition(MTLBlendFactor.oneMinusDestinationAlpha.rawValue == 9)
    precondition(MTLBlendFactor(rawValue: 9) == MTLBlendFactor.oneMinusDestinationAlpha)
    precondition(MTLBlendFactor.sourceAlphaSaturated.rawValue == 10)
    precondition(MTLBlendFactor(rawValue: 10) == MTLBlendFactor.sourceAlphaSaturated)
    precondition(MTLBlendFactor.blendColor.rawValue == 11)
    precondition(MTLBlendFactor(rawValue: 11) == MTLBlendFactor.blendColor)
    precondition(MTLBlendFactor.oneMinusBlendColor.rawValue == 12)
    precondition(MTLBlendFactor(rawValue: 12) == MTLBlendFactor.oneMinusBlendColor)
    precondition(MTLBlendFactor.blendAlpha.rawValue == 13)
    precondition(MTLBlendFactor(rawValue: 13) == MTLBlendFactor.blendAlpha)
    precondition(MTLBlendFactor.oneMinusBlendAlpha.rawValue == 14)
    precondition(MTLBlendFactor(rawValue: 14) == MTLBlendFactor.oneMinusBlendAlpha)
    precondition(MTLBlendFactor.source1Color.rawValue == 15)
    precondition(MTLBlendFactor(rawValue: 15) == MTLBlendFactor.source1Color)
    precondition(MTLBlendFactor.oneMinusSource1Color.rawValue == 16)
    precondition(MTLBlendFactor(rawValue: 16) == MTLBlendFactor.oneMinusSource1Color)
    precondition(MTLBlendFactor.source1Alpha.rawValue == 17)
    precondition(MTLBlendFactor(rawValue: 17) == MTLBlendFactor.source1Alpha)
    precondition(MTLBlendFactor.oneMinusSource1Alpha.rawValue == 18)
    precondition(MTLBlendFactor(rawValue: 18) == MTLBlendFactor.oneMinusSource1Alpha)
    precondition(MTLBlendFactor.zero != MTLBlendFactor.one)
    var MTLBlendFactorSet: Set<MTLBlendFactor> = [.zero]
    MTLBlendFactorSet.insert(.one)
    precondition(MTLBlendFactorSet.count == 2)

    _ = MTLBlendOperation.add
    precondition(MTLBlendOperation.add.rawValue == 0)
    precondition(MTLBlendOperation(rawValue: 0) == MTLBlendOperation.add)
    precondition(MTLBlendOperation.subtract.rawValue == 1)
    precondition(MTLBlendOperation(rawValue: 1) == MTLBlendOperation.subtract)
    precondition(MTLBlendOperation.reverseSubtract.rawValue == 2)
    precondition(MTLBlendOperation(rawValue: 2) == MTLBlendOperation.reverseSubtract)
    precondition(MTLBlendOperation.min.rawValue == 3)
    precondition(MTLBlendOperation(rawValue: 3) == MTLBlendOperation.min)
    precondition(MTLBlendOperation.max.rawValue == 4)
    precondition(MTLBlendOperation(rawValue: 4) == MTLBlendOperation.max)
    precondition(MTLBlendOperation.add != MTLBlendOperation.subtract)
    var MTLBlendOperationSet: Set<MTLBlendOperation> = [.add]
    MTLBlendOperationSet.insert(.subtract)
    precondition(MTLBlendOperationSet.count == 2)

    _ = MTLBufferSparseTier.tierNone
    precondition(MTLBufferSparseTier.tierNone.rawValue == 0)
    precondition(MTLBufferSparseTier(rawValue: 0) == MTLBufferSparseTier.tierNone)
    precondition(MTLBufferSparseTier.tier1.rawValue == 1)
    precondition(MTLBufferSparseTier(rawValue: 1) == MTLBufferSparseTier.tier1)
    precondition(MTLBufferSparseTier.tierNone != MTLBufferSparseTier.tier1)
    var MTLBufferSparseTierSet: Set<MTLBufferSparseTier> = [.tierNone]
    MTLBufferSparseTierSet.insert(.tier1)
    precondition(MTLBufferSparseTierSet.count == 2)

    _ = MTLCPUBuiltinKernel.fillUInt32
    precondition(MTLCPUBuiltinKernel.fillUInt32.rawValue == "openuikit.cpu.fillUInt32")
    precondition(MTLCPUBuiltinKernel(rawValue: "openuikit.cpu.fillUInt32") == MTLCPUBuiltinKernel.fillUInt32)
    precondition(MTLCPUBuiltinKernel.addUInt32.rawValue == "openuikit.cpu.addUInt32")
    precondition(MTLCPUBuiltinKernel(rawValue: "openuikit.cpu.addUInt32") == MTLCPUBuiltinKernel.addUInt32)
    precondition(MTLCPUBuiltinKernel.copyUInt8.rawValue == "openuikit.cpu.copyUInt8")
    precondition(MTLCPUBuiltinKernel(rawValue: "openuikit.cpu.copyUInt8") == MTLCPUBuiltinKernel.copyUInt8)
    precondition(MTLCPUBuiltinKernel.fillUInt32 != MTLCPUBuiltinKernel.addUInt32)
    var MTLCPUBuiltinKernelSet: Set<MTLCPUBuiltinKernel> = [.fillUInt32]
    MTLCPUBuiltinKernelSet.insert(.addUInt32)
    precondition(MTLCPUBuiltinKernelSet.count == 2)

    _ = MTLCPUCacheMode.defaultCache
    precondition(MTLCPUCacheMode.defaultCache.rawValue == 0)
    precondition(MTLCPUCacheMode(rawValue: 0) == MTLCPUCacheMode.defaultCache)
    precondition(MTLCPUCacheMode.writeCombined.rawValue == 1)
    precondition(MTLCPUCacheMode(rawValue: 1) == MTLCPUCacheMode.writeCombined)
    precondition(MTLCPUCacheMode.defaultCache != MTLCPUCacheMode.writeCombined)
    var MTLCPUCacheModeSet: Set<MTLCPUCacheMode> = [.defaultCache]
    MTLCPUCacheModeSet.insert(.writeCombined)
    precondition(MTLCPUCacheModeSet.count == 2)

    _ = MTLCaptureDestination.developerTools
    precondition(MTLCaptureDestination.developerTools.rawValue == 1)
    precondition(MTLCaptureDestination(rawValue: 1) == MTLCaptureDestination.developerTools)
    precondition(MTLCaptureDestination.gpuTraceDocument.rawValue == 2)
    precondition(MTLCaptureDestination(rawValue: 2) == MTLCaptureDestination.gpuTraceDocument)
    precondition(MTLCaptureDestination.developerTools != MTLCaptureDestination.gpuTraceDocument)
    var MTLCaptureDestinationSet: Set<MTLCaptureDestination> = [.developerTools]
    MTLCaptureDestinationSet.insert(.gpuTraceDocument)
    precondition(MTLCaptureDestinationSet.count == 2)

    _ = MTLCaptureError.notSupported
    precondition(MTLCaptureError.notSupported.rawValue == 1)
    precondition(MTLCaptureError(rawValue: 1) == MTLCaptureError.notSupported)
    precondition(MTLCaptureError.alreadyCapturing.rawValue == 2)
    precondition(MTLCaptureError(rawValue: 2) == MTLCaptureError.alreadyCapturing)
    precondition(MTLCaptureError.invalidDescriptor.rawValue == 3)
    precondition(MTLCaptureError(rawValue: 3) == MTLCaptureError.invalidDescriptor)
    precondition(MTLCaptureError.notSupported != MTLCaptureError.alreadyCapturing)
    var MTLCaptureErrorSet: Set<MTLCaptureError> = [.notSupported]
    MTLCaptureErrorSet.insert(.alreadyCapturing)
    precondition(MTLCaptureErrorSet.count == 2)

    _ = MTLCommandBufferError.Code.`none`
    precondition(MTLCommandBufferError.Code.`none`.rawValue == 0)
    precondition(MTLCommandBufferError.Code(rawValue: 0) == MTLCommandBufferError.Code.`none`)
    precondition(MTLCommandBufferError.Code.`internal`.rawValue == 1)
    precondition(MTLCommandBufferError.Code(rawValue: 1) == MTLCommandBufferError.Code.`internal`)
    precondition(MTLCommandBufferError.Code.timeout.rawValue == 2)
    precondition(MTLCommandBufferError.Code(rawValue: 2) == MTLCommandBufferError.Code.timeout)
    precondition(MTLCommandBufferError.Code.pageFault.rawValue == 3)
    precondition(MTLCommandBufferError.Code(rawValue: 3) == MTLCommandBufferError.Code.pageFault)
    precondition(MTLCommandBufferError.Code.blacklisted.rawValue == 4)
    precondition(MTLCommandBufferError.Code(rawValue: 4) == MTLCommandBufferError.Code.blacklisted)
    precondition(MTLCommandBufferError.Code.notPermitted.rawValue == 7)
    precondition(MTLCommandBufferError.Code(rawValue: 7) == MTLCommandBufferError.Code.notPermitted)
    precondition(MTLCommandBufferError.Code.outOfMemory.rawValue == 8)
    precondition(MTLCommandBufferError.Code(rawValue: 8) == MTLCommandBufferError.Code.outOfMemory)
    precondition(MTLCommandBufferError.Code.invalidResource.rawValue == 9)
    precondition(MTLCommandBufferError.Code(rawValue: 9) == MTLCommandBufferError.Code.invalidResource)
    precondition(MTLCommandBufferError.Code.memoryless.rawValue == 10)
    precondition(MTLCommandBufferError.Code(rawValue: 10) == MTLCommandBufferError.Code.memoryless)
    precondition(MTLCommandBufferError.Code.stackOverflow.rawValue == 12)
    precondition(MTLCommandBufferError.Code(rawValue: 12) == MTLCommandBufferError.Code.stackOverflow)
    precondition(MTLCommandBufferError.Code.`none` != MTLCommandBufferError.Code.`internal`)
    var MTLCommandBufferError_CodeSet: Set<MTLCommandBufferError.Code> = [.`none`]
    MTLCommandBufferError_CodeSet.insert(.`internal`)
    precondition(MTLCommandBufferError_CodeSet.count == 2)

    _ = MTLCommandBufferStatus.notEnqueued
    precondition(MTLCommandBufferStatus.notEnqueued.rawValue == 0)
    precondition(MTLCommandBufferStatus(rawValue: 0) == MTLCommandBufferStatus.notEnqueued)
    precondition(MTLCommandBufferStatus.enqueued.rawValue == 1)
    precondition(MTLCommandBufferStatus(rawValue: 1) == MTLCommandBufferStatus.enqueued)
    precondition(MTLCommandBufferStatus.committed.rawValue == 2)
    precondition(MTLCommandBufferStatus(rawValue: 2) == MTLCommandBufferStatus.committed)
    precondition(MTLCommandBufferStatus.scheduled.rawValue == 3)
    precondition(MTLCommandBufferStatus(rawValue: 3) == MTLCommandBufferStatus.scheduled)
    precondition(MTLCommandBufferStatus.completed.rawValue == 4)
    precondition(MTLCommandBufferStatus(rawValue: 4) == MTLCommandBufferStatus.completed)
    precondition(MTLCommandBufferStatus.error.rawValue == 5)
    precondition(MTLCommandBufferStatus(rawValue: 5) == MTLCommandBufferStatus.error)
    precondition(MTLCommandBufferStatus.notEnqueued != MTLCommandBufferStatus.enqueued)
    var MTLCommandBufferStatusSet: Set<MTLCommandBufferStatus> = [.notEnqueued]
    MTLCommandBufferStatusSet.insert(.enqueued)
    precondition(MTLCommandBufferStatusSet.count == 2)

    _ = MTLCompareFunction.never
    precondition(MTLCompareFunction.never.rawValue == 0)
    precondition(MTLCompareFunction(rawValue: 0) == MTLCompareFunction.never)
    precondition(MTLCompareFunction.less.rawValue == 1)
    precondition(MTLCompareFunction(rawValue: 1) == MTLCompareFunction.less)
    precondition(MTLCompareFunction.equal.rawValue == 2)
    precondition(MTLCompareFunction(rawValue: 2) == MTLCompareFunction.equal)
    precondition(MTLCompareFunction.lessEqual.rawValue == 3)
    precondition(MTLCompareFunction(rawValue: 3) == MTLCompareFunction.lessEqual)
    precondition(MTLCompareFunction.greater.rawValue == 4)
    precondition(MTLCompareFunction(rawValue: 4) == MTLCompareFunction.greater)
    precondition(MTLCompareFunction.notEqual.rawValue == 5)
    precondition(MTLCompareFunction(rawValue: 5) == MTLCompareFunction.notEqual)
    precondition(MTLCompareFunction.greaterEqual.rawValue == 6)
    precondition(MTLCompareFunction(rawValue: 6) == MTLCompareFunction.greaterEqual)
    precondition(MTLCompareFunction.always.rawValue == 7)
    precondition(MTLCompareFunction(rawValue: 7) == MTLCompareFunction.always)
    precondition(MTLCompareFunction.never != MTLCompareFunction.less)
    var MTLCompareFunctionSet: Set<MTLCompareFunction> = [.never]
    MTLCompareFunctionSet.insert(.less)
    precondition(MTLCompareFunctionSet.count == 2)

    _ = MTLCompileSymbolVisibility.`default`
    precondition(MTLCompileSymbolVisibility.`default`.rawValue == 0)
    precondition(MTLCompileSymbolVisibility(rawValue: 0) == MTLCompileSymbolVisibility.`default`)
    precondition(MTLCompileSymbolVisibility.hidden.rawValue == 1)
    precondition(MTLCompileSymbolVisibility(rawValue: 1) == MTLCompileSymbolVisibility.hidden)
    precondition(MTLCompileSymbolVisibility.`default` != MTLCompileSymbolVisibility.hidden)
    var MTLCompileSymbolVisibilitySet: Set<MTLCompileSymbolVisibility> = [.`default`]
    MTLCompileSymbolVisibilitySet.insert(.hidden)
    precondition(MTLCompileSymbolVisibilitySet.count == 2)

    _ = MTLCounterSamplingPoint.atStageBoundary
    precondition(MTLCounterSamplingPoint.atStageBoundary.rawValue == 0)
    precondition(MTLCounterSamplingPoint(rawValue: 0) == MTLCounterSamplingPoint.atStageBoundary)
    precondition(MTLCounterSamplingPoint.atDrawBoundary.rawValue == 1)
    precondition(MTLCounterSamplingPoint(rawValue: 1) == MTLCounterSamplingPoint.atDrawBoundary)
    precondition(MTLCounterSamplingPoint.atDispatchBoundary.rawValue == 2)
    precondition(MTLCounterSamplingPoint(rawValue: 2) == MTLCounterSamplingPoint.atDispatchBoundary)
    precondition(MTLCounterSamplingPoint.atTileDispatchBoundary.rawValue == 3)
    precondition(MTLCounterSamplingPoint(rawValue: 3) == MTLCounterSamplingPoint.atTileDispatchBoundary)
    precondition(MTLCounterSamplingPoint.atBlitBoundary.rawValue == 4)
    precondition(MTLCounterSamplingPoint(rawValue: 4) == MTLCounterSamplingPoint.atBlitBoundary)
    precondition(MTLCounterSamplingPoint.atStageBoundary != MTLCounterSamplingPoint.atDrawBoundary)
    var MTLCounterSamplingPointSet: Set<MTLCounterSamplingPoint> = [.atStageBoundary]
    MTLCounterSamplingPointSet.insert(.atDrawBoundary)
    precondition(MTLCounterSamplingPointSet.count == 2)

    _ = MTLCullMode.`none`
    precondition(MTLCullMode.`none`.rawValue == 0)
    precondition(MTLCullMode(rawValue: 0) == MTLCullMode.`none`)
    precondition(MTLCullMode.front.rawValue == 1)
    precondition(MTLCullMode(rawValue: 1) == MTLCullMode.front)
    precondition(MTLCullMode.back.rawValue == 2)
    precondition(MTLCullMode(rawValue: 2) == MTLCullMode.back)
    precondition(MTLCullMode.`none` != MTLCullMode.front)
    var MTLCullModeSet: Set<MTLCullMode> = [.`none`]
    MTLCullModeSet.insert(.front)
    precondition(MTLCullModeSet.count == 2)

    _ = MTLDataType.`none`
    precondition(MTLDataType.`none`.rawValue == 0)
    precondition(MTLDataType(rawValue: 0) == MTLDataType.`none`)
    precondition(MTLDataType.`struct`.rawValue == 1)
    precondition(MTLDataType(rawValue: 1) == MTLDataType.`struct`)
    precondition(MTLDataType.array.rawValue == 2)
    precondition(MTLDataType(rawValue: 2) == MTLDataType.array)
    precondition(MTLDataType.float.rawValue == 3)
    precondition(MTLDataType(rawValue: 3) == MTLDataType.float)
    precondition(MTLDataType.float2.rawValue == 4)
    precondition(MTLDataType(rawValue: 4) == MTLDataType.float2)
    precondition(MTLDataType.float3.rawValue == 5)
    precondition(MTLDataType(rawValue: 5) == MTLDataType.float3)
    precondition(MTLDataType.float4.rawValue == 6)
    precondition(MTLDataType(rawValue: 6) == MTLDataType.float4)
    precondition(MTLDataType.float2x2.rawValue == 7)
    precondition(MTLDataType(rawValue: 7) == MTLDataType.float2x2)
    precondition(MTLDataType.float2x3.rawValue == 8)
    precondition(MTLDataType(rawValue: 8) == MTLDataType.float2x3)
    precondition(MTLDataType.float2x4.rawValue == 9)
    precondition(MTLDataType(rawValue: 9) == MTLDataType.float2x4)
    precondition(MTLDataType.float3x2.rawValue == 10)
    precondition(MTLDataType(rawValue: 10) == MTLDataType.float3x2)
    precondition(MTLDataType.float3x3.rawValue == 11)
    precondition(MTLDataType(rawValue: 11) == MTLDataType.float3x3)
    precondition(MTLDataType.float3x4.rawValue == 12)
    precondition(MTLDataType(rawValue: 12) == MTLDataType.float3x4)
    precondition(MTLDataType.float4x2.rawValue == 13)
    precondition(MTLDataType(rawValue: 13) == MTLDataType.float4x2)
    precondition(MTLDataType.float4x3.rawValue == 14)
    precondition(MTLDataType(rawValue: 14) == MTLDataType.float4x3)
    precondition(MTLDataType.float4x4.rawValue == 15)
    precondition(MTLDataType(rawValue: 15) == MTLDataType.float4x4)
    precondition(MTLDataType.half.rawValue == 16)
    precondition(MTLDataType(rawValue: 16) == MTLDataType.half)
    precondition(MTLDataType.half2.rawValue == 17)
    precondition(MTLDataType(rawValue: 17) == MTLDataType.half2)
    precondition(MTLDataType.half3.rawValue == 18)
    precondition(MTLDataType(rawValue: 18) == MTLDataType.half3)
    precondition(MTLDataType.half4.rawValue == 19)
    precondition(MTLDataType(rawValue: 19) == MTLDataType.half4)
    precondition(MTLDataType.half2x2.rawValue == 20)
    precondition(MTLDataType(rawValue: 20) == MTLDataType.half2x2)
    precondition(MTLDataType.half2x3.rawValue == 21)
    precondition(MTLDataType(rawValue: 21) == MTLDataType.half2x3)
    precondition(MTLDataType.half2x4.rawValue == 22)
    precondition(MTLDataType(rawValue: 22) == MTLDataType.half2x4)
    precondition(MTLDataType.half3x2.rawValue == 23)
    precondition(MTLDataType(rawValue: 23) == MTLDataType.half3x2)
    precondition(MTLDataType.half3x3.rawValue == 24)
    precondition(MTLDataType(rawValue: 24) == MTLDataType.half3x3)
    precondition(MTLDataType.half3x4.rawValue == 25)
    precondition(MTLDataType(rawValue: 25) == MTLDataType.half3x4)
    precondition(MTLDataType.half4x2.rawValue == 26)
    precondition(MTLDataType(rawValue: 26) == MTLDataType.half4x2)
    precondition(MTLDataType.half4x3.rawValue == 27)
    precondition(MTLDataType(rawValue: 27) == MTLDataType.half4x3)
    precondition(MTLDataType.half4x4.rawValue == 28)
    precondition(MTLDataType(rawValue: 28) == MTLDataType.half4x4)
    precondition(MTLDataType.int.rawValue == 29)
    precondition(MTLDataType(rawValue: 29) == MTLDataType.int)
    precondition(MTLDataType.int2.rawValue == 30)
    precondition(MTLDataType(rawValue: 30) == MTLDataType.int2)
    precondition(MTLDataType.int3.rawValue == 31)
    precondition(MTLDataType(rawValue: 31) == MTLDataType.int3)
    precondition(MTLDataType.int4.rawValue == 32)
    precondition(MTLDataType(rawValue: 32) == MTLDataType.int4)
    precondition(MTLDataType.uint.rawValue == 33)
    precondition(MTLDataType(rawValue: 33) == MTLDataType.uint)
    precondition(MTLDataType.uint2.rawValue == 34)
    precondition(MTLDataType(rawValue: 34) == MTLDataType.uint2)
    precondition(MTLDataType.uint3.rawValue == 35)
    precondition(MTLDataType(rawValue: 35) == MTLDataType.uint3)
    precondition(MTLDataType.uint4.rawValue == 36)
    precondition(MTLDataType(rawValue: 36) == MTLDataType.uint4)
    precondition(MTLDataType.short.rawValue == 37)
    precondition(MTLDataType(rawValue: 37) == MTLDataType.short)
    precondition(MTLDataType.short2.rawValue == 38)
    precondition(MTLDataType(rawValue: 38) == MTLDataType.short2)
    precondition(MTLDataType.short3.rawValue == 39)
    precondition(MTLDataType(rawValue: 39) == MTLDataType.short3)
    precondition(MTLDataType.short4.rawValue == 40)
    precondition(MTLDataType(rawValue: 40) == MTLDataType.short4)
    precondition(MTLDataType.ushort.rawValue == 41)
    precondition(MTLDataType(rawValue: 41) == MTLDataType.ushort)
    precondition(MTLDataType.ushort2.rawValue == 42)
    precondition(MTLDataType(rawValue: 42) == MTLDataType.ushort2)
    precondition(MTLDataType.ushort3.rawValue == 43)
    precondition(MTLDataType(rawValue: 43) == MTLDataType.ushort3)
    precondition(MTLDataType.ushort4.rawValue == 44)
    precondition(MTLDataType(rawValue: 44) == MTLDataType.ushort4)
    precondition(MTLDataType.char.rawValue == 45)
    precondition(MTLDataType(rawValue: 45) == MTLDataType.char)
    precondition(MTLDataType.char2.rawValue == 46)
    precondition(MTLDataType(rawValue: 46) == MTLDataType.char2)
    precondition(MTLDataType.char3.rawValue == 47)
    precondition(MTLDataType(rawValue: 47) == MTLDataType.char3)
    precondition(MTLDataType.char4.rawValue == 48)
    precondition(MTLDataType(rawValue: 48) == MTLDataType.char4)
    precondition(MTLDataType.uchar.rawValue == 49)
    precondition(MTLDataType(rawValue: 49) == MTLDataType.uchar)
    precondition(MTLDataType.uchar2.rawValue == 50)
    precondition(MTLDataType(rawValue: 50) == MTLDataType.uchar2)
    precondition(MTLDataType.uchar3.rawValue == 51)
    precondition(MTLDataType(rawValue: 51) == MTLDataType.uchar3)
    precondition(MTLDataType.uchar4.rawValue == 52)
    precondition(MTLDataType(rawValue: 52) == MTLDataType.uchar4)
    precondition(MTLDataType.bool.rawValue == 53)
    precondition(MTLDataType(rawValue: 53) == MTLDataType.bool)
    precondition(MTLDataType.bool2.rawValue == 54)
    precondition(MTLDataType(rawValue: 54) == MTLDataType.bool2)
    precondition(MTLDataType.bool3.rawValue == 55)
    precondition(MTLDataType(rawValue: 55) == MTLDataType.bool3)
    precondition(MTLDataType.bool4.rawValue == 56)
    precondition(MTLDataType(rawValue: 56) == MTLDataType.bool4)
    precondition(MTLDataType.texture.rawValue == 58)
    precondition(MTLDataType(rawValue: 58) == MTLDataType.texture)
    precondition(MTLDataType.sampler.rawValue == 59)
    precondition(MTLDataType(rawValue: 59) == MTLDataType.sampler)
    precondition(MTLDataType.pointer.rawValue == 60)
    precondition(MTLDataType(rawValue: 60) == MTLDataType.pointer)
    precondition(MTLDataType.r8Unorm.rawValue == 62)
    precondition(MTLDataType(rawValue: 62) == MTLDataType.r8Unorm)
    precondition(MTLDataType.r8Snorm.rawValue == 63)
    precondition(MTLDataType(rawValue: 63) == MTLDataType.r8Snorm)
    precondition(MTLDataType.r16Unorm.rawValue == 64)
    precondition(MTLDataType(rawValue: 64) == MTLDataType.r16Unorm)
    precondition(MTLDataType.r16Snorm.rawValue == 65)
    precondition(MTLDataType(rawValue: 65) == MTLDataType.r16Snorm)
    precondition(MTLDataType.rg8Unorm.rawValue == 66)
    precondition(MTLDataType(rawValue: 66) == MTLDataType.rg8Unorm)
    precondition(MTLDataType.rg8Snorm.rawValue == 67)
    precondition(MTLDataType(rawValue: 67) == MTLDataType.rg8Snorm)
    precondition(MTLDataType.rg16Unorm.rawValue == 68)
    precondition(MTLDataType(rawValue: 68) == MTLDataType.rg16Unorm)
    precondition(MTLDataType.rg16Snorm.rawValue == 69)
    precondition(MTLDataType(rawValue: 69) == MTLDataType.rg16Snorm)
    precondition(MTLDataType.rgba8Unorm.rawValue == 70)
    precondition(MTLDataType(rawValue: 70) == MTLDataType.rgba8Unorm)
    precondition(MTLDataType.rgba8Unorm_srgb.rawValue == 71)
    precondition(MTLDataType(rawValue: 71) == MTLDataType.rgba8Unorm_srgb)
    precondition(MTLDataType.rgba8Snorm.rawValue == 72)
    precondition(MTLDataType(rawValue: 72) == MTLDataType.rgba8Snorm)
    precondition(MTLDataType.rgba16Unorm.rawValue == 73)
    precondition(MTLDataType(rawValue: 73) == MTLDataType.rgba16Unorm)
    precondition(MTLDataType.rgba16Snorm.rawValue == 74)
    precondition(MTLDataType(rawValue: 74) == MTLDataType.rgba16Snorm)
    precondition(MTLDataType.rgb10a2Unorm.rawValue == 75)
    precondition(MTLDataType(rawValue: 75) == MTLDataType.rgb10a2Unorm)
    precondition(MTLDataType.rg11b10Float.rawValue == 76)
    precondition(MTLDataType(rawValue: 76) == MTLDataType.rg11b10Float)
    precondition(MTLDataType.rgb9e5Float.rawValue == 77)
    precondition(MTLDataType(rawValue: 77) == MTLDataType.rgb9e5Float)
    precondition(MTLDataType.renderPipeline.rawValue == 78)
    precondition(MTLDataType(rawValue: 78) == MTLDataType.renderPipeline)
    precondition(MTLDataType.computePipeline.rawValue == 79)
    precondition(MTLDataType(rawValue: 79) == MTLDataType.computePipeline)
    precondition(MTLDataType.indirectCommandBuffer.rawValue == 80)
    precondition(MTLDataType(rawValue: 80) == MTLDataType.indirectCommandBuffer)
    precondition(MTLDataType.long.rawValue == 81)
    precondition(MTLDataType(rawValue: 81) == MTLDataType.long)
    precondition(MTLDataType.long2.rawValue == 82)
    precondition(MTLDataType(rawValue: 82) == MTLDataType.long2)
    precondition(MTLDataType.long3.rawValue == 83)
    precondition(MTLDataType(rawValue: 83) == MTLDataType.long3)
    precondition(MTLDataType.long4.rawValue == 84)
    precondition(MTLDataType(rawValue: 84) == MTLDataType.long4)
    precondition(MTLDataType.ulong.rawValue == 85)
    precondition(MTLDataType(rawValue: 85) == MTLDataType.ulong)
    precondition(MTLDataType.ulong2.rawValue == 86)
    precondition(MTLDataType(rawValue: 86) == MTLDataType.ulong2)
    precondition(MTLDataType.ulong3.rawValue == 87)
    precondition(MTLDataType(rawValue: 87) == MTLDataType.ulong3)
    precondition(MTLDataType.ulong4.rawValue == 88)
    precondition(MTLDataType(rawValue: 88) == MTLDataType.ulong4)
    precondition(MTLDataType.visibleFunctionTable.rawValue == 115)
    precondition(MTLDataType(rawValue: 115) == MTLDataType.visibleFunctionTable)
    precondition(MTLDataType.intersectionFunctionTable.rawValue == 116)
    precondition(MTLDataType(rawValue: 116) == MTLDataType.intersectionFunctionTable)
    precondition(MTLDataType.primitiveAccelerationStructure.rawValue == 117)
    precondition(MTLDataType(rawValue: 117) == MTLDataType.primitiveAccelerationStructure)
    precondition(MTLDataType.instanceAccelerationStructure.rawValue == 118)
    precondition(MTLDataType(rawValue: 118) == MTLDataType.instanceAccelerationStructure)
    precondition(MTLDataType.depthStencilState.rawValue == 119)
    precondition(MTLDataType(rawValue: 119) == MTLDataType.depthStencilState)
    precondition(MTLDataType.bfloat.rawValue == 121)
    precondition(MTLDataType(rawValue: 121) == MTLDataType.bfloat)
    precondition(MTLDataType.bfloat2.rawValue == 122)
    precondition(MTLDataType(rawValue: 122) == MTLDataType.bfloat2)
    precondition(MTLDataType.bfloat3.rawValue == 123)
    precondition(MTLDataType(rawValue: 123) == MTLDataType.bfloat3)
    precondition(MTLDataType.bfloat4.rawValue == 124)
    precondition(MTLDataType(rawValue: 124) == MTLDataType.bfloat4)
    precondition(MTLDataType.tensor.rawValue == 125)
    precondition(MTLDataType(rawValue: 125) == MTLDataType.tensor)
    precondition(MTLDataType.`none` != MTLDataType.`struct`)
    var MTLDataTypeSet: Set<MTLDataType> = [.`none`]
    MTLDataTypeSet.insert(.`struct`)
    precondition(MTLDataTypeSet.count == 2)

    _ = MTLDepthClipMode.clip
    precondition(MTLDepthClipMode.clip.rawValue == 0)
    precondition(MTLDepthClipMode(rawValue: 0) == MTLDepthClipMode.clip)
    precondition(MTLDepthClipMode.clamp.rawValue == 1)
    precondition(MTLDepthClipMode(rawValue: 1) == MTLDepthClipMode.clamp)
    precondition(MTLDepthClipMode.clip != MTLDepthClipMode.clamp)
    var MTLDepthClipModeSet: Set<MTLDepthClipMode> = [.clip]
    MTLDepthClipModeSet.insert(.clamp)
    precondition(MTLDepthClipModeSet.count == 2)

    _ = MTLDispatchType.serial
    precondition(MTLDispatchType.serial.rawValue == 0)
    precondition(MTLDispatchType(rawValue: 0) == MTLDispatchType.serial)
    precondition(MTLDispatchType.concurrent.rawValue == 1)
    precondition(MTLDispatchType(rawValue: 1) == MTLDispatchType.concurrent)
    precondition(MTLDispatchType.serial != MTLDispatchType.concurrent)
    var MTLDispatchTypeSet: Set<MTLDispatchType> = [.serial]
    MTLDispatchTypeSet.insert(.concurrent)
    precondition(MTLDispatchTypeSet.count == 2)

    _ = MTLFeatureSet.iOS_GPUFamily1_v1
    precondition(MTLFeatureSet.iOS_GPUFamily1_v1.rawValue == 0)
    precondition(MTLFeatureSet(rawValue: 0) == MTLFeatureSet.iOS_GPUFamily1_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v1.rawValue == 1)
    precondition(MTLFeatureSet(rawValue: 1) == MTLFeatureSet.iOS_GPUFamily2_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v2.rawValue == 2)
    precondition(MTLFeatureSet(rawValue: 2) == MTLFeatureSet.iOS_GPUFamily1_v2)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v2.rawValue == 3)
    precondition(MTLFeatureSet(rawValue: 3) == MTLFeatureSet.iOS_GPUFamily2_v2)
    precondition(MTLFeatureSet.iOS_GPUFamily3_v1.rawValue == 4)
    precondition(MTLFeatureSet(rawValue: 4) == MTLFeatureSet.iOS_GPUFamily3_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v3.rawValue == 5)
    precondition(MTLFeatureSet(rawValue: 5) == MTLFeatureSet.iOS_GPUFamily1_v3)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v3.rawValue == 6)
    precondition(MTLFeatureSet(rawValue: 6) == MTLFeatureSet.iOS_GPUFamily2_v3)
    precondition(MTLFeatureSet.iOS_GPUFamily3_v2.rawValue == 7)
    precondition(MTLFeatureSet(rawValue: 7) == MTLFeatureSet.iOS_GPUFamily3_v2)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v4.rawValue == 8)
    precondition(MTLFeatureSet(rawValue: 8) == MTLFeatureSet.iOS_GPUFamily1_v4)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v4.rawValue == 9)
    precondition(MTLFeatureSet(rawValue: 9) == MTLFeatureSet.iOS_GPUFamily2_v4)
    precondition(MTLFeatureSet.iOS_GPUFamily3_v3.rawValue == 10)
    precondition(MTLFeatureSet(rawValue: 10) == MTLFeatureSet.iOS_GPUFamily3_v3)
    precondition(MTLFeatureSet.iOS_GPUFamily4_v1.rawValue == 11)
    precondition(MTLFeatureSet(rawValue: 11) == MTLFeatureSet.iOS_GPUFamily4_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v5.rawValue == 12)
    precondition(MTLFeatureSet(rawValue: 12) == MTLFeatureSet.iOS_GPUFamily1_v5)
    precondition(MTLFeatureSet.iOS_GPUFamily2_v5.rawValue == 13)
    precondition(MTLFeatureSet(rawValue: 13) == MTLFeatureSet.iOS_GPUFamily2_v5)
    precondition(MTLFeatureSet.iOS_GPUFamily3_v4.rawValue == 14)
    precondition(MTLFeatureSet(rawValue: 14) == MTLFeatureSet.iOS_GPUFamily3_v4)
    precondition(MTLFeatureSet.iOS_GPUFamily4_v2.rawValue == 15)
    precondition(MTLFeatureSet(rawValue: 15) == MTLFeatureSet.iOS_GPUFamily4_v2)
    precondition(MTLFeatureSet.iOS_GPUFamily5_v1.rawValue == 16)
    precondition(MTLFeatureSet(rawValue: 16) == MTLFeatureSet.iOS_GPUFamily5_v1)
    precondition(MTLFeatureSet.iOS_GPUFamily1_v1 != MTLFeatureSet.iOS_GPUFamily2_v1)
    var MTLFeatureSetSet: Set<MTLFeatureSet> = [.iOS_GPUFamily1_v1]
    MTLFeatureSetSet.insert(.iOS_GPUFamily2_v1)
    precondition(MTLFeatureSetSet.count == 2)

    _ = MTLFunctionType.vertex
    precondition(MTLFunctionType.vertex.rawValue == 1)
    precondition(MTLFunctionType(rawValue: 1) == MTLFunctionType.vertex)
    precondition(MTLFunctionType.fragment.rawValue == 2)
    precondition(MTLFunctionType(rawValue: 2) == MTLFunctionType.fragment)
    precondition(MTLFunctionType.kernel.rawValue == 3)
    precondition(MTLFunctionType(rawValue: 3) == MTLFunctionType.kernel)
    precondition(MTLFunctionType.visible.rawValue == 5)
    precondition(MTLFunctionType(rawValue: 5) == MTLFunctionType.visible)
    precondition(MTLFunctionType.intersection.rawValue == 6)
    precondition(MTLFunctionType(rawValue: 6) == MTLFunctionType.intersection)
    precondition(MTLFunctionType.mesh.rawValue == 7)
    precondition(MTLFunctionType(rawValue: 7) == MTLFunctionType.mesh)
    precondition(MTLFunctionType.object.rawValue == 8)
    precondition(MTLFunctionType(rawValue: 8) == MTLFunctionType.object)
    precondition(MTLFunctionType.vertex != MTLFunctionType.fragment)
    var MTLFunctionTypeSet: Set<MTLFunctionType> = [.vertex]
    MTLFunctionTypeSet.insert(.fragment)
    precondition(MTLFunctionTypeSet.count == 2)

    _ = MTLGPUFamily.apple1
    precondition(MTLGPUFamily.apple1.rawValue == 1001)
    precondition(MTLGPUFamily(rawValue: 1001) == MTLGPUFamily.apple1)
    precondition(MTLGPUFamily.apple2.rawValue == 1002)
    precondition(MTLGPUFamily(rawValue: 1002) == MTLGPUFamily.apple2)
    precondition(MTLGPUFamily.apple3.rawValue == 1003)
    precondition(MTLGPUFamily(rawValue: 1003) == MTLGPUFamily.apple3)
    precondition(MTLGPUFamily.apple4.rawValue == 1004)
    precondition(MTLGPUFamily(rawValue: 1004) == MTLGPUFamily.apple4)
    precondition(MTLGPUFamily.apple5.rawValue == 1005)
    precondition(MTLGPUFamily(rawValue: 1005) == MTLGPUFamily.apple5)
    precondition(MTLGPUFamily.apple6.rawValue == 1006)
    precondition(MTLGPUFamily(rawValue: 1006) == MTLGPUFamily.apple6)
    precondition(MTLGPUFamily.apple7.rawValue == 1007)
    precondition(MTLGPUFamily(rawValue: 1007) == MTLGPUFamily.apple7)
    precondition(MTLGPUFamily.apple8.rawValue == 1008)
    precondition(MTLGPUFamily(rawValue: 1008) == MTLGPUFamily.apple8)
    precondition(MTLGPUFamily.apple9.rawValue == 1009)
    precondition(MTLGPUFamily(rawValue: 1009) == MTLGPUFamily.apple9)
    precondition(MTLGPUFamily.apple10.rawValue == 1010)
    precondition(MTLGPUFamily(rawValue: 1010) == MTLGPUFamily.apple10)
    precondition(MTLGPUFamily.mac1.rawValue == 2001)
    precondition(MTLGPUFamily(rawValue: 2001) == MTLGPUFamily.mac1)
    precondition(MTLGPUFamily.mac2.rawValue == 2002)
    precondition(MTLGPUFamily(rawValue: 2002) == MTLGPUFamily.mac2)
    precondition(MTLGPUFamily.common1.rawValue == 3001)
    precondition(MTLGPUFamily(rawValue: 3001) == MTLGPUFamily.common1)
    precondition(MTLGPUFamily.common2.rawValue == 3002)
    precondition(MTLGPUFamily(rawValue: 3002) == MTLGPUFamily.common2)
    precondition(MTLGPUFamily.common3.rawValue == 3003)
    precondition(MTLGPUFamily(rawValue: 3003) == MTLGPUFamily.common3)
    precondition(MTLGPUFamily.macCatalyst1.rawValue == 4001)
    precondition(MTLGPUFamily(rawValue: 4001) == MTLGPUFamily.macCatalyst1)
    precondition(MTLGPUFamily.macCatalyst2.rawValue == 4002)
    precondition(MTLGPUFamily(rawValue: 4002) == MTLGPUFamily.macCatalyst2)
    precondition(MTLGPUFamily.metal3.rawValue == 5001)
    precondition(MTLGPUFamily(rawValue: 5001) == MTLGPUFamily.metal3)
    precondition(MTLGPUFamily.metal4.rawValue == 5002)
    precondition(MTLGPUFamily(rawValue: 5002) == MTLGPUFamily.metal4)
    precondition(MTLGPUFamily.apple1 != MTLGPUFamily.apple2)
    var MTLGPUFamilySet: Set<MTLGPUFamily> = [.apple1]
    MTLGPUFamilySet.insert(.apple2)
    precondition(MTLGPUFamilySet.count == 2)

    _ = MTLHazardTrackingMode.`default`
    precondition(MTLHazardTrackingMode.`default`.rawValue == 0)
    precondition(MTLHazardTrackingMode(rawValue: 0) == MTLHazardTrackingMode.`default`)
    precondition(MTLHazardTrackingMode.untracked.rawValue == 1)
    precondition(MTLHazardTrackingMode(rawValue: 1) == MTLHazardTrackingMode.untracked)
    precondition(MTLHazardTrackingMode.tracked.rawValue == 2)
    precondition(MTLHazardTrackingMode(rawValue: 2) == MTLHazardTrackingMode.tracked)
    precondition(MTLHazardTrackingMode.`default` != MTLHazardTrackingMode.untracked)
    var MTLHazardTrackingModeSet: Set<MTLHazardTrackingMode> = [.`default`]
    MTLHazardTrackingModeSet.insert(.untracked)
    precondition(MTLHazardTrackingModeSet.count == 2)

    _ = MTLHeapType.automatic
    precondition(MTLHeapType.automatic.rawValue == 0)
    precondition(MTLHeapType(rawValue: 0) == MTLHeapType.automatic)
    precondition(MTLHeapType.placement.rawValue == 1)
    precondition(MTLHeapType(rawValue: 1) == MTLHeapType.placement)
    precondition(MTLHeapType.sparse.rawValue == 2)
    precondition(MTLHeapType(rawValue: 2) == MTLHeapType.sparse)
    precondition(MTLHeapType.automatic != MTLHeapType.placement)
    var MTLHeapTypeSet: Set<MTLHeapType> = [.automatic]
    MTLHeapTypeSet.insert(.placement)
    precondition(MTLHeapTypeSet.count == 2)

    _ = MTLIOError.Code.urlInvalid
    precondition(MTLIOError.Code.urlInvalid.rawValue == 1)
    precondition(MTLIOError.Code(rawValue: 1) == MTLIOError.Code.urlInvalid)
    precondition(MTLIOError.Code.`internal`.rawValue == 2)
    precondition(MTLIOError.Code(rawValue: 2) == MTLIOError.Code.`internal`)
    precondition(MTLIOError.Code.urlInvalid != MTLIOError.Code.`internal`)
    var MTLIOError_CodeSet: Set<MTLIOError.Code> = [.urlInvalid]
    MTLIOError_CodeSet.insert(.`internal`)
    precondition(MTLIOError_CodeSet.count == 2)

    _ = MTLIndexType.uint16
    precondition(MTLIndexType.uint16.rawValue == 0)
    precondition(MTLIndexType(rawValue: 0) == MTLIndexType.uint16)
    precondition(MTLIndexType.uint32.rawValue == 1)
    precondition(MTLIndexType(rawValue: 1) == MTLIndexType.uint32)
    precondition(MTLIndexType.uint16 != MTLIndexType.uint32)
    var MTLIndexTypeSet: Set<MTLIndexType> = [.uint16]
    MTLIndexTypeSet.insert(.uint32)
    precondition(MTLIndexTypeSet.count == 2)

    _ = MTLLanguageVersion.version1_0
    precondition(MTLLanguageVersion.version1_0.rawValue == 0x10000)
    precondition(MTLLanguageVersion(rawValue: 0x10000) == MTLLanguageVersion.version1_0)
    precondition(MTLLanguageVersion.version1_1.rawValue == 0x10001)
    precondition(MTLLanguageVersion(rawValue: 0x10001) == MTLLanguageVersion.version1_1)
    precondition(MTLLanguageVersion.version1_2.rawValue == 0x10002)
    precondition(MTLLanguageVersion(rawValue: 0x10002) == MTLLanguageVersion.version1_2)
    precondition(MTLLanguageVersion.version2_0.rawValue == 0x20000)
    precondition(MTLLanguageVersion(rawValue: 0x20000) == MTLLanguageVersion.version2_0)
    precondition(MTLLanguageVersion.version2_1.rawValue == 0x20001)
    precondition(MTLLanguageVersion(rawValue: 0x20001) == MTLLanguageVersion.version2_1)
    precondition(MTLLanguageVersion.version2_2.rawValue == 0x20002)
    precondition(MTLLanguageVersion(rawValue: 0x20002) == MTLLanguageVersion.version2_2)
    precondition(MTLLanguageVersion.version2_3.rawValue == 0x20003)
    precondition(MTLLanguageVersion(rawValue: 0x20003) == MTLLanguageVersion.version2_3)
    precondition(MTLLanguageVersion.version2_4.rawValue == 0x20004)
    precondition(MTLLanguageVersion(rawValue: 0x20004) == MTLLanguageVersion.version2_4)
    precondition(MTLLanguageVersion.version3_0.rawValue == 0x30000)
    precondition(MTLLanguageVersion(rawValue: 0x30000) == MTLLanguageVersion.version3_0)
    precondition(MTLLanguageVersion.version3_1.rawValue == 0x30001)
    precondition(MTLLanguageVersion(rawValue: 0x30001) == MTLLanguageVersion.version3_1)
    precondition(MTLLanguageVersion.version3_2.rawValue == 0x30002)
    precondition(MTLLanguageVersion(rawValue: 0x30002) == MTLLanguageVersion.version3_2)
    precondition(MTLLanguageVersion.version4_0.rawValue == 0x40000)
    precondition(MTLLanguageVersion(rawValue: 0x40000) == MTLLanguageVersion.version4_0)
    precondition(MTLLanguageVersion.version1_0 != MTLLanguageVersion.version1_1)
    var MTLLanguageVersionSet: Set<MTLLanguageVersion> = [.version1_0]
    MTLLanguageVersionSet.insert(.version1_1)
    precondition(MTLLanguageVersionSet.count == 2)

    _ = MTLLibraryError.Code.unsupported
    precondition(MTLLibraryError.Code.unsupported.rawValue == 1)
    precondition(MTLLibraryError.Code(rawValue: 1) == MTLLibraryError.Code.unsupported)
    precondition(MTLLibraryError.Code.`internal`.rawValue == 2)
    precondition(MTLLibraryError.Code(rawValue: 2) == MTLLibraryError.Code.`internal`)
    precondition(MTLLibraryError.Code.compileFailure.rawValue == 3)
    precondition(MTLLibraryError.Code(rawValue: 3) == MTLLibraryError.Code.compileFailure)
    precondition(MTLLibraryError.Code.compileWarning.rawValue == 4)
    precondition(MTLLibraryError.Code(rawValue: 4) == MTLLibraryError.Code.compileWarning)
    precondition(MTLLibraryError.Code.functionNotFound.rawValue == 5)
    precondition(MTLLibraryError.Code(rawValue: 5) == MTLLibraryError.Code.functionNotFound)
    precondition(MTLLibraryError.Code.fileNotFound.rawValue == 6)
    precondition(MTLLibraryError.Code(rawValue: 6) == MTLLibraryError.Code.fileNotFound)
    precondition(MTLLibraryError.Code.unsupported != MTLLibraryError.Code.`internal`)
    var MTLLibraryError_CodeSet: Set<MTLLibraryError.Code> = [.unsupported]
    MTLLibraryError_CodeSet.insert(.`internal`)
    precondition(MTLLibraryError_CodeSet.count == 2)

    _ = MTLLibraryOptimizationLevel.`default`
    precondition(MTLLibraryOptimizationLevel.`default`.rawValue == 0)
    precondition(MTLLibraryOptimizationLevel(rawValue: 0) == MTLLibraryOptimizationLevel.`default`)
    precondition(MTLLibraryOptimizationLevel.size.rawValue == 1)
    precondition(MTLLibraryOptimizationLevel(rawValue: 1) == MTLLibraryOptimizationLevel.size)
    precondition(MTLLibraryOptimizationLevel.`default` != MTLLibraryOptimizationLevel.size)
    var MTLLibraryOptimizationLevelSet: Set<MTLLibraryOptimizationLevel> = [.`default`]
    MTLLibraryOptimizationLevelSet.insert(.size)
    precondition(MTLLibraryOptimizationLevelSet.count == 2)

    _ = MTLLibraryType.executable
    precondition(MTLLibraryType.executable.rawValue == 0)
    precondition(MTLLibraryType(rawValue: 0) == MTLLibraryType.executable)
    precondition(MTLLibraryType.dynamic.rawValue == 1)
    precondition(MTLLibraryType(rawValue: 1) == MTLLibraryType.dynamic)
    precondition(MTLLibraryType.executable != MTLLibraryType.dynamic)
    var MTLLibraryTypeSet: Set<MTLLibraryType> = [.executable]
    MTLLibraryTypeSet.insert(.dynamic)
    precondition(MTLLibraryTypeSet.count == 2)

    _ = MTLLoadAction.dontCare
    precondition(MTLLoadAction.dontCare.rawValue == 0)
    precondition(MTLLoadAction(rawValue: 0) == MTLLoadAction.dontCare)
    precondition(MTLLoadAction.load.rawValue == 1)
    precondition(MTLLoadAction(rawValue: 1) == MTLLoadAction.load)
    precondition(MTLLoadAction.clear.rawValue == 2)
    precondition(MTLLoadAction(rawValue: 2) == MTLLoadAction.clear)
    precondition(MTLLoadAction.dontCare != MTLLoadAction.load)
    var MTLLoadActionSet: Set<MTLLoadAction> = [.dontCare]
    MTLLoadActionSet.insert(.load)
    precondition(MTLLoadActionSet.count == 2)

    _ = MTLMathFloatingPointFunctions.fast
    precondition(MTLMathFloatingPointFunctions.fast.rawValue == 0)
    precondition(MTLMathFloatingPointFunctions(rawValue: 0) == MTLMathFloatingPointFunctions.fast)
    precondition(MTLMathFloatingPointFunctions.precise.rawValue == 1)
    precondition(MTLMathFloatingPointFunctions(rawValue: 1) == MTLMathFloatingPointFunctions.precise)
    precondition(MTLMathFloatingPointFunctions.fast != MTLMathFloatingPointFunctions.precise)
    var MTLMathFloatingPointFunctionsSet: Set<MTLMathFloatingPointFunctions> = [.fast]
    MTLMathFloatingPointFunctionsSet.insert(.precise)
    precondition(MTLMathFloatingPointFunctionsSet.count == 2)

    _ = MTLMathMode.safe
    precondition(MTLMathMode.safe.rawValue == 0)
    precondition(MTLMathMode(rawValue: 0) == MTLMathMode.safe)
    precondition(MTLMathMode.relaxed.rawValue == 1)
    precondition(MTLMathMode(rawValue: 1) == MTLMathMode.relaxed)
    precondition(MTLMathMode.fast.rawValue == 2)
    precondition(MTLMathMode(rawValue: 2) == MTLMathMode.fast)
    precondition(MTLMathMode.safe != MTLMathMode.relaxed)
    var MTLMathModeSet: Set<MTLMathMode> = [.safe]
    MTLMathModeSet.insert(.relaxed)
    precondition(MTLMathModeSet.count == 2)

    _ = MTLMultisampleDepthResolveFilter.sample0
    precondition(MTLMultisampleDepthResolveFilter.sample0.rawValue == 0)
    precondition(MTLMultisampleDepthResolveFilter(rawValue: 0) == MTLMultisampleDepthResolveFilter.sample0)
    precondition(MTLMultisampleDepthResolveFilter.min.rawValue == 1)
    precondition(MTLMultisampleDepthResolveFilter(rawValue: 1) == MTLMultisampleDepthResolveFilter.min)
    precondition(MTLMultisampleDepthResolveFilter.max.rawValue == 2)
    precondition(MTLMultisampleDepthResolveFilter(rawValue: 2) == MTLMultisampleDepthResolveFilter.max)
    precondition(MTLMultisampleDepthResolveFilter.sample0 != MTLMultisampleDepthResolveFilter.min)
    var MTLMultisampleDepthResolveFilterSet: Set<MTLMultisampleDepthResolveFilter> = [.sample0]
    MTLMultisampleDepthResolveFilterSet.insert(.min)
    precondition(MTLMultisampleDepthResolveFilterSet.count == 2)

    _ = MTLMultisampleStencilResolveFilter.sample0
    precondition(MTLMultisampleStencilResolveFilter.sample0.rawValue == 0)
    precondition(MTLMultisampleStencilResolveFilter(rawValue: 0) == MTLMultisampleStencilResolveFilter.sample0)
    precondition(MTLMultisampleStencilResolveFilter.depthResolvedSample.rawValue == 1)
    precondition(MTLMultisampleStencilResolveFilter(rawValue: 1) == MTLMultisampleStencilResolveFilter.depthResolvedSample)
    precondition(MTLMultisampleStencilResolveFilter.sample0 != MTLMultisampleStencilResolveFilter.depthResolvedSample)
    var MTLMultisampleStencilResolveFilterSet: Set<MTLMultisampleStencilResolveFilter> = [.sample0]
    MTLMultisampleStencilResolveFilterSet.insert(.depthResolvedSample)
    precondition(MTLMultisampleStencilResolveFilterSet.count == 2)

    _ = MTLPatchType.`none`
    precondition(MTLPatchType.`none`.rawValue == 0)
    precondition(MTLPatchType(rawValue: 0) == MTLPatchType.`none`)
    precondition(MTLPatchType.triangle.rawValue == 1)
    precondition(MTLPatchType(rawValue: 1) == MTLPatchType.triangle)
    precondition(MTLPatchType.quad.rawValue == 2)
    precondition(MTLPatchType(rawValue: 2) == MTLPatchType.quad)
    precondition(MTLPatchType.`none` != MTLPatchType.triangle)
    var MTLPatchTypeSet: Set<MTLPatchType> = [.`none`]
    MTLPatchTypeSet.insert(.triangle)
    precondition(MTLPatchTypeSet.count == 2)

    _ = MTLPixelFormat.invalid
    precondition(MTLPixelFormat.invalid.rawValue == 0)
    precondition(MTLPixelFormat(rawValue: 0) == MTLPixelFormat.invalid)
    precondition(MTLPixelFormat.a8Unorm.rawValue == 1)
    precondition(MTLPixelFormat(rawValue: 1) == MTLPixelFormat.a8Unorm)
    precondition(MTLPixelFormat.r8Unorm.rawValue == 10)
    precondition(MTLPixelFormat(rawValue: 10) == MTLPixelFormat.r8Unorm)
    precondition(MTLPixelFormat.r8Unorm_srgb.rawValue == 11)
    precondition(MTLPixelFormat(rawValue: 11) == MTLPixelFormat.r8Unorm_srgb)
    precondition(MTLPixelFormat.r8Snorm.rawValue == 12)
    precondition(MTLPixelFormat(rawValue: 12) == MTLPixelFormat.r8Snorm)
    precondition(MTLPixelFormat.r8Uint.rawValue == 13)
    precondition(MTLPixelFormat(rawValue: 13) == MTLPixelFormat.r8Uint)
    precondition(MTLPixelFormat.r8Sint.rawValue == 14)
    precondition(MTLPixelFormat(rawValue: 14) == MTLPixelFormat.r8Sint)
    precondition(MTLPixelFormat.r16Unorm.rawValue == 20)
    precondition(MTLPixelFormat(rawValue: 20) == MTLPixelFormat.r16Unorm)
    precondition(MTLPixelFormat.r16Snorm.rawValue == 22)
    precondition(MTLPixelFormat(rawValue: 22) == MTLPixelFormat.r16Snorm)
    precondition(MTLPixelFormat.r16Uint.rawValue == 23)
    precondition(MTLPixelFormat(rawValue: 23) == MTLPixelFormat.r16Uint)
    precondition(MTLPixelFormat.r16Sint.rawValue == 24)
    precondition(MTLPixelFormat(rawValue: 24) == MTLPixelFormat.r16Sint)
    precondition(MTLPixelFormat.r16Float.rawValue == 25)
    precondition(MTLPixelFormat(rawValue: 25) == MTLPixelFormat.r16Float)
    precondition(MTLPixelFormat.rg8Unorm.rawValue == 30)
    precondition(MTLPixelFormat(rawValue: 30) == MTLPixelFormat.rg8Unorm)
    precondition(MTLPixelFormat.rg8Unorm_srgb.rawValue == 31)
    precondition(MTLPixelFormat(rawValue: 31) == MTLPixelFormat.rg8Unorm_srgb)
    precondition(MTLPixelFormat.rg8Snorm.rawValue == 32)
    precondition(MTLPixelFormat(rawValue: 32) == MTLPixelFormat.rg8Snorm)
    precondition(MTLPixelFormat.rg8Uint.rawValue == 33)
    precondition(MTLPixelFormat(rawValue: 33) == MTLPixelFormat.rg8Uint)
    precondition(MTLPixelFormat.rg8Sint.rawValue == 34)
    precondition(MTLPixelFormat(rawValue: 34) == MTLPixelFormat.rg8Sint)
    precondition(MTLPixelFormat.b5g6r5Unorm.rawValue == 40)
    precondition(MTLPixelFormat(rawValue: 40) == MTLPixelFormat.b5g6r5Unorm)
    precondition(MTLPixelFormat.a1bgr5Unorm.rawValue == 41)
    precondition(MTLPixelFormat(rawValue: 41) == MTLPixelFormat.a1bgr5Unorm)
    precondition(MTLPixelFormat.abgr4Unorm.rawValue == 42)
    precondition(MTLPixelFormat(rawValue: 42) == MTLPixelFormat.abgr4Unorm)
    precondition(MTLPixelFormat.bgr5A1Unorm.rawValue == 43)
    precondition(MTLPixelFormat(rawValue: 43) == MTLPixelFormat.bgr5A1Unorm)
    precondition(MTLPixelFormat.r32Uint.rawValue == 53)
    precondition(MTLPixelFormat(rawValue: 53) == MTLPixelFormat.r32Uint)
    precondition(MTLPixelFormat.r32Sint.rawValue == 54)
    precondition(MTLPixelFormat(rawValue: 54) == MTLPixelFormat.r32Sint)
    precondition(MTLPixelFormat.r32Float.rawValue == 55)
    precondition(MTLPixelFormat(rawValue: 55) == MTLPixelFormat.r32Float)
    precondition(MTLPixelFormat.rg16Unorm.rawValue == 60)
    precondition(MTLPixelFormat(rawValue: 60) == MTLPixelFormat.rg16Unorm)
    precondition(MTLPixelFormat.rg16Snorm.rawValue == 62)
    precondition(MTLPixelFormat(rawValue: 62) == MTLPixelFormat.rg16Snorm)
    precondition(MTLPixelFormat.rg16Uint.rawValue == 63)
    precondition(MTLPixelFormat(rawValue: 63) == MTLPixelFormat.rg16Uint)
    precondition(MTLPixelFormat.rg16Sint.rawValue == 64)
    precondition(MTLPixelFormat(rawValue: 64) == MTLPixelFormat.rg16Sint)
    precondition(MTLPixelFormat.rg16Float.rawValue == 65)
    precondition(MTLPixelFormat(rawValue: 65) == MTLPixelFormat.rg16Float)
    precondition(MTLPixelFormat.rgba8Unorm.rawValue == 70)
    precondition(MTLPixelFormat(rawValue: 70) == MTLPixelFormat.rgba8Unorm)
    precondition(MTLPixelFormat.rgba8Unorm_srgb.rawValue == 71)
    precondition(MTLPixelFormat(rawValue: 71) == MTLPixelFormat.rgba8Unorm_srgb)
    precondition(MTLPixelFormat.rgba8Snorm.rawValue == 72)
    precondition(MTLPixelFormat(rawValue: 72) == MTLPixelFormat.rgba8Snorm)
    precondition(MTLPixelFormat.rgba8Uint.rawValue == 73)
    precondition(MTLPixelFormat(rawValue: 73) == MTLPixelFormat.rgba8Uint)
    precondition(MTLPixelFormat.rgba8Sint.rawValue == 74)
    precondition(MTLPixelFormat(rawValue: 74) == MTLPixelFormat.rgba8Sint)
    precondition(MTLPixelFormat.bgra8Unorm.rawValue == 80)
    precondition(MTLPixelFormat(rawValue: 80) == MTLPixelFormat.bgra8Unorm)
    precondition(MTLPixelFormat.bgra8Unorm_srgb.rawValue == 81)
    precondition(MTLPixelFormat(rawValue: 81) == MTLPixelFormat.bgra8Unorm_srgb)
    precondition(MTLPixelFormat.rgb10a2Unorm.rawValue == 90)
    precondition(MTLPixelFormat(rawValue: 90) == MTLPixelFormat.rgb10a2Unorm)
    precondition(MTLPixelFormat.rgb10a2Uint.rawValue == 91)
    precondition(MTLPixelFormat(rawValue: 91) == MTLPixelFormat.rgb10a2Uint)
    precondition(MTLPixelFormat.rg11b10Float.rawValue == 92)
    precondition(MTLPixelFormat(rawValue: 92) == MTLPixelFormat.rg11b10Float)
    precondition(MTLPixelFormat.rgb9e5Float.rawValue == 93)
    precondition(MTLPixelFormat(rawValue: 93) == MTLPixelFormat.rgb9e5Float)
    precondition(MTLPixelFormat.bgr10a2Unorm.rawValue == 94)
    precondition(MTLPixelFormat(rawValue: 94) == MTLPixelFormat.bgr10a2Unorm)
    precondition(MTLPixelFormat.rg32Uint.rawValue == 103)
    precondition(MTLPixelFormat(rawValue: 103) == MTLPixelFormat.rg32Uint)
    precondition(MTLPixelFormat.rg32Sint.rawValue == 104)
    precondition(MTLPixelFormat(rawValue: 104) == MTLPixelFormat.rg32Sint)
    precondition(MTLPixelFormat.rg32Float.rawValue == 105)
    precondition(MTLPixelFormat(rawValue: 105) == MTLPixelFormat.rg32Float)
    precondition(MTLPixelFormat.rgba16Unorm.rawValue == 110)
    precondition(MTLPixelFormat(rawValue: 110) == MTLPixelFormat.rgba16Unorm)
    precondition(MTLPixelFormat.rgba16Snorm.rawValue == 112)
    precondition(MTLPixelFormat(rawValue: 112) == MTLPixelFormat.rgba16Snorm)
    precondition(MTLPixelFormat.rgba16Uint.rawValue == 113)
    precondition(MTLPixelFormat(rawValue: 113) == MTLPixelFormat.rgba16Uint)
    precondition(MTLPixelFormat.rgba16Sint.rawValue == 114)
    precondition(MTLPixelFormat(rawValue: 114) == MTLPixelFormat.rgba16Sint)
    precondition(MTLPixelFormat.rgba16Float.rawValue == 115)
    precondition(MTLPixelFormat(rawValue: 115) == MTLPixelFormat.rgba16Float)
    precondition(MTLPixelFormat.rgba32Uint.rawValue == 123)
    precondition(MTLPixelFormat(rawValue: 123) == MTLPixelFormat.rgba32Uint)
    precondition(MTLPixelFormat.rgba32Sint.rawValue == 124)
    precondition(MTLPixelFormat(rawValue: 124) == MTLPixelFormat.rgba32Sint)
    precondition(MTLPixelFormat.rgba32Float.rawValue == 125)
    precondition(MTLPixelFormat(rawValue: 125) == MTLPixelFormat.rgba32Float)
    precondition(MTLPixelFormat.bc1_rgba.rawValue == 130)
    precondition(MTLPixelFormat(rawValue: 130) == MTLPixelFormat.bc1_rgba)
    precondition(MTLPixelFormat.bc1_rgba_srgb.rawValue == 131)
    precondition(MTLPixelFormat(rawValue: 131) == MTLPixelFormat.bc1_rgba_srgb)
    precondition(MTLPixelFormat.bc2_rgba.rawValue == 132)
    precondition(MTLPixelFormat(rawValue: 132) == MTLPixelFormat.bc2_rgba)
    precondition(MTLPixelFormat.bc2_rgba_srgb.rawValue == 133)
    precondition(MTLPixelFormat(rawValue: 133) == MTLPixelFormat.bc2_rgba_srgb)
    precondition(MTLPixelFormat.bc3_rgba.rawValue == 134)
    precondition(MTLPixelFormat(rawValue: 134) == MTLPixelFormat.bc3_rgba)
    precondition(MTLPixelFormat.bc3_rgba_srgb.rawValue == 135)
    precondition(MTLPixelFormat(rawValue: 135) == MTLPixelFormat.bc3_rgba_srgb)
    precondition(MTLPixelFormat.bc4_rUnorm.rawValue == 140)
    precondition(MTLPixelFormat(rawValue: 140) == MTLPixelFormat.bc4_rUnorm)
    precondition(MTLPixelFormat.bc4_rSnorm.rawValue == 141)
    precondition(MTLPixelFormat(rawValue: 141) == MTLPixelFormat.bc4_rSnorm)
    precondition(MTLPixelFormat.bc5_rgUnorm.rawValue == 142)
    precondition(MTLPixelFormat(rawValue: 142) == MTLPixelFormat.bc5_rgUnorm)
    precondition(MTLPixelFormat.bc5_rgSnorm.rawValue == 143)
    precondition(MTLPixelFormat(rawValue: 143) == MTLPixelFormat.bc5_rgSnorm)
    precondition(MTLPixelFormat.bc6H_rgbFloat.rawValue == 150)
    precondition(MTLPixelFormat(rawValue: 150) == MTLPixelFormat.bc6H_rgbFloat)
    precondition(MTLPixelFormat.bc6H_rgbuFloat.rawValue == 151)
    precondition(MTLPixelFormat(rawValue: 151) == MTLPixelFormat.bc6H_rgbuFloat)
    precondition(MTLPixelFormat.bc7_rgbaUnorm.rawValue == 152)
    precondition(MTLPixelFormat(rawValue: 152) == MTLPixelFormat.bc7_rgbaUnorm)
    precondition(MTLPixelFormat.bc7_rgbaUnorm_srgb.rawValue == 153)
    precondition(MTLPixelFormat(rawValue: 153) == MTLPixelFormat.bc7_rgbaUnorm_srgb)
    precondition(MTLPixelFormat.pvrtc_rgb_2bpp.rawValue == 160)
    precondition(MTLPixelFormat(rawValue: 160) == MTLPixelFormat.pvrtc_rgb_2bpp)
    precondition(MTLPixelFormat.pvrtc_rgb_2bpp_srgb.rawValue == 161)
    precondition(MTLPixelFormat(rawValue: 161) == MTLPixelFormat.pvrtc_rgb_2bpp_srgb)
    precondition(MTLPixelFormat.pvrtc_rgb_4bpp.rawValue == 162)
    precondition(MTLPixelFormat(rawValue: 162) == MTLPixelFormat.pvrtc_rgb_4bpp)
    precondition(MTLPixelFormat.pvrtc_rgb_4bpp_srgb.rawValue == 163)
    precondition(MTLPixelFormat(rawValue: 163) == MTLPixelFormat.pvrtc_rgb_4bpp_srgb)
    precondition(MTLPixelFormat.pvrtc_rgba_2bpp.rawValue == 164)
    precondition(MTLPixelFormat(rawValue: 164) == MTLPixelFormat.pvrtc_rgba_2bpp)
    precondition(MTLPixelFormat.pvrtc_rgba_2bpp_srgb.rawValue == 165)
    precondition(MTLPixelFormat(rawValue: 165) == MTLPixelFormat.pvrtc_rgba_2bpp_srgb)
    precondition(MTLPixelFormat.pvrtc_rgba_4bpp.rawValue == 166)
    precondition(MTLPixelFormat(rawValue: 166) == MTLPixelFormat.pvrtc_rgba_4bpp)
    precondition(MTLPixelFormat.pvrtc_rgba_4bpp_srgb.rawValue == 167)
    precondition(MTLPixelFormat(rawValue: 167) == MTLPixelFormat.pvrtc_rgba_4bpp_srgb)
    precondition(MTLPixelFormat.eac_r11Unorm.rawValue == 170)
    precondition(MTLPixelFormat(rawValue: 170) == MTLPixelFormat.eac_r11Unorm)
    precondition(MTLPixelFormat.eac_r11Snorm.rawValue == 172)
    precondition(MTLPixelFormat(rawValue: 172) == MTLPixelFormat.eac_r11Snorm)
    precondition(MTLPixelFormat.eac_rg11Unorm.rawValue == 174)
    precondition(MTLPixelFormat(rawValue: 174) == MTLPixelFormat.eac_rg11Unorm)
    precondition(MTLPixelFormat.eac_rg11Snorm.rawValue == 176)
    precondition(MTLPixelFormat(rawValue: 176) == MTLPixelFormat.eac_rg11Snorm)
    precondition(MTLPixelFormat.eac_rgba8.rawValue == 178)
    precondition(MTLPixelFormat(rawValue: 178) == MTLPixelFormat.eac_rgba8)
    precondition(MTLPixelFormat.eac_rgba8_srgb.rawValue == 179)
    precondition(MTLPixelFormat(rawValue: 179) == MTLPixelFormat.eac_rgba8_srgb)
    precondition(MTLPixelFormat.etc2_rgb8.rawValue == 180)
    precondition(MTLPixelFormat(rawValue: 180) == MTLPixelFormat.etc2_rgb8)
    precondition(MTLPixelFormat.etc2_rgb8_srgb.rawValue == 181)
    precondition(MTLPixelFormat(rawValue: 181) == MTLPixelFormat.etc2_rgb8_srgb)
    precondition(MTLPixelFormat.etc2_rgb8a1.rawValue == 182)
    precondition(MTLPixelFormat(rawValue: 182) == MTLPixelFormat.etc2_rgb8a1)
    precondition(MTLPixelFormat.etc2_rgb8a1_srgb.rawValue == 183)
    precondition(MTLPixelFormat(rawValue: 183) == MTLPixelFormat.etc2_rgb8a1_srgb)
    precondition(MTLPixelFormat.astc_4x4_srgb.rawValue == 186)
    precondition(MTLPixelFormat(rawValue: 186) == MTLPixelFormat.astc_4x4_srgb)
    precondition(MTLPixelFormat.astc_5x4_srgb.rawValue == 187)
    precondition(MTLPixelFormat(rawValue: 187) == MTLPixelFormat.astc_5x4_srgb)
    precondition(MTLPixelFormat.astc_5x5_srgb.rawValue == 188)
    precondition(MTLPixelFormat(rawValue: 188) == MTLPixelFormat.astc_5x5_srgb)
    precondition(MTLPixelFormat.astc_6x5_srgb.rawValue == 189)
    precondition(MTLPixelFormat(rawValue: 189) == MTLPixelFormat.astc_6x5_srgb)
    precondition(MTLPixelFormat.astc_6x6_srgb.rawValue == 190)
    precondition(MTLPixelFormat(rawValue: 190) == MTLPixelFormat.astc_6x6_srgb)
    precondition(MTLPixelFormat.astc_8x5_srgb.rawValue == 192)
    precondition(MTLPixelFormat(rawValue: 192) == MTLPixelFormat.astc_8x5_srgb)
    precondition(MTLPixelFormat.astc_8x6_srgb.rawValue == 193)
    precondition(MTLPixelFormat(rawValue: 193) == MTLPixelFormat.astc_8x6_srgb)
    precondition(MTLPixelFormat.astc_8x8_srgb.rawValue == 194)
    precondition(MTLPixelFormat(rawValue: 194) == MTLPixelFormat.astc_8x8_srgb)
    precondition(MTLPixelFormat.astc_10x5_srgb.rawValue == 195)
    precondition(MTLPixelFormat(rawValue: 195) == MTLPixelFormat.astc_10x5_srgb)
    precondition(MTLPixelFormat.astc_10x6_srgb.rawValue == 196)
    precondition(MTLPixelFormat(rawValue: 196) == MTLPixelFormat.astc_10x6_srgb)
    precondition(MTLPixelFormat.astc_10x8_srgb.rawValue == 197)
    precondition(MTLPixelFormat(rawValue: 197) == MTLPixelFormat.astc_10x8_srgb)
    precondition(MTLPixelFormat.astc_10x10_srgb.rawValue == 198)
    precondition(MTLPixelFormat(rawValue: 198) == MTLPixelFormat.astc_10x10_srgb)
    precondition(MTLPixelFormat.astc_12x10_srgb.rawValue == 199)
    precondition(MTLPixelFormat(rawValue: 199) == MTLPixelFormat.astc_12x10_srgb)
    precondition(MTLPixelFormat.astc_12x12_srgb.rawValue == 200)
    precondition(MTLPixelFormat(rawValue: 200) == MTLPixelFormat.astc_12x12_srgb)
    precondition(MTLPixelFormat.astc_4x4_ldr.rawValue == 204)
    precondition(MTLPixelFormat(rawValue: 204) == MTLPixelFormat.astc_4x4_ldr)
    precondition(MTLPixelFormat.astc_5x4_ldr.rawValue == 205)
    precondition(MTLPixelFormat(rawValue: 205) == MTLPixelFormat.astc_5x4_ldr)
    precondition(MTLPixelFormat.astc_5x5_ldr.rawValue == 206)
    precondition(MTLPixelFormat(rawValue: 206) == MTLPixelFormat.astc_5x5_ldr)
    precondition(MTLPixelFormat.astc_6x5_ldr.rawValue == 207)
    precondition(MTLPixelFormat(rawValue: 207) == MTLPixelFormat.astc_6x5_ldr)
    precondition(MTLPixelFormat.astc_6x6_ldr.rawValue == 208)
    precondition(MTLPixelFormat(rawValue: 208) == MTLPixelFormat.astc_6x6_ldr)
    precondition(MTLPixelFormat.astc_8x5_ldr.rawValue == 210)
    precondition(MTLPixelFormat(rawValue: 210) == MTLPixelFormat.astc_8x5_ldr)
    precondition(MTLPixelFormat.astc_8x6_ldr.rawValue == 211)
    precondition(MTLPixelFormat(rawValue: 211) == MTLPixelFormat.astc_8x6_ldr)
    precondition(MTLPixelFormat.astc_8x8_ldr.rawValue == 212)
    precondition(MTLPixelFormat(rawValue: 212) == MTLPixelFormat.astc_8x8_ldr)
    precondition(MTLPixelFormat.astc_10x5_ldr.rawValue == 213)
    precondition(MTLPixelFormat(rawValue: 213) == MTLPixelFormat.astc_10x5_ldr)
    precondition(MTLPixelFormat.astc_10x6_ldr.rawValue == 214)
    precondition(MTLPixelFormat(rawValue: 214) == MTLPixelFormat.astc_10x6_ldr)
    precondition(MTLPixelFormat.astc_10x8_ldr.rawValue == 215)
    precondition(MTLPixelFormat(rawValue: 215) == MTLPixelFormat.astc_10x8_ldr)
    precondition(MTLPixelFormat.astc_10x10_ldr.rawValue == 216)
    precondition(MTLPixelFormat(rawValue: 216) == MTLPixelFormat.astc_10x10_ldr)
    precondition(MTLPixelFormat.astc_12x10_ldr.rawValue == 217)
    precondition(MTLPixelFormat(rawValue: 217) == MTLPixelFormat.astc_12x10_ldr)
    precondition(MTLPixelFormat.astc_12x12_ldr.rawValue == 218)
    precondition(MTLPixelFormat(rawValue: 218) == MTLPixelFormat.astc_12x12_ldr)
    precondition(MTLPixelFormat.astc_4x4_hdr.rawValue == 222)
    precondition(MTLPixelFormat(rawValue: 222) == MTLPixelFormat.astc_4x4_hdr)
    precondition(MTLPixelFormat.astc_5x4_hdr.rawValue == 223)
    precondition(MTLPixelFormat(rawValue: 223) == MTLPixelFormat.astc_5x4_hdr)
    precondition(MTLPixelFormat.astc_5x5_hdr.rawValue == 224)
    precondition(MTLPixelFormat(rawValue: 224) == MTLPixelFormat.astc_5x5_hdr)
    precondition(MTLPixelFormat.astc_6x5_hdr.rawValue == 225)
    precondition(MTLPixelFormat(rawValue: 225) == MTLPixelFormat.astc_6x5_hdr)
    precondition(MTLPixelFormat.astc_6x6_hdr.rawValue == 226)
    precondition(MTLPixelFormat(rawValue: 226) == MTLPixelFormat.astc_6x6_hdr)
    precondition(MTLPixelFormat.astc_8x5_hdr.rawValue == 228)
    precondition(MTLPixelFormat(rawValue: 228) == MTLPixelFormat.astc_8x5_hdr)
    precondition(MTLPixelFormat.astc_8x6_hdr.rawValue == 229)
    precondition(MTLPixelFormat(rawValue: 229) == MTLPixelFormat.astc_8x6_hdr)
    precondition(MTLPixelFormat.astc_8x8_hdr.rawValue == 230)
    precondition(MTLPixelFormat(rawValue: 230) == MTLPixelFormat.astc_8x8_hdr)
    precondition(MTLPixelFormat.astc_10x5_hdr.rawValue == 231)
    precondition(MTLPixelFormat(rawValue: 231) == MTLPixelFormat.astc_10x5_hdr)
    precondition(MTLPixelFormat.astc_10x6_hdr.rawValue == 232)
    precondition(MTLPixelFormat(rawValue: 232) == MTLPixelFormat.astc_10x6_hdr)
    precondition(MTLPixelFormat.astc_10x8_hdr.rawValue == 233)
    precondition(MTLPixelFormat(rawValue: 233) == MTLPixelFormat.astc_10x8_hdr)
    precondition(MTLPixelFormat.astc_10x10_hdr.rawValue == 234)
    precondition(MTLPixelFormat(rawValue: 234) == MTLPixelFormat.astc_10x10_hdr)
    precondition(MTLPixelFormat.astc_12x10_hdr.rawValue == 235)
    precondition(MTLPixelFormat(rawValue: 235) == MTLPixelFormat.astc_12x10_hdr)
    precondition(MTLPixelFormat.astc_12x12_hdr.rawValue == 236)
    precondition(MTLPixelFormat(rawValue: 236) == MTLPixelFormat.astc_12x12_hdr)
    precondition(MTLPixelFormat.gbgr422.rawValue == 240)
    precondition(MTLPixelFormat(rawValue: 240) == MTLPixelFormat.gbgr422)
    precondition(MTLPixelFormat.bgrg422.rawValue == 241)
    precondition(MTLPixelFormat(rawValue: 241) == MTLPixelFormat.bgrg422)
    precondition(MTLPixelFormat.depth16Unorm.rawValue == 250)
    precondition(MTLPixelFormat(rawValue: 250) == MTLPixelFormat.depth16Unorm)
    precondition(MTLPixelFormat.depth32Float.rawValue == 252)
    precondition(MTLPixelFormat(rawValue: 252) == MTLPixelFormat.depth32Float)
    precondition(MTLPixelFormat.stencil8.rawValue == 253)
    precondition(MTLPixelFormat(rawValue: 253) == MTLPixelFormat.stencil8)
    precondition(MTLPixelFormat.depth32Float_stencil8.rawValue == 260)
    precondition(MTLPixelFormat(rawValue: 260) == MTLPixelFormat.depth32Float_stencil8)
    precondition(MTLPixelFormat.x32_stencil8.rawValue == 261)
    precondition(MTLPixelFormat(rawValue: 261) == MTLPixelFormat.x32_stencil8)
    precondition(MTLPixelFormat.bgra10_xr.rawValue == 552)
    precondition(MTLPixelFormat(rawValue: 552) == MTLPixelFormat.bgra10_xr)
    precondition(MTLPixelFormat.bgra10_xr_srgb.rawValue == 553)
    precondition(MTLPixelFormat(rawValue: 553) == MTLPixelFormat.bgra10_xr_srgb)
    precondition(MTLPixelFormat.bgr10_xr.rawValue == 554)
    precondition(MTLPixelFormat(rawValue: 554) == MTLPixelFormat.bgr10_xr)
    precondition(MTLPixelFormat.bgr10_xr_srgb.rawValue == 555)
    precondition(MTLPixelFormat(rawValue: 555) == MTLPixelFormat.bgr10_xr_srgb)
    precondition(MTLPixelFormat.invalid != MTLPixelFormat.a8Unorm)
    var MTLPixelFormatSet: Set<MTLPixelFormat> = [.invalid]
    MTLPixelFormatSet.insert(.a8Unorm)
    precondition(MTLPixelFormatSet.count == 2)

    _ = MTLPrimitiveType.point
    precondition(MTLPrimitiveType.point.rawValue == 0)
    precondition(MTLPrimitiveType(rawValue: 0) == MTLPrimitiveType.point)
    precondition(MTLPrimitiveType.line.rawValue == 1)
    precondition(MTLPrimitiveType(rawValue: 1) == MTLPrimitiveType.line)
    precondition(MTLPrimitiveType.lineStrip.rawValue == 2)
    precondition(MTLPrimitiveType(rawValue: 2) == MTLPrimitiveType.lineStrip)
    precondition(MTLPrimitiveType.triangle.rawValue == 3)
    precondition(MTLPrimitiveType(rawValue: 3) == MTLPrimitiveType.triangle)
    precondition(MTLPrimitiveType.triangleStrip.rawValue == 4)
    precondition(MTLPrimitiveType(rawValue: 4) == MTLPrimitiveType.triangleStrip)
    precondition(MTLPrimitiveType.point != MTLPrimitiveType.line)
    var MTLPrimitiveTypeSet: Set<MTLPrimitiveType> = [.point]
    MTLPrimitiveTypeSet.insert(.line)
    precondition(MTLPrimitiveTypeSet.count == 2)

    _ = MTLPurgeableState.keepCurrent
    precondition(MTLPurgeableState.keepCurrent.rawValue == 1)
    precondition(MTLPurgeableState(rawValue: 1) == MTLPurgeableState.keepCurrent)
    precondition(MTLPurgeableState.nonVolatile.rawValue == 2)
    precondition(MTLPurgeableState(rawValue: 2) == MTLPurgeableState.nonVolatile)
    precondition(MTLPurgeableState.volatile.rawValue == 3)
    precondition(MTLPurgeableState(rawValue: 3) == MTLPurgeableState.volatile)
    precondition(MTLPurgeableState.empty.rawValue == 4)
    precondition(MTLPurgeableState(rawValue: 4) == MTLPurgeableState.empty)
    precondition(MTLPurgeableState.keepCurrent != MTLPurgeableState.nonVolatile)
    var MTLPurgeableStateSet: Set<MTLPurgeableState> = [.keepCurrent]
    MTLPurgeableStateSet.insert(.nonVolatile)
    precondition(MTLPurgeableStateSet.count == 2)

    _ = MTLReadWriteTextureTier.tierNone
    precondition(MTLReadWriteTextureTier.tierNone.rawValue == 0)
    precondition(MTLReadWriteTextureTier(rawValue: 0) == MTLReadWriteTextureTier.tierNone)
    precondition(MTLReadWriteTextureTier.tier1.rawValue == 1)
    precondition(MTLReadWriteTextureTier(rawValue: 1) == MTLReadWriteTextureTier.tier1)
    precondition(MTLReadWriteTextureTier.tier2.rawValue == 2)
    precondition(MTLReadWriteTextureTier(rawValue: 2) == MTLReadWriteTextureTier.tier2)
    precondition(MTLReadWriteTextureTier.tierNone != MTLReadWriteTextureTier.tier1)
    var MTLReadWriteTextureTierSet: Set<MTLReadWriteTextureTier> = [.tierNone]
    MTLReadWriteTextureTierSet.insert(.tier1)
    precondition(MTLReadWriteTextureTierSet.count == 2)

    _ = MTLSamplerAddressMode.clampToEdge
    precondition(MTLSamplerAddressMode.clampToEdge.rawValue == 0)
    precondition(MTLSamplerAddressMode(rawValue: 0) == MTLSamplerAddressMode.clampToEdge)
    precondition(MTLSamplerAddressMode.mirrorClampToEdge.rawValue == 1)
    precondition(MTLSamplerAddressMode(rawValue: 1) == MTLSamplerAddressMode.mirrorClampToEdge)
    precondition(MTLSamplerAddressMode.`repeat`.rawValue == 2)
    precondition(MTLSamplerAddressMode(rawValue: 2) == MTLSamplerAddressMode.`repeat`)
    precondition(MTLSamplerAddressMode.mirrorRepeat.rawValue == 3)
    precondition(MTLSamplerAddressMode(rawValue: 3) == MTLSamplerAddressMode.mirrorRepeat)
    precondition(MTLSamplerAddressMode.clampToZero.rawValue == 4)
    precondition(MTLSamplerAddressMode(rawValue: 4) == MTLSamplerAddressMode.clampToZero)
    precondition(MTLSamplerAddressMode.clampToBorderColor.rawValue == 5)
    precondition(MTLSamplerAddressMode(rawValue: 5) == MTLSamplerAddressMode.clampToBorderColor)
    precondition(MTLSamplerAddressMode.clampToEdge != MTLSamplerAddressMode.mirrorClampToEdge)
    var MTLSamplerAddressModeSet: Set<MTLSamplerAddressMode> = [.clampToEdge]
    MTLSamplerAddressModeSet.insert(.mirrorClampToEdge)
    precondition(MTLSamplerAddressModeSet.count == 2)

    _ = MTLSamplerBorderColor.transparentBlack
    precondition(MTLSamplerBorderColor.transparentBlack.rawValue == 0)
    precondition(MTLSamplerBorderColor(rawValue: 0) == MTLSamplerBorderColor.transparentBlack)
    precondition(MTLSamplerBorderColor.opaqueBlack.rawValue == 1)
    precondition(MTLSamplerBorderColor(rawValue: 1) == MTLSamplerBorderColor.opaqueBlack)
    precondition(MTLSamplerBorderColor.opaqueWhite.rawValue == 2)
    precondition(MTLSamplerBorderColor(rawValue: 2) == MTLSamplerBorderColor.opaqueWhite)
    precondition(MTLSamplerBorderColor.transparentBlack != MTLSamplerBorderColor.opaqueBlack)
    var MTLSamplerBorderColorSet: Set<MTLSamplerBorderColor> = [.transparentBlack]
    MTLSamplerBorderColorSet.insert(.opaqueBlack)
    precondition(MTLSamplerBorderColorSet.count == 2)

    _ = MTLSamplerMinMagFilter.nearest
    precondition(MTLSamplerMinMagFilter.nearest.rawValue == 0)
    precondition(MTLSamplerMinMagFilter(rawValue: 0) == MTLSamplerMinMagFilter.nearest)
    precondition(MTLSamplerMinMagFilter.linear.rawValue == 1)
    precondition(MTLSamplerMinMagFilter(rawValue: 1) == MTLSamplerMinMagFilter.linear)
    precondition(MTLSamplerMinMagFilter.nearest != MTLSamplerMinMagFilter.linear)
    var MTLSamplerMinMagFilterSet: Set<MTLSamplerMinMagFilter> = [.nearest]
    MTLSamplerMinMagFilterSet.insert(.linear)
    precondition(MTLSamplerMinMagFilterSet.count == 2)

    _ = MTLSamplerMipFilter.notMipmapped
    precondition(MTLSamplerMipFilter.notMipmapped.rawValue == 0)
    precondition(MTLSamplerMipFilter(rawValue: 0) == MTLSamplerMipFilter.notMipmapped)
    precondition(MTLSamplerMipFilter.nearest.rawValue == 1)
    precondition(MTLSamplerMipFilter(rawValue: 1) == MTLSamplerMipFilter.nearest)
    precondition(MTLSamplerMipFilter.linear.rawValue == 2)
    precondition(MTLSamplerMipFilter(rawValue: 2) == MTLSamplerMipFilter.linear)
    precondition(MTLSamplerMipFilter.notMipmapped != MTLSamplerMipFilter.nearest)
    var MTLSamplerMipFilterSet: Set<MTLSamplerMipFilter> = [.notMipmapped]
    MTLSamplerMipFilterSet.insert(.nearest)
    precondition(MTLSamplerMipFilterSet.count == 2)

    _ = MTLSamplerReductionMode.weightedAverage
    precondition(MTLSamplerReductionMode.weightedAverage.rawValue == 0)
    precondition(MTLSamplerReductionMode(rawValue: 0) == MTLSamplerReductionMode.weightedAverage)
    precondition(MTLSamplerReductionMode.minimum.rawValue == 1)
    precondition(MTLSamplerReductionMode(rawValue: 1) == MTLSamplerReductionMode.minimum)
    precondition(MTLSamplerReductionMode.maximum.rawValue == 2)
    precondition(MTLSamplerReductionMode(rawValue: 2) == MTLSamplerReductionMode.maximum)
    precondition(MTLSamplerReductionMode.weightedAverage != MTLSamplerReductionMode.minimum)
    var MTLSamplerReductionModeSet: Set<MTLSamplerReductionMode> = [.weightedAverage]
    MTLSamplerReductionModeSet.insert(.minimum)
    precondition(MTLSamplerReductionModeSet.count == 2)

    _ = MTLShaderValidation.`default`
    precondition(MTLShaderValidation.`default`.rawValue == 0)
    precondition(MTLShaderValidation(rawValue: 0) == MTLShaderValidation.`default`)
    precondition(MTLShaderValidation.enabled.rawValue == 1)
    precondition(MTLShaderValidation(rawValue: 1) == MTLShaderValidation.enabled)
    precondition(MTLShaderValidation.disabled.rawValue == 2)
    precondition(MTLShaderValidation(rawValue: 2) == MTLShaderValidation.disabled)
    precondition(MTLShaderValidation.`default` != MTLShaderValidation.enabled)
    var MTLShaderValidationSet: Set<MTLShaderValidation> = [.`default`]
    MTLShaderValidationSet.insert(.enabled)
    precondition(MTLShaderValidationSet.count == 2)

    _ = MTLSparsePageSize.size16
    precondition(MTLSparsePageSize.size16.rawValue == 16)
    precondition(MTLSparsePageSize(rawValue: 16) == MTLSparsePageSize.size16)
    precondition(MTLSparsePageSize.size64.rawValue == 64)
    precondition(MTLSparsePageSize(rawValue: 64) == MTLSparsePageSize.size64)
    precondition(MTLSparsePageSize.size256.rawValue == 256)
    precondition(MTLSparsePageSize(rawValue: 256) == MTLSparsePageSize.size256)
    precondition(MTLSparsePageSize.size16 != MTLSparsePageSize.size64)
    var MTLSparsePageSizeSet: Set<MTLSparsePageSize> = [.size16]
    MTLSparsePageSizeSet.insert(.size64)
    precondition(MTLSparsePageSizeSet.count == 2)

    _ = MTLSparseTextureMappingMode.map
    precondition(MTLSparseTextureMappingMode.map.rawValue == 0)
    precondition(MTLSparseTextureMappingMode(rawValue: 0) == MTLSparseTextureMappingMode.map)
    precondition(MTLSparseTextureMappingMode.unmap.rawValue == 1)
    precondition(MTLSparseTextureMappingMode(rawValue: 1) == MTLSparseTextureMappingMode.unmap)
    precondition(MTLSparseTextureMappingMode.map != MTLSparseTextureMappingMode.unmap)
    var MTLSparseTextureMappingModeSet: Set<MTLSparseTextureMappingMode> = [.map]
    MTLSparseTextureMappingModeSet.insert(.unmap)
    precondition(MTLSparseTextureMappingModeSet.count == 2)

    _ = MTLStencilOperation.keep
    precondition(MTLStencilOperation.keep.rawValue == 0)
    precondition(MTLStencilOperation(rawValue: 0) == MTLStencilOperation.keep)
    precondition(MTLStencilOperation.zero.rawValue == 1)
    precondition(MTLStencilOperation(rawValue: 1) == MTLStencilOperation.zero)
    precondition(MTLStencilOperation.replace.rawValue == 2)
    precondition(MTLStencilOperation(rawValue: 2) == MTLStencilOperation.replace)
    precondition(MTLStencilOperation.incrementClamp.rawValue == 3)
    precondition(MTLStencilOperation(rawValue: 3) == MTLStencilOperation.incrementClamp)
    precondition(MTLStencilOperation.decrementClamp.rawValue == 4)
    precondition(MTLStencilOperation(rawValue: 4) == MTLStencilOperation.decrementClamp)
    precondition(MTLStencilOperation.invert.rawValue == 5)
    precondition(MTLStencilOperation(rawValue: 5) == MTLStencilOperation.invert)
    precondition(MTLStencilOperation.incrementWrap.rawValue == 6)
    precondition(MTLStencilOperation(rawValue: 6) == MTLStencilOperation.incrementWrap)
    precondition(MTLStencilOperation.decrementWrap.rawValue == 7)
    precondition(MTLStencilOperation(rawValue: 7) == MTLStencilOperation.decrementWrap)
    precondition(MTLStencilOperation.keep != MTLStencilOperation.zero)
    var MTLStencilOperationSet: Set<MTLStencilOperation> = [.keep]
    MTLStencilOperationSet.insert(.zero)
    precondition(MTLStencilOperationSet.count == 2)

    _ = MTLStorageMode.shared
    precondition(MTLStorageMode.shared.rawValue == 0)
    precondition(MTLStorageMode(rawValue: 0) == MTLStorageMode.shared)
    precondition(MTLStorageMode.`private`.rawValue == 2)
    precondition(MTLStorageMode(rawValue: 2) == MTLStorageMode.`private`)
    precondition(MTLStorageMode.memoryless.rawValue == 3)
    precondition(MTLStorageMode(rawValue: 3) == MTLStorageMode.memoryless)
    precondition(MTLStorageMode.shared != MTLStorageMode.`private`)
    var MTLStorageModeSet: Set<MTLStorageMode> = [.shared]
    MTLStorageModeSet.insert(.`private`)
    precondition(MTLStorageModeSet.count == 2)

    _ = MTLStoreAction.dontCare
    precondition(MTLStoreAction.dontCare.rawValue == 0)
    precondition(MTLStoreAction(rawValue: 0) == MTLStoreAction.dontCare)
    precondition(MTLStoreAction.store.rawValue == 1)
    precondition(MTLStoreAction(rawValue: 1) == MTLStoreAction.store)
    precondition(MTLStoreAction.multisampleResolve.rawValue == 2)
    precondition(MTLStoreAction(rawValue: 2) == MTLStoreAction.multisampleResolve)
    precondition(MTLStoreAction.storeAndMultisampleResolve.rawValue == 3)
    precondition(MTLStoreAction(rawValue: 3) == MTLStoreAction.storeAndMultisampleResolve)
    precondition(MTLStoreAction.unknown.rawValue == 4)
    precondition(MTLStoreAction(rawValue: 4) == MTLStoreAction.unknown)
    precondition(MTLStoreAction.customSampleDepthStore.rawValue == 5)
    precondition(MTLStoreAction(rawValue: 5) == MTLStoreAction.customSampleDepthStore)
    precondition(MTLStoreAction.dontCare != MTLStoreAction.store)
    var MTLStoreActionSet: Set<MTLStoreAction> = [.dontCare]
    MTLStoreActionSet.insert(.store)
    precondition(MTLStoreActionSet.count == 2)

    _ = MTLTextureCompressionType.lossless
    precondition(MTLTextureCompressionType.lossless.rawValue == 0)
    precondition(MTLTextureCompressionType(rawValue: 0) == MTLTextureCompressionType.lossless)
    precondition(MTLTextureCompressionType.lossy.rawValue == 1)
    precondition(MTLTextureCompressionType(rawValue: 1) == MTLTextureCompressionType.lossy)
    precondition(MTLTextureCompressionType.lossless != MTLTextureCompressionType.lossy)
    var MTLTextureCompressionTypeSet: Set<MTLTextureCompressionType> = [.lossless]
    MTLTextureCompressionTypeSet.insert(.lossy)
    precondition(MTLTextureCompressionTypeSet.count == 2)

    _ = MTLTextureSparseTier.tierNone
    precondition(MTLTextureSparseTier.tierNone.rawValue == 0)
    precondition(MTLTextureSparseTier(rawValue: 0) == MTLTextureSparseTier.tierNone)
    precondition(MTLTextureSparseTier.tier1.rawValue == 1)
    precondition(MTLTextureSparseTier(rawValue: 1) == MTLTextureSparseTier.tier1)
    precondition(MTLTextureSparseTier.tier2.rawValue == 2)
    precondition(MTLTextureSparseTier(rawValue: 2) == MTLTextureSparseTier.tier2)
    precondition(MTLTextureSparseTier.tierNone != MTLTextureSparseTier.tier1)
    var MTLTextureSparseTierSet: Set<MTLTextureSparseTier> = [.tierNone]
    MTLTextureSparseTierSet.insert(.tier1)
    precondition(MTLTextureSparseTierSet.count == 2)

    _ = MTLTextureSwizzle.zero
    precondition(MTLTextureSwizzle.zero.rawValue == 0)
    precondition(MTLTextureSwizzle(rawValue: 0) == MTLTextureSwizzle.zero)
    precondition(MTLTextureSwizzle.one.rawValue == 1)
    precondition(MTLTextureSwizzle(rawValue: 1) == MTLTextureSwizzle.one)
    precondition(MTLTextureSwizzle.red.rawValue == 2)
    precondition(MTLTextureSwizzle(rawValue: 2) == MTLTextureSwizzle.red)
    precondition(MTLTextureSwizzle.green.rawValue == 3)
    precondition(MTLTextureSwizzle(rawValue: 3) == MTLTextureSwizzle.green)
    precondition(MTLTextureSwizzle.blue.rawValue == 4)
    precondition(MTLTextureSwizzle(rawValue: 4) == MTLTextureSwizzle.blue)
    precondition(MTLTextureSwizzle.alpha.rawValue == 5)
    precondition(MTLTextureSwizzle(rawValue: 5) == MTLTextureSwizzle.alpha)
    precondition(MTLTextureSwizzle.zero != MTLTextureSwizzle.one)
    var MTLTextureSwizzleSet: Set<MTLTextureSwizzle> = [.zero]
    MTLTextureSwizzleSet.insert(.one)
    precondition(MTLTextureSwizzleSet.count == 2)

    _ = MTLTextureType.type1D
    precondition(MTLTextureType.type1D.rawValue == 0)
    precondition(MTLTextureType(rawValue: 0) == MTLTextureType.type1D)
    precondition(MTLTextureType.type1DArray.rawValue == 1)
    precondition(MTLTextureType(rawValue: 1) == MTLTextureType.type1DArray)
    precondition(MTLTextureType.type2D.rawValue == 2)
    precondition(MTLTextureType(rawValue: 2) == MTLTextureType.type2D)
    precondition(MTLTextureType.type2DArray.rawValue == 3)
    precondition(MTLTextureType(rawValue: 3) == MTLTextureType.type2DArray)
    precondition(MTLTextureType.type2DMultisample.rawValue == 4)
    precondition(MTLTextureType(rawValue: 4) == MTLTextureType.type2DMultisample)
    precondition(MTLTextureType.typeCube.rawValue == 5)
    precondition(MTLTextureType(rawValue: 5) == MTLTextureType.typeCube)
    precondition(MTLTextureType.typeCubeArray.rawValue == 6)
    precondition(MTLTextureType(rawValue: 6) == MTLTextureType.typeCubeArray)
    precondition(MTLTextureType.type3D.rawValue == 7)
    precondition(MTLTextureType(rawValue: 7) == MTLTextureType.type3D)
    precondition(MTLTextureType.type2DMultisampleArray.rawValue == 8)
    precondition(MTLTextureType(rawValue: 8) == MTLTextureType.type2DMultisampleArray)
    precondition(MTLTextureType.typeTextureBuffer.rawValue == 9)
    precondition(MTLTextureType(rawValue: 9) == MTLTextureType.typeTextureBuffer)
    precondition(MTLTextureType.type1D != MTLTextureType.type1DArray)
    var MTLTextureTypeSet: Set<MTLTextureType> = [.type1D]
    MTLTextureTypeSet.insert(.type1DArray)
    precondition(MTLTextureTypeSet.count == 2)

    _ = MTLTriangleFillMode.fill
    precondition(MTLTriangleFillMode.fill.rawValue == 0)
    precondition(MTLTriangleFillMode(rawValue: 0) == MTLTriangleFillMode.fill)
    precondition(MTLTriangleFillMode.lines.rawValue == 1)
    precondition(MTLTriangleFillMode(rawValue: 1) == MTLTriangleFillMode.lines)
    precondition(MTLTriangleFillMode.fill != MTLTriangleFillMode.lines)
    var MTLTriangleFillModeSet: Set<MTLTriangleFillMode> = [.fill]
    MTLTriangleFillModeSet.insert(.lines)
    precondition(MTLTriangleFillModeSet.count == 2)

    _ = MTLVertexFormat.invalid
    precondition(MTLVertexFormat.invalid.rawValue == 0)
    precondition(MTLVertexFormat(rawValue: 0) == MTLVertexFormat.invalid)
    precondition(MTLVertexFormat.uchar2.rawValue == 1)
    precondition(MTLVertexFormat(rawValue: 1) == MTLVertexFormat.uchar2)
    precondition(MTLVertexFormat.uchar3.rawValue == 2)
    precondition(MTLVertexFormat(rawValue: 2) == MTLVertexFormat.uchar3)
    precondition(MTLVertexFormat.uchar4.rawValue == 3)
    precondition(MTLVertexFormat(rawValue: 3) == MTLVertexFormat.uchar4)
    precondition(MTLVertexFormat.char2.rawValue == 4)
    precondition(MTLVertexFormat(rawValue: 4) == MTLVertexFormat.char2)
    precondition(MTLVertexFormat.char3.rawValue == 5)
    precondition(MTLVertexFormat(rawValue: 5) == MTLVertexFormat.char3)
    precondition(MTLVertexFormat.char4.rawValue == 6)
    precondition(MTLVertexFormat(rawValue: 6) == MTLVertexFormat.char4)
    precondition(MTLVertexFormat.uchar2Normalized.rawValue == 7)
    precondition(MTLVertexFormat(rawValue: 7) == MTLVertexFormat.uchar2Normalized)
    precondition(MTLVertexFormat.uchar3Normalized.rawValue == 8)
    precondition(MTLVertexFormat(rawValue: 8) == MTLVertexFormat.uchar3Normalized)
    precondition(MTLVertexFormat.uchar4Normalized.rawValue == 9)
    precondition(MTLVertexFormat(rawValue: 9) == MTLVertexFormat.uchar4Normalized)
    precondition(MTLVertexFormat.char2Normalized.rawValue == 10)
    precondition(MTLVertexFormat(rawValue: 10) == MTLVertexFormat.char2Normalized)
    precondition(MTLVertexFormat.char3Normalized.rawValue == 11)
    precondition(MTLVertexFormat(rawValue: 11) == MTLVertexFormat.char3Normalized)
    precondition(MTLVertexFormat.char4Normalized.rawValue == 12)
    precondition(MTLVertexFormat(rawValue: 12) == MTLVertexFormat.char4Normalized)
    precondition(MTLVertexFormat.ushort2.rawValue == 13)
    precondition(MTLVertexFormat(rawValue: 13) == MTLVertexFormat.ushort2)
    precondition(MTLVertexFormat.ushort3.rawValue == 14)
    precondition(MTLVertexFormat(rawValue: 14) == MTLVertexFormat.ushort3)
    precondition(MTLVertexFormat.ushort4.rawValue == 15)
    precondition(MTLVertexFormat(rawValue: 15) == MTLVertexFormat.ushort4)
    precondition(MTLVertexFormat.short2.rawValue == 16)
    precondition(MTLVertexFormat(rawValue: 16) == MTLVertexFormat.short2)
    precondition(MTLVertexFormat.short3.rawValue == 17)
    precondition(MTLVertexFormat(rawValue: 17) == MTLVertexFormat.short3)
    precondition(MTLVertexFormat.short4.rawValue == 18)
    precondition(MTLVertexFormat(rawValue: 18) == MTLVertexFormat.short4)
    precondition(MTLVertexFormat.ushort2Normalized.rawValue == 19)
    precondition(MTLVertexFormat(rawValue: 19) == MTLVertexFormat.ushort2Normalized)
    precondition(MTLVertexFormat.ushort3Normalized.rawValue == 20)
    precondition(MTLVertexFormat(rawValue: 20) == MTLVertexFormat.ushort3Normalized)
    precondition(MTLVertexFormat.ushort4Normalized.rawValue == 21)
    precondition(MTLVertexFormat(rawValue: 21) == MTLVertexFormat.ushort4Normalized)
    precondition(MTLVertexFormat.short2Normalized.rawValue == 22)
    precondition(MTLVertexFormat(rawValue: 22) == MTLVertexFormat.short2Normalized)
    precondition(MTLVertexFormat.short3Normalized.rawValue == 23)
    precondition(MTLVertexFormat(rawValue: 23) == MTLVertexFormat.short3Normalized)
    precondition(MTLVertexFormat.short4Normalized.rawValue == 24)
    precondition(MTLVertexFormat(rawValue: 24) == MTLVertexFormat.short4Normalized)
    precondition(MTLVertexFormat.half2.rawValue == 25)
    precondition(MTLVertexFormat(rawValue: 25) == MTLVertexFormat.half2)
    precondition(MTLVertexFormat.half3.rawValue == 26)
    precondition(MTLVertexFormat(rawValue: 26) == MTLVertexFormat.half3)
    precondition(MTLVertexFormat.half4.rawValue == 27)
    precondition(MTLVertexFormat(rawValue: 27) == MTLVertexFormat.half4)
    precondition(MTLVertexFormat.float.rawValue == 28)
    precondition(MTLVertexFormat(rawValue: 28) == MTLVertexFormat.float)
    precondition(MTLVertexFormat.float2.rawValue == 29)
    precondition(MTLVertexFormat(rawValue: 29) == MTLVertexFormat.float2)
    precondition(MTLVertexFormat.float3.rawValue == 30)
    precondition(MTLVertexFormat(rawValue: 30) == MTLVertexFormat.float3)
    precondition(MTLVertexFormat.float4.rawValue == 31)
    precondition(MTLVertexFormat(rawValue: 31) == MTLVertexFormat.float4)
    precondition(MTLVertexFormat.int.rawValue == 32)
    precondition(MTLVertexFormat(rawValue: 32) == MTLVertexFormat.int)
    precondition(MTLVertexFormat.int2.rawValue == 33)
    precondition(MTLVertexFormat(rawValue: 33) == MTLVertexFormat.int2)
    precondition(MTLVertexFormat.int3.rawValue == 34)
    precondition(MTLVertexFormat(rawValue: 34) == MTLVertexFormat.int3)
    precondition(MTLVertexFormat.int4.rawValue == 35)
    precondition(MTLVertexFormat(rawValue: 35) == MTLVertexFormat.int4)
    precondition(MTLVertexFormat.uint.rawValue == 36)
    precondition(MTLVertexFormat(rawValue: 36) == MTLVertexFormat.uint)
    precondition(MTLVertexFormat.uint2.rawValue == 37)
    precondition(MTLVertexFormat(rawValue: 37) == MTLVertexFormat.uint2)
    precondition(MTLVertexFormat.uint3.rawValue == 38)
    precondition(MTLVertexFormat(rawValue: 38) == MTLVertexFormat.uint3)
    precondition(MTLVertexFormat.uint4.rawValue == 39)
    precondition(MTLVertexFormat(rawValue: 39) == MTLVertexFormat.uint4)
    precondition(MTLVertexFormat.int1010102Normalized.rawValue == 40)
    precondition(MTLVertexFormat(rawValue: 40) == MTLVertexFormat.int1010102Normalized)
    precondition(MTLVertexFormat.uint1010102Normalized.rawValue == 41)
    precondition(MTLVertexFormat(rawValue: 41) == MTLVertexFormat.uint1010102Normalized)
    precondition(MTLVertexFormat.uchar4Normalized_bgra.rawValue == 42)
    precondition(MTLVertexFormat(rawValue: 42) == MTLVertexFormat.uchar4Normalized_bgra)
    precondition(MTLVertexFormat.uchar.rawValue == 45)
    precondition(MTLVertexFormat(rawValue: 45) == MTLVertexFormat.uchar)
    precondition(MTLVertexFormat.char.rawValue == 46)
    precondition(MTLVertexFormat(rawValue: 46) == MTLVertexFormat.char)
    precondition(MTLVertexFormat.ucharNormalized.rawValue == 47)
    precondition(MTLVertexFormat(rawValue: 47) == MTLVertexFormat.ucharNormalized)
    precondition(MTLVertexFormat.charNormalized.rawValue == 48)
    precondition(MTLVertexFormat(rawValue: 48) == MTLVertexFormat.charNormalized)
    precondition(MTLVertexFormat.ushort.rawValue == 49)
    precondition(MTLVertexFormat(rawValue: 49) == MTLVertexFormat.ushort)
    precondition(MTLVertexFormat.short.rawValue == 50)
    precondition(MTLVertexFormat(rawValue: 50) == MTLVertexFormat.short)
    precondition(MTLVertexFormat.ushortNormalized.rawValue == 51)
    precondition(MTLVertexFormat(rawValue: 51) == MTLVertexFormat.ushortNormalized)
    precondition(MTLVertexFormat.shortNormalized.rawValue == 52)
    precondition(MTLVertexFormat(rawValue: 52) == MTLVertexFormat.shortNormalized)
    precondition(MTLVertexFormat.half.rawValue == 53)
    precondition(MTLVertexFormat(rawValue: 53) == MTLVertexFormat.half)
    precondition(MTLVertexFormat.floatRG11B10.rawValue == 54)
    precondition(MTLVertexFormat(rawValue: 54) == MTLVertexFormat.floatRG11B10)
    precondition(MTLVertexFormat.floatRGB9E5.rawValue == 55)
    precondition(MTLVertexFormat(rawValue: 55) == MTLVertexFormat.floatRGB9E5)
    precondition(MTLVertexFormat.invalid != MTLVertexFormat.uchar2)
    var MTLVertexFormatSet: Set<MTLVertexFormat> = [.invalid]
    MTLVertexFormatSet.insert(.uchar2)
    precondition(MTLVertexFormatSet.count == 2)

    _ = MTLVertexStepFunction.constant
    precondition(MTLVertexStepFunction.constant.rawValue == 0)
    precondition(MTLVertexStepFunction(rawValue: 0) == MTLVertexStepFunction.constant)
    precondition(MTLVertexStepFunction.perVertex.rawValue == 1)
    precondition(MTLVertexStepFunction(rawValue: 1) == MTLVertexStepFunction.perVertex)
    precondition(MTLVertexStepFunction.perInstance.rawValue == 2)
    precondition(MTLVertexStepFunction(rawValue: 2) == MTLVertexStepFunction.perInstance)
    precondition(MTLVertexStepFunction.perPatch.rawValue == 3)
    precondition(MTLVertexStepFunction(rawValue: 3) == MTLVertexStepFunction.perPatch)
    precondition(MTLVertexStepFunction.perPatchControlPoint.rawValue == 4)
    precondition(MTLVertexStepFunction(rawValue: 4) == MTLVertexStepFunction.perPatchControlPoint)
    precondition(MTLVertexStepFunction.constant != MTLVertexStepFunction.perVertex)
    var MTLVertexStepFunctionSet: Set<MTLVertexStepFunction> = [.constant]
    MTLVertexStepFunctionSet.insert(.perVertex)
    precondition(MTLVertexStepFunctionSet.count == 2)

    _ = MTLVisibilityResultMode.disabled
    precondition(MTLVisibilityResultMode.disabled.rawValue == 0)
    precondition(MTLVisibilityResultMode(rawValue: 0) == MTLVisibilityResultMode.disabled)
    precondition(MTLVisibilityResultMode.boolean.rawValue == 1)
    precondition(MTLVisibilityResultMode(rawValue: 1) == MTLVisibilityResultMode.boolean)
    precondition(MTLVisibilityResultMode.counting.rawValue == 2)
    precondition(MTLVisibilityResultMode(rawValue: 2) == MTLVisibilityResultMode.counting)
    precondition(MTLVisibilityResultMode.disabled != MTLVisibilityResultMode.boolean)
    var MTLVisibilityResultModeSet: Set<MTLVisibilityResultMode> = [.disabled]
    MTLVisibilityResultModeSet.insert(.boolean)
    precondition(MTLVisibilityResultModeSet.count == 2)

    _ = MTLVisibilityResultType.reset
    precondition(MTLVisibilityResultType.reset.rawValue == 0)
    precondition(MTLVisibilityResultType(rawValue: 0) == MTLVisibilityResultType.reset)
    precondition(MTLVisibilityResultType.accumulate.rawValue == 1)
    precondition(MTLVisibilityResultType(rawValue: 1) == MTLVisibilityResultType.accumulate)
    precondition(MTLVisibilityResultType.reset != MTLVisibilityResultType.accumulate)
    var MTLVisibilityResultTypeSet: Set<MTLVisibilityResultType> = [.reset]
    MTLVisibilityResultTypeSet.insert(.accumulate)
    precondition(MTLVisibilityResultTypeSet.count == 2)

    _ = MTLWinding.clockwise
    precondition(MTLWinding.clockwise.rawValue == 0)
    precondition(MTLWinding(rawValue: 0) == MTLWinding.clockwise)
    precondition(MTLWinding.counterClockwise.rawValue == 1)
    precondition(MTLWinding(rawValue: 1) == MTLWinding.counterClockwise)
    precondition(MTLWinding.clockwise != MTLWinding.counterClockwise)
    var MTLWindingSet: Set<MTLWinding> = [.clockwise]
    MTLWindingSet.insert(.counterClockwise)
    precondition(MTLWindingSet.count == 2)

    var MTLBarrierScopeValue = MTLBarrierScope.buffers
    precondition(MTLBarrierScopeValue.contains(.buffers))
    MTLBarrierScopeValue.formUnion(.textures)
    precondition(MTLBarrierScopeValue.contains(.textures))
    _ = MTLBarrierScope.buffers
    _ = MTLBarrierScope.textures
    _ = MTLBarrierScope(rawValue: MTLBarrierScopeValue.rawValue)

    var MTLBlitOptionValue = MTLBlitOption.depthFromDepthStencil
    precondition(MTLBlitOptionValue.contains(.depthFromDepthStencil))
    MTLBlitOptionValue.formUnion(.stencilFromDepthStencil)
    precondition(MTLBlitOptionValue.contains(.stencilFromDepthStencil))
    _ = MTLBlitOption.depthFromDepthStencil
    _ = MTLBlitOption.stencilFromDepthStencil
    _ = MTLBlitOption.rowLinearPVRTC
    _ = MTLBlitOption(rawValue: MTLBlitOptionValue.rawValue)

    var MTLColorWriteMaskValue = MTLColorWriteMask.red
    precondition(MTLColorWriteMaskValue.contains(.red))
    MTLColorWriteMaskValue.formUnion(.green)
    precondition(MTLColorWriteMaskValue.contains(.green))
    _ = MTLColorWriteMask.red
    _ = MTLColorWriteMask.green
    _ = MTLColorWriteMask.blue
    _ = MTLColorWriteMask.alpha
    _ = MTLColorWriteMask.all
    _ = MTLColorWriteMask(rawValue: MTLColorWriteMaskValue.rawValue)

    let MTLCommandBufferErrorOptionValue = MTLCommandBufferErrorOption.encoderExecutionStatus
    precondition(MTLCommandBufferErrorOptionValue.contains(.encoderExecutionStatus))
    _ = MTLCommandBufferErrorOption.encoderExecutionStatus
    _ = MTLCommandBufferErrorOption(rawValue: MTLCommandBufferErrorOptionValue.rawValue)

    var MTLFunctionOptionsValue = MTLFunctionOptions.compileToBinary
    precondition(MTLFunctionOptionsValue.contains(.compileToBinary))
    MTLFunctionOptionsValue.formUnion(.storeFunctionInMetalPipelinesScript)
    precondition(MTLFunctionOptionsValue.contains(.storeFunctionInMetalPipelinesScript))
    _ = MTLFunctionOptions.compileToBinary
    _ = MTLFunctionOptions.storeFunctionInMetalPipelinesScript
    _ = MTLFunctionOptions.storeFunctionInMetalScript
    _ = MTLFunctionOptions.failOnBinaryArchiveMiss
    _ = MTLFunctionOptions.pipelineIndependent
    _ = MTLFunctionOptions(rawValue: MTLFunctionOptionsValue.rawValue)

    var MTLIndirectCommandTypeValue = MTLIndirectCommandType.draw
    precondition(MTLIndirectCommandTypeValue.contains(.draw))
    MTLIndirectCommandTypeValue.formUnion(.drawIndexed)
    precondition(MTLIndirectCommandTypeValue.contains(.drawIndexed))
    _ = MTLIndirectCommandType.draw
    _ = MTLIndirectCommandType.drawIndexed
    _ = MTLIndirectCommandType.drawPatches
    _ = MTLIndirectCommandType.drawIndexedPatches
    _ = MTLIndirectCommandType.concurrentDispatch
    _ = MTLIndirectCommandType.concurrentDispatchThreads
    _ = MTLIndirectCommandType.drawMeshThreadgroups
    _ = MTLIndirectCommandType.drawMeshThreads
    _ = MTLIndirectCommandType(rawValue: MTLIndirectCommandTypeValue.rawValue)

    var MTLPipelineOptionValue = MTLPipelineOption.argumentInfo
    precondition(MTLPipelineOptionValue.contains(.argumentInfo))
    MTLPipelineOptionValue.formUnion(.bindingInfo)
    precondition(MTLPipelineOptionValue.contains(.bindingInfo))
    _ = MTLPipelineOption.argumentInfo
    _ = MTLPipelineOption.bindingInfo
    _ = MTLPipelineOption.bufferTypeInfo
    _ = MTLPipelineOption.failOnBinaryArchiveMiss
    _ = MTLPipelineOption(rawValue: MTLPipelineOptionValue.rawValue)

    var MTLRenderStagesValue = MTLRenderStages.vertex
    precondition(MTLRenderStagesValue.contains(.vertex))
    MTLRenderStagesValue.formUnion(.fragment)
    precondition(MTLRenderStagesValue.contains(.fragment))
    _ = MTLRenderStages.vertex
    _ = MTLRenderStages.fragment
    _ = MTLRenderStages.tile
    _ = MTLRenderStages.object
    _ = MTLRenderStages.mesh
    _ = MTLRenderStages(rawValue: MTLRenderStagesValue.rawValue)

    var MTLResourceOptionsValue = MTLResourceOptions.cpuCacheModeWriteCombined
    precondition(MTLResourceOptionsValue.contains(.cpuCacheModeWriteCombined))
    MTLResourceOptionsValue.formUnion(.optionCPUCacheModeWriteCombined)
    precondition(MTLResourceOptionsValue.contains(.optionCPUCacheModeWriteCombined))
    _ = MTLResourceOptions.cpuCacheModeWriteCombined
    _ = MTLResourceOptions.optionCPUCacheModeWriteCombined
    _ = MTLResourceOptions.cpuCacheModeDefaultCache
    _ = MTLResourceOptions.storageModeShared
    _ = MTLResourceOptions.storageModePrivate
    _ = MTLResourceOptions.storageModeMemoryless
    _ = MTLResourceOptions.hazardTrackingModeUntracked
    _ = MTLResourceOptions.hazardTrackingModeTracked
    _ = MTLResourceOptions(rawValue: MTLResourceOptionsValue.rawValue)

    var MTLResourceUsageValue = MTLResourceUsage.read
    precondition(MTLResourceUsageValue.contains(.read))
    MTLResourceUsageValue.formUnion(.write)
    precondition(MTLResourceUsageValue.contains(.write))
    _ = MTLResourceUsage.read
    _ = MTLResourceUsage.write
    _ = MTLResourceUsage.sample
    _ = MTLResourceUsage(rawValue: MTLResourceUsageValue.rawValue)

    var MTLStagesValue = MTLStages.vertex
    precondition(MTLStagesValue.contains(.vertex))
    MTLStagesValue.formUnion(.fragment)
    precondition(MTLStagesValue.contains(.fragment))
    _ = MTLStages.vertex
    _ = MTLStages.fragment
    _ = MTLStages.tile
    _ = MTLStages.object
    _ = MTLStages.mesh
    _ = MTLStages.dispatch
    _ = MTLStages.blit
    _ = MTLStages.accelerationStructure
    _ = MTLStages.machineLearning
    _ = MTLStages.resourceState
    _ = MTLStages.all
    _ = MTLStages(rawValue: MTLStagesValue.rawValue)

    let MTLStoreActionOptionsValue = MTLStoreActionOptions.customSamplePositions
    precondition(MTLStoreActionOptionsValue.contains(.customSamplePositions))
    _ = MTLStoreActionOptions.customSamplePositions
    _ = MTLStoreActionOptions(rawValue: MTLStoreActionOptionsValue.rawValue)

    var MTLTextureUsageValue = MTLTextureUsage.unknown
    precondition(MTLTextureUsageValue.contains(.unknown))
    MTLTextureUsageValue.formUnion(.shaderRead)
    precondition(MTLTextureUsageValue.contains(.shaderRead))
    _ = MTLTextureUsage.unknown
    _ = MTLTextureUsage.shaderRead
    _ = MTLTextureUsage.shaderWrite
    _ = MTLTextureUsage.renderTarget
    _ = MTLTextureUsage.pixelFormatView
    _ = MTLTextureUsage.shaderAtomic
    _ = MTLTextureUsage(rawValue: MTLTextureUsageValue.rawValue)

    _ = MTLCommandBufferErrorDomain
    _ = MTLLibraryErrorDomain
    _ = MTLCaptureErrorDomain
    _ = MTLBinaryArchiveDomain
    _ = MTLCounterErrorDomain
    _ = MTLDynamicLibraryDomain
    _ = MTLIOErrorDomain
    _ = MTLLogStateErrorDomain
    _ = MTLTensorDomain
    _ = MTL4CommandQueueErrorDomain
    _ = MTLCommandBufferEncoderInfoErrorKey
    _ = MTLAttributeStrideStatic
    _ = MTLBufferLayoutStrideDynamic
    _ = MTLCounterDontSample
    _ = MTLCounterErrorValue
    _ = MTL_TENSOR_MAX_RANK
    _ = MTLResourceCPUCacheModeShift
    _ = MTLResourceCPUCacheModeMask
    _ = MTLResourceStorageModeShift
    _ = MTLResourceStorageModeMask
    _ = MTLResourceHazardTrackingModeShift
    _ = MTLResourceHazardTrackingModeMask
    precondition(MTLLibraryErrorDomain == "MTLLibraryErrorDomain")
    precondition(MTLCommandBufferErrorDomain == "MTLCommandBufferErrorDomain")
    precondition(MTLCaptureErrorDomain == "MTLCaptureErrorDomain")
    precondition(MTLCounterDontSample == -1)
    precondition(MTLResourceCPUCacheModeShift == 0)
    precondition(MTLResourceStorageModeShift == 4)
    precondition(MTLResourceHazardTrackingModeShift == 8)
    precondition(MTLIOError.urlInvalid.rawValue == 1)
    precondition(MTLCommandBufferError.accessRevoked == .blacklisted)
    metalExerciseOptionSet(MTLAccelerationStructureInstanceOptions.opaque, .nonOpaque)
    metalExerciseOptionSet(MTLAccelerationStructureUsage.refit, .preferFastBuild)
    metalExerciseOptionSet(MTLAccelerationStructureRefitOptions.vertexData, .perPrimitiveData)
    metalExerciseOptionSet(MTLIntersectionFunctionSignature.instancing, .triangleData)
    metalExerciseOptionSet(MTL4BinaryFunctionOptions.pipelineIndependent, .pipelineIndependent)
    metalExerciseOptionSet(MTL4RenderEncoderOptions.suspending, .resuming)
    metalExerciseOptionSet(MTL4ShaderReflection.bindingInfo, .bufferTypeInfo)
    metalExerciseOptionSet(MTL4VisibilityOptions.device, .resourceAlias)
    metalExerciseOptionSet(MTL4PipelineDataSetSerializerConfiguration.captureDescriptors, .captureBinaries)
    metalExerciseOptionSet(MTLStitchedLibraryOptions.failOnBinaryArchiveMiss, .storeLibraryInMetalPipelinesScript)
    metalExerciseOptionSet(MTLTensorUsage.compute, .render)
    let accelLiteral: MTLAccelerationStructureInstanceOptions = [.opaque, .disableTriangleCulling]
    precondition(accelLiteral.contains(.opaque))
    let usageLiteral: MTLAccelerationStructureUsage = [.refit, .preferFastBuild]
    precondition(usageLiteral.contains(.refit))
    let signatureLiteral: MTLIntersectionFunctionSignature = [.instancing, .triangleData]
    precondition(signatureLiteral.contains(.instancing))
    let metal4Literal: MTL4RenderEncoderOptions = [.suspending, .resuming]
    precondition(metal4Literal.contains(.suspending))
    precondition(MTLAccelerationStructureInstanceOptions.disableTriangleCulling.rawValue == 1)
    precondition(MTLAccelerationStructureInstanceOptions.triangleFrontFacingWindingCounterClockwise.rawValue == 2)
    precondition(MTLAccelerationStructureInstanceOptions.opaque.rawValue == 4)
    precondition(MTLAccelerationStructureInstanceOptions.nonOpaque.rawValue == 8)
    precondition(MTLAccelerationStructureUsage.extendedLimits.rawValue == 4)
    precondition(MTLAccelerationStructureUsage.preferFastIntersection.rawValue == 8)
    precondition(MTLAccelerationStructureUsage.minimizeMemory.rawValue == 16)
    precondition(MTLIntersectionFunctionSignature.worldSpaceData.rawValue == 4)
    precondition(MTLIntersectionFunctionSignature.instanceMotion.rawValue == 8)
    precondition(MTLIntersectionFunctionSignature.primitiveMotion.rawValue == 16)
    precondition(MTLIntersectionFunctionSignature.extendedLimits.rawValue == 32)
    precondition(MTLIntersectionFunctionSignature.maxLevels.rawValue == 64)
    precondition(MTLIntersectionFunctionSignature.curveData.rawValue == 128)
    precondition(MTLIntersectionFunctionSignature.intersectionFunctionBuffer.rawValue == 256)
    precondition(MTLIntersectionFunctionSignature.userData.rawValue == 256 << 1)
    precondition(MTLMutability.default.rawValue == 0)
    precondition(MTLMutability(rawValue: 0) == MTLMutability.default)
    precondition(MTLMutability.mutable.rawValue == 1)
    precondition(MTLMutability(rawValue: 1) == MTLMutability.mutable)
    precondition(MTLMutability.immutable.rawValue == 2)
    precondition(MTLMutability(rawValue: 2) == MTLMutability.immutable)
    precondition(MTLMutability.default != MTLMutability.mutable)
    var MTLMutabilitySet: Set<MTLMutability> = [.default]
    MTLMutabilitySet.insert(.mutable)
    precondition(MTLMutabilitySet.count == 2)
    precondition(MTLMotionBorderMode.clamp.rawValue == 0)
    precondition(MTLMotionBorderMode(rawValue: 0) == MTLMotionBorderMode.clamp)
    precondition(MTLMotionBorderMode.vanish.rawValue == 1)
    precondition(MTLMotionBorderMode(rawValue: 1) == MTLMotionBorderMode.vanish)
    precondition(MTLMotionBorderMode.clamp != MTLMotionBorderMode.vanish)
    var MTLMotionBorderModeSet: Set<MTLMotionBorderMode> = [.clamp]
    MTLMotionBorderModeSet.insert(.vanish)
    precondition(MTLMotionBorderModeSet.count == 2)

    metalExerciseRawEnum([
        MTL4AlphaToCoverageState.disabled, .enabled
    ])
    metalExerciseRawEnum([
        MTL4AlphaToOneState.disabled, .enabled
    ])
    metalExerciseRawEnum([
        MTL4BlendState.disabled, .enabled, .unspecialized
    ])
    metalExerciseRawEnum([
        MTL4IndirectCommandBufferSupportState.disabled, .enabled
    ])
    metalExerciseRawEnum([
        MTL4LogicalToPhysicalColorAttachmentMappingState.identity, .inherited
    ])
    metalExerciseRawEnum([
        MTL4CompilerTaskStatus.none, .scheduled, .compiling, .finished
    ])
    metalExerciseRawEnum([
        MTL4TimestampGranularity.relaxed, .precise
    ])
    metalExerciseRawEnum([
        MTL4CounterHeapType.invalid, .timestamp
    ])
    metalExerciseRawEnum([
        MTLCurveType.round, .flat
    ])
    metalExerciseRawEnum([
        MTLCurveBasis.bSpline, .linear, .bezier, .catmullRom
    ])
    metalExerciseRawEnum([
        MTLCurveEndCaps.none, .disk, .sphere
    ])
    metalExerciseRawEnum([
        MTLIOPriority.high, .normal, .low
    ])
    metalExerciseRawEnum([
        MTLIOStatus.pending, .cancelled, .error, .complete
    ])
    metalExerciseRawEnum([
        MTLIOCompressionMethod.zlib, .lzfse, .lz4, .lzma, .lzBitmap
    ])
    metalExerciseRawEnum([
        MTLIOCommandQueueType.concurrent, .serial
    ])
    metalExerciseRawEnum([
        MTLMatrixLayout.columnMajor, .rowMajor
    ])
    metalExerciseRawEnum([
        MTLPrimitiveTopologyClass.unspecified, .point, .line, .triangle
    ])
    metalExerciseRawEnum([
        MTLTessellationControlPointIndexType.none, .uint16, .uint32
    ])
    metalExerciseRawEnum([
        MTLTessellationFactorFormat.half
    ])
    metalExerciseRawEnum([
        MTLTessellationFactorStepFunction.constant, .perPatch, .perInstance, .perPatchAndPerInstance
    ])
    metalExerciseRawEnum([
        MTLTessellationPartitionMode.pow2, .integer, .fractionalOdd, .fractionalEven
    ])
    metalExerciseRawEnum([
        MTLTransformType.packedFloat4x3, .component
    ])
    metalExerciseRawEnum([
        MTLAccelerationStructureInstanceDescriptorType.default, .userID, .motion, .indirect, .indirectMotion
    ])
    metalExerciseRawEnum([
        MTLSparseTextureRegionAlignmentMode.outward, .inward
    ])
    metalExerciseRawEnum([
        MTL4CommandQueueError.Code.none, .internal, .timeout, .notPermitted, .outOfMemory, .accessRevoked, .deviceRemoved
    ])
    precondition(MTL4CommandQueueError.none == .none)
    precondition(MTL4CommandQueueError.internal == .internal)
    precondition(MTL4CommandQueueError.timeout == .timeout)
    precondition(MTL4CommandQueueError.notPermitted == .notPermitted)
    precondition(MTL4CommandQueueError.outOfMemory == .outOfMemory)
    precondition(MTL4CommandQueueError.accessRevoked == .accessRevoked)
    precondition(MTL4CommandQueueError.deviceRemoved == .deviceRemoved)
    precondition(MTL4CommandQueueError.errorDomain == MTL4CommandQueueErrorDomain)
    let queueError = MTL4CommandQueueError(.notPermitted, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(queueError.code == .notPermitted)
    precondition(queueError.errorCode == MTL4CommandQueueError.Code.notPermitted.rawValue)
    _ = queueError.errorUserInfo
    _ = queueError.hashValue
    var hasher = Hasher()
    queueError.hash(into: &hasher)
    precondition(MTL4CommandQueueError.notPermitted ~= queueError)
    precondition(queueError != MTL4CommandQueueError(.none))

    let timestamp = MTLCommonCounter.timestamp
    precondition(timestamp.rawValue == "Timestamp")
    precondition(MTLCommonCounter(rawValue: "Timestamp") == timestamp)
    precondition(MTLCommonCounter.clipperInvocations != MTLCommonCounter.clipperPrimitivesOut)
    precondition(MTLCommonCounter.computeKernelInvocations.rawValue == "ComputeKernelInvocations")
    precondition(MTLCommonCounter.fragmentCycles.rawValue == "FragmentCycles")
    precondition(MTLCommonCounter.fragmentInvocations.rawValue == "FragmentInvocations")
    precondition(MTLCommonCounter.fragmentsPassed.rawValue == "FragmentsPassed")
    precondition(MTLCommonCounter.postTessellationVertexCycles.rawValue == "PostTessellationVertexCycles")
    precondition(MTLCommonCounter.postTessellationVertexInvocations.rawValue == "PostTessellationVertexInvocations")
    precondition(MTLCommonCounter.renderTargetWriteCycles.rawValue == "RenderTargetWriteCycles")
    precondition(MTLCommonCounter.tessellationCycles.rawValue == "TessellationCycles")
    precondition(MTLCommonCounter.tessellationInputPatches.rawValue == "TessellationInputPatches")
    precondition(MTLCommonCounter.totalCycles.rawValue == "TotalCycles")
    precondition(MTLCommonCounter.vertexCycles.rawValue == "VertexCycles")
    precondition(MTLCommonCounter.vertexInvocations.rawValue == "VertexInvocations")
    var counterSet: Set<MTLCommonCounter> = [.timestamp]
    counterSet.insert(.totalCycles)
    precondition(counterSet.count == 2)
    _ = timestamp.hashValue
    var counterHasher = Hasher()
    timestamp.hash(into: &counterHasher)

    precondition(MTLCommonCounterSet.timestamp.rawValue == "timestamp")
    precondition(MTLCommonCounterSet.stageUtilization.rawValue == "stageUtilization")
    precondition(MTLCommonCounterSet.statistic.rawValue == "statistic")
    precondition(MTLCommonCounterSet(rawValue: "timestamp") == .timestamp)
    precondition(MTLCommonCounterSet.timestamp != MTLCommonCounterSet.statistic)
    var namedSets: Set<MTLCommonCounterSet> = [.timestamp]
    namedSets.insert(.statistic)
    precondition(namedSets.count == 2)
    _ = MTLCommonCounterSet.stageUtilization.hashValue
    var setHasher = Hasher()
    MTLCommonCounterSet.stageUtilization.hash(into: &setHasher)

    var ts = MTLCounterResultTimestamp()
    ts.timestamp = 42
    precondition(ts.timestamp == 42)
    var stage = MTLCounterResultStageUtilization()
    stage.totalCycles = 1
    stage.vertexCycles = 2
    stage.tessellationCycles = 3
    stage.postTessellationVertexCycles = 4
    stage.fragmentCycles = 5
    stage.renderTargetCycles = 6
    precondition(stage.totalCycles == 1)
    precondition(stage.vertexCycles == 2)
    precondition(stage.tessellationCycles == 3)
    precondition(stage.postTessellationVertexCycles == 4)
    precondition(stage.fragmentCycles == 5)
    precondition(stage.renderTargetCycles == 6)
    var stat = MTLCounterResultStatistic()
    stat.clipperInvocations = 1
    stat.clipperPrimitivesOut = 2
    stat.computeKernelInvocations = 3
    stat.fragmentInvocations = 4
    stat.fragmentsPassed = 5
    stat.postTessellationVertexInvocations = 6
    stat.tessellationInputPatches = 7
    stat.vertexInvocations = 8
    precondition(stat.clipperInvocations == 1)
    precondition(stat.vertexInvocations == 8)

    metalExerciseRawEnum([
        MTLTensorDataType.none, .float32, .float16, .bfloat16, .int8, .uint8, .int16, .uint16, .int32, .uint32
    ])
    metalExerciseRawEnum([
        MTLStepFunction.constant, .perVertex, .perInstance, .perPatch, .perPatchControlPoint,
        .threadPositionInGridX, .threadPositionInGridY, .threadPositionInGridXIndexed, .threadPositionInGridYIndexed
    ])
    metalExerciseRawEnum([
        MTLLogLevel.undefined, .debug, .info, .notice, .error, .fault
    ])
    metalExerciseRawEnum([
        MTLCommandEncoderErrorState.unknown, .completed, .affected, .pending, .faulted
    ])
    metalExerciseRawEnum([
        MTLFunctionLogType.validation
    ])
    metalExerciseRawEnum([
        MTLIOCompressionStatus.complete, .error
    ])
    metalExerciseRawEnum([
        MTLLogStateError.invalid, .invalidSize
    ])
    metalExerciseRawEnum([
        MTLDynamicLibraryError.Code.none, .invalidFile, .compilationFailure, .unresolvedInstallName,
        .dependencyLoadFailure, .unsupported
    ])
    precondition(MTLDynamicLibraryError.none == .none)
    precondition(MTLDynamicLibraryError.invalidFile == .invalidFile)
    precondition(MTLDynamicLibraryError.compilationFailure == .compilationFailure)
    precondition(MTLDynamicLibraryError.unresolvedInstallName == .unresolvedInstallName)
    precondition(MTLDynamicLibraryError.dependencyLoadFailure == .dependencyLoadFailure)
    precondition(MTLDynamicLibraryError.unsupported == .unsupported)
    precondition(MTLDynamicLibraryError.errorDomain == MTLDynamicLibraryDomain)
    let dynError = MTLDynamicLibraryError(.unsupported, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(dynError.code == .unsupported)
    precondition(dynError.errorCode == Int(MTLDynamicLibraryError.Code.unsupported.rawValue))
    _ = dynError.errorUserInfo
    _ = dynError.hashValue
    _ = dynError.localizedDescription
    var dynHasher = Hasher()
    dynError.hash(into: &dynHasher)
    precondition(MTLDynamicLibraryError.unsupported ~= dynError)
    precondition(dynError != MTLDynamicLibraryError(.none))

    metalExerciseRawEnum([
        MTLBinaryArchiveError.Code.none, .invalidFile, .unexpectedElement, .compilationFailure, .internalError
    ])
    precondition(MTLBinaryArchiveError.none == .none)
    precondition(MTLBinaryArchiveError.invalidFile == .invalidFile)
    precondition(MTLBinaryArchiveError.unexpectedElement == .unexpectedElement)
    precondition(MTLBinaryArchiveError.compilationFailure == .compilationFailure)
    precondition(MTLBinaryArchiveError.internalError == .internalError)
    precondition(MTLBinaryArchiveError.errorDomain == MTLBinaryArchiveDomain)
    let binError = MTLBinaryArchiveError(.internalError, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(binError.code == .internalError)
    precondition(MTLBinaryArchiveError.internalError ~= binError)
    _ = binError.errorUserInfo
    _ = binError.hashValue
    _ = binError.localizedDescription

    metalExerciseRawEnum([
        MTLCounterSampleBufferError.Code.outOfMemory, .invalid, .internal
    ])
    precondition(MTLCounterSampleBufferError.outOfMemory == .outOfMemory)
    precondition(MTLCounterSampleBufferError.invalid == .invalid)
    precondition(MTLCounterSampleBufferError.internal == .internal)
    precondition(MTLCounterSampleBufferError.errorDomain == MTLCounterErrorDomain)
    let counterError = MTLCounterSampleBufferError(.invalid, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(counterError.code == .invalid)
    precondition(MTLCounterSampleBufferError.invalid ~= counterError)
    _ = counterError.hashValue
    _ = counterError.localizedDescription

    metalExerciseRawEnum([
        MTLTensorError.Code.none, .internalError, .invalidDescriptor
    ])
    precondition(MTLTensorError.none == .none)
    precondition(MTLTensorError.internalError == .internalError)
    precondition(MTLTensorError.invalidDescriptor == .invalidDescriptor)
    precondition(MTLTensorError.errorDomain == MTLTensorDomain)
    let tensorError = MTLTensorError(.invalidDescriptor, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(tensorError.code == .invalidDescriptor)
    precondition(MTLTensorError.invalidDescriptor ~= tensorError)
    _ = tensorError.hashValue
    _ = tensorError.localizedDescription

    precondition(MTLCommandBufferError.none == .none)
    precondition(MTLCommandBufferError.internal == .internal)
    precondition(MTLCommandBufferError.timeout == .timeout)
    precondition(MTLCommandBufferError.pageFault == .pageFault)
    precondition(MTLCommandBufferError.blacklisted == .blacklisted)
    precondition(MTLCommandBufferError.notPermitted == .notPermitted)
    precondition(MTLCommandBufferError.outOfMemory == .outOfMemory)
    precondition(MTLCommandBufferError.invalidResource == .invalidResource)
    precondition(MTLCommandBufferError.memoryless == .memoryless)
    precondition(MTLCommandBufferError.stackOverflow == .stackOverflow)
    _ = MTLCommandBufferError.errorDomain
    let ioThrown = MTLIOError(.internal, userInfo: [NSLocalizedDescriptionKey: "cpu"])
    precondition(ioThrown == MTLIOError(.internal))
    precondition(ioThrown != MTLIOError(.urlInvalid))
    _ = ioThrown.hashValue
    _ = ioThrown.localizedDescription
    precondition(MTLIOError.internal ~= ioThrown)
}

private func metalExerciseOptionSet<T: OptionSet & Hashable>(_ first: T, _ second: T)
where T.RawValue: FixedWidthInteger, T.Element == T {
    let empty = T()
    precondition(empty.isEmpty)
    var value = first
    precondition(value.contains(first))
    let inserted = value.insert(second)
    _ = inserted
    value.formUnion(second)
    precondition(value.contains(first))
    let unioned = first.union(second)
    precondition(unioned.contains(first))
    let combined = first.union(second)
    let inter = combined.intersection(first)
    precondition(inter.contains(first))
    var form = combined
    form.formIntersection(first)
    var symmetric = first
    symmetric.formSymmetricDifference(second)
    _ = first.symmetricDifference(second)
    _ = first.subtracting(second)
    var subtract = combined
    subtract.subtract(second)
    precondition(first.isSubset(of: combined))
    precondition(combined.isSuperset(of: first))
    _ = first.isStrictSubset(of: combined)
    _ = combined.isStrictSuperset(of: first)
    _ = first.isDisjoint(with: second) || first == second
    _ = value.remove(second)
    _ = value.update(with: first)
    precondition(first != second || first == second)
    var set = Set<T>()
    set.insert(first)
    set.insert(second)
    _ = value.hashValue
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = hasher.finalize()
    _ = T(rawValue: first.rawValue)
}

private func metalExerciseRawEnum<T: RawRepresentable & Hashable>(_ values: [T])
where T.RawValue: Equatable {
    precondition(!values.isEmpty)
    for value in values {
        precondition(T(rawValue: value.rawValue) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    if values.count >= 2 {
        precondition(values[0] != values[1])
        var set = Set<T>()
        set.insert(values[0])
        set.insert(values[1])
        precondition(set.count == 2)
    }
}
