import Foundation

open class GKNoiseSource: NSObject {
    func value(at x: Double, y: Double, z: Double) -> Double { 0 }
}

open class GKCoherentNoiseSource: GKNoiseSource {
    public var frequency: Double = 1
    public var octaveCount: Int = 6
    public var lacunarity: Double = 2
    public var seed: Int32 = 0

    func fade(_ t: Double) -> Double {
        t * t * t * (t * (t * 6 - 15) + 10)
    }

    func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + t * (b - a)
    }

    func grad(_ hash: Int, _ x: Double, _ y: Double, _ z: Double) -> Double {
        let h = hash & 15
        let u = h < 8 ? x : y
        let v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }

    func permutation() -> [Int] {
        var p = Array(0..<256)
        var state = UInt64(bitPattern: Int64(seed))
        if state == 0 { state = 0x9E37_79B9_7F4A_7C15 }
        for i in stride(from: 255, through: 1, by: -1) {
            state = state &* 6_364_136_223_846_793_005 &+ 1
            let j = Int(state % UInt64(i + 1))
            p.swapAt(i, j)
        }
        return p + p
    }

    func perlin(_ x: Double, _ y: Double, _ z: Double) -> Double {
        let perm = permutation()
        let xi = Int(floor(x)) & 255
        let yi = Int(floor(y)) & 255
        let zi = Int(floor(z)) & 255
        let xf = x - floor(x)
        let yf = y - floor(y)
        let zf = z - floor(z)
        let u = fade(xf)
        let v = fade(yf)
        let w = fade(zf)
        let aaa = perm[perm[perm[xi] + yi] + zi]
        let aba = perm[perm[perm[xi] + yi + 1] + zi]
        let aab = perm[perm[perm[xi] + yi] + zi + 1]
        let abb = perm[perm[perm[xi] + yi + 1] + zi + 1]
        let baa = perm[perm[perm[xi + 1] + yi] + zi]
        let bba = perm[perm[perm[xi + 1] + yi + 1] + zi]
        let bab = perm[perm[perm[xi + 1] + yi] + zi + 1]
        let bbb = perm[perm[perm[xi + 1] + yi + 1] + zi + 1]
        let x1 = lerp(grad(aaa, xf, yf, zf), grad(baa, xf - 1, yf, zf), u)
        let x2 = lerp(grad(aba, xf, yf - 1, zf), grad(bba, xf - 1, yf - 1, zf), u)
        let y1 = lerp(x1, x2, v)
        let x3 = lerp(grad(aab, xf, yf, zf - 1), grad(bab, xf - 1, yf, zf - 1), u)
        let x4 = lerp(grad(abb, xf, yf - 1, zf - 1), grad(bbb, xf - 1, yf - 1, zf - 1), u)
        let y2 = lerp(x3, x4, v)
        return lerp(y1, y2, w)
    }

    func fractal(_ x: Double, _ y: Double, _ z: Double, persistence: Double) -> Double {
        var amplitude = 1.0
        var freq = frequency
        var total = 0.0
        var maxValue = 0.0
        let octaves = max(octaveCount, 1)
        for _ in 0..<octaves {
            total += perlin(x * freq, y * freq, z * freq) * amplitude
            maxValue += amplitude
            amplitude *= persistence
            freq *= lacunarity
        }
        if maxValue == 0 { return 0 }
        return total / maxValue
    }
}

open class GKPerlinNoiseSource: GKCoherentNoiseSource {
    public var persistence: Double = 0.5

    public init(frequency: Double, octaveCount: Int, persistence: Double, lacunarity: Double, seed: Int32) {
        super.init()
        self.frequency = frequency
        self.octaveCount = octaveCount
        self.persistence = persistence
        self.lacunarity = lacunarity
        self.seed = seed
    }

    public override init() {
        super.init()
    }

    override func value(at x: Double, y: Double, z: Double) -> Double {
        fractal(x, y, z, persistence: persistence)
    }
}

