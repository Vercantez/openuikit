@_exported import Foundation
@preconcurrency import Dispatch

/// A portable representation of work submitted to the system background-task
/// scheduler. Requests are copied when submitted, matching the value-like
/// behavior applications expect from Apple's daemon boundary.
open class BGTaskRequest: NSObject, NSCopying, @unchecked Sendable {
  public let identifier: String
  open var earliestBeginDate: Date?

  fileprivate init(identifier: String) {
    self.identifier = identifier
    super.init()
  }

  open func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return portableCopy()
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

open class BGAppRefreshTaskRequest: BGTaskRequest, @unchecked Sendable {
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

open class BGProcessingTaskRequest: BGTaskRequest, @unchecked Sendable {
  open var requiresNetworkConnectivity = false
  open var requiresExternalPower = false

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

/// Continued-processing request used by iOS 26's long-running foreground-to-
/// background work. Linux has no Apple continued-processing daemon; the
/// request is still a real, copyable value that the portable scheduler can
/// hold and later launch through host SPI.
open class BGContinuedProcessingTaskRequest: BGTaskRequest, @unchecked Sendable {
  public struct Resources: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// Pinned `dotnet/macios` `BGContinuedProcessingTaskRequestResources.Gpu`
    /// is `(1L << 0)`. Apple's overlay exposes only this static member.
    public static let gpu = Resources(rawValue: 1 << 0)
  }

  /// Pinned `dotnet/macios` native enum: `Fail = 0`, `Queue = 1`.
  public enum SubmissionStrategy: Int, Hashable, Sendable {
    case fail = 0
    case queue = 1
  }

  open var title: String
  open var subtitle: String
  /// Unconfirmed against Apple's runtime default. Linux uses `.fail` (C
  /// enum zero) until an Apple-oracle observation lands.
  open var strategy: SubmissionStrategy
  /// Unconfirmed against Apple's runtime default. Linux uses the empty set
  /// (macios `Default = 0x0`) until an Apple-oracle observation lands.
  open var requiredResources: Resources

  public init(identifier: String, title: String, subtitle: String) {
    self.title = title
    self.subtitle = subtitle
    self.strategy = .fail
    self.requiredResources = []
    super.init(identifier: identifier)
  }

  fileprivate override func portableCopy() -> BGTaskRequest {
    let copy = BGContinuedProcessingTaskRequest(
      identifier: identifier,
      title: title,
      subtitle: subtitle
    )
    copy.earliestBeginDate = earliestBeginDate
    copy.strategy = strategy
    copy.requiredResources = requiredResources
    return copy
  }

  fileprivate override func portableTask() -> BGTask {
    BGContinuedProcessingTask(
      identifier: identifier,
      title: title,
      subtitle: subtitle
    )
  }
}

open class BGHealthResearchTaskRequest: BGProcessingTaskRequest,
  @unchecked Sendable
{
  /// Graph types this as `NSString`. Default is empty; Apple's HealthKit
  /// protection-type default is unobserved.
  open var protectionTypeOfRequiredData: NSString = ""

  public override init(identifier: String) {
    super.init(identifier: identifier)
  }

  fileprivate override func portableCopy() -> BGTaskRequest {
    let copy = BGHealthResearchTaskRequest(identifier: identifier)
    copy.earliestBeginDate = earliestBeginDate
    copy.requiresNetworkConnectivity = requiresNetworkConnectivity
    copy.requiresExternalPower = requiresExternalPower
    copy.protectionTypeOfRequiredData = protectionTypeOfRequiredData
    return copy
  }

  fileprivate override func portableTask() -> BGTask {
    BGHealthResearchTask(identifier: identifier)
  }
}

open class BGTask: NSObject, @unchecked Sendable {
  public let identifier: String
  open var expirationHandler: (() -> Void)?

  private let stateLock = NSLock()
  private var completion: Bool?
  private var expired = false

  fileprivate init(identifier: String) {
    self.identifier = identifier
    super.init()
  }

