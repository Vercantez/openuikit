// Vector stand-ins for the SF Symbols iOS 26 draws in bar buttons.
// Owner: viewcontroller module (M13 "bars & appearance").
//
// ============================================================================
// DIVERGENCE — READ THIS BEFORE TRUSTING A PIXEL
// ============================================================================
// `UIBarButtonItem(barButtonSystemItem:)` renders an SF Symbol for most of
// its cases on iOS 26. SF Symbols are a proprietary font: OpenUIKit can
// neither vendor them nor synthesize them, exactly like the emoji/CJK gap in
// docs/KNOWN_GAPS.md. What IS portable is measured:
//
//   * the symbol's POINT SIZE. The bounding boxes below are read off real
//     iOS 26.1 (iPhone 16, 17 pt regular symbol configuration) from the
//     `_UIModernBarButton` image sizes — probe with
//     `SIMCTL_CHILD_SIMSCENE_DEBUG=1 scripts/render_sim_scenes.sh`.
//   * which system items are TEXT rather than a symbol: measured, exactly
//     `.edit` ("Edit") and `.save` ("Save"). Those two are exact and are what
//     the fixtures use.
//
// Everything else here is a hand-fitted vector equivalent: same bounding box,
// same stroke weight, same visual idea, NOT the same outline. No golden gates
// them, and none is used by a fixture. An app gets a recognizable, correctly
// sized, correctly colored glyph; a pixel comparison against real iOS would
// not pass. docs/KNOWN_GAPS.md carries the same warning.
//
// Stroke weight: SF Symbols "regular" at 17 pt draws ~1.6 pt strokes with
// round caps and joins (measured off the golden's plus / xmark stems).

struct _BarSymbol {
    /// Bounding box, in points — MEASURED from real iOS 26 (see header).
    let size: CGSize
    /// Draws the glyph into `rect` (already the symbol's bounding box).
    let draw: (CGRect, UIColor) -> Void

    static let strokeWidth: CGFloat = 1.6

    static func forSystemItem(_ item: UIBarButtonItem.SystemItem) -> _BarSymbol? {
        switch item {
        case .edit, .save, .flexibleSpace, .fixedSpace:
            return nil                                   // text / no content
        case .done:
            return _BarSymbol(size: CGSize(width: 18.333, height: 16.333), draw: checkmark)
        case .cancel, .close:
            return _BarSymbol(size: CGSize(width: 17.333, height: 15.333), draw: xmark)
        case .add:
            return _BarSymbol(size: CGSize(width: 18, height: 16), draw: plus)
        case .trash:
            return _BarSymbol(size: CGSize(width: 19, height: 20.667), draw: trash)
        case .action:
            return _BarSymbol(size: CGSize(width: 19, height: 22), draw: shareUp)
        case .refresh:
            return _BarSymbol(size: CGSize(width: 17.333, height: 20), draw: refresh)
        case .reply:
            return _BarSymbol(size: CGSize(width: 21.333, height: 17.333), draw: arrowUturnLeft)
        case .undo:
            return _BarSymbol(size: CGSize(width: 20, height: 17.667), draw: arrowUturnLeft)
        case .redo:
            return _BarSymbol(size: CGSize(width: 20, height: 17.667), draw: arrowUturnRight)
        case .compose:
            return _BarSymbol(size: CGSize(width: 21, height: 20), draw: compose)
        case .organize:
            return _BarSymbol(size: CGSize(width: 23, height: 17.333), draw: folder)
        case .bookmarks:
            return _BarSymbol(size: CGSize(width: 22.667, height: 17.667), draw: book)
        case .search:
            return _BarSymbol(size: CGSize(width: 20.333, height: 18.667), draw: magnifier)
        case .camera:
            return _BarSymbol(size: CGSize(width: 24.667, height: 18), draw: camera)
        case .stop:
            return _BarSymbol(size: CGSize(width: 17, height: 17), draw: stopSquare)
        case .play:
            return _BarSymbol(size: CGSize(width: 15, height: 18), draw: play)
        case .pause:
            return _BarSymbol(size: CGSize(width: 14, height: 18), draw: pause)
        case .rewind:
            return _BarSymbol(size: CGSize(width: 22, height: 16), draw: rewind)
        case .fastForward:
            return _BarSymbol(size: CGSize(width: 22, height: 16), draw: fastForward)
        }
    }

    // MARK: Primitives

    private static func strokePath(_ build: (UIBezierPath) -> Void,
                                   _ color: UIColor, width: CGFloat = strokeWidth) {
        let p = UIBezierPath()
        build(p)
        p.lineWidth = width
        p.lineCapStyle = .round
        p.lineJoinStyle = .round
        p.stroke(with: color)
    }

    // MARK: Glyphs

    static let xmark: (CGRect, UIColor) -> Void = { r, c in
        let i = r.insetBy(dx: r.width * 0.09, dy: r.height * 0.06)
        strokePath({ p in
            p.move(to: CGPoint(x: i.minX, y: i.minY))
            p.addLine(to: CGPoint(x: i.maxX, y: i.maxY))
            p.move(to: CGPoint(x: i.maxX, y: i.minY))
            p.addLine(to: CGPoint(x: i.minX, y: i.maxY))
        }, c)
    }

