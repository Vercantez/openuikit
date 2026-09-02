import Dispatch
import Foundation
@_spi(LinuxPort) import QuickLookThumbnailing

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
    path: String = "/tmp/qlt-sample",
    types: QLThumbnailGenerator.Request.RepresentationTypes = .thumbnail
) -> QLThumbnailGenerator.Request {
    QLThumbnailGenerator.Request(
        fileAt: URL(fileURLWithPath: path),
        size: CGSize(width: 64, height: 48),
        scale: 2,
        representationTypes: types
    )
}

private func qltNSErrorCode(_ error: (any Error)?) -> Int? {
    (error as NSError?)?.code
}

private func qltBridgedDomain<E: Foundation._BridgedStoredNSError>(_: E.Type) -> String {
    E._nsErrorDomain
}

private func qltErrorTypeName<C: Foundation._ErrorCodeProtocol>(_: C.Type) -> String {
    String(describing: C._ErrorType.self)
}

func testQLThumbnailErrorDomain() {
    precondition(QLThumbnailErrorDomain == "QLThumbnailErrorDomain")
    precondition(QLThumbnailError.errorDomain == "QLThumbnailErrorDomain")
    precondition(QLThumbnailError.errorDomain == QLThumbnailErrorDomain)
    precondition(QLThumbnailError._nsErrorDomain == QLThumbnailErrorDomain)
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
    do {
        throw QLThumbnailError(.requestInvalid)
    } catch let error as QLThumbnailError where error.code == .requestInvalid {
        ()
    } catch {
        preconditionFailure("expected Code.requestInvalid pattern match")
    }
}

func testQLThumbnailErrorNSErrorBridge() {
    let userInfo: [String: Any] = ["qlt": "bridge"]
    let typed = QLThumbnailError(.savingToURLFailed, userInfo: userInfo)
    precondition(typed._nsError.domain == QLThumbnailErrorDomain)
    precondition(typed._nsError.code == 1)
    precondition(typed._nsError.userInfo["qlt"] as? String == "bridge")

    let bridged = typed as NSError
    precondition(bridged.domain == QLThumbnailErrorDomain)
    precondition(bridged.code == QLThumbnailError.Code.savingToURLFailed.rawValue)
    precondition(bridged.userInfo["qlt"] as? String == "bridge")

    let fromStored = QLThumbnailError(_nsError: typed._nsError)
    precondition(fromStored.code == .savingToURLFailed)
    precondition(fromStored.userInfo["qlt"] as? String == "bridge")
    precondition(fromStored == typed)

    do {
        throw typed
    } catch let caught as QLThumbnailError {
        precondition(caught.code == .savingToURLFailed)
        precondition(caught.userInfo["qlt"] as? String == "bridge")
    } catch {
        preconditionFailure("expected throw/catch QLThumbnailError round trip")
    }

    // Linux Foundation does not wrap arbitrary domains in `as? QLThumbnailError`.
    // Do not treat a missing cast as success or invent a local bridge.
    let nsRoundTrip = bridged as? QLThumbnailError
    _ = nsRoundTrip
}

func testQLThumbnailErrorProtocolConformance() {
    precondition(qltBridgedDomain(QLThumbnailError.self) == QLThumbnailErrorDomain)
    precondition(qltErrorTypeName(QLThumbnailError.Code.self) == String(describing: QLThumbnailError.self))

    let error = QLThumbnailError(.noCloudThumbnail)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    _ = error.hashValue

    var seen: Set<Int> = []
    seen.insert(error.hashValue)
    seen.insert(QLThumbnailError(.noCloudThumbnail).hashValue)
    precondition(seen.count == 1)
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

func testGenerateBestRepresentationCallbackAfterReturn() {
    let request = qltSampleRequest()
    let result = qltAwait {
        try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
    }
    guard case .failure(let error as QLThumbnailError) = result else {
        preconditionFailure("expected QLThumbnailError")
    }
    precondition(error.code == .generationFailed)

    var didReturn = false
    var callbackAfterReturn = false
    var callbacks = 0
    var callbackError: (any Error)?
    var callbackValue: QLThumbnailRepresentation?
    let semaphore = DispatchSemaphore(value: 0)
    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
        callbackAfterReturn = didReturn
        callbacks += 1
        callbackValue = representation
        callbackError = error
        semaphore.signal()
    }
    didReturn = true
    semaphore.wait()
    precondition(callbackAfterReturn)
    precondition(callbacks == 1)
    precondition(callbackValue == nil)
    precondition((callbackError as? QLThumbnailError)?.code == .generationFailed)
}

