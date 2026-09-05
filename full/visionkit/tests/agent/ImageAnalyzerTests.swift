@_spi(OpenUIKitHost) import VisionKit
import Foundation

func testImageAnalyzerAvailability() {
    precondition(ImageAnalyzer.isSupported == false)
    precondition(ImageAnalyzer.supportedTextRecognitionLanguages.isEmpty)
    let analyzer = ImageAnalyzer()
    _ = analyzer
}

func testImageAnalyzerConfiguration() {
    var configuration = ImageAnalyzer.Configuration(.text)
    precondition(configuration.analysisTypes.contains(.text))
    precondition(!configuration.analysisTypes.contains(.visualLookUp))
    precondition(configuration.locales.isEmpty)
    configuration.locales = ["en-US"]
    precondition(configuration.locales == ["en-US"])
    let lookUp = ImageAnalyzer.Configuration([.visualLookUp, .machineReadableCode])
    precondition(lookUp.analysisTypes.contains(.visualLookUp))
    precondition(lookUp.analysisTypes.contains(.machineReadableCode))
}

func testImageAnalysisResults() {
    let analysis = ImageAnalysis.hostFixture(
        transcript: "HELLO",
        resultTypes: [.text]
    )
    precondition(analysis.transcript == "HELLO")
    precondition(analysis.hasResults(for: .text))
    precondition(!analysis.hasResults(for: .visualLookUp))
    precondition(analysis.hasResults(for: [.text, .machineReadableCode]))
    precondition(!analysis.hasResults(for: [.visualLookUp, .machineReadableCode]))
    let empty = ImageAnalysis.hostFixture(transcript: "", resultTypes: [])
    precondition(empty.transcript.isEmpty)
    precondition(!empty.hasResults(for: .text))
}
