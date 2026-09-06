@_spi(OpenUIKitHost) import SensitiveContentAnalysis
import Foundation

private func scExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testVideoAnalysisHandlerType() {
    let analyzer = SCSensitivityAnalyzer()
    let url = URL(fileURLWithPath: "/tmp/sensitivecontentanalysis-video.mov")
    let handler = analyzer.videoAnalysis(forFileAt: url)
    scExpect(type(of: handler) == SCSensitivityAnalyzer.VideoAnalysisHandler.self, "handler type")
}

func testVideoAnalysisForFileAt() {
    let analyzer = SCSensitivityAnalyzer()
    let url = URL(fileURLWithPath: "/tmp/sensitivecontentanalysis-video.mov")
    let handler = analyzer.videoAnalysis(forFileAt: url)
    scExpect(handler.host_fileURL == url, "handler captures the file URL")
    let other = URL(fileURLWithPath: "/tmp/other.mov")
    let otherHandler = analyzer.videoAnalysis(forFileAt: other)
    scExpect(otherHandler.host_fileURL == other, "each handler stores its own URL")
    scExpect(handler !== otherHandler, "distinct handlers")
}

func testVideoAnalysisHandlerProgress() {
    let analyzer = SCSensitivityAnalyzer()
    let url = URL(fileURLWithPath: "/tmp/sensitivecontentanalysis-video.mov")
    let handler = analyzer.videoAnalysis(forFileAt: url)
    scExpect(handler.progress.totalUnitCount == 1, "fresh progress totalUnitCount is 1")
    scExpect(handler.progress.isCancelled == false, "fresh progress is not cancelled")
    scExpect(handler.progress.isFinished == false, "fresh progress is not finished")
    let replacement = Progress(totalUnitCount: 8)
    handler.progress = replacement
    scExpect(handler.progress === replacement, "progress setter stores the new object")
    scExpect(handler.progress.totalUnitCount == 8, "assigned totalUnitCount")
}

func testHasSensitiveContentFailsClosed() {
    let analyzer = SCSensitivityAnalyzer()
    let url = URL(fileURLWithPath: "/tmp/sensitivecontentanalysis-video.mov")
    let handler = analyzer.videoAnalysis(forFileAt: url)
    let method: () async throws -> SCSensitivityAnalysis = handler.hasSensitiveContent
    _ = method
    let error = handler.host_prepareFailClosed()
    scExpect(error.errorCode == 1, "fail-closed code")
    scExpect(SCLinuxUnavailableError.errorDomain == SCLinuxUnavailableErrorDomain, "fail-closed domain")
    scExpect(handler.progress.isCancelled, "progress is cancelled on fail-closed")
    scExpect(error == SCLinuxUnavailableError(), "same sentinel error the async method throws")
}
