// Destination/backdrop filtering for Canvas.
//
// A backdrop filter is different from drawing a blurred image: it samples
// pixels that are already present in the current render target, expands the
// read window by the complete blur support, and replaces only the requested
// (and currently clipped) destination region.  Both Canvas backends use the
// same CPU kernel so output is deterministic across platforms.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGRect
#elseif canImport(Foundation)
import Foundation
#endif

/// Backend-neutral parameters for filtering pixels already rendered beneath
/// a Canvas region.
///
/// Operations run in this order: Gaussian blur, saturation, tint.  The blur
/// radius is the Gaussian sigma in user-space points and therefore follows
/// the Canvas CTM's area-equivalent scalar scale (`sqrt(abs(determinant))`).
/// This is intentionally backend-neutral, but means anisotropic scale and
/// shear do not produce a directional/elliptical blur; they use that single
/// scalar approximation. To keep both time and storage bounded by the finite
/// destination, device-space sigma is capped at four times the larger Canvas
/// pixel dimension. Larger requests use that finite-image approximation; they
/// are not an exact infinite-radius Gaussian limit. Saturation `1` is unchanged
/// and `0` is grayscale.
/// Tint is composited source-over the filtered result.
/// `intensity` linearly mixes the complete filtered result with the original
/// backdrop; it is useful for effect transitions and group opacity.
///
/// Both Canvas backends run the same filter kernel for identical input bytes,
/// but their pre-filter compositors may differ by one byte count. Saturation
/// above `1` can amplify and clamp that difference, so a post-filter channel
/// can legitimately differ anywhere across the full `0...255` byte range.
public struct CanvasBackdropFilterConfiguration: Equatable, Sendable {
    public var blurRadius: CGFloat
    public var saturation: CGFloat
    public var tintColor: CGColor?
    public var intensity: CGFloat

    public init(blurRadius: CGFloat = 0,
                saturation: CGFloat = 1,
                tintColor: CGColor? = nil,
                intensity: CGFloat = 1) {
        self.blurRadius = blurRadius
        self.saturation = saturation
        self.tintColor = tintColor
        self.intensity = intensity
    }
}

extension Canvas {
    /// Filter the already-rendered destination beneath `rect` in current user
    /// space.  Sampling expands beyond `rect` by the blur kernel's full
    /// support, while writes remain bounded by the transformed rect and the
    /// current clip.  Samples at the Canvas edge use edge replication rather
    /// than transparent padding, avoiding dark/transparent edge fringes.
    public func applyBackdropFilter(_ configuration: CanvasBackdropFilterConfiguration,
                                    in rect: CGRect) {
        guard bitmap.width > 0, bitmap.height > 0 else { return }

        let intensity = Self._finiteClamped(configuration.intensity,
                                            lower: 0, upper: 1, fallback: 0)
        guard intensity > 0 else { return }
        let saturation = Self._finiteClamped(configuration.saturation,
                                             lower: 0,
                                             upper: 1_000,
                                             fallback: 1)
        let blurRadius = Self._finiteClamped(configuration.blurRadius,
                                             lower: 0,
                                             upper: CGFloat.greatestFiniteMagnitude,
                                             fallback: 0)
        let tint = configuration.tintColor.map(Self._normalizedBackdropColor)
        let hasTint = (tint?.alpha ?? 0) > 0
        guard blurRadius > 0 || saturation != 1 || hasTint else { return }

        guard var coverage = _BackdropFilterGeometry.coverage(
            of: rect, transform: state.ctm,
            width: bitmap.width, height: bitmap.height)
        else { return }

        // Region coverage is produced by the same analytic rasterizer that
        // mirrors Canvas clips for both backends.  Multiplying the current
        // clip here gives replacement semantics at antialiased boundaries:
        // filtered and original premultiplied pixels are interpolated once.
        if let clip = state.clipMask {
            for index in coverage.indices {
                let c = coverage[index]
                if c == 0 { continue }
                let m = clip[index]
                coverage[index] = m == 255
                    ? c
                    : UInt8((Int(c) * Int(m) + 127) / 255)
            }
        }

        guard let bounds = _CanvasDeviceBounds.coverageBounds(
            coverage, width: bitmap.width, height: bitmap.height)
        else { return }

        let t = state.ctm
        // Take the square root while the determinant is still represented as
        // an exact dyadic sum.  Rounding |a*d-b*c| to CGFloat first loses
        // determinants below 2^-1074 and saturates determinants above
        // CGFloat.greatestFiniteMagnitude even though their square roots can
        // be perfectly representable (for example uniform scales 2^+-600).
        let effectiveScale = _BackdropFilterGeometry.areaEquivalentScale(
            a: t.a, b: t.b, c: t.c, d: t.d)
        let requestedSigma = blurRadius > 0
            ? Double(blurRadius) * Double(effectiveScale)
            : 0
        // Keep hostile-but-finite input from overflowing integer kernel
        // arithmetic.  Beyond four surface spans an edge-clamped Gaussian is
        // already visually converged for this finite image.
        let surfaceSpan = Swift.max(bitmap.width, bitmap.height)
        let maximumSigma = Double(Swift.max(1, surfaceSpan)) * 4
        let sigma = requestedSigma.isFinite
            ? Swift.min(requestedSigma, maximumSigma)
            : maximumSigma
        let resolved = _CanvasBackdropFilter(
            boxRadii: _BackdropFilterCPU.boxRadii(forSigma: sigma),
            saturation: Double(saturation),
            tint: tint,
            intensity: Double(intensity))
        backend.applyBackdropFilter(resolved, coverage: coverage, bounds: bounds)
    }

    private static func _finiteClamped(_ value: CGFloat, lower: CGFloat,
                                       upper: CGFloat, fallback: CGFloat) -> CGFloat {
        guard value.isFinite else { return fallback }
        return Swift.min(upper, Swift.max(lower, value))
    }

    private static func _normalizedBackdropColor(_ color: CGColor) -> CGColor {
        CGColor(red: _finiteClamped(color.red, lower: 0, upper: 1, fallback: 0),
                green: _finiteClamped(color.green, lower: 0, upper: 1, fallback: 0),
                blue: _finiteClamped(color.blue, lower: 0, upper: 1, fallback: 0),
                alpha: _finiteClamped(color.alpha, lower: 0, upper: 1, fallback: 0))
    }
}

/// One exact signed binary term: `(high:low) * 2^exponent`.
///
/// Affine input components are IEEE-754 binary64 values on every supported
/// OpenUIKit host.  Multiplying their integer significands with
/// `multipliedFullWidth` preserves all 106 product bits even when the floating
/// product itself would overflow.  Keeping the exponent separate also keeps a
/// small translation alive while much larger products cancel.
private struct _ExactBinaryTerm {
    let sign: Int
    let exponent: Int
    let low: UInt64
    let high: UInt64

    var bitWidth: Int {
        if high != 0 { return 64 + (64 - high.leadingZeroBitCount) }
        return 64 - low.leadingZeroBitCount
    }

    static func product(_ lhs: CGFloat, _ rhs: CGFloat) -> _ExactBinaryTerm? {
        guard let left = decompose(lhs), let right = decompose(rhs) else {
            return nil
        }
        let product = left.mantissa.multipliedFullWidth(by: right.mantissa)
        return _ExactBinaryTerm(
            sign: left.sign * right.sign,
            exponent: left.exponent + right.exponent,
            low: product.low,
            high: product.high)
    }

    static func value(_ value: CGFloat) -> _ExactBinaryTerm? {
        guard let component = decompose(value) else { return nil }
        return _ExactBinaryTerm(sign: component.sign,
                                exponent: component.exponent,
                                low: component.mantissa, high: 0)
    }

