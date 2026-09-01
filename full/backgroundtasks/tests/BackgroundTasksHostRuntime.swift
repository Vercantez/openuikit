import Foundation
import Dispatch
@_spi(OpenUIKitHost) import BackgroundTasks

@main
private struct BackgroundTasksHostRuntime {
  static func main() async {
    let scheduler = BGTaskScheduler.shared
    scheduler._resetPortableState()

    var refreshLaunches = 0
    precondition(scheduler.register(
      forTaskWithIdentifier: "portable.refresh",
      using: nil
    ) { task in
      precondition(task is BGAppRefreshTask)
      refreshLaunches += 1
      task.setTaskCompleted(success: true)
    })
    precondition(!scheduler.register(
      forTaskWithIdentifier: "portable.refresh",
      using: nil
    ) { _ in })

    let refresh = BGAppRefreshTaskRequest(identifier: "portable.refresh")
    try! scheduler.submit(refresh)
    refresh.earliestBeginDate = .distantFuture
    let copied = await scheduler.pendingTaskRequests()
    precondition(copied.count == 1)
    precondition(copied[0].earliestBeginDate == nil)

    let refreshTask = scheduler._launchPortableTask(
      withIdentifier: "portable.refresh"
    )
    precondition(refreshLaunches == 1)
    precondition(refreshTask is BGAppRefreshTask)
    precondition(refreshTask?._portableCompletion == true)

    let queue = DispatchQueue(label: "portable.processing")
    let queueKey = DispatchSpecificKey<String>()
    queue.setSpecific(key: queueKey, value: "processing")
    let launched = DispatchSemaphore(value: 0)
    precondition(scheduler.register(
      forTaskWithIdentifier: "portable.processing",
      using: queue
    ) { task in
      precondition(task is BGProcessingTask)
      precondition(DispatchQueue.getSpecific(key: queueKey) == "processing")
      task.expirationHandler = { task.setTaskCompleted(success: false) }
      launched.signal()
    })

    let processing = BGProcessingTaskRequest(identifier: "portable.processing")
    processing.requiresNetworkConnectivity = true
    processing.requiresExternalPower = true
    processing.earliestBeginDate = .distantFuture
    try! scheduler.submit(processing)
    precondition(scheduler._launchPortableTask(
      withIdentifier: "portable.processing"
    ) == nil)
    let processingTask = scheduler._launchPortableTask(
      withIdentifier: "portable.processing",
      ignoringEarliestBeginDate: true
    )
    precondition(launched.wait(timeout: .now() + 2) == .success)
    processingTask?._expirePortableTask()
    precondition(processingTask?._portableCompletion == false)

    let one = BGAppRefreshTaskRequest(identifier: "one")
    let two = BGAppRefreshTaskRequest(identifier: "two")
    try! scheduler.submit(one)
    try! scheduler.submit(two)
    var callbackIdentifiers: [String] = []
    scheduler.getPendingTaskRequests {
      callbackIdentifiers = $0.map(\.identifier)
    }
    precondition(callbackIdentifiers == ["one", "two"])
    scheduler.cancel(taskRequestWithIdentifier: "one")
    let afterSingleCancel = await scheduler.pendingTaskRequests()
    precondition(afterSingleCancel.map(\.identifier) == ["two"])
    scheduler.cancelAllTaskRequests()
    let afterCancelAll = await scheduler.pendingTaskRequests()
    precondition(afterCancelAll.isEmpty)

    scheduler._setPortableAvailability(false)
    do {
      try scheduler.submit(BGAppRefreshTaskRequest(identifier: "unavailable"))
      preconditionFailure("unavailable scheduler accepted work")
    } catch let error as BGTaskScheduler.Error {
      precondition(error == .unavailable)
      precondition((error as NSError).code == BGTaskScheduler.Error.Code.unavailable.rawValue)
    } catch {
      preconditionFailure("unexpected scheduler error")
    }

    scheduler._resetPortableState()
    print(
      "BACKGROUNDTASKS_HOST_OK requests=refresh,processing "
        + "scheduler=register,copy,pending,cancel queue=honored "
        + "lifecycle=launch,expire,complete errors=darwin-shaped"
    )
  }
}
