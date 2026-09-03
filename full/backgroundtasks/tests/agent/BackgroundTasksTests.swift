import Dispatch
import Foundation
@_spi(OpenUIKitHost) import BackgroundTasks

private func resetScheduler() {
  BGTaskScheduler.shared._resetPortableState()
}

private func bridgedDomain<E: Foundation._BridgedStoredNSError>(_: E.Type) -> String {
  E._nsErrorDomain
}

private func errorTypeName<C: Foundation._ErrorCodeProtocol>(_: C.Type) -> String {
  String(describing: C._ErrorType.self)
}

func testErrorDomain() {
  precondition(BGTaskScheduler.errorDomain == "BGTaskSchedulerErrorDomain")
  precondition(BGTaskScheduler.Error.errorDomain == "BGTaskSchedulerErrorDomain")
  precondition(BGTaskScheduler.Error.errorDomain == BGTaskScheduler.errorDomain)
  precondition(BGTaskScheduler.Error._nsErrorDomain == BGTaskScheduler.errorDomain)
}

func testErrorCodes() {
  typealias Code = BGTaskScheduler.Error.Code
  precondition(Code.unavailable.rawValue == 1)
  precondition(Code.tooManyPendingTaskRequests.rawValue == 2)
  precondition(Code.notPermitted.rawValue == 3)
  precondition(Code.immediateRunIneligible.rawValue == 4)
  precondition(BGTaskScheduler.Error.unavailable == .unavailable)
  precondition(BGTaskScheduler.Error.tooManyPendingTaskRequests == .tooManyPendingTaskRequests)
  precondition(BGTaskScheduler.Error.notPermitted == .notPermitted)
  precondition(BGTaskScheduler.Error.immediateRunIneligible == .immediateRunIneligible)
  precondition(Code(rawValue: 1) == .unavailable)
  precondition(Code(rawValue: 4) == .immediateRunIneligible)
  precondition(Code(rawValue: 0) == nil)
  precondition(Code(rawValue: 5) == nil)
  precondition(Code.unavailable.hashValue == Code.unavailable.hashValue)
  precondition(Code.unavailable != .notPermitted)
  var hasher = Hasher()
  Code.immediateRunIneligible.hash(into: &hasher)
  _ = hasher.finalize()
}

func testErrorEqualityAndHash() {
  let empty = BGTaskScheduler.Error(.unavailable)
  precondition(empty.userInfo.isEmpty)
  precondition(empty.errorUserInfo.isEmpty)
  precondition(empty.errorCode == 1)
  precondition(empty.code == .unavailable)
  precondition(!empty.localizedDescription.isEmpty)

  let sentinel = BGTaskScheduler.Error(.unavailable, userInfo: ["sentinel": "value"])
  precondition(sentinel.userInfo["sentinel"] as? String == "value")
  precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
  precondition(empty == BGTaskScheduler.Error(.unavailable))
  precondition(sentinel != empty)
  precondition(
    BGTaskScheduler.Error(.unavailable, userInfo: ["x": 1]) !=
      BGTaskScheduler.Error(.unavailable, userInfo: ["x": "1"])
  )
  precondition(empty.hashValue == sentinel.hashValue)
  precondition(empty != BGTaskScheduler.Error(.notPermitted))

  var hasherA = Hasher()
  var hasherB = Hasher()
  empty.hash(into: &hasherA)
  BGTaskScheduler.Error(.unavailable).hash(into: &hasherB)
  precondition(hasherA.finalize() == hasherB.finalize())
}

func testErrorPatternMatch() {
  let error: any Error = BGTaskScheduler.Error(.notPermitted)
  precondition(BGTaskScheduler.Error.Code.notPermitted ~= error)
  precondition(!(BGTaskScheduler.Error.Code.unavailable ~= error))
  do {
    throw BGTaskScheduler.Error(.tooManyPendingTaskRequests)
  } catch let caught as BGTaskScheduler.Error where caught.code == .tooManyPendingTaskRequests {
    ()
  } catch {
    preconditionFailure("expected Code.tooManyPendingTaskRequests pattern match")
  }
}

