import Foundation

func scalar(_ value: Double?) -> String {
    value.map { String($0) } ?? "nil"
}

print(
    "options new=\(NSKeyValueObservingOptions.new.rawValue) " +
    "old=\(NSKeyValueObservingOptions.old.rawValue) " +
    "initial=\(NSKeyValueObservingOptions.initial.rawValue) " +
    "prior=\(NSKeyValueObservingOptions.prior.rawValue)"
)
for total in [-1, 0, 1, 100] as [Int64] {
    let progress = Progress(totalUnitCount: total)
    print(
        "state total=\(total) completed=\(progress.completedUnitCount) " +
        "fraction=\(progress.fractionCompleted) " +
        "indeterminate=\(progress.isIndeterminate) finished=\(progress.isFinished)"
    )
}

let progress = Progress(totalUnitCount: 100)
var events: [String] = []
let observation = progress.observe(
    \.fractionCompleted, options: [.initial, .old, .new, .prior]
) { _, change in
    events.append(
        "fraction old=\(scalar(change.oldValue)) " +
        "new=\(scalar(change.newValue)) prior=\(change.isPrior)"
    )
}
progress.completedUnitCount = 25
for event in events { print(event) }
print(
    "state total=100 completed=25 fraction=\(progress.fractionCompleted) " +
    "indeterminate=\(progress.isIndeterminate) finished=\(progress.isFinished)"
)
let zero = Progress(totalUnitCount: 0)
zero.completedUnitCount = 1
print(
    "state total=0 completed=1 fraction=\(zero.fractionCompleted) " +
    "indeterminate=\(zero.isIndeterminate) finished=\(zero.isFinished)"
)
withExtendedLifetime(observation) {}
