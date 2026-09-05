import Foundation
@_spi(OpenUIKitHost) import GLKit

func testGLKTextureLoaderErrorCodes() {
    let codes: [(GLKTextureLoaderError.Code, UInt32)] = [
        (.fileOrURLNotFound, 0),
        (.invalidNSData, 1),
        (.invalidCGImage, 2),
        (.unknownPathType, 3),
        (.unknownFileType, 4),
        (.pvrAtlasUnsupported, 5),
        (.cubeMapInvalidNumFiles, 6),
        (.compressedTextureUpload, 7),
        (.uncompressedTextureUpload, 8),
        (.unsupportedCubeMapDimensions, 9),
        (.unsupportedBitDepth, 10),
        (.unsupportedPVRFormat, 11),
        (.dataPreprocessingFailure, 12),
        (.mipmapUnsupported, 13),
        (.unsupportedOrientation, 14),
        (.reorientationFailure, 15),
        (.alphaPremultiplicationFailure, 16),
        (.invalidEAGLContext, 17),
        (.incompatibleFormatSRGB, 18),
        (.unsupportedTextureTarget, 19),
    ]
    glkCheck(GLKTextureLoaderError.Code.fileOrURLNotFound != .invalidNSData, "code !=")
    for (code, raw) in codes {
        glkHashAndRaw(code, expected: raw)
        glkCheck(GLKTextureLoaderError(code).errorCode == Int(raw), "errorCode \(raw)")
    }
    glkCheck(GLKTextureLoaderError.fileOrURLNotFound.rawValue == 0, "static fileOrURLNotFound")
    glkCheck(GLKTextureLoaderError.invalidNSData.rawValue == 1, "static invalidNSData")
    glkCheck(GLKTextureLoaderError.invalidCGImage.rawValue == 2, "static invalidCGImage")
    glkCheck(GLKTextureLoaderError.unknownPathType.rawValue == 3, "static unknownPathType")
    glkCheck(GLKTextureLoaderError.unknownFileType.rawValue == 4, "static unknownFileType")
    glkCheck(GLKTextureLoaderError.pvrAtlasUnsupported.rawValue == 5, "static pvrAtlasUnsupported")
    glkCheck(GLKTextureLoaderError.cubeMapInvalidNumFiles.rawValue == 6, "static cubeMapInvalidNumFiles")
    glkCheck(GLKTextureLoaderError.compressedTextureUpload.rawValue == 7, "static compressedTextureUpload")
    glkCheck(GLKTextureLoaderError.uncompressedTextureUpload.rawValue == 8, "static uncompressedTextureUpload")
    glkCheck(GLKTextureLoaderError.unsupportedCubeMapDimensions.rawValue == 9, "static cube dim")
    glkCheck(GLKTextureLoaderError.unsupportedBitDepth.rawValue == 10, "static bit depth")
    glkCheck(GLKTextureLoaderError.unsupportedPVRFormat.rawValue == 11, "static pvr")
    glkCheck(GLKTextureLoaderError.dataPreprocessingFailure.rawValue == 12, "static preprocess")
    glkCheck(GLKTextureLoaderError.mipmapUnsupported.rawValue == 13, "static mipmap")
    glkCheck(GLKTextureLoaderError.unsupportedOrientation.rawValue == 14, "static orientation")
    glkCheck(GLKTextureLoaderError.reorientationFailure.rawValue == 15, "static reorient")
    glkCheck(GLKTextureLoaderError.alphaPremultiplicationFailure.rawValue == 16, "static alpha")
    glkCheck(GLKTextureLoaderError.invalidEAGLContext.rawValue == 17, "static eagl")
    glkCheck(GLKTextureLoaderError.incompatibleFormatSRGB.rawValue == 18, "static srgb")
    glkCheck(GLKTextureLoaderError.unsupportedTextureTarget.rawValue == 19, "static target")
}

func testGLKTextureLoaderErrorBridging() {
    let info: [String: Any] = [GLKTextureLoaderErrorKey: "17"]
    let error = GLKTextureLoaderError(.invalidEAGLContext, userInfo: info)
    glkCheck(error.code == .invalidEAGLContext, "bridged code")
    glkCheck(error.errorCode == 17, "bridged errorCode")
    glkCheck(error.userInfo[GLKTextureLoaderErrorKey] as? String == "17", "userInfo")
    glkCheck((error.errorUserInfo[GLKTextureLoaderErrorKey] as? String) == "17", "errorUserInfo")
    glkCheck(GLKTextureLoaderError.errorDomain == GLKTextureLoaderErrorDomain, "errorDomain")
    glkCheck(type(of: error).errorDomain == GLKTextureLoaderErrorDomain, "static errorDomain")
    let same = GLKTextureLoaderError(.invalidEAGLContext)
    let also = GLKTextureLoaderError(.invalidEAGLContext)
    let other = GLKTextureLoaderError(.fileOrURLNotFound)
    glkCheck(same == also, "GLKTextureLoaderError ==")
    glkCheck(error != other, "GLKTextureLoaderError !=")
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = error.hashValue
    _ = same.hashValue
    let thrown: any Error = error
    glkCheck(GLKTextureLoaderError.Code.invalidEAGLContext ~= thrown, "~= match")
    glkCheck(!(GLKTextureLoaderError.Code.fileOrURLNotFound ~= thrown), "~= miss")
    glkCheck(!error.localizedDescription.isEmpty, "localizedDescription nonempty")
}
