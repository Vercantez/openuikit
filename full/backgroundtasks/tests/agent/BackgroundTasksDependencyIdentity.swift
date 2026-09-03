import BackgroundTasks
import Foundation

/// Compiled against the product module on the clean EC2 integration build.
/// Isolated Linux hosts still typecheck Foundation values through public APIs.
func backgroundTasksDependencyIdentityProbe() {
  let begin = Date(timeIntervalSince1970: 1_700_000_000)
  let refresh = BGAppRefreshTaskRequest(identifier: "identity.refresh")
  refresh.earliestBeginDate = begin
  precondition(refresh.earliestBeginDate == begin)
  precondition(refresh.identifier == "identity.refresh")

  let processing = BGProcessingTaskRequest(identifier: "identity.processing")
  processing.requiresNetworkConnectivity = true
  processing.requiresExternalPower = true
  processing.earliestBeginDate = begin
  precondition(processing.requiresNetworkConnectivity)
  precondition(processing.requiresExternalPower)

  let protection = NSString(string: "NSFileProtectionComplete")
  let health = BGHealthResearchTaskRequest(identifier: "identity.health")
  health.protectionTypeOfRequiredData = protection
  precondition(health.protectionTypeOfRequiredData.isEqual(to: protection as String))

  let continued = BGContinuedProcessingTaskRequest(
    identifier: "identity.continued",
    title: "Export",
    subtitle: "Videos"
  )
  continued.earliestBeginDate = begin
  continued.requiredResources = .gpu
  precondition(continued.earliestBeginDate == begin)
  precondition(continued.requiredResources.contains(.gpu))

  _ = BGTaskScheduler.shared
  _ = BGTaskScheduler.errorDomain
  let error = BGTaskScheduler.Error(.unavailable)
  let nsError = error as NSError
  precondition(nsError.domain == BGTaskScheduler.errorDomain)
  precondition(nsError.code == BGTaskScheduler.Error.Code.unavailable.rawValue)
}
