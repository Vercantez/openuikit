import Foundation
@preconcurrency import Dispatch

/// A portable representation of work submitted to the system background-task
/// scheduler. Requests are copied when submitted, matching the value-like
/// behavior applications expect from Apple's daemon boundary.
open class BGTaskRequest: NSObject, @unchecked Sendable {
  public let identifier: String
  public var earliestBeginDate: Date?

  public init(identifier: String) {
    self.identifier = identifier
    super.init()
  }

  fileprivate func portableCopy() -> BGTaskRequest {
    let copy = BGTaskRequest(identifier: identifier)
    copy.earliestBeginDate = earliestBeginDate
    return copy
  }

  fileprivate func portableTask() -> BGTask {
    BGTask(identifier: identifier)
  }
}

public final class BGAppRefreshTaskRequest: BGTaskRequest,
  @unchecked Sendable
{
  public override init(identifier: String) {
    super.init(identifier: identifier)
  }

  fileprivate override func portableCopy() -> BGTaskRequest {
    let copy = BGAppRefreshTaskRequest(identifier: identifier)
    copy.earliestBeginDate = earliestBeginDate
    return copy
  }

  fileprivate override func portableTask() -> BGTask {
    BGAppRefreshTask(identifier: identifier)
  }
}

public final class BGProcessingTaskRequest: BGTaskRequest,
  @unchecked Sendable
{
  public var requiresNetworkConnectivity = false
  public var requiresExternalPower = false

  public override init(identifier: String) {
    super.init(identifier: identifier)
  }

  fileprivate override func portableCopy() -> BGTaskRequest {
    let copy = BGProcessingTaskRequest(identifier: identifier)
    copy.earliestBeginDate = earliestBeginDate
    copy.requiresNetworkConnectivity = requiresNetworkConnectivity
    copy.requiresExternalPower = requiresExternalPower
    return copy
  }

  fileprivate override func portableTask() -> BGTask {
    BGProcessingTask(identifier: identifier)
  }
}

open class BGTask: NSObject, @unchecked Sendable {
  public let identifier: String
  public var expirationHandler: (() -> Void)?

  private let stateLock = NSLock()
  private var completion: Bool?
  private var expired = false

  fileprivate init(identifier: String) {
    self.identifier = identifier
    super.init()
  }

  public func setTaskCompleted(success: Bool) {
    stateLock.lock()
    if completion == nil {
      completion = success
    }
    stateLock.unlock()
  }

  @_spi(OpenUIKitHost)
  public var _portableCompletion: Bool? {
    stateLock.lock()
    let result = completion
    stateLock.unlock()
    return result
  }

  @_spi(OpenUIKitHost)
  public func _expirePortableTask() {
    stateLock.lock()
    guard !expired else {
      stateLock.unlock()
      return
    }
    expired = true
    let handler = expirationHandler
    stateLock.unlock()
    handler?()
  }
}

public final class BGAppRefreshTask: BGTask, @unchecked Sendable {}
public final class BGProcessingTask: BGTask, @unchecked Sendable {}

public final class BGTaskScheduler: NSObject, @unchecked Sendable {
  public enum Error: Swift.Error, Equatable, Sendable {
    case unavailable
    case tooManyPendingTaskRequests
    case notPermitted

    public enum Code: Int, Sendable {
      case unavailable = 1
      case tooManyPendingTaskRequests = 2
      case notPermitted = 3
    }

    public var code: Code {
      switch self {
      case .unavailable: .unavailable
      case .tooManyPendingTaskRequests: .tooManyPendingTaskRequests
      case .notPermitted: .notPermitted
      }
    }
  }

  private struct Registration: @unchecked Sendable {
    let queue: DispatchQueue?
    let handler: (BGTask) -> Void
  }

  public static let shared = BGTaskScheduler()

  private let stateLock = NSLock()
  private var registrations: [String: Registration] = [:]
  private var pending: [BGTaskRequest] = []
  private var available = true
  private var permittedIdentifiers: Set<String>?

  private override init() {
    super.init()
  }

  @discardableResult
  public func register(
    forTaskWithIdentifier identifier: String,
    using queue: DispatchQueue?,
    launchHandler: @escaping (BGTask) -> Void
  ) -> Bool {
    guard !identifier.isEmpty else { return false }
    stateLock.lock()
    defer { stateLock.unlock() }
    guard registrations[identifier] == nil else { return false }
    if let permittedIdentifiers, !permittedIdentifiers.contains(identifier) {
      return false
    }
    registrations[identifier] = Registration(
      queue: queue,
      handler: launchHandler
    )
    return true
  }

  public func submit(_ taskRequest: BGTaskRequest) throws {
    stateLock.lock()
    defer { stateLock.unlock() }
    guard available else { throw Error.unavailable }
    if let permittedIdentifiers,
      !permittedIdentifiers.contains(taskRequest.identifier)
    {
      throw Error.notPermitted
    }
    guard pending.count < 10 else {
      throw Error.tooManyPendingTaskRequests
    }
    pending.append(taskRequest.portableCopy())
  }

  public func getPendingTaskRequests(
    completionHandler: @escaping ([BGTaskRequest]) -> Void
  ) {
    completionHandler(portablePendingTaskRequests())
  }

  public func pendingTaskRequests() async -> [BGTaskRequest] {
    portablePendingTaskRequests()
  }

  public func cancel(taskRequestWithIdentifier identifier: String) {
    stateLock.lock()
    pending.removeAll { $0.identifier == identifier }
    stateLock.unlock()
  }

  public func cancelAllTaskRequests() {
    stateLock.lock()
    pending.removeAll()
    stateLock.unlock()
  }

  private func portablePendingTaskRequests() -> [BGTaskRequest] {
    stateLock.lock()
    let result = pending.map { $0.portableCopy() }
    stateLock.unlock()
    return result
  }

  /// Launches one due request through its registered handler. The production
  /// Linux app host calls this at lifecycle boundaries; it is SPI so unchanged
  /// applications continue to see only Apple's public API.
  @_spi(OpenUIKitHost)
  @discardableResult
  public func _launchPortableTask(
    withIdentifier identifier: String,
    ignoringEarliestBeginDate: Bool = false
  ) -> BGTask? {
    stateLock.lock()
    guard let registration = registrations[identifier],
      let index = pending.firstIndex(where: {
        $0.identifier == identifier
          && (ignoringEarliestBeginDate
            || ($0.earliestBeginDate ?? .distantPast) <= Date())
      })
    else {
      stateLock.unlock()
      return nil
    }
    let request = pending.remove(at: index)
    stateLock.unlock()

    let task = request.portableTask()
    if let queue = registration.queue {
      queue.async { registration.handler(task) }
    } else {
      registration.handler(task)
    }
    return task
  }

  @_spi(OpenUIKitHost)
  public func _setPortableAvailability(
    _ isAvailable: Bool,
    permittedIdentifiers: Set<String>? = nil
  ) {
    stateLock.lock()
    available = isAvailable
    self.permittedIdentifiers = permittedIdentifiers
    stateLock.unlock()
  }

  @_spi(OpenUIKitHost)
  public func _resetPortableState() {
    stateLock.lock()
    registrations.removeAll()
    pending.removeAll()
    available = true
    permittedIdentifiers = nil
    stateLock.unlock()
  }
}

extension BGTaskScheduler.Error: CustomNSError {
  public static var errorDomain: String { "BGTaskSchedulerErrorDomain" }
  public var errorCode: Int { code.rawValue }
  public var errorUserInfo: [String: Any] { [:] }
}