open class GKBillowNoiseSource: GKCoherentNoiseSource {
    public var persistence: Double = 0.5

    public init(frequency: Double, octaveCount: Int, persistence: Double, lacunarity: Double, seed: Int32) {
        super.init()
        self.frequency = frequency
        self.octaveCount = octaveCount
        self.persistence = persistence
        self.lacunarity = lacunarity
        self.seed = seed
    }

    override func value(at x: Double, y: Double, z: Double) -> Double {
        abs(fractal(x, y, z, persistence: persistence)) * 2 - 1
    }
}

open class GKRidgedNoiseSource: GKCoherentNoiseSource {
    public init(frequency: Double, octaveCount: Int, lacunarity: Double, seed: Int32) {
        super.init()
        self.frequency = frequency
        self.octaveCount = octaveCount
        self.lacunarity = lacunarity
        self.seed = seed
    }

    override func value(at x: Double, y: Double, z: Double) -> Double {
        1 - abs(fractal(x, y, z, persistence: 0.5))
    }
}

open class GKConstantNoiseSource: GKNoiseSource {
    public var value: Double

    public required init(value: Double) {
        self.value = value
        super.init()
    }

    open class func constantNoise(withValue value: Double) -> Self {
        Self(value: value)
    }

    override func value(at x: Double, y: Double, z: Double) -> Double { value }
}

open class GKCylindersNoiseSource: GKNoiseSource {
    public var frequency: Double

    public required init(frequency: Double) {
        self.frequency = frequency
        super.init()
    }

    open class func cylindersNoise(withFrequency frequency: Double) -> Self {
        Self(frequency: frequency)
    }

    override func value(at x: Double, y: Double, z: Double) -> Double {
        let dist = (x * x + z * z).squareRoot() * frequency
        let nearest = dist - dist.rounded()
        return 1 - abs(nearest) * 4
    }
}

open class GKSpheresNoiseSource: GKNoiseSource {
    public var frequency: Double

    public required init(frequency: Double) {
        self.frequency = frequency
        super.init()
    }

    open class func spheresNoise(withFrequency frequency: Double) -> Self {
        Self(frequency: frequency)
    }

    override func value(at x: Double, y: Double, z: Double) -> Double {
        let dist = (x * x + y * y + z * z).squareRoot() * frequency
        let nearest = dist - dist.rounded()
        return 1 - abs(nearest) * 4
    }
}

open class GKCheckerboardNoiseSource: GKNoiseSource {
    public var squareSize: Double

    public required init(squareSize: Double) {
        self.squareSize = max(squareSize, 1e-6)
        super.init()
    }

    open class func checkerboardNoise(withSquareSize squareSize: Double) -> Self {
        Self(squareSize: squareSize)
    }

    override func value(at x: Double, y: Double, z: Double) -> Double {
        let xi = Int(floor(x / squareSize))
        let yi = Int(floor(y / squareSize))
        let zi = Int(floor(z / squareSize))
        return ((xi + yi + zi) & 1) == 0 ? 1 : -1
    }
}

open class GKVoronoiNoiseSource: GKNoiseSource {
    public var frequency: Double
    public var displacement: Double
    public var isDistanceEnabled: Bool
    public var seed: Int32

    public required init(frequency: Double, displacement: Double, distanceEnabled: Bool, seed: Int32) {
        self.frequency = frequency
        self.displacement = displacement
        self.isDistanceEnabled = distanceEnabled
        self.seed = seed
        super.init()
    }

    open class func voronoiNoise(
        withFrequency frequency: Double,
        displacement: Double,
        distanceEnabled: Bool,
        seed: Int32
    ) -> Self {
        Self(frequency: frequency, displacement: displacement, distanceEnabled: distanceEnabled, seed: seed)
    }

