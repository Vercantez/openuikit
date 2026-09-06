import Accelerate
import Foundation

func testVImageCGeometry() {
    var src: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    var dest = [UInt8](repeating: 0, count: 9)
    src.withUnsafeMutableBytes { sb in
        dest.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 3, width: 3, rowBytes: 3)
            var outb = vImage_Buffer(data: db.baseAddress, height: 3, width: 3, rowBytes: 3)
            precondition(vImageScale_Planar8(&inb, &outb, nil, vImage_Flags(kvImageNoFlags)) == kvImageNoError)
            precondition(vImageCopyBuffer(&inb, &outb, 1, vImage_Flags(kvImageNoFlags)) == kvImageNoError)
            precondition(vImageHorizontalReflect_Planar8(&inb, &outb, vImage_Flags(kvImageNoFlags)) == kvImageNoError)
            precondition(vImageVerticalReflect_Planar8(&inb, &outb, vImage_Flags(kvImageNoFlags)) == kvImageNoError)
            precondition(vImageRotate90_Planar8(&inb, &outb, 0, 0, vImage_Flags(kvImageNoFlags)) == kvImageNoError)
        }
    }
    var color: [UInt8] = [9, 9]
    dest.withUnsafeMutableBytes { db in
        var outb = vImage_Buffer(data: db.baseAddress, height: 3, width: 3, rowBytes: 3)
        _ = vImageBufferFill_CbCr8(&outb, &color, vImage_Flags(kvImageNoFlags))
    }
    var argb: [UInt8] = [10, 1, 2, 3, 20, 4, 5, 6, 30, 7, 7, 8, 40, 9, 9, 9]
    argb.withUnsafeMutableBytes { db in
        var buf = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 8)
        var fill: [UInt8] = [1, 2, 3, 4]
        precondition(vImageBufferFill_ARGB8888(&buf, &fill, vImage_Flags(kvImageNoFlags)) == kvImageNoError)
        _ = vImageScale_ARGB8888(&buf, &buf, nil, vImage_Flags(kvImageNoFlags))
        _ = vImageHorizontalReflect_ARGB8888(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageVerticalReflect_ARGB8888(&buf, &buf, vImage_Flags(kvImageNoFlags))
        _ = vImageRotate90_ARGB8888(&buf, &buf, 0, &fill, vImage_Flags(kvImageNoFlags))
    }
    var initBuf = vImage_Buffer()
    _ = vImageBuffer_Init(&initBuf, 2, 2, 8, vImage_Flags(kvImageNoAllocate))
    let sz = vImageBuffer_GetSize(&initBuf)
    precondition(sz.width == 2)
}

