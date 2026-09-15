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

/// Classical Sobel + weighted PCA line fit. Not Apple's horizon model.
func visionDetectHorizon(in raster: VisionRaster) -> VNHorizonObservation {
    let gray = raster.grayscale()
    let width = raster.width
    let height = raster.height
    guard width > 2, height > 2 else {
        return VNHorizonObservation(angle: 0, confidence: 0)
    }
    var sumX = 0.0
    var sumY = 0.0
    var sumXX = 0.0
    var sumXY = 0.0
    var sumYY = 0.0
    var weightSum = 0.0
    for y in 1..<(height - 1) {
        for x in 1..<(width - 1) {
            let gx = Double(gray[y * width + x + 1]) - Double(gray[y * width + x - 1])
            let gy = Double(gray[(y + 1) * width + x]) - Double(gray[(y - 1) * width + x])
            let mag = (gx * gx + gy * gy).squareRoot()
            guard mag >= 16 else { continue }
            let px = Double(x)
            let py = Double(height - 1 - y)
            sumX += mag * px
            sumY += mag * py
            sumXX += mag * px * px
            sumXY += mag * px * py
            sumYY += mag * py * py
            weightSum += mag
        }
    }
    guard weightSum > 0 else {
        return VNHorizonObservation(angle: 0, confidence: 0)
    }
    let meanX = sumX / weightSum
    let meanY = sumY / weightSum
    let covXX = sumXX / weightSum - meanX * meanX
    let covXY = sumXY / weightSum - meanX * meanY
    let covYY = sumYY / weightSum - meanY * meanY
    let angle = 0.5 * Foundation.atan2(2 * covXY, covXX - covYY)
    let density = weightSum / Double(max(1, width * height))
    let confidence = Float(max(0.05, min(1, density / 8)))
    return VNHorizonObservation(angle: angle, confidence: confidence)
}

/// Laplacian-energy smudge score in 0...1. Not an Apple lens-smudge model.
func visionLensSmudgeConfidence(in raster: VisionRaster) -> Float {
    let gray = raster.grayscale()
    let width = raster.width
    let height = raster.height
    guard width > 2, height > 2 else { return 1 }
    var sumSq = 0.0
    var count = 0.0
    for y in 1..<(height - 1) {
        for x in 1..<(width - 1) {
            let index = y * width + x
            let lap = Double(gray[index - 1]) + Double(gray[index + 1])
                + Double(gray[index - width]) + Double(gray[index + width])
                - 4 * Double(gray[index])
            sumSq += lap * lap
            count += 1
        }
    }
    let rms = (sumSq / max(count, 1)).squareRoot()
    return Float(max(0, min(1, 1 - rms / 30)))
}

