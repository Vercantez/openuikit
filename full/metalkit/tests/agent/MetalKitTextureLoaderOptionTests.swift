import Foundation
import MetalKit

func testTextureLoaderOptionConstants() {
    let table: [(MTKTextureLoader.Option, String)] = [
        (.allocateMipmaps, "MTKTextureLoaderOptionAllocateMipmaps"),
        (.generateMipmaps, "MTKTextureLoaderOptionGenerateMipmaps"),
        (.SRGB, "MTKTextureLoaderOptionSRGB"),
        (.textureUsage, "MTKTextureLoaderOptionTextureUsage"),
        (.textureCPUCacheMode, "MTKTextureLoaderOptionTextureCPUCacheMode"),
        (.textureStorageMode, "MTKTextureLoaderOptionTextureStorageMode"),
        (.cubeLayout, "MTKTextureLoaderOptionCubeLayout"),
        (.origin, "MTKTextureLoaderOptionOrigin"),
        (.loadAsArray, "MTKTextureLoaderOptionLoadAsArray"),
    ]
    for (option, raw) in table {
        precondition(option.rawValue == raw)
    }
    precondition(MTKTextureLoader.Option.allocateMipmaps != MTKTextureLoader.Option.generateMipmaps)
}

func testTextureLoaderOriginConstants() {
    precondition(MTKTextureLoader.Origin.topLeft.rawValue == "MTKTextureLoaderOriginTopLeft")
    precondition(MTKTextureLoader.Origin.bottomLeft.rawValue == "MTKTextureLoaderOriginBottomLeft")
    precondition(MTKTextureLoader.Origin.flippedVertically.rawValue == "MTKTextureLoaderOriginFlippedVertically")
    precondition(MTKTextureLoader.Origin.topLeft != MTKTextureLoader.Origin.bottomLeft)
}

func testTextureLoaderCubeLayoutConstant() {
    precondition(MTKTextureLoader.CubeLayout.vertical.rawValue == "MTKTextureLoaderCubeLayoutVertical")
}

func testTextureLoaderErrorConstants() {
    precondition(MTKTextureLoader.Error.domain.rawValue == "MTKTextureLoaderErrorDomain")
    precondition(MTKTextureLoader.Error.key.rawValue == "MTKTextureLoaderErrorKey")
    precondition(MTKTextureLoader.Error.domain != MTKTextureLoader.Error.key)
}

func testTextureLoaderOptionRawValueAndHashable() {
    let option = MTKTextureLoader.Option(rawValue: "MTKTextureLoaderOptionSRGB")
    precondition(option == .SRGB)
    precondition(option != .origin)
    var hasher = Hasher()
    option.hash(into: &hasher)
    precondition(option.hashValue == MTKTextureLoader.Option.SRGB.hashValue)
}

func testTextureLoaderOriginRawValueAndHashable() {
    let origin = MTKTextureLoader.Origin(rawValue: "MTKTextureLoaderOriginTopLeft")
    precondition(origin == .topLeft)
    precondition(origin != .flippedVertically)
    var hasher = Hasher()
    origin.hash(into: &hasher)
    precondition(origin.hashValue == MTKTextureLoader.Origin.topLeft.hashValue)
}

func testTextureLoaderErrorRawValueAndHashable() {
    let error = MTKTextureLoader.Error(rawValue: "MTKTextureLoaderErrorDomain")
    precondition(error == .domain)
    precondition(error != .key)
    var hasher = Hasher()
    error.hash(into: &hasher)
    precondition(error.hashValue == MTKTextureLoader.Error.domain.hashValue)
}

func testTextureLoaderCubeLayoutRawValueAndHashable() {
    let layout = MTKTextureLoader.CubeLayout(rawValue: "MTKTextureLoaderCubeLayoutVertical")
    precondition(layout == .vertical)
    precondition(!(layout != .vertical))
    var hasher = Hasher()
    layout.hash(into: &hasher)
    precondition(layout.hashValue == MTKTextureLoader.CubeLayout.vertical.hashValue)
}