func testVImageCHistogramAlphaConvert() {
    var src: [UInt8] = [0, 1, 2, 255]
    var hist = [vImagePixelCount](repeating: 0, count: 256)
    src.withUnsafeMutableBytes { sb in
        var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 2)
        precondition(vImageHistogramCalculation_Planar8(&inb, &hist, vImage_Flags(kvImageNoFlags)) == kvImageNoError)
        precondition(hist[1] >= 1)
        var dest: [UInt8] = [0, 0, 0, 0]
        dest.withUnsafeMutableBytes { db in
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 2)
            _ = vImageBoxConvolve_Planar8(&inb, &outb, nil, 0, 0, 3, 3, 0, vImage_Flags(kvImageEdgeExtend))
        }
    }
    var top: [UInt8] = [128, 10, 20, 30, 128, 10, 20, 30, 128, 10, 20, 30, 128, 10, 20, 30]
    var bottom = [UInt8](repeating: 200, count: 16)
    var blended = [UInt8](repeating: 0, count: 16)
    top.withUnsafeMutableBytes { tb in
        bottom.withUnsafeMutableBytes { bb in
            blended.withUnsafeMutableBytes { db in
                var t = vImage_Buffer(data: tb.baseAddress, height: 2, width: 2, rowBytes: 8)
                var b = vImage_Buffer(data: bb.baseAddress, height: 2, width: 2, rowBytes: 8)
                var d = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 8)
                _ = vImageAlphaBlend_ARGB8888(&t, &b, &d, vImage_Flags(kvImageNoFlags))
                _ = vImagePremultiplyData_ARGB8888(&t, &d, vImage_Flags(kvImageNoFlags))
                _ = vImageUnpremultiplyData_ARGB8888(&t, &d, vImage_Flags(kvImageNoFlags))
            }
        }
    }
    var planar: [UInt8] = [0, 128, 255, 64]
    var floats = [Float](repeating: 0, count: 4)
    planar.withUnsafeMutableBytes { sb in
        floats.withUnsafeMutableBytes { db in
            var inb = vImage_Buffer(data: sb.baseAddress, height: 2, width: 2, rowBytes: 2)
            var outb = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 8)
            _ = vImageConvert_Planar8toPlanarF(&inb, &outb, 1, 0, vImage_Flags(kvImageNoFlags))
            _ = vImageConvert_PlanarFtoPlanar8(&outb, &inb, 1, 0, vImage_Flags(kvImageNoFlags))
        }
    }
    var a: [UInt8] = [255, 255, 255, 255]
    var r: [UInt8] = [1, 2, 3, 4]
    var g: [UInt8] = [5, 6, 7, 8]
    var bch: [UInt8] = [9, 9, 9, 9]
    var argb = [UInt8](repeating: 0, count: 16)
    a.withUnsafeMutableBytes { ab in
        r.withUnsafeMutableBytes { rb in
            g.withUnsafeMutableBytes { gb in
                bch.withUnsafeMutableBytes { bb in
                    argb.withUnsafeMutableBytes { db in
                        var A = vImage_Buffer(data: ab.baseAddress, height: 2, width: 2, rowBytes: 2)
                        var R = vImage_Buffer(data: rb.baseAddress, height: 2, width: 2, rowBytes: 2)
                        var G = vImage_Buffer(data: gb.baseAddress, height: 2, width: 2, rowBytes: 2)
                        var B = vImage_Buffer(data: bb.baseAddress, height: 2, width: 2, rowBytes: 2)
                        var D = vImage_Buffer(data: db.baseAddress, height: 2, width: 2, rowBytes: 8)
                        _ = vImageConvert_Planar8toARGB8888(&A, &R, &G, &B, &D, vImage_Flags(kvImageNoFlags))
                        _ = vImageConvert_ARGB8888toPlanar8(&D, &A, &R, &G, &B, vImage_Flags(kvImageNoFlags))
                    }
                }
            }
        }
    }
    var u16: [UInt16] = [0x0102, 0x0304]
    u16.withUnsafeMutableBytes { sb in
        var buf = vImage_Buffer(data: sb.baseAddress, height: 1, width: 2, rowBytes: 4)
        _ = vImageByteSwap_Planar16U(&buf, &buf, vImage_Flags(kvImageNoFlags))
    }
}

