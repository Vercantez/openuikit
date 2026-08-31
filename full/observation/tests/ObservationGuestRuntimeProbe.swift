// A source and runtime proof that deliberately imports SwiftUI only. This is
// the untouched-application shape used by Hackers' VotingViewModel.
import SwiftUI

@Observable
private final class ObservationProbeModel {
    var value = 1
    var other = 10

    @ObservationIgnored
    var ignored = 100
}

private final class ObservationProbeCounter: @unchecked Sendable {
    var value = 0
}

@inline(never)
func runObservationGuestRuntimeProbe() -> String {
    let model = ObservationProbeModel()

    let valueChanges = ObservationProbeCounter()
    let initial = withObservationTracking {
        model.value
    } onChange: {
        valueChanges.value += 1
    }
    precondition(initial == 1)
    model.value = 2
    precondition(valueChanges.value == 1)
    model.value = 3
    precondition(valueChanges.value == 1, "Observation callbacks are one-shot")

    let combinedChanges = ObservationProbeCounter()
    let combined = withObservationTracking {
        model.value + model.other
    } onChange: {
        combinedChanges.value += 1
    }
    precondition(combined == 13)
    model.other = 11
    precondition(combinedChanges.value == 1)

    let ignoredChanges = ObservationProbeCounter()
    let ignored = withObservationTracking {
        model.ignored
    } onChange: {
        ignoredChanges.value += 1
    }
    precondition(ignored == 100)
    model.ignored = 101
    precondition(ignoredChanges.value == 0)

    let registrar = ObservationRegistrar()
    let registrarCopy = registrar
    precondition(registrar == registrarCopy)
    precondition(registrar == ObservationRegistrar())

    return "macro,reexport,registrar,tracking,ignored,one-shot"
}
