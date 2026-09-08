import Network

private func requireIntegerWitness(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testFixedWidthIntegerBitWidthWitnesses() {
    requireIntegerWitness(Int8.bitWidth == 8 && UInt8.bitWidth == 8, "8-bit widths")
    requireIntegerWitness(Int16.bitWidth == 16 && UInt16.bitWidth == 16, "16-bit widths")
    requireIntegerWitness(Int32.bitWidth == 32 && UInt32.bitWidth == 32, "32-bit widths")
    requireIntegerWitness(Int64.bitWidth == 64 && UInt64.bitWidth == 64, "64-bit widths")
}

func testFixedWidthIntegerLittleEndianValueWitnesses() {
    requireIntegerWitness(Int8(7).littleEndian == 7 && UInt8(7).littleEndian == 7, "8-bit little endian")
    requireIntegerWitness(Int16(0x1234).littleEndian == 0x1234 && UInt16(0x1234).littleEndian == 0x1234, "16-bit little endian")
    requireIntegerWitness(Int32(0x1234).littleEndian == 0x1234 && UInt32(0x1234).littleEndian == 0x1234, "32-bit little endian")
    requireIntegerWitness(Int64(0x1234).littleEndian == 0x1234 && UInt64(0x1234).littleEndian == 0x1234, "64-bit little endian")
}

func testFixedWidthIntegerLittleEndianInitializerWitnesses() {
    requireIntegerWitness(Int8(littleEndian: 7) == 7 && UInt8(littleEndian: 7) == 7, "8-bit little endian init")
    requireIntegerWitness(Int16(littleEndian: 0x1234) == 0x1234 && UInt16(littleEndian: 0x1234) == 0x1234, "16-bit little endian init")
    requireIntegerWitness(Int32(littleEndian: 0x1234) == 0x1234 && UInt32(littleEndian: 0x1234) == 0x1234, "32-bit little endian init")
    requireIntegerWitness(Int64(littleEndian: 0x1234) == 0x1234 && UInt64(littleEndian: 0x1234) == 0x1234, "64-bit little endian init")
}

func testFixedWidthIntegerTruncatingWitnesses() {
    requireIntegerWitness(Int8(truncatingIfNeeded: 0x107) == 7 && UInt8(truncatingIfNeeded: 0x107) == 7, "8-bit truncation")
    requireIntegerWitness(Int16(truncatingIfNeeded: 0x1_0007) == 7 && UInt16(truncatingIfNeeded: 0x1_0007) == 7, "16-bit truncation")
    requireIntegerWitness(Int32(truncatingIfNeeded: Int64(0x1_0000_0007)) == 7 && UInt32(truncatingIfNeeded: UInt64(0x1_0000_0007)) == 7, "32-bit truncation")
    requireIntegerWitness(Int64(truncatingIfNeeded: UInt64.max) == -1 && UInt64(truncatingIfNeeded: -1) == UInt64.max, "64-bit truncation")
}

func testFixedWidthIntegerByteSwapWitnesses() {
    requireIntegerWitness(Int8(7).byteSwapped == 7 && UInt8(7).byteSwapped == 7, "8-bit swap")
    requireIntegerWitness(Int16(0x1234).byteSwapped == 0x3412 && UInt16(0x1234).byteSwapped == 0x3412, "16-bit swap")
    requireIntegerWitness(Int32(0x12345678).byteSwapped == 0x78563412 && UInt32(0x12345678).byteSwapped == 0x78563412, "32-bit swap")
    requireIntegerWitness(Int64(0x0102030405060708).byteSwapped == 0x0807060504030201 && UInt64(0x0102030405060708).byteSwapped == 0x0807060504030201, "64-bit swap")
}

func testFixedWidthIntegerBigEndianValueWitnesses() {
    requireIntegerWitness(Int8(7).bigEndian == 7 && UInt8(7).bigEndian == 7, "8-bit big endian")
    requireIntegerWitness(Int16(0x1234).bigEndian == 0x3412 && UInt16(0x1234).bigEndian == 0x3412, "16-bit big endian")
    requireIntegerWitness(Int32(0x12345678).bigEndian == 0x78563412 && UInt32(0x12345678).bigEndian == 0x78563412, "32-bit big endian")
    requireIntegerWitness(Int64(0x0102030405060708).bigEndian == 0x0807060504030201 && UInt64(0x0102030405060708).bigEndian == 0x0807060504030201, "64-bit big endian")
}

func testFixedWidthIntegerBigEndianInitializerWitnesses() {
    requireIntegerWitness(Int8(bigEndian: 7) == 7 && UInt8(bigEndian: 7) == 7, "8-bit big endian init")
    requireIntegerWitness(Int16(bigEndian: 0x3412) == 0x1234 && UInt16(bigEndian: 0x3412) == 0x1234, "16-bit big endian init")
    requireIntegerWitness(Int32(bigEndian: 0x78563412) == 0x12345678 && UInt32(bigEndian: 0x78563412) == 0x12345678, "32-bit big endian init")
    requireIntegerWitness(Int64(bigEndian: 0x0807060504030201) == 0x0102030405060708 && UInt64(bigEndian: 0x0807060504030201) == 0x0102030405060708, "64-bit big endian init")
}

func testFixedWidthIntegerRemainderWitnesses() {
    requireIntegerWitness(Int8(13) % 5 == 3 && UInt8(13) % 5 == 3, "8-bit remainder")
    requireIntegerWitness(Int16(13) % 5 == 3 && UInt16(13) % 5 == 3, "16-bit remainder")
    requireIntegerWitness(Int32(13) % 5 == 3 && UInt32(13) % 5 == 3, "32-bit remainder")
    requireIntegerWitness(Int64(13) % 5 == 3 && UInt64(13) % 5 == 3, "64-bit remainder")
}

func testFixedWidthIntegerWrappingAdditionWitnesses() {
    requireIntegerWitness(Int8.max &+ 1 == Int8.min && UInt8.max &+ 1 == 0, "8-bit wrapping add")
    requireIntegerWitness(Int16.max &+ 1 == Int16.min && UInt16.max &+ 1 == 0, "16-bit wrapping add")
    requireIntegerWitness(Int32.max &+ 1 == Int32.min && UInt32.max &+ 1 == 0, "32-bit wrapping add")
    requireIntegerWitness(Int64.max &+ 1 == Int64.min && UInt64.max &+ 1 == 0, "64-bit wrapping add")
}

func testFixedWidthIntegerWrappingSubtractionWitnesses() {
    requireIntegerWitness(Int8.min &- 1 == Int8.max && UInt8.min &- 1 == UInt8.max, "8-bit wrapping subtract")
    requireIntegerWitness(Int16.min &- 1 == Int16.max && UInt16.min &- 1 == UInt16.max, "16-bit wrapping subtract")
    requireIntegerWitness(Int32.min &- 1 == Int32.max && UInt32.min &- 1 == UInt32.max, "32-bit wrapping subtract")
    requireIntegerWitness(Int64.min &- 1 == Int64.max && UInt64.min &- 1 == UInt64.max, "64-bit wrapping subtract")
}

// The pinned Network graph includes these concrete standard-library witnesses
// for every signed and unsigned fixed-width integer.  Keep the checks generic
// where the graph's identifier is a protocol-extension overload, and concrete
// where it is a concrete BinaryInteger overload.
private func integerComparableWitness<T: FixedWidthInteger>(_ a: T, _ b: T) -> (Bool, Bool, Bool, Bool, Bool, Bool) {
    (a < b, a <= b, b > a, b >= a, a == a, a != b)
}

func testFixedWidthIntegerComparableWitnesses() {
    requireIntegerWitness(integerComparableWitness(Int8(2), 3) == (true, true, true, true, true, true), "Int8 comparison")
    requireIntegerWitness(integerComparableWitness(UInt8(2), 3) == (true, true, true, true, true, true), "UInt8 comparison")
    requireIntegerWitness(integerComparableWitness(Int16(2), 3) == (true, true, true, true, true, true), "Int16 comparison")
    requireIntegerWitness(integerComparableWitness(UInt16(2), 3) == (true, true, true, true, true, true), "UInt16 comparison")
    requireIntegerWitness(integerComparableWitness(Int32(2), 3) == (true, true, true, true, true, true), "Int32 comparison")
    requireIntegerWitness(integerComparableWitness(UInt32(2), 3) == (true, true, true, true, true, true), "UInt32 comparison")
    requireIntegerWitness(integerComparableWitness(Int64(2), 3) == (true, true, true, true, true, true), "Int64 comparison")
    requireIntegerWitness(integerComparableWitness(UInt64(2), 3) == (true, true, true, true, true, true), "UInt64 comparison")
}

func testFixedWidthIntegerConcreteComparisonWitnesses() {
    requireIntegerWitness(Int8(2) < 3 && Int8(2) <= 3 && Int8(3) > 2 && Int8(3) >= 2 && Int8(2) == 2 && Int8(2) != 3, "Int8 concrete comparison")
    requireIntegerWitness(UInt8(2) < 3 && UInt8(2) <= 3 && UInt8(3) > 2 && UInt8(3) >= 2 && UInt8(2) == 2 && UInt8(2) != 3, "UInt8 concrete comparison")
    requireIntegerWitness(Int16(2) < 3 && Int16(2) <= 3 && Int16(3) > 2 && Int16(3) >= 2 && Int16(2) == 2 && Int16(2) != 3, "Int16 concrete comparison")
    requireIntegerWitness(UInt16(2) < 3 && UInt16(2) <= 3 && UInt16(3) > 2 && UInt16(3) >= 2 && UInt16(2) == 2 && UInt16(2) != 3, "UInt16 concrete comparison")
    requireIntegerWitness(Int32(2) < 3 && Int32(2) <= 3 && Int32(3) > 2 && Int32(3) >= 2 && Int32(2) == 2 && Int32(2) != 3, "Int32 concrete comparison")
    requireIntegerWitness(UInt32(2) < 3 && UInt32(2) <= 3 && UInt32(3) > 2 && UInt32(3) >= 2 && UInt32(2) == 2 && UInt32(2) != 3, "UInt32 concrete comparison")
    requireIntegerWitness(Int64(2) < 3 && Int64(2) <= 3 && Int64(3) > 2 && Int64(3) >= 2 && Int64(2) == 2 && Int64(2) != 3, "Int64 concrete comparison")
    requireIntegerWitness(UInt64(2) < 3 && UInt64(2) <= 3 && UInt64(3) > 2 && UInt64(3) >= 2 && UInt64(2) == 2 && UInt64(2) != 3, "UInt64 concrete comparison")
}

func testFixedWidthIntegerRangeExpressionWitnesses() {
    let signed: Int16 = 4
    let unsigned: UInt16 = 4
    requireIntegerWitness((signed...).contains(5) && (...signed).contains(3), "signed partial ranges")
    requireIntegerWitness((unsigned...).contains(5) && (...unsigned).contains(3), "unsigned partial ranges")
    requireIntegerWitness((Int32(2)...Int32(5)).contains(4), "signed closed range")
    requireIntegerWitness((UInt32(2)...UInt32(5)).contains(4), "unsigned closed range")
    requireIntegerWitness((Int64(2)..<Int64(5)).contains(4), "signed half-open range")
    requireIntegerWitness((UInt64(2)..<UInt64(5)).contains(4), "unsigned half-open range")
}

private func integerBitwiseWitness<T: FixedWidthInteger>(_ a: T, _ b: T) -> (T, T, T) {
    (a & b, a | b, a ^ b)
}

func testFixedWidthIntegerBitwiseWitnesses() {
    requireIntegerWitness(integerBitwiseWitness(Int8(0b1100), 0b1010) == (8, 14, 6), "Int8 bitwise")
    requireIntegerWitness(integerBitwiseWitness(UInt8(0b1100), 0b1010) == (8, 14, 6), "UInt8 bitwise")
    requireIntegerWitness(integerBitwiseWitness(Int16(0b1100), 0b1010) == (8, 14, 6), "Int16 bitwise")
    requireIntegerWitness(integerBitwiseWitness(UInt16(0b1100), 0b1010) == (8, 14, 6), "UInt16 bitwise")
    requireIntegerWitness(integerBitwiseWitness(Int32(0b1100), 0b1010) == (8, 14, 6), "Int32 bitwise")
    requireIntegerWitness(integerBitwiseWitness(UInt32(0b1100), 0b1010) == (8, 14, 6), "UInt32 bitwise")
    requireIntegerWitness(integerBitwiseWitness(Int64(0b1100), 0b1010) == (8, 14, 6), "Int64 bitwise")
    requireIntegerWitness(integerBitwiseWitness(UInt64(0b1100), 0b1010) == (8, 14, 6), "UInt64 bitwise")
}

func testFixedWidthIntegerQuotientAndRemainderWitnesses() {
    requireIntegerWitness(Int8(17).quotientAndRemainder(dividingBy: 5) == (3, 2), "Int8 quotient")
    requireIntegerWitness(UInt8(17).quotientAndRemainder(dividingBy: 5) == (3, 2), "UInt8 quotient")
    requireIntegerWitness(Int16(17).quotientAndRemainder(dividingBy: 5) == (3, 2), "Int16 quotient")
    requireIntegerWitness(UInt16(17).quotientAndRemainder(dividingBy: 5) == (3, 2), "UInt16 quotient")
    requireIntegerWitness(Int32(17).quotientAndRemainder(dividingBy: 5) == (3, 2), "Int32 quotient")
    requireIntegerWitness(UInt32(17).quotientAndRemainder(dividingBy: 5) == (3, 2), "UInt32 quotient")
    requireIntegerWitness(Int64(17).quotientAndRemainder(dividingBy: 5) == (3, 2), "Int64 quotient")
    requireIntegerWitness(UInt64(17).quotientAndRemainder(dividingBy: 5) == (3, 2), "UInt64 quotient")
}

func testFixedWidthIntegerStrideWitnesses() {
    requireIntegerWitness(Int8(4).advanced(by: 3) == 7 && Int8(4).distance(to: 9) == 5, "Int8 stride")
    requireIntegerWitness(UInt8(4).advanced(by: 3) == 7 && UInt8(4).distance(to: 9) == 5, "UInt8 stride")
    requireIntegerWitness(Int16(4).advanced(by: 3) == 7 && Int16(4).distance(to: 9) == 5, "Int16 stride")
    requireIntegerWitness(UInt16(4).advanced(by: 3) == 7 && UInt16(4).distance(to: 9) == 5, "UInt16 stride")
    requireIntegerWitness(Int32(4).advanced(by: 3) == 7 && Int32(4).distance(to: 9) == 5, "Int32 stride")
    requireIntegerWitness(UInt32(4).advanced(by: 3) == 7 && UInt32(4).distance(to: 9) == 5, "UInt32 stride")
    requireIntegerWitness(Int64(4).advanced(by: 3) == 7 && Int64(4).distance(to: 9) == 5, "Int64 stride")
    requireIntegerWitness(UInt64(4).advanced(by: 3) == 7 && UInt64(4).distance(to: 9) == 5, "UInt64 stride")
}

func testFixedWidthIntegerDescriptionWitnesses() {
    requireIntegerWitness([Int8(7).description, Int16(7).description, Int32(7).description, Int64(7).description] == ["7", "7", "7", "7"], "signed descriptions")
    requireIntegerWitness([UInt8(7).description, UInt16(7).description, UInt32(7).description, UInt64(7).description] == ["7", "7", "7", "7"], "unsigned descriptions")
}

func testFixedWidthIntegerShiftWitnesses() {
    requireIntegerWitness(Int8(16) >> 2 == 4 && UInt8(16) >> 2 == 4, "8-bit shifts")
    requireIntegerWitness(Int16(16) >> 2 == 4 && UInt16(16) >> 2 == 4, "16-bit shifts")
    requireIntegerWitness(Int32(16) >> 2 == 4 && UInt32(16) >> 2 == 4, "32-bit shifts")
    requireIntegerWitness(Int64(16) >> 2 == 4 && UInt64(16) >> 2 == 4, "64-bit shifts")
}

func testIntegerArithmeticAssignmentWitnesses() {
    var i8: Int8 = 6; i8 *= 3; i8 /= 2; i8 %= 5; i8 += 2; i8 -= 1
    var u8: UInt8 = 6; u8 *= 3; u8 /= 2; u8 %= 5; u8 += 2; u8 -= 1
    var i16: Int16 = 6; i16 *= 3; i16 /= 2; i16 %= 5; i16 += 2; i16 -= 1
    var u16: UInt16 = 6; u16 *= 3; u16 /= 2; u16 %= 5; u16 += 2; u16 -= 1
    var i32: Int32 = 6; i32 *= 3; i32 /= 2; i32 %= 5; i32 += 2; i32 -= 1
    var u32: UInt32 = 6; u32 *= 3; u32 /= 2; u32 %= 5; u32 += 2; u32 -= 1
    var i64: Int64 = 6; i64 *= 3; i64 /= 2; i64 %= 5; i64 += 2; i64 -= 1
    var u64: UInt64 = 6; u64 *= 3; u64 /= 2; u64 %= 5; u64 += 2; u64 -= 1
    requireIntegerWitness(i8 == 5 && u8 == 5 && i16 == 5 && u16 == 5 && i32 == 5 && u32 == 5 && i64 == 5 && u64 == 5, "assignment arithmetic")
}

func testIntegerShiftAssignmentWitnesses() {
    var values: [UInt64] = []
    var i8: Int8 = 3; i8 <<= 2; i8 >>= 1; values.append(UInt64(i8))
    var u8: UInt8 = 3; u8 <<= 2; u8 >>= 1; values.append(UInt64(u8))
    var i16: Int16 = 3; i16 <<= 2; i16 >>= 1; values.append(UInt64(i16))
    var u16: UInt16 = 3; u16 <<= 2; u16 >>= 1; values.append(UInt64(u16))
    var i32: Int32 = 3; i32 <<= 2; i32 >>= 1; values.append(UInt64(i32))
    var u32: UInt32 = 3; u32 <<= 2; u32 >>= 1; values.append(UInt64(u32))
    var i64: Int64 = 3; i64 <<= 2; i64 >>= 1; values.append(UInt64(i64))
    var u64: UInt64 = 3; u64 <<= 2; u64 >>= 1; values.append(u64)
    requireIntegerWitness(values.allSatisfy { $0 == 6 }, "assignment shifts")
}

func testIntegerConversionWitnesses() {
    requireIntegerWitness(Int8(exactly: 7 as Int16) == 7 && UInt8(exactly: 7 as UInt16) == 7, "8 exact")
    requireIntegerWitness(Int16(clamping: Int32.max) == Int16.max && UInt16(clamping: UInt32.max) == UInt16.max, "clamping")
    requireIntegerWitness(Int32("2a", radix: 16) == 42 && UInt32("2a", radix: 16) == 42, "radix")
    requireIntegerWitness(Int64("42") == 42 && UInt64("42") == 42, "string")
    requireIntegerWitness(Int8(UInt8(7)) == 7 && UInt8(Int8(7)) == 7, "binary integer")
    requireIntegerWitness(Int16(exactly: UInt16(8)) == 8 && UInt16(exactly: Int16(8)) == 8, "binary exact")
    requireIntegerWitness(Int32(Int64(9)) == 9 && UInt32(UInt64(9)) == 9, "wide conversion")
    requireIntegerWitness(Int64(exactly: UInt64.max) == nil && UInt64(exactly: Int64(-1)) == nil, "failable bounds")
}

func testIntegerBasicArithmeticWitnesses() {
    requireIntegerWitness(Int8(6) + 2 == 8 && UInt8(6) - 2 == 4, "8 arithmetic")
    requireIntegerWitness(Int16(6) * 2 == 12 && UInt16(12) / 2 == 6, "16 arithmetic")
    requireIntegerWitness(Int32(6) + Int32(Int16(2)) == 8 && UInt64(UInt32(6)) < UInt64(8), "heterogeneous arithmetic/comparison")
    requireIntegerWitness(Int64.zero == 0 && UInt64.zero == 0, "zero")
}

func testSignedIntegerWitnesses() {
    var a: Int8 = 7; a.negate()
    var b: Int16 = 9; b.negate()
    var c: Int32 = 11; c.negate()
    var d: Int64 = 13; d.negate()
    requireIntegerWitness(-a == 7 && -b == 9 && -c == 11 && -d == 13, "signed negate")
    requireIntegerWitness(Int8.isSigned && Int16.isSigned && Int32.isSigned && Int64.isSigned, "signed marker")
    requireIntegerWitness(Int8.min < 0 && Int16.max > 0 && Int32.min < 0 && Int64.max > 0, "signed bounds")
    requireIntegerWitness(Int8(12).isMultiple(of: 3) && Int64(12).magnitude == 12, "signed numeric")
}

func testUnsignedIntegerWitnesses() {
    requireIntegerWitness(!UInt8.isSigned && !UInt16.isSigned && !UInt32.isSigned && !UInt64.isSigned, "unsigned marker")
    requireIntegerWitness(UInt8.min == 0 && UInt16.max > 0 && UInt32.min == 0 && UInt64.max > 0, "unsigned bounds")
    requireIntegerWitness(UInt8(12).isMultiple(of: 3) && UInt64(12).magnitude == 12, "unsigned numeric")
    requireIntegerWitness(UInt8(exactly: 255 as UInt16) == 255 && UInt16(UInt8(7)) == 7, "unsigned conversion")
}

func testIntegerRandomClosedRangeWitnesses() {
    requireIntegerWitness((0...0).contains(Int8.random(in: 0...0)), "Int8 closed random")
    requireIntegerWitness((0...0).contains(UInt8.random(in: 0...0)), "UInt8 closed random")
    requireIntegerWitness((0...0).contains(Int16.random(in: 0...0)), "Int16 closed random")
    requireIntegerWitness((0...0).contains(UInt16.random(in: 0...0)), "UInt16 closed random")
    requireIntegerWitness((0...0).contains(Int32.random(in: 0...0)), "Int32 closed random")
    requireIntegerWitness((0...0).contains(UInt32.random(in: 0...0)), "UInt32 closed random")
    requireIntegerWitness((0...0).contains(Int64.random(in: 0...0)), "Int64 closed random")
    requireIntegerWitness((0...0).contains(UInt64.random(in: 0...0)), "UInt64 closed random")
}

func testIntegerRandomRangeWitnesses() {
    requireIntegerWitness((0..<1).contains(Int8.random(in: 0..<1)), "Int8 random")
    requireIntegerWitness((0..<1).contains(UInt8.random(in: 0..<1)), "UInt8 random")
    requireIntegerWitness((0..<1).contains(Int16.random(in: 0..<1)), "Int16 random")
    requireIntegerWitness((0..<1).contains(UInt16.random(in: 0..<1)), "UInt16 random")
    requireIntegerWitness((0..<1).contains(Int32.random(in: 0..<1)), "Int32 random")
    requireIntegerWitness((0..<1).contains(UInt32.random(in: 0..<1)), "UInt32 random")
    requireIntegerWitness((0..<1).contains(Int64.random(in: 0..<1)), "Int64 random")
    requireIntegerWitness((0..<1).contains(UInt64.random(in: 0..<1)), "UInt64 random")
}

func testIntegerRandomGeneratorWitnesses() {
    var generator = SystemRandomNumberGenerator()
    let a = Int8.random(in: 0...0, using: &generator)
    let b = UInt8.random(in: 0..<1, using: &generator)
    let c = Int16.random(in: 0...0, using: &generator)
    let d = UInt16.random(in: 0..<1, using: &generator)
    let e = Int32.random(in: 0...0, using: &generator)
    let f = UInt32.random(in: 0..<1, using: &generator)
    let g = Int64.random(in: 0...0, using: &generator)
    let h = UInt64.random(in: 0..<1, using: &generator)
    requireIntegerWitness(a == 0 && b == 0 && c == 0 && d == 0 && e == 0 && f == 0 && g == 0 && h == 0, "generator random")
}

func testIntegerBoundsMultiplicityAndLiteralWitnesses() {
    let literals: (Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64) = (6, 6, 6, 6, 6, 6, 6, 6)
    requireIntegerWitness(literals.0.isMultiple(of: 3) && literals.1.isMultiple(of: 3), "8-bit multiples")
    requireIntegerWitness(literals.2.isMultiple(of: 3) && literals.3.isMultiple(of: 3), "16-bit multiples")
    requireIntegerWitness(literals.4.isMultiple(of: 3) && literals.5.isMultiple(of: 3), "32-bit multiples")
    requireIntegerWitness(literals.6.isMultiple(of: 3) && literals.7.isMultiple(of: 3), "64-bit multiples")
    requireIntegerWitness(Int8.min == -128 && UInt8.min == 0 && Int16.max == 32767 && UInt16.max == 65535, "small bounds")
    requireIntegerWitness(Int32.min < 0 && UInt32.min == 0 && Int64.max > 0 && UInt64.max > 0, "large bounds")
}

func testIntegerFoundationDefaultFormattingWitnesses() {
    requireIntegerWitness(Int8(42).formatted() == "42", "Int8 formatting")
    requireIntegerWitness(UInt8(42).formatted() == "42", "UInt8 formatting")
    requireIntegerWitness(Int16(42).formatted() == "42", "Int16 formatting")
    requireIntegerWitness(UInt16(42).formatted() == "42", "UInt16 formatting")
    requireIntegerWitness(Int32(42).formatted() == "42", "Int32 formatting")
    requireIntegerWitness(UInt32(42).formatted() == "42", "UInt32 formatting")
    requireIntegerWitness(Int64(42).formatted() == "42", "Int64 formatting")
    requireIntegerWitness(UInt64(42).formatted() == "42", "UInt64 formatting")
}
