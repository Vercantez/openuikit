import Dispatch
import Foundation
import QuickLookThumbnailing

private func qltAwait<T>(_ body: @escaping () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    var result: Result<T, Error>?
    Task {
        do {
            result = .success(try await body())
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }
    semaphore.wait()
    guard let result else {
        preconditionFailure("async probe did not complete")
    }
    return result
}

private func qltSampleRequest(
    types: QLThumbnailGenerator.Request.RepresentationTypes = .thumbnail
) -> QLThumbnailGenerator.Request {
    QLThumbnailGenerator.Request(
        fileAt: URL(fileURLWithPath: "/tmp/qlt-sample"),
        size: CGSize(width: 64, height: 48),
        scale: 2,
        representationTypes: types
    )
}

func testQLThumbnailErrorDomain() {
    precondition(QLThumbnailErrorDomain == "QLThumbnailErrorDomain")
    precondition(QLThumbnailError.errorDomain == "QLThumbnailErrorDomain")
    precondition(QLThumbnailError.errorDomain == QLThumbnailErrorDomain)
}

func testQLThumbnailErrorCodes() {
    precondition(QLThumbnailError.Code.generationFailed.rawValue == 0)
    precondition(QLThumbnailError.Code.savingToURLFailed.rawValue == 1)
    precondition(QLThumbnailError.Code.noCachedThumbnail.rawValue == 2)
    precondition(QLThumbnailError.Code.noCloudThumbnail.rawValue == 3)
    precondition(QLThumbnailError.Code.requestInvalid.rawValue == 4)
    precondition(QLThumbnailError.Code.requestCancelled.rawValue == 5)
    precondition(QLThumbnailError.generationFailed == .generationFailed)
    precondition(QLThumbnailError.savingToURLFailed == .savingToURLFailed)
    precondition(QLThumbnailError.noCachedThumbnail == .noCachedThumbnail)
    precondition(QLThumbnailError.noCloudThumbnail == .noCloudThumbnail)
    precondition(QLThumbnailError.requestInvalid == .requestInvalid)
    precondition(QLThumbnailError.requestCancelled == .requestCancelled)
    precondition(QLThumbnailError.Code(rawValue: 0) == .generationFailed)
    precondition(QLThumbnailError.Code(rawValue: 5) == .requestCancelled)
    precondition(QLThumbnailError.Code(rawValue: 6) == nil)
    precondition(
        QLThumbnailError.Code.generationFailed.hashValue ==
            QLThumbnailError.Code.generationFailed.hashValue
    )
    var hasher = Hasher()
    QLThumbnailError.Code.requestInvalid.hash(into: &hasher)
    _ = hasher.finalize()
}

func testQLThumbnailErrorEqualityAndHash() {
    let empty = QLThumbnailError(.generationFailed)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 0)
    precondition(empty.code == .generationFailed)
    precondition(!empty.localizedDescription.isEmpty)

    let sentinel = QLThumbnailError(.generationFailed, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(empty == QLThumbnailError(.generationFailed))
    precondition(sentinel != empty)
    precondition(
        QLThumbnailError(.generationFailed, userInfo: ["x": 1]) !=
            QLThumbnailError(.generationFailed, userInfo: ["x": "1"])
    )
    precondition(empty.hashValue == sentinel.hashValue)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    QLThumbnailError(.generationFailed).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testQLThumbnailErrorPatternMatch() {
    let error: any Error = QLThumbnailError(.requestCancelled)
    precondition(QLThumbnailError.Code.requestCancelled ~= error)
    precondition(!(QLThumbnailError.Code.generationFailed ~= error))
}

func testRepresentationTypesOptionSet() {
    typealias Types = QLThumbnailGenerator.Request.RepresentationTypes
    precondition(Types.icon.rawValue == 1)
    precondition(Types.lowQualityThumbnail.rawValue == 2)
    precondition(Types.thumbnail.rawValue == 4)
    precondition(Types.all.rawValue == UInt.max)
    precondition(Types().isEmpty)
    precondition(Types.icon != Types.thumbnail)

    var types: Types = [.icon, .thumbnail]
    precondition(types.contains(.icon))
    precondition(types.contains(.thumbnail))
    precondition(!types.contains(.lowQualityThumbnail))
    precondition(types.contains(.icon))
    let inserted = types.insert(.lowQualityThumbnail)
    precondition(inserted.inserted)
    precondition(types.contains(.lowQualityThumbnail))
    precondition(types.remove(.icon) == .icon)
    precondition(!types.contains(.icon))
    precondition(types.update(with: .icon) == nil)

    let union = Types.icon.union(.thumbnail)
    precondition(union.contains(.icon) && union.contains(.thumbnail))
    let intersection = Types.all.intersection(.icon)
    precondition(intersection == .icon)
    let difference = Types.icon.symmetricDifference(.thumbnail)
    precondition(difference.contains(.icon) && difference.contains(.thumbnail))
    precondition(Types.icon.isSubset(of: .all))
    precondition(Types.all.isSuperset(of: .thumbnail))
    precondition(Types.icon.isDisjoint(with: .thumbnail))
    precondition(Types.icon.isStrictSubset(of: .all))
    precondition(Types.all.isStrictSuperset(of: .icon))
    precondition(Types.icon.subtracting(.icon).isEmpty)

    var mutating = Types.icon
    mutating.formUnion(.thumbnail)
    mutating.formIntersection(.all)
    mutating.formSymmetricDifference(.lowQualityThumbnail)
    mutating.subtract(.thumbnail)
    precondition(!mutating.isEmpty)

    let fromSequence = Types([.icon, .icon, .thumbnail])
    precondition(fromSequence.contains(.icon) && fromSequence.contains(.thumbnail))
}

func testRepresentationTypeRawValues() {
    typealias Kind = QLThumbnailRepresentation.RepresentationType
    precondition(Kind.icon.rawValue == 0)
    precondition(Kind.lowQualityThumbnail.rawValue == 1)
    precondition(Kind.thumbnail.rawValue == 2)
    precondition(Kind(rawValue: 0) == .icon)
    precondition(Kind(rawValue: 3) == nil)
    precondition(Kind.icon != .thumbnail)
    precondition(Kind.icon.hashValue == Kind.icon.hashValue)
    var hasher = Hasher()
    Kind.thumbnail.hash(into: &hasher)
    _ = hasher.finalize()
}

func testRequestStoresInputs() {
    let url = URL(fileURLWithPath: "/tmp/qlt-request")
    let size = CGSize(width: 120, height: 80)
    let request = QLThumbnailGenerator.Request(
        fileAt: url,
        size: size,
        scale: 3,
        representationTypes: [.icon, .thumbnail]
    )
    precondition(request.size.width == 120)
    precondition(request.size.height == 80)
    precondition(request.scale == 3)
    precondition(request.representationTypes.contains(.icon))
    precondition(request.representationTypes.contains(.thumbnail))
    precondition(request.iconMode == false)
    precondition(request.minimumDimension == 0)
    request.iconMode = true
    request.minimumDimension = 16
    precondition(request.iconMode)
    precondition(request.minimumDimension == 16)

    let alias = QLThumbnailGenerator.Request(
        fileAtURL: url,
        size: size,
        scale: 3,
        representationTypes: .all
    )
    precondition(alias.representationTypes == .all)
    precondition(alias.description.contains("QLThumbnailGenerator.Request"))

    let copied = request.copy() as! QLThumbnailGenerator.Request
    precondition(copied !== request)
    precondition(copied.size.width == request.size.width)
    precondition(copied.iconMode == true)
    precondition(copied.minimumDimension == 16)
}

func testRequestCoderFailsClosed() {
    let data = try! NSKeyedArchiver.archivedData(withRootObject: "qlt", requiringSecureCoding: true)
    let unarchiver = try! NSKeyedUnarchiver(forReadingFrom: data)
    let decoded = QLThumbnailGenerator.Request(coder: unarchiver)
    precondition(decoded == nil)
    precondition(QLThumbnailGenerator.Request.supportsSecureCoding)
}

func testGeneratorSharedIdentity() {
    let shared = QLThumbnailGenerator.shared
    precondition(shared === QLThumbnailGenerator.shared)
    _ = QLThumbnailGenerator()
}

func testGenerateBestRepresentationFailsClosed() {
    let request = qltSampleRequest()
    let result = qltAwait {
        try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
    }
    guard case .failure(let error as QLThumbnailError) = result else {
        preconditionFailure("expected QLThumbnailError")
    }
    precondition(error.code == .generationFailed)

    let semaphore = DispatchSemaphore(value: 0)
    var callbackError: (any Error)?
    var callbackValue: QLThumbnailRepresentation?
    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
        callbackValue = representation
        callbackError = error
        semaphore.signal()
    }
    semaphore.wait()
    precondition(callbackValue == nil)
    precondition((callbackError as? QLThumbnailError)?.code == .generationFailed)
}

func testGenerateRepresentationsFailsClosed() {
    let request = qltSampleRequest(types: [.lowQualityThumbnail, .thumbnail])
    let semaphore = DispatchSemaphore(value: 0)
    var seenType: QLThumbnailRepresentation.RepresentationType?
    var seenRepresentation: QLThumbnailRepresentation?
    var seenError: (any Error)?
    QLThumbnailGenerator.shared.generateRepresentations(for: request) { representation, type, error in
        seenRepresentation = representation
        seenType = type
        seenError = error
        semaphore.signal()
    }
    semaphore.wait()
    precondition(seenRepresentation == nil)
    precondition(seenType == .thumbnail)
    precondition((seenError as? QLThumbnailError)?.code == .generationFailed)
    QLThumbnailGenerator.shared.generateRepresentations(for: request, update: nil)
}

func testSaveBestRepresentationStringFailsClosed() {
    let destination = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("qlt-must-not-exist-\(UUID().uuidString).png")
    let request = qltSampleRequest()
    let result = qltAwait {
        try await QLThumbnailGenerator.shared.saveBestRepresentation(
            for: request,
            to: destination,
            contentType: "public.png"
        )
    }
    guard case .failure(let error as QLThumbnailError) = result else {
        preconditionFailure("expected QLThumbnailError")
    }
    precondition(error.code == .generationFailed)
    precondition(!FileManager.default.fileExists(atPath: destination.path))
}

func testCancelThenGenerateRequestCancelled() {
    let request = qltSampleRequest()
    QLThumbnailGenerator.shared.cancel(request)
    let result = qltAwait {
        try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
    }
    guard case .failure(let error as QLThumbnailError) = result else {
        preconditionFailure("expected QLThumbnailError")
    }
    precondition(error.code == .requestCancelled)

    let other = qltSampleRequest()
    let otherResult = qltAwait {
        try await QLThumbnailGenerator.shared.generateBestRepresentation(for: other)
    }
    guard case .failure(let otherError as QLThumbnailError) = otherResult else {
        preconditionFailure("expected QLThumbnailError")
    }
    precondition(otherError.code == .generationFailed)
}

func testReplyImageFileURLAndBadge() {
    let fileURL = URL(fileURLWithPath: "/tmp/qlt-reply.png")
    let reply = QLThumbnailReply(imageFileURL: fileURL)
    precondition(reply.extensionBadge.isEmpty)
    reply.extensionBadge = "PDF"
    precondition(reply.extensionBadge == "PDF")
    precondition(reply.description.contains("QLThumbnailReply"))
}

func testReplyCurrentContextDrawingDoesNotInvokeBlock() {
    var invoked = false
    let reply = QLThumbnailReply(
        contextSize: CGSize(width: 10, height: 20),
        currentContextDrawing: {
            invoked = true
            return true
        }
    )
    precondition(!invoked)
    let aliased = QLThumbnailReply(
        contextSize: CGSize(width: 8, height: 8),
        currentContextDrawingBlock: {
            invoked = true
            return false
        }
    )
    precondition(!invoked)
    _ = reply
    _ = aliased
}

func testProviderProvideThumbnailFailsClosed() {
    let request = QLFileThumbnailRequest(
        fileURL: URL(fileURLWithPath: "/tmp/qlt-file"),
        maximumSize: CGSize(width: 100, height: 100),
        minimumSize: CGSize(width: 20, height: 20),
        scale: 2
    )
    precondition(request.fileURL.path == "/tmp/qlt-file")
    precondition(request.maximumSize.width == 100)
    precondition(request.minimumSize.width == 20)
    precondition(request.scale == 2)

    let provider = QLThumbnailProvider()
    let semaphore = DispatchSemaphore(value: 0)
    var reply: QLThumbnailReply?
    var error: (any Error)?
    provider.provideThumbnail(for: request) { providedReply, providedError in
        reply = providedReply
        error = providedError
        semaphore.signal()
    }
    semaphore.wait()
    precondition(reply == nil)
    precondition((error as? QLThumbnailError)?.code == .generationFailed)
}