    static func integer(_ value: Int) -> _ExactBinaryTerm? {
        guard value != 0 else { return nil }
        return _ExactBinaryTerm(
            sign: value < 0 ? -1 : 1,
            exponent: 0,
            low: UInt64(value.magnitude), high: 0)
    }

    static func integerProduct(_ lhs: Int, _ rhs: Int) -> _ExactBinaryTerm? {
        guard lhs != 0, rhs != 0 else { return nil }
        let product = UInt64(lhs.magnitude).multipliedFullWidth(
            by: UInt64(rhs.magnitude))
        return _ExactBinaryTerm(
            sign: (lhs < 0) == (rhs < 0) ? 1 : -1,
            exponent: 0, low: product.low, high: product.high)
    }

    func shifted(by amount: Int, signMultiplier: Int = 1) -> Self {
        _ExactBinaryTerm(sign: sign * signMultiplier,
                         exponent: exponent + amount,
                         low: low, high: high)
    }

    private static func decompose(_ value: CGFloat)
        -> (sign: Int, mantissa: UInt64, exponent: Int)? {
        let bits = Double(value).bitPattern
        let fractionMask = (UInt64(1) << 52) - 1
        let fraction = bits & fractionMask
        let rawExponent = Int((bits >> 52) & 0x7ff)
        guard rawExponent != 0x7ff else { return nil }
        let mantissa: UInt64
        let exponent: Int
        if rawExponent == 0 {
            mantissa = fraction
            exponent = -1074
        } else {
            mantissa = (UInt64(1) << 52) | fraction
            exponent = rawExponent - 1023 - 52
        }
        guard mantissa != 0 else { return nil }
        return ((bits >> 63) == 0 ? 1 : -1, mantissa, exponent)
    }
}

/// Tiny fixed-range signed bigint used only for exact affine evaluation.
/// Three binary64 products span at most 4,196 bits, so this is bounded to
/// roughly 530 bytes and does not grow with the surface or filter radius.
private struct _ExactBinaryAccumulator {
    private var sign: Int = 0
    private var words: [UInt64]
    private let baseExponent: Int
    private let sourceTerms: [_ExactBinaryTerm]

    init(terms: [_ExactBinaryTerm]) {
        sourceTerms = terms
        guard let minimumExponent = terms.map(\.exponent).min() else {
            baseExponent = 0
            words = [0]
            return
        }
        baseExponent = minimumExponent
        let highestBit = terms.map {
            $0.exponent - minimumExponent + $0.bitWidth - 1
        }.max() ?? 0
        // Reserve the exact carry width for every term. Most affine sums have
        // three, while the box-kernel half-tie comparison deliberately adds
        // repeated exact products rather than rounding a huge polynomial.
        var carryBits = 0
        var termCapacity = 1
        while termCapacity < terms.count {
            carryBits += 1
            termCapacity *= 2
        }
        let requiredBits = highestBit + 1 + carryBits
        words = [UInt64](repeating: 0,
                         count: Swift.max(1, (requiredBits + 63) / 64))
        for term in terms { add(term) }
    }

    var signum: Int { sign }

    func exactDyadic() -> _BackdropExactDyadic {
        _BackdropExactDyadic(
            integer: _BackdropSignedInteger(
                sign: sign,
                magnitude: _BackdropUnsignedInteger(
                    littleEndianUInt64: words)),
            exponent: baseExponent)
    }

    private mutating func add(_ term: _ExactBinaryTerm) {
        var incoming = [UInt64](repeating: 0, count: words.count)
        let shift = term.exponent - baseExponent
        let word = shift / 64
        let bit = shift % 64

        incoming[word] |= term.low << bit
        if bit == 0 {
            if word + 1 < incoming.count { incoming[word + 1] |= term.high }
        } else {
            if word + 1 < incoming.count {
                incoming[word + 1] |= term.low >> (64 - bit)
                incoming[word + 1] |= term.high << bit
            }
            if word + 2 < incoming.count {
                incoming[word + 2] |= term.high >> (64 - bit)
            }
        }

        if sign == 0 {
            words = incoming
            sign = term.sign
            return
        }
        if sign == term.sign {
            Self.addMagnitudes(&words, incoming)
            return
        }

        switch Self.compare(words, incoming) {
        case 0:
            words = [UInt64](repeating: 0, count: words.count)
            sign = 0
        case 1:
            Self.subtractMagnitude(&words, incoming)
        default:
            var difference = incoming
            Self.subtractMagnitude(&difference, words)
            words = difference
            sign = term.sign
        }
    }

    func roundedCGFloat() -> CGFloat {
        guard sign != 0, let highestBit = highestBitIndex() else { return 0 }
        var unbiasedExponent = baseExponent + highestBit
        let negative = sign < 0

        if unbiasedExponent < -1022 {
            let binaryShift = baseExponent + 1074
            let significand: UInt64
            if binaryShift >= 0 {
                significand = words[0] << binaryShift
            } else {
                significand = roundedRightShift(-binaryShift)
            }
            let signBit = negative ? UInt64(1) << 63 : 0
            guard significand != 0 else {
                return CGFloat(Double(bitPattern: signBit))
            }
            if significand >= UInt64(1) << 52 {
                return CGFloat(Double(bitPattern: signBit | (UInt64(1) << 52)))
            }
            return CGFloat(Double(bitPattern: signBit | significand))
        }

        let discard = highestBit - 52
        var significand: UInt64
        if discard > 0 {
            significand = roundedRightShift(discard)
        } else {
            significand = words[0] << (-discard)
        }
        if significand == UInt64(1) << 53 {
            significand = UInt64(1) << 52
            unbiasedExponent += 1
        }
        if unbiasedExponent > 1023 {
            return negative
                ? -CGFloat.greatestFiniteMagnitude
                : CGFloat.greatestFiniteMagnitude
        }

        let rawExponent = UInt64(unbiasedExponent + 1023)
        let fractionMask = (UInt64(1) << 52) - 1
        let signBit = negative ? UInt64(1) << 63 : 0
        let bits = signBit | (rawExponent << 52) | (significand & fractionMask)
        return CGFloat(Double(bitPattern: bits))
    }

    /// Correctly rounded `sqrt(abs(self))` without first rounding the exact
    /// dyadic value into binary64. The determinant of a finite binary64 affine
    /// transform can span exponents -2148...2048; its square root is still
    /// within (or just beyond) binary64's own range. A normalized approximation
    /// supplies the candidate, then exact comparisons against the squared
    /// adjacent midpoints remove the otherwise possible one-ULP double-round.
    func magnitudeSquareRootCGFloat() -> CGFloat {
        guard sign != 0, let highestBit = highestBitIndex() else { return 0 }

        var valueExponent = baseExponent + highestBit
        let discard = highestBit - 52
        var significand: UInt64
        if discard > 0 {
            significand = roundedRightShift(discard)
        } else {
            significand = words[0] << (-discard)
        }
        // Rounding the normalized significand can carry into the next binade.
        if significand == UInt64(1) << 53 {
            significand = UInt64(1) << 52
            valueExponent += 1
        }

        var normalized = Double(significand) / Double(UInt64(1) << 52)
        if !valueExponent.isMultiple(of: 2) {
            normalized *= 2
            valueExponent -= 1
        }
        let root = normalized.squareRoot()
        var candidate = Double(sign: .plus,
                               exponent: valueExponent / 2,
                               significand: root)
        guard candidate.isFinite else { return CGFloat.greatestFiniteMagnitude }

        if candidate > 0 {
            let lower = candidate.nextDown
            let comparison = compareMagnitude(
                toSquaredMidpointBetween: lower, and: candidate)
            if comparison < 0
                || (comparison == 0 && !candidate.bitPattern.isMultiple(of: 2)) {
                candidate = lower
                return CGFloat(candidate)
            }
        }

        let upper = candidate.nextUp
        if upper.isFinite {
            let comparison = compareMagnitude(
                toSquaredMidpointBetween: candidate, and: upper)
            if comparison > 0
                || (comparison == 0 && !candidate.bitPattern.isMultiple(of: 2)) {
                candidate = upper
            }
        }
        return CGFloat(candidate)
    }

