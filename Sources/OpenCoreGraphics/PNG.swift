// Minimal PNG encoder: RGBA8, zlib stream with STORED deflate blocks.
// Valid PNG, no compression, zero dependencies.

func _pngEncode(_ bmp: Bitmap) -> [UInt8] {
    var out: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    func be32(_ v: UInt32) -> [UInt8] {
        [UInt8(v >> 24 & 0xFF), UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)]
    }
    func chunk(_ type: String, _ data: [UInt8]) {
        out += be32(UInt32(data.count))
        let typed = Array(type.utf8) + data
        out += typed
        out += be32(_crc32(typed))
    }

    var ihdr = be32(UInt32(bmp.width)) + be32(UInt32(bmp.height))
    ihdr += [8, 6, 0, 0, 0]  // 8-bit, RGBA, deflate, standard filter, no interlace
    chunk("IHDR", ihdr)

    // Raw scanlines with filter byte 0.
    var raw = [UInt8]()
    raw.reserveCapacity(bmp.height * (1 + bmp.width * 4))
    let rowBytes = bmp.width * 4
    for y in 0..<bmp.height {
        raw.append(0)
        raw += bmp.pixels[y * rowBytes..<(y + 1) * rowBytes]
    }

    // zlib: header + stored deflate blocks + adler32
    var idat: [UInt8] = [0x78, 0x01]
    var offset = 0
    while offset < raw.count {
        let len = Swift.min(65535, raw.count - offset)
        let final: UInt8 = (offset + len == raw.count) ? 1 : 0
        idat.append(final)  // BFINAL + BTYPE=00 (stored)
        idat.append(UInt8(len & 0xFF)); idat.append(UInt8(len >> 8))
        let nlen = ~UInt16(len)
        idat.append(UInt8(nlen & 0xFF)); idat.append(UInt8(nlen >> 8))
        idat += raw[offset..<offset + len]
        offset += len
    }
    idat += be32(_adler32(raw))
    chunk("IDAT", idat)
    chunk("IEND", [])
    return out
}

private let _crcTable: [UInt32] = {
    (0..<256).map { n -> UInt32 in
        var c = UInt32(n)
        for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
        return c
    }
}()

func _crc32(_ data: [UInt8]) -> UInt32 {
    var c: UInt32 = 0xFFFFFFFF
    for b in data { c = _crcTable[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
    return c ^ 0xFFFFFFFF
}

func _adler32(_ data: [UInt8]) -> UInt32 {
    var a: UInt32 = 1, b: UInt32 = 0
    for byte in data {
        a = (a + UInt32(byte)) % 65521
        b = (b + a) % 65521
    }
    return (b << 16) | a
}
