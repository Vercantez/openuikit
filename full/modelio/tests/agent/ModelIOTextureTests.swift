import Foundation
import ModelIO

func testTextureData() {
    let pixels = Data([1, 2, 3, 4, 5, 6, 7, 8])
    let texture = MDLTexture(
        data: pixels,
        topLeftOrigin: true,
        name: "tex",
        dimensions: SIMD2<Int32>(2, 1),
        rowStride: 8,
        channelCount: 4,
        channelEncoding: .uInt8,
        isCube: false
    )
    mdlCheck(texture.name == "tex", "name")
    mdlCheck(texture.dimensions.x == 2, "dim")
    mdlCheck(texture.rowStride == 8, "stride")
    mdlCheck(texture.channelCount == 4, "channels")
    mdlCheck(texture.channelEncoding == .uInt8, "enc")
    mdlCheck(texture.hasAlphaValues, "alpha")
    mdlCheck(texture.mipLevelCount == 1, "mips")
    texture.isCube = true
    mdlCheck(texture.isCube, "cube flag")
    let top = texture.texelDataWithTopLeftOrigin()
    mdlCheck(top == pixels, "top left")
    let bottom = texture.texelDataWithBottomLeftOrigin()
    mdlCheck(bottom != nil, "bottom")
    mdlCheck(texture.texelDataWithTopLeftOrigin(atMipLevel: 0, create: false) != nil, "mip top")
    mdlCheck(texture.texelDataWithBottomLeftOrigin(atMipLevel: 0, create: true) != nil, "mip bottom")
    let empty = MDLTexture()
    mdlCheck(empty.dimensions.x == 1, "default")
}

func testTextureWrite() {
    let texture = MDLTexture(
        data: Data([9, 8, 7, 6]),
        topLeftOrigin: true,
        name: "w",
        dimensions: SIMD2<Int32>(1, 1),
        rowStride: 4,
        channelCount: 4,
        channelEncoding: .uInt8,
        isCube: false
    )
    let url = mdlTempDir().appendingPathComponent("t.bin")
    try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    mdlCheck(texture.write(to: url), "write")
    mdlCheck(texture.write(to: url, level: 0), "write level")
    mdlCheck(texture.write(to: url, type: "public.png" as NSString), "write type")
    mdlCheck(texture.write(to: url, type: "public.png" as NSString, level: 0), "write type level")
}

func testNamedTextureMissing() {
    mdlCheck(MDLTexture(named: "definitely-missing-modelio") == nil, "named")
    mdlCheck(MDLTexture(named: "missing", bundle: nil) == nil, "bundle")
    let resolver = MDLPathAssetResolver(path: "/no/such/modelio")
    mdlCheck(MDLTexture(named: "x", assetResolver: resolver) == nil, "resolver")
    mdlCheck(MDLTexture(cubeWithImagesNamed: ["a"]) == nil, "cube short")
    mdlCheck(MDLTexture(cubeWithImagesNamed: ["a", "b", "c", "d", "e", "f"], bundle: nil) != nil, "cube 6")
}

func testIrradianceCube() {
    let source = MDLTexture()
    let cube = MDLTexture.irradianceTextureCube(with: source, name: "irr", dimensions: SIMD2<Int32>(4, 4))
    mdlCheck(cube.isCube, "cube")
    let rough = MDLTexture.irradianceTextureCube(with: source, name: "irr2", dimensions: SIMD2<Int32>(2, 2), roughness: 0.5)
    mdlCheck(rough.dimensions.x == 2, "rough dim")
}

func testTextureFilter() {
    let filter = MDLTextureFilter()
    filter.magFilter = .nearest
    filter.minFilter = .linear
    filter.mipFilter = .nearest
    filter.sWrapMode = .repeat
    filter.tWrapMode = .mirror
    filter.rWrapMode = .clamp
    mdlCheck(filter.magFilter == .nearest, "mag")
    mdlCheck(filter.minFilter == .linear, "min")
    mdlCheck(filter.mipFilter == .nearest, "mip")
    mdlCheck(filter.sWrapMode == .repeat, "s")
    mdlCheck(filter.tWrapMode == .mirror, "t")
    mdlCheck(filter.rWrapMode == .clamp, "r")
}

func testTextureSampler() {
    let sampler = MDLTextureSampler()
    sampler.texture = MDLTexture()
    sampler.hardwareFilter = MDLTextureFilter()
    sampler.transform = MDLTransform()
    mdlCheck(sampler.texture != nil, "tex")
    mdlCheck(sampler.hardwareFilter != nil, "filter")
    mdlCheck(sampler.transform != nil, "xform")
}