func testErrorNSErrorBridge() {
  let userInfo: [String: Any] = ["bg": "bridge"]
  let typed = BGTaskScheduler.Error(.immediateRunIneligible, userInfo: userInfo)
  precondition(typed._nsError.domain == BGTaskScheduler.errorDomain)
  precondition(typed._nsError.code == 4)
  precondition(typed._nsError.userInfo["bg"] as? String == "bridge")

  let bridged = typed as NSError
  precondition(bridged.domain == BGTaskScheduler.errorDomain)
  precondition(bridged.code == BGTaskScheduler.Error.Code.immediateRunIneligible.rawValue)
  precondition(bridged.userInfo["bg"] as? String == "bridge")

  let fromStored = BGTaskScheduler.Error(_nsError: typed._nsError)
  precondition(fromStored.code == .immediateRunIneligible)
  precondition(fromStored.userInfo["bg"] as? String == "bridge")
  precondition(fromStored == typed)

  do {
    throw typed
  } catch let caught as BGTaskScheduler.Error {
    precondition(caught.code == .immediateRunIneligible)
    precondition(caught.userInfo["bg"] as? String == "bridge")
  } catch {
    preconditionFailure("expected throw/catch BGTaskScheduler.Error round trip")
  }

  let nsRoundTrip = bridged as? BGTaskScheduler.Error
  _ = nsRoundTrip
}

func testErrorProtocolConformance() {
  precondition(bridgedDomain(BGTaskScheduler.Error.self) == BGTaskScheduler.errorDomain)
  precondition(
    errorTypeName(BGTaskScheduler.Error.Code.self)
      == String(describing: BGTaskScheduler.Error.self)
  )

  let error = BGTaskScheduler.Error(.tooManyPendingTaskRequests)
  var hasher = Hasher()
  error.hash(into: &hasher)
  _ = hasher.finalize()
  _ = error.hashValue

  var seen: Set<Int> = []
  seen.insert(error.hashValue)
  seen.insert(BGTaskScheduler.Error(.tooManyPendingTaskRequests).hashValue)
  precondition(seen.count == 1)
}

func testResourcesOptionSet() {
  typealias Resources = BGContinuedProcessingTaskRequest.Resources
  precondition(Resources.gpu.rawValue == 1)
  precondition(Resources().isEmpty)
  precondition(Resources(rawValue: 0).isEmpty)
  precondition(Resources.gpu != Resources())

  var resources: Resources = [.gpu]
  precondition(resources.contains(.gpu))
  let inserted = resources.insert(.gpu)
  precondition(!inserted.inserted)
  precondition(resources.remove(.gpu) == .gpu)
  precondition(!resources.contains(.gpu))
  precondition(resources.update(with: .gpu) == nil)

  let union = Resources().union(.gpu)
  precondition(union.contains(.gpu))
  let intersection = Resources.gpu.intersection(.gpu)
  precondition(intersection == .gpu)
  let difference = Resources.gpu.symmetricDifference(Resources())
  precondition(difference.contains(.gpu))
  precondition(Resources().isSubset(of: .gpu))
  precondition(Resources.gpu.isSuperset(of: Resources()))
  precondition(Resources().isDisjoint(with: .gpu))
  precondition(Resources().isStrictSubset(of: .gpu))
  precondition(Resources.gpu.isStrictSuperset(of: Resources()))
  precondition(Resources.gpu.subtracting(.gpu).isEmpty)

  var mutating = Resources.gpu
  mutating.formUnion(Resources())
  mutating.formIntersection(.gpu)
  mutating.formSymmetricDifference(.gpu)
  mutating.subtract(Resources())
  precondition(mutating.isEmpty)

  let fromSequence = Resources([.gpu, .gpu])
  precondition(fromSequence.contains(.gpu))
  let fromLiteral: Resources = [.gpu]
  precondition(fromLiteral.contains(.gpu))
}

func testSubmissionStrategy() {
  typealias Strategy = BGContinuedProcessingTaskRequest.SubmissionStrategy
  precondition(Strategy.fail.rawValue == 0)
  precondition(Strategy.queue.rawValue == 1)
  precondition(Strategy(rawValue: 0) == .fail)
  precondition(Strategy(rawValue: 1) == .queue)
  precondition(Strategy(rawValue: 2) == nil)
  precondition(Strategy.fail != .queue)
  precondition(Strategy.fail.hashValue == Strategy.fail.hashValue)
  var hasher = Hasher()
  Strategy.queue.hash(into: &hasher)
  _ = hasher.finalize()
}