func testGenerateRepresentationsCallbackAfterReturn() {
    let request = qltSampleRequest(types: [.lowQualityThumbnail, .thumbnail])
    var didReturn = false
    var callbackAfterReturn = false
    var callbacks = 0
    var seenType: QLThumbnailRepresentation.RepresentationType?
    var seenRepresentation: QLThumbnailRepresentation?
    var seenError: (any Error)?
    let semaphore = DispatchSemaphore(value: 0)
    QLThumbnailGenerator.shared.generateRepresentations(for: request) { representation, type, error in
        callbackAfterReturn = didReturn
        callbacks += 1
        seenRepresentation = representation
        seenType = type
        seenError = error
        semaphore.signal()
    }
    didReturn = true
    semaphore.wait()
    precondition(callbackAfterReturn)
    precondition(callbacks == 1)
    precondition(seenRepresentation == nil)
    precondition(seenType == .thumbnail)
    precondition((seenError as? QLThumbnailError)?.code == .generationFailed)
    QLThumbnailGenerator.shared.generateRepresentations(for: request, update: nil)
}

func testSaveBestRepresentationCallbackAfterReturn() {
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

    var didReturn = false
    var callbackAfterReturn = false
    var callbacks = 0
    var callbackError: (any Error)?
    let semaphore = DispatchSemaphore(value: 0)
    QLThumbnailGenerator.shared.saveBestRepresentation(
        for: request,
        to: destination,
        contentType: "public.png"
    ) { error in
        callbackAfterReturn = didReturn
        callbacks += 1
        callbackError = error
        semaphore.signal()
    }
    didReturn = true
    semaphore.wait()
    precondition(callbackAfterReturn)
    precondition(callbacks == 1)
    precondition((callbackError as? QLThumbnailError)?.code == .generationFailed)
    precondition(!FileManager.default.fileExists(atPath: destination.path))
}

func testCancelPreCancelDoesNotPoisonRequest() {
    let generator = QLThumbnailGenerator()
    let request = qltSampleRequest(path: "/tmp/qlt-precancel")
    generator.cancel(request)

    let result = qltAwait {
        try await generator.generateBestRepresentation(for: request)
    }
    guard case .failure(let error as QLThumbnailError) = result else {
        preconditionFailure("expected QLThumbnailError")
    }
    precondition(error.code == .generationFailed)

    var callbacks = 0
    var callbackCode: Int?
    let semaphore = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, error in
        callbacks += 1
        callbackCode = qltNSErrorCode(error)
        semaphore.signal()
    }
    semaphore.wait()
    precondition(callbacks == 1)
    precondition(callbackCode == QLThumbnailError.Code.generationFailed.rawValue)
}

func testCancelWhileOperationActive() {
    let generator = QLThumbnailGenerator()
    let request = qltSampleRequest(path: "/tmp/qlt-active-cancel")
    generator.callbackQueue.suspend()

    var didReturn = false
    var callbackAfterReturn = false
    var callbacks = 0
    var callbackCode: Int?
    let semaphore = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, error in
        callbackAfterReturn = didReturn
        callbacks += 1
        callbackCode = qltNSErrorCode(error)
        semaphore.signal()
    }
    generator.cancel(request)
    didReturn = true
    generator.callbackQueue.resume()
    semaphore.wait()
    precondition(callbackAfterReturn)
    precondition(callbacks == 1)
    precondition(callbackCode == QLThumbnailError.Code.requestCancelled.rawValue)
}

