#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testRecognizeTextFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNRecognizeTextRequest()
    visionExpectEqual(request.recognitionLevel, .accurate, "text level")
    visionExpectEqual(try! request.supportedRecognitionLanguages(), [], "no languages")
    request.customWords = ["OpenUIKit"]
    visionExpectEqual(request.customWords, ["OpenUIKit"], "custom words")
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.domain, VNErrorDomain, "ml domain")
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "ml invalidModel")
        visionExpect(request.results == nil, "ml results nil")
    }
}

func testDetectFaceRectanglesFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNDetectFaceRectanglesRequest()
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "face invalidModel")
        visionExpect(request.results == nil, "face results nil")
    }
}

func testClassifyImageFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNClassifyImageRequest()
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "classify invalidModel")
        visionExpect(request.results == nil, "classify results nil")
    }
    do {
        _ = try VNClassifyImageRequest.knownClassifications(forRevision: 1)
        visionExpect(false, "classifications should fail")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "known classifications")
    }
}

func testHumanBodyPoseFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNDetectHumanBodyPoseRequest()
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "pose invalidModel")
        visionExpect(request.results == nil, "pose results nil")
    }
}

func testCoreMLFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNCoreMLRequest(completionHandler: nil)
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "coreml invalidModel")
        visionExpect(request.results == nil, "coreml results nil")
    }
    do {
        _ = try VNCoreMLModel(for: MLModel())
        visionExpect(false, "coreml model should fail")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "coreml model")
    }
}
