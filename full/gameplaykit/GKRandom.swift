import Foundation

public protocol GKRandom {
    func nextInt() -> Int
    func nextInt(upperBound: Int) -> Int
    func nextUniform() -> Float
    func nextBool() -> Bool
}

open class GKRandomSource: NSObject, GKRandom, NSCopying {
    private static let shared = GKSystemRandomSource()

    open class func sharedRandom() -> GKRandomSource {
        shared
    }

    public override init() {
        super.init()
    }

    public required init(coder aDecoder: NSCoder) {
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        GKRandomSource()
    }

    open func nextInt() -> Int {
        var generator = SystemRandomNumberGenerator()
        let bits = generator.next()
        return Int(Int32(truncatingIfNeeded: bits))
    }

    open func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        if upperBound == 1 { return 0 }
        var candidate = nextInt()
        if candidate < 0 { candidate = -candidate }
        return candidate % upperBound
    }

    open func nextUniform() -> Float {
        let bits = UInt32(truncatingIfNeeded: nextInt())
        return Float(bits & 0x00FF_FFFF) / Float(0x0100_0000)
    }

    open func nextBool() -> Bool {
        nextInt(upperBound: 2) == 1
    }

    open func arrayByShufflingObjects(in array: [Any]) -> [Any] {
        var result = array
        guard result.count > 1 else { return result }
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let swapIndex = nextInt(upperBound: index + 1)
            result.swapAt(index, swapIndex)
        }
        return result
    }
}

private final class GKSystemRandomSource: GKRandomSource {
    override func copy(with zone: NSZone? = nil) -> Any {
        GKSystemRandomSource()
    }
}

open class GKARC4RandomSource: GKRandomSource {
    private var state: [UInt8] = Array(0...255)
    private var si: Int = 0
    private var sj: Int = 0

    open var seed: Data {
        didSet { resetState() }
    }

    public init(seed: Data) {
        self.seed = seed
        super.init()
        resetState()
    }

    public convenience override init() {
        var bytes = [UInt8](repeating: 0, count: 16)
        var generator = SystemRandomNumberGenerator()
        for index in 0..<bytes.count {
            bytes[index] = UInt8.random(in: 0...255, using: &generator)
        }
        self.init(seed: Data(bytes))
    }

    public required init(coder aDecoder: NSCoder) {
        seed = Data()
        super.init(coder: aDecoder)
        resetState()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = GKARC4RandomSource(seed: seed)
        copy.state = state
        copy.si = si
        copy.sj = sj
        return copy
    }

    private func resetState() {
        state = Array(0...255)
        si = 0
        sj = 0
        let key = seed.isEmpty ? Data([0]) : seed
        var j = 0
        for i in 0..<256 {
            let keyByte = Int(key[key.index(key.startIndex, offsetBy: i % key.count)])
            j = (j + Int(state[i]) + keyByte) & 255
            state.swapAt(i, j)
        }
    }

    private func nextByte() -> UInt8 {
        si = (si + 1) & 255
        sj = (sj + Int(state[si])) & 255
        state.swapAt(si, sj)
        let k = Int(state[si]) + Int(state[sj])
        return state[k & 255]
    }

    open func dropValues(_ count: Int) {
        guard count > 0 else { return }
        for _ in 0..<count {
            _ = nextByte()
        }
    }

    open override func nextInt() -> Int {
        var bits: UInt32 = 0
        for _ in 0..<4 {
            bits = (bits << 8) | UInt32(nextByte())
        }
        return Int(Int32(bitPattern: bits))
    }
}

open class GKLinearCongruentialRandomSource: GKRandomSource {
    open var seed: UInt64

    public init(seed: UInt64) {
        self.seed = seed == 0 ? 1 : seed
        super.init()
    }

    public convenience override init() {
        var generator = SystemRandomNumberGenerator()
        self.init(seed: generator.next())
    }

    public required init(coder aDecoder: NSCoder) {
        seed = 1
        super.init(coder: aDecoder)
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        GKLinearCongruentialRandomSource(seed: seed)
    }

    open override func nextInt() -> Int {
        // Numerical Recipes / Java-style 64-bit LCG; exact Apple constants are unverified.
        seed = seed &* 6_364_136_223_846_793_005 &+ 1
        let bits = UInt32(truncatingIfNeeded: seed >> 32)
        return Int(Int32(bitPattern: bits))
    }
}

open class GKMersenneTwisterRandomSource: GKRandomSource {
    private static let n = 312
    private static let m = 156
    private static let matrixA: UInt64 = 0xB502_6F5A_A966_19E9
    private static let upperMask: UInt64 = 0xFFFF_FFFF_8000_0000
    private static let lowerMask: UInt64 = 0x7FFF_FFFF

    open var seed: UInt64 {
        didSet { twistSeed() }
    }

    private var mt: [UInt64]
    private var index: Int

    public init(seed: UInt64) {
        self.seed = seed
        mt = Array(repeating: 0, count: Self.n)
        index = Self.n
        super.init()
        twistSeed()
    }

    public convenience override init() {
        var generator = SystemRandomNumberGenerator()
        self.init(seed: generator.next())
    }

    public required init(coder aDecoder: NSCoder) {
        seed = 5489
        mt = Array(repeating: 0, count: Self.n)
        index = Self.n
        super.init(coder: aDecoder)
        twistSeed()
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = GKMersenneTwisterRandomSource(seed: seed)
        copy.mt = mt
        copy.index = index
        return copy
    }

    private func twistSeed() {
        mt[0] = seed
        for i in 1..<Self.n {
            mt[i] = 6_364_136_223_846_793_005 &* (mt[i - 1] ^ (mt[i - 1] >> 62)) &+ UInt64(i)
        }
        index = Self.n
    }

