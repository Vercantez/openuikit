import FoundationProgressPortable

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

@main
struct FoundationProgressRuntime {
    static func main() {
        let progress = FoundationProgressPortable.Progress(totalUnitCount: 100)
        var fractions: [(Double?, Double?, Bool)] = []
        var indeterminate: [Bool?] = []
        var cancellations: [Bool?] = []

        let fraction = progress.observe(
            \.fractionCompleted, options: [.initial, .old, .new, .prior]
        ) { _, change in
            fractions.append((change.oldValue, change.newValue, change.isPrior))
        }
        let indefinite = progress.observe(
            \.isIndeterminate, options: [.initial, .new]
        ) { _, change in
            indeterminate.append(change.newValue)
        }
        let cancelled = progress.observe(\.isCancelled, options: [.new]) {
            _, change in cancellations.append(change.newValue)
        }

        expect(fractions.count == 1 && fractions[0].0 == nil && fractions[0].1 == 0,
               "initial fraction")
        expect(indeterminate == [false], "initial determinate state")
        expect(Set([fraction, indefinite, cancelled]).count == 3, "token identity")
        progress.completedUnitCount = 25
        expect(progress.fractionCompleted == 0.25, "fraction update")
        expect(fractions.count == 3, "prior and post callbacks")
        expect(fractions[1].0 == 0 && fractions[1].1 == nil && fractions[1].2,
               "prior payload")
        expect(fractions[2].0 == 0 && fractions[2].1 == 0.25 && !fractions[2].2,
               "post payload")

        progress.cancel()
        expect(progress.isCancelled && cancellations == [true], "cancel callback")
        cancelled.invalidate()
        progress.cancel()
        expect(cancellations == [true], "invalidation")

        let zero = FoundationProgressPortable.Progress(totalUnitCount: 0)
        expect(zero.isIndeterminate, "zero begins indeterminate")
        zero.completedUnitCount = 1
        expect(!zero.isIndeterminate && zero.fractionCompleted == 1 && zero.isFinished,
               "zero becomes finished")
        let negative = FoundationProgressPortable.Progress(totalUnitCount: -1)
        negative.completedUnitCount = 2
        expect(negative.isIndeterminate && negative.fractionCompleted == 0,
               "negative remains indeterminate")

        progress.pause()
        expect(progress.isPaused, "pause")
        progress.resume()
        expect(!progress.isPaused, "resume")
        expect(progress.isCancellable && !progress.isPausable, "capability defaults")
        withExtendedLifetime((fraction, indefinite, cancelled)) {}
        print("FOUNDATION_PROGRESS_HOST_OK fraction=initial-prior-new kvo=typed-invalidated states=cancel-pause-finish")
    }
}
