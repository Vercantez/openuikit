import Foundation
import ModelIO

func testMDLAnimatedValueInterpolation() {
    mdlHashAndRaw(MDLAnimatedValueInterpolation.constant, expected: 0, label: "constant")
    mdlHashAndRaw(MDLAnimatedValueInterpolation.linear, expected: 1, label: "linear")
    mdlCheck(MDLAnimatedValueInterpolation.constant != .linear, "!=")
}

func testMDLCameraProjection() {
    mdlHashAndRaw(MDLCameraProjection.perspective, expected: 0, label: "perspective")
    mdlHashAndRaw(MDLCameraProjection.orthographic, expected: 1, label: "orthographic")
    mdlCheck(MDLCameraProjection.perspective != .orthographic, "!=")
}

func testMDLDataPrecision() {
    mdlHashAndRaw(MDLDataPrecision.undefined, expected: 0, label: "undefined")
    mdlHashAndRaw(MDLDataPrecision.float, expected: 1, label: "float")
    mdlHashAndRaw(MDLDataPrecision.double, expected: 2, label: "double")
    mdlCheck(MDLDataPrecision.float != .double, "!=")
}

func testMDLGeometryType() {
    mdlHashAndRaw(MDLGeometryType.points, expected: 0, label: "points")
    mdlHashAndRaw(MDLGeometryType.lines, expected: 1, label: "lines")
    mdlHashAndRaw(MDLGeometryType.triangles, expected: 2, label: "triangles")
    mdlHashAndRaw(MDLGeometryType.triangleStrips, expected: 3, label: "strips")
    mdlHashAndRaw(MDLGeometryType.quads, expected: 4, label: "quads")
    mdlHashAndRaw(MDLGeometryType.variableTopology, expected: 5, label: "variable")
    mdlCheck(MDLGeometryType.triangles != .quads, "!=")
}

func testMDLIndexBitDepth() {
    mdlHashAndRaw(MDLIndexBitDepth.invalid, expected: 0, label: "invalid")
    mdlHashAndRaw(MDLIndexBitDepth.uInt8, expected: 8, label: "uInt8")
    mdlHashAndRaw(MDLIndexBitDepth.uInt16, expected: 16, label: "uInt16")
    mdlHashAndRaw(MDLIndexBitDepth.uInt32, expected: 32, label: "uInt32")
    mdlCheck(MDLIndexBitDepth.uint8 == .uInt8, "uint8 alias")
    mdlCheck(MDLIndexBitDepth.uint16 == .uInt16, "uint16 alias")
    mdlCheck(MDLIndexBitDepth.uint32 == .uInt32, "uint32 alias")
    mdlCheck(MDLIndexBitDepth.uInt8 != .uInt16, "!=")
}

func testMDLLightType() {
    mdlHashAndRaw(MDLLightType.unknown, expected: 0, label: "unknown")
    mdlHashAndRaw(MDLLightType.ambient, expected: 1, label: "ambient")
    mdlHashAndRaw(MDLLightType.directional, expected: 2, label: "directional")
    mdlHashAndRaw(MDLLightType.spot, expected: 3, label: "spot")
    mdlHashAndRaw(MDLLightType.point, expected: 4, label: "point")
    mdlHashAndRaw(MDLLightType.linear, expected: 5, label: "linear")
    mdlHashAndRaw(MDLLightType.discArea, expected: 6, label: "disc")
    mdlHashAndRaw(MDLLightType.rectangularArea, expected: 7, label: "rect")
    mdlHashAndRaw(MDLLightType.superElliptical, expected: 8, label: "super")
    mdlHashAndRaw(MDLLightType.photometric, expected: 9, label: "photometric")
    mdlHashAndRaw(MDLLightType.probe, expected: 10, label: "probe")
    mdlHashAndRaw(MDLLightType.environment, expected: 11, label: "environment")
    mdlCheck(MDLLightType.point != .spot, "!=")
}

func testMDLMaterialFace() {
    mdlHashAndRaw(MDLMaterialFace.front, expected: 0, label: "front")
    mdlHashAndRaw(MDLMaterialFace.back, expected: 1, label: "back")
    mdlHashAndRaw(MDLMaterialFace.doubleSided, expected: 2, label: "double")
    mdlCheck(MDLMaterialFace.front != .back, "!=")
}

