import CarKey
import Foundation

func testFunctionIdentifier() {
    let a = FunctionIdentifier(42)
    let b = FunctionIdentifier(rawValue: 42)
    let c = FunctionIdentifier(7)
    precondition(a.rawValue == 42)
    precondition(b.rawValue == 42)
    precondition(a == b)
    precondition(a != c)
    precondition(!(a != b))
    var h1 = Hasher()
    var h2 = Hasher()
    a.hash(into: &h1)
    b.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(a.hashValue == b.hashValue)
    precondition(FunctionIdentifier.RawValue.self == Int.self)
    let negative = FunctionIdentifier(-3)
    precondition(negative.rawValue == -3)
}

func testActionIdentifier() {
    let a = ActionIdentifier(9)
    let b = ActionIdentifier(rawValue: 9)
    let c = ActionIdentifier(0)
    precondition(a.rawValue == 9)
    precondition(b.rawValue == 9)
    precondition(a == b)
    precondition(a != c)
    precondition(!(a != b))
    var h1 = Hasher()
    var h2 = Hasher()
    a.hash(into: &h1)
    b.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(a.hashValue == b.hashValue)
    precondition(ActionIdentifier.RawValue.self == Int.self)
}

func testFunctionStatus() {
    let a = FunctionStatus(1)
    let b = FunctionStatus(rawValue: 1)
    let c = FunctionStatus(2)
    precondition(a.rawValue == 1)
    precondition(b.rawValue == 1)
    precondition(a == b)
    precondition(a != c)
    precondition(!(a != b))
    var h1 = Hasher()
    var h2 = Hasher()
    a.hash(into: &h1)
    b.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(a.hashValue == b.hashValue)
    precondition(FunctionStatus.RawValue.self == Int.self)
}

func testExecutionStatus() {
    let a = ExecutionStatus(11)
    let b = ExecutionStatus(rawValue: 11)
    let c = ExecutionStatus(0)
    precondition(a.rawValue == 11)
    precondition(b.rawValue == 11)
    precondition(a.rawValue == b.rawValue)
    precondition(c.rawValue == 0)
    precondition(ExecutionStatus.RawValue.self == Int.self)
}

func testContinuationStrategy() {
    let automatic = CarKeyRemoteControlSession.ContinuationStrategy.automatic
    let manual = CarKeyRemoteControlSession.ContinuationStrategy.manual
    precondition(automatic == .automatic)
    precondition(manual == .manual)
    precondition(automatic != manual)
    precondition(!(automatic != .automatic))
    var h1 = Hasher()
    var h2 = Hasher()
    automatic.hash(into: &h1)
    CarKeyRemoteControlSession.ContinuationStrategy.automatic.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(automatic.hashValue == CarKeyRemoteControlSession.ContinuationStrategy.automatic.hashValue)
    precondition(automatic.hashValue != manual.hashValue)
}
