import CoreML
import Foundation

// The CoreML symbol graph contains synthesized conformances for the integer
// scalar types accepted by shaped arrays.  Keep these focused: each test calls
// the concrete overloads rather than relying on a generic declaration check.
func testIntegerOverlayComparisonsAndRanges() {
    precondition(Int(2) > 1 && Int8(2) >= 2 && Int16(1) < 2 && Int32(1) <= 1)
    precondition(UInt8(1) != 2 && UInt16(2) == 2 && UInt32(3) > 2)
    precondition(Array(Int8(1)..<Int8(3)) == [1, 2])
    precondition(Array(Int16(1)...Int16(2)) == [1, 2])
    precondition((...Int32(2)).contains(1) && (..<UInt8(2)).contains(1))
    precondition((UInt16(1)...).contains(2))
}

func testIntegerOverlayArithmeticAndOverflow() {
    var i: Int8 = 4
    i += 2; i -= 1
    precondition(i == 5 && -i == -5)
    i.negate(); precondition(i == -5)
    i &+= 10; i &-= 2; i &*= 3
    precondition(i == 9)
    precondition(Int16.max &+ 1 == Int16.min)
    precondition(Int32.min &- 1 == Int32.max)
    precondition(UInt8.max &* 2 == 254)
    precondition((UInt16(9).quotientAndRemainder(dividingBy: 4)).quotient == 2)
    precondition(Int(12).isMultiple(of: 3))
}

func testIntegerOverlayBitwiseAndShifts() {
    precondition((Int(6) & 3) == 2 && (Int8(4) | 1) == 5)
    precondition((Int16(7) ^ 3) == 4 && (~Int32(0)) == -1)
    precondition((UInt8(1) << 2) == 4 && (UInt16(8) >> 2) == 2)
    precondition((UInt32.max &<< 1) == UInt32.max &* 2)
    precondition((Int8(-1) &>> 1) == -1)
    var value: UInt16 = 8
    value >>= 1; value <<= 2; value &>>= 1; value &<<= 1
    precondition(value == 16)
}

func testIntegerOverlayInitializersAndConversions() {
    precondition(Int() == 0 && Int8(integerLiteral: 7) == 7)
    precondition(Int16(exactly: 12.0) == 12)
    precondition(Int32(clamping: Int64.max) == Int32.max)
    precondition(UInt8(truncatingIfNeeded: 257) == 1)
    precondition(UInt16(42) == 42 && UInt32(Int8(7)) == 7)
    precondition(Int8(UInt8(8)) == 8 && Int16(UInt16(9)) == 9)
    precondition(Int32(UInt32(10)) == 10 && Int(UInt8(11)) == 11)
}

func testIntegerOverlayPropertiesAndEndian() {
    precondition(Int.isSigned && Int8.isSigned && !UInt8.isSigned)
    precondition(Int16.min < 0 && UInt16.min == 0 && UInt32.max > 0)
    precondition(Int32.zero == 0 && UInt8(8).bitWidth == 8)
    precondition(Int8(-3).magnitude == 3)
    let x: UInt32 = 0x01020304
    precondition(UInt32(littleEndian: x.littleEndian) == x)
    precondition(UInt32(bigEndian: x.bigEndian) == x)
    precondition(Int16(14).description == "14")
}

func testIntegerOverlayStrideAndDistance() {
    precondition(Int(2).advanced(by: 3) == 5 && Int(2).distance(to: 7) == 5)
    precondition(Int8(2).advanced(by: 3) == 5 && Int8(2).distance(to: 7) == 5)
    precondition(Int16(2).advanced(by: 3) == 5 && Int16(2).distance(to: 7) == 5)
    precondition(Int32(2).advanced(by: 3) == 5 && Int32(2).distance(to: 7) == 5)
    precondition(UInt8(2).advanced(by: 3) == 5 && UInt8(2).distance(to: 7) == 5)
    precondition(UInt16(2).advanced(by: 3) == 5 && UInt16(2).distance(to: 7) == 5)
    precondition(UInt32(2).advanced(by: 3) == 5 && UInt32(2).distance(to: 7) == 5)
}

func testIntegerOverlayRandomRanges() {
    var generator = SystemRandomNumberGenerator()
    precondition((1...3).contains(Int.random(in: 1...3)))
    precondition((Int8(1)...3).contains(Int8.random(in: 1...3, using: &generator)))
    precondition((Int16(1)..<4).contains(Int16.random(in: 1..<4)))
    precondition((Int32(1)...3).contains(Int32.random(in: 1...3, using: &generator)))
    precondition((UInt8(1)...3).contains(UInt8.random(in: 1...3)))
    precondition((UInt16(1)...3).contains(UInt16.random(in: 1...3, using: &generator)))
    precondition((UInt32(1)..<4).contains(UInt32.random(in: 1..<4)))
}

func testIntegerOverlayFormattingAndParsing() {
    precondition(Int(12).formatted() == "12")
    precondition(Int8(12).formatted() == "12")
    precondition(Int16(12).formatted() == "12")
    precondition(Int32(12).formatted() == "12")
    precondition(UInt8(12).formatted() == "12")
    precondition(UInt16(12).formatted() == "12")
    precondition(UInt32(12).formatted() == "12")
    precondition(Int("12", radix: 10) == 12 && Int8("7", radix: 10) == 7)
    precondition(UInt16("ff", radix: 16) == 255 && UInt32("10", radix: 2) == 2)
    precondition((try? Int("12", format: .number)) == 12)
    precondition((try? Int8("12", format: .number)) == 12)
    precondition((try? UInt32("12", format: .number)) == 12)
}
