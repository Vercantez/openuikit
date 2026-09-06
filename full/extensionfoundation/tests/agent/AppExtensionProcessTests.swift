@_spi(OpenUIKitHost) import ExtensionFoundation

private func sampleIdentity() -> AppExtensionIdentity {
    AppExtensionIdentity(
        bundleIdentifier: "com.example.ext",
        extensionPointIdentifier: "editor",
        localizedName: "Editor"
    )
}

func testProcessConfigurationStoresIdentity() {
    let identity = sampleIdentity()
    let configuration = AppExtensionProcess.Configuration(
        appExtensionIdentity: identity
    )
    precondition(configuration.appExtensionIdentity == identity)
}

func testProcessConfigurationDefaultInterruptionIsHarmless() {
    let configuration = AppExtensionProcess.Configuration(
        appExtensionIdentity: sampleIdentity()
    )
    configuration.onInterruption()
}

func testProcessConfigurationCustomInterruption() {
    final class Flag: @unchecked Sendable {
        var value = false
    }
    let flag = Flag()
    var configuration = AppExtensionProcess.Configuration(
        appExtensionIdentity: sampleIdentity(),
        onInterruption: { flag.value = true }
    )
    precondition(flag.value == false)
    configuration.onInterruption()
    precondition(flag.value == true)
    configuration.onInterruption = {}
    configuration.onInterruption()
    precondition(flag.value == true)
}

func testProcessConfigurationIdentityMutation() {
    var configuration = AppExtensionProcess.Configuration(
        appExtensionIdentity: sampleIdentity()
    )
    let other = AppExtensionIdentity(
        bundleIdentifier: "com.example.other",
        extensionPointIdentifier: "other",
        localizedName: "Other"
    )
    configuration.appExtensionIdentity = other
    precondition(configuration.appExtensionIdentity.bundleIdentifier == "com.example.other")
}

func testProcessInitThrowsProcessUnavailable() {
    let configuration = AppExtensionProcess.Configuration(
        appExtensionIdentity: sampleIdentity()
    )
    do {
        _ = try AppExtensionProcess(configuration: configuration)
        preconditionFailure("process init must throw")
    } catch let error as ExtensionFoundationHostError {
        precondition(error == .processUnavailable)
        precondition(error.errorCode == 2)
        precondition(ExtensionFoundationHostError.errorDomain == "ExtensionFoundation.Linux")
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testProcessMakeXPCConnectionThrows() {
    let process = AppExtensionProcess(hostUnlaunched: AppExtensionProcess.Configuration(
        appExtensionIdentity: sampleIdentity()
    ))
    do {
        _ = try process.makeXPCConnection()
        preconditionFailure("makeXPCConnection must throw")
    } catch let error as ExtensionFoundationHostError {
        precondition(error == .xpcUnavailable)
        precondition(error.errorCode == 3)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testProcessMakeXPCSessionThrows() {
    let process = AppExtensionProcess(hostUnlaunched: AppExtensionProcess.Configuration(
        appExtensionIdentity: sampleIdentity()
    ))
    do {
        _ = try process.makeXPCSession()
        preconditionFailure("makeXPCSession must throw")
    } catch let error as ExtensionFoundationHostError {
        precondition(error == .xpcUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testProcessInvalidateIsLocalNoOp() {
    let process = AppExtensionProcess(hostUnlaunched: AppExtensionProcess.Configuration(
        appExtensionIdentity: sampleIdentity()
    ))
    precondition(process.host_isInvalidated == false)
    process.invalidate()
    precondition(process.host_isInvalidated == true)
    process.invalidate()
    precondition(process.host_isInvalidated == true)
}

func testUnlaunchedProcessPreservesIdentity() {
    let identity = sampleIdentity()
    let process = AppExtensionProcess(hostUnlaunched: AppExtensionProcess.Configuration(
        appExtensionIdentity: identity
    ))
    precondition(process.host_configuration.appExtensionIdentity == identity)
}