func testDocumentedVImageConstants() {
    precondition(kvImageNoError == 0)
    precondition(kvImageRoiLargerThanInputBuffer == -21766)
    precondition(kvImageInvalidKernelSize == -21767)
    precondition(kvImageInvalidEdgeStyle == -21768)
    precondition(kvImageInvalidOffset_X == -21769)
    precondition(kvImageInvalidOffset_Y == -21770)
    precondition(kvImageMemoryAllocationError == -21771)
    precondition(kvImageNullPointerArgument == -21772)
    precondition(kvImageInvalidParameter == -21773)
    precondition(kvImageBufferSizeMismatch == -21774)
    precondition(kvImageUnknownFlagsBit == -21775)
    precondition(kvImageInternalError == -21776)
    precondition(kvImageInvalidRowBytes == -21777)
    precondition(kvImageInvalidImageFormat == -21778)
    precondition(kvImageColorSyncIsAbsent == -21779)
    precondition(kvImageOutOfPlaceOperationRequired == -21780)
    precondition(kvImageInvalidCVImageFormat == -21781)
    precondition(kvImageUnsupportedConversion == -21782)
    precondition(kvImageCoreVideoIsAbsent == -21783)
    precondition(kvImageInvalidImageObject == -21784)
    precondition(kvImageNoFlags == 0)
    precondition(kvImageLeaveAlphaUnchanged == 1)
    precondition(kvImageCopyInPlace == 2)
    precondition(kvImageBackgroundColorFill == 4)
    precondition(kvImageEdgeExtend == 8)
    precondition(kvImageDoNotTile == 16)
    precondition(kvImageHighQualityResampling == 32)
    precondition(kvImageTruncateKernel == 64)
    precondition(kvImageGetTempBufferSize == 128)
    precondition(kvImagePrintDiagnosticsToConsole == 256)
    precondition(kvImageNoAllocate == 512)
    precondition(kvImageHDRContent == 1024)
    precondition(kvImageDoNotClamp == 2048)
    precondition(kvImageUseFP16Accumulator == 4096)
    precondition(kvImage_PNG_FILTER_VALUE_NONE == 0)
    precondition(kvImage_PNG_FILTER_VALUE_SUB == 1)
    precondition(kvImage_PNG_FILTER_VALUE_UP == 2)
    precondition(kvImage_PNG_FILTER_VALUE_AVG == 3)
    precondition(kvImage_PNG_FILTER_VALUE_PAETH == 4)
    precondition(kvImageConvert_DitherNone == 0)
    precondition(kvImageConvert_DitherOrdered == 1)
    precondition(kvImageConvert_DitherOrderedReproducible == 2)
    precondition(kvImageConvert_DitherFloydSteinberg == 3)
    precondition(kvImageConvert_DitherAtkinson == 4)
    precondition(kvImageNoInterpolation.rawValue == 0)
    precondition(kvImageFullInterpolation.rawValue == 1)
    precondition(kvImageHalfInterpolation.rawValue == 2)
    precondition(kvImageInterpolationNearest == 0)
    precondition(kvImageInterpolationLinear == 1)
    precondition(kvImageGamma_UseGammaValue == 0)
    precondition(kvImageGamma_UseGammaValue_half_precision == 1)
    precondition(vDSP_HANN_DENORM == 0)
    precondition(vDSP_HANN_NORM == 1)
    precondition(vDSP_HALF_WINDOW == 2)
    precondition(FFT_FORWARD == 1)
    precondition(FFT_INVERSE == -1)
    precondition(FFT_RADIX2 == 0)
    precondition(FFT_RADIX3 == 1)
    precondition(FFT_RADIX5 == 2)
    precondition(kFFTDirection_Forward == 1)
    precondition(kFFTDirection_Inverse == -1)
    precondition(kFFTRadix2 == 0)
    precondition(kFFTRadix3 == 1)
    precondition(kFFTRadix5 == 2)
    precondition(LA_SUCCESS == 0)
    precondition(vDSP_DCT_Type.II.rawValue == 2)
    precondition(vDSP_DFT_Direction.FORWARD.rawValue == 1)
    precondition(vDSP_DFT_Direction.INVERSE.rawValue == -1)
}

