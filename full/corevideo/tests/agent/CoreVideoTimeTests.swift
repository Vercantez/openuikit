import CoreVideo
import Foundation

func testCVTime() {
    let zero = CVTime()
    precondition(zero.timeValue == 0 && zero.timeScale == 0)
    let scaled = CVTime(timeValue: 30, timeScale: 600)
    precondition(scaled.timeValue == 30 && scaled.timeScale == 600)
    var flagged = CVTime(timeValue: 0, timeScale: 0, flags: CVTimeFlags.isIndefinite.rawValue)
    precondition(flagged.flagOptions.contains(.isIndefinite))
    flagged.flagOptions = []
    precondition(flagged.flags == 0)
    precondition(CVTime.zero == kCVZeroTime)
    precondition(CVTime.indefinite == kCVIndefiniteTime)
    precondition(CVTime.zero != CVTime.indefinite)
}

func testCVSMPTETime() {
    let empty = CVSMPTETime()
    precondition(empty.hours == 0 && empty.frames == 0)
    var typed = CVSMPTETime(
        subframes: 1,
        subframeDivisor: 80,
        counter: 2,
        type: .type24,
        flags: [.valid],
        hours: 1,
        minutes: 2,
        seconds: 3,
        frames: 4
    )
    precondition(typed.typeOptions == .type24)
    precondition(typed.flagOptions.contains(.valid))
    typed.typeOptions = .type30
    typed.flagOptions = [.running]
    precondition(typed.type == CVSMPTETimeType.type30.rawValue)
    let raw = CVSMPTETime(
        subframes: 0,
        subframeDivisor: 0,
        counter: 0,
        type: 0,
        flags: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        frames: 0
    )
    precondition(raw == empty)
}

func testCVTimeStamp() {
    let empty = CVTimeStamp()
    precondition(empty.rateScalar == 1)
    var stamp = CVTimeStamp(
        videoTime: CVTime(timeValue: 10, timeScale: 600),
        hostTime: 42,
        rateScaler: 1.5,
        videoRefreshPeriod: 1001,
        smpteTime: CVSMPTETime(),
        topField: true,
        bottomField: false
    )
    precondition(stamp.flagOptions.contains(.videoTimeValid))
    precondition(stamp.flagOptions.contains(.hostTimeValid))
    precondition(stamp.flagOptions.contains(.rateScalarValid))
    precondition(stamp.flagOptions.contains(.videoRefreshPeriodValid))
    precondition(stamp.flagOptions.contains(.smpteTimeValid))
    precondition(stamp.flagOptions.contains(.topField))
    stamp.flagOptions.insert(.bottomField)
    let full = CVTimeStamp(
        version: 1,
        videoTimeScale: 600,
        videoTime: 10,
        hostTime: 42,
        rateScalar: 1,
        videoRefreshPeriod: 1001,
        smpteTime: CVSMPTETime(),
        flags: 0,
        reserved: 0
    )
    precondition(full.version == 1)
    precondition(empty != full)
}

func testPlanarInfoStructs() {
    let component = CVPlanarComponentInfo(offset: 16, rowBytes: 64)
    precondition(component.offset == 16 && component.rowBytes == 64)
    precondition(CVPlanarComponentInfo() == CVPlanarComponentInfo(offset: 0, rowBytes: 0))
    let planar = CVPlanarPixelBufferInfo(componentInfo: component)
    precondition(planar.componentInfo.offset == 16)
    precondition(CVPlanarPixelBufferInfo() != planar)
    let bi = CVPlanarPixelBufferInfo_YCbCrBiPlanar(
        componentInfoY: component,
        componentInfoCbCr: CVPlanarComponentInfo(offset: 80, rowBytes: 32)
    )
    precondition(bi.componentInfoCbCr.offset == 80)
    precondition(CVPlanarPixelBufferInfo_YCbCrBiPlanar() != bi)
    let tri = CVPlanarPixelBufferInfo_YCbCrPlanar(
        componentInfoY: component,
        componentInfoCb: CVPlanarComponentInfo(offset: 80, rowBytes: 32),
        componentInfoCr: CVPlanarComponentInfo(offset: 112, rowBytes: 32)
    )
    precondition(tri.componentInfoCr.offset == 112)
    precondition(CVPlanarPixelBufferInfo_YCbCrPlanar() != tri)
}

func testFillExtendedPixelsCallBackData() {
    var data = CVFillExtendedPixelsCallBackData()
    precondition(data.version == 0)
    precondition(data.fillCallBack == nil)
    let filled = CVFillExtendedPixelsCallBackData(
        version: 1,
        fillCallBack: { _, _ in true },
        refCon: nil
    )
    precondition(filled.version == 1)
    data.version = 2
    precondition(data.version == 2)
}
