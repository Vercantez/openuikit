import Foundation
@_spi(OpenUIKitHost) import ManagedAppDistribution

func testCurrentDistributorSingleton() {
    let a = ManagedAppLibrary.currentDistributor
    let b = ManagedAppLibrary.currentDistributor
    precondition(a === b)
}

func testAvailableAppsType() {
    let apps = ManagedAppLibrary.currentDistributor.availableApps
    _ = apps.makeAsyncIterator()
}

func testCatalogFailClosedDeviceNotManaged() {
    let snapshot = ManagedAppLibrary.currentDistributor._catalogSnapshot()
    switch snapshot {
    case .failure(.deviceNotManaged):
        break
    default:
        preconditionFailure("Linux catalog must fail closed as deviceNotManaged")
    }
}

func testManagedAppsMakeAsyncIterator() {
    let iterator = ManagedAppLibrary.currentDistributor.availableApps.makeAsyncIterator()
    _ = iterator
}

func testManagedAppsElementTypealias() {
    let sample: ManagedAppLibrary.ManagedApps.Element = .failure(.deviceNotManaged)
    switch sample {
    case .failure(.deviceNotManaged):
        break
    default:
        preconditionFailure("unexpected element")
    }
}

func testAsyncIteratorElementTypealias() {
    let sample: ManagedAppLibrary.ManagedApps.AsyncIterator.Element = .success([])
    switch sample {
    case .success(let apps):
        precondition(apps.isEmpty)
    default:
        preconditionFailure("unexpected element")
    }
}

func testAsyncIteratorFailureIsNever() {
    let never: ManagedAppLibrary.ManagedApps.AsyncIterator.Failure.Type = Never.self
    precondition(never == Never.self)
}
