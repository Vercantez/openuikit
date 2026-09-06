import Foundation

func visionDetectRectangles(
    in raster: VisionRaster,
    request: VNDetectRectanglesRequest
) -> [VNRectangleObservation] {
    let gray = raster.grayscale()
    let width = raster.width
    let height = raster.height
    guard width > 2, height > 2 else { return [] }
    var magnitude = [Float](repeating: 0, count: width * height)
    var maxMag: Float = 1
    for y in 1..<(height - 1) {
        for x in 1..<(width - 1) {
            let gx = Float(gray[y * width + x + 1]) - Float(gray[y * width + x - 1])
            let gy = Float(gray[(y + 1) * width + x]) - Float(gray[(y - 1) * width + x])
            let mag = (gx * gx + gy * gy).squareRoot()
            magnitude[y * width + x] = mag
            if mag > maxMag { maxMag = mag }
        }
    }
    let threshold = max(12, maxMag * 0.25)
    var edges = [UInt8](repeating: 0, count: width * height)
    for i in 0..<magnitude.count {
        edges[i] = magnitude[i] >= threshold ? 1 : 0
    }
    let contours = traceContours(edges, width: width, height: height, maximum: 64)
    var observations: [VNRectangleObservation] = []
    let minSize = max(0.001, CGFloat(request.minimumSize))
    let minAspect = max(0.01, CGFloat(request.minimumAspectRatio))
    let maxAspect = max(minAspect, CGFloat(request.maximumAspectRatio))
    let tolerance = max(0, Double(request.quadratureTolerance))
    for contour in contours {
        let simplified = douglasPeucker(
            contour.map { SIMD2<Float>(Float($0.x), Float($0.y)) },
            epsilon: max(1.5, Double(min(width, height)) * 0.02)
        )
        guard simplified.count == 4 || simplified.count == 5 else { continue }
        let quad = Array(simplified.prefix(4))
        let points = quad.map { CGPoint(x: Double($0.x), y: Double($0.y)) }
        let anglesOK = quadratureOK(points, toleranceDegrees: tolerance)
        guard anglesOK else { continue }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let boxWidth = (xs.max() ?? 0) - (xs.min() ?? 0)
        let boxHeight = (ys.max() ?? 0) - (ys.min() ?? 0)
        let normW = boxWidth / Double(width)
        let normH = boxHeight / Double(height)
        let size = min(normW, normH)
        guard size + 1e-9 >= Double(minSize) else { continue }
        let aspect = boxHeight == 0 ? 0 : boxWidth / boxHeight
        let aspectRatio = aspect > 1 ? 1 / aspect : aspect
        guard aspectRatio + 1e-9 >= Double(minAspect), aspectRatio - 1e-9 <= Double(maxAspect) else {
            continue
        }
        var edgeStrength: Float = 0
        var samples = 0
        for point in points {
            let x = min(width - 1, max(0, Int(point.x.rounded())))
            let y = min(height - 1, max(0, Int(point.y.rounded())))
            edgeStrength += magnitude[y * width + x]
            samples += 1
        }
        let confidence = min(1, (edgeStrength / Float(max(samples, 1))) / maxMag)
        if confidence < request.minimumConfidence { continue }
        let ordered = orderQuad(points)
        observations.append(
            VNRectangleObservation(
                requestRevision: VNDetectRectanglesRequestRevision1,
                topLeft: visionNormalizedPoint(x: ordered[0].x, y: ordered[0].y, width: width, height: height),
                topRight: visionNormalizedPoint(x: ordered[1].x, y: ordered[1].y, width: width, height: height),
                bottomRight: visionNormalizedPoint(x: ordered[2].x, y: ordered[2].y, width: width, height: height),
                bottomLeft: visionNormalizedPoint(x: ordered[3].x, y: ordered[3].y, width: width, height: height),
                confidence: confidence
            )
        )
    }
    observations.sort { $0.confidence > $1.confidence }
    if request.maximumObservations > 0 {
        return Array(observations.prefix(request.maximumObservations))
    }
    return observations
}

