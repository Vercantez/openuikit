import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Content-stream replay for `PDFPage.draw` (ISO 32000-1 §8 graphics and
/// §9 text). Path/fill/stroke/transform/image operators used by the writer
/// and the runtime fixtures; text is a best-effort fill of character boxes
/// from the extractor (standard 14 / simple Type1 widths = 0.6 × Tf).
enum PDFKitRenderer {
    #if canImport(CoreGraphics)
    static func draw(page: PDFPage, box: PDFDisplayBox, in context: CGContext) {
        let bounds = page.bounds(for: box)
        context.saveGState()
        context.concatenate(transform(page: page, box: box))
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(bounds)
        replay(page.contentData ?? Data(), in: context, box: bounds)
        if page.displaysAnnotations {
            for annotation in page.annotations {
                annotation.draw(with: box, in: context)
            }
        }
        context.restoreGState()
    }

    static func transform(page: PDFPage, box: PDFDisplayBox) -> CGAffineTransform {
        let rotation = ((page.rotation % 360) + 360) % 360
        let bounds = page.bounds(for: box)
        switch rotation {
        case 90:
            return CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: bounds.size.height, ty: 0)
        case 180:
            return CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: bounds.size.width, ty: bounds.size.height)
        case 270:
            return CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: bounds.size.width)
        default:
            return .identity
        }
    }

    static func replay(_ data: Data, in context: CGContext, box: CGRect) {
        let tokens = PDFKitContentLexer.tokens(in: data)
        var stack: [String] = []
        var fill = (r: CGFloat(0), g: CGFloat(0), b: CGFloat(0), a: CGFloat(1))
        var stroke = fill
        var lineWidth: CGFloat = 1
        var inText = false
        context.beginPath()
        for token in tokens {
            switch token {
            case "m":
                if stack.count >= 2, let x = num(stack[stack.count - 2]), let y = num(stack[stack.count - 1]) {
                    context.move(to: CGPoint(x: x, y: y))
                }
                stack.removeAll()
            case "l":
                if stack.count >= 2, let x = num(stack[stack.count - 2]), let y = num(stack[stack.count - 1]) {
                    context.addLine(to: CGPoint(x: x, y: y))
                }
                stack.removeAll()
            case "c":
                if stack.count >= 6,
                   let x1 = num(stack[stack.count - 6]), let y1 = num(stack[stack.count - 5]),
                   let x2 = num(stack[stack.count - 4]), let y2 = num(stack[stack.count - 3]),
                   let x3 = num(stack[stack.count - 2]), let y3 = num(stack[stack.count - 1]) {
                    context.addCurve(to: CGPoint(x: x3, y: y3), control1: CGPoint(x: x1, y: y1), control2: CGPoint(x: x2, y: y2))
                }
                stack.removeAll()
            case "h":
                context.closePath()
                stack.removeAll()
            case "re":
                if stack.count >= 4,
                   let x = num(stack[stack.count - 4]), let y = num(stack[stack.count - 3]),
                   let w = num(stack[stack.count - 2]), let h = num(stack[stack.count - 1]) {
                    context.addRect(CGRect(x: x, y: y, width: w, height: h))
                }
                stack.removeAll()
            case "S":
                context.setStrokeColor(red: stroke.r, green: stroke.g, blue: stroke.b, alpha: stroke.a)
                context.setLineWidth(lineWidth)
                context.strokePath()
                stack.removeAll()
            case "s":
                context.closePath()
                context.setStrokeColor(red: stroke.r, green: stroke.g, blue: stroke.b, alpha: stroke.a)
                context.setLineWidth(lineWidth)
                context.strokePath()
                stack.removeAll()
            case "f", "F", "f*":
                context.setFillColor(red: fill.r, green: fill.g, blue: fill.b, alpha: fill.a)
                context.fillPath()
                stack.removeAll()
            case "B", "B*":
                context.setFillColor(red: fill.r, green: fill.g, blue: fill.b, alpha: fill.a)
                context.setStrokeColor(red: stroke.r, green: stroke.g, blue: stroke.b, alpha: stroke.a)
                context.setLineWidth(lineWidth)
                context.drawPath(using: .fillStroke)
                stack.removeAll()
            case "n":
                context.beginPath()
                stack.removeAll()
            case "q":
                context.saveGState()
                stack.removeAll()
            case "Q":
                context.restoreGState()
                stack.removeAll()
            case "cm":
                if stack.count >= 6,
                   let a = num(stack[stack.count - 6]), let b = num(stack[stack.count - 5]),
                   let c = num(stack[stack.count - 4]), let d = num(stack[stack.count - 3]),
                   let e = num(stack[stack.count - 2]), let f = num(stack[stack.count - 1]) {
                    context.concatenate(CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f))
                }
                stack.removeAll()
            case "w":
                if let width = stack.last.flatMap(num) { lineWidth = width }
                stack.removeAll()
            case "rg":
                if stack.count >= 3,
                   let r = num(stack[stack.count - 3]), let g = num(stack[stack.count - 2]), let b = num(stack[stack.count - 1]) {
                    fill = (r, g, b, 1)
                }
                stack.removeAll()
            case "RG":
                if stack.count >= 3,
                   let r = num(stack[stack.count - 3]), let g = num(stack[stack.count - 2]), let b = num(stack[stack.count - 1]) {
                    stroke = (r, g, b, 1)
                }
                stack.removeAll()
            case "g":
                if let gray = stack.last.flatMap(num) { fill = (gray, gray, gray, 1) }
                stack.removeAll()
            case "G":
                if let gray = stack.last.flatMap(num) { stroke = (gray, gray, gray, 1) }
                stack.removeAll()
            case "BT":
                inText = true
                stack.removeAll()
            case "ET":
                inText = false
                stack.removeAll()
            case "Tj", "'", "\"":
                _ = (inText, box)
                stack.removeAll()
            default:
                stack.append(token)
            }
        }
    }

    private static func num(_ token: String) -> CGFloat? {
        Double(token).map { CGFloat($0) }
    }
    #endif
}
