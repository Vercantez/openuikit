import Foundation
import AlarmKit

func testAlarmUpdatesTypesAndEmptyNext() {
    let _: AlarmManager.AlarmUpdates.Element.Type = [Alarm].self
    let _: AlarmManager.AlarmUpdates.AsyncIterator.Type =
        AlarmManager.AlarmUpdates.Iterator.self
    let _: AlarmManager.AlarmUpdates.Iterator.Element.Type = [Alarm].self
    alarmKitRunBlocking {
        var iterator = AlarmManager.AlarmUpdates().makeAsyncIterator()
        let element: [Alarm]? = await iterator.next()
        alarmKitExpect(element == nil, "alarmUpdates is empty")
        var opaque = AlarmManager.shared.alarmUpdates.makeAsyncIterator()
        let opaqueElement: [Alarm]? = try await opaque.next()
        alarmKitExpect(opaqueElement == nil, "opaque alarmUpdates is empty")
    }
}

func testAlarmUpdatesNextIsolation() {
    alarmKitRunBlocking {
        var iterator = AlarmManager.AlarmUpdates().makeAsyncIterator()
        let isolated: [Alarm]? = await iterator.next(isolation: nil)
        alarmKitExpect(isolated == nil, "next(isolation:) is empty")
    }
}

func testAuthorizationUpdatesTypesAndEmptyNext() {
    let _: AlarmManager.AlarmAuthorizationStateUpdates.Element.Type =
        AlarmManager.AuthorizationState.self
    let _: AlarmManager.AlarmAuthorizationStateUpdates.AsyncIterator.Type =
        AlarmManager.AlarmAuthorizationStateUpdates.Iterator.self
    let _: AlarmManager.AlarmAuthorizationStateUpdates.Iterator.Element.Type =
        AlarmManager.AuthorizationState.self
    alarmKitRunBlocking {
        var iterator = AlarmManager.AlarmAuthorizationStateUpdates().makeAsyncIterator()
        let element: AlarmManager.AuthorizationState? = await iterator.next()
        alarmKitExpect(element == nil, "authorizationUpdates is empty")
        var opaque = AlarmManager.shared.authorizationUpdates.makeAsyncIterator()
        let opaqueElement: AlarmManager.AuthorizationState? = try await opaque.next()
        alarmKitExpect(opaqueElement == nil, "opaque authorizationUpdates is empty")
    }
}

func testAuthorizationUpdatesNextIsolation() {
    alarmKitRunBlocking {
        var iterator = AlarmManager.AlarmAuthorizationStateUpdates().makeAsyncIterator()
        let isolated: AlarmManager.AuthorizationState? =
            await iterator.next(isolation: nil)
        alarmKitExpect(isolated == nil, "auth next(isolation:) is empty")
    }
}