func testMDLMaterialMipMapFilterMode() {
    mdlHashAndRaw(MDLMaterialMipMapFilterMode.nearest, expected: 0, label: "nearest")
    mdlHashAndRaw(MDLMaterialMipMapFilterMode.linear, expected: 1, label: "linear")
    mdlCheck(MDLMaterialMipMapFilterMode.nearest != .linear, "!=")
}

func testMDLMaterialPropertyType() {
    mdlHashAndRaw(MDLMaterialPropertyType.none, expected: 0, label: "none")
    mdlHashAndRaw(MDLMaterialPropertyType.string, expected: 1, label: "string")
    mdlHashAndRaw(MDLMaterialPropertyType.URL, expected: 2, label: "URL")
    mdlHashAndRaw(MDLMaterialPropertyType.texture, expected: 3, label: "texture")
    mdlHashAndRaw(MDLMaterialPropertyType.color, expected: 4, label: "color")
    mdlHashAndRaw(MDLMaterialPropertyType.float, expected: 5, label: "float")
    mdlHashAndRaw(MDLMaterialPropertyType.float2, expected: 6, label: "float2")
    mdlHashAndRaw(MDLMaterialPropertyType.float3, expected: 7, label: "float3")
    mdlHashAndRaw(MDLMaterialPropertyType.float4, expected: 8, label: "float4")
    mdlHashAndRaw(MDLMaterialPropertyType.matrix44, expected: 9, label: "matrix")
    mdlHashAndRaw(MDLMaterialPropertyType.buffer, expected: 10, label: "buffer")
    mdlCheck(MDLMaterialPropertyType.float != .color, "!=")
}

func testMDLMaterialSemantic() {
    mdlHashAndRaw(MDLMaterialSemantic.baseColor, expected: 0, label: "baseColor")
    mdlHashAndRaw(MDLMaterialSemantic.subsurface, expected: 1, label: "subsurface")
    mdlHashAndRaw(MDLMaterialSemantic.metallic, expected: 2, label: "metallic")
    mdlHashAndRaw(MDLMaterialSemantic.specular, expected: 3, label: "specular")
    mdlHashAndRaw(MDLMaterialSemantic.specularExponent, expected: 4, label: "specExp")
    mdlHashAndRaw(MDLMaterialSemantic.specularTint, expected: 5, label: "specTint")
    mdlHashAndRaw(MDLMaterialSemantic.roughness, expected: 6, label: "roughness")
    mdlHashAndRaw(MDLMaterialSemantic.anisotropic, expected: 7, label: "aniso")
    mdlHashAndRaw(MDLMaterialSemantic.anisotropicRotation, expected: 8, label: "anisoRot")
    mdlHashAndRaw(MDLMaterialSemantic.sheen, expected: 9, label: "sheen")
    mdlHashAndRaw(MDLMaterialSemantic.sheenTint, expected: 10, label: "sheenTint")
    mdlHashAndRaw(MDLMaterialSemantic.clearcoat, expected: 11, label: "clearcoat")
    mdlHashAndRaw(MDLMaterialSemantic.clearcoatGloss, expected: 12, label: "gloss")
    mdlHashAndRaw(MDLMaterialSemantic.emission, expected: 13, label: "emission")
    mdlHashAndRaw(MDLMaterialSemantic.bump, expected: 14, label: "bump")
    mdlHashAndRaw(MDLMaterialSemantic.opacity, expected: 15, label: "opacity")
    mdlHashAndRaw(MDLMaterialSemantic.interfaceIndexOfRefraction, expected: 16, label: "iorI")
    mdlHashAndRaw(MDLMaterialSemantic.materialIndexOfRefraction, expected: 17, label: "iorM")
    mdlHashAndRaw(MDLMaterialSemantic.objectSpaceNormal, expected: 18, label: "osn")
    mdlHashAndRaw(MDLMaterialSemantic.tangentSpaceNormal, expected: 19, label: "tsn")
    mdlHashAndRaw(MDLMaterialSemantic.displacement, expected: 20, label: "disp")
    mdlHashAndRaw(MDLMaterialSemantic.displacementScale, expected: 21, label: "dispScale")
    mdlHashAndRaw(MDLMaterialSemantic.ambientOcclusion, expected: 22, label: "ao")
    mdlHashAndRaw(MDLMaterialSemantic.ambientOcclusionScale, expected: 23, label: "aoScale")
    mdlHashAndRaw(MDLMaterialSemantic.none, expected: 0x8000, label: "none")
    mdlHashAndRaw(MDLMaterialSemantic.userDefined, expected: 0x8001, label: "user")
    mdlCheck(MDLMaterialSemantic.baseColor != .metallic, "!=")
}