  open func setTaskCompleted(success: Bool) {
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

open class BGAppRefreshTask: BGTask, @unchecked Sendable {}

open class BGProcessingTask: BGTask, @unchecked Sendable {}

open class BGHealthResearchTask: BGProcessingTask, @unchecked Sendable {}

open class BGContinuedProcessingTask: BGTask, ProgressReporting,
  @unchecked Sendable
{
  private let titleLock = NSLock()
  private var storedTitle: String
  private var storedSubtitle: String
  public let progress: Progress

  open var title: String {
    titleLock.lock()
    defer { titleLock.unlock() }
    return storedTitle
  }

  open var subtitle: String {
    titleLock.lock()
    defer { titleLock.unlock() }
    return storedSubtitle
  }

  fileprivate init(identifier: String, title: String, subtitle: String) {
    self.storedTitle = title
    self.storedSubtitle = subtitle
    self.progress = Progress(totalUnitCount: 1)
    super.init(identifier: identifier)
  }

  open func updateTitle(_ title: String, subtitle: String) {
    titleLock.lock()
    storedTitle = title
    storedSubtitle = subtitle
    titleLock.unlock()
  }
}

open class BGTaskScheduler: NSObject, @unchecked Sendable {
  /// Bridged scheduler error.
  ///
  /// Pinned `dotnet/macios` `[ErrorDomain ("BGTaskSchedulerErrorDomain")]`
  /// with `Unavailable = 1` through `ImmediateRunIneligible = 4`. Linux
  /// Foundation's `_BridgedStoredNSError` hash witnesses trap, so hash
  /// members are provided here. Typed `NSError as? BGTaskScheduler.Error`
  /// round-trips are not claimed.
  public struct Error: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
      public typealias _ErrorType = BGTaskScheduler.Error

      case unavailable = 1
      case tooManyPendingTaskRequests = 2
      case notPermitted = 3
      case immediateRunIneligible = 4
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
      self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { BGTaskScheduler.errorDomain }

    public static var unavailable: Code { .unavailable }
    public static var tooManyPendingTaskRequests: Code {
      .tooManyPendingTaskRequests
    }
    public static var notPermitted: Code { .notPermitted }
    public static var immediateRunIneligible: Code { .immediateRunIneligible }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(_nsError.domain)
      hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
      var hasher = Hasher()
      hash(into: &hasher)
      return hasher.finalize()
    }
  }

  private struct Registration: @unchecked Sendable {
    let queue: DispatchQueue?
    let handler: (BGTask) -> Void
  }

  private static let _shared = BGTaskScheduler()

  open class var shared: BGTaskScheduler { _shared }

  /// Swift overlay of `_BGTaskSchedulerErrorDomain`.
  public static let errorDomain = "BGTaskSchedulerErrorDomain"

  /// Linux has no continued-processing GPU resource. Returns the empty set
  /// rather than advertising `.gpu`.
  open class var supportedResources: BGContinuedProcessingTaskRequest.Resources {
    []
  }

  /// Portable pending-request cap. Apple's daemon limit is unobserved.
  fileprivate static let portablePendingLimit = 10

  private let stateLock = NSLock()
  private var registrations: [String: Registration] = [:]
  private var pending: [BGTaskRequest] = []
  private var available = true
  private var permittedIdentifiers: Set<String>?

  private override init() {
    super.init()
  }

  @discardableResult
  open func register(
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

  open func submit(_ taskRequest: BGTaskRequest) throws {
    stateLock.lock()
    defer { stateLock.unlock() }
    guard available else { throw Error(.unavailable) }
    if let permittedIdentifiers,
      !permittedIdentifiers.contains(taskRequest.identifier)
    {
      throw Error(.notPermitted)
    }
    guard pending.count < Self.portablePendingLimit else {
      throw Error(.tooManyPendingTaskRequests)
    }
    pending.append(taskRequest.portableCopy())
  }

  open func getPendingTaskRequests(
    completionHandler: @escaping ([BGTaskRequest]) -> Void
  ) {
    completionHandler(portablePendingTaskRequests())
  }

  open func pendingTaskRequests() async -> [BGTaskRequest] {
    portablePendingTaskRequests()
  }

  open func cancel(taskRequestWithIdentifier identifier: String) {
    stateLock.lock()
    pending.removeAll { $0.identifier == identifier }
    stateLock.unlock()
  }

  open func cancelAllTaskRequests() {
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