    private func cellPoint(_ ix: Int, _ iy: Int) -> SIMD2<Double> {
        var h = UInt64(bitPattern: Int64(seed))
            ^ (UInt64(bitPattern: Int64(ix)) &* 0x9E37_79B9_7F4A_7C15)
            ^ (UInt64(bitPattern: Int64(iy)) &* 0xBF58_476D_1CE4_E5B9)
        h ^= h >> 30
        h &*= 0xBF58_476D_1CE4_E5B9
        let fx = Double(h & 0xFFFF_FFFF) / Double(UInt32.max)
        h ^= h >> 27
        let fy = Double(h & 0xFFFF_FFFF) / Double(UInt32.max)
        return SIMD2<Double>(Double(ix) + fx, Double(iy) + fy)
    }

    override func value(at x: Double, y: Double, z: Double) -> Double {
        let px = x * frequency
        let py = y * frequency
        let ix = Int(floor(px))
        let iy = Int(floor(py))
        var best = Double.greatestFiniteMagnitude
        var bestHash = 0.0
        for oy in -1...1 {
            for ox in -1...1 {
                let candidate = cellPoint(ix + ox, iy + oy)
                let dx = px - candidate.x
                let dy = py - candidate.y
                let d = (dx * dx + dy * dy).squareRoot()
                if d < best {
                    best = d
                    bestHash = Double((ix + ox) &* 31 &+ (iy + oy))
                }
            }
        }
        if isDistanceEnabled {
            return gkClamp(Float(1 - best * displacement), -1, 1).doubleValue
        }
        return sin(bestHash + Double(seed)) * displacement
    }
}

private extension Float {
    var doubleValue: Double { Double(self) }
}

private enum GKNoiseOp {
    case source(GKNoiseSource)
    case constant(Double)
    case add(GKNoise, GKNoise)
    case multiply(GKNoise, GKNoise)
    case min(GKNoise, GKNoise)
    case max(GKNoise, GKNoise)
    case invert(GKNoise)
    case abs(GKNoise)
    case clamp(GKNoise, Double, Double)
    case raise(GKNoise, Double)
    case raiseNoise(GKNoise, GKNoise)
    case select(GKNoise, GKNoise, GKNoise)
    case blend([GKNoise], GKNoise, [Double], [Double])
}

open class GKNoise: NSObject {
    private var op: GKNoiseOp
    private var translation = SIMD3<Double>(0, 0, 0)
    private var scale = SIMD3<Double>(1, 1, 1)
    private var rotation = SIMD3<Double>(0, 0, 0)

    public override convenience init() {
        self.init(GKConstantNoiseSource(value: 0))
    }

    public convenience init(_ noiseSource: GKNoiseSource) {
        self.init(op: .source(noiseSource))
    }

    public convenience init(noiseSource: GKNoiseSource) {
        self.init(noiseSource)
    }

    public convenience init(componentNoises noises: [GKNoise], selectionNoise: GKNoise) {
        self.init(op: .select(noises.first ?? GKNoise(), noises.last ?? GKNoise(), selectionNoise))
    }

    public convenience init(
        componentNoises noises: [GKNoise],
        selectionNoise: GKNoise,
        componentBoundaries: [NSNumber],
        boundaryBlendDistances blendDistances: [NSNumber]
    ) {
        self.init(
            op: .blend(
                noises,
                selectionNoise,
                componentBoundaries.map { $0.doubleValue },
                blendDistances.map { $0.doubleValue }
            )
        )
    }

    private init(op: GKNoiseOp) {
        self.op = op
        super.init()
    }

    open func value(atPosition position: SIMD2<Float>) -> Float {
        Float(sample(Double(position.x), Double(position.y), 0))
    }

    func sample(_ x: Double, _ y: Double, _ z: Double) -> Double {
        let cosR = cos(rotation.z)
        let sinR = sin(rotation.z)
        let rx = x * cosR - y * sinR
        let ry = x * sinR + y * cosR
        let px = rx * scale.x + translation.x
        let py = ry * scale.y + translation.y
        let pz = z * scale.z + translation.z
        return evaluate(px, py, pz)
    }

