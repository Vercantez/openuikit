import Accelerate
import Foundation

func testVImagePermuteARGBToRGBA() {
    var src: [UInt8] = [
        10, 1, 2, 3,
        20, 4, 5, 6
    ]
    var dest = [UInt8](repeating: 0, count: 8)
    var map: [UInt8] = [1, 2, 3, 0]
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 1, width: 2, rowBytes: 8)
            var outb = vImage_Buffer(data: db.baseAddress, height: 1, width: 2, rowBytes: 8)
            let status = vImagePermuteChannels_ARGB8888(&inb, &outb, &map, vImage_Flags(kvImageNoFlags))
            precondition(status == kvImageNoError)
        }
    }
    precondition(dest == [1, 2, 3, 10, 4, 5, 6, 20])
}

func testVImageAffineWarpPlanar8Identity() {
    var src: [UInt8] = [
        10, 20,
        30, 40
    ]
    var dest = [UInt8](repeating: 9, count: 4)
    var identity = vImage_AffineTransform(a: Float(1), b: Float(0), c: Float(0), d: Float(1), tx: Float(0), ty: Float(0))
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 2)
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 2)
            let status = vImageAffineWarp_Planar8(
                &inb, &outb, nil, &identity, 0, vImage_Flags(kvImageNoFlags)
            )
            precondition(status == kvImageNoError)
        }
    }
    precondition(dest == src)
}

func testVImageScalePlanar8Nearest() {
    var src: [UInt8] = [
        10, 20,
        30, 40
    ]
    var scaled = [UInt8](repeating: 0, count: 16)
    src.withUnsafeMutableBytes { sb in
        scaled.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 2)
            var outb = vImage_Buffer(data: db.baseAddress, height: 4, width: 4, rowBytes: 4)
            let status = vImageScale_Planar8(&inb, &outb, nil, vImage_Flags(kvImageNoFlags))
            precondition(status == kvImageNoError)
        }
    }
    precondition(scaled == [
        10, 10, 20, 20,
        10, 10, 20, 20,
        30, 30, 40, 40,
        30, 30, 40, 40
    ])
    var bilinear = [UInt8](repeating: 0, count: 4)
    src.withUnsafeMutableBytes { sb in
        bilinear.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 2)
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 2)
            let status = vImageScale_Planar8(
                &inb, &outb, nil, vImage_Flags(kvImageHighQualityResampling)
            )
            precondition(status == kvImageNoError)
        }
    }
    precondition(bilinear == src)
}

func testVImageRotatePlanar8ZeroAnd180() {
    var src: [UInt8] = [
        1, 2,
        3, 4
    ]
    var dest = [UInt8](repeating: 0, count: 4)
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 2)
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 2)
            let z = vImageRotate_Planar8(&inb, &outb, nil, 0, 0, vImage_Flags(kvImageNoFlags))
            precondition(z == kvImageNoError)
        }
    }
    precondition(dest == src)
    var flipped = [UInt8](repeating: 0, count: 4)
    src.withUnsafeMutableBytes { sb in
        flipped.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 2)
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 2)
            let r = vImageRotate_Planar8(
                &inb, &outb, nil, Float.pi, 0, vImage_Flags(kvImageNoFlags)
            )
            precondition(r == kvImageNoError)
        }
    }
    precondition(flipped == [4, 3, 2, 1])
}

func testVImageAffineWarpARGB8888Identity() {
    var src: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
    var dest = [UInt8](repeating: 0, count: 8)
    var identity = vImage_AffineTransform(a: Float(1), b: Float(0), c: Float(0), d: Float(1), tx: Float(0), ty: Float(0))
    var back: [UInt8] = [0, 0, 0, 0]
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 1, width: 2, rowBytes: 8)
            var outb = vImage_Buffer(data: db.baseAddress, height: 1, width: 2, rowBytes: 8)
            let status = vImageAffineWarp_ARGB8888(
                &inb, &outb, nil, &identity, &back, vImage_Flags(kvImageNoFlags)
            )
            precondition(status == kvImageNoError)
        }
    }
    precondition(dest == src)
}

