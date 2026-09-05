@_spi(OpenUIKitHost) import CoreMotion
import Foundation

func testPedometerData() {
    let pedometer = CoreMotionHostControl.makePedometerData(
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 60),
        numberOfSteps: 12,
        distance: 8.5,
        floorsAscended: 1,
        floorsDescended: 0,
        currentPace: 1.2,
        currentCadence: 1.8,
        averageActivePace: 1.1
    )
    precondition(pedometer.numberOfSteps.intValue == 12)
    precondition(pedometer.distance?.doubleValue == 8.5)
    precondition(pedometer.floorsAscended?.intValue == 1)
    precondition(pedometer.floorsDescended?.intValue == 0)
    precondition(pedometer.currentPace?.doubleValue == 1.2)
    precondition(pedometer.currentCadence?.doubleValue == 1.8)
    precondition(pedometer.averageActivePace?.doubleValue == 1.1)
    precondition(pedometer.startDate.timeIntervalSince1970 == 0)
    precondition(pedometer.endDate.timeIntervalSince1970 == 60)
    let decoded = coreMotionArchiveRoundTrip(pedometer)
    precondition(decoded.numberOfSteps.intValue == 12)
}

func testPedometerEvent() {
    let event = CoreMotionHostControl.makePedometerEvent(
        date: Date(timeIntervalSince1970: 3),
        type: .resume
    )
    precondition(event.type == .resume)
    precondition(event.date.timeIntervalSince1970 == 3)
    precondition(coreMotionArchiveRoundTrip(event).type == .resume)
}

func testOdometerData() {
    let odometer = CoreMotionHostControl.makeOdometerData(
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 5),
        deltaDistance: 10,
        deltaDistanceAccuracy: 1,
        speed: 2,
        speedAccuracy: 0.2,
        deltaAltitude: 0.5,
        verticalAccuracy: 0.3,
        originDevice: .local,
        gpsDate: Date(timeIntervalSince1970: 4),
        slope: 0.01,
        maxAbsSlope: 0.02
    )
    precondition(odometer.deltaDistance == 10)
    precondition(odometer.deltaDistanceAccuracy == 1)
    precondition(odometer.originDevice == .local)
    precondition(odometer.slope == 0.01)
    precondition(odometer.maxAbsSlope == 0.02)
    precondition(odometer.startDate.timeIntervalSince1970 == 0)
    precondition(odometer.endDate.timeIntervalSince1970 == 5)
    precondition(odometer.gpsDate.timeIntervalSince1970 == 4)
    precondition(odometer.verticalAccuracy == 0.3)
    let decoded = coreMotionArchiveRoundTrip(odometer)
    precondition(decoded.speed == 2)
    precondition(decoded.speedAccuracy == 0.2)
    precondition(decoded.deltaAltitude == 0.5)
}

func testPedometerManagerFailClosed() {
    precondition(CMPedometer.authorizationStatus() == .denied)
    precondition(!CMPedometer.isStepCountingAvailable())
    precondition(!CMPedometer.isDistanceAvailable())
    precondition(!CMPedometer.isFloorCountingAvailable())
    precondition(!CMPedometer.isPaceAvailable())
    precondition(!CMPedometer.isCadenceAvailable())
    precondition(!CMPedometer.isPedometerEventTrackingAvailable())
    let pedometer = CMPedometer()
    let handler: CMPedometerHandler = { _, _ in }
    let eventHandler: CMPedometerEventHandler = { _, _ in }
    pedometer.queryPedometerData(
        from: Date(timeIntervalSince1970: 0),
        to: Date(timeIntervalSince1970: 1),
        withHandler: handler
    )
    pedometer.startUpdates(from: Date(), withHandler: handler)
    pedometer.stopUpdates()
    pedometer.startEventUpdates(handler: eventHandler)
    pedometer.stopEventUpdates()
}