func testVImageErrorAndOptions() {
    precondition(vImage.Error.noError.rawValue == 0)
    precondition(vImage.Error.roiLargerThanInputBuffer.rawValue == -21766)
    precondition(vImage.Error.invalidKernelSize.rawValue == -21767)
    precondition(vImage.Error.invalidEdgeStyle.rawValue == -21768)
    precondition(vImage.Error.invalidOffset_X.rawValue == -21769)
    precondition(vImage.Error.invalidOffset_Y.rawValue == -21770)
    precondition(vImage.Error.memoryAllocationError.rawValue == -21771)
    precondition(vImage.Error.nullPointerArgument.rawValue == -21772)
    precondition(vImage.Error.invalidParameter.rawValue == -21773)
    precondition(vImage.Error.bufferSizeMismatch.rawValue == -21774)
    precondition(vImage.Error.unknownFlagsBit.rawValue == -21775)
    precondition(vImage.Error.internalError.rawValue == -21776)
    precondition(vImage.Error.invalidRowBytes.rawValue == -21777)
    precondition(vImage.Error.invalidImageFormat.rawValue == -21778)
    precondition(vImage.Error.colorSyncIsAbsent.rawValue == -21779)
    precondition(vImage.Error.outOfPlaceOperationRequired.rawValue == -21780)
    precondition(vImage.Error.invalidCVImageFormat.rawValue == -21781)
    precondition(vImage.Error.unsupportedConversion.rawValue == -21782)
    precondition(vImage.Error.coreVideoIsAbsent.rawValue == -21783)
    precondition(vImage.Error.invalidImageObject.rawValue == -21784)
    precondition(vImage.Error(vImageError: kvImageNoError) == .noError)
    precondition(vImage.Error(rawValue: 0) == .noError)
    precondition(vImage.Options.noFlags.rawValue == vImage_Flags(kvImageNoFlags))
    precondition(vImage.Options.leaveAlphaUnchanged.rawValue == vImage_Flags(kvImageLeaveAlphaUnchanged))
    precondition(vImage.Options.copyInPlace.rawValue == vImage_Flags(kvImageCopyInPlace))
    precondition(vImage.Options.backgroundColorFill.rawValue == vImage_Flags(kvImageBackgroundColorFill))
    precondition(vImage.Options.imageExtend.rawValue == vImage_Flags(kvImageEdgeExtend))
    precondition(vImage.Options.doNotTile.rawValue == vImage_Flags(kvImageDoNotTile))
    precondition(vImage.Options.highQualityResampling.rawValue == vImage_Flags(kvImageHighQualityResampling))
    precondition(vImage.Options.truncateKernel.rawValue == vImage_Flags(kvImageTruncateKernel))
    precondition(vImage.Options.getTempBufferSize.rawValue == vImage_Flags(kvImageGetTempBufferSize))
    precondition(vImage.Options.printDiagnosticsToConsole.rawValue == vImage_Flags(kvImagePrintDiagnosticsToConsole))
    precondition(vImage.Options.noAllocate.rawValue == vImage_Flags(kvImageNoAllocate))
    precondition(vImage.Options.hdrContent.rawValue == vImage_Flags(kvImageHDRContent))
    precondition(vImage.Options.doNotClamp.rawValue == vImage_Flags(kvImageDoNotClamp))
    let opts: vImage.Options = [.noFlags, .imageExtend]
    precondition(opts.contains(.imageExtend))
    precondition(!opts.isEmpty)
    _ = opts.union(.doNotTile)
    _ = opts.intersection(.imageExtend)
    _ = opts.subtracting(.noFlags)
    _ = vImage.Options()
    _ = vImage.ConvolutionKernel.gaussian1Dx3
    _ = vImage.ConvolutionKernel.gaussian1Dx5
    _ = vImage.ConvolutionKernel.gaussian1Dx7
    precondition(vImage.Planar8.channelCount == 1)
    precondition(vImage.Planar8.bitCountPerPixel == 8)
    precondition(vImage.Planar8.bitCountPerComponent == 8)
    precondition(vImage.PlanarF.channelCount == 1)
    precondition(vImage.Interleaved8x4.channelCount == 4)
    precondition(vImage.Interleaved8x3.channelCount == 3)
    precondition(vImage.Interleaved8x2.channelCount == 2)
    precondition(vImage.InterleavedFx4.channelCount == 4)
    precondition(vImage.Size(width: 2, height: 3).width == 2)
    precondition(vImage.Planar8x2.planeCount == 2)
    precondition(vImage.Planar8x2.bitCountPerPlanarPixel == 8)
    precondition(vImage.Planar8x3.planeCount == 3)
    precondition(vImage.Planar8x3.bitCountPerPlanarPixel == 8)
    precondition(vImage.Planar8x4.planeCount == 4)
    precondition(vImage.Planar8x4.bitCountPerPlanarPixel == 8)
    precondition(vImage.PlanarFx2.planeCount == 2)
    precondition(vImage.PlanarFx2.bitCountPerPlanarPixel == 32)
    precondition(vImage.PlanarFx3.planeCount == 3)
    precondition(vImage.PlanarFx3.bitCountPerPlanarPixel == 32)
    precondition(vImage.PlanarFx4.planeCount == 4)
    precondition(vImage.PlanarFx4.bitCountPerPlanarPixel == 32)
}