    /// Compares `abs(self)` with `((lower + upper) / 2)^2` as an exact dyadic
    /// sum. Expanding the square avoids representing the 54-bit midpoint in a
    /// binary64 intermediate:
    ///
    ///   lower^2 / 4 + lower*upper / 2 + upper^2 / 4.
    private func compareMagnitude(toSquaredMidpointBetween lower: Double,
                                  and upper: Double) -> Int {
        var comparisonTerms = sourceTerms.map {
            $0.shifted(by: 0, signMultiplier: sign)
        }
        if let term = _ExactBinaryTerm.product(CGFloat(lower), CGFloat(lower)) {
            comparisonTerms.append(term.shifted(by: -2, signMultiplier: -1))
        }
        if let term = _ExactBinaryTerm.product(CGFloat(lower), CGFloat(upper)) {
            comparisonTerms.append(term.shifted(by: -1, signMultiplier: -1))
        }
        if let term = _ExactBinaryTerm.product(CGFloat(upper), CGFloat(upper)) {
            comparisonTerms.append(term.shifted(by: -2, signMultiplier: -1))
        }
        return _ExactBinaryAccumulator(terms: comparisonTerms).signum
    }

    private func highestBitIndex() -> Int? {
        for index in words.indices.reversed() where words[index] != 0 {
            return index * 64 + (63 - words[index].leadingZeroBitCount)
        }
        return nil
    }

    private func roundedRightShift(_ shift: Int) -> UInt64 {
        precondition(shift > 0)
        var result = low64(afterRightShift: shift)
        let halfway = bit(at: shift - 1)
        if halfway && (hasAnyBit(below: shift - 1) || !result.isMultiple(of: 2)) {
            result += 1
        }
        return result
    }

    private func low64(afterRightShift shift: Int) -> UInt64 {
        let word = shift / 64
        guard word < words.count else { return 0 }
        let bit = shift % 64
        var result = words[word] >> bit
        if bit != 0, word + 1 < words.count {
            result |= words[word + 1] << (64 - bit)
        }
        return result
    }

    private func bit(at index: Int) -> Bool {
        guard index >= 0 else { return false }
        let word = index / 64
        guard word < words.count else { return false }
        return (words[word] & (UInt64(1) << (index % 64))) != 0
    }

    private func hasAnyBit(below limit: Int) -> Bool {
        guard limit > 0 else { return false }
        let completeWords = limit / 64
        for index in 0..<Swift.min(completeWords, words.count) {
            if words[index] != 0 { return true }
        }
        let remainingBits = limit % 64
        if remainingBits != 0, completeWords < words.count {
            let mask = (UInt64(1) << remainingBits) - 1
            return (words[completeWords] & mask) != 0
        }
        return false
    }

    private static func compare(_ lhs: [UInt64], _ rhs: [UInt64]) -> Int {
        for index in lhs.indices.reversed() where lhs[index] != rhs[index] {
            return lhs[index] > rhs[index] ? 1 : -1
        }
        return 0
    }

    private static func addMagnitudes(_ lhs: inout [UInt64], _ rhs: [UInt64]) {
        var carry = false
        for index in lhs.indices {
            let (partial, firstOverflow) = lhs[index].addingReportingOverflow(rhs[index])
            let (sum, secondOverflow) = partial.addingReportingOverflow(carry ? 1 : 0)
            lhs[index] = sum
            carry = firstOverflow || secondOverflow
        }
        precondition(!carry)
    }

    private static func subtractMagnitude(_ lhs: inout [UInt64], _ rhs: [UInt64]) {
        var borrow = false
        for index in lhs.indices {
            let (partial, firstOverflow) = lhs[index].subtractingReportingOverflow(rhs[index])
            let (difference, secondOverflow) = partial.subtractingReportingOverflow(borrow ? 1 : 0)
            lhs[index] = difference
            borrow = firstOverflow || secondOverflow
        }
        precondition(!borrow)
    }
}

/// Small arbitrary-precision unsigned integer used for exact clipping only.
/// Base 2^32 keeps every limb multiply/add inside `UInt64` without relying on
/// platform C integer extensions. Affine inputs bound the initial values to
/// roughly 4,200 bits, and a single edge intersection only squares that bound.
private struct _BackdropUnsignedInteger: Equatable, Comparable {
    private(set) var words: [UInt32]

    static let zero = _BackdropUnsignedInteger(words: [])
    static let one = _BackdropUnsignedInteger(1)

    init(_ value: UInt64) {
        if value == 0 {
            words = []
        } else {
            words = [UInt32(truncatingIfNeeded: value)]
            let high = UInt32(truncatingIfNeeded: value >> 32)
            if high != 0 { words.append(high) }
        }
    }

    init(littleEndianUInt64 words64: [UInt64]) {
        words = []
        words.reserveCapacity(words64.count * 2)
        for word in words64 {
            words.append(UInt32(truncatingIfNeeded: word))
            words.append(UInt32(truncatingIfNeeded: word >> 32))
        }
        normalize()
    }

    private init(words: [UInt32]) {
        self.words = words
        normalize()
    }

    var isZero: Bool { words.isEmpty }

    var bitWidth: Int {
        guard let high = words.last else { return 0 }
        return (words.count - 1) * 32 + (32 - high.leadingZeroBitCount)
    }

    var trailingZeroBitCount: Int {
        for (index, word) in words.enumerated() where word != 0 {
            return index * 32 + word.trailingZeroBitCount
        }
        return 0
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.words.count != rhs.words.count {
            return lhs.words.count < rhs.words.count
        }
        for index in lhs.words.indices.reversed()
            where lhs.words[index] != rhs.words[index] {
            return lhs.words[index] < rhs.words[index]
        }
        return false
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        let count = Swift.max(lhs.words.count, rhs.words.count)
        var result = [UInt32](repeating: 0, count: count + 1)
        var carry: UInt64 = 0
        for index in 0..<count {
            let left = index < lhs.words.count ? UInt64(lhs.words[index]) : 0
            let right = index < rhs.words.count ? UInt64(rhs.words[index]) : 0
            let sum = left + right + carry
            result[index] = UInt32(truncatingIfNeeded: sum)
            carry = sum >> 32
        }
        result[count] = UInt32(carry)
        return Self(words: result)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        precondition(lhs >= rhs)
        var result = lhs.words
        var borrow: UInt64 = 0
        let base = UInt64(1) << 32
        for index in result.indices {
            let right = (index < rhs.words.count ? UInt64(rhs.words[index]) : 0)
                + borrow
            let left = UInt64(result[index])
            if left >= right {
                result[index] = UInt32(left - right)
                borrow = 0
            } else {
                result[index] = UInt32(base + left - right)
                borrow = 1
            }
        }
        precondition(borrow == 0)
        return Self(words: result)
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        guard !lhs.isZero, !rhs.isZero else { return .zero }
        var result = [UInt32](repeating: 0,
                              count: lhs.words.count + rhs.words.count)
        for leftIndex in lhs.words.indices {
            var carry: UInt64 = 0
            for rightIndex in rhs.words.indices {
                let index = leftIndex + rightIndex
                let total = UInt64(lhs.words[leftIndex])
                    * UInt64(rhs.words[rightIndex])
                    + UInt64(result[index]) + carry
                result[index] = UInt32(truncatingIfNeeded: total)
                carry = total >> 32
            }
            var index = leftIndex + rhs.words.count
            while carry != 0 {
                let total = UInt64(result[index]) + carry
                result[index] = UInt32(truncatingIfNeeded: total)
                carry = total >> 32
                index += 1
            }
        }
        return Self(words: result)
    }

