import Foundation

/// The data model object for storing markup data created from a
/// `PaperMarkupViewController`.
public struct PaperMarkup: Equatable, Sendable {
    /// The bounds of the paper.
    ///
    /// The contents of the paper are positioned relative to its bounds.
    public var bounds: CGRect

    var elements: [PaperMarkupElement]

    /// Initializes and returns a new paper model with the specified bounds.
    public init(bounds: CGRect) {
        self.bounds = bounds
        self.elements = []
    }

    /// Initializes and returns a new paper model from the specified data.
    public init(dataRepresentation: Data) throws {
        guard dataRepresentation.count >= 12 else {
            throw MarkupError.incorrectFormat
        }
        let magic = dataRepresentation.prefix(4)
        guard magic == PaperMarkupOpenUIKitMagic else {
            throw MarkupError.incorrectFormat
        }
        let version = paperKitUInt32BigEndian(dataRepresentation, offset: 4)
        if version > PaperMarkupOpenUIKitArchiveVersion {
            throw MarkupError.incompatibleFormatTooNew
        }
        if version < 1 {
            throw MarkupError.incorrectFormat
        }
        let payloadLength = paperKitUInt32BigEndian(dataRepresentation, offset: 8)
        let expectedCount = 12 + Int(payloadLength)
        guard dataRepresentation.count == expectedCount else {
            throw MarkupError.malformedData
        }
        let payload = dataRepresentation.subdata(in: 12..<expectedCount)
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: payload, options: [])
        } catch {
            throw MarkupError.malformedData
        }
        guard let root = object as? [String: Any] else {
            throw MarkupError.malformedData
        }
        guard let boundsDict = root["bounds"] as? [String: Any],
              let parsedBounds = PaperMarkup.parseRect(boundsDict) else {
            throw MarkupError.malformedData
        }
        guard let rawElements = root["elements"] as? [Any] else {
            throw MarkupError.malformedData
        }
        var decoded: [PaperMarkupElement] = []
        decoded.reserveCapacity(rawElements.count)
        for item in rawElements {
            guard let dict = item as? [String: Any],
                  let element = PaperMarkup.parseElement(dict) else {
                throw MarkupError.malformedData
            }
            decoded.append(element)
        }
        self.bounds = parsedBounds
        self.elements = decoded
    }

    /// Generate a serialized data representation of the data model.
    public func dataRepresentation() async throws -> Data {
        try encodeOpenUIKitArchive()
    }

    /// Concatenated text-box strings, or `nil` when the paper has no text.
    public var indexableContent: String? {
        get async {
            let parts = elements.compactMap { element -> String? in
                if case .textbox(let text, _, _) = element {
                    return text.isEmpty ? nil : text
                }
                return nil
            }
            if parts.isEmpty {
                return nil
            }
            return parts.joined(separator: "\n")
        }
    }

    /// The frame that tightly fits the rendered contents on the paper.
    ///
    /// Linux unions element frames and inflates by `max(1, lineWidth / 2)`.
    /// Apple's stroke/shadow padding is an oracle question. An empty paper
    /// returns `CGRect.null`.
    public var contentsRenderFrame: CGRect {
        var union = CGRect.null
        for element in elements {
            let pad: CGFloat
            switch element {
            case .shape(let configuration, let frame, _):
                pad = max(1, configuration.lineWidth / 2)
                union = union.union(frame.insetBy(dx: -pad, dy: -pad))
            case .line(let configuration, let start, let end, _, _):
                pad = max(1, configuration.lineWidth / 2)
                let minX = min(start.x, end.x)
                let minY = min(start.y, end.y)
                let width = max(abs(end.x - start.x), 0.5)
                let height = max(abs(end.y - start.y), 0.5)
                let frame = CGRect(x: minX, y: minY, width: width, height: height)
                union = union.union(frame.insetBy(dx: -pad, dy: -pad))
            case .textbox(_, let frame, _), .image(_, _, let frame, _):
                union = union.union(frame.insetBy(dx: -1, dy: -1))
            case .drawing:
                union = union.union(bounds)
            }
        }
        return union
    }

    /// The set of features used by this data model.
    public var featureSet: FeatureSet {
        var used = FeatureSet.empty
        used.contentVersion = .version1
        used.colorMaximumLinearExposure = 1.0
        for element in elements {
            switch element {
            case .shape(let configuration, _, _):
                used.shapes.insert(configuration.type)
                if configuration.fillColor != nil {
                    used.insert(.shapeFills)
                }
                if configuration.strokeColor != nil || configuration.lineWidth > 0 {
                    used.insert(.shapeStrokes)
                }
            case .line(let configuration, _, _, let startMarker, let endMarker):
                used.shapes.insert(.line)
                if configuration.fillColor != nil {
                    used.insert(.shapeFills)
                }
                if configuration.strokeColor != nil || configuration.lineWidth > 0 {
                    used.insert(.shapeStrokes)
                }
                if startMarker && endMarker {
                    used.lineMarkerPositions.insert(.double)
                } else if startMarker || endMarker {
                    used.lineMarkerPositions.insert(.single)
                } else {
                    used.lineMarkerPositions.insert(.plain)
                }
            case .textbox:
                used.insert(.text)
            case .image:
                used.insert(.images)
            case .drawing:
                used.insert(.drawing)
                used.inks = paperKitAllInkTypes()
            }
        }
        return used
    }

    /// Draws the entire paper contents in the specified rectangle.
    ///
    /// Linux does not rasterize markup into `CGContext`. The call returns
    /// without painting pixels so callers cannot treat it as Apple rendering.
    public func draw(
        in context: CGContext,
        frame: CGRect,
        options: RenderingOptions = RenderingOptions()
    ) async {
        _ = context
        _ = frame
        _ = options
    }

    /// Adds the contents of a data model on top of this paper.
    public mutating func append(contentsOf other: PaperMarkup) {
        elements.append(contentsOf: other.elements)
    }

    /// Adds the contents of a PencilKit drawing on top of this paper.
    public mutating func append(contentsOf drawing: PKDrawing) {
        _ = drawing
        elements.append(.drawing)
    }

    /// Transforms the contents of this paper with the specified transform.
    ///
    /// Skew stripping versus Darwin is an oracle question; Linux applies the
    /// full affine matrix to every point and uses the axis-aligned bounding
    /// box of transformed corners for frames.
    public mutating func transformContent(_ transform: CGAffineTransform) {
        elements = elements.map { $0.applying(transform) }
    }

    /// Add a new element on top of the paper.
    public mutating func insertNewShape(
        configuration: ShapeConfiguration,
        frame: CGRect,
        rotation: CGFloat = 0
    ) {
        elements.append(.shape(configuration, frame: frame, rotation: rotation))
    }

    /// Add a line element on top of the paper.
    public mutating func insertNewLine(
        configuration: ShapeConfiguration,
        from start: CGPoint,
        to end: CGPoint,
        startMarker lineStartMarker: Bool = false,
        endMarker lineEndMarker: Bool = false
    ) {
        elements.append(
            .line(
                configuration,
                from: start,
                to: end,
                startMarker: lineStartMarker,
                endMarker: lineEndMarker
            )
        )
    }

    /// Add a new text box on top of the paper.
    public mutating func insertNewTextbox(
        attributedText: NSAttributedString,
        frame: CGRect,
        rotation: CGFloat = 0
    ) {
        elements.append(.textbox(attributedText.string, frame: frame, rotation: rotation))
    }

    /// Add a new text box on top of the paper.
    public mutating func insertNewTextbox(
        attributedText: AttributedString,
        frame: CGRect,
        rotation: CGFloat = 0
    ) {
        elements.append(.textbox(String(attributedText.characters), frame: frame, rotation: rotation))
    }

    /// Add a new image on top of the paper.
    ///
    /// Linux records width, height, frame, and rotation. Pixel buffers are
    /// not stored and are not replayed as Apple bitmaps.
    public mutating func insertNewImage(_ image: CGImage, frame: CGRect, rotation: CGFloat = 0) {
        elements.append(
            .image(width: image.width, height: image.height, frame: frame, rotation: rotation)
        )
    }

    /// Remove all contents that is not supported by the provided feature set.
    ///
    /// After calling this method `featureSet.isSubset(of: featureSet)` is
    /// `true` for the argument.
    public mutating func removeContentUnsupported(by featureSet: FeatureSet) {
        elements.removeAll { element in
            !element.isSupported(by: featureSet)
        }
    }

    public static func == (lhs: PaperMarkup, rhs: PaperMarkup) -> Bool {
        lhs.bounds == rhs.bounds && lhs.elements == rhs.elements
    }

    func encodeOpenUIKitArchive() throws -> Data {
        let payloadObject: [String: Any] = [
            "bounds": PaperMarkup.rectDictionary(bounds),
            "elements": elements.map { $0.jsonObject() },
        ]
        let payload: Data
        do {
            payload = try JSONSerialization.data(withJSONObject: payloadObject, options: [])
        } catch {
            throw MarkupError.malformedData
        }
        var archive = Data()
        archive.append(PaperMarkupOpenUIKitMagic)
        var version = PaperMarkupOpenUIKitArchiveVersion.bigEndian
        Swift.withUnsafeBytes(of: &version) { archive.append(contentsOf: $0) }
        var length = UInt32(payload.count).bigEndian
        Swift.withUnsafeBytes(of: &length) { archive.append(contentsOf: $0) }
        archive.append(payload)
        return archive
    }

    static func parseRect(_ dict: [String: Any]) -> CGRect? {
        guard let x = cgFloat(dict["x"]),
              let y = cgFloat(dict["y"]),
              let w = cgFloat(dict["w"]),
              let h = cgFloat(dict["h"]) else {
            return nil
        }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    static func parsePoint(_ dict: [String: Any]) -> CGPoint? {
        guard let x = cgFloat(dict["x"]), let y = cgFloat(dict["y"]) else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }

    static func rectDictionary(_ rect: CGRect) -> [String: Any] {
        ["x": rect.origin.x, "y": rect.origin.y, "w": rect.size.width, "h": rect.size.height]
    }

    static func pointDictionary(_ point: CGPoint) -> [String: Any] {
        ["x": point.x, "y": point.y]
    }

    static func cgFloat(_ value: Any?) -> CGFloat? {
        switch value {
        case let number as NSNumber:
            return CGFloat(number.doubleValue)
        case let double as Double:
            return CGFloat(double)
        case let int as Int:
            return CGFloat(int)
        default:
            return nil
        }
    }

    static func parseColor(_ value: Any?) -> CGColor? {
        guard let parts = value as? [Any], parts.count == 4 else {
            return nil
        }
        guard let r = cgFloat(parts[0]),
              let g = cgFloat(parts[1]),
              let b = cgFloat(parts[2]),
              let a = cgFloat(parts[3]) else {
            return nil
        }
        return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
    }

    static func parseElement(_ dict: [String: Any]) -> PaperMarkupElement? {
        guard let kind = dict["kind"] as? String else {
            return nil
        }
        switch kind {
        case "shape":
            guard let typeName = dict["type"] as? String,
                  let shape = ShapeConfiguration.shape(named: typeName),
                  let frame = (dict["frame"] as? [String: Any]).flatMap(parseRect),
                  let rotation = cgFloat(dict["rotation"]) else {
                return nil
            }
            let fill = dict["fill"] == nil || dict["fill"] is NSNull ? nil : parseColor(dict["fill"])
            let stroke = dict["stroke"] == nil || dict["stroke"] is NSNull ? nil : parseColor(dict["stroke"])
            let lineWidth = cgFloat(dict["lineWidth"]) ?? 0
            let configuration = ShapeConfiguration(
                type: shape,
                fillColor: fill,
                strokeColor: stroke,
                lineWidth: lineWidth
            )
            return .shape(configuration, frame: frame, rotation: rotation)
        case "line":
            guard let typeName = dict["type"] as? String,
                  let shape = ShapeConfiguration.shape(named: typeName),
                  let start = (dict["from"] as? [String: Any]).flatMap(parsePoint),
                  let end = (dict["to"] as? [String: Any]).flatMap(parsePoint),
                  let startMarker = dict["startMarker"] as? Bool,
                  let endMarker = dict["endMarker"] as? Bool else {
                return nil
            }
            let fill = dict["fill"] == nil || dict["fill"] is NSNull ? nil : parseColor(dict["fill"])
            let stroke = dict["stroke"] == nil || dict["stroke"] is NSNull ? nil : parseColor(dict["stroke"])
            let lineWidth = cgFloat(dict["lineWidth"]) ?? 0
            let configuration = ShapeConfiguration(
                type: shape,
                fillColor: fill,
                strokeColor: stroke,
                lineWidth: lineWidth
            )
            return .line(configuration, from: start, to: end, startMarker: startMarker, endMarker: endMarker)
        case "textbox":
            guard let text = dict["text"] as? String,
                  let frame = (dict["frame"] as? [String: Any]).flatMap(parseRect),
                  let rotation = cgFloat(dict["rotation"]) else {
                return nil
            }
            return .textbox(text, frame: frame, rotation: rotation)
        case "image":
            guard let width = dict["width"] as? Int,
                  let height = dict["height"] as? Int,
                  let frame = (dict["frame"] as? [String: Any]).flatMap(parseRect),
                  let rotation = cgFloat(dict["rotation"]) else {
                return nil
            }
            return .image(width: width, height: height, frame: frame, rotation: rotation)
        case "drawing":
            return .drawing
        default:
            return nil
        }
    }
}