    static let plus: (CGRect, UIColor) -> Void = { r, c in
        strokePath({ p in
            p.move(to: CGPoint(x: r.minX, y: r.midY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            p.move(to: CGPoint(x: r.midX, y: r.midY - r.width / 2))
            p.addLine(to: CGPoint(x: r.midX, y: r.midY + r.width / 2))
        }, c)
    }

    static let checkmark: (CGRect, UIColor) -> Void = { r, c in
        strokePath({ p in
            p.move(to: CGPoint(x: r.minX + r.width * 0.04, y: r.minY + r.height * 0.52))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.34, y: r.maxY - r.height * 0.06))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.04, y: r.minY + r.height * 0.06))
        }, c, width: strokeWidth * 1.35)
    }

    static let magnifier: (CGRect, UIColor) -> Void = { r, c in
        let d = min(r.width, r.height) * 0.74
        let circle = CGRect(x: r.minX + 0.8, y: r.minY + 0.8, width: d, height: d)
        strokePath({ p in
            p.append(UIBezierPath(ovalIn: circle))
            p.move(to: CGPoint(x: circle.maxX - d * 0.14, y: circle.maxY - d * 0.14))
            p.addLine(to: CGPoint(x: r.maxX - 0.8, y: r.maxY - 0.8))
        }, c)
    }

    static let trash: (CGRect, UIColor) -> Void = { r, c in
        let lidY = r.minY + r.height * 0.19
        let bodyTop = lidY + r.height * 0.07
        strokePath({ p in
            p.move(to: CGPoint(x: r.minX, y: lidY))
            p.addLine(to: CGPoint(x: r.maxX, y: lidY))
            // handle
            p.move(to: CGPoint(x: r.minX + r.width * 0.31, y: lidY))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.31, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.31, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.31, y: lidY))
            // can
            p.move(to: CGPoint(x: r.minX + r.width * 0.12, y: bodyTop))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.20, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.20, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.12, y: bodyTop))
            // ribs
            p.move(to: CGPoint(x: r.midX - r.width * 0.13, y: bodyTop + r.height * 0.11))
            p.addLine(to: CGPoint(x: r.midX - r.width * 0.15, y: r.maxY - r.height * 0.07))
            p.move(to: CGPoint(x: r.midX + r.width * 0.13, y: bodyTop + r.height * 0.11))
            p.addLine(to: CGPoint(x: r.midX + r.width * 0.15, y: r.maxY - r.height * 0.07))
        }, c)
    }

    static let shareUp: (CGRect, UIColor) -> Void = { r, c in
        let boxTop = r.minY + r.height * 0.36
        strokePath({ p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.60))
            p.move(to: CGPoint(x: r.midX - r.width * 0.24, y: r.minY + r.height * 0.22))
            p.addLine(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.midX + r.width * 0.24, y: r.minY + r.height * 0.22))
            p.move(to: CGPoint(x: r.midX - r.width * 0.22, y: boxTop))
            p.addLine(to: CGPoint(x: r.minX, y: boxTop))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX, y: boxTop))
            p.addLine(to: CGPoint(x: r.midX + r.width * 0.22, y: boxTop))
        }, c)
    }

    static let refresh: (CGRect, UIColor) -> Void = { r, c in
        let d = min(r.width, r.height * 0.86)
        let box = CGRect(x: r.midX - d / 2, y: r.maxY - d, width: d, height: d)
        strokePath({ p in
            p.addArc(withCenter: CGPoint(x: box.midX, y: box.midY),
                     radius: d / 2, startAngle: -0.55 * CGFloat.pi,
                     endAngle: 1.30 * CGFloat.pi, clockwise: true)
            let tip = CGPoint(x: box.midX + (d / 2) * 0.588, y: box.midY - (d / 2) * 0.809)
            p.move(to: CGPoint(x: tip.x - d * 0.20, y: tip.y - d * 0.02))
            p.addLine(to: tip)
            p.addLine(to: CGPoint(x: tip.x - d * 0.03, y: tip.y - d * 0.22))
        }, c)
    }

    private static func uturn(_ r: CGRect, _ c: UIColor, mirrored: Bool) {
        let s: CGFloat = mirrored ? -1 : 1
        func x(_ t: CGFloat) -> CGFloat { mirrored ? r.maxX - r.width * t : r.minX + r.width * t }
        strokePath({ p in
            p.move(to: CGPoint(x: x(0.02), y: r.minY + r.height * 0.34))
            p.addLine(to: CGPoint(x: x(0.42), y: r.minY + r.height * 0.34))
            p.addQuadCurve(to: CGPoint(x: x(0.62), y: r.maxY),
                           controlPoint: CGPoint(x: x(1.0), y: r.minY + r.height * 0.40))
            p.move(to: CGPoint(x: x(0.24), y: r.minY))
            p.addLine(to: CGPoint(x: x(0.02), y: r.minY + r.height * 0.34))
            p.addLine(to: CGPoint(x: x(0.24), y: r.minY + r.height * 0.68))
        }, c)
        _ = s
    }

    static let arrowUturnLeft: (CGRect, UIColor) -> Void = { r, c in uturn(r, c, mirrored: false) }
    static let arrowUturnRight: (CGRect, UIColor) -> Void = { r, c in uturn(r, c, mirrored: true) }

    static let compose: (CGRect, UIColor) -> Void = { r, c in
        strokePath({ p in
            p.move(to: CGPoint(x: r.maxX - r.width * 0.30, y: r.minY + r.height * 0.06))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.06))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.06, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.06, y: r.minY + r.height * 0.36))
            // pencil
            p.move(to: CGPoint(x: r.minX + r.width * 0.42, y: r.minY + r.height * 0.56))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.04, y: r.minY))
            p.move(to: CGPoint(x: r.minX + r.width * 0.42, y: r.minY + r.height * 0.56))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.36, y: r.minY + r.height * 0.70))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.50, y: r.minY + r.height * 0.64))
        }, c)
    }

    static let folder: (CGRect, UIColor) -> Void = { r, c in
        strokePath({ p in
            p.move(to: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.30, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.40, y: r.minY + r.height * 0.18))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.18))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.close()
        }, c)
    }

    static let book: (CGRect, UIColor) -> Void = { r, c in
        strokePath({ p in
            p.move(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.16))
            p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            p.move(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.16))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.10),
                           controlPoint: CGPoint(x: r.minX + r.width * 0.22, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.10))
            p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY),
                           controlPoint: CGPoint(x: r.minX + r.width * 0.22, y: r.maxY - r.height * 0.04))
            p.move(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.16))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.10),
                           controlPoint: CGPoint(x: r.maxX - r.width * 0.22, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.10))
            p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY),
                           controlPoint: CGPoint(x: r.maxX - r.width * 0.22, y: r.maxY - r.height * 0.04))
        }, c)
    }

    static let camera: (CGRect, UIColor) -> Void = { r, c in
        let body = CGRect(x: r.minX, y: r.minY + r.height * 0.18,
                          width: r.width, height: r.height * 0.82)
        strokePath({ p in
            p.append(UIBezierPath(roundedRect: body, cornerRadius: r.height * 0.22))
            p.move(to: CGPoint(x: r.minX + r.width * 0.30, y: body.minY))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.38, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.56, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.64, y: body.minY))
            let lens = min(body.width, body.height) * 0.44
            p.append(UIBezierPath(ovalIn: CGRect(x: body.midX - lens / 2,
                                                 y: body.midY - lens / 2,
                                                 width: lens, height: lens)))
        }, c)
    }

    static let stopSquare: (CGRect, UIColor) -> Void = { r, c in
        let p = UIBezierPath(roundedRect: r, cornerRadius: r.width * 0.16)
        p.fill(with: c)
    }

    static let play: (CGRect, UIColor) -> Void = { r, c in
        let p = UIBezierPath()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.close()
        p.fill(with: c)
    }

    static let pause: (CGRect, UIColor) -> Void = { r, c in
        let w = r.width * 0.34
        UIBezierPath(roundedRect: CGRect(x: r.minX, y: r.minY, width: w, height: r.height),
                     cornerRadius: w * 0.3).fill(with: c)
        UIBezierPath(roundedRect: CGRect(x: r.maxX - w, y: r.minY, width: w, height: r.height),
                     cornerRadius: w * 0.3).fill(with: c)
    }

    private static func doubleTriangle(_ r: CGRect, _ c: UIColor, forward: Bool) {
        let w = r.width * 0.5
        for i in 0..<2 {
            let x0 = r.minX + CGFloat(i) * w
            let p = UIBezierPath()
            if forward {
                p.move(to: CGPoint(x: x0, y: r.minY))
                p.addLine(to: CGPoint(x: x0 + w, y: r.midY))
                p.addLine(to: CGPoint(x: x0, y: r.maxY))
            } else {
                p.move(to: CGPoint(x: x0 + w, y: r.minY))
                p.addLine(to: CGPoint(x: x0, y: r.midY))
                p.addLine(to: CGPoint(x: x0 + w, y: r.maxY))
            }
            p.close()
            p.fill(with: c)
        }
    }

    static let rewind: (CGRect, UIColor) -> Void = { r, c in doubleTriangle(r, c, forward: false) }
    static let fastForward: (CGRect, UIColor) -> Void = { r, c in doubleTriangle(r, c, forward: true) }
}

/// Draws a `_BarSymbol` at its natural size.
@preconcurrency @MainActor
final class _BarSymbolView: UIView {
    var symbol: _BarSymbol? { didSet { setNeedsDisplay() } }
    var color: UIColor = .label { didSet { setNeedsDisplay() } }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
    }

    override func draw(_ rect: CGRect) {
        guard let symbol else { return }
        symbol.draw(bounds, color.resolvedColor(with: UITraitCollection.current))
    }
}
