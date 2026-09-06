import Dispatch
import Foundation
@_spi(OpenUIKitHost) import ScreenTime

func testConfigurationObserverType() {
    let queue = DispatchQueue(label: "screentime.observer.type")
    let observer = STScreenTimeConfigurationObserver(updateQueue: queue)
    precondition(type(of: observer) == STScreenTimeConfigurationObserver.self)
    let object: NSObject = observer
    precondition(object === observer)
}

func testConfigurationObserverInitUpdateQueue() {
    let queue = DispatchQueue(label: "screentime.observer.init")
    let observer = STScreenTimeConfigurationObserver(updateQueue: queue)
    precondition(observer.updateQueue === queue)
    precondition(observer.isObserving == false)
}

func testConfigurationObserverStartObserving() {
    let queue = DispatchQueue(label: "screentime.observer.start")
    let observer = STScreenTimeConfigurationObserver(updateQueue: queue)
    observer.startObserving()
    precondition(observer.isObserving)
    observer.startObserving()
    precondition(observer.isObserving)
}

func testConfigurationObserverStopObserving() {
    let queue = DispatchQueue(label: "screentime.observer.stop")
    let observer = STScreenTimeConfigurationObserver(updateQueue: queue)
    observer.startObserving()
    observer.stopObserving()
    precondition(observer.isObserving == false)
    observer.stopObserving()
    precondition(observer.isObserving == false)
}

func testConfigurationObserverConfigurationNil() {
    let queue = DispatchQueue(label: "screentime.observer.configuration")
    let observer = STScreenTimeConfigurationObserver(updateQueue: queue)
    precondition(observer.configuration == nil)
    observer.startObserving()
    precondition(observer.configuration == nil)
    observer.stopObserving()
    precondition(observer.configuration == nil)
}