enum PaperMarkupElement: Equatable, Sendable {
    case shape(ShapeConfiguration, frame: CGRect, rotation: CGFloat)
    case line(ShapeConfiguration, from: CGPoint, to: CGPoint, startMarker: Bool, endMarker: Bool)
    case textbox(String, frame: CGRect, rotation: CGFloat)
    case image(width: Int, height: Int, frame: CGRect, rotation: CGFloat)
    case drawing

    static func == (lhs: PaperMarkupElement, rhs: PaperMarkupElement) -> Bool {
        switch (lhs, rhs) {
        case let (.shape(lc, lf, lr), .shape(rc, rf, rr)):
            return shapesEqual(lc, rc) && lf == rf && lr == rr
        case let (.line(lc, ls, le, lsm, lem), .line(rc, rs, re, rsm, rem)):
            return shapesEqual(lc, rc) && ls == rs && le == re && lsm == rsm && lem == rem
        case let (.textbox(lt, lf, lr), .textbox(rt, rf, rr)):
            return lt == rt && lf == rf && lr == rr
        case let (.image(lw, lh, lf, lr), .image(rw, rh, rf, rr)):
            return lw == rw && lh == rh && lf == rf && lr == rr
        case (.drawing, .drawing):
            return true
        default:
            return false
        }
    }

