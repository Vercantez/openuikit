import Foundation

enum QRCode {
    struct Matrix {
        var size: Int
        var modules: [Bool]

        init(size: Int, filled: Bool = false) {
            self.size = size
            self.modules = [Bool](repeating: filled, count: size * size)
        }

        subscript(x: Int, y: Int) -> Bool {
            get {
                guard x >= 0, y >= 0, x < size, y < size else { return false }
                return modules[y * size + x]
            }
            set {
                guard x >= 0, y >= 0, x < size, y < size else { return }
                modules[y * size + x] = newValue
            }
        }

        func raster(moduleSize: Int, quietZone: Int) -> VisionRaster {
            let scale = max(1, moduleSize)
            let quiet = max(0, quietZone)
            let dim = (size + quiet * 2) * scale
            var image = VisionRaster(width: dim, height: dim, filled: (255, 255, 255, 255))
            for y in 0..<size {
                for x in 0..<size {
                    if self[x, y] {
                        let originX = (x + quiet) * scale
                        let originY = (y + quiet) * scale
                        for dy in 0..<scale {
                            for dx in 0..<scale {
                                image[originX + dx, originY + dy] = (0, 0, 0, 255)
                            }
                        }
                    }
                }
            }
            return image
        }
    }

    static func encode(_ payload: String) throws -> Matrix {
        let bytes = Array(payload.utf8)
        let version = try versionForByteCount(bytes.count)
        let spec = QRSpec.spec(version)
        var bits = BitBuffer()
        bits.append(4, value: 0b0100)
        bits.append(spec.countBits, value: bytes.count)
        for byte in bytes {
            bits.append(8, value: Int(byte))
        }
        bits.append(min(4, spec.dataCodewords * 8 - bits.count), value: 0)
        while bits.count % 8 != 0 {
            bits.append(1, value: 0)
        }
        var codewords = bits.bytes()
        let pads: [UInt8] = [0xEC, 0x11]
        var padIndex = 0
        while codewords.count < spec.dataCodewords {
            codewords.append(pads[padIndex % 2])
            padIndex += 1
        }
        if codewords.count > spec.dataCodewords {
            throw vnMakeError(.invalidArgument, description: "QR payload exceeds version capacity")
        }
        let ecc = ReedSolomon.encode(codewords, eccCount: spec.eccCodewords)
        var all = codewords
        all.append(contentsOf: ecc)
        let size = version * 4 + 17
        var matrix = Matrix(size: size)
        var reserved = Matrix(size: size)
        placeFinders(&matrix, reserved: &reserved)
        placeTiming(&matrix, reserved: &reserved)
        placeDarkModule(&matrix, reserved: &reserved, version: version)
        if version >= 2 {
            placeAlignments(&matrix, reserved: &reserved, version: version)
        }
        placeFormat(&matrix, reserved: &reserved, mask: 0)
        placeData(&matrix, reserved: reserved, codewords: all)
        applyMask(&matrix, reserved: reserved, mask: 0)
        placeFormat(&matrix, reserved: &reserved, mask: 0)
        return matrix
    }

    static func decode(_ raster: VisionRaster) -> (String, CGRect)? {
        let binary = binarize(raster)
        if let sampled = sampleAxisAligned(binary, width: raster.width, height: raster.height),
           let payload = decodeMatrix(sampled.matrix) {
            return (payload, sampled.box)
        }
        guard let sampled = sampleMatrix(binary, width: raster.width, height: raster.height) else {
            return nil
        }
        guard let payload = decodeMatrix(sampled.matrix) else { return nil }
        return (payload, sampled.box)
    }