func testAppRefreshRequestCopyAndIdentity() {
  resetScheduler()
  let request = BGAppRefreshTaskRequest(identifier: "refresh.copy")
  request.earliestBeginDate = Date(timeIntervalSince1970: 42)
  let copied = request.copy() as! BGAppRefreshTaskRequest
  precondition(copied !== request)
  precondition(copied.identifier == "refresh.copy")
  precondition(copied.earliestBeginDate == request.earliestBeginDate)
  copied.earliestBeginDate = Date(timeIntervalSince1970: 99)
  precondition(request.earliestBeginDate == Date(timeIntervalSince1970: 42))
}

func testProcessingRequestFlags() {
  let request = BGProcessingTaskRequest(identifier: "processing.flags")
  precondition(request.identifier == "processing.flags")
  precondition(request.requiresNetworkConnectivity == false)
  precondition(request.requiresExternalPower == false)
  request.requiresNetworkConnectivity = true
  request.requiresExternalPower = true
  let copied = request.copy() as! BGProcessingTaskRequest
  precondition(copied.requiresNetworkConnectivity)
  precondition(copied.requiresExternalPower)
  copied.requiresNetworkConnectivity = false
  precondition(request.requiresNetworkConnectivity)
}

func testContinuedProcessingRequestDefaultsAndCopy() {
  let request = BGContinuedProcessingTaskRequest(
    identifier: "continued.copy",
    title: "Export",
    subtitle: "Videos"
  )
  precondition(request.identifier == "continued.copy")
  precondition(request.title == "Export")
  precondition(request.subtitle == "Videos")
  precondition(request.strategy == .fail)
  precondition(request.requiredResources.isEmpty)
  request.strategy = .queue
  request.requiredResources = .gpu
  request.title = "Encode"
  request.subtitle = "HDR"
  let copied = request.copy() as! BGContinuedProcessingTaskRequest
  precondition(copied.title == "Encode")
  precondition(copied.subtitle == "HDR")
  precondition(copied.strategy == .queue)
  precondition(copied.requiredResources.contains(.gpu))
  copied.strategy = .fail
  precondition(request.strategy == .queue)
}

func testHealthResearchRequest() {
  let request = BGHealthResearchTaskRequest(identifier: "health.copy")
  precondition(request.identifier == "health.copy")
  precondition((request.protectionTypeOfRequiredData as String).isEmpty)
  precondition(request.requiresNetworkConnectivity == false)
  let protection = NSString(string: "NSFileProtectionComplete")
  request.protectionTypeOfRequiredData = protection
  request.requiresNetworkConnectivity = true
  request.requiresExternalPower = true
  let copied = request.copy() as! BGHealthResearchTaskRequest
  precondition(copied.protectionTypeOfRequiredData == protection)
  precondition(copied.requiresNetworkConnectivity)
  precondition(copied.requiresExternalPower)
  copied.protectionTypeOfRequiredData = NSString(string: "other")
  precondition(request.protectionTypeOfRequiredData == protection)
}

func testRegisterAndDuplicate() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  precondition(scheduler === BGTaskScheduler.shared)
  var launches = 0
  precondition(
    scheduler.register(forTaskWithIdentifier: "reg.one", using: nil) { _ in
      launches += 1
    }
  )
  precondition(
    !scheduler.register(forTaskWithIdentifier: "reg.one", using: nil) { _ in }
  )
  precondition(!scheduler.register(forTaskWithIdentifier: "", using: nil) { _ in })
  scheduler._setPortableAvailability(true, permittedIdentifiers: ["reg.allowed"])
  precondition(
    !scheduler.register(forTaskWithIdentifier: "reg.denied", using: nil) { _ in }
  )
  precondition(
    scheduler.register(forTaskWithIdentifier: "reg.allowed", using: nil) { _ in }
  )
  precondition(launches == 0)
}

func testSubmitCopyOnWrite() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  precondition(
    scheduler.register(forTaskWithIdentifier: "submit.copy", using: nil) { _ in }
  )
  let request = BGAppRefreshTaskRequest(identifier: "submit.copy")
  try! scheduler.submit(request)
  request.earliestBeginDate = .distantFuture
  var pending: [BGTaskRequest] = []
  scheduler.getPendingTaskRequests { pending = $0 }
  precondition(pending.count == 1)
  precondition(pending[0].identifier == "submit.copy")
  precondition(pending[0].earliestBeginDate == nil)
  precondition(pending[0] is BGAppRefreshTaskRequest)
}