    func applying(_ transform: CGAffineTransform) -> PaperMarkupElement {
        switch self {
        case .shape(let configuration, let frame, let rotation):
            return .shape(configuration, frame: transformRect(frame, transform), rotation: rotation)
        case .line(let configuration, let start, let end, let startMarker, let endMarker):
            return .line(
                configuration,
                from: paperKitApply(transform, to: start),
                to: paperKitApply(transform, to: end),
                startMarker: startMarker,
                endMarker: endMarker
            )
        case .textbox(let text, let frame, let rotation):
            return .textbox(text, frame: transformRect(frame, transform), rotation: rotation)
        case .image(let width, let height, let frame, let rotation):
            return .image(width: width, height: height, frame: transformRect(frame, transform), rotation: rotation)
        case .drawing:
            return .drawing
        }
    }

    func isSupported(by featureSet: FeatureSet) -> Bool {
        switch self {
        case .shape(let configuration, _, _):
            if !featureSet.shapes.contains(configuration.type) {
                return false
            }
            if configuration.fillColor != nil && !featureSet.contains(.shapeFills) {
                // Doc: if strokes are not supported, shapes can always be filled.
                if featureSet.contains(.shapeStrokes) {
                    return false
                }
            }
            if (configuration.strokeColor != nil || configuration.lineWidth > 0)
                && !featureSet.contains(.shapeStrokes) {
                return false
            }
            return true
        case .line(_, _, _, let startMarker, let endMarker):
            if !featureSet.shapes.contains(.line) {
                return false
            }
            let needed: FeatureSet.LineMarkerPositions
            if startMarker && endMarker {
                needed = .double
            } else if startMarker || endMarker {
                needed = .single
            } else {
                needed = .plain
            }
            return featureSet.lineMarkerPositions.contains(needed)
        case .textbox:
            return featureSet.contains(.text)
        case .image:
            return featureSet.contains(.images)
        case .drawing:
            return featureSet.contains(.drawing)
        }
    }