func testMDLMaterialTextureFilterMode() {
    mdlHashAndRaw(MDLMaterialTextureFilterMode.nearest, expected: 0, label: "nearest")
    mdlHashAndRaw(MDLMaterialTextureFilterMode.linear, expected: 1, label: "linear")
    mdlCheck(MDLMaterialTextureFilterMode.nearest != .linear, "!=")
}

func testMDLMaterialTextureWrapMode() {
    mdlHashAndRaw(MDLMaterialTextureWrapMode.clamp, expected: 0, label: "clamp")
    mdlHashAndRaw(MDLMaterialTextureWrapMode.repeat, expected: 1, label: "repeat")
    mdlHashAndRaw(MDLMaterialTextureWrapMode.mirror, expected: 2, label: "mirror")
    mdlCheck(MDLMaterialTextureWrapMode.clamp != .mirror, "!=")
}

func testMDLMeshBufferType() {
    mdlHashAndRaw(MDLMeshBufferType.vertex, expected: 1, label: "vertex")
    mdlHashAndRaw(MDLMeshBufferType.index, expected: 2, label: "index")
    mdlHashAndRaw(MDLMeshBufferType.custom, expected: 3, label: "custom")
    mdlCheck(MDLMeshBufferType.vertex != .index, "!=")
}

func testMDLProbePlacement() {
    mdlHashAndRaw(MDLProbePlacement.uniformGrid, expected: 0, label: "grid")
    mdlHashAndRaw(MDLProbePlacement.irradianceDistribution, expected: 1, label: "irr")
    mdlCheck(MDLProbePlacement.uniformGrid != .irradianceDistribution, "!=")
}

func testMDLTextureChannelEncoding() {
    mdlHashAndRaw(MDLTextureChannelEncoding.uInt8, expected: 1, label: "u8")
    mdlHashAndRaw(MDLTextureChannelEncoding.uInt16, expected: 2, label: "u16")
    mdlHashAndRaw(MDLTextureChannelEncoding.uInt24, expected: 3, label: "u24")
    mdlHashAndRaw(MDLTextureChannelEncoding.uInt32, expected: 4, label: "u32")
    mdlHashAndRaw(MDLTextureChannelEncoding.float16, expected: 258, label: "f16")
    mdlHashAndRaw(MDLTextureChannelEncoding.float32, expected: 260, label: "f32")
    mdlHashAndRaw(MDLTextureChannelEncoding.float16SR, expected: 770, label: "f16sr")
    mdlCheck(MDLTextureChannelEncoding.uint8 == .uInt8, "uint8")
    mdlCheck(MDLTextureChannelEncoding.uint16 == .uInt16, "uint16")
    mdlCheck(MDLTextureChannelEncoding.uint24 == .uInt24, "uint24")
    mdlCheck(MDLTextureChannelEncoding.uint32 == .uInt32, "uint32")
    mdlCheck(MDLTextureChannelEncoding.uInt8 != .float32, "!=")
}

func testMDLTransformOpRotationOrder() {
    mdlHashAndRaw(MDLTransformOpRotationOrder.xyz, expected: 1, label: "xyz")
    mdlHashAndRaw(MDLTransformOpRotationOrder.xzy, expected: 2, label: "xzy")
    mdlHashAndRaw(MDLTransformOpRotationOrder.yxz, expected: 3, label: "yxz")
    mdlHashAndRaw(MDLTransformOpRotationOrder.yzx, expected: 4, label: "yzx")
    mdlHashAndRaw(MDLTransformOpRotationOrder.zxy, expected: 5, label: "zxy")
    mdlHashAndRaw(MDLTransformOpRotationOrder.zyx, expected: 6, label: "zyx")
    mdlCheck(MDLTransformOpRotationOrder.xyz != .zyx, "!=")
}

