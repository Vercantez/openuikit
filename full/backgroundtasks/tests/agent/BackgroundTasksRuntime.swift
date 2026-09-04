import BackgroundTasks
import Dispatch
import Foundation

/// Schema-v2 sealed acceptance compiles `tests/agent/*Tests.swift` and the
/// generated load-smoke runner. This file records the runtime contract those
/// tests exercise: process-local scheduling, copy-on-submit, Darwin-shaped
/// `BGTaskScheduler.Error`, and fail-closed continued-processing resources.
enum BackgroundTasksRuntime {
  static let errorDomain = "BGTaskSchedulerErrorDomain"
  static let portablePendingLimit = 10
}