    private func nextUInt64() -> UInt64 {
        if index >= Self.n {
            for i in 0..<Self.n {
                let x = (mt[i] & Self.upperMask) | (mt[(i + 1) % Self.n] & Self.lowerMask)
                var xA = x >> 1
                if x & 1 != 0 {
                    xA ^= Self.matrixA
                }
                mt[i] = mt[(i + Self.m) % Self.n] ^ xA
            }
            index = 0
        }
        var y = mt[index]
        index += 1
        y ^= (y >> 29) & 0x5555_5555_5555_5555
        y ^= (y << 17) & 0x71D6_7FFF_EDA6_0000
        y ^= (y << 37) & 0xFFF7_EEE0_0000_0000
        y ^= (y >> 43)
        return y
    }

    open override func nextInt() -> Int {
        Int(Int32(truncatingIfNeeded: nextUInt64()))
    }
}

open class GKRandomDistribution: NSObject, GKRandom {
    public let lowestValue: Int
    public let highestValue: Int
    public let numberOfPossibleOutcomes: Int
    public let source: any GKRandom

    public required init(randomSource source: any GKRandom, lowestValue lowestInclusive: Int, highestValue highestInclusive: Int) {
        let low = min(lowestInclusive, highestInclusive)
        let high = max(lowestInclusive, highestInclusive)
        self.source = source
        self.lowestValue = low
        self.highestValue = high
        self.numberOfPossibleOutcomes = high - low + 1
        super.init()
    }

    public convenience init(lowestValue lowestInclusive: Int, highestValue highestInclusive: Int) {
        self.init(
            randomSource: GKRandomSource.sharedRandom(),
            lowestValue: lowestInclusive,
            highestValue: highestInclusive
        )
    }

    public convenience init(forDieWithSideCount sideCount: Int) {
        self.init(lowestValue: 1, highestValue: max(sideCount, 1))
    }

    open class func d6() -> Self {
        Self(randomSource: GKRandomSource.sharedRandom(), lowestValue: 1, highestValue: 6)
    }

    open class func d20() -> Self {
        Self(randomSource: GKRandomSource.sharedRandom(), lowestValue: 1, highestValue: 20)
    }

    open func nextInt() -> Int {
        if numberOfPossibleOutcomes <= 0 { return lowestValue }
        return lowestValue + source.nextInt(upperBound: numberOfPossibleOutcomes)
    }

    open func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        let value = nextInt() - lowestValue
        return abs(value) % upperBound
    }

    open func nextUniform() -> Float {
        if numberOfPossibleOutcomes <= 1 { return 0 }
        let value = nextInt() - lowestValue
        return Float(value) / Float(numberOfPossibleOutcomes - 1)
    }

    open func nextBool() -> Bool {
        nextInt(upperBound: 2) == 1
    }
}

open class GKGaussianDistribution: GKRandomDistribution {
    public let mean: Float
    public let deviation: Float
    private var spare: Float?
    private let usesRange: Bool

    public required init(randomSource source: any GKRandom, lowestValue lowestInclusive: Int, highestValue highestInclusive: Int) {
        let low = min(lowestInclusive, highestInclusive)
        let high = max(lowestInclusive, highestInclusive)
        self.mean = Float(low + high) / 2
        self.deviation = Float(high - low) / 6
        self.usesRange = true
        super.init(randomSource: source, lowestValue: low, highestValue: high)
    }

    public init(randomSource source: any GKRandom, mean: Float, deviation: Float) {
        self.mean = mean
        self.deviation = abs(deviation)
        self.usesRange = false
        let span = Int(self.deviation * 3 + 0.5)
        super.init(
            randomSource: source,
            lowestValue: Int(mean) - max(span, 0),
            highestValue: Int(mean) + max(span, 0)
        )
    }

    open override func nextInt() -> Int {
        let sample = nextGaussian()
        var rounded = Int(sample.rounded())
        if usesRange {
            rounded = min(max(rounded, lowestValue), highestValue)
        }
        return rounded
    }

    private func nextGaussian() -> Float {
        if let spare {
            self.spare = nil
            return mean + spare * deviation
        }
        var u = source.nextUniform()
        var v = source.nextUniform()
        if u <= 1e-12 { u = 1e-12 }
        if v <= 1e-12 { v = 1e-12 }
        let radius = (-2 * log(Double(u))).squareRoot()
        let theta = 2 * Double.pi * Double(v)
        let z0 = Float(radius * cos(theta))
        spare = Float(radius * sin(theta))
        return mean + z0 * deviation
    }
}

open class GKShuffledDistribution: GKRandomDistribution {
    private var deck: [Int] = []

    public required init(randomSource source: any GKRandom, lowestValue lowestInclusive: Int, highestValue highestInclusive: Int) {
        super.init(randomSource: source, lowestValue: lowestInclusive, highestValue: highestInclusive)
        refill()
    }

    private func refill() {
        deck = Array(lowestValue...highestValue)
        var working = deck
        if working.count > 1 {
            for index in stride(from: working.count - 1, through: 1, by: -1) {
                let swapIndex = source.nextInt(upperBound: index + 1)
                working.swapAt(index, swapIndex)
            }
        }
        deck = working
    }

    open override func nextInt() -> Int {
        if deck.isEmpty {
            refill()
        }
        return deck.removeLast()
    }
}

extension NSArray {
    public func shuffled() -> [Any] {
        shuffled(using: GKRandomSource.sharedRandom())
    }

    public func shuffled(using randomSource: GKRandomSource) -> [Any] {
        randomSource.arrayByShufflingObjects(in: self as! [Any])
    }
}