func testPixelBufferOps() {
    let size = vImage.Size(width: 2, height: 2)
    let src = vImage.PixelBuffer<vImage.Planar8>(pixelValues: [1, 2, 3, 4], size: size)
    precondition(src.width == 2)
    precondition(src.height == 2)
    precondition(src.count == 4)
    precondition(src.channelCount == 1)
    let dest = vImage.PixelBuffer<vImage.Planar8>(size: size)
    src.copy(to: dest)
    precondition(dest.storage == [1, 2, 3, 4])
    src.scale(destination: dest)
    src.reflect(over: .horizontal, destination: dest)
    src.rotate(.clockwise0Degrees, backgroundColor: 0, destination: dest)
    src.boxConvolve(kernelSize: vImage.Size(width: 3, height: 3), edgeMode: .extend, destination: dest)
    src.tentConvolve(kernelSize: vImage.Size(width: 3, height: 3), edgeMode: .extend, destination: dest)
    _ = src.boxConvolved(kernelSize: vImage.Size(width: 3, height: 3), edgeMode: .extend)
    src.contrastStretch(destination: dest)
    src.equalizeHistogram(destination: dest)
    let hist = src.histogram()
    precondition(hist.count == 256)
    let destF = vImage.PixelBuffer<vImage.PlanarF>(size: size)
    src.convert(to: destF)
    destF.convert(to: dest)
    src.withUnsafeBufferPointer { precondition($0.count == 4) }
    src.withUnsafeVImageBuffer { buf in
        precondition(buf.width == 2)
    }
    _ = vImage.PixelBuffer<vImage.Planar8>(size: size, pixelFormat: vImage.Planar8.self)
    _ = vImage.PixelBuffer<vImage.PlanarF>(pixelValues: [Float]([0, 1, 0, 1]), size: size)
    precondition(src.byteCountPerPixel == 1)
    precondition(src.columnCount == 2)
    precondition(src.rowCount == 2)
    precondition(src.leadingDimension == src.rowStride)
    precondition(src.accelerateMatrixOrder == .rowMajor)
    precondition(src.array == [1, 2, 3, 4])
    src.withUnsafePointerToVImageBuffer { ptr in
        precondition(ptr.pointee.width == 2)
    }
    _ = src.tentConvolved(kernelSize: vImage.Size(width: 3, height: 3), edgeMode: .extend)
    src.colorThreshold(2, destination: dest)
    src.applyLookup([UInt8](0...255), destination: dest)
    src.applyLookup(table: [UInt8](0...255), destination: dest)
    let destFLookup = vImage.PixelBuffer<vImage.PlanarF>(size: size)
    src.applyLookup([Float](repeating: 0.5, count: 256), destination: destFLookup)
    src.premultiply(alpha: src)
    src.unpremultiply(alpha: src)
    let argb = vImage.PixelBuffer<vImage.Interleaved8x4>(
        pixelValues: [128, 10, 20, 30, 255, 1, 2, 3, 64, 4, 5, 6, 32, 7, 8, 9],
        size: size
    )
    argb.premultiply(channelOrdering: .ARGB)
    argb.unpremultiply(channelOrdering: .ARGB)
    argb.applyLookup(
        alphaTable: [UInt8](0...255),
        redTable: [UInt8](0...255),
        greenTable: [UInt8](0...255),
        blueTable: [UInt8](0...255),
        destination: argb
    )
}

