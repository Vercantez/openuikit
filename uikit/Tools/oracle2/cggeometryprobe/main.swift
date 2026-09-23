// CoreGraphics' Int / Double geometry conveniences (CGPoint(x:y:),
// CGSize(width:height:), CGVector(dx:dy:), CGRect(x:y:width:height:) taking
// Swift.Int or Swift.Double), with NetNewsWire's call shape (RSParser
// HTMLMetadata.swift:212, `CGSize(width: width, height: height)` from Double
// operands). The same file runs on the iOS 26.1 simulator (run.sh ->
// transcript-ios26.1.txt) and as the guest probe CGGeometryGuestProbe
// (Tools/guestprobes), whose output must equal the transcript line for line.
#if canImport(UIKit)
import UIKit
#else
import Foundation
import OpenUIKit
#endif

func show(_ label: String, _ values: [CGFloat]) {
    print("CG \(label) " + values.map { String(Double($0)) }.joined(separator: " "))
}

@inline(never) func metadataSize(width: Double, height: Double) -> CGSize {
    CGSize(width: width, height: height)
}

@main
struct CGGeometryProbe {
    static func main() {
        let d: Double = 1.5
        let i: Int = 2
        let p1 = CGPoint(x: d, y: -d)
        let p2 = CGPoint(x: i, y: -3)
        show("point.double", [p1.x, p1.y])
        show("point.int", [p2.x, p2.y])
        let s1 = CGSize(width: d, height: d * 2)
        let s2 = CGSize(width: i, height: i + 1)
        show("size.double", [s1.width, s1.height])
        show("size.int", [s2.width, s2.height])
        let v1 = CGVector(dx: d, dy: 2.25)
        let v2 = CGVector(dx: i, dy: -i)
        show("vector.double", [v1.dx, v1.dy])
        show("vector.int", [v2.dx, v2.dy])
        let r1 = CGRect(x: d, y: 0.25, width: 10.5, height: d)
        let r2 = CGRect(x: i, y: 3, width: 40, height: i * 5)
        show("rect.double", [r1.origin.x, r1.origin.y, r1.size.width, r1.size.height])
        show("rect.int", [r2.origin.x, r2.origin.y, r2.size.width, r2.size.height])
        let m = metadataSize(width: 1200, height: 630)
        show("netnewswire.metadata", [m.width, m.height])
        print("CG_GEOMETRY_DONE")
    }
}
