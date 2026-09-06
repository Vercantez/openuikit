@_spi(OpenUIKitHost) import AutomatedDeviceEnrollment

func testAutomatedDeviceEnrollmentAddition() {
    AutomatedDeviceEnrollmentHostControl.resetLedger()

    let hidden = AutomatedDeviceEnrollmentBoolBox(false)
    let hiddenBinding = AutomatedDeviceEnrollmentHostControl.boolBinding(to: hidden)
    let host = AutomatedDeviceEnrollmentHostView()
    let hiddenModified = host.automatedDeviceEnrollmentAddition(isPresented: hiddenBinding)
    _ = hiddenModified
    precondition(hidden.value == false)
    precondition(AutomatedDeviceEnrollmentHostControl.lastPresentedFlag == false)
    precondition(AutomatedDeviceEnrollmentHostControl.additionPhase == .idle)
    precondition(AutomatedDeviceEnrollmentHostControl.lastUnavailableError == nil)
    precondition(AutomatedDeviceEnrollmentHostControl.modifierAttachCount == 1)

    hidden.value = true
    precondition(hiddenBinding.wrappedValue == true)
    hiddenBinding.wrappedValue = false
    precondition(hidden.value == false)

    let presented = AutomatedDeviceEnrollmentBoolBox(true)
    let presentedBinding = AutomatedDeviceEnrollmentHostControl.boolBinding(to: presented)
    let empty = EmptyView()
    let presentedModified = empty.automatedDeviceEnrollmentAddition(
        isPresented: presentedBinding
    )
    _ = presentedModified
    precondition(presented.value == true)
    precondition(AutomatedDeviceEnrollmentHostControl.lastPresentedFlag == true)
    precondition(AutomatedDeviceEnrollmentHostControl.additionPhase == .refused)
    precondition(
        AutomatedDeviceEnrollmentHostControl.lastUnavailableError
            == .linuxHost(operation: "automatedDeviceEnrollmentAddition")
    )
    precondition(AutomatedDeviceEnrollmentHostControl.modifierAttachCount == 2)

    do {
        try AutomatedDeviceEnrollmentHostControl.presentAddition()
        preconditionFailure("Linux must not present Automated Device Enrollment UI")
    } catch let error as AutomatedDeviceEnrollmentUnavailable {
        precondition(error == .linuxHost(operation: "automatedDeviceEnrollmentAddition"))
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    precondition(AutomatedDeviceEnrollmentHostControl.additionPhase == .refused)
    precondition(presented.value == true)

    testAutomatedDeviceEnrollmentUnavailableEquality()
    testAutomatedDeviceEnrollmentAdditionPhaseMachine()
    testAutomatedDeviceEnrollmentConstantBinding()
}

func testAutomatedDeviceEnrollmentUnavailableEquality() {
    let a = AutomatedDeviceEnrollmentUnavailable.linuxHost(
        operation: "automatedDeviceEnrollmentAddition"
    )
    let b = AutomatedDeviceEnrollmentUnavailable.linuxHost(
        operation: "automatedDeviceEnrollmentAddition"
    )
    let c = AutomatedDeviceEnrollmentUnavailable.linuxHost(operation: "other")
    precondition(a == b)
    precondition(a != c)
    precondition(Set([a, b]).count == 1)
    precondition(Set([a, c]).count == 2)
}

func testAutomatedDeviceEnrollmentAdditionPhaseMachine() {
    AutomatedDeviceEnrollmentHostControl.resetLedger()
    precondition(AutomatedDeviceEnrollmentHostControl.additionPhase == .idle)
    precondition(AutomatedDeviceEnrollmentHostControl.modifierAttachCount == 0)
    precondition(AutomatedDeviceEnrollmentHostControl.lastPresentedFlag == nil)

    let box = AutomatedDeviceEnrollmentBoolBox(false)
    _ = EmptyView().automatedDeviceEnrollmentAddition(
        isPresented: AutomatedDeviceEnrollmentHostControl.boolBinding(to: box)
    )
    precondition(AutomatedDeviceEnrollmentHostControl.additionPhase == .idle)

    box.value = true
    _ = AutomatedDeviceEnrollmentHostView().automatedDeviceEnrollmentAddition(
        isPresented: AutomatedDeviceEnrollmentHostControl.boolBinding(to: box)
    )
    precondition(AutomatedDeviceEnrollmentHostControl.additionPhase == .refused)
}

func testAutomatedDeviceEnrollmentConstantBinding() {
    AutomatedDeviceEnrollmentHostControl.resetLedger()
    let constant = Binding<Bool>.constant(true)
    _ = EmptyView().automatedDeviceEnrollmentAddition(isPresented: constant)
    precondition(constant.wrappedValue == true)
    constant.wrappedValue = false
    precondition(constant.wrappedValue == true)
    precondition(AutomatedDeviceEnrollmentHostControl.additionPhase == .refused)
}