func visionDetectContours(
    in raster: VisionRaster,
    request: VNDetectContoursRequest
) -> VNContoursObservation {
    var working = raster
    let maxDim = max(8, request.maximumImageDimension)
    if max(working.width, working.height) > maxDim {
        let scale = Double(maxDim) / Double(max(working.width, working.height))
        working = working.resized(
            width: max(1, Int(Double(working.width) * scale)),
            height: max(1, Int(Double(working.height) * scale))
        )
    }
    let gray = working.grayscale()
    let pivot = request.contrastPivot?.floatValue ?? 0.5
    let adjustment = max(0.1, request.contrastAdjustment)
    var binary = [UInt8](repeating: 0, count: gray.count)
    let threshold = UInt8(max(0, min(255, (Double(pivot) * 255).rounded())))
    for (index, value) in gray.enumerated() {
        let centered = (Double(value) - Double(threshold)) * Double(adjustment) + Double(threshold)
        let clamped = UInt8(max(0, min(255, centered.rounded())))
        let dark = clamped < threshold
        binary[index] = (request.detectsDarkOnLight ? dark : !dark) ? 1 : 0
    }
    let traces = traceContours(binary, width: working.width, height: working.height, maximum: 128)
    var contours: [VNContour] = []
    for (index, points) in traces.enumerated() {
        let normalized = points.map { point in
            SIMD2<Float>(
                Float(point.x / Double(max(working.width, 1))),
                Float(1 - point.y / Double(max(working.height, 1)))
            )
        }
        contours.append(
            VNContour(normalizedPoints: normalized, indexPath: IndexPath(index: index))
        )
    }
    return VNContoursObservation(topLevelContours: contours)
}

func visionFeaturePrint(in raster: VisionRaster) -> VNFeaturePrintObservation {
    let sample = raster.resized(width: 32, height: 32)
    var bins = [Float](repeating: 0, count: 512)
    let pixelCount = Float(max(1, sample.width * sample.height))
    for y in 0..<sample.height {
        for x in 0..<sample.width {
            let pixel = sample[x, y]
            let r = Int(pixel.0) >> 5
            let g = Int(pixel.1) >> 5
            let b = Int(pixel.2) >> 5
            bins[(r << 6) | (g << 3) | b] += 1
        }
    }
    for index in 0..<bins.count {
        bins[index] /= pixelCount
    }
    var data = Data(count: bins.count * MemoryLayout<Float>.size)
    data.withUnsafeMutableBytes { buffer in
        let pointer = buffer.bindMemory(to: Float.self)
        for (index, value) in bins.enumerated() {
            pointer[index] = value
        }
    }
    return VNFeaturePrintObservation(elementType: .float, data: data)
}

func visionTranslationalAlignment(
    source: VisionRaster,
    target: VisionRaster
) -> VNImageTranslationAlignmentObservation {
    let size = 64
    let a = source.resized(width: size, height: size).grayscale()
    let b = target.resized(width: size, height: size).grayscale()
    let fa = fft2D(a, width: size)
    let fb = fft2D(b, width: size)
    var cross = [Complex](repeating: .zero, count: size * size)
    for i in 0..<cross.count {
        let product = fa[i].conjugate * fb[i]
        let mag = max(1e-8, product.modulus)
        cross[i] = Complex(re: product.re / mag, im: product.im / mag)
    }
    let corr = inverseFFT2D(cross, width: size)
    var peak = 0
    var best = -Double.greatestFiniteMagnitude
    for i in 0..<corr.count {
        if corr[i].re > best {
            best = corr[i].re
            peak = i
        }
    }
    var dx = peak % size
    var dy = peak / size
    if dx > size / 2 { dx -= size }
    if dy > size / 2 { dy -= size }
    let scaleX = Double(source.width) / Double(size)
    let scaleY = Double(source.height) / Double(size)
    let transform = CGAffineTransform(
        translationX: CGFloat(Double(dx) * scaleX),
        y: CGFloat(Double(dy) * scaleY)
    )
    return VNImageTranslationAlignmentObservation(alignmentTransform: transform)
}

