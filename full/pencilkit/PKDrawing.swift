import Foundation

public struct PKDrawing: Equatable {
    public var strokes: [PKStroke]

    public init() {
        self.strokes = []
    }

    public init<S>(strokes: S) where S: Sequence, S.Element == PKStroke {
        self.strokes = Array(strokes)
    }

    public init(data: Data) throws {
        self = try PKDrawingCodec.decode(data)
    }

    public var bounds: CGRect {
        guard let first = strokes.first else { return .zero }
        return strokes.dropFirst().reduce(first.renderBounds) { $0.union($1.renderBounds) }
    }

    public var requiredContentVersion: PKContentVersion {
        strokes.map(\.requiredContentVersion).max(by: { $0.rawValue < $1.rawValue }) ?? .version1
    }

    public mutating func append(_ toAppend: PKDrawing) {
        strokes.append(contentsOf: toAppend.strokes)
    }

    public func appending(_ toAppend: PKDrawing) -> PKDrawing {
        var copy = self
        copy.append(toAppend)
        return copy
    }

    public mutating func transform(using transform: PencilKitTransform) {
        strokes = strokes.map { stroke in
            var next = stroke
            next.path = PKStrokePath(
                controlPoints: stroke.path.map { point in
                    var mapped = point
                    mapped.location = pk_applyTransform(transform, to: point.location)
                    return mapped
                },
                creationDate: stroke.path.creationDate
            )
            return next
        }
    }

    public func transformed(using transform: PencilKitTransform) -> PKDrawing {
        var copy = self
        copy.transform(using: transform)
        return copy
    }

    public func dataRepresentation() -> Data {
        PKDrawingCodec.encode(self)
    }

    /// Fail-closed raster: returns a blank image whose size is `rect.size * scale`.
    /// Pixel contents are never claimed to match Apple ink rendering.
    public func image(from rect: CGRect, scale: CGFloat) -> PencilKitImage {
        let width = max(rect.width * scale, 0)
        let height = max(rect.height * scale, 0)
#if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { _ in }
#else
        return PencilKitHostImage(size: CGSize(width: width, height: height))
#endif
    }

    /// Fail-closed: isolated Linux does not replay ink into a `CGContext`.
    public func draw(
        in cgContext: PencilKitContext,
        frame: CGRect,
        from sourceRect: CGRect,
        darkUserInterfaceStyle: Bool = false
    ) async {
        _ = (cgContext, frame, sourceRect, darkUserInterfaceStyle)
    }

    public static func == (a: PKDrawing, b: PKDrawing) -> Bool {
        a.strokes == b.strokes
    }
}

extension PKDrawing: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        self = try PKDrawing(data: data)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(dataRepresentation())
    }
}

open class PKDrawingReference: NSObject {
    public var drawing: PKDrawing

    public override init() {
        self.drawing = PKDrawing()
        super.init()
    }

    public init(data: Data) throws {
        self.drawing = try PKDrawing(data: data)
        super.init()
    }

    public convenience init(strokes: [PKStroke]) {
        self.init()
        self.drawing = PKDrawing(strokes: strokes)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public var bounds: CGRect { drawing.bounds }
    public var requiredContentVersion: PKContentVersion { drawing.requiredContentVersion }
    public var strokes: [PKStroke] { drawing.strokes }

    public func dataRepresentation() -> Data { drawing.dataRepresentation() }

    public func appending(_ drawing: PKDrawing) -> PKDrawing {
        self.drawing.appending(drawing)
    }

    public func appendingStrokes(_ strokes: [PKStroke]) -> PKDrawing {
        self.drawing.appending(PKDrawing(strokes: strokes))
    }

    public func applying(_ transform: PencilKitTransform) -> PKDrawing {
        drawing.transformed(using: transform)
    }

    public func image(from rect: CGRect, scale: CGFloat) -> PencilKitImage {
        drawing.image(from: rect, scale: scale)
    }
}

enum PKDrawingCodec {
    static func jsonDouble(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }

    static func jsonInt(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? Double { return Int(value) }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }

    static func encode(_ drawing: PKDrawing) -> Data {
        let strokes: [[String: Any]] = drawing.strokes.map { stroke in
            let color = pk_colorComponents(stroke.ink.color)
            let transform = pk_transformComponents(stroke.transform)
            let points: [[String: Any]] = stroke.path.map { point in
                [
                    "x": Double(point.location.x),
                    "y": Double(point.location.y),
                    "time": point.timeOffset,
                    "w": Double(point.size.width),
                    "h": Double(point.size.height),
                    "opacity": Double(point.opacity),
                    "force": Double(point.force),
                    "azimuth": Double(point.azimuth),
                    "altitude": Double(point.altitude),
                    "secondaryScale": Double(point.secondaryScale),
                    "threshold": Double(point.threshold),
                ]
            }
            return [
                "inkType": stroke.ink.inkType.rawValue,
                "color": [Double(color.0), Double(color.1), Double(color.2), Double(color.3)],
                "width": Double(stroke.path.first?.size.width ?? 0),
                "randomSeed": Int(stroke.randomSeed),
                "creationDate": stroke.path.creationDate.timeIntervalSince1970,
                "transform": [
                    Double(transform.0), Double(transform.1), Double(transform.2),
                    Double(transform.3), Double(transform.4), Double(transform.5),
                ],
                "points": points,
            ]
        }
        let payload: [String: Any] = ["v": 1, "strokes": strokes]
        let json = (try? JSONSerialization.data(withJSONObject: payload, options: [])) ?? Data()
        return PKDrawingOpenUIKitMagic + json
    }

    static func decode(_ data: Data) throws -> PKDrawing {
        guard data.count >= 4 else {
            throw PKDrawingDataError.malformedOpenUIKitDrawing
        }
        let magic = data.prefix(4)
        guard magic == PKDrawingOpenUIKitMagic else {
            throw PKDrawingDataError.appleFormatUnsupported
        }
        let json = data.dropFirst(4)
        guard
            let object = try JSONSerialization.jsonObject(with: Data(json)) as? [String: Any],
            let strokeRows = object["strokes"] as? [[String: Any]]
        else {
            throw PKDrawingDataError.malformedOpenUIKitDrawing
        }
        let strokes: [PKStroke] = try strokeRows.map { row in
            guard
                let inkRaw = row["inkType"] as? String,
                let inkType = PKInkingTool.InkType(rawValue: inkRaw),
                let colorRow = row["color"] as? [Any],
                colorRow.count == 4,
                let transformRow = row["transform"] as? [Any],
                transformRow.count == 6,
                let seed = jsonInt(row["randomSeed"]),
                let created = jsonDouble(row["creationDate"]),
                let pointRows = row["points"] as? [[String: Any]],
                let c0 = jsonDouble(colorRow[0]),
                let c1 = jsonDouble(colorRow[1]),
                let c2 = jsonDouble(colorRow[2]),
                let c3 = jsonDouble(colorRow[3]),
                let t0 = jsonDouble(transformRow[0]),
                let t1 = jsonDouble(transformRow[1]),
                let t2 = jsonDouble(transformRow[2]),
                let t3 = jsonDouble(transformRow[3]),
                let t4 = jsonDouble(transformRow[4]),
                let t5 = jsonDouble(transformRow[5])
            else {
                throw PKDrawingDataError.malformedOpenUIKitDrawing
            }
            let color = pk_makeColor(
                red: CGFloat(c0),
                green: CGFloat(c1),
                blue: CGFloat(c2),
                alpha: CGFloat(c3)
            )
            let ink = PKInk(inkType, color: color)
            let points: [PKStrokePoint] = try pointRows.map { pointRow in
                guard
                    let x = jsonDouble(pointRow["x"]),
                    let y = jsonDouble(pointRow["y"]),
                    let time = jsonDouble(pointRow["time"]),
                    let w = jsonDouble(pointRow["w"]),
                    let h = jsonDouble(pointRow["h"]),
                    let opacity = jsonDouble(pointRow["opacity"]),
                    let force = jsonDouble(pointRow["force"]),
                    let azimuth = jsonDouble(pointRow["azimuth"]),
                    let altitude = jsonDouble(pointRow["altitude"]),
                    let secondary = jsonDouble(pointRow["secondaryScale"]),
                    let threshold = jsonDouble(pointRow["threshold"])
                else {
                    throw PKDrawingDataError.malformedOpenUIKitDrawing
                }
                return PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: time,
                    size: CGSize(width: w, height: h),
                    opacity: CGFloat(opacity),
                    force: CGFloat(force),
                    azimuth: CGFloat(azimuth),
                    altitude: CGFloat(altitude),
                    secondaryScale: CGFloat(secondary),
                    threshold: CGFloat(threshold)
                )
            }
            let path = PKStrokePath(
                controlPoints: points,
                creationDate: Date(timeIntervalSince1970: created)
            )
            let transform = pk_makeTransform(
                a: CGFloat(t0),
                b: CGFloat(t1),
                c: CGFloat(t2),
                d: CGFloat(t3),
                tx: CGFloat(t4),
                ty: CGFloat(t5)
            )
            return PKStroke(
                ink: ink,
                path: path,
                transform: transform,
                mask: nil,
                randomSeed: UInt32(truncatingIfNeeded: seed)
            )
        }
        return PKDrawing(strokes: strokes)
    }
}