func testBNNSCreateFailClosed() {
    var params = BNNSLayerParametersActivation()
    precondition(BNNSFilterCreateLayerActivation(&params, nil) == nil)
    var arith = BNNSLayerParametersArithmetic()
    precondition(BNNSFilterCreateLayerArithmetic(&arith, nil) == nil)
    var conv = BNNSLayerParametersConvolution()
    precondition(BNNSFilterCreateLayerConvolution(&conv, nil) == nil)
    precondition(BNNSFilterCreateLayerTransposedConvolution(&conv, nil) == nil)
    var fc = BNNSLayerParametersFullyConnected()
    precondition(BNNSFilterCreateLayerFullyConnected(&fc, nil) == nil)
    var dropout = BNNSLayerParametersDropout()
    precondition(BNNSFilterCreateLayerDropout(&dropout, nil) == nil)
    var embed = BNNSLayerParametersEmbedding()
    precondition(BNNSFilterCreateLayerEmbedding(&embed, nil) == nil)
    var gram = BNNSLayerParametersGram()
    precondition(BNNSFilterCreateLayerGram(&gram, nil) == nil)
    var pool = BNNSLayerParametersPooling()
    precondition(BNNSFilterCreateLayerPooling(&pool, nil) == nil)
    var red = BNNSLayerParametersReduction()
    precondition(BNNSFilterCreateLayerReduction(&red, nil) == nil)
    var resize = BNNSLayerParametersResize()
    precondition(BNNSFilterCreateLayerResize(&resize, nil) == nil)
    var pad = BNNSLayerParametersPadding()
    precondition(BNNSFilterCreateLayerPadding(&pad, nil) == nil)
    var perm = BNNSLayerParametersPermute()
    precondition(BNNSFilterCreateLayerPermute(&perm, nil) == nil)
    var mm = BNNSLayerParametersBroadcastMatMul()
    precondition(BNNSFilterCreateLayerBroadcastMatMul(&mm, nil) == nil)
    var tc = BNNSLayerParametersTensorContraction()
    precondition(BNNSFilterCreateLayerTensorContraction(&tc, nil) == nil)
    var mha = BNNSLayerParametersMultiheadAttention()
    precondition(BNNSFilterCreateLayerMultiheadAttention(&mha, nil) == nil)
    var norm = BNNSLayerParametersNormalization()
    precondition(BNNSFilterCreateLayerNormalization(BNNSFilterType(rawValue: 0), &norm, nil) == nil)
    var lossDummy = 0
    withUnsafeBytes(of: &lossDummy) { raw in
        precondition(BNNSFilterCreateLayerLoss(raw.baseAddress!, nil) == nil)
    }
    var inDesc = BNNSImageStackDescriptor()
    var outDesc = BNNSImageStackDescriptor()
    var convLayer = BNNSConvolutionLayerParameters()
    precondition(BNNSFilterCreateConvolutionLayer(&inDesc, &outDesc, &convLayer, nil) == nil)
    var vecIn = BNNSVectorDescriptor()
    var vecOut = BNNSVectorDescriptor()
    var fcLayer = BNNSFullyConnectedLayerParameters()
    precondition(BNNSFilterCreateFullyConnectedLayer(&vecIn, &vecOut, &fcLayer, nil) == nil)
    var poolLayer = BNNSPoolingLayerParameters()
    precondition(BNNSFilterCreatePoolingLayer(&inDesc, &outDesc, &poolLayer, nil) == nil)
    var act = BNNSActivation()
    precondition(BNNSFilterCreateVectorActivationLayer(&vecIn, &vecOut, &act, nil) == nil)
    precondition(BNNSCreateRandomGenerator(BNNSRandomGeneratorMethod(rawValue: 0), nil) == nil)
    precondition(BNNSCreateRandomGeneratorWithSeed(BNNSRandomGeneratorMethod(rawValue: 0), 1, nil) == nil)
    precondition(BNNSCreateNearestNeighbors(1, 1, 1, BNNSDataTypeFloat32, nil) == nil)
}