    func jsonObject() -> [String: Any] {
        switch self {
        case .shape(let configuration, let frame, let rotation):
            return [
                "kind": "shape",
                "type": configuration.linuxTypeName,
                "fill": colorJSON(configuration.fillColor) as Any,
                "stroke": colorJSON(configuration.strokeColor) as Any,
                "lineWidth": configuration.lineWidth,
                "frame": PaperMarkup.rectDictionary(frame),
                "rotation": rotation,
            ]
        case .line(let configuration, let start, let end, let startMarker, let endMarker):
            return [
                "kind": "line",
                "type": configuration.linuxTypeName,
                "fill": colorJSON(configuration.fillColor) as Any,
                "stroke": colorJSON(configuration.strokeColor) as Any,
                "lineWidth": configuration.lineWidth,
                "from": PaperMarkup.pointDictionary(start),
                "to": PaperMarkup.pointDictionary(end),
                "startMarker": startMarker,
                "endMarker": endMarker,
            ]
        case .textbox(let text, let frame, let rotation):
            return [
                "kind": "textbox",
                "text": text,
                "frame": PaperMarkup.rectDictionary(frame),
                "rotation": rotation,
            ]
        case .image(let width, let height, let frame, let rotation):
            return [
                "kind": "image",
                "width": width,
                "height": height,
                "frame": PaperMarkup.rectDictionary(frame),
                "rotation": rotation,
            ]
        case .drawing:
            return ["kind": "drawing"]
        }
    }
}

