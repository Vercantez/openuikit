import Dispatch
import Foundation
import QuickLookThumbnailing

private final class QLTLocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ value: Value) {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    func increment() where Value == Int {
        lock.lock()
        self.value += 1
        lock.unlock()
    }
}

private func qltAwait<T>(_ body: @escaping () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = QLTLocked<Result<T, Error>?>(nil)
    Task {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    semaphore.wait()
    guard let result = box.load() else {
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
    copied.iconMode = false
    copied.minimumDimension = 0
    precondition(request.iconMode)
    precondition(request.minimumDimension == 16)
}

func testRequestSecureCodingRoundTrip() {
    let url = URL(fileURLWithPath: "/tmp/qlt-archive")
    let request = QLThumbnailGenerator.Request(
        fileAt: url,
        size: CGSize(width: 120, height: 80),
        scale: 3,
        representationTypes: [.icon, .thumbnail]
    )
    request.iconMode = true
    request.minimumDimension = 16
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(withRootObject: request, requiringSecureCoding: true)
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    let restored: QLThumbnailGenerator.Request
    do {
        guard let value = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: QLThumbnailGenerator.Request.self,
            from: data
        ) else {
            preconditionFailure("expected restored request")
        }
        restored = value
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
    precondition(restored !== request)
    precondition(restored.size.width == 120)
    precondition(restored.size.height == 80)
    precondition(restored.scale == 3)
    precondition(restored.representationTypes.contains(.icon))
    precondition(restored.representationTypes.contains(.thumbnail))
    precondition(restored.iconMode)
    precondition(restored.minimumDimension == 16)
    precondition(restored.description.contains("/tmp/qlt-archive"))
    restored.iconMode = false
    restored.minimumDimension = 1
    precondition(request.iconMode)
    precondition(request.minimumDimension == 16)
    precondition(QLThumbnailGenerator.Request.supportsSecureCoding)
}

func testRequestSecureCodingRejectsMalformed() {
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: "qlt", requiringSecureCoding: true)
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(QLThumbnailGenerator.Request(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("malformed string archive setup failed: \(error)")
    }

    do {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(Int32(1), forKey: "QLThumbnailGenerator.Request.version")
        archiver.encode(120.0, forKey: "QLThumbnailGenerator.Request.size.width")
        archiver.encode(80.0, forKey: "QLThumbnailGenerator.Request.size.height")
        archiver.encode(2.0, forKey: "QLThumbnailGenerator.Request.scale")
        archiver.encode(Int64(1), forKey: "QLThumbnailGenerator.Request.representationTypes")
        archiver.encode(false, forKey: "QLThumbnailGenerator.Request.iconMode")
        archiver.encode(0.0, forKey: "QLThumbnailGenerator.Request.minimumDimension")
        let data = archiver.encodedData
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(QLThumbnailGenerator.Request(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("missing URL archive setup failed: \(error)")
    }

    do {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(Int32(1), forKey: "QLThumbnailGenerator.Request.version")
        archiver.encode(URL(fileURLWithPath: "/tmp/qlt-nan") as NSURL, forKey: "QLThumbnailGenerator.Request.fileURL")
        archiver.encode(Double.nan, forKey: "QLThumbnailGenerator.Request.size.width")
        archiver.encode(80.0, forKey: "QLThumbnailGenerator.Request.size.height")
        archiver.encode(2.0, forKey: "QLThumbnailGenerator.Request.scale")
        archiver.encode(Int64(1), forKey: "QLThumbnailGenerator.Request.representationTypes")
        archiver.encode(false, forKey: "QLThumbnailGenerator.Request.iconMode")
        archiver.encode(0.0, forKey: "QLThumbnailGenerator.Request.minimumDimension")
        let data = archiver.encodedData
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(QLThumbnailGenerator.Request(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("non-finite size archive setup failed: \(error)")
    }

    do {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(Int32(99), forKey: "QLThumbnailGenerator.Request.version")
        archiver.encode(URL(fileURLWithPath: "/tmp/qlt-ver") as NSURL, forKey: "QLThumbnailGenerator.Request.fileURL")
        archiver.encode(1.0, forKey: "QLThumbnailGenerator.Request.size.width")
        archiver.encode(1.0, forKey: "QLThumbnailGenerator.Request.size.height")
        archiver.encode(1.0, forKey: "QLThumbnailGenerator.Request.scale")
        archiver.encode(Int64(1), forKey: "QLThumbnailGenerator.Request.representationTypes")
        archiver.encode(false, forKey: "QLThumbnailGenerator.Request.iconMode")
        archiver.encode(0.0, forKey: "QLThumbnailGenerator.Request.minimumDimension")
        let data = archiver.encodedData
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(QLThumbnailGenerator.Request(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("version mismatch archive setup failed: \(error)")
    }
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

    let didReturn = QLTLocked(false)
    let callbackAfterReturn = QLTLocked(false)
    let callbacks = QLTLocked(0)
    let callbackError = QLTLocked<(any Error)?>(nil)
    let callbackValue = QLTLocked<QLThumbnailRepresentation?>(nil)
    let semaphore = DispatchSemaphore(value: 0)
    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
        callbackAfterReturn.store(didReturn.load())
        callbacks.increment()
        callbackValue.store(representation)
        callbackError.store(error)
        semaphore.signal()
    }
    didReturn.store(true)
    semaphore.wait()
    precondition(callbackAfterReturn.load())
    precondition(callbacks.load() == 1)
    precondition(callbackValue.load() == nil)
    precondition((callbackError.load() as? QLThumbnailError)?.code == .generationFailed)
}

func testGenerateRepresentationsCallbackAfterReturn() {
    let request = qltSampleRequest(types: [.lowQualityThumbnail, .thumbnail])
    let didReturn = QLTLocked(false)
    let callbackAfterReturn = QLTLocked(false)
    let callbacks = QLTLocked(0)
    let seenType = QLTLocked<QLThumbnailRepresentation.RepresentationType?>(nil)
    let seenRepresentation = QLTLocked<QLThumbnailRepresentation?>(nil)
    let seenError = QLTLocked<(any Error)?>(nil)
    let semaphore = DispatchSemaphore(value: 0)
    QLThumbnailGenerator.shared.generateRepresentations(for: request) { representation, type, error in
        callbackAfterReturn.store(didReturn.load())
        callbacks.increment()
        seenRepresentation.store(representation)
        seenType.store(type)
        seenError.store(error)
        semaphore.signal()
    }
    didReturn.store(true)
    semaphore.wait()
    precondition(callbackAfterReturn.load())
    precondition(callbacks.load() == 1)
    precondition(seenRepresentation.load() == nil)
    precondition(seenType.load() == .thumbnail)
    precondition((seenError.load() as? QLThumbnailError)?.code == .generationFailed)
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

    let didReturn = QLTLocked(false)
    let callbackAfterReturn = QLTLocked(false)
    let callbacks = QLTLocked(0)
    let callbackError = QLTLocked<(any Error)?>(nil)
    let semaphore = DispatchSemaphore(value: 0)
    QLThumbnailGenerator.shared.saveBestRepresentation(
        for: request,
        to: destination,
        contentType: "public.png"
    ) { error in
        callbackAfterReturn.store(didReturn.load())
        callbacks.increment()
        callbackError.store(error)
        semaphore.signal()
    }
    didReturn.store(true)
    semaphore.wait()
    precondition(callbackAfterReturn.load())
    precondition(callbacks.load() == 1)
    precondition((callbackError.load() as? QLThumbnailError)?.code == .generationFailed)
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

    let callbacks = QLTLocked(0)
    let callbackCode = QLTLocked<Int?>(nil)
    let semaphore = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, error in
        callbacks.increment()
        callbackCode.store(qltNSErrorCode(error))
        semaphore.signal()
    }
    semaphore.wait()
    precondition(callbacks.load() == 1)
    precondition(callbackCode.load() == QLThumbnailError.Code.generationFailed.rawValue)
}

func testReuseAfterTerminalDelivery() {
    let generator = QLThumbnailGenerator()
    let request = qltSampleRequest(path: "/tmp/qlt-reuse")

    let firstCode = QLTLocked<Int?>(nil)
    let first = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, error in
        firstCode.store(qltNSErrorCode(error))
        first.signal()
    }
    first.wait()
    precondition(firstCode.load() == QLThumbnailError.Code.generationFailed.rawValue)

    generator.cancel(request)

    let secondCode = QLTLocked<Int?>(nil)
    let callbacks = QLTLocked(0)
    let second = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, error in
        callbacks.increment()
        secondCode.store(qltNSErrorCode(error))
        second.signal()
    }
    second.wait()
    precondition(callbacks.load() == 1)
    precondition(secondCode.load() == QLThumbnailError.Code.generationFailed.rawValue)
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

func testDependencyIdentityHostGeometry() {
    let size = CGSize(width: 32, height: 32)
    let scale: CGFloat = 1
    let request = QLThumbnailGenerator.Request(
        fileAt: URL(fileURLWithPath: "/tmp/qlt-identity-host"),
        size: size,
        scale: scale,
        representationTypes: .icon
    )
    let roundTrippedSize: CGSize = request.size
    let roundTrippedScale: CGFloat = request.scale
    precondition(roundTrippedSize.width == 32)
    precondition(roundTrippedSize.height == 32)
    precondition(roundTrippedScale == 1)
    let representation = QLThumbnailRepresentation()
    let contentRect: CGRect = representation.contentRect
    precondition(contentRect == .zero)
}