    private func evaluate(_ x: Double, _ y: Double, _ z: Double) -> Double {
        switch op {
        case .source(let source):
            return source.value(at: x, y: y, z: z)
        case .constant(let value):
            return value
        case .add(let a, let b):
            return a.sample(x, y, z) + b.sample(x, y, z)
        case .multiply(let a, let b):
            return a.sample(x, y, z) * b.sample(x, y, z)
        case .min(let a, let b):
            return min(a.sample(x, y, z), b.sample(x, y, z))
        case .max(let a, let b):
            return max(a.sample(x, y, z), b.sample(x, y, z))
        case .invert(let noise):
            return -noise.sample(x, y, z)
        case .abs(let noise):
            return abs(noise.sample(x, y, z))
        case .clamp(let noise, let lo, let hi):
            return min(max(noise.sample(x, y, z), lo), hi)
        case .raise(let noise, let power):
            return pow(noise.sample(x, y, z), power)
        case .raiseNoise(let noise, let power):
            return pow(noise.sample(x, y, z), power.sample(x, y, z))
        case .select(let a, let b, let control):
            return control.sample(x, y, z) > 0 ? b.sample(x, y, z) : a.sample(x, y, z)
        case .blend(let noises, let control, let bounds, _):
            let t = control.sample(x, y, z)
            if noises.isEmpty { return 0 }
            var index = 0
            for (i, bound) in bounds.enumerated() where t >= bound {
                index = min(i + 1, noises.count - 1)
            }
            return noises[index].sample(x, y, z)
        }
    }

    open func add(_ noise: GKNoise) { op = .add(GKNoise(op: op), noise) }
    open func multiply(_ noise: GKNoise) { op = .multiply(GKNoise(op: op), noise) }
    open func minimum(_ noise: GKNoise) { op = .min(GKNoise(op: op), noise) }
    open func maximum(_ noise: GKNoise) { op = .max(GKNoise(op: op), noise) }
    open func invert() { op = .invert(GKNoise(op: op)) }
    open func applyAbsoluteValue() { op = .abs(GKNoise(op: op)) }
    open func clamp(lowerBound: Double, upperBound: Double) {
        op = .clamp(GKNoise(op: op), lowerBound, upperBound)
    }
    open func raiseToPower(_ power: Double) { op = .raise(GKNoise(op: op), power) }
    open func raiseToPower(_ noise: GKNoise) { op = .raiseNoise(GKNoise(op: op), noise) }
    open func move(by delta: SIMD3<Double>) { translation = translation + delta }
    open func scale(by factor: SIMD3<Double>) { scale = SIMD3<Double>(scale.x * factor.x, scale.y * factor.y, scale.z * factor.z) }
    open func rotate(by radians: SIMD3<Double>) { rotation = rotation + radians }

    open func applyTurbulence(frequency: Double, power: Double, roughness: Int32, seed: Int32) {
        let turbulence = GKPerlinNoiseSource(
            frequency: frequency,
            octaveCount: Int(max(roughness, 1)),
            persistence: 0.5,
            lacunarity: 2,
            seed: seed
        )
        op = .add(GKNoise(op: op), GKNoise(turbulence) )
        _ = power
    }

    open func displaceWithNoises(x xDisplacementNoise: GKNoise, y yDisplacementNoise: GKNoise, z zDisplacementNoise: GKNoise) {
        let current = GKNoise(op: op)
        op = .add(current, xDisplacementNoise)
        _ = yDisplacementNoise
        _ = zDisplacementNoise
    }

    open func remapValues(toCurveWithControlPoints controlPoints: [NSNumber: NSNumber]) {
        let pairs = controlPoints.keys.compactMap { key -> (Double, Double)? in
            guard let y = controlPoints[key] else { return nil }
            return (key.doubleValue, y.doubleValue)
        }.sorted { $0.0 < $1.0 }
        guard !pairs.isEmpty else { return }
        let current = GKNoise(op: op)
        op = .clamp(current, pairs.first!.0, pairs.last!.0)
    }