func testPendingAndCancel() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  try! scheduler.submit(BGAppRefreshTaskRequest(identifier: "one"))
  try! scheduler.submit(BGAppRefreshTaskRequest(identifier: "two"))
  var identifiers: [String] = []
  scheduler.getPendingTaskRequests { identifiers = $0.map(\.identifier) }
  precondition(identifiers == ["one", "two"])
  scheduler.cancel(taskRequestWithIdentifier: "one")
  scheduler.getPendingTaskRequests { identifiers = $0.map(\.identifier) }
  precondition(identifiers == ["two"])
  scheduler.cancelAllTaskRequests()
  scheduler.getPendingTaskRequests { identifiers = $0.map(\.identifier) }
  precondition(identifiers.isEmpty)
}

func testUnavailableAndNotPermitted() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  scheduler._setPortableAvailability(false)
  do {
    try scheduler.submit(BGAppRefreshTaskRequest(identifier: "unavailable"))
    preconditionFailure("unavailable scheduler accepted work")
  } catch let error as BGTaskScheduler.Error {
    precondition(error.code == .unavailable)
    precondition((error as NSError).code == BGTaskScheduler.Error.Code.unavailable.rawValue)
    precondition((error as NSError).domain == BGTaskScheduler.errorDomain)
  } catch {
    preconditionFailure("unexpected scheduler error")
  }

  scheduler._resetPortableState()
  scheduler._setPortableAvailability(true, permittedIdentifiers: ["allowed"])
  do {
    try scheduler.submit(BGAppRefreshTaskRequest(identifier: "denied"))
    preconditionFailure("unpermitted identifier was accepted")
  } catch let error as BGTaskScheduler.Error {
    precondition(error.code == .notPermitted)
  } catch {
    preconditionFailure("unexpected scheduler error")
  }
  try! scheduler.submit(BGAppRefreshTaskRequest(identifier: "allowed"))
}

func testTooManyPending() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  for index in 0..<10 {
    try! scheduler.submit(BGAppRefreshTaskRequest(identifier: "cap.\(index)"))
  }
  do {
    try scheduler.submit(BGAppRefreshTaskRequest(identifier: "cap.overflow"))
    preconditionFailure("pending cap was not enforced")
  } catch let error as BGTaskScheduler.Error {
    precondition(error.code == .tooManyPendingTaskRequests)
  } catch {
    preconditionFailure("unexpected scheduler error")
  }
}

func testLaunchRefreshAndProcessing() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  var refreshLaunches = 0
  precondition(
    scheduler.register(forTaskWithIdentifier: "launch.refresh", using: nil) { task in
      precondition(task is BGAppRefreshTask)
      precondition(task.identifier == "launch.refresh")
      refreshLaunches += 1
      task.setTaskCompleted(success: true)
    }
  )
  try! scheduler.submit(BGAppRefreshTaskRequest(identifier: "launch.refresh"))
  let refreshTask = scheduler._launchPortableTask(withIdentifier: "launch.refresh")
  precondition(refreshLaunches == 1)
  precondition(refreshTask is BGAppRefreshTask)
  precondition(refreshTask?._portableCompletion == true)

  var processingLaunches = 0
  precondition(
    scheduler.register(forTaskWithIdentifier: "launch.processing", using: nil) { task in
      precondition(task is BGProcessingTask)
      processingLaunches += 1
      task.setTaskCompleted(success: false)
    }
  )
  let processing = BGProcessingTaskRequest(identifier: "launch.processing")
  processing.requiresNetworkConnectivity = true
  processing.requiresExternalPower = true
  processing.earliestBeginDate = .distantFuture
  try! scheduler.submit(processing)
  precondition(scheduler._launchPortableTask(withIdentifier: "launch.processing") == nil)
  let processingTask = scheduler._launchPortableTask(
    withIdentifier: "launch.processing",
    ignoringEarliestBeginDate: true
  )
  precondition(processingLaunches == 1)
  precondition(processingTask is BGProcessingTask)
  precondition(processingTask?._portableCompletion == false)
}