func paperKitUInt32BigEndian(_ data: Data, offset: Int) -> UInt32 {
    let bytes = [UInt8](data[offset..<(offset + 4)])
    return (UInt32(bytes[0]) << 24)
        | (UInt32(bytes[1]) << 16)
        | (UInt32(bytes[2]) << 8)
        | UInt32(bytes[3])
}

private func shapesEqual(_ lhs: ShapeConfiguration, _ rhs: ShapeConfiguration) -> Bool {
    lhs.type == rhs.type
        && lhs.lineWidth == rhs.lineWidth
        && paperKitColorsEqual(lhs.fillColor, rhs.fillColor)
        && paperKitColorsEqual(lhs.strokeColor, rhs.strokeColor)
}

private func colorJSON(_ color: CGColor?) -> Any {
    guard let color else {
        return NSNull()
    }
    let parts = paperKitColorComponents(color)
    return [parts.0, parts.1, parts.2, parts.3]
}

private func transformRect(_ rect: CGRect, _ transform: CGAffineTransform) -> CGRect {
    let corners = [
        paperKitApply(transform, to: CGPoint(x: rect.minX, y: rect.minY)),
        paperKitApply(transform, to: CGPoint(x: rect.maxX, y: rect.minY)),
        paperKitApply(transform, to: CGPoint(x: rect.minX, y: rect.maxY)),
        paperKitApply(transform, to: CGPoint(x: rect.maxX, y: rect.maxY)),
    ]
    let xs = corners.map(\.x)
    let ys = corners.map(\.y)
    let minX = xs.min() ?? 0
    let minY = ys.min() ?? 0
    let maxX = xs.max() ?? 0
    let maxY = ys.max() ?? 0
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}