func testReuseAfterTerminalDelivery() {
    let generator = QLThumbnailGenerator()
    let request = qltSampleRequest(path: "/tmp/qlt-reuse")

    var firstCode: Int?
    let first = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, error in
        firstCode = qltNSErrorCode(error)
        first.signal()
    }
    first.wait()
    precondition(firstCode == QLThumbnailError.Code.generationFailed.rawValue)

    generator.cancel(request)

    var secondCode: Int?
    var callbacks = 0
    let second = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, error in
        callbacks += 1
        secondCode = qltNSErrorCode(error)
        second.signal()
    }
    second.wait()
    precondition(callbacks == 1)
    precondition(secondCode == QLThumbnailError.Code.generationFailed.rawValue)
}

func testIndependentGeneratorCancellation() {
    let first = QLThumbnailGenerator()
    let second = QLThumbnailGenerator()
    let request = qltSampleRequest(path: "/tmp/qlt-independent")
    first.callbackQueue.suspend()
    second.callbackQueue.suspend()

    var firstCode: Int?
    var secondCode: Int?
    var firstCount = 0
    var secondCount = 0
    let firstDone = DispatchSemaphore(value: 0)
    let secondDone = DispatchSemaphore(value: 0)
    first.generateBestRepresentation(for: request) { _, error in
        firstCount += 1
        firstCode = qltNSErrorCode(error)
        firstDone.signal()
    }
    second.generateBestRepresentation(for: request) { _, error in
        secondCount += 1
        secondCode = qltNSErrorCode(error)
        secondDone.signal()
    }
    first.cancel(request)
    first.callbackQueue.resume()
    second.callbackQueue.resume()
    firstDone.wait()
    secondDone.wait()
    precondition(firstCount == 1)
    precondition(secondCount == 1)
    precondition(firstCode == QLThumbnailError.Code.requestCancelled.rawValue)
    precondition(secondCode == QLThumbnailError.Code.generationFailed.rawValue)
}

func testConcurrentGenerateAndCancelExactlyOnce() {
    final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        func increment() {
            lock.lock()
            value += 1
            lock.unlock()
        }
        func snapshot() -> Int {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
    }

    let generator = QLThumbnailGenerator()
    let group = DispatchGroup()
    let counter = Counter()
    let count = 32
    for index in 0..<count {
        let request = QLThumbnailGenerator.Request(
            fileAtURL: URL(fileURLWithPath: "/tmp/qlt-conc-\(index)"),
            size: CGSize(width: 16, height: 16),
            scale: 1,
            representationTypes: .all
        )
        group.enter()
        DispatchQueue.global().async {
            generator.generateBestRepresentation(for: request) { _, _ in
                counter.increment()
                group.leave()
            }
            if index % 2 == 0 {
                generator.cancel(request)
            }
        }
    }
    group.wait()
    precondition(counter.snapshot() == count)
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

func testFileThumbnailRequestPublicInitPlaceholders() {
    let request = QLFileThumbnailRequest()
    precondition(request.maximumSize == .zero)
    precondition(request.minimumSize == .zero)
    precondition(request.scale == 0)
    _ = request.fileURL
}

func testRepresentationPublicInitTypeIconContentRectZero() {
    let representation = QLThumbnailRepresentation()
    precondition(representation.type == .icon)
    precondition(representation.contentRect == .zero)
    precondition(representation.contentRect.origin.x == 0)
    precondition(representation.contentRect.origin.y == 0)
    precondition(representation.contentRect.size.width == 0)
    precondition(representation.contentRect.size.height == 0)
}

func testProviderProvideThumbnailFailsClosed() {
    let request = QLFileThumbnailRequest()
    let provider = QLThumbnailProvider()
    var reply: QLThumbnailReply?
    var error: (any Error)?
    var didReturn = false
    var callbackAfterReturn = false
    provider.provideThumbnail(for: request) { providedReply, providedError in
        callbackAfterReturn = didReturn
        reply = providedReply
        error = providedError
    }
    didReturn = true
    precondition(reply == nil)
    precondition((error as? QLThumbnailError)?.code == .generationFailed)
    // Provider timing was not in the iOS 26.1 generator observation. This port
    // keeps the handler synchronous; do not treat that as measured Apple behavior.
    precondition(callbackAfterReturn == false)
}