    func shiftedLeft(_ amount: Int) -> Self {
        guard !isZero, amount > 0 else { return self }
        let wholeWords = amount / 32
        let bits = amount % 32
        var result = [UInt32](repeating: 0,
                              count: words.count + wholeWords + (bits == 0 ? 0 : 1))
        var carry: UInt64 = 0
        for index in words.indices {
            let value = (UInt64(words[index]) << bits) | carry
            result[index + wholeWords] = UInt32(truncatingIfNeeded: value)
            carry = value >> 32
        }
        if bits != 0 { result[words.count + wholeWords] = UInt32(carry) }
        return Self(words: result)
    }

    func shiftedRight(_ amount: Int) -> Self {
        guard !isZero, amount > 0 else { return self }
        let wholeWords = amount / 32
        guard wholeWords < words.count else { return .zero }
        let bits = amount % 32
        var result = [UInt32](repeating: 0, count: words.count - wholeWords)
        for source in wholeWords..<words.count {
            let destination = source - wholeWords
            var value = UInt64(words[source]) >> bits
            if bits != 0, source + 1 < words.count {
                value |= UInt64(words[source + 1]) << (32 - bits)
            }
            result[destination] = UInt32(truncatingIfNeeded: value)
        }
        return Self(words: result)
    }

    /// The quotient is intentionally `UInt64`: callers scale normalized
    /// rationals so it has at most 53 significant bits.
    func quotientAndRemainder(dividingBy divisor: Self) -> (UInt64, Self) {
        precondition(!divisor.isZero)
        guard self >= divisor else { return (0, self) }
        let maximumShift = bitWidth - divisor.bitWidth
        precondition(maximumShift < 64)
        var remainder = self
        var quotient: UInt64 = 0
        for shift in stride(from: maximumShift, through: 0, by: -1) {
            let shiftedDivisor = divisor.shiftedLeft(shift)
            if remainder >= shiftedDivisor {
                remainder = remainder - shiftedDivisor
                quotient |= UInt64(1) << shift
            }
        }
        return (quotient, remainder)
    }

    private mutating func normalize() {
        while words.last == 0 { words.removeLast() }
    }
}

private struct _BackdropSignedInteger: Equatable {
    let sign: Int
    let magnitude: _BackdropUnsignedInteger

    static let zero = _BackdropSignedInteger(sign: 0, magnitude: .zero)

    init(sign: Int, magnitude: _BackdropUnsignedInteger) {
        self.sign = magnitude.isZero ? 0 : (sign < 0 ? -1 : 1)
        self.magnitude = magnitude
    }

    static prefix func - (value: Self) -> Self {
        Self(sign: -value.sign, magnitude: value.magnitude)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        guard lhs.sign != 0 else { return rhs }
        guard rhs.sign != 0 else { return lhs }
        if lhs.sign == rhs.sign {
            return Self(sign: lhs.sign,
                        magnitude: lhs.magnitude + rhs.magnitude)
        }
        if lhs.magnitude == rhs.magnitude { return .zero }
        if lhs.magnitude > rhs.magnitude {
            return Self(sign: lhs.sign,
                        magnitude: lhs.magnitude - rhs.magnitude)
        }
        return Self(sign: rhs.sign,
                    magnitude: rhs.magnitude - lhs.magnitude)
    }

    static func - (lhs: Self, rhs: Self) -> Self { lhs + (-rhs) }

    static func * (lhs: Self, rhs: Self) -> Self {
        Self(sign: lhs.sign * rhs.sign,
             magnitude: lhs.magnitude * rhs.magnitude)
    }

    func shiftedLeft(_ amount: Int) -> Self {
        Self(sign: sign, magnitude: magnitude.shiftedLeft(amount))
    }
}

/// An exact signed dyadic number, `integer * 2^exponent`.
private struct _BackdropExactDyadic: Comparable, Equatable {
    let integer: _BackdropSignedInteger
    let exponent: Int

    static let zero = _BackdropExactDyadic(integer: .zero, exponent: 0)

    init(integer: _BackdropSignedInteger, exponent: Int) {
        guard integer.sign != 0 else {
            self.integer = .zero
            self.exponent = 0
            return
        }
        let trailing = integer.magnitude.trailingZeroBitCount
        self.integer = _BackdropSignedInteger(
            sign: integer.sign,
            magnitude: integer.magnitude.shiftedRight(trailing))
        self.exponent = exponent + trailing
    }

    init(nonnegativeInteger value: Int) {
        precondition(value >= 0)
        self.init(integer: _BackdropSignedInteger(
            sign: value == 0 ? 0 : 1,
            magnitude: _BackdropUnsignedInteger(UInt64(value))), exponent: 0)
    }

    var sign: Int { integer.sign }

    static prefix func - (value: Self) -> Self {
        Self(integer: -value.integer, exponent: value.exponent)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        guard lhs.sign != 0 else { return rhs }
        guard rhs.sign != 0 else { return lhs }
        let commonExponent = Swift.min(lhs.exponent, rhs.exponent)
        let left = lhs.integer.shiftedLeft(lhs.exponent - commonExponent)
        let right = rhs.integer.shiftedLeft(rhs.exponent - commonExponent)
        return Self(integer: left + right, exponent: commonExponent)
    }

    static func - (lhs: Self, rhs: Self) -> Self { lhs + (-rhs) }

    static func * (lhs: Self, rhs: Self) -> Self {
        Self(integer: lhs.integer * rhs.integer,
             exponent: lhs.exponent + rhs.exponent)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.sign != rhs.sign { return lhs.sign < rhs.sign }
        guard lhs.sign != 0 else { return false }
        let comparison = compareMagnitudes(lhs.integer.magnitude, lhs.exponent,
                                           rhs.integer.magnitude, rhs.exponent)
        return lhs.sign > 0 ? comparison < 0 : comparison > 0
    }

    private static func compareMagnitudes(
        _ lhs: _BackdropUnsignedInteger, _ lhsExponent: Int,
        _ rhs: _BackdropUnsignedInteger, _ rhsExponent: Int
    ) -> Int {
        let lhsTop = lhs.bitWidth + lhsExponent
        let rhsTop = rhs.bitWidth + rhsExponent
        if lhsTop != rhsTop { return lhsTop < rhsTop ? -1 : 1 }
        let commonExponent = Swift.min(lhsExponent, rhsExponent)
        let left = lhs.shiftedLeft(lhsExponent - commonExponent)
        let right = rhs.shiftedLeft(rhsExponent - commonExponent)
        if left == right { return 0 }
        return left < right ? -1 : 1
    }
}

/// Exact rational produced by intersecting one exact dyadic rectangle edge
/// with one axis-aligned surface boundary.
private struct _BackdropExactRational: Comparable, Equatable {
    let numerator: _BackdropSignedInteger
    let denominator: _BackdropUnsignedInteger
    let exponent: Int

    init(_ value: _BackdropExactDyadic) {
        numerator = value.integer
        denominator = .one
        exponent = value.exponent
    }

    init(numerator: _BackdropExactDyadic,
         denominator: _BackdropExactDyadic) {
        precondition(denominator.sign != 0)
        self.numerator = _BackdropSignedInteger(
            sign: numerator.sign * denominator.sign,
            magnitude: numerator.integer.magnitude)
        self.denominator = denominator.integer.magnitude
        self.exponent = numerator.exponent - denominator.exponent
    }