func testMDLVertexFormat() {
    let cases: [(MDLVertexFormat, UInt, String)] = [
        (.invalid, 0, "invalid"),
        (.packedBit, 0x1000, "packedBit"),
        (.uCharBits, 0x10000, "uCharBits"),
        (.charBits, 0x20000, "charBits"),
        (.uCharNormalizedBits, 0x30000, "uCharNBits"),
        (.charNormalizedBits, 0x40000, "charNBits"),
        (.uShortBits, 0x50000, "uShortBits"),
        (.shortBits, 0x60000, "shortBits"),
        (.uShortNormalizedBits, 0x70000, "uShortNBits"),
        (.shortNormalizedBits, 0x80000, "shortNBits"),
        (.uIntBits, 0x90000, "uIntBits"),
        (.intBits, 0xA0000, "intBits"),
        (.halfBits, 0xB0000, "halfBits"),
        (.floatBits, 0xC0000, "floatBits"),
        (.uChar, 0x10000 | 1, "uChar"),
        (.uChar2, 0x10000 | 2, "uChar2"),
        (.uChar3, 0x10000 | 3, "uChar3"),
        (.uChar4, 0x10000 | 4, "uChar4"),
        (.char, 0x20000 | 1, "char"),
        (.char2, 0x20000 | 2, "char2"),
        (.char3, 0x20000 | 3, "char3"),
        (.char4, 0x20000 | 4, "char4"),
        (.uCharNormalized, 0x30000 | 1, "uCharN"),
        (.uChar2Normalized, 0x30000 | 2, "uChar2N"),
        (.uChar3Normalized, 0x30000 | 3, "uChar3N"),
        (.uChar4Normalized, 0x30000 | 4, "uChar4N"),
        (.charNormalized, 0x40000 | 1, "charN"),
        (.char2Normalized, 0x40000 | 2, "char2N"),
        (.char3Normalized, 0x40000 | 3, "char3N"),
        (.char4Normalized, 0x40000 | 4, "char4N"),
        (.uShort, 0x50000 | 1, "uShort"),
        (.uShort2, 0x50000 | 2, "uShort2"),
        (.uShort3, 0x50000 | 3, "uShort3"),
        (.uShort4, 0x50000 | 4, "uShort4"),
        (.short, 0x60000 | 1, "short"),
        (.short2, 0x60000 | 2, "short2"),
        (.short3, 0x60000 | 3, "short3"),
        (.short4, 0x60000 | 4, "short4"),
        (.uShortNormalized, 0x70000 | 1, "uShortN"),
        (.uShort2Normalized, 0x70000 | 2, "uShort2N"),
        (.uShort3Normalized, 0x70000 | 3, "uShort3N"),
        (.uShort4Normalized, 0x70000 | 4, "uShort4N"),
        (.shortNormalized, 0x80000 | 1, "shortN"),
        (.short2Normalized, 0x80000 | 2, "short2N"),
        (.short3Normalized, 0x80000 | 3, "short3N"),
        (.short4Normalized, 0x80000 | 4, "short4N"),
        (.uInt, 0x90000 | 1, "uInt"),
        (.uInt2, 0x90000 | 2, "uInt2"),
        (.uInt3, 0x90000 | 3, "uInt3"),
        (.uInt4, 0x90000 | 4, "uInt4"),
        (.int, 0xA0000 | 1, "int"),
        (.int2, 0xA0000 | 2, "int2"),
        (.int3, 0xA0000 | 3, "int3"),
        (.int4, 0xA0000 | 4, "int4"),
        (.half, 0xB0000 | 1, "half"),
        (.half2, 0xB0000 | 2, "half2"),
        (.half3, 0xB0000 | 3, "half3"),
        (.half4, 0xB0000 | 4, "half4"),
        (.float, 0xC0000 | 1, "float"),
        (.float2, 0xC0000 | 2, "float2"),
        (.float3, 0xC0000 | 3, "float3"),
        (.float4, 0xC0000 | 4, "float4"),
        (.int1010102Normalized, 0xA0000 | 0x1000 | 4, "int1010102"),
        (.uInt1010102Normalized, 0x90000 | 0x1000 | 4, "uInt1010102"),
    ]
    for (value, raw, label) in cases {
        mdlCheck(value.rawValue == raw, label)
        mdlCheck(MDLVertexFormat(rawValue: raw)?.rawValue == raw, "\(label) init")
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = value.hashValue
    }
    mdlCheck(MDLVertexFormat.float3 != .float2, "!=")
    mdlCheck(MDLVertexFormat.invalid != .float3, "invalid !=")
}