    open func remapValues(toTerracesWithPeaks peakInputValues: [NSNumber], terracesInverted inverted: Bool) {
        _ = inverted
        if let first = peakInputValues.first, let last = peakInputValues.last {
            clamp(lowerBound: first.doubleValue, upperBound: last.doubleValue)
        }
    }
}

open class GKNoiseMap: NSObject {
    public let size: SIMD2<Double>
    public let origin: SIMD2<Double>
    public let sampleCount: SIMD2<Int32>
    public let isSeamless: Bool
    private var samples: [Float]

    public override convenience init() {
        self.init(GKNoise())
    }

    public convenience init(_ noise: GKNoise) {
        self.init(noise, size: SIMD2<Double>(2, 2), origin: SIMD2<Double>(-1, -1), sampleCount: SIMD2<Int32>(256, 256), seamless: false)
    }

    public convenience init(noise: GKNoise) {
        self.init(noise)
    }

    public convenience init(
        noise: GKNoise,
        size: SIMD2<Double>,
        origin: SIMD2<Double>,
        sampleCount: SIMD2<Int32>,
        seamless: Bool
    ) {
        self.init(noise, size: size, origin: origin, sampleCount: sampleCount, seamless: seamless)
    }

    public init(
        _ noise: GKNoise,
        size: SIMD2<Double>,
        origin: SIMD2<Double>,
        sampleCount: SIMD2<Int32>,
        seamless: Bool
    ) {
        self.size = size
        self.origin = origin
        self.sampleCount = sampleCount
        self.isSeamless = seamless
        let width = max(Int(sampleCount.x), 1)
        let height = max(Int(sampleCount.y), 1)
        var data = Array(repeating: Float(0), count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let u = Double(x) / Double(max(width - 1, 1))
                let v = Double(y) / Double(max(height - 1, 1))
                let px = origin.x + u * size.x
                let py = origin.y + v * size.y
                data[y * width + x] = noise.value(atPosition: SIMD2<Float>(Float(px), Float(py)))
            }
        }
        self.samples = data
        super.init()
    }

    open func value(at position: SIMD2<Int32>) -> Float {
        let width = max(Int(sampleCount.x), 1)
        let height = max(Int(sampleCount.y), 1)
        let x = min(max(Int(position.x), 0), width - 1)
        let y = min(max(Int(position.y), 0), height - 1)
        return samples[y * width + x]
    }

    open func setValue(_ value: Float, at position: SIMD2<Int32>) {
        let width = max(Int(sampleCount.x), 1)
        let height = max(Int(sampleCount.y), 1)
        let x = Int(position.x)
        let y = Int(position.y)
        guard x >= 0, y >= 0, x < width, y < height else { return }
        samples[y * width + x] = value
    }

    open func interpolatedValue(at position: SIMD2<Float>) -> Float {
        let width = max(Int(sampleCount.x), 1)
        let height = max(Int(sampleCount.y), 1)
        let x = Double(position.x)
        let y = Double(position.y)
        let x0 = Int(floor(x))
        let y0 = Int(floor(y))
        let x1 = min(x0 + 1, width - 1)
        let y1 = min(y0 + 1, height - 1)
        let tx = Float(x - floor(x))
        let ty = Float(y - floor(y))
        let v00 = value(at: SIMD2<Int32>(Int32(max(x0, 0)), Int32(max(y0, 0))))
        let v10 = value(at: SIMD2<Int32>(Int32(x1), Int32(max(y0, 0))))
        let v01 = value(at: SIMD2<Int32>(Int32(max(x0, 0)), Int32(y1)))
        let v11 = value(at: SIMD2<Int32>(Int32(x1), Int32(y1)))
        let a = v00 + (v10 - v00) * tx
        let b = v01 + (v11 - v01) * tx
        return a + (b - a) * ty
    }
}
