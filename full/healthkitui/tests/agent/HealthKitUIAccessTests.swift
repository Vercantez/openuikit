import Foundation
@_spi(OpenUIKitHost) import HealthKitUI

func testAuthorizationViewControllerPresenter() {
    let store = HKHealthStore()
    precondition(store.authorizationViewControllerPresenter == nil)

    let presenter = UIViewController()
    store.authorizationViewControllerPresenter = presenter
    precondition(store.authorizationViewControllerPresenter === presenter)

    store.authorizationViewControllerPresenter = nil
    precondition(store.authorizationViewControllerPresenter == nil)
}

func testHealthDataAccessRequestShareTypes() {
    HealthKitUIHostControl.resetAccessRequests()
    let store = HKHealthStore()
    let sample = HKSampleType(identifier: "HKQuantityTypeIdentifierStepCount")
    let object = HKObjectType(identifier: "HKQuantityTypeIdentifierHeartRate")
    var invoked = false
    let view = EmptyView().healthDataAccessRequest(
        store: store,
        shareTypes: [sample],
        readTypes: [object],
        trigger: false
    ) { result in
        invoked = true
        switch result {
        case .success:
            preconditionFailure("Linux must not invent Health authorization success")
        case .failure(let error):
            let unavailable = error as? HealthKitUIUnavailable
            precondition(unavailable == .linuxHost(operation: "View.healthDataAccessRequest"))
        }
    }
    _ = view
    let pending = HealthKitUIHostControl.pendingAccessRequests()
    precondition(pending.count == 1)
    precondition(pending[0].kind == .shareAndRead)
    precondition(pending[0].shareCount == 1)
    precondition(pending[0].readCount == 1)
    precondition(!invoked)
    precondition(HealthKitUIHostControl.failClosedPendingAccessRequests() == 1)
    precondition(invoked)
    precondition(HealthKitUIHostControl.pendingAccessRequests().isEmpty)
}

func testHealthDataAccessRequestReadTypes() {
    HealthKitUIHostControl.resetAccessRequests()
    let store = HKHealthStore()
    let object = HKObjectType(identifier: "HKQuantityTypeIdentifierStepCount")
    var invoked = false
    let view = EmptyView().healthDataAccessRequest(
        store: store,
        readTypes: [object],
        trigger: true
    ) { result in
        invoked = true
        switch result {
        case .success:
            preconditionFailure("Linux must not invent Health authorization success")
        case .failure(let error):
            let unavailable = error as? HealthKitUIUnavailable
            precondition(unavailable == .linuxHost(operation: "View.healthDataAccessRequest"))
        }
    }
    _ = view
    let pending = HealthKitUIHostControl.pendingAccessRequests()
    precondition(pending.count == 1)
    precondition(pending[0].kind == .readOnly)
    precondition(pending[0].shareCount == 0)
    precondition(pending[0].readCount == 1)
    precondition(!invoked)
    precondition(HealthKitUIHostControl.failClosedPendingAccessRequests() == 1)
    precondition(invoked)
}

func testHealthDataAccessRequestObjectType() {
    HealthKitUIHostControl.resetAccessRequests()
    let store = HKHealthStore()
    let object = HKObjectType(identifier: "HKVisionPrescriptionTypeIdentifier")
    let predicate = NSPredicate(value: true)
    var invoked = false
    let view = EmptyView().healthDataAccessRequest(
        store: store,
        objectType: object,
        predicate: predicate,
        trigger: 1
    ) { result in
        invoked = true
        switch result {
        case .success:
            preconditionFailure("Linux must not invent Health authorization success")
        case .failure(let error):
            let unavailable = error as? HealthKitUIUnavailable
            precondition(unavailable == .linuxHost(operation: "View.healthDataAccessRequest"))
        }
    }
    _ = view
    let pending = HealthKitUIHostControl.pendingAccessRequests()
    precondition(pending.count == 1)
    precondition(pending[0].kind == .perObject)
    precondition(pending[0].objectTypeIdentifier == "HKVisionPrescriptionTypeIdentifier")
    precondition(pending[0].hasPredicate)
    precondition(!invoked)
    precondition(HealthKitUIHostControl.failClosedPendingAccessRequests() == 1)
    precondition(invoked)
}