    private static func sampleAxisAligned(
        _ binary: [UInt8],
        width: Int,
        height: Int
    ) -> (matrix: Matrix, box: CGRect)? {
        var minX = width, minY = height, maxX = 0, maxY = 0
        var found = false
        for y in 0..<height {
            for x in 0..<width {
                if binary[y * width + x] == 1 {
                    found = true
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        guard found else { return nil }
        let boxWidth = max(1, maxX - minX + 1)
        let boxHeight = max(1, maxY - minY + 1)
        for version in 1...6 {
            let size = version * 4 + 17
            let moduleX = Double(boxWidth) / Double(size)
            let moduleY = Double(boxHeight) / Double(size)
            if abs(moduleX - moduleY) > max(2, moduleX * 0.25) { continue }
            if moduleX < 1 { continue }
            var matrix = Matrix(size: size)
            for y in 0..<size {
                for x in 0..<size {
                    let px = min(width - 1, max(0, Int((Double(minX) + (Double(x) + 0.5) * moduleX).rounded())))
                    let py = min(height - 1, max(0, Int((Double(minY) + (Double(y) + 0.5) * moduleY).rounded())))
                    matrix[x, y] = binary[py * width + px] == 1
                }
            }
            if decodeMatrix(matrix) != nil {
                let box = visionNormalizedBox(
                    minX: Double(minX),
                    minY: Double(minY),
                    maxX: Double(maxX + 1),
                    maxY: Double(maxY + 1),
                    width: width,
                    height: height
                )
                return (matrix, box)
            }
        }
        return nil
    }

    private static func versionForByteCount(_ count: Int) throws -> Int {
        for version in 1...6 {
            let spec = QRSpec.spec(version)
            let header = 4 + spec.countBits
            let need = (header + count * 8 + 7) / 8
            if need <= spec.dataCodewords {
                return version
            }
        }
        throw vnMakeError(.invalidArgument, description: "QR payload too large for Linux encoder (version 1-6)")
    }

    private static func placeFinders(_ matrix: inout Matrix, reserved: inout Matrix) {
        let origins = [(0, 0), (matrix.size - 7, 0), (0, matrix.size - 7)]
        for (ox, oy) in origins {
            for y in -1...7 {
                for x in -1...7 {
                    let px = ox + x
                    let py = oy + y
                    guard px >= 0, py >= 0, px < matrix.size, py < matrix.size else { continue }
                    reserved[px, py] = true
                    let dx = x < 0 ? 0 : (x > 6 ? 6 : x)
                    let dy = y < 0 ? 0 : (y > 6 ? 6 : y)
                    let ring = max(abs(dx - 3), abs(dy - 3))
                    matrix[px, py] = ring != 2 && !(x < 0 || y < 0 || x > 6 || y > 6)
                }
            }
        }
    }

    private static func placeTiming(_ matrix: inout Matrix, reserved: inout Matrix) {
        for i in 8..<(matrix.size - 8) {
            matrix[i, 6] = i % 2 == 0
            matrix[6, i] = i % 2 == 0
            reserved[i, 6] = true
            reserved[6, i] = true
        }
    }

    private static func placeDarkModule(_ matrix: inout Matrix, reserved: inout Matrix, version: Int) {
        let x = 8
        let y = 4 * version + 9
        matrix[x, y] = true
        reserved[x, y] = true
    }

    private static func placeAlignments(_ matrix: inout Matrix, reserved: inout Matrix, version: Int) {
        let positions = QRSpec.alignment(version)
        for y in positions {
            for x in positions {
                if (x < 9 && y < 9) || (x > matrix.size - 10 && y < 9) || (x < 9 && y > matrix.size - 10) {
                    continue
                }
                for dy in -2...2 {
                    for dx in -2...2 {
                        let px = x + dx
                        let py = y + dy
                        reserved[px, py] = true
                        matrix[px, py] = max(abs(dx), abs(dy)) != 1
                    }
                }
            }
        }
    }

    private static func formatBits(mask: Int) -> Int {
        // ECC-M = 00
        let data = mask & 0b111
        var d = data << 10
        let generator = 0b10100110111
        for i in stride(from: 14, through: 10, by: -1) {
            if (d & (1 << i)) != 0 {
                d ^= generator << (i - 10)
            }
        }
        return ((data << 10) | d) ^ 0x5412
    }

    private static func placeFormat(_ matrix: inout Matrix, reserved: inout Matrix, mask: Int) {
        let bits = formatBits(mask: mask)
        for i in 0..<15 {
            let bit = ((bits >> (14 - i)) & 1) == 1
            if i < 6 {
                matrix[i, 8] = bit
                reserved[i, 8] = true
            } else if i < 8 {
                matrix[i + 1, 8] = bit
                reserved[i + 1, 8] = true
            } else {
                matrix[matrix.size - 15 + i, 8] = bit
                reserved[matrix.size - 15 + i, 8] = true
            }
            if i < 8 {
                matrix[8, matrix.size - 1 - i] = bit
                reserved[8, matrix.size - 1 - i] = true
            } else if i < 9 {
                matrix[8, 15 - i] = bit
                reserved[8, 15 - i] = true
            } else {
                matrix[8, 14 - i] = bit
                reserved[8, 14 - i] = true
            }
        }
        reserved[8, 8] = true
    }

    private static func placeData(_ matrix: inout Matrix, reserved: Matrix, codewords: [UInt8]) {
        var bitIndex = 0
        var bits: [Bool] = []
        bits.reserveCapacity(codewords.count * 8)
        for byte in codewords {
            for shift in stride(from: 7, through: 0, by: -1) {
                bits.append(((byte >> shift) & 1) == 1)
            }
        }
        var goingUp = true
        var x = matrix.size - 1
        while x > 0 {
            if x == 6 { x -= 1 }
            let yRange = goingUp ? stride(from: matrix.size - 1, through: 0, by: -1) : stride(from: 0, through: matrix.size - 1, by: 1)
            for y in yRange {
                for dx in [0, -1] {
                    let px = x + dx
                    if reserved[px, y] { continue }
                    matrix[px, y] = bitIndex < bits.count ? bits[bitIndex] : false
                    bitIndex += 1
                }
            }
            goingUp.toggle()
            x -= 2
        }
    }

    private static func maskBit(_ mask: Int, x: Int, y: Int) -> Bool {
        switch mask {
        case 0: return (x + y) % 2 == 0
        case 1: return y % 2 == 0
        case 2: return x % 3 == 0
        case 3: return (x + y) % 3 == 0
        case 4: return (y / 2 + x / 3) % 2 == 0
        case 5: return (x * y) % 2 + (x * y) % 3 == 0
        case 6: return ((x * y) % 2 + (x * y) % 3) % 2 == 0
        default: return ((x + y) % 2 + (x * y) % 3) % 2 == 0
        }
    }

    private static func applyMask(_ matrix: inout Matrix, reserved: Matrix, mask: Int) {
        for y in 0..<matrix.size {
            for x in 0..<matrix.size {
                if !reserved[x, y], maskBit(mask, x: x, y: y) {
                    matrix[x, y].toggle()
                }
            }
        }
    }

    private static func binarize(_ raster: VisionRaster) -> [UInt8] {
        let gray = raster.grayscale()
        var sum = 0
        for value in gray { sum += Int(value) }
        let mean = gray.isEmpty ? 128 : sum / gray.count
        return gray.map { $0 < UInt8(mean) ? 1 : 0 }
    }

    private static func sampleMatrix(_ binary: [UInt8], width: Int, height: Int) -> (matrix: Matrix, box: CGRect)? {
        guard let finders = findFinderPatterns(binary, width: width, height: height), finders.count >= 3 else {
            return nil
        }
        let ordered = orderFinders(finders)
        let module = max(1.0, (ordered.tl.size + ordered.tr.size + ordered.bl.size) / 3)
        let dx = ordered.tr.x - ordered.tl.x
        let dy = ordered.tr.y - ordered.tl.y
        let distance = hypot(dx, dy)
        let versionSize = Int((distance / module + 7).rounded())
        let size: Int
        if abs(versionSize - 21) <= 2 {
            size = 21
        } else {
            let version = max(1, min(6, Int(((Double(versionSize) - 17) / 4).rounded())))
            size = version * 4 + 17
        }
        var matrix = Matrix(size: size)
        let originX = ordered.tl.x - 3.5 * module
        let originY = ordered.tl.y - 3.5 * module
        let rightX = (ordered.tr.x + 3.5 * module - originX) / Double(size)
        let rightY = (ordered.tr.y - 3.5 * module - originY) / Double(size)
        let downX = (ordered.bl.x - 3.5 * module - originX) / Double(size)
        let downY = (ordered.bl.y + 3.5 * module - originY) / Double(size)
        for y in 0..<size {
            for x in 0..<size {
                let px = originX + (Double(x) + 0.5) * rightX + (Double(y) + 0.5) * downX
                let py = originY + (Double(x) + 0.5) * rightY + (Double(y) + 0.5) * downY
                let ix = Int(px.rounded())
                let iy = Int(py.rounded())
                if ix >= 0, iy >= 0, ix < width, iy < height {
                    matrix[x, y] = binary[iy * width + ix] == 1
                }
            }
        }
        let minX = min(ordered.tl.x, min(ordered.tr.x, ordered.bl.x)) - 3.5 * module
        let maxX = max(ordered.tl.x, max(ordered.tr.x, ordered.bl.x)) + 3.5 * module
        let minY = min(ordered.tl.y, min(ordered.tr.y, ordered.bl.y)) - 3.5 * module
        let maxY = max(ordered.tl.y, max(ordered.tr.y, ordered.bl.y)) + 3.5 * module
        let box = visionNormalizedBox(minX: minX, minY: minY, maxX: maxX, maxY: maxY, width: width, height: height)
        return (matrix, box)
    }

    private struct Finder {
        var x: Double
        var y: Double
        var size: Double
    }

    private static func findFinderPatterns(_ binary: [UInt8], width: Int, height: Int) -> [Finder]? {
        var candidates: [Finder] = []
        for y in 0..<height {
            var runs: [(Int, Int)] = []
            var x = 0
            while x < width {
                let color = Int(binary[y * width + x])
                let start = x
                while x < width, Int(binary[y * width + x]) == color { x += 1 }
                runs.append((color, x - start))
            }
            guard runs.count >= 5 else { continue }
            var offset = 0
            for index in 0..<(runs.count - 4) {
                let r0 = runs[index]
                let r1 = runs[index + 1]
                let r2 = runs[index + 2]
                let r3 = runs[index + 3]
                let r4 = runs[index + 4]
                if r0.0 == 1, r1.0 == 0, r2.0 == 1, r3.0 == 0, r4.0 == 1,
                   ratio11311(r0.1, r1.1, r2.1, r3.1, r4.1) {
                    let startX = offset
                    let widthModules = r0.1 + r1.1 + r2.1 + r3.1 + r4.1
                    let centerX = Double(startX) + Double(widthModules) / 2
                    let module = Double(widthModules) / 7
                    if let centerY = crossCheckVertical(
                        binary,
                        width: width,
                        height: height,
                        centerX: Int(centerX.rounded()),
                        centerY: y,
                        module: module
                    ) {
                        candidates.append(Finder(x: centerX, y: centerY, size: module))
                    }
                }
                offset += r0.1
            }
        }
        return clusterFinders(candidates)
    }

    private static func ratio11311(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int) -> Bool {
        let total = a + b + c + d + e
        guard total >= 7 else { return false }
        let unit = Double(total) / 7
        func near(_ value: Int, _ expected: Double) -> Bool {
            abs(Double(value) - expected) <= max(1.2, expected * 0.6)
        }
        return near(a, unit) && near(b, unit) && near(c, 3 * unit) && near(d, unit) && near(e, unit)
    }

    private static func crossCheckVertical(
        _ binary: [UInt8],
        width: Int,
        height: Int,
        centerX: Int,
        centerY: Int,
        module: Double
    ) -> Double? {
        guard centerX >= 0, centerX < width else { return nil }
        var y = centerY
        while y >= 0, binary[y * width + centerX] == 1 { y -= 1 }
        let afterBlack = y
        while y >= 0, binary[y * width + centerX] == 0 { y -= 1 }
        while y >= 0, binary[y * width + centerX] == 1 { y -= 1 }
        let top = y + 1
        y = centerY
        while y < height, binary[y * width + centerX] == 1 { y += 1 }
        while y < height, binary[y * width + centerX] == 0 { y += 1 }
        while y < height, binary[y * width + centerX] == 1 { y += 1 }
        let bottom = y - 1
        let span = bottom - top + 1
        guard span > 0 else { return nil }
        let unit = Double(span) / 7
        if abs(unit - module) > max(1.5, module * 0.75) { return nil }
        _ = afterBlack
        return Double(top + bottom) / 2
    }

    private static func clusterFinders(_ candidates: [Finder]) -> [Finder]? {
        var clusters: [Finder] = []
        for candidate in candidates {
            if let index = clusters.firstIndex(where: {
                hypot($0.x - candidate.x, $0.y - candidate.y) < max(4, $0.size * 3)
            }) {
                let existing = clusters[index]
                clusters[index] = Finder(
                    x: (existing.x + candidate.x) / 2,
                    y: (existing.y + candidate.y) / 2,
                    size: (existing.size + candidate.size) / 2
                )
            } else {
                clusters.append(candidate)
            }
        }
        return clusters.count >= 3 ? clusters : nil
    }

    private static func orderFinders(_ finders: [Finder]) -> (tl: Finder, tr: Finder, bl: Finder) {
        var best = (tl: finders[0], tr: finders[1], bl: finders[2])
        var bestScore = Double.greatestFiniteMagnitude
        for i in 0..<finders.count {
            for j in 0..<finders.count where j != i {
                for k in 0..<finders.count where k != i && k != j {
                    let a = finders[i]
                    let b = finders[j]
                    let c = finders[k]
                    let abx = b.x - a.x
                    let aby = b.y - a.y
                    let acx = c.x - a.x
                    let acy = c.y - a.y
                    let cross = abx * acy - aby * acx
                    if cross > 0 { continue }
                    let score = abs(hypot(abx, aby) - hypot(acx, acy))
                    if score < bestScore {
                        bestScore = score
                        best = (a, b, c)
                    }
                }
            }
        }
        return best
    }

    private static func decodeMatrix(_ matrix: Matrix) -> String? {
        let size = matrix.size
        let version = (size - 17) / 4
        guard version >= 1, version <= 6 else { return nil }
        guard let mask = readMask(matrix) else { return nil }
        var copy = matrix
        var reserved = Matrix(size: size)
        placeFinders(&copy, reserved: &reserved)
        placeTiming(&copy, reserved: &reserved)
        placeDarkModule(&copy, reserved: &reserved, version: version)
        if version >= 2 {
            placeAlignments(&copy, reserved: &reserved, version: version)
        }
        placeFormat(&copy, reserved: &reserved, mask: mask)
        var unmasked = matrix
        applyMask(&unmasked, reserved: reserved, mask: mask)
        let spec = QRSpec.spec(version)
        let total = spec.dataCodewords + spec.eccCodewords
        var bits: [Bool] = []
        var goingUp = true
        var x = size - 1
        while x > 0 {
            if x == 6 { x -= 1 }
            let yRange = goingUp ? stride(from: size - 1, through: 0, by: -1) : stride(from: 0, through: size - 1, by: 1)
            for y in yRange {
                for dx in [0, -1] {
                    let px = x + dx
                    if reserved[px, y] { continue }
                    bits.append(unmasked[px, y])
                }
            }
            goingUp.toggle()
            x -= 2
        }
        var codewords: [UInt8] = []
        var index = 0
        while codewords.count < total && index + 8 <= bits.count {
            var value: UInt8 = 0
            for _ in 0..<8 {
                value = (value << 1) | (bits[index] ? 1 : 0)
                index += 1
            }
            codewords.append(value)
        }
        guard codewords.count >= total else { return nil }
        let data = Array(codewords.prefix(spec.dataCodewords))
        let ecc = Array(codewords.dropFirst(spec.dataCodewords).prefix(spec.eccCodewords))
        guard let corrected = ReedSolomon.decode(data + ecc, dataCount: spec.dataCodewords, eccCount: spec.eccCodewords) else {
            return nil
        }
        return decodeBytes(corrected, countBits: spec.countBits)
    }

    private static func readMask(_ matrix: Matrix) -> Int? {
        var bits = 0
        for i in 0..<15 {
            let bit: Bool
            if i < 8 {
                bit = matrix[8, matrix.size - 1 - i]
            } else if i < 9 {
                bit = matrix[8, 15 - i]
            } else {
                bit = matrix[8, 14 - i]
            }
            bits = (bits << 1) | (bit ? 1 : 0)
        }
        let unmasked = bits ^ 0x5412
        return unmasked >> 10 & 0b111
    }

    private static func decodeBytes(_ data: [UInt8], countBits: Int) -> String? {
        var buffer = BitBuffer()
        for byte in data {
            buffer.append(8, value: Int(byte))
        }
        var cursor = 0
        func take(_ count: Int) -> Int? {
            guard cursor + count <= buffer.bits.count else { return nil }
            var value = 0
            for _ in 0..<count {
                value = (value << 1) | (buffer.bits[cursor] ? 1 : 0)
                cursor += 1
            }
            return value
        }
        var output = Data()
        while let mode = take(4) {
            if mode == 0 { break }
            if mode == 0b0100 {
                guard let count = take(countBits) else { return nil }
                for _ in 0..<count {
                    guard let byte = take(8) else { return nil }
                    output.append(UInt8(byte))
                }
            } else if mode == 0b0001 {
                guard let count = take(versionCountBits(numeric: true, countBits: countBits)) else { return nil }
                var remaining = count
                while remaining >= 3 {
                    guard let value = take(10) else { return nil }
                    output.append(contentsOf: String(format: "%03d", value).utf8)
                    remaining -= 3
                }
                if remaining == 2 {
                    guard let value = take(7) else { return nil }
                    output.append(contentsOf: String(format: "%02d", value).utf8)
                } else if remaining == 1 {
                    guard let value = take(4) else { return nil }
                    output.append(contentsOf: String(format: "%d", value).utf8)
                }
            } else if mode == 0b0010 {
                let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:")
                guard let count = take(versionCountBits(numeric: false, countBits: countBits)) else { return nil }
                var remaining = count
                while remaining >= 2 {
                    guard let value = take(11) else { return nil }
                    output.append(alphabet[value / 45].asciiValue ?? 0)
                    output.append(alphabet[value % 45].asciiValue ?? 0)
                    remaining -= 2
                }
                if remaining == 1 {
                    guard let value = take(6) else { return nil }
                    output.append(alphabet[value].asciiValue ?? 0)
                }
            } else {
                break
            }
        }
        return String(data: output, encoding: .utf8)
    }

    private static func versionCountBits(numeric: Bool, countBits: Int) -> Int {
        if numeric { return countBits == 8 ? 10 : 12 }
        return countBits == 8 ? 9 : 11
    }
}

private struct QRSpec {
    var dataCodewords: Int
    var eccCodewords: Int
    var countBits: Int

    static func spec(_ version: Int) -> QRSpec {
        switch version {
        case 1: return QRSpec(dataCodewords: 16, eccCodewords: 10, countBits: 8)
        case 2: return QRSpec(dataCodewords: 28, eccCodewords: 16, countBits: 8)
        case 3: return QRSpec(dataCodewords: 44, eccCodewords: 26, countBits: 8)
        case 4: return QRSpec(dataCodewords: 64, eccCodewords: 18, countBits: 8)
        case 5: return QRSpec(dataCodewords: 86, eccCodewords: 24, countBits: 8)
        default: return QRSpec(dataCodewords: 108, eccCodewords: 16, countBits: 8)
        }
    }

    static func alignment(_ version: Int) -> [Int] {
        switch version {
        case 2: return [6, 18]
        case 3: return [6, 22]
        case 4: return [6, 26]
        case 5: return [6, 30]
        case 6: return [6, 34]
        default: return []
        }
    }
}

private struct BitBuffer {
    var bits: [Bool] = []
    var count: Int { bits.count }

    mutating func append(_ width: Int, value: Int) {
        guard width > 0 else { return }
        for shift in stride(from: width - 1, through: 0, by: -1) {
            bits.append(((value >> shift) & 1) == 1)
        }
    }

    func bytes() -> [UInt8] {
        var output: [UInt8] = []
        var index = 0
        while index < bits.count {
            var value: UInt8 = 0
            for _ in 0..<8 {
                value <<= 1
                if index < bits.count, bits[index] { value |= 1 }
                index += 1
            }
            output.append(value)
        }
        return output
    }
}

enum ReedSolomon {
    private static let exp: [UInt8] = {
        var table = [UInt8](repeating: 0, count: 512)
        var value: UInt8 = 1
        for i in 0..<255 {
            table[i] = value
            let shifted = UInt16(value) << 1
            value = UInt8((shifted ^ ((shifted & 0x100) != 0 ? 0x11d : 0)) & 0xff)
        }
        for i in 255..<512 { table[i] = table[i - 255] }
        return table
    }()

    private static let log: [Int] = {
        var table = [Int](repeating: 0, count: 256)
        for i in 0..<255 {
            table[Int(exp[i])] = i
        }
        return table
    }()

    private static func mul(_ a: UInt8, _ b: UInt8) -> UInt8 {
        if a == 0 || b == 0 { return 0 }
        return exp[Int(log[Int(a)]) + Int(log[Int(b)])]
    }

    static func encode(_ data: [UInt8], eccCount: Int) -> [UInt8] {
        var generator = [UInt8](repeating: 0, count: eccCount + 1)
        generator[0] = 1
        for i in 0..<eccCount {
            var next = [UInt8](repeating: 0, count: eccCount + 1)
            for j in 0...i {
                next[j] ^= generator[j]
                next[j + 1] ^= mul(generator[j], exp[i])
            }
            generator = next
        }
        var ecc = [UInt8](repeating: 0, count: eccCount)
        for byte in data {
            let factor = byte ^ ecc[0]
            ecc.removeFirst()
            ecc.append(0)
            if factor != 0 {
                for j in 0..<eccCount {
                    ecc[j] ^= mul(generator[j + 1], factor)
                }
            }
        }
        return ecc
    }

    static func decode(_ received: [UInt8], dataCount: Int, eccCount: Int) -> [UInt8]? {
        let n = received.count
        var syndromes = [UInt8](repeating: 0, count: eccCount)
        var hasError = false
        for i in 0..<eccCount {
            var sum: UInt8 = 0
            for byte in received {
                sum = mul(sum, exp[i]) ^ byte
            }
            syndromes[i] = sum
            if sum != 0 { hasError = true }
        }
        if !hasError {
            return Array(received.prefix(dataCount))
        }
        var sigma = [UInt8](repeating: 0, count: eccCount + 1)
        var last = [UInt8](repeating: 0, count: eccCount + 1)
        sigma[0] = 1
        last[0] = 1
        var shift = 1
        for r in 0..<eccCount {
            var delta: UInt8 = syndromes[r]
            for j in 1..<sigma.count where r >= j {
                delta ^= mul(sigma[j], syndromes[r - j])
            }
            last.insert(0, at: 0)
            if last.count > eccCount + 1 { last.removeLast() }
            if delta != 0 {
                if last.count < sigma.count || (degree(last) <= degree(sigma) && shift * 2 > r + 1) {
                    let t = sigma
                    let scale = mul(delta, inv(last.first(where: { $0 != 0 }) ?? 1))
                    var scaled = last.map { mul($0, scale) }
                    while scaled.count < sigma.count { scaled.append(0) }
                    for i in 0..<sigma.count {
                        sigma[i] ^= scaled[i]
                    }
                    last = t
                    shift = 1
                } else {
                    let scale = mul(delta, inv(last.first(where: { $0 != 0 }) ?? 1))
                    for i in 0..<min(sigma.count, last.count) {
                        sigma[i] ^= mul(last[i], scale)
                    }
                    shift += 1
                }
            } else {
                shift += 1
            }
        }
        var locations: [Int] = []
        for i in 0..<n {
            var sum: UInt8 = 0
            var x: UInt8 = 1
            let xi = exp[255 - i]
            for coeff in sigma {
                sum ^= mul(coeff, x)
                x = mul(x, xi)
            }
            if sum == 0 { locations.append(n - 1 - i) }
        }
        if locations.isEmpty { return Array(received.prefix(dataCount)) }
        var omega = [UInt8](repeating: 0, count: eccCount)
        for i in 0..<eccCount {
            var sum: UInt8 = 0
            for j in 0...i {
                sum ^= mul(sigma[j], syndromes[i - j])
            }
            omega[i] = sum
        }
        var corrected = received
        for location in locations where location >= 0 && location < corrected.count {
            let xiInv = exp[location % 255]
            var denom: UInt8 = 1
            for other in locations where other != location {
                denom = mul(denom, UInt8((Int(xiInv) ^ Int(exp[other % 255])) & 0xff))
            }
            var num: UInt8 = 0
            var x: UInt8 = 1
            for coeff in omega {
                num ^= mul(coeff, x)
                x = mul(x, xiInv)
            }
            if denom == 0 { continue }
            corrected[location] ^= mul(num, inv(denom))
        }
        return Array(corrected.prefix(dataCount))
    }

    private static func degree(_ poly: [UInt8]) -> Int {
        for i in stride(from: poly.count - 1, through: 0, by: -1) {
            if poly[i] != 0 { return i }
        }
        return 0
    }

    private static func inv(_ value: UInt8) -> UInt8 {
        guard value != 0 else { return 0 }
        return exp[255 - log[Int(value)]]
    }
}

enum Code128 {
    static let patterns: [String] = [
        "11011001100", "11001101100", "11001100110", "10010011000", "10010001100",
        "10001001100", "10011001000", "10011000100", "10001100100", "11001001000",
        "11001000100", "11000100100", "10110011100", "10011011100", "10011001110",
        "10111001100", "10011101100", "10011100110", "11001110010", "11001011100",
        "11001001110", "11011100100", "11001110100", "11101101110", "11101001100",
        "11100101100", "11100100110", "11101100100", "11100110100", "11100110010",
        "11011011000", "11011000110", "11000110110", "10100011000", "10001011000",
        "10001000110", "10110001000", "10001101000", "10001100010", "11010001000",
        "11000101000", "11000100010", "10110111000", "10110001110", "10001101110",
        "10111011000", "10111000110", "10001110110", "11101110110", "11010001110",
        "11000101110", "11011101000", "11011100010", "11011101110", "11101011000",
        "11101000110", "11100010110", "11101101000", "11101100010", "11100011010",
        "11101111010", "11001000010", "11110001010", "10100110000", "10100001100",
        "10010110000", "10010000110", "10000101100", "10000100110", "10110010000",
        "10110000100", "10011010000", "10011000010", "10000110100", "10000110010",
        "11000010010", "11001010000", "11110111010", "11000010100", "10001111010",
        "10100111100", "10010111100", "10010011110", "10111100100", "10011110100",
        "10011110010", "11110100100", "11110010100", "11110010010", "11011011110",
        "11011110110", "11110110110", "10101111000", "10100011110", "10001011110",
        "10111101000", "10111100010", "11110101000", "11110100010", "10111011110",
        "10111101110", "11101011110", "11110101110", "11010000100", "11010010000",
        "11010011100", "1100011101011"
    ]

    struct Encoded {
        var modules: [Bool]
        func raster(moduleWidth: Int, barHeight: Int, quiet: Int) -> VisionRaster {
            let scale = max(1, moduleWidth)
            let height = max(8, barHeight)
            let pad = max(0, quiet)
            let width = modules.count * scale + pad * 2
            var image = VisionRaster(width: width, height: height, filled: (255, 255, 255, 255))
            for (index, bit) in modules.enumerated() where bit {
                let x0 = pad + index * scale
                for y in 0..<height {
                    for dx in 0..<scale {
                        image[x0 + dx, y] = (0, 0, 0, 255)
                    }
                }
            }
            return image
        }
    }

    static func encode(_ payload: String) throws -> Encoded {
        var values = [104]
        for scalar in payload.unicodeScalars {
            let value = Int(scalar.value)
            guard value >= 32, value <= 126 else {
                throw vnMakeError(.invalidArgument, description: "Code128B payload")
            }
            values.append(value - 32)
        }
        var checksum = values[0]
        for (index, value) in values.dropFirst().enumerated() {
            checksum += value * (index + 1)
        }
        values.append(checksum % 103)
        values.append(106)
        var modules: [Bool] = []
        for value in values {
            for character in patterns[value] {
                modules.append(character == "1")
            }
        }
        return Encoded(modules: modules)
    }

    static func decode(_ raster: VisionRaster) -> (String, CGRect)? {
        let y = raster.height / 2
        var runColors: [UInt8] = []
        var runLengths: [Int] = []
        var last: UInt8 = raster.grayAt(0, y) < 128 ? 1 : 0
        var length = 0
        for x in 0..<raster.width {
            let color: UInt8 = raster.grayAt(x, y) < 128 ? 1 : 0
            if color == last {
                length += 1
            } else {
                runColors.append(last)
                runLengths.append(length)
                last = color
                length = 1
            }
        }
        runColors.append(last)
        runLengths.append(length)
        guard let start = runColors.firstIndex(of: 1) else { return nil }
        let unit = max(1, runLengths.dropFirst(start).prefix(6).reduce(0, +) / 11)
        var modules: [Bool] = []
        for (color, len) in zip(runColors, runLengths) {
            let count = max(1, Int((Double(len) / Double(unit)).rounded()))
            modules.append(contentsOf: repeatElement(color == 1, count: count))
        }
        var values: [Int] = []
        var index = modules.firstIndex(of: true) ?? 0
        while index + 11 <= modules.count {
            let slice = modules[index..<(index + 11)]
            let pattern = slice.map { $0 ? "1" : "0" }.joined()
            if let value = patterns.firstIndex(of: pattern) {
                values.append(value)
                index += (value == 106 ? 13 : 11)
                if value == 106 { break }
            } else if index + 13 <= modules.count {
                let stop = modules[index..<(index + 13)].map { $0 ? "1" : "0" }.joined()
                if stop == patterns[106] {
                    values.append(106)
                    break
                }
                index += 1
            } else {
                break
            }
        }
        guard values.count >= 3, values.first == 104, values.last == 106 else { return nil }
        let body = Array(values.dropFirst().dropLast())
        guard let checksum = body.last else { return nil }
        let data = Array(body.dropLast())
        var expected = 104
        for (offset, value) in data.enumerated() {
            expected += value * (offset + 1)
        }
        guard expected % 103 == checksum else { return nil }
        let payload = String(data.map { Character(UnicodeScalar($0 + 32)!) })
        let minX = Double(modules.firstIndex(of: true) ?? 0) * Double(unit)
        let maxX = Double(raster.width)
        let box = visionNormalizedBox(
            minX: minX,
            minY: 0,
            maxX: maxX,
            maxY: Double(raster.height),
            width: raster.width,
            height: raster.height
        )
        return (payload, box)
    }
}

enum EAN13 {
    static let leftL = [
        "0001101", "0011001", "0010011", "0111101", "0100011",
        "0110001", "0101111", "0111011", "0110111", "0001011"
    ]
    static let leftG = [
        "0100111", "0110011", "0011011", "0100001", "0011101",
        "0111001", "0000101", "0010001", "0001001", "0010111"
    ]
    static let rightR = [
        "1110010", "1100110", "1101100", "1000010", "1011100",
        "1001110", "1010000", "1000100", "1001000", "1110100"
    ]
    static let parity = [
        "LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
        "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"
    ]

    struct Encoded {
        var modules: [Bool]
        func raster(moduleWidth: Int, barHeight: Int, quiet: Int) -> VisionRaster {
            Code128.Encoded(modules: modules).raster(
                moduleWidth: moduleWidth,
                barHeight: barHeight,
                quiet: quiet
            )
        }
    }

    static func encode(_ payload: String) throws -> Encoded {
        let digits = payload.compactMap { $0.wholeNumberValue }
        guard digits.count == 12 || digits.count == 13 else {
            throw vnMakeError(.invalidArgument, description: "EAN-13 needs 12 or 13 digits")
        }
        var body = Array(digits.prefix(12))
        let checksum = checksumDigit(body)
        if digits.count == 13, digits[12] != checksum {
            throw vnMakeError(.invalidArgument, description: "EAN-13 checksum")
        }
        body.append(checksum)
        var modules: [Bool] = [1, 0, 1].map { $0 == 1 }
        let pattern = parity[body[0]]
        for (index, digit) in body[1...6].enumerated() {
            let encoding = pattern[pattern.index(pattern.startIndex, offsetBy: index)]
            let bits = encoding == "L" ? leftL[digit] : leftG[digit]
            modules.append(contentsOf: bits.map { $0 == "1" })
        }
        modules.append(contentsOf: [0, 1, 0, 1, 0].map { $0 == 1 })
        for digit in body[7...12] {
            modules.append(contentsOf: rightR[digit].map { $0 == "1" })
        }
        modules.append(contentsOf: [1, 0, 1].map { $0 == 1 })
        return Encoded(modules: modules)
    }

    static func checksumDigit(_ digits: [Int]) -> Int {
        var sum = 0
        for (index, digit) in digits.enumerated() {
            sum += digit * ((index % 2 == 0) ? 1 : 3)
        }
        return (10 - (sum % 10)) % 10
    }

    static func decode(_ raster: VisionRaster) -> (String, CGRect)? {
        decodeBits(raster)
    }

    static func decodeBits(_ raster: VisionRaster) -> (String, CGRect)? {
        let y = raster.height / 2
        var bits: [Bool] = []
        var last = raster.grayAt(0, y) < 128
        var length = 0
        var runs: [(Bool, Int)] = []
        for x in 0..<raster.width {
            let black = raster.grayAt(x, y) < 128
            if black == last {
                length += 1
            } else {
                runs.append((last, length))
                last = black
                length = 1
            }
        }
        runs.append((last, length))
        guard let start = runs.firstIndex(where: { $0.0 }) else { return nil }
        let unit = max(1.0, Double(runs[start].1))
        for (black, len) in runs {
            let count = max(1, Int((Double(len) / unit).rounded()))
            bits.append(contentsOf: repeatElement(black, count: count))
        }
        guard let first = bits.firstIndex(of: true) else { return nil }
        let slice = Array(bits[first...])
        guard slice.count >= 95 else { return nil }
        let modules = Array(slice.prefix(95))
        guard modules[0], !modules[1], modules[2] else { return nil }
        var digits = [Int](repeating: 0, count: 13)
        var leftPattern = ""
        for i in 0..<6 {
            let startIndex = 3 + i * 7
            let pattern = String(modules[startIndex..<(startIndex + 7)].map { $0 ? "1" : "0" })
            if let digit = leftL.firstIndex(of: pattern) {
                digits[i + 1] = digit
                leftPattern.append("L")
            } else if let digit = leftG.firstIndex(of: pattern) {
                digits[i + 1] = digit
                leftPattern.append("G")
            } else {
                return nil
            }
        }
        guard let firstDigit = parity.firstIndex(of: leftPattern) else { return nil }
        digits[0] = firstDigit
        for i in 0..<6 {
            let startIndex = 50 + i * 7
            let pattern = String(modules[startIndex..<(startIndex + 7)].map { $0 ? "1" : "0" })
            guard let digit = rightR.firstIndex(of: pattern) else { return nil }
            digits[7 + i] = digit
        }
        let body = Array(digits.prefix(12))
        guard EAN13.checksumDigit(body) == digits[12] else { return nil }
        let payload = digits.map(String.init).joined()
        let box = visionNormalizedBox(
            minX: Double(first),
            minY: 0,
            maxX: Double(first + 95 * Int(unit)),
            maxY: Double(raster.height),
            width: raster.width,
            height: raster.height
        )
        return (payload, box)
    }
}

func visionDetectBarcodes(
    in raster: VisionRaster,
    symbologies: [VNBarcodeSymbology]
) -> [VNBarcodeObservation] {
    var observations: [VNBarcodeObservation] = []
    let wanted = Set(symbologies.map(\.rawValue))
    let wantsQR = wanted.contains(VNBarcodeSymbology.qr.rawValue) || symbologies.isEmpty
    let wants128 = wanted.contains(VNBarcodeSymbology.code128.rawValue) || symbologies.isEmpty
    let wantsEAN = wanted.contains(VNBarcodeSymbology.ean13.rawValue) || symbologies.isEmpty
    if wantsQR, let (payload, box) = QRCode.decode(raster) {
        observations.append(barcodeObservation(payload: payload, symbology: .qr, box: box))
    }
    if wants128, let (payload, box) = Code128.decode(raster) {
        observations.append(barcodeObservation(payload: payload, symbology: .code128, box: box))
    }
    if wantsEAN, let (payload, box) = EAN13.decodeBits(raster) {
        observations.append(barcodeObservation(payload: payload, symbology: .ean13, box: box))
    }
    return observations
}

private func barcodeObservation(
    payload: String,
    symbology: VNBarcodeSymbology,
    box: CGRect
) -> VNBarcodeObservation {
    VNBarcodeObservation(
        requestRevision: VNDetectBarcodesRequestRevision4,
        topLeft: CGPoint(x: box.minX, y: box.maxY),
        topRight: CGPoint(x: box.maxX, y: box.maxY),
        bottomRight: CGPoint(x: box.maxX, y: box.minY),
        bottomLeft: CGPoint(x: box.minX, y: box.minY),
        symbology: symbology,
        payloadStringValue: payload,
        payloadData: Data(payload.utf8)
    )
}