func testVImageTentConvolvePlanar8Constant() {
    var src: [UInt8] = [
        10, 10, 10,
        10, 10, 10,
        10, 10, 10
    ]
    var dest = [UInt8](repeating: 0, count: 9)
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 3, width: 3, rowBytes: 3)
            var outb = vImage_Buffer(data: db.baseAddress, height: 3, width: 3, rowBytes: 3)
            let status = vImageTentConvolve_Planar8(
                &inb, &outb, nil, 0, 0, 3, 3, 0, vImage_Flags(kvImageEdgeExtend)
            )
            precondition(status == kvImageNoError)
        }
    }
    precondition(dest == src)
}

func testVImageTentConvolveARGB8888Constant() {
    var argb: [UInt8] = [
        10, 1, 2, 3, 10, 1, 2, 3,
        10, 1, 2, 3, 10, 1, 2, 3
    ]
    var argbOut = [UInt8](repeating: 0, count: 16)
    argb.withUnsafeMutableBytes { sb in
        argbOut.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 8)
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 8)
            let status = vImageTentConvolve_ARGB8888(
                &inb, &outb, nil, 0, 0, 3, 3, nil, vImage_Flags(kvImageEdgeExtend)
            )
            precondition(status == kvImageNoError)
        }
    }
    precondition(argbOut == argb)
}

func testVImagePermuteRGB888() {
    var src: [UInt8] = [1, 2, 3, 4, 5, 6]
    var dest = [UInt8](repeating: 0, count: 6)
    var map: [UInt8] = [2, 1, 0]
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 1, width: 2, rowBytes: 6)
            var outb = vImage_Buffer(data: db.baseAddress, height: 1, width: 2, rowBytes: 6)
            let status = vImagePermuteChannels_RGB888(&inb, &outb, &map, vImage_Flags(kvImageNoFlags))
            precondition(status == kvImageNoError)
        }
    }
    precondition(dest == [3, 2, 1, 6, 5, 4])
}

func testVImageAffineWarpDPlanar8Identity() {
    var src: [UInt8] = [
        10, 20,
        30, 40
    ]
    var dest = [UInt8](repeating: 9, count: 4)
    var identity = vImage_AffineTransform_Double(
        a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0
    )
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 2)
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 2)
            let status = vImageAffineWarpD_Planar8(
                &inb, &outb, nil, &identity, 0, vImage_Flags(kvImageNoFlags)
            )
            precondition(status == kvImageNoError)
        }
    }
    precondition(dest == src)
}

func testVImageAffineWarpDARGB8888Identity() {
    var argb: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
    var argbOut = [UInt8](repeating: 0, count: 8)
    var identity = vImage_AffineTransform_Double(
        a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0
    )
    var back: [UInt8] = [0, 0, 0, 0]
    argb.withUnsafeMutableBytes { sb in
        argbOut.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 1, width: 2, rowBytes: 8)
            var outb = vImage_Buffer(data: db.baseAddress, height: 1, width: 2, rowBytes: 8)
            let status = vImageAffineWarpD_ARGB8888(
                &inb, &outb, nil, &identity, &back, vImage_Flags(kvImageNoFlags)
            )
            precondition(status == kvImageNoError)
        }
    }
    precondition(argbOut == argb)
}

func testVImageScaleARGB8888Nearest() {
    var src: [UInt8] = [9, 1, 2, 3]
    var dest = [UInt8](repeating: 0, count: 16)
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 1, width: 1, rowBytes: 4)
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 8)
            let status = vImageScale_ARGB8888(&inb, &outb, nil, vImage_Flags(kvImageNoFlags))
            precondition(status == kvImageNoError)
        }
    }
    precondition(dest == [9, 1, 2, 3, 9, 1, 2, 3, 9, 1, 2, 3, 9, 1, 2, 3])
}

func testVImageRotateARGB8888Zero() {
    var src: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
    var dest = [UInt8](repeating: 0, count: 8)
    var back: [UInt8] = [0, 0, 0, 0]
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 1, width: 2, rowBytes: 8)
            var outb = vImage_Buffer(data: db.baseAddress, height: 1, width: 2, rowBytes: 8)
            let status = vImageRotate_ARGB8888(&inb, &outb, nil, 0, &back, vImage_Flags(kvImageNoFlags))
            precondition(status == kvImageNoError)
        }
    }
    precondition(dest == src)
}