private func traceContours(
    _ binary: [UInt8],
    width: Int,
    height: Int,
    maximum: Int
) -> [[CGPoint]] {
    guard width > 0, height > 0, binary.count >= width * height else { return [] }
    // Clockwise in y-down image coordinates: E SE S SW W NW N NE.
    let neighbors = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
    // 8-connectivity component labelling: each foreground blob is traced exactly
    // once from its topmost-leftmost pixel, whose west neighbor is background or
    // out of bounds by scan-order construction.
    var labels = [Int](repeating: -1, count: width * height)
    var contours: [[CGPoint]] = []
    var blobTag = 0
    var stack: [Int] = []
    for seedY in 0..<height {
        for seedX in 0..<width {
            let seed = seedY * width + seedX
            if binary[seed] == 0 || labels[seed] != -1 { continue }
            stack.removeAll(keepingCapacity: true)
            stack.append(seed)
            labels[seed] = blobTag
            while let index = stack.popLast() {
                let x = index % width
                let y = index / width
                for offset in neighbors {
                    let nx = x + offset.0
                    let ny = y + offset.1
                    if nx < 0 || ny < 0 || nx >= width || ny >= height { continue }
                    let neighbor = ny * width + nx
                    if binary[neighbor] == 1 && labels[neighbor] == -1 {
                        labels[neighbor] = blobTag
                        stack.append(neighbor)
                    }
                }
            }
            blobTag += 1
            // Moore-neighbor boundary following with an explicit backtrack
            // direction: neighbors are examined clockwise from behind the entry
            // direction, and (pixel, backtrack) state tracking stops repeats
            // instead of lapping. The seed's initial backtrack is west.
            var contour = [CGPoint(x: seedX, y: seedY)]
            var cx = seedX
            var cy = seedY
            var backDir = 4
            var visited: Set<Int> = [(seedY * width + seedX) * 8 + backDir]
            let stepCap = width * height + 8
            var steps = 0
            var closed = false
            while steps < stepCap {
                steps += 1
                var moved = false
                for k in 0..<8 {
                    let nextDir = (backDir + 1 + k) % 8
                    let nx = cx + neighbors[nextDir].0
                    let ny = cy + neighbors[nextDir].1
                    if nx < 0 || ny < 0 || nx >= width || ny >= height { continue }
                    if binary[ny * width + nx] == 0 { continue }
                    let nextBackDir = (nextDir + 4) % 8
                    let state = (ny * width + nx) * 8 + nextBackDir
                    if visited.contains(state) {
                        closed = contour.count >= 8
                        break
                    }
                    visited.insert(state)
                    cx = nx
                    cy = ny
                    backDir = nextBackDir
                    contour.append(CGPoint(x: cx, y: cy))
                    moved = true
                    break
                }
                if !moved { break }
                if closed { break }
            }
            if closed {
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

/// Classical dark-on-light connected-component text-line detector with optional
/// per-component character boxes. This is a documented Linux-local heuristic,
/// not Apple's text detection model: it finds high-contrast blob rows, so it
/// reports geometric text regions but never recognizes characters.
func visionDetectTextRectangles(
    in raster: VisionRaster,
    request: VNDetectTextRectanglesRequest
) -> [VNTextObservation] {
    let width = raster.width
    let height = raster.height
    guard width >= 8, height >= 8 else { return [] }
    let gray = raster.grayscale()
    var darkCount = 0
    for value in gray {
        if value < 128 { darkCount += 1 }
    }
    let darkIsForeground = darkCount * 2 <= gray.count
    var foreground = [Bool](repeating: false, count: gray.count)
    for index in 0..<gray.count {
        foreground[index] = darkIsForeground ? gray[index] < 128 : gray[index] >= 128
    }
    var labels = [Int](repeating: -1, count: gray.count)
    var components: [(minX: Int, minY: Int, maxX: Int, maxY: Int, area: Int)] = []
    var stack: [Int] = []
    for seed in 0..<gray.count {
        if !foreground[seed] || labels[seed] != -1 { continue }
        if components.count >= 512 { break }
        let tag = components.count
        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1
        var area = 0
        stack.removeAll(keepingCapacity: true)
        stack.append(seed)
        labels[seed] = tag
        while let index = stack.popLast() {
            let x = index % width
            let y = index / width
            if x < minX { minX = x }
            if y < minY { minY = y }
            if x > maxX { maxX = x }
            if y > maxY { maxY = y }
            area += 1
            if x > 0 && foreground[index - 1] && labels[index - 1] == -1 {
                labels[index - 1] = tag
                stack.append(index - 1)
            }
            if x + 1 < width && foreground[index + 1] && labels[index + 1] == -1 {
                labels[index + 1] = tag
                stack.append(index + 1)
            }
            if y > 0 && foreground[index - width] && labels[index - width] == -1 {
                labels[index - width] = tag
                stack.append(index - width)
            }
            if y + 1 < height && foreground[index + width] && labels[index + width] == -1 {
                labels[index + width] = tag
                stack.append(index + width)
            }
        }
        components.append((minX, minY, maxX, maxY, area))
    }
    let minArea = max(8, (width * height) / 2000)
    var kept: [(minX: Int, minY: Int, maxX: Int, maxY: Int, area: Int)] = []
    for component in components {
        let boxWidth = component.maxX - component.minX + 1
        let boxHeight = component.maxY - component.minY + 1
        guard component.area >= minArea else { continue }
        guard boxWidth >= 3, boxHeight >= 2 else { continue }
        guard boxHeight <= height / 2 else { continue }
        guard Double(boxWidth) / Double(max(boxHeight, 1)) <= 64 else { continue }
        kept.append(component)
    }
    kept.sort { $0.minY < $1.minY }
    var lines: [[(minX: Int, minY: Int, maxX: Int, maxY: Int, area: Int)]] = []
    for component in kept {
        var placed = false
        for index in 0..<lines.count {
            let overlaps = lines[index].contains { member in
                component.minY <= member.maxY && member.minY <= component.maxY
            }
            if overlaps {
                lines[index].append(component)
                placed = true
                break
            }
        }
        if !placed {
            lines.append([component])
        }
    }
    var observations: [VNTextObservation] = []
    for line in lines.prefix(32) {
        let minX = line.map(\.minX).min() ?? 0
        let minY = line.map(\.minY).min() ?? 0
        let maxX = line.map(\.maxX).max() ?? 0
        let maxY = line.map(\.maxY).max() ?? 0
        let unionArea = max(1, (maxX - minX + 1) * (maxY - minY + 1))
        let fill = Double(line.reduce(0) { $0 + $1.area }) / Double(unionArea)
        let confidence = VNConfidence(min(1, 0.4 + 0.6 * fill))
        var characterBoxes: [VNRectangleObservation]? = nil
        if request.reportCharacterBoxes {
            characterBoxes = line.map { member in
                visionAxisQuad(
                    minX: member.minX,
                    minY: member.minY,
                    maxX: member.maxX,
                    maxY: member.maxY,
                    width: width,
                    height: height,
                    revision: VNDetectTextRectanglesRequest.currentRevision,
                    confidence: confidence
                )
            }
        }
        let quad = visionAxisQuad(
            minX: minX,
            minY: minY,
            maxX: maxX,
            maxY: maxY,
            width: width,
            height: height,
            revision: VNDetectTextRectanglesRequest.currentRevision,
            confidence: confidence
        )
        observations.append(
            VNTextObservation(
                requestRevision: VNDetectTextRectanglesRequest.currentRevision,
                topLeft: quad.topLeft,
                topRight: quad.topRight,
                bottomRight: quad.bottomRight,
                bottomLeft: quad.bottomLeft,
                characterBoxes: characterBoxes,
                confidence: confidence
            )
        )
    }
    return observations
}

private func visionAxisQuad(
    minX: Int,
    minY: Int,
    maxX: Int,
    maxY: Int,
    width: Int,
    height: Int,
    revision: Int,
    confidence: VNConfidence
) -> VNRectangleObservation {
    VNRectangleObservation(
        requestRevision: revision,
        topLeft: visionNormalizedPoint(x: Double(minX), y: Double(minY), width: width, height: height),
        topRight: visionNormalizedPoint(
            x: Double(maxX + 1),
            y: Double(minY),
            width: width,
            height: height
        ),
        bottomRight: visionNormalizedPoint(
            x: Double(maxX + 1),
            y: Double(maxY + 1),
            width: width,
            height: height
        ),
        bottomLeft: visionNormalizedPoint(
            x: Double(minX),
            y: Double(maxY + 1),
            width: width,
            height: height
        ),
        confidence: confidence
    )
}

/// Largest classical Sobel/quadrilateral fit as the document quad. This is a
/// documented Linux-local stand-in, not Apple's document segmentation model.
func visionDetectDocumentQuad(in raster: VisionRaster) -> VNRectangleObservation? {
    let probe = VNDetectRectanglesRequest()
    probe.minimumSize = 0.02
    probe.minimumAspectRatio = 0.05
    probe.maximumAspectRatio = 1.0
    probe.quadratureTolerance = 45
    probe.maximumObservations = 0
    let quads = visionDetectRectangles(in: raster, request: probe)
    return quads.max { lhs, rhs in
        lhs.boundingBox.width * lhs.boundingBox.height < rhs.boundingBox.width * rhs.boundingBox.height
    }
}

/// Classical center-surround contrast saliency map with a thresholded salient
/// box. One documented Linux-local heuristic stands in for both the attention
/// and objectness requests; it is not either Apple saliency model.
func visionSaliencyMap(in raster: VisionRaster) -> VNSaliencyImageObservation {
    let width = raster.width
    let height = raster.height
    guard width >= 2, height >= 2 else {
        return VNSaliencyImageObservation(
            pixelBuffer: CVPixelBuffer(width: max(width, 0), height: max(height, 0)),
            salientObjects: nil,
            confidence: 0
        )
    }
    let grid = 32
    let small = raster.resized(width: grid, height: grid).grayscale().map { Double($0) }
    var blur = [Double](repeating: 0, count: grid * grid)
    for y in 0..<grid {
        for x in 0..<grid {
            var sum = 0.0
            var count = 0.0
            for dy in -1...1 {
                for dx in -1...1 {
                    let nx = x + dx
                    let ny = y + dy
                    if nx >= 0 && ny >= 0 && nx < grid && ny < grid {
                        sum += small[ny * grid + nx]
                        count += 1
                    }
                }
            }
            blur[y * grid + x] = sum / max(count, 1)
        }
    }
    var contrast = [Double](repeating: 0, count: grid * grid)
    var maxContrast = 0.0
    for index in 0..<contrast.count {
        contrast[index] = abs(small[index] - blur[index])
        if contrast[index] > maxContrast { maxContrast = contrast[index] }
    }
    var heat = VisionRaster(width: width, height: height)
    if maxContrast > 0 {
        for y in 0..<height {
            for x in 0..<width {
                let gx = min(grid - 1, (x * grid) / width)
                let gy = min(grid - 1, (y * grid) / height)
                let scaled = (contrast[gy * grid + gx] / maxContrast * 255).rounded()
                let value = UInt8(max(0, min(255, Int(scaled))))
                heat[x, y] = (value, value, value, 255)
            }
        }
    }
    var objects: [VNRectangleObservation]? = nil
    var confidence: VNConfidence = 0
    if maxContrast > 1 {
        let threshold = maxContrast * 0.5
        var minX = grid
        var minY = grid
        var maxX = -1
        var maxY = -1
        for y in 0..<grid {
            for x in 0..<grid {
                if contrast[y * grid + x] >= threshold {
                    if x < minX { minX = x }
                    if y < minY { minY = y }
                    if x > maxX { maxX = x }
                    if y > maxY { maxY = y }
                }
            }
        }
        confidence = VNConfidence(min(1, maxContrast / 64))
        if maxX >= 0 {
            let left = Double(minX) / Double(grid)
            let right = Double(maxX + 1) / Double(grid)
            let top = Double(minY) / Double(grid)
            let bottom = Double(maxY + 1) / Double(grid)
            objects = [
                VNRectangleObservation(
                    requestRevision: VNGenerateAttentionBasedSaliencyImageRequest.currentRevision,
                    topLeft: CGPoint(x: left, y: 1 - top),
                    topRight: CGPoint(x: right, y: 1 - top),
                    bottomRight: CGPoint(x: right, y: 1 - bottom),
                    bottomLeft: CGPoint(x: left, y: 1 - bottom),
                    confidence: confidence
                )
            ]
        }
    }
    return VNSaliencyImageObservation(
        pixelBuffer: heat.makePixelBuffer(),
        salientObjects: objects,
        confidence: confidence
    )
}

/// Classical Laplacian-variance sharpness plus Hasler-Susstrunk colorfulness
/// mapped to an overall score. A documented Linux-local heuristic, not Apple's
/// aesthetics model: flat gray scores 0 and reports utility.
func visionAestheticsScores(in raster: VisionRaster) -> VNImageAestheticsScoresObservation {
    let width = raster.width
    let height = raster.height
    guard width >= 3, height >= 3 else {
        return VNImageAestheticsScoresObservation(overallScore: 0, isUtility: true, confidence: 0.5)
    }
    let gray = raster.grayscale().map { Double($0) }
    var sum = 0.0
    var sumSquare = 0.0
    var count = 0.0
    for y in 1..<(height - 1) {
        for x in 1..<(width - 1) {
            let index = y * width + x
            let laplacian =
                gray[index - 1] + gray[index + 1] + gray[index - width] + gray[index + width]
                - 4 * gray[index]
            sum += laplacian
            sumSquare += laplacian * laplacian
            count += 1
        }
    }
    let mean = sum / max(count, 1)
    let variance = max(0, sumSquare / max(count, 1) - mean * mean)
    let sharpness = variance / (variance + 500)
    var rgSum = 0.0
    var ybSum = 0.0
    var rgSquare = 0.0
    var ybSquare = 0.0
    var samples = 0.0
    for y in stride(from: 0, to: height, by: 2) {
        for x in stride(from: 0, to: width, by: 2) {
            let pixel = raster[x, y]
            let red = Double(pixel.0)
            let green = Double(pixel.1)
            let blue = Double(pixel.2)
            let rg = red - green
            let yb = 0.5 * (red + green) - blue
            rgSum += rg
            ybSum += yb
            rgSquare += rg * rg
            ybSquare += yb * yb
            samples += 1
        }
    }
    let rgMean = rgSum / max(samples, 1)
    let ybMean = ybSum / max(samples, 1)
    let rgStd = (max(0, rgSquare / max(samples, 1) - rgMean * rgMean)).squareRoot()
    let ybStd = (max(0, ybSquare / max(samples, 1) - ybMean * ybMean)).squareRoot()
    let colorfulness =
        (rgStd * rgStd + ybStd * ybStd).squareRoot()
        + 0.3 * (rgMean * rgMean + ybMean * ybMean).squareRoot()
    let color = colorfulness / (colorfulness + 70)
    let overall = Float(max(0, min(1, 0.65 * sharpness + 0.35 * color)))
    return VNImageAestheticsScoresObservation(
        overallScore: overall,
        isUtility: overall < 0.2,
        confidence: 1
    )
}

/// Classical dense block-matching optical flow. This is a documented Linux-local
/// stand-in, not Apple's flow model.
///
/// Apple oracle (macOS Vision, Xcode 26.1, 2026-09-14): `VNGenerateOpticalFlowRequest`
/// returns one `VNPixelBufferObservation` sized to the reference image in
/// `kCVPixelFormatType_TwoComponent32Float` (two Float32 (dx, dy) per pixel).
/// The sign convention matches the CG shift direction (x-right, y-down), and
/// identical frames read ~0. Magnitudes on random noise read ~1.3x the true shift,
/// so only the layout, sign convention, size, and zero-motion behavior are pinned;
/// Linux magnitudes are the block-matcher's own and are asserted with tolerance.
///
/// `reference` is the handler image; `target` is the targeted image resampled to the
/// reference size when they differ. Matching runs on a <=40px working grid with a 5x5
/// SAD block and integer displacements, then nearest-neighbour upsampling scaled back
/// to full-resolution pixels. `searchRadius` is in full-resolution pixels.
func visionOpticalFlowVectors(
    from reference: VisionRaster,
    to target: VisionRaster,
    searchRadius: Int
) -> (width: Int, height: Int, vectors: [SIMD2<Float>], confidence: Float) {
    let width = reference.width
    let height = reference.height
    guard width >= 8, height >= 8 else {
        return (width, height, [SIMD2<Float>](repeating: SIMD2<Float>(0, 0), count: max(0, width * height)), 1)
    }
    let resampled = (target.width == width && target.height == height)
        ? target : target.resized(width: width, height: height)
    let maxDim = max(width, height)
    let scale = min(1, 40 / Double(maxDim))
    let gridWidth = max(8, Int((Double(width) * scale).rounded()))
    let gridHeight = max(8, Int((Double(height) * scale).rounded()))
    let smallRef = reference.resized(width: gridWidth, height: gridHeight).grayscale()
    let smallTarget = resampled.resized(width: gridWidth, height: gridHeight).grayscale()
    let workingRadius = max(2, Int((Double(max(1, searchRadius)) * scale).rounded()))
    let half = 2
    var grid = [SIMD2<Float>](repeating: SIMD2<Float>(0, 0), count: gridWidth * gridHeight)
    var totalSAD: Double = 0
    smallRef.withUnsafeBufferPointer { refPointer in
        smallTarget.withUnsafeBufferPointer { targetPointer in
            guard let refBase = refPointer.baseAddress, let targetBase = targetPointer.baseAddress else { return }
            for gy in 0..<gridHeight {
                for gx in 0..<gridWidth {
                    var bestDX = 0
                    var bestDY = 0
                    var bestSAD = Int.max
                    for dy in -workingRadius...workingRadius {
                        for dx in -workingRadius...workingRadius {
                            var sad = 0
                            for by in -half...half {
                                let ry = min(gridHeight - 1, max(0, gy + by))
                                let ty = min(gridHeight - 1, max(0, gy + by + dy))
                                for bx in -half...half {
                                    let rx = min(gridWidth - 1, max(0, gx + bx))
                                    let tx = min(gridWidth - 1, max(0, gx + bx + dx))
                                    sad += abs(Int(refBase[ry * gridWidth + rx]) - Int(targetBase[ty * gridWidth + tx]))
                                }
                            }
                            if sad < bestSAD {
                                bestSAD = sad
                                bestDX = dx
                                bestDY = dy
                            }
                        }
                    }
                    totalSAD += Double(bestSAD)
                    grid[gy * gridWidth + gx] = SIMD2<Float>(Float(bestDX), Float(bestDY))
                }
            }
        }
    }
    let invScale = Float(1 / scale)
    var vectors = [SIMD2<Float>](repeating: SIMD2<Float>(0, 0), count: width * height)
    for y in 0..<height {
        let gy = min(gridHeight - 1, Int(Double(y) * scale))
        for x in 0..<width {
            let gx = min(gridWidth - 1, Int(Double(x) * scale))
            vectors[y * width + x] = grid[gy * gridWidth + gx] * invScale
        }
    }
    let meanSAD = totalSAD / Double(max(1, gridWidth * gridHeight * (2 * half + 1) * (2 * half + 1)))
    let confidence = Float(max(0, min(1, 1 - meanSAD / 96)))
    return (width, height, vectors, confidence)
}

/// All-zero flow field at `width` x `height` with identity confidence, matching the
/// port's stateful-tracker first-frame precedent (identity alignment, confidence 1).
func visionZeroFlowVectors(width: Int, height: Int) -> (vectors: [SIMD2<Float>], confidence: Float) {
    ([SIMD2<Float>](repeating: SIMD2<Float>(0, 0), count: max(0, width * height)), 1)
}

/// Search radius in full-resolution pixels for an optical-flow accuracy level.
/// Documented Linux-local schedule; Apple exposes only the four named levels.
func visionOpticalFlowSearchRadius(accuracy: Int) -> Int {
    switch accuracy {
    case 0: return 4
    case 1: return 8
    case 2: return 12
    default: return 16
    }
}

/// Classical Harris corner detection on a grayscale raster. Returns pixel
/// coordinates sorted by response (strongest first) with a minimum separation
/// of 4 pixels, capped at `maxCount`. A documented Linux-local helper shared by
/// homographic registration and trajectory tracklets; not an Apple detector.
func visionHarrisCorners(
    gray: [UInt8],
    width: Int,
    height: Int,
    maxCount: Int
) -> [(x: Int, y: Int, response: Float)] {
    guard width >= 8, height >= 8, maxCount > 0 else { return [] }
    var gx = [Float](repeating: 0, count: width * height)
    var gy = [Float](repeating: 0, count: width * height)
    for y in 1..<(height - 1) {
        for x in 1..<(width - 1) {
            let index = y * width + x
            gx[index] = Float(gray[index + 1]) - Float(gray[index - 1])
            gy[index] = Float(gray[index + width]) - Float(gray[index - width])
        }
    }
    var candidates: [(x: Int, y: Int, response: Float)] = []
    var maxResponse: Float = 0
    var responses = [Float](repeating: 0, count: width * height)
    for y in 1..<(height - 1) {
        for x in 1..<(width - 1) {
            var sxx: Float = 0
            var syy: Float = 0
            var sxy: Float = 0
            for dy in -1...1 {
                for dx in -1...1 {
                    let index = (y + dy) * width + (x + dx)
                    sxx += gx[index] * gx[index]
                    syy += gy[index] * gy[index]
                    sxy += gx[index] * gy[index]
                }
            }
            let determinant = sxx * syy - sxy * sxy
            let trace = sxx + syy
            let response = determinant - 0.04 * trace * trace
            if response > 0 {
                responses[y * width + x] = response
                if response > maxResponse { maxResponse = response }
            }
        }
    }
    guard maxResponse > 0 else { return [] }
    let floor = maxResponse * 0.01
    for y in 1..<(height - 1) {
        for x in 1..<(width - 1) {
            let response = responses[y * width + x]
            if response >= floor {
                candidates.append((x, y, response))
            }
        }
    }
    candidates.sort { $0.response > $1.response }
    var accepted: [(x: Int, y: Int, response: Float)] = []
    for candidate in candidates {
        var clear = true
        for other in accepted {
            let dx = candidate.x - other.x
            let dy = candidate.y - other.y
            if dx * dx + dy * dy < 16 {
                clear = false
                break
            }
        }
        if clear {
            accepted.append(candidate)
            if accepted.count >= maxCount { break }
        }
    }
    return accepted
}

/// Zero-mean normalized cross-correlation of two square patches of radius
/// `radius` centred at `a` in `first` and `b` in `second`. Returns -2 when
/// either patch leaves the raster. Range is -1...1 for valid patches.
func visionPatchNCC(
    first: [UInt8],
    second: [UInt8],
    width: Int,
    height: Int,
    a: (x: Int, y: Int),
    b: (x: Int, y: Int),
    radius: Int
) -> Float {
    guard a.x - radius >= 0, a.y - radius >= 0, a.x + radius < width, a.y + radius < height,
        b.x - radius >= 0, b.y - radius >= 0, b.x + radius < width, b.y + radius < height
    else { return -2 }
    var sumA = 0.0
    var sumB = 0.0
    var count = 0.0
    for dy in -radius...radius {
        for dx in -radius...radius {
            sumA += Double(first[(a.y + dy) * width + (a.x + dx)])
            sumB += Double(second[(b.y + dy) * width + (b.x + dx)])
            count += 1
        }
    }
    let meanA = sumA / count
    let meanB = sumB / count
    var num = 0.0
    var denA = 0.0
    var denB = 0.0
    for dy in -radius...radius {
        for dx in -radius...radius {
            let da = Double(first[(a.y + dy) * width + (a.x + dx)]) - meanA
            let db = Double(second[(b.y + dy) * width + (b.x + dx)]) - meanB
            num += da * db
            denA += da * da
            denB += db * db
        }
    }
    let denominator = (denA * denB).squareRoot()
    guard denominator > 1e-9 else { return -2 }
    return Float(num / denominator)
}

/// Best NCC match for source point `a` inside `second` within `searchRadius`
/// pixels. Returns nil when no candidate reaches `threshold`.
func visionMatchCorner(
    first: [UInt8],
    second: [UInt8],
    width: Int,
    height: Int,
    a: (x: Int, y: Int),
    searchRadius: Int,
    patchRadius: Int,
    threshold: Float
) -> (x: Int, y: Int, score: Float)? {
    var best: (x: Int, y: Int, score: Float)?
    for dy in -searchRadius...searchRadius {
        for dx in -searchRadius...searchRadius {
            let b = (x: a.x + dx, y: a.y + dy)
            let score = visionPatchNCC(
                first: first, second: second, width: width, height: height,
                a: a, b: b, radius: patchRadius
            )
            if score >= threshold, best == nil || score > best!.score {
                best = (b.x, b.y, score)
            }
        }
    }
    return best
}

/// Least-squares 3x3 homography from `pairs` (source -> destination) with
/// Hartley normalization, solved with h[8] fixed to 1 via 8x8 normal
/// equations. Returns 9 row-major doubles, or nil when degenerate.
func visionDLTHomography(_ pairs: [(src: SIMD2<Double>, dst: SIMD2<Double>)]) -> [Double]? {
    let count = pairs.count
    guard count >= 4 else { return nil }
    var srcMean = SIMD2<Double>(0, 0)
    var dstMean = SIMD2<Double>(0, 0)
    for pair in pairs {
        srcMean += pair.src
        dstMean += pair.dst
    }
    srcMean /= Double(count)
    dstMean /= Double(count)
    var srcSpread = 0.0
    var dstSpread = 0.0
    for pair in pairs {
        let a = pair.src - srcMean
        let b = pair.dst - dstMean
        srcSpread += (a.x * a.x + a.y * a.y).squareRoot()
        dstSpread += (b.x * b.x + b.y * b.y).squareRoot()
    }
    srcSpread /= Double(count)
    dstSpread /= Double(count)
    guard srcSpread > 1e-9, dstSpread > 1e-9 else { return nil }
    let srcScale = 1.4142135623730951 / srcSpread
    let dstScale = 1.4142135623730951 / dstSpread
    var lhs = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 8)
    var rhs = [Double](repeating: 0, count: 8)
    for pair in pairs {
        let sx = (pair.src.x - srcMean.x) * srcScale
        let sy = (pair.src.y - srcMean.y) * srcScale
        let dx = (pair.dst.x - dstMean.x) * dstScale
        let dy = (pair.dst.y - dstMean.y) * dstScale
        let rows: [([Double], Double)] = [
            ([sx, sy, 1, 0, 0, 0, -dx * sx, -dx * sy], dx),
            ([0, 0, 0, sx, sy, 1, -dy * sx, -dy * sy], dy),
        ]
        for (row, value) in rows {
            for i in 0..<8 {
                rhs[i] += row[i] * value
                for j in 0..<8 {
                    lhs[i][j] += row[i] * row[j]
                }
            }
        }
    }
    var matrix = lhs
    var vector = rhs
    for column in 0..<8 {
        var pivot = column
        for row in (column + 1)..<8 {
            if abs(matrix[row][column]) > abs(matrix[pivot][column]) { pivot = row }
        }
        guard abs(matrix[pivot][column]) > 1e-12 else { return nil }
        if pivot != column {
            matrix.swapAt(pivot, column)
            vector.swapAt(pivot, column)
        }
        let divisor = matrix[column][column]
        for row in (column + 1)..<8 {
            let factor = matrix[row][column] / divisor
            if factor != 0 {
                for k in column..<8 { matrix[row][k] -= factor * matrix[column][k] }
                vector[row] -= factor * vector[column]
            }
        }
    }
    var solution = [Double](repeating: 0, count: 8)
    for row in stride(from: 7, through: 0, by: -1) {
        var sum = vector[row]
        for k in (row + 1)..<8 { sum -= matrix[row][k] * solution[k] }
        solution[row] = sum / matrix[row][row]
    }
    var normalized = solution
    normalized.append(1)
    func translation(_ tx: Double, _ ty: Double) -> [Double] {
        [1, 0, tx, 0, 1, ty, 0, 0, 1]
    }
    func scaled(_ s: Double) -> [Double] {
        [s, 0, 0, 0, s, 0, 0, 0, 1]
    }
    func multiply(_ a: [Double], _ b: [Double]) -> [Double] {
        var out = [Double](repeating: 0, count: 9)
        for r in 0..<3 {
            for c in 0..<3 {
                out[r * 3 + c] = a[r * 3] * b[c] + a[r * 3 + 1] * b[3 + c] + a[r * 3 + 2] * b[6 + c]
            }
        }
        return out
    }
    let tSrc = multiply(scaled(srcScale), translation(-srcMean.x, -srcMean.y))
    let invDst = multiply(translation(dstMean.x, dstMean.y), scaled(1 / dstScale))
    let denormalized = multiply(invDst, multiply(normalized, tSrc))
    guard abs(denormalized[8]) > 1e-12 else { return nil }
    return denormalized.map { $0 / denormalized[8] }
}

/// Row-major 3x3 homography mapping `source` pixels to `target` pixels using
/// Harris corners, NCC matching, and deterministic exhaustive RANSAC over the
/// 12 best matches. Falls back to the phase-correlation translation embedded
/// in a 3x3 matrix when too few inliers survive. Returns the matrix and an
/// inlier-ratio confidence in 0...1.
///
/// Linux-local convention (documented, not Apple-observed): `warpTransform`
/// maps targeted-image (floating/source) pixel coordinates to reference-image
/// (target) pixel coordinates, column-major (`p' = H * p` with `p = (x, y, 1)`).
func visionHomographyMatrix(source: VisionRaster, target: VisionRaster) -> (matrix: [Double], confidence: Float) {
    let fallback: () -> (matrix: [Double], confidence: Float) = {
        let shift = visionTranslationalAlignment(source: source, target: target).alignmentTransform
        let tx = Double(shift.tx)
        let ty = Double(shift.ty)
        return ([1, 0, tx, 0, 1, ty, 0, 0, 1], 0.35)
    }
    let work = 64
    guard source.width >= 16, source.height >= 16, target.width >= 16, target.height >= 16 else {
        return fallback()
    }
    let gridWidth = work
    let gridHeight = max(1, work * source.height / max(1, source.width))
    let smallSource = source.resized(width: gridWidth, height: gridHeight)
    let smallTarget = target.resized(width: gridWidth, height: gridHeight)
    let graySource = smallSource.grayscale()
    let grayTarget = smallTarget.grayscale()
    let corners = visionHarrisCorners(gray: graySource, width: gridWidth, height: gridHeight, maxCount: 48)
    guard corners.count >= 4 else { return fallback() }
    var matches: [(src: SIMD2<Double>, dst: SIMD2<Double>, score: Float)] = []
    for corner in corners {
        if let hit = visionMatchCorner(
            first: graySource, second: grayTarget, width: gridWidth, height: gridHeight,
            a: (corner.x, corner.y), searchRadius: 12, patchRadius: 3, threshold: 0.75
        ) {
            matches.append((
                SIMD2<Double>(Double(corner.x), Double(corner.y)),
                SIMD2<Double>(Double(hit.x), Double(hit.y)),
                hit.score
            ))
        }
        if matches.count >= 24 { break }
    }
    guard matches.count >= 4 else { return fallback() }
    matches.sort { $0.score > $1.score }
    let pool = Array(matches.prefix(12))
    func reprojectionError(_ h: [Double], src: SIMD2<Double>, dst: SIMD2<Double>) -> Double {
        let w = h[6] * src.x + h[7] * src.y + h[8]
        guard abs(w) > 1e-9 else { return Double.greatestFiniteMagnitude }
        let px = (h[0] * src.x + h[1] * src.y + h[2]) / w
        let py = (h[3] * src.x + h[4] * src.y + h[5]) / w
        let dx = px - dst.x
        let dy = py - dst.y
        return (dx * dx + dy * dy).squareRoot()
    }
    var bestMatrix: [Double]?
    var bestInliers: [Int] = []
    var bestError = Double.greatestFiniteMagnitude
    let n = pool.count
    for a in 0..<(n - 3) {
        for b in (a + 1)..<(n - 2) {
            for c in (b + 1)..<(n - 1) {
                for d in (c + 1)..<n {
                    let subset = [pool[a], pool[b], pool[c], pool[d]]
                    guard let h = visionDLTHomography(subset.map({ (src: $0.src, dst: $0.dst) })) else { continue }
                    var inliers: [Int] = []
                    var total = 0.0
                    for (index, pair) in pool.enumerated() {
                        let error = reprojectionError(h, src: pair.src, dst: pair.dst)
                        if error <= 2.0 {
                            inliers.append(index)
                            total += error
                        }
                    }
                    if inliers.count > bestInliers.count
                        || (inliers.count == bestInliers.count && total < bestError)
                    {
                        bestInliers = inliers
                        bestMatrix = h
                        bestError = total
                    }
                }
            }
        }
    }
    guard bestMatrix != nil, bestInliers.count >= 6,
        Double(bestInliers.count) >= Double(pool.count) * 0.5,
        let refined = visionDLTHomography(bestInliers.map({
            (src: pool[$0].src, dst: pool[$0].dst)
        }))
    else { return fallback() }
    let scaleX = Double(source.width) / Double(gridWidth)
    let scaleY = Double(source.height) / Double(gridHeight)
    let toFull: [Double] = [scaleX, 0, 0, 0, scaleY, 0, 0, 0, 1]
    let toGrid: [Double] = [1 / scaleX, 0, 0, 0, 1 / scaleY, 0, 0, 0, 1]
    func rescale(_ a: [Double], _ b: [Double]) -> [Double] {
        var out = [Double](repeating: 0, count: 9)
        for r in 0..<3 {
            for c in 0..<3 {
                out[r * 3 + c] = a[r * 3] * b[c] + a[r * 3 + 1] * b[3 + c] + a[r * 3 + 2] * b[6 + c]
            }
        }
        return out
    }
    var full = rescale(toFull, rescale(refined, toGrid))
    guard abs(full[8]) > 1e-12 else { return fallback() }
    full = full.map { $0 / full[8] }
    let ratio = Float(bestInliers.count) / Float(max(1, pool.count))
    return (full, 0.5 + 0.5 * min(1, ratio))
}

/// Classical homographic alignment observation for `source` (targeted/floating)
/// onto `target` (reference). Documented non-Apple heuristic: Harris corners +
/// NCC matching + normalized DLT with exhaustive deterministic RANSAC, falling
/// back to the phase-correlation translation when too few inliers survive.
func visionHomographicAlignment(
    source: VisionRaster,
    target: VisionRaster
) -> VNImageHomographicAlignmentObservation {
    let result = visionHomographyMatrix(source: source, target: target)
    let h = result.matrix
    let observation = VNImageHomographicAlignmentObservation(confidence: result.confidence)
    observation.warpTransform = matrix_float3x3(columns: (
        SIMD3<Float>(Float(h[0]), Float(h[3]), Float(h[6])),
        SIMD3<Float>(Float(h[1]), Float(h[4]), Float(h[7])),
        SIMD3<Float>(Float(h[2]), Float(h[5]), Float(h[8]))
    ))
    return observation
}

/// Classical generic-foreground instance mask. Reuses the port's center-surround
/// contrast heat map, thresholds at half-maximum, flood-fills interior holes,
/// and labels the largest connected foreground blob as instance 1 (everything
/// else is background 0). Uniform images yield an empty mask with confidence 0.
/// This is generic contrast foreground, not Apple person segmentation.
func visionForegroundInstanceMask(in raster: VisionRaster) -> VNInstanceMaskObservation {
    let width = raster.width
    let height = raster.height
    func empty(_ confidence: VNConfidence) -> VNInstanceMaskObservation {
        VNInstanceMaskObservation(
            instanceMask: CVPixelBuffer(width: max(width, 0), height: max(height, 0)),
            confidence: confidence
        )
    }
    guard width >= 2, height >= 2 else { return empty(0) }
    let grid = 32
    let small = raster.resized(width: grid, height: grid).grayscale().map { Double($0) }
    var blur = [Double](repeating: 0, count: grid * grid)
    for y in 0..<grid {
        for x in 0..<grid {
            var sum = 0.0
            var count = 0.0
            for dy in -1...1 {
                for dx in -1...1 {
                    let nx = x + dx
                    let ny = y + dy
                    if nx >= 0 && ny >= 0 && nx < grid && ny < grid {
                        sum += small[ny * grid + nx]
                        count += 1
                    }
                }
            }
            blur[y * grid + x] = sum / max(count, 1)
        }
    }
    var contrast = [Double](repeating: 0, count: grid * grid)
    var maxContrast = 0.0
    for index in 0..<contrast.count {
        contrast[index] = abs(small[index] - blur[index])
        if contrast[index] > maxContrast { maxContrast = contrast[index] }
    }
    guard maxContrast > 1 else { return empty(0) }
    let threshold = maxContrast * 0.5
    var foreground = [Bool](repeating: false, count: grid * grid)
    for index in 0..<foreground.count {
        foreground[index] = contrast[index] >= threshold
    }
    do {
        var visited = [Bool](repeating: false, count: grid * grid)
        var stack: [(x: Int, y: Int)] = []
        for x in 0..<grid {
            if !foreground[x] { stack.append((x, 0)) }
            if !foreground[(grid - 1) * grid + x] { stack.append((x, grid - 1)) }
        }
        for y in 0..<grid {
            if !foreground[y * grid] { stack.append((0, y)) }
            if !foreground[y * grid + grid - 1] { stack.append((grid - 1, y)) }
        }
        while let cell = stack.popLast() {
            let index = cell.y * grid + cell.x
            if visited[index] || foreground[index] { continue }
            visited[index] = true
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let nx = cell.x + dx
                let ny = cell.y + dy
                if nx >= 0 && ny >= 0 && nx < grid && ny < grid {
                    stack.append((nx, ny))
                }
            }
        }
        for index in 0..<foreground.count {
            if !visited[index] && !foreground[index] {
                foreground[index] = true
            }
        }
    }
    var labels = [Int](repeating: 0, count: grid * grid)
    var sizes: [Int] = [0]
    var nextLabel = 0
    for y in 0..<grid {
        for x in 0..<grid {
            let index = y * grid + x
            guard foreground[index], labels[index] == 0 else { continue }
            nextLabel += 1
            sizes.append(0)
            var stack = [(x, y)]
            while let cell = stack.popLast() {
                if cell.0 < 0 || cell.1 < 0 || cell.0 >= grid || cell.1 >= grid { continue }
                let cellIndex = cell.1 * grid + cell.0
                if !foreground[cellIndex] || labels[cellIndex] != 0 { continue }
                labels[cellIndex] = nextLabel
                sizes[nextLabel] += 1
                stack.append((cell.0 + 1, cell.1))
                stack.append((cell.0 - 1, cell.1))
                stack.append((cell.0, cell.1 + 1))
                stack.append((cell.0, cell.1 - 1))
            }
        }
    }
    var bestLabel = 0
    var bestSize = 0
    for label in 1...max(1, nextLabel) {
        if sizes[label] > bestSize {
            bestSize = sizes[label]
            bestLabel = label
        }
    }
    guard bestLabel > 0 else { return empty(0) }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        let gridY = min(grid - 1, (y * grid) / height)
        for x in 0..<width {
            let gridX = min(grid - 1, (x * grid) / width)
            let offset = (y * width + x) * 4
            if labels[gridY * grid + gridX] == bestLabel {
                pixels[offset] = 1
                pixels[offset + 3] = 255
            } else {
                pixels[offset + 3] = 255
            }
        }
    }
    return VNInstanceMaskObservation(
        instanceMask: CVPixelBuffer(width: width, height: height, pixels: pixels),
        confidence: VNConfidence(min(1, maxContrast / 64))
    )
}