func testLaunchHonorsQueueAndExpiration() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  let queue = DispatchQueue(label: "portable.processing.queue")
  let queueKey = DispatchSpecificKey<String>()
  queue.setSpecific(key: queueKey, value: "processing")
  let launched = DispatchSemaphore(value: 0)
  precondition(
    scheduler.register(forTaskWithIdentifier: "queue.processing", using: queue) { task in
      precondition(task is BGProcessingTask)
      precondition(DispatchQueue.getSpecific(key: queueKey) == "processing")
      task.expirationHandler = { task.setTaskCompleted(success: false) }
      launched.signal()
    }
  )
  try! scheduler.submit(BGProcessingTaskRequest(identifier: "queue.processing"))
  let processingTask = scheduler._launchPortableTask(withIdentifier: "queue.processing")
  precondition(launched.wait(timeout: .now() + 2) == .success)
  processingTask?._expirePortableTask()
  processingTask?._expirePortableTask()
  precondition(processingTask?._portableCompletion == false)
}

func testContinuedProcessingLaunchAndUpdateTitle() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  var launched: BGContinuedProcessingTask?
  precondition(
    scheduler.register(forTaskWithIdentifier: "launch.continued", using: nil) { task in
      launched = task as? BGContinuedProcessingTask
      task.setTaskCompleted(success: true)
    }
  )
  let request = BGContinuedProcessingTaskRequest(
    identifier: "launch.continued",
    title: "Export",
    subtitle: "Videos"
  )
  request.requiredResources = .gpu
  request.strategy = .queue
  try! scheduler.submit(request)
  let task = scheduler._launchPortableTask(withIdentifier: "launch.continued")
    as? BGContinuedProcessingTask
  precondition(task != nil)
  precondition(launched === task)
  precondition(task?.title == "Export")
  precondition(task?.subtitle == "Videos")
  precondition(task?.progress.totalUnitCount == 1)
  task?.updateTitle("Almost done", subtitle: "Last file")
  precondition(task?.title == "Almost done")
  precondition(task?.subtitle == "Last file")
  precondition(task?._portableCompletion == true)
}

func testHealthResearchLaunch() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  var launched: BGHealthResearchTask?
  precondition(
    scheduler.register(forTaskWithIdentifier: "launch.health", using: nil) { task in
      launched = task as? BGHealthResearchTask
      precondition(task is BGProcessingTask)
      task.setTaskCompleted(success: true)
    }
  )
  try! scheduler.submit(BGHealthResearchTaskRequest(identifier: "launch.health"))
  let task = scheduler._launchPortableTask(withIdentifier: "launch.health")
  precondition(task is BGHealthResearchTask)
  precondition(launched === task)
  precondition(task?._portableCompletion == true)
}

func testSupportedResourcesLinuxEmpty() {
  precondition(BGTaskScheduler.supportedResources.isEmpty)
  precondition(!BGTaskScheduler.supportedResources.contains(.gpu))
}

func testSetTaskCompletedIdempotent() {
  resetScheduler()
  let scheduler = BGTaskScheduler.shared
  var taskRef: BGTask?
  precondition(
    scheduler.register(forTaskWithIdentifier: "complete.once", using: nil) { task in
      taskRef = task
      task.setTaskCompleted(success: true)
      task.setTaskCompleted(success: false)
    }
  )
  try! scheduler.submit(BGAppRefreshTaskRequest(identifier: "complete.once"))
  _ = scheduler._launchPortableTask(withIdentifier: "complete.once")
  precondition(taskRef?._portableCompletion == true)
}

func testNSCopyingRoundTripTypes() {
  let refresh: Any = BGAppRefreshTaskRequest(identifier: "copy.refresh").copy()
  precondition(refresh is BGAppRefreshTaskRequest)
  let processing: Any = BGProcessingTaskRequest(identifier: "copy.processing").copy()
  precondition(processing is BGProcessingTaskRequest)
  let continued: Any = BGContinuedProcessingTaskRequest(
    identifier: "copy.continued",
    title: "t",
    subtitle: "s"
  ).copy()
  precondition(continued is BGContinuedProcessingTaskRequest)
  let health: Any = BGHealthResearchTaskRequest(identifier: "copy.health").copy()
  precondition(health is BGHealthResearchTaskRequest)
}