func visionTrackObject(
    in raster: VisionRaster,
    request: VNTrackingRequest
) -> VNDetectedObjectObservation {
    let box = request.inputObservation.boundingBox
    let imageRect = VNImageRectForNormalizedRect(box, raster.width, raster.height)
    let minX = max(0, Int(imageRect.minX.rounded(.down)))
    let maxX = min(raster.width, Int(imageRect.maxX.rounded(.up)))
    let minYTop = max(0, raster.height - Int(imageRect.maxY.rounded(.up)))
    let maxYTop = min(raster.height, raster.height - Int(imageRect.minY.rounded(.down)))
    let templateWidth = max(1, maxX - minX)
    let templateHeight = max(1, maxYTop - minYTop)
    var template = [UInt8](repeating: 0, count: templateWidth * templateHeight)
    if request.templateGray == nil {
        for y in 0..<templateHeight {
            for x in 0..<templateWidth {
                template[y * templateWidth + x] = raster.grayAt(minX + x, minYTop + y)
            }
        }
        request.templateGray = template
        request.templateSize = (templateWidth, templateHeight)
        return VNDetectedObjectObservation(
            requestRevision: VNTrackObjectRequestRevision2,
            boundingBox: box,
            confidence: request.inputObservation.confidence
        )
    }
    let stored = request.templateGray ?? template
    let size = request.templateSize
    let search = max(size.0, size.1)
    var best = (x: minX, y: minYTop, score: Double.greatestFiniteMagnitude)
    let x0 = max(0, minX - search)
    let y0 = max(0, minYTop - search)
    let x1 = min(raster.width - size.0, minX + search)
    let y1 = min(raster.height - size.1, minYTop + search)
    for y in stride(from: y0, through: max(y0, y1), by: 2) {
        for x in stride(from: x0, through: max(x0, x1), by: 2) {
            var sad = 0
            for ty in 0..<size.1 {
                for tx in 0..<size.0 {
                    sad += abs(Int(raster.grayAt(x + tx, y + ty)) - Int(stored[ty * size.0 + tx]))
                }
            }
            let score = Double(sad) / Double(max(1, size.0 * size.1))
            if score < best.score {
                best = (x, y, score)
            }
        }
    }
    let cx = Double(best.x) + Double(size.0) / 2
    let cy = Double(best.y) + Double(size.1) / 2
    let norm = visionNormalizedBox(
        minX: Double(best.x),
        minY: Double(best.y),
        maxX: Double(best.x + size.0),
        maxY: Double(best.y + size.1),
        width: raster.width,
        height: raster.height
    )
    _ = cx
    _ = cy
    let confidence = Float(max(0, min(1, 1 - best.score / 128)))
    return VNDetectedObjectObservation(
        requestRevision: VNTrackObjectRequestRevision2,
        boundingBox: norm,
        confidence: confidence
    )
}

private func traceContours(
    _ binary: [UInt8],
    width: Int,
    height: Int,
    maximum: Int
) -> [[CGPoint]] {
    var seen = [Bool](repeating: false, count: binary.count)
    var contours: [[CGPoint]] = []
    let neighbors = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
    for y in 1..<(height - 1) {
        for x in 1..<(width - 1) {
            let index = y * width + x
            if binary[index] == 0 || seen[index] { continue }
            if binary[index - 1] == 1 { continue }
            var contour: [CGPoint] = []
            var cx = x
            var cy = y
            var dir = 0
            repeat {
                contour.append(CGPoint(x: cx, y: cy))
                seen[cy * width + cx] = true
                var found = false
                for offset in 0..<8 {
                    let n = neighbors[(dir + offset) % 8]
                    let nx = cx + n.0
                    let ny = cy + n.1
                    if nx >= 0, ny >= 0, nx < width, ny < height, binary[ny * width + nx] == 1 {
                        cx = nx
                        cy = ny
                        dir = (dir + offset + 6) % 8
                        found = true
                        break
                    }
                }
                if !found { break }
                if contour.count > width * height { break }
            } while !(cx == x && cy == y) || contour.count < 4
            if contour.count >= 8 {
                contours.append(contour)
                if contours.count >= maximum { return contours }
            }
        }
    }
    return contours
}

private func quadratureOK(_ points: [CGPoint], toleranceDegrees: Double) -> Bool {
    guard points.count == 4 else { return false }
    for index in 0..<4 {
        let prev = points[(index + 3) % 4]
        let current = points[index]
        let next = points[(index + 1) % 4]
        let v1x = prev.x - current.x
        let v1y = prev.y - current.y
        let v2x = next.x - current.x
        let v2y = next.y - current.y
        let dot = v1x * v2x + v1y * v2y
        let n1 = hypot(v1x, v1y)
        let n2 = hypot(v2x, v2y)
        guard n1 > 1e-6, n2 > 1e-6 else { return false }
        let cosine = max(-1, min(1, dot / (n1 * n2)))
        let angle = acos(cosine) * 180 / Double.pi
        if abs(angle - 90) > toleranceDegrees { return false }
    }
    return true
}