    var sign: Int { numerator.sign }

    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.sign == rhs.sign else { return false }
        guard lhs.sign != 0 else { return true }
        let left = lhs.numerator.magnitude * rhs.denominator
        let right = rhs.numerator.magnitude * lhs.denominator
        return Self.compareMagnitudes(left, lhs.exponent,
                                      right, rhs.exponent) == 0
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.sign != rhs.sign { return lhs.sign < rhs.sign }
        guard lhs.sign != 0 else { return false }
        let left = lhs.numerator.magnitude * rhs.denominator
        let right = rhs.numerator.magnitude * lhs.denominator
        let leftTop = left.bitWidth + lhs.exponent
        let rightTop = right.bitWidth + rhs.exponent
        let comparison: Int
        if leftTop != rightTop {
            comparison = leftTop < rightTop ? -1 : 1
        } else {
            let commonExponent = Swift.min(lhs.exponent, rhs.exponent)
            let alignedLeft = left.shiftedLeft(lhs.exponent - commonExponent)
            let alignedRight = right.shiftedLeft(rhs.exponent - commonExponent)
            comparison = alignedLeft == alignedRight
                ? 0 : (alignedLeft < alignedRight ? -1 : 1)
        }
        return lhs.sign > 0 ? comparison < 0 : comparison > 0
    }

    func roundedCGFloat() -> CGFloat {
        guard sign != 0 else { return 0 }
        let numeratorMagnitude = numerator.magnitude
        var valueExponent = numeratorMagnitude.bitWidth
            - denominator.bitWidth + exponent
        let comparisonAtCandidateExponent = Self.compareMagnitudes(
            numeratorMagnitude, exponent,
            denominator, valueExponent)
        if comparisonAtCandidateExponent < 0 { valueExponent -= 1 }

        let targetExponent = valueExponent < -1022
            ? -1074 : valueExponent - 52
        let numeratorShift = Swift.max(0, exponent - targetExponent)
        let denominatorShift = Swift.max(0, targetExponent - exponent)
        let scaledNumerator = numeratorMagnitude.shiftedLeft(numeratorShift)
        let scaledDenominator = denominator.shiftedLeft(denominatorShift)
        var (significand, remainder) = scaledNumerator
            .quotientAndRemainder(dividingBy: scaledDenominator)
        let twiceRemainder = remainder.shiftedLeft(1)
        if twiceRemainder > scaledDenominator
            || (twiceRemainder == scaledDenominator
                && !significand.isMultiple(of: 2)) {
            significand += 1
        }

        let signBit = sign < 0 ? UInt64(1) << 63 : 0
        if valueExponent < -1022 {
            if significand >= UInt64(1) << 52 {
                return CGFloat(Double(bitPattern: signBit | (UInt64(1) << 52)))
            }
            return CGFloat(Double(bitPattern: signBit | significand))
        }
        if significand == UInt64(1) << 53 {
            significand = UInt64(1) << 52
            valueExponent += 1
        }
        if valueExponent > 1023 {
            return sign < 0
                ? -CGFloat.greatestFiniteMagnitude
                : CGFloat.greatestFiniteMagnitude
        }
        let fractionMask = (UInt64(1) << 52) - 1
        let bits = signBit | (UInt64(valueExponent + 1023) << 52)
            | (significand & fractionMask)
        return CGFloat(Double(bitPattern: bits))
    }

    private static func compareMagnitudes(
        _ lhs: _BackdropUnsignedInteger, _ lhsExponent: Int,
        _ rhs: _BackdropUnsignedInteger, _ rhsExponent: Int
    ) -> Int {
        let lhsTop = lhs.bitWidth + lhsExponent
        let rhsTop = rhs.bitWidth + rhsExponent
        if lhsTop != rhsTop { return lhsTop < rhsTop ? -1 : 1 }
        let commonExponent = Swift.min(lhsExponent, rhsExponent)
        let left = lhs.shiftedLeft(lhsExponent - commonExponent)
        let right = rhs.shiftedLeft(rhsExponent - commonExponent)
        if left == right { return 0 }
        return left < right ? -1 : 1
    }
}

/// Finite, surface-clipped geometry for the public rectangle entry point.
///
/// CGRect accessors and ordinary affine multiplication may overflow even when
/// every supplied component is finite. This path builds every corner directly
/// from exact origin/extent products, intersects original edges with the
/// surface as exact rationals, and converts to `CGFloat` only after the polygon
/// is inside the surface. Unequal overflowing coordinates and near-endpoint
/// ratios therefore retain every represented-input bit, and hostile values
/// never reach an integer conversion.
enum _BackdropFilterGeometry {
    private struct DyadicPoint {
        let x: _BackdropExactDyadic
        let y: _BackdropExactDyadic
    }

    private struct RationalPoint {
        let x: _BackdropExactRational
        let y: _BackdropExactRational
    }

    static func coverage(of rect: CGRect, transform: CGAffineTransform,
                         width: Int, height: Int) -> [UInt8]? {
        let components = [rect.origin.x, rect.origin.y,
                          rect.size.width, rect.size.height,
                          transform.a, transform.b, transform.c,
                          transform.d, transform.tx, transform.ty]
        guard width > 0, height > 0,
              components.allSatisfy(\.isFinite),
              rect.size.width > 0, rect.size.height > 0 else { return nil }

        func apply(includeWidth: Bool, includeHeight: Bool) -> DyadicPoint {
            func coordinate(_ xScale: CGFloat, _ yScale: CGFloat,
                            _ translation: CGFloat) -> _BackdropExactDyadic {
                var terms: [_ExactBinaryTerm] = []
                if let product = _ExactBinaryTerm.product(rect.origin.x, xScale) {
                    terms.append(product)
                }
                if includeWidth,
                   let product = _ExactBinaryTerm.product(rect.size.width, xScale) {
                    terms.append(product)
                }
                if let product = _ExactBinaryTerm.product(rect.origin.y, yScale) {
                    terms.append(product)
                }
                if includeHeight,
                   let product = _ExactBinaryTerm.product(rect.size.height, yScale) {
                    terms.append(product)
                }
                if let value = _ExactBinaryTerm.value(translation) {
                    terms.append(value)
                }
                return _ExactBinaryAccumulator(terms: terms).exactDyadic()
            }
            return DyadicPoint(
                x: coordinate(transform.a, transform.c, transform.tx),
                y: coordinate(transform.b, transform.d, transform.ty))
        }

        let corners = [
            apply(includeWidth: false, includeHeight: false),
            apply(includeWidth: true, includeHeight: false),
            apply(includeWidth: true, includeHeight: true),
            apply(includeWidth: false, includeHeight: true),
        ]
        let zero = _BackdropExactDyadic.zero
        let limitX = _BackdropExactDyadic(nonnegativeInteger: width)
        let limitY = _BackdropExactDyadic(nonnegativeInteger: height)
        guard let exactPolygon = clippedConvexPolygon(
            corners: corners, minimumX: zero, maximumX: limitX,
            minimumY: zero, maximumY: limitY)
        else { return nil }

        let maximumX = CGFloat(width)
        let maximumY = CGFloat(height)
        let rasterPolygon = convexHull(exactPolygon.map {
            CGPoint(
                x: Swift.min(maximumX, Swift.max(0, $0.x.roundedCGFloat())),
                y: Swift.min(maximumY, Swift.max(0, $0.y.roundedCGFloat())))
        })
        guard rasterPolygon.count >= 3 else { return nil }

        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity
        for point in rasterPolygon {
            minX = Swift.min(minX, point.x)
            minY = Swift.min(minY, point.y)
            maxX = Swift.max(maxX, point.x)
            maxY = Swift.max(maxY, point.y)
        }
        guard var accumulator = _CoverageAccumulator(
            clippingBoxMinX: minX, minY: minY, maxX: maxX, maxY: maxY,
            limitWidth: width, limitHeight: height)
        else { return nil }

        var subpath = _Subpath()
        subpath.points = rasterPolygon
        accumulator.add(subpaths: [subpath], implicitClose: true)
        var result = [UInt8](repeating: 0, count: width * height)
        let originX = accumulator.originX
        let originY = accumulator.originY
        let coveredWidth = accumulator.width
        result.withUnsafeMutableBufferPointer { mask in
            accumulator.enumerateRows(evenOdd: false) { row, values in
                let rowBase = (originY + row) * width + originX
                for x in 0..<coveredWidth {
                    mask[rowBase + x] = UInt8((values[x] * 255).rounded())
                }
            }
        }
        return result
    }

