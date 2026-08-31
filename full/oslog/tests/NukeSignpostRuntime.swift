import Foundation
import os

enum ImagePipeline {
    struct Configuration {
        static let isSignpostLoggingEnabled = true
    }
}

private final class ImageTask {}

@main
private struct NukeSignpostRuntime {
    static func main() async throws {
        let task = ImageTask()
        signpost(task, "NukeEvent", .event, "image-ready")

        let syncValue = signpost("NukeSync") { 42 }
        precondition(syncValue == 42)

        let asyncWork: @Sendable () async throws -> Int = { 84 }
        let asyncValue = try await signpost("NukeAsync", asyncWork)
        precondition(asyncValue == 84)

        precondition(Formatter.bytes(1_024).isEmpty == false)
        print("OSLOG_UNTOUCHED_NUKE_RUNTIME_OK sync=42 async=84")
    }
}