private func orderQuad(_ points: [CGPoint]) -> [CGPoint] {
    let sorted = points.sorted { lhs, rhs in
        if lhs.y == rhs.y { return lhs.x < rhs.x }
        return lhs.y < rhs.y
    }
    let top = Array(sorted.prefix(2)).sorted { $0.x < $1.x }
    let bottom = Array(sorted.suffix(2)).sorted { $0.x < $1.x }
    return [top[0], top[1], bottom[1], bottom[0]]
}

private struct Complex {
    var re: Double
    var im: Double
    static let zero = Complex(re: 0, im: 0)
    var conjugate: Complex { Complex(re: re, im: -im) }
    var modulus: Double { hypot(re, im) }

    static func * (lhs: Complex, rhs: Complex) -> Complex {
        Complex(re: lhs.re * rhs.re - lhs.im * rhs.im, im: lhs.re * rhs.im + lhs.im * rhs.re)
    }
}

private func fft2D(_ gray: [UInt8], width: Int) -> [Complex] {
    var grid = gray.map { Complex(re: Double($0), im: 0) }
    for y in 0..<width {
        var row = Array(grid[(y * width)..<((y + 1) * width)])
        fft(&row)
        for x in 0..<width { grid[y * width + x] = row[x] }
    }
    for x in 0..<width {
        var col = (0..<width).map { grid[$0 * width + x] }
        fft(&col)
        for y in 0..<width { grid[y * width + x] = col[y] }
    }
    return grid
}

private func inverseFFT2D(_ values: [Complex], width: Int) -> [Complex] {
    var grid = values.map { $0.conjugate }
    for y in 0..<width {
        var row = Array(grid[(y * width)..<((y + 1) * width)])
        fft(&row)
        for x in 0..<width { grid[y * width + x] = row[x] }
    }
    for x in 0..<width {
        var col = (0..<width).map { grid[$0 * width + x] }
        fft(&col)
        for y in 0..<width { grid[y * width + x] = col[y] }
    }
    let scale = Double(width * width)
    return grid.map { Complex(re: $0.re / scale, im: -$0.im / scale) }
}

private func fft(_ values: inout [Complex]) {
    let n = values.count
    var j = 0
    for i in 1..<n {
        var bit = n >> 1
        while j & bit != 0 {
            j ^= bit
            bit >>= 1
        }
        j ^= bit
        if i < j { values.swapAt(i, j) }
    }
    var length = 2
    while length <= n {
        let angle = -2 * Double.pi / Double(length)
        let wlen = Complex(re: cos(angle), im: sin(angle))
        for i in stride(from: 0, to: n, by: length) {
            var w = Complex(re: 1, im: 0)
            for k in 0..<(length / 2) {
                let u = values[i + k]
                let v = values[i + k + length / 2] * w
                values[i + k] = Complex(re: u.re + v.re, im: u.im + v.im)
                values[i + k + length / 2] = Complex(re: u.re - v.re, im: u.im - v.im)
                w = w * wlen
            }
        }
        length <<= 1
    }
}

func douglasPeucker(_ points: [SIMD2<Float>], epsilon: Double) -> [SIMD2<Float>] {
    if points.count <= 2 {
        return points
    }
    let start = points.first!
    let end = points.last!
    var maxDistance: Double = 0
    var maxIndex = 0
    for index in 1..<(points.count - 1) {
        let distance = perpendicularDistance(points[index], start, end)
        if distance > maxDistance {
            maxDistance = distance
            maxIndex = index
        }
    }
    if maxDistance > epsilon {
        let left = douglasPeucker(Array(points[0...maxIndex]), epsilon: epsilon)
        let right = douglasPeucker(Array(points[maxIndex...]), epsilon: epsilon)
        return left.dropLast() + right
    }
    return [start, end]
}

private func perpendicularDistance(
    _ point: SIMD2<Float>,
    _ start: SIMD2<Float>,
    _ end: SIMD2<Float>
) -> Double {
    let dx = Double(end.x - start.x)
    let dy = Double(end.y - start.y)
    if dx == 0 && dy == 0 {
        let px = Double(point.x - start.x)
        let py = Double(point.y - start.y)
        return (px * px + py * py).squareRoot()
    }
    let numerator = abs(
        dy * Double(point.x) - dx * Double(point.y) + Double(end.x) * Double(start.y)
            - Double(end.y) * Double(start.x)
    )
    return numerator / (dx * dx + dy * dy).squareRoot()
}