    /// Evaluates `a*b + c*d + translation` without first overflowing either
    /// product.  Each represented binary64 input contributes its exact integer
    /// significand and exponent; the exact sum is rounded once and saturated
    /// only if the final representable value is outside CGFloat's finite range.
    static func saturatedLinearCombination(_ a: CGFloat, _ b: CGFloat,
                                            _ c: CGFloat, _ d: CGFloat,
                                            _ translation: CGFloat) -> CGFloat {
        var terms: [_ExactBinaryTerm] = []
        if let product = _ExactBinaryTerm.product(a, b) { terms.append(product) }
        if let product = _ExactBinaryTerm.product(c, d) { terms.append(product) }
        if let value = _ExactBinaryTerm.value(translation) { terms.append(value) }
        return _ExactBinaryAccumulator(terms: terms).roundedCGFloat()
    }

    /// The area-equivalent scalar scale `sqrt(abs(a*d-b*c))`, evaluated over
    /// the exact represented binary64 inputs before the final square root.
    static func areaEquivalentScale(a: CGFloat, b: CGFloat,
                                    c: CGFloat, d: CGFloat) -> CGFloat {
        var terms: [_ExactBinaryTerm] = []
        if let product = _ExactBinaryTerm.product(a, d) { terms.append(product) }
        if let product = _ExactBinaryTerm.product(b, -c) { terms.append(product) }
        return _ExactBinaryAccumulator(terms: terms).magnitudeSquareRootCGFloat()
    }

    /// A clipped convex polygon has only three kinds of vertex: an original
    /// corner, an original-edge/surface-edge intersection, or a surface
    /// corner. Enumerating those directly avoids sequential rational
    /// interpolation (and its denominator growth) while remaining exact.
    private static func clippedConvexPolygon(
        corners: [DyadicPoint],
        minimumX: _BackdropExactDyadic,
        maximumX: _BackdropExactDyadic,
        minimumY: _BackdropExactDyadic,
        maximumY: _BackdropExactDyadic
    ) -> [RationalPoint]? {
        precondition(corners.count == 4)
        let orientation = cross(corners[0], corners[1], corners[3]).sign
        guard orientation != 0 else { return nil }

        let rationalMinimumX = _BackdropExactRational(minimumX)
        let rationalMaximumX = _BackdropExactRational(maximumX)
        let rationalMinimumY = _BackdropExactRational(minimumY)
        let rationalMaximumY = _BackdropExactRational(maximumY)
        var candidates: [RationalPoint] = []
        candidates.reserveCapacity(16)

        for point in corners
            where point.x >= minimumX && point.x <= maximumX
                && point.y >= minimumY && point.y <= maximumY {
            candidates.append(RationalPoint(
                x: _BackdropExactRational(point.x),
                y: _BackdropExactRational(point.y)))
        }

        func crosses(_ start: _BackdropExactDyadic,
                     _ end: _BackdropExactDyadic,
                     boundary: _BackdropExactDyadic) -> Bool {
            let startSign = (start - boundary).sign
            let endSign = (end - boundary).sign
            guard startSign != 0 || endSign != 0 else { return false }
            return startSign == 0 || endSign == 0 || startSign != endSign
        }

        func intersectionOther(
            startAxis: _BackdropExactDyadic,
            endAxis: _BackdropExactDyadic,
            startOther: _BackdropExactDyadic,
            endOther: _BackdropExactDyadic,
            boundary: _BackdropExactDyadic
        ) -> _BackdropExactRational {
            // y = (y0*(x1-B) + y1*(B-x0)) / (x1-x0), and
            // symmetrically for a horizontal surface edge.
            let numerator = startOther * (endAxis - boundary)
                + endOther * (boundary - startAxis)
            return _BackdropExactRational(
                numerator: numerator, denominator: endAxis - startAxis)
        }

        for index in corners.indices {
            let start = corners[index]
            let end = corners[(index + 1) % corners.count]
            for boundary in [minimumX, maximumX]
                where crosses(start.x, end.x, boundary: boundary) {
                let y = intersectionOther(
                    startAxis: start.x, endAxis: end.x,
                    startOther: start.y, endOther: end.y,
                    boundary: boundary)
                if y >= rationalMinimumY && y <= rationalMaximumY {
                    candidates.append(RationalPoint(
                        x: _BackdropExactRational(boundary), y: y))
                }
            }
            for boundary in [minimumY, maximumY]
                where crosses(start.y, end.y, boundary: boundary) {
                let x = intersectionOther(
                    startAxis: start.y, endAxis: end.y,
                    startOther: start.x, endOther: end.x,
                    boundary: boundary)
                if x >= rationalMinimumX && x <= rationalMaximumX {
                    candidates.append(RationalPoint(
                        x: x, y: _BackdropExactRational(boundary)))
                }
            }
        }

        for x in [minimumX, maximumX] {
            for y in [minimumY, maximumY] {
                let point = DyadicPoint(x: x, y: y)
                var isInside = true
                for index in corners.indices {
                    let edgeSign = cross(
                        corners[index], corners[(index + 1) % corners.count],
                        point).sign
                    if edgeSign != 0, edgeSign != orientation {
                        isInside = false
                        break
                    }
                }
                if isInside {
                    candidates.append(RationalPoint(
                        x: _BackdropExactRational(x),
                        y: _BackdropExactRational(y)))
                }
            }
        }
        return candidates.count >= 3 ? candidates : nil
    }

    private static func cross(_ origin: DyadicPoint,
                              _ first: DyadicPoint,
                              _ second: DyadicPoint) -> _BackdropExactDyadic {
        (first.x - origin.x) * (second.y - origin.y)
            - (first.y - origin.y) * (second.x - origin.x)
    }

    /// The exact candidate set is unordered. Its rounded coordinates are
    /// already surface-finite; a monotone hull both orders them and removes
    /// duplicate/collinear vertices that become indistinguishable to the
    /// CGFloat rasterizer.
    private static func convexHull(_ candidates: [CGPoint]) -> [CGPoint] {
        let sorted = candidates.sorted {
            $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x
        }
        var points: [CGPoint] = []
        points.reserveCapacity(sorted.count)
        for point in sorted where points.last != point { points.append(point) }
        guard points.count > 2 else { return points }

        func turn(_ origin: CGPoint, _ first: CGPoint,
                  _ second: CGPoint) -> CGFloat {
            (first.x - origin.x) * (second.y - origin.y)
                - (first.y - origin.y) * (second.x - origin.x)
        }

        var lower: [CGPoint] = []
        for point in points {
            while lower.count >= 2,
                  turn(lower[lower.count - 2], lower[lower.count - 1], point) <= 0 {
                lower.removeLast()
            }
            lower.append(point)
        }
        var upper: [CGPoint] = []
        for point in points.reversed() {
            while upper.count >= 2,
                  turn(upper[upper.count - 2], upper[upper.count - 1], point) <= 0 {
                upper.removeLast()
            }
            upper.append(point)
        }
        lower.removeLast()
        upper.removeLast()
        return lower + upper
    }
}

struct _CanvasDeviceBounds {
    let x0: Int
    let y0: Int
    let x1: Int
    let y1: Int

