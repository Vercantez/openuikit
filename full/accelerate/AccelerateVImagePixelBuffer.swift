import Foundation

extension vImage.PixelBuffer {
    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Format.ComponentType>) throws -> R) rethrows -> R {
        try storage.withUnsafeBufferPointer(body)
    }

    public func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Format.ComponentType>) throws -> R) rethrows -> R {
        var values = storage
        var result: R?
        try values.withUnsafeMutableBufferPointer { buf in
            result = try body(&buf)
        }
        _storageBox.values = values
        return result!
    }

    public func withUnsafeVImageBuffer<R>(_ body: (vImage_Buffer) throws -> R) rethrows -> R {
        var values = storage
        return try values.withUnsafeMutableBufferPointer { buf in
            let image = vImage_Buffer(
                data: UnsafeMutableRawPointer(buf.baseAddress),
                height: vImagePixelCount(height),
                width: vImagePixelCount(width),
                rowBytes: bytesPerRow
            )
            return try body(image)
        }
    }

    public func withUnsafePointerToVImageBuffer<R>(_ body: (UnsafePointer<vImage_Buffer>) throws -> R) rethrows -> R {
        try withUnsafeVImageBuffer { buffer in
            var copy = buffer
            return try withUnsafePointer(to: &copy, body)
        }
    }

    public func copy(to destinationBuffer: vImage.PixelBuffer<Format>) {
        destinationBuffer._storageBox.values = storage
    }

    public func scale(destination: vImage.PixelBuffer<Format>) {
        let srcW = max(width, 1)
        let srcH = max(height, 1)
        let destW = destination.width
        let destH = destination.height
        var out = destination.storage
        if out.count < destW * destH {
            if let sample = storage.first {
                out = Array(repeating: sample, count: destW * destH)
            }
        }
        if destW > 0, destH > 0, !storage.isEmpty {
            for y in 0..<destH {
                let sy = min(srcH - 1, y * srcH / destH)
                for x in 0..<destW {
                    let sx = min(srcW - 1, x * srcW / destW)
                    out[y * destination.rowStride + x] = storage[sy * rowStride + sx]
                }
            }
        }
        destination._storageBox.values = out
    }

    public func scale(useFloat16Accumulator: Bool, destination: vImage.PixelBuffer<Format>) {
        _ = useFloat16Accumulator
        scale(destination: destination)
    }

    public func clip(to bounds: ClosedRange<Format.ComponentType>, destination: vImage.PixelBuffer<Format>)
    where Format.ComponentType: Comparable {
        destination._storageBox.values = storage.map { min(max($0, bounds.lowerBound), bounds.upperBound) }
    }

    public func linearInterpolate(
        bufferB: vImage.PixelBuffer<Format>,
        interpolationConstant: Format.ComponentType,
        destination: vImage.PixelBuffer<Format>
    ) where Format.ComponentType: BinaryFloatingPoint {
        let t = interpolationConstant
        let n = min(storage.count, bufferB.storage.count)
        var out = destination.storage
        if out.count < n { out = Array(repeating: .zero, count: n) }
        for i in 0..<n {
            out[i] = storage[i] * (1 - t) + bufferB.storage[i] * t
        }
        destination._storageBox.values = out
    }

    public func reflect(over axis: vImage.ReflectionAxis, destination: vImage.PixelBuffer<Format>) {
        var out = destination.storage
        let count = width * height
        if out.count < count, let sample = storage.first {
            out = Array(repeating: sample, count: count)
        }
        for y in 0..<height {
            for x in 0..<width {
                let dx: Int
                let dy: Int
                switch axis {
                case .horizontal:
                    dx = width - 1 - x
                    dy = y
                case .vertical:
                    dx = x
                    dy = height - 1 - y
                }
                out[dy * destination.rowStride + dx] = storage[y * rowStride + x]
            }
        }
        destination._storageBox.values = out
    }

    public func rotate(
        _ rotation: vImage.Rotation,
        backgroundColor: Format.ComponentType? = nil,
        destination: vImage.PixelBuffer<Format>
    ) {
        let fill = backgroundColor ?? storage.first
        var out = destination.storage
        let count = destination.width * destination.height
        if out.count < count, let fill {
            out = Array(repeating: fill, count: count)
        }
        for y in 0..<height {
            for x in 0..<width {
                let (dx, dy) = _rotatedPoint(x: x, y: y, width: width, height: height, rotation: rotation)
                if dy >= 0, dy < destination.height, dx >= 0, dx < destination.width {
                    out[dy * destination.rowStride + dx] = storage[y * rowStride + x]
                }
            }
        }
        destination._storageBox.values = out
    }

    public func rotate(
        _ rotation: vImage.Rotation,
        backgroundColor: Format.ComponentType? = nil,
        useFloat16Accumulator: Bool,
        destination: vImage.PixelBuffer<Format>
    ) {
        _ = useFloat16Accumulator
        rotate(rotation, backgroundColor: backgroundColor, destination: destination)
    }

    public func boxConvolve(kernelSize: vImage.Size, edgeMode: vImage.EdgeMode<Format.ComponentType>, destination: vImage.PixelBuffer<Format>)
    where Format.ComponentType: BinaryInteger {
        _ = edgeMode
        let kw = kernelSize.width % 2 == 0 ? kernelSize.width + 1 : max(kernelSize.width, 1)
        let kh = kernelSize.height % 2 == 0 ? kernelSize.height + 1 : max(kernelSize.height, 1)
        let rx = kw / 2
        let ry = kh / 2
        var out = destination.storage
        func sample(_ x: Int, _ y: Int) -> Int {
            let xx = min(max(x, 0), width - 1)
            let yy = min(max(y, 0), height - 1)
            return Int(storage[yy * rowStride + xx])
        }
        for y in 0..<height {
            for x in 0..<width {
                var sum = 0
                for ky in -ry...ry {
                    for kx in -rx...rx {
                        sum += sample(x + kx, y + ky)
                    }
                }
                out[y * destination.rowStride + x] = Format.ComponentType((sum + (kw * kh) / 2) / (kw * kh))
            }
        }
        destination._storageBox.values = out
    }

    public func tentConvolve(kernelSize: vImage.Size, edgeMode: vImage.EdgeMode<Format.ComponentType>, destination: vImage.PixelBuffer<Format>)
    where Format.ComponentType: BinaryInteger {
        boxConvolve(kernelSize: kernelSize, edgeMode: edgeMode, destination: destination)
    }

    public func boxConvolved(kernelSize: vImage.Size, edgeMode: vImage.EdgeMode<Format.ComponentType>) -> vImage.PixelBuffer<Format>
    where Format.ComponentType: BinaryInteger & AdditiveArithmetic {
        let dest = vImage.PixelBuffer<Format>(size: size)
        boxConvolve(kernelSize: kernelSize, edgeMode: edgeMode, destination: dest)
        return dest
    }

    public func tentConvolved(kernelSize: vImage.Size, edgeMode: vImage.EdgeMode<Format.ComponentType>) -> vImage.PixelBuffer<Format>
    where Format.ComponentType: BinaryInteger & AdditiveArithmetic {
        boxConvolved(kernelSize: kernelSize, edgeMode: edgeMode)
    }

    public func contrastStretch(destination: vImage.PixelBuffer<Format>) where Format.ComponentType: BinaryInteger {
        guard let minValue = storage.min(), let maxValue = storage.max(), maxValue > minValue else {
            destination._storageBox.values = storage
            return
        }
        let span = Int(maxValue) - Int(minValue)
        destination._storageBox.values = storage.map { value in
            Format.ComponentType((Int(value) - Int(minValue)) * 255 / max(span, 1))
        }
    }

    public func contrastStretch(binCount: Int, destination: vImage.PixelBuffer<Format>) where Format.ComponentType: BinaryInteger {
        _ = binCount
        contrastStretch(destination: destination)
    }

    public func equalizeHistogram(destination: vImage.PixelBuffer<Format>) where Format.ComponentType == UInt8 {
        var hist = [Int](repeating: 0, count: 256)
        for value in storage { hist[Int(value)] += 1 }
        var cdf = [Int](repeating: 0, count: 256)
        var running = 0
        for i in 0..<256 {
            running += hist[i]
            cdf[i] = running
        }
        let total = max(storage.count, 1)
        let cdfMin = cdf.first(where: { $0 > 0 }) ?? 0
        destination._storageBox.values = storage.map { value in
            let c = cdf[Int(value)]
            return UInt8((c - cdfMin) * 255 / max(total - cdfMin, 1))
        }
    }

    public func equalizeHistogram(binCount: Int, destination: vImage.PixelBuffer<Format>) where Format.ComponentType == UInt8 {
        _ = binCount
        equalizeHistogram(destination: destination)
    }

    public func histogram() -> [vImagePixelCount] where Format.ComponentType == UInt8 {
        var hist = [vImagePixelCount](repeating: 0, count: 256)
        for value in storage { hist[Int(value)] += 1 }
        return hist
    }

    public func histogram(binCount: Int) -> [vImagePixelCount] where Format.ComponentType: BinaryInteger {
        let bins = max(binCount, 1)
        var hist = [vImagePixelCount](repeating: 0, count: bins)
        for value in storage {
            let idx = min(max(Int(value), 0), bins - 1)
            hist[idx] += 1
        }
        return hist
    }

    public func convert(to destination: vImage.PixelBuffer<vImage.PlanarF>) where Format.ComponentType == UInt8 {
        destination._storageBox.values = storage.map { Float($0) / 255 }
    }

    public func convert(to destination: vImage.PixelBuffer<vImage.Planar8>) where Format.ComponentType == Float {
        destination._storageBox.values = storage.map { value in
            UInt8(max(0, min(255, Int((value * 255).rounded()))))
        }
    }

    public func applyLookup(
        table: [Format.ComponentType],
        destination: vImage.PixelBuffer<Format>
    ) where Format.ComponentType == UInt8 {
        destination._storageBox.values = storage.map { value in
            let idx = Int(value)
            return idx < table.count ? table[idx] : value
        }
    }

    public func colorThreshold(_ threshold: Format.ComponentType, destination: vImage.PixelBuffer<Format>)
    where Format.ComponentType: Comparable & AdditiveArithmetic {
        destination._storageBox.values = storage.map { $0 >= threshold ? $0 : .zero }
    }

    public func premultiply(channelOrdering: vImage.ChannelOrdering) where Format.ComponentType == UInt8 {
        _ = channelOrdering
        var values = storage
        let channels = max(Format.channelCount, 1)
        if channels == 4 {
            for i in stride(from: 0, to: values.count, by: 4) {
                let a = Int(values[i])
                values[i + 1] = UInt8(Int(values[i + 1]) * a / 255)
                values[i + 2] = UInt8(Int(values[i + 2]) * a / 255)
                values[i + 3] = UInt8(Int(values[i + 3]) * a / 255)
            }
        }
        _storageBox.values = values
    }

    public func unpremultiply(channelOrdering: vImage.ChannelOrdering) where Format.ComponentType == UInt8 {
        _ = channelOrdering
        var values = storage
        let channels = max(Format.channelCount, 1)
        if channels == 4 {
            for i in stride(from: 0, to: values.count, by: 4) {
                let a = Int(values[i])
                if a != 0 {
                    values[i + 1] = UInt8(min(255, Int(values[i + 1]) * 255 / a))
                    values[i + 2] = UInt8(min(255, Int(values[i + 2]) * 255 / a))
                    values[i + 3] = UInt8(min(255, Int(values[i + 3]) * 255 / a))
                }
            }
        }
        _storageBox.values = values
    }

    public func applyLookup(_ lookupTable: [Format.ComponentType], destination: vImage.PixelBuffer<Format>)
    where Format.ComponentType == UInt8 {
        applyLookup(table: lookupTable, destination: destination)
    }

    public func applyLookup(_ lookupTable: [Pixel_F], destination: vImage.PixelBuffer<vImage.PlanarF>)
    where Format.ComponentType == UInt8 {
        destination._storageBox.values = storage.map { value in
            let idx = Int(value)
            return idx < lookupTable.count ? lookupTable[idx] : Float(value) / 255
        }
    }

    public func applyLookup(_ lookupTable: [Pixel_F], destination: vImage.PixelBuffer<vImage.PlanarF>)
    where Format.ComponentType == Float {
        destination._storageBox.values = storage.map { value in
            let idx = min(max(Int(value * 255), 0), max(lookupTable.count - 1, 0))
            return idx < lookupTable.count ? lookupTable[idx] : value
        }
    }

    public func applyLookup(_ lookupTable: [Pixel_8], destination: vImage.PixelBuffer<vImage.Planar8>)
    where Format.ComponentType == Float {
        destination._storageBox.values = storage.map { value in
            let idx = min(max(Int(value * 255), 0), max(lookupTable.count - 1, 0))
            return idx < lookupTable.count ? lookupTable[idx] : UInt8(max(0, min(255, Int(value * 255))))
        }
    }

    public func applyLookup(_ lookupTable: [Pixel_16U], destination: vImage.PixelBuffer<vImage.Planar16U>)
    where Format.ComponentType == UInt8 {
        destination._storageBox.values = storage.map { value in
            let idx = Int(value)
            return idx < lookupTable.count ? lookupTable[idx] : UInt16(value)
        }
    }

    public func applyLookup(_ lookupTable: [Pixel_16U], destination: vImage.PixelBuffer<vImage.Planar16U>)
    where Format.ComponentType == UInt16 {
        destination._storageBox.values = storage.map { value in
            let idx = min(Int(value), max(lookupTable.count - 1, 0))
            return idx < lookupTable.count ? lookupTable[idx] : value
        }
    }

    public func applyLookup(
        alphaTable: [Pixel_8]?,
        redTable: [Pixel_8]?,
        greenTable: [Pixel_8]?,
        blueTable: [Pixel_8]?,
        destination: vImage.PixelBuffer<vImage.Interleaved8x4>
    ) where Format.ComponentType == UInt8 {
        var out = destination.storage
        let n = min(storage.count / 4, out.count / 4)
        func mapChannel(_ value: UInt8, table: [Pixel_8]?) -> UInt8 {
            guard let table else { return value }
            let idx = Int(value)
            return idx < table.count ? table[idx] : value
        }
        for i in 0..<n {
            let base = i * 4
            out[base] = mapChannel(storage[base], table: alphaTable)
            out[base + 1] = mapChannel(storage[base + 1], table: redTable)
            out[base + 2] = mapChannel(storage[base + 2], table: greenTable)
            out[base + 3] = mapChannel(storage[base + 3], table: blueTable)
        }
        destination._storageBox.values = out
    }

    public func premultiply() where Format.ComponentType == Pixel_16F {
        var values = storage
        if Format.channelCount == 4 {
            for i in stride(from: 0, to: values.count, by: 4) {
                let a = Float16(bitPattern: values[i])
                values[i + 1] = (Float16(bitPattern: values[i + 1]) * a).bitPattern
                values[i + 2] = (Float16(bitPattern: values[i + 2]) * a).bitPattern
                values[i + 3] = (Float16(bitPattern: values[i + 3]) * a).bitPattern
            }
        }
        _storageBox.values = values
    }

    public func unpremultiply() where Format.ComponentType == Pixel_16F {
        var values = storage
        if Format.channelCount == 4 {
            for i in stride(from: 0, to: values.count, by: 4) {
                let a = Float16(bitPattern: values[i])
                if a != 0 {
                    values[i + 1] = (Float16(bitPattern: values[i + 1]) / a).bitPattern
                    values[i + 2] = (Float16(bitPattern: values[i + 2]) / a).bitPattern
                    values[i + 3] = (Float16(bitPattern: values[i + 3]) / a).bitPattern
                }
            }
        }
        _storageBox.values = values
    }

    public func premultiply(alpha: vImage.PixelBuffer<Format>) where Format.ComponentType == UInt8 {
        var values = storage
        let alphas = alpha.storage
        let n = min(values.count, alphas.count)
        for i in 0..<n {
            values[i] = UInt8(Int(values[i]) * Int(alphas[i]) / 255)
        }
        _storageBox.values = values
    }

    public func unpremultiply(alpha: vImage.PixelBuffer<Format>) where Format.ComponentType == UInt8 {
        var values = storage
        let alphas = alpha.storage
        let n = min(values.count, alphas.count)
        for i in 0..<n {
            let a = Int(alphas[i])
            if a != 0 {
                values[i] = UInt8(min(255, Int(values[i]) * 255 / a))
            }
        }
        _storageBox.values = values
    }

    public func premultiply(alpha: vImage.PixelBuffer<Format>) where Format.ComponentType == Float {
        var values = storage
        let alphas = alpha.storage
        let n = min(values.count, alphas.count)
        for i in 0..<n { values[i] *= alphas[i] }
        _storageBox.values = values
    }

    public func unpremultiply(alpha: vImage.PixelBuffer<Format>) where Format.ComponentType == Float {
        var values = storage
        let alphas = alpha.storage
        let n = min(values.count, alphas.count)
        for i in 0..<n where alphas[i] != 0 {
            values[i] /= alphas[i]
        }
        _storageBox.values = values
    }

    public func premultiply(channelOrdering: vImage.ChannelOrdering) where Format.ComponentType == Float {
        _ = channelOrdering
        var values = storage
        if Format.channelCount == 4 {
            for i in stride(from: 0, to: values.count, by: 4) {
                let a = values[i]
                values[i + 1] *= a
                values[i + 2] *= a
                values[i + 3] *= a
            }
        }
        _storageBox.values = values
    }

    public func unpremultiply(channelOrdering: vImage.ChannelOrdering) where Format.ComponentType == Float {
        _ = channelOrdering
        var values = storage
        if Format.channelCount == 4 {
            for i in stride(from: 0, to: values.count, by: 4) {
                let a = values[i]
                if a != 0 {
                    values[i + 1] /= a
                    values[i + 2] /= a
                    values[i + 3] /= a
                }
            }
        }
        _storageBox.values = values
    }

    public func premultiply(channelOrdering: vImage.ChannelOrdering) where Format.ComponentType == UInt16 {
        _ = channelOrdering
        var values = storage
        if Format.channelCount == 4 {
            for i in stride(from: 0, to: values.count, by: 4) {
                let a = Int(values[i])
                values[i + 1] = UInt16(Int(values[i + 1]) * a / 65535)
                values[i + 2] = UInt16(Int(values[i + 2]) * a / 65535)
                values[i + 3] = UInt16(Int(values[i + 3]) * a / 65535)
            }
        }
        _storageBox.values = values
    }

    public func unpremultiply(channelOrdering: vImage.ChannelOrdering) where Format.ComponentType == UInt16 {
        _ = channelOrdering
        var values = storage
        if Format.channelCount == 4 {
            for i in stride(from: 0, to: values.count, by: 4) {
                let a = Int(values[i])
                if a != 0 {
                    values[i + 1] = UInt16(min(65535, Int(values[i + 1]) * 65535 / a))
                    values[i + 2] = UInt16(min(65535, Int(values[i + 2]) * 65535 / a))
                    values[i + 3] = UInt16(min(65535, Int(values[i + 3]) * 65535 / a))
                }
            }
        }
        _storageBox.values = values
    }
}

private func _rotatedPoint(x: Int, y: Int, width: Int, height: Int, rotation: vImage.Rotation) -> (Int, Int) {
    switch rotation {
    case .clockwise0Degrees, .counterClockwise0Degrees:
        return (x, y)
    case .clockwise90Degrees, .counterClockwise270Degrees:
        return (height - 1 - y, x)
    case .clockwise180Degrees, .counterClockwise180Degrees:
        return (width - 1 - x, height - 1 - y)
    case .clockwise270Degrees, .counterClockwise90Degrees:
        return (y, width - 1 - x)
    case .angleInDegrees, .angleInRadians:
        return (x, y)
    }
}
