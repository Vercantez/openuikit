import Foundation
import BrowserEngineKit

func testBEAccessibilityPressedStateRawValues() {
    precondition(BEAccessibilityPressedState.undefined.rawValue == 0)
    precondition(BEAccessibilityPressedState.false.rawValue == 1)
    precondition(BEAccessibilityPressedState.true.rawValue == 2)
    precondition(BEAccessibilityPressedState.mixed.rawValue == 3)
    precondition(BEAccessibilityPressedState(rawValue: 0) == .undefined)
    precondition(BEAccessibilityPressedState(rawValue: 1) == .false)
    precondition(BEAccessibilityPressedState(rawValue: 2) == .true)
    precondition(BEAccessibilityPressedState(rawValue: 3) == .mixed)
    precondition(BEAccessibilityPressedState(rawValue: 4) == nil)
    precondition(BEAccessibilityPressedState(rawValue: -1) == nil)
}

func testBEAccessibilityPressedStateInequality() {
    precondition(BEAccessibilityPressedState.undefined != .false)
    precondition(!(BEAccessibilityPressedState.true != .true))
}

func testBEAccessibilityPressedStateHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    BEAccessibilityPressedState.mixed.hash(into: &hasherA)
    BEAccessibilityPressedState.mixed.hash(into: &hasherB)
    _ = hasherA.finalize()
    _ = hasherB.finalize()
    precondition(BEAccessibilityPressedState.undefined.hashValue != BEAccessibilityPressedState.mixed.hashValue)
}

func testBEGestureTypeRawValues() {
    precondition(BEGestureType.loupe.rawValue == 0)
    precondition(BEGestureType.oneFingerTap.rawValue == 1)
    precondition(BEGestureType.doubleTapAndHold.rawValue == 2)
    precondition(BEGestureType.doubleTap.rawValue == 3)
    precondition(BEGestureType.oneFingerDoubleTap.rawValue == 8)
    precondition(BEGestureType.oneFingerTripleTap.rawValue == 9)
    precondition(BEGestureType.twoFingerSingleTap.rawValue == 10)
    precondition(BEGestureType.twoFingerRangedSelectGesture.rawValue == 11)
    precondition(BEGestureType.imPhraseBoundaryDrag.rawValue == 14)
    precondition(BEGestureType.forceTouch.rawValue == 15)
    precondition(BEGestureType(rawValue: 0) == .loupe)
    precondition(BEGestureType(rawValue: 15) == .forceTouch)
    precondition(BEGestureType(rawValue: 4) == nil)
    precondition(BEGestureType(rawValue: 7) == nil)
}

func testBEGestureTypeInequality() {
    precondition(BEGestureType.loupe != .forceTouch)
    precondition(!(BEGestureType.doubleTap != .doubleTap))
}

func testBEGestureTypeHashable() {
    var hasher = Hasher()
    BEGestureType.loupe.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(BEGestureType.loupe.hashValue != BEGestureType.forceTouch.hashValue)
}

func testBEKeyModifierFlagsRawValues() {
    precondition(BEKeyModifierFlags.none.rawValue == 0)
    precondition(BEKeyModifierFlags.shift.rawValue == 1)
    precondition(BEKeyModifierFlags.capsLock.rawValue == 2)
    precondition(BEKeyModifierFlags(rawValue: 0) == BEKeyModifierFlags.none)
    precondition(BEKeyModifierFlags(rawValue: 1) == .shift)
    precondition(BEKeyModifierFlags(rawValue: 2) == .capsLock)
    precondition(BEKeyModifierFlags(rawValue: 3) == nil)
}

func testBEKeyModifierFlagsInequality() {
    precondition(BEKeyModifierFlags.none != .shift)
    precondition(!(BEKeyModifierFlags.capsLock != .capsLock))
}

func testBEKeyModifierFlagsHashable() {
    var hasher = Hasher()
    BEKeyModifierFlags.shift.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(BEKeyModifierFlags.none.hashValue != BEKeyModifierFlags.capsLock.hashValue)
}

func testBEKeyPressStateRawValues() {
    precondition(BEKeyEntry.KeyPressState.down.rawValue == 1)
    precondition(BEKeyEntry.KeyPressState.up.rawValue == 2)
    precondition(BEKeyEntry.KeyPressState(rawValue: 1) == .down)
    precondition(BEKeyEntry.KeyPressState(rawValue: 2) == .up)
    precondition(BEKeyEntry.KeyPressState(rawValue: 0) == nil)
}

func testBEKeyPressStateInequality() {
    precondition(BEKeyEntry.KeyPressState.down != .up)
    precondition(!(BEKeyEntry.KeyPressState.down != .down))
}

func testBEKeyPressStateHashable() {
    var hasher = Hasher()
    BEKeyEntry.KeyPressState.down.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(BEKeyEntry.KeyPressState.down.hashValue != BEKeyEntry.KeyPressState.up.hashValue)
}

func testBEScrollViewScrollUpdatePhaseRawValues() {
    precondition(BEScrollViewScrollUpdate.Phase.began.rawValue == 0)
    precondition(BEScrollViewScrollUpdate.Phase.changed.rawValue == 1)
    precondition(BEScrollViewScrollUpdate.Phase.ended.rawValue == 2)
    precondition(BEScrollViewScrollUpdate.Phase.cancelled.rawValue == 3)
    precondition(BEScrollViewScrollUpdate.Phase(rawValue: 0) == .began)
    precondition(BEScrollViewScrollUpdate.Phase(rawValue: 3) == .cancelled)
    precondition(BEScrollViewScrollUpdate.Phase(rawValue: 4) == nil)
}

func testBEScrollViewScrollUpdatePhaseInequality() {
    precondition(BEScrollViewScrollUpdate.Phase.began != .ended)
    precondition(!(BEScrollViewScrollUpdate.Phase.changed != .changed))
}

func testBEScrollViewScrollUpdatePhaseHashable() {
    var hasher = Hasher()
    BEScrollViewScrollUpdate.Phase.ended.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(BEScrollViewScrollUpdate.Phase.began.hashValue != BEScrollViewScrollUpdate.Phase.cancelled.hashValue)
}

func testBESelectionTouchPhaseRawValues() {
    precondition(BESelectionTouchPhase.started.rawValue == 0)
    precondition(BESelectionTouchPhase.moved.rawValue == 1)
    precondition(BESelectionTouchPhase.ended.rawValue == 2)
    precondition(BESelectionTouchPhase.endedMovingForward.rawValue == 3)
    precondition(BESelectionTouchPhase.endedMovingBackward.rawValue == 4)
    precondition(BESelectionTouchPhase.endedNotMoving.rawValue == 5)
    precondition(BESelectionTouchPhase(rawValue: 0) == .started)
    precondition(BESelectionTouchPhase(rawValue: 5) == .endedNotMoving)
    precondition(BESelectionTouchPhase(rawValue: 6) == nil)
}

func testBESelectionTouchPhaseInequality() {
    precondition(BESelectionTouchPhase.started != .ended)
    precondition(!(BESelectionTouchPhase.moved != .moved))
}

func testBESelectionTouchPhaseHashable() {
    var hasher = Hasher()
    BESelectionTouchPhase.started.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(BESelectionTouchPhase.started.hashValue != BESelectionTouchPhase.ended.hashValue)
}