    static func coverageBounds(_ coverage: [UInt8], width: Int, height: Int)
        -> _CanvasDeviceBounds? {
        var x0 = width
        var y0 = height
        var x1 = 0
        var y1 = 0
        for y in 0..<height {
            let row = y * width
            for x in 0..<width where coverage[row + x] != 0 {
                if x < x0 { x0 = x }
                if y < y0 { y0 = y }
                if x + 1 > x1 { x1 = x + 1 }
                if y + 1 > y1 { y1 = y + 1 }
            }
        }
        guard x0 < x1, y0 < y1 else { return nil }
        return _CanvasDeviceBounds(x0: x0, y0: y0, x1: x1, y1: y1)
    }

    func expanded(by amount: Int, width: Int, height: Int) -> _CanvasDeviceBounds {
        _CanvasDeviceBounds(x0: Swift.max(0, x0 - amount),
                            y0: Swift.max(0, y0 - amount),
                            x1: Swift.min(width, x1 + amount),
                            y1: Swift.min(height, y1 + amount))
    }
}

struct _CanvasBackdropFilter {
    let boxRadii: [Int]
    let saturation: Double
    let tint: CGColor?
    let intensity: Double
}

/// Shared deterministic premultiplied-RGBA8 filter kernel.
///
/// Quartz already owns premultiplied bytes.  The Swift rasterizer's straight
/// Bitmap is canonicalized to premultiplied bytes before filtering and
/// converted back afterward.  That prevents transparent RGB from bleeding
/// into the blur and makes the filter kernel byte-identical for identical
/// input bytes.  A pre-existing transparency compositor may have already
/// rounded those input bytes differently by one count on the two backends;
/// high saturation can amplify and clamp that input delta to the full byte
/// range, so the one-count pre-filter bound is not a post-filter parity bound.
enum _BackdropFilterCPU {
    static func boxRadii(forSigma sigma: Double) -> [Int] {
        guard sigma > 0.01, sigma.isFinite else { return [] }
        let passCount = 3.0
        let idealWidth = ((12 * sigma * sigma) / passCount + 1).squareRoot()
        var lowerWidth = Int(idealWidth.rounded(.down))
        if lowerWidth % 2 == 0 { lowerWidth -= 1 }
        if lowerWidth < 1 { lowerWidth = 1 }
        let upperWidth = lowerWidth + 2
        let lowerPasses = exactLowerPassCount(sigma: sigma,
                                              lowerWidth: lowerWidth)
        return (0..<3).map { pass in
            let width = pass < lowerPasses ? lowerWidth : upperWidth
            return (width - 1) / 2
        }
    }

    /// Round the three-box lower-width count without evaluating the
    /// cancellation-heavy floating expression
    ///
    ///   (12*sigma^2 - 3*w^2 - 12*w - 9) / (-4*w - 4).
    ///
    /// At large integral sigma the numerator loses enough low bits to move an
    /// exact 1.5 tie below the boundary. Compare twice the positive numerator
    /// against denominator multiples 1, 3 and 5 as exact dyadic sums instead;
    /// equality advances to the next integer, matching Swift's nearest/away
    /// rounding rule.
    private static func exactLowerPassCount(sigma: Double,
                                            lowerWidth: Int) -> Int {
        let representedSigma = CGFloat(sigma)
        var positiveNumerator: [_ExactBinaryTerm] = []

        if let square = _ExactBinaryTerm.integerProduct(lowerWidth, lowerWidth) {
            for _ in 0..<3 { positiveNumerator.append(square) }
        }
        if let linear = _ExactBinaryTerm.integer(lowerWidth) {
            for _ in 0..<12 { positiveNumerator.append(linear) }
        }
        if let constant = _ExactBinaryTerm.value(1) {
            for _ in 0..<9 { positiveNumerator.append(constant) }
        }
        if let negativeSigmaSquare = _ExactBinaryTerm.product(
            representedSigma, -representedSigma
        ) {
            for _ in 0..<12 { positiveNumerator.append(negativeSigmaSquare) }
        }

        func comparison(toOddMultiple multiple: Int) -> Int {
            var terms = positiveNumerator + positiveNumerator
            if let negativeLower = _ExactBinaryTerm.integerProduct(
                -lowerWidth, 4 * multiple) { terms.append(negativeLower) }
            if let negativeConstant = _ExactBinaryTerm.integer(-4 * multiple) {
                terms.append(negativeConstant)
            }
            return _ExactBinaryAccumulator(terms: terms).signum
        }

        if comparison(toOddMultiple: 1) < 0 { return 0 }
        if comparison(toOddMultiple: 3) < 0 { return 1 }
        if comparison(toOddMultiple: 5) < 0 { return 2 }
        return 3
    }

    static func applyToStraight(_ pixels: inout [UInt8], width: Int, height: Int,
                                coverage: [UInt8], bounds: _CanvasDeviceBounds,
                                filter: _CanvasBackdropFilter) {
        let support = filter.boxRadii.reduce(0, +)
        let sourceBounds = bounds.expanded(by: support, width: width, height: height)
        let workWidth = sourceBounds.x1 - sourceBounds.x0
        let workHeight = sourceBounds.y1 - sourceBounds.y0
        var work = [UInt8](repeating: 0, count: workWidth * workHeight * 4)

        for y in sourceBounds.y0..<sourceBounds.y1 {
            for x in sourceBounds.x0..<sourceBounds.x1 {
                let source = (y * width + x) * 4
                let destination = ((y - sourceBounds.y0) * workWidth
                                   + x - sourceBounds.x0) * 4
                let alpha = Int(pixels[source + 3])
                work[destination] = UInt8((Int(pixels[source]) * alpha + 127) / 255)
                work[destination + 1] = UInt8((Int(pixels[source + 1]) * alpha + 127) / 255)
                work[destination + 2] = UInt8((Int(pixels[source + 2]) * alpha + 127) / 255)
                work[destination + 3] = UInt8(alpha)
            }
        }

        filterWork(&work, width: workWidth, height: workHeight,
                   boxRadii: filter.boxRadii)
        writeFiltered(work, canvasWidth: width, workWidth: workWidth,
                      sourceBounds: sourceBounds,
                      targetBounds: bounds, coverage: coverage, filter: filter,
                      readOriginal: { x, y in
                          let offset = (y * width + x) * 4
                          let alpha = Int(pixels[offset + 3])
                          return (
                              UInt8((Int(pixels[offset]) * alpha + 127) / 255),
                              UInt8((Int(pixels[offset + 1]) * alpha + 127) / 255),
                              UInt8((Int(pixels[offset + 2]) * alpha + 127) / 255),
                              UInt8(alpha))
                      },
                      write: { x, y, pixel in
                          let offset = (y * width + x) * 4
                          let alpha = Int(pixel.3)
                          if alpha == 0 {
                              pixels[offset] = 0
                              pixels[offset + 1] = 0
                              pixels[offset + 2] = 0
                              pixels[offset + 3] = 0
                          } else if alpha == 255 {
                              pixels[offset] = pixel.0
                              pixels[offset + 1] = pixel.1
                              pixels[offset + 2] = pixel.2
                              pixels[offset + 3] = 255
                          } else {
                              pixels[offset] = UInt8(Swift.min(
                                  255, (Int(pixel.0) * 255 + alpha / 2) / alpha))
                              pixels[offset + 1] = UInt8(Swift.min(
                                  255, (Int(pixel.1) * 255 + alpha / 2) / alpha))
                              pixels[offset + 2] = UInt8(Swift.min(
                                  255, (Int(pixel.2) * 255 + alpha / 2) / alpha))
                              pixels[offset + 3] = UInt8(alpha)
                          }
                      })
    }

