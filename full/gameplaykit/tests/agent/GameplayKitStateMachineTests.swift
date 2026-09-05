import Foundation
import GameplayKit

private final class LoadState: GKState {
    var entered = false
    var exited = false
    var updated = 0
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ReadyState.self
    }
    override func didEnter(from previousState: GKState?) {
        entered = true
    }
    override func willExit(to nextState: GKState) {
        exited = true
    }
    override func update(deltaTime seconds: TimeInterval) {
        updated += 1
        _ = seconds
    }
}

private final class ReadyState: GKState {
    var enteredFromLoad = false
    override func didEnter(from previousState: GKState?) {
        enteredFromLoad = previousState is LoadState
    }
}

private final class BounceState: GKState {
    var enterCount = 0
    override func didEnter(from previousState: GKState?) {
        enterCount += 1
        if enterCount == 1 {
            _ = stateMachine?.enter(LandState.self)
        }
    }
}

private final class LandState: GKState {
    var enterCount = 0
    override func didEnter(from previousState: GKState?) {
        enterCount += 1
    }
}

func testStateMachineTransitions() {
    let load = LoadState()
    let ready = ReadyState()
    let machine = GKStateMachine(states: [load, ready])
    precondition(load.stateMachine === machine)
    precondition(machine.currentState == nil)
    precondition(machine.enter(LoadState.self))
    precondition(machine.currentState === load)
    precondition(load.entered)
    precondition(machine.canEnterState(ReadyState.self))
    precondition(!machine.canEnterState(LoadState.self) || load.isValidNextState(ReadyState.self))
    precondition(machine.enter(ReadyState.self))
    precondition(ready.enteredFromLoad)
    precondition(load.exited)
    precondition(machine.state(forClass: LoadState.self) === load)
    precondition(machine.state(forClass: ReadyState.self) === ready)
}

func testStateMachineReentrantEnterAndUpdate() {
    let bounce = BounceState()
    let land = LandState()
    let reentrant = GKStateMachine(states: [bounce, land])
    precondition(reentrant.enter(BounceState.self))
    precondition(reentrant.currentState === land)
    precondition(bounce.enterCount == 1)
    precondition(land.enterCount == 1)
    reentrant.update(deltaTime: 0.016)
    let load = LoadState()
    let ready = ReadyState()
    let timed = GKStateMachine(states: [load, ready])
    precondition(timed.enter(LoadState.self))
    timed.update(deltaTime: 1)
    precondition(load.updated == 1)
    precondition(!timed.enter(NSObject.self))
    precondition(timed.canEnterState(ReadyState.self))
    precondition(!timed.canEnterState(NSString.self))
}