func testURLTexture() {
    let directory = mdlTempDir()
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("p.bin")
    try! Data([1, 2, 3, 4]).write(to: url)
    let texture = MDLURLTexture(url: url, name: "u")
    mdlCheck(texture.url == url, "url")
    let via = MDLURLTexture(URL: url, name: "U")
    mdlCheck(via.url == url, "URL:")
}

func testCheckerboard() {
    let board = MDLCheckerboardTexture(
        divisions: 4,
        name: "check",
        dimensions: SIMD2<Int32>(8, 8),
        channelCount: 1,
        channelEncoding: .uInt8
    )
    mdlCheck(board.divisions == 4, "divisions")
    let data = board.texelDataWithTopLeftOrigin()
    mdlCheck(data?.count == 64, "8x8")
    mdlCheck(data![0] != data![1] || data![0] == 255 || data![0] == 0, "pattern bytes")
}

func testColorTemperatureSwatch() {
    let swatch = MDLColorSwatchTexture(
        colorTemperatureGradientFrom: 2700,
        toColorTemperature: 6500,
        name: "kelvin",
        textureDimensions: SIMD2<Int32>(16, 4)
    )
    mdlCheck(swatch.dimensions.x == 16, "width")
    mdlCheck(swatch.texelDataWithTopLeftOrigin()?.count == 16 * 4 * 4, "rgba")
}

func testNoiseTextures() {
    let vector = MDLNoiseTexture(
        vectorNoiseWithSmoothness: 2,
        name: "vn",
        textureDimensions: SIMD2<Int32>(8, 8),
        channelEncoding: .uInt8
    )
    mdlCheck(vector.channelCount == 3, "vector channels")
    let scalar = MDLNoiseTexture(
        scalarNoiseWithSmoothness: 2,
        name: "sn",
        textureDimensions: SIMD2<Int32>(8, 8),
        channelCount: 1,
        channelEncoding: .uInt8,
        grayscale: true
    )
    mdlCheck(scalar.channelCount == 1, "scalar")
    let cellular = MDLNoiseTexture(
        cellularNoiseWithFrequency: 4,
        name: "cn",
        textureDimensions: SIMD2<Int32>(8, 8),
        channelEncoding: .uInt8
    )
    mdlCheck(cellular.texelDataWithTopLeftOrigin()?.count == 64, "cellular")
}

func testNormalMap() {
    let source = MDLNoiseTexture(
        scalarNoiseWithSmoothness: 2,
        name: "h",
        textureDimensions: SIMD2<Int32>(8, 8),
        channelCount: 1,
        channelEncoding: .uInt8,
        grayscale: true
    )
    let n1 = MDLNormalMapTexture(
        byGeneratingNormalMapWith: source,
        name: "n1",
        smoothness: 1,
        contrast: 1
    )
    mdlCheck(n1.channelCount == 3, "from convenience")
    let n2 = MDLNormalMapTexture(
        byGeneratingNormalMapWithTexture: source,
        name: "n2",
        smoothness: 1,
        contrast: 2
    )
    mdlCheck(n2.dimensions.x == 8, "from designated")
}

func testSkyCube() {
    let sky = MDLSkyCubeTexture(
        name: "sky",
        channelEncoding: .uInt8,
        textureDimensions: SIMD2<Int32>(16, 16),
        turbidity: 2,
        sunElevation: 0.8,
        sunAzimuth: 0.2,
        upperAtmosphereScattering: 0.5,
        groundAlbedo: 0.3
    )
    mdlCheck(sky.isCube, "cube")
    sky.turbidity = 1
    sky.sunElevation = 0.5
    sky.sunAzimuth = 0
    sky.upperAtmosphereScattering = 0.4
    sky.groundAlbedo = 0.2
    sky.horizonElevation = 0.1
    sky.brightness = 1.2
    sky.contrast = 1
    sky.exposure = 0
    sky.gamma = 1
    sky.saturation = 1
    sky.highDynamicRangeCompression = SIMD2(1, 1)
    sky.update()
    mdlCheck(sky.texelDataWithTopLeftOrigin()?.count == 16 * 16 * 4, "pixels")
    let short = MDLSkyCubeTexture(
        name: "sky2",
        channelEncoding: .uInt8,
        textureDimensions: SIMD2<Int32>(8, 8),
        turbidity: 1,
        sunElevation: 0.7,
        upperAtmosphereScattering: 0.4,
        groundAlbedo: 0.2
    )
    mdlCheck(short.dimensions.x == 8, "no-azimuth init")
}