    static func applyToPremultiplied(_ pixels: UnsafeMutablePointer<UInt8>,
                                     width: Int, height: Int, bytesPerRow: Int,
                                     coverage: [UInt8], bounds: _CanvasDeviceBounds,
                                     filter: _CanvasBackdropFilter) {
        let support = filter.boxRadii.reduce(0, +)
        let sourceBounds = bounds.expanded(by: support, width: width, height: height)
        let workWidth = sourceBounds.x1 - sourceBounds.x0
        let workHeight = sourceBounds.y1 - sourceBounds.y0
        var work = [UInt8](repeating: 0, count: workWidth * workHeight * 4)

        for y in sourceBounds.y0..<sourceBounds.y1 {
            let sourceRow = y * bytesPerRow
            for x in sourceBounds.x0..<sourceBounds.x1 {
                let source = sourceRow + x * 4
                let destination = ((y - sourceBounds.y0) * workWidth
                                   + x - sourceBounds.x0) * 4
                work[destination] = pixels[source]
                work[destination + 1] = pixels[source + 1]
                work[destination + 2] = pixels[source + 2]
                work[destination + 3] = pixels[source + 3]
            }
        }

        filterWork(&work, width: workWidth, height: workHeight,
                   boxRadii: filter.boxRadii)
        writeFiltered(work, canvasWidth: width, workWidth: workWidth,
                      sourceBounds: sourceBounds,
                      targetBounds: bounds, coverage: coverage, filter: filter,
                      readOriginal: { x, y in
                          let offset = y * bytesPerRow + x * 4
                          return (pixels[offset], pixels[offset + 1],
                                  pixels[offset + 2], pixels[offset + 3])
                      },
                      write: { x, y, pixel in
                          let offset = y * bytesPerRow + x * 4
                          pixels[offset] = pixel.0
                          pixels[offset + 1] = pixel.1
                          pixels[offset + 2] = pixel.2
                          pixels[offset + 3] = pixel.3
                      })
    }

    private static func filterWork(_ pixels: inout [UInt8], width: Int,
                                   height: Int, boxRadii: [Int]) {
        for radius in boxRadii where radius > 0 {
            boxBlur(&pixels, width: width, height: height, radius: radius)
        }
    }

    private static func writeFiltered(
        _ filtered: [UInt8],
        canvasWidth: Int,
        workWidth: Int,
        sourceBounds: _CanvasDeviceBounds,
        targetBounds: _CanvasDeviceBounds,
        coverage: [UInt8],
        filter: _CanvasBackdropFilter,
        readOriginal: (_ x: Int, _ y: Int) -> (UInt8, UInt8, UInt8, UInt8),
        write: (_ x: Int, _ y: Int, _ pixel: (UInt8, UInt8, UInt8, UInt8)) -> Void
    ) {
        let tint = filter.tint
        let tintAlpha = Double(tint?.alpha ?? 0)
        let tintRed = Double(tint?.red ?? 0) * 255 * tintAlpha
        let tintGreen = Double(tint?.green ?? 0) * 255 * tintAlpha
        let tintBlue = Double(tint?.blue ?? 0) * 255 * tintAlpha
        let tintInverse = 1 - tintAlpha

        for y in targetBounds.y0..<targetBounds.y1 {
            for x in targetBounds.x0..<targetBounds.x1 {
                let mask = coverage[y * canvasWidth + x]
                if mask == 0 { continue }
                let workOffset = ((y - sourceBounds.y0) * workWidth
                                  + x - sourceBounds.x0) * 4
                let alpha = Double(filtered[workOffset + 3])
                let red = Double(filtered[workOffset])
                let green = Double(filtered[workOffset + 1])
                let blue = Double(filtered[workOffset + 2])
                var outRed = red
                var outGreen = green
                var outBlue = blue
                if filter.saturation != 1 {
                    let luminance = red * 0.2126 + green * 0.7152 + blue * 0.0722
                    outRed = luminance + filter.saturation * (red - luminance)
                    outGreen = luminance + filter.saturation * (green - luminance)
                    outBlue = luminance + filter.saturation * (blue - luminance)
                }
                var outAlpha = alpha
                outRed = Swift.min(alpha, Swift.max(0, outRed))
                outGreen = Swift.min(alpha, Swift.max(0, outGreen))
                outBlue = Swift.min(alpha, Swift.max(0, outBlue))

                if tintAlpha > 0 {
                    outRed = tintRed + outRed * tintInverse
                    outGreen = tintGreen + outGreen * tintInverse
                    outBlue = tintBlue + outBlue * tintInverse
                    outAlpha = 255 * tintAlpha + outAlpha * tintInverse
                }

                let original = readOriginal(x, y)
                let mix = Double(mask) / 255 * filter.intensity
                let inverseMix = 1 - mix
                let mixedAlpha = byte(Double(original.3) * inverseMix
                                      + outAlpha * mix)
                let mixedRed = Swift.min(mixedAlpha,
                    byte(Double(original.0) * inverseMix + outRed * mix))
                let mixedGreen = Swift.min(mixedAlpha,
                    byte(Double(original.1) * inverseMix + outGreen * mix))
                let mixedBlue = Swift.min(mixedAlpha,
                    byte(Double(original.2) * inverseMix + outBlue * mix))
                write(x, y, (mixedRed, mixedGreen, mixedBlue, mixedAlpha))
            }
        }
    }

    private static func byte(_ value: Double) -> UInt8 {
        UInt8(Swift.min(255, Swift.max(0, value.rounded())))
    }

    /// One separable, edge-clamped box blur over all premultiplied channels.
    private static func boxBlur(_ pixels: inout [UInt8], width: Int,
                                height: Int, radius: Int) {
        guard radius > 0, width > 0, height > 0 else { return }
        var temporary = [UInt8](repeating: 0, count: pixels.count)
        let span = radius * 2 + 1

        pixels.withUnsafeBufferPointer { source in
            temporary.withUnsafeMutableBufferPointer { destination in
                for y in 0..<height {
                    let row = y * width * 4
                    for channel in 0..<4 {
                        var sum = initialEdgeReplicatedSum(
                            length: width, radius: radius,
                            sample: { x in Int(source[row + x * 4 + channel]) })
                        for x in 0..<width {
                            destination[row + x * 4 + channel] = UInt8(
                                (sum + span / 2) / span)
                            let removeX = Swift.min(width - 1,
                                Swift.max(0, x - radius))
                            let addX = Swift.min(width - 1,
                                Swift.max(0, x + radius + 1))
                            sum -= Int(source[row + removeX * 4 + channel])
                            sum += Int(source[row + addX * 4 + channel])
                        }
                    }
                }
            }
        }

        temporary.withUnsafeBufferPointer { source in
            pixels.withUnsafeMutableBufferPointer { destination in
                for x in 0..<width {
                    for channel in 0..<4 {
                        var sum = initialEdgeReplicatedSum(
                            length: height, radius: radius,
                            sample: { y in Int(source[(y * width + x) * 4 + channel]) })
                        for y in 0..<height {
                            destination[(y * width + x) * 4 + channel] = UInt8(
                                (sum + span / 2) / span)
                            let removeY = Swift.min(height - 1,
                                Swift.max(0, y - radius))
                            let addY = Swift.min(height - 1,
                                Swift.max(0, y + radius + 1))
                            sum -= Int(source[(removeY * width + x) * 4 + channel])
                            sum += Int(source[(addY * width + x) * 4 + channel])
                        }
                    }
                }
            }
        }
    }

    /// Sum the edge-replicated window centered on element zero.  Work is
    /// bounded by `length`, not `radius`: off-array samples are represented by
    /// endpoint multiplicities rather than iterating `-radius...radius`.
    private static func initialEdgeReplicatedSum(
        length: Int, radius: Int, sample: (_ index: Int) -> Int
    ) -> Int {
        precondition(length > 0 && radius > 0)
        var sum = sample(0) * (radius + 1)
        let lastExplicit = Swift.min(radius, length - 1)
        if lastExplicit >= 1 {
            for index in 1...lastExplicit { sum += sample(index) }
        }
        if radius >= length {
            sum += sample(length - 1) * (radius - length + 1)
        }
        return sum
    }
}
