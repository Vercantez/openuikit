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
