//===----------------------------------------------------------------------===//
// Image / sequence request handlers. Data and URL sources are accepted;
// Apple ML execution is fail-closed.
//===----------------------------------------------------------------------===//

open class VNImageRequestHandler: NSObject, @unchecked Sendable {
    internal let imageData: Data?
    internal let imageURL: URL?
    internal let options: [VNImageOption: Any]

    public init(data imageData: Data, options: [VNImageOption: Any] = [:]) {
        self.imageData = imageData
        self.imageURL = nil
        self.options = options
        super.init()
    }

    public init(url imageURL: URL, options: [VNImageOption: Any] = [:]) {
        self.imageData = nil
        self.imageURL = imageURL
        self.options = options
        super.init()
    }

    public convenience init(URL imageURL: URL, options: [VNImageOption: Any] = [:]) {
        self.init(url: imageURL, options: options)
    }

    public func perform(_ requests: [VNRequest]) throws {
        try visionPerform(requests, imageData: imageData, imageURL: imageURL)
    }
}

open class VNSequenceRequestHandler: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public func perform(_ requests: [VNRequest], onImageData imageData: Data) throws {
        try visionPerform(requests, imageData: imageData, imageURL: nil)
    }

    public func perform(_ requests: [VNRequest], onImageURL imageURL: URL) throws {
        try visionPerform(requests, imageData: nil, imageURL: imageURL)
    }
}

internal func visionPerform(
    _ requests: [VNRequest],
    imageData: Data?,
    imageURL: URL?
) throws {
    if requests.isEmpty {
        return
    }

    if let imageData, imageData.isEmpty {
        let error = visionError(.invalidImage, "Vision image data is empty")
        for request in requests {
            request.finish(error: error)
        }
        throw error
    }

    if let imageURL {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: imageURL.path,
            isDirectory: &isDirectory
        )
        if !exists || isDirectory.boolValue {
            let error = visionError(.ioError, "Vision image URL is missing: \(imageURL.path)")
            for request in requests {
                request.finish(error: error)
            }
            throw error
        }
    }

    var firstError: (any Error)?
    for request in requests {
        if request.cancelled {
            let error = visionError(.requestCancelled, "VNRequest.cancel() was called")
            request.finish(error: error)
            firstError = firstError ?? error
            continue
        }
        if !request.revisionIsSupported {
            let error = visionError(
                .unsupportedRevision,
                "Unsupported Vision revision \(request.revision) for \(type(of: request))"
            )
            request.finish(error: error)
            firstError = firstError ?? error
            continue
        }
        let error = request.modelUnavailableError()
        request.finish(error: error)
        firstError = firstError ?? error
    }
    if let firstError {
        throw firstError
    }
}

extension VNRequest {
    fileprivate var revisionIsSupported: Bool {
        let supported = Swift.type(of: self).supportedRevisions
        if supported.isEmpty {
            return true
        }
        return supported.contains(revision)
    }
}
