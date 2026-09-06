import Foundation
@_spi(OpenUIKitHost) import RelevanceKit

func testRelevantContextValueType() {
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)
    let context = RelevantContext.date(stamp)
    precondition(type(of: context) == RelevantContext.self)
    precondition(context.hostKind == .exactDate)
    precondition(context == RelevantContext.date(stamp))
    precondition(context != RelevantContext.sleep(.wakeup))
}

func testSleepConditionType() {
    let wakeup: RelevantContext.SleepCondition = .wakeup
    let bedtime: RelevantContext.SleepCondition = .bedtime
    precondition(type(of: wakeup) == RelevantContext.SleepCondition.self)
    precondition(wakeup == .wakeup)
    precondition(wakeup != bedtime)
}

func testFitnessConditionType() {
    let workout: RelevantContext.FitnessCondition = .workoutActive
    let rings: RelevantContext.FitnessCondition = .activityRingsIncomplete
    precondition(type(of: workout) == RelevantContext.FitnessCondition.self)
    precondition(workout == .workoutActive)
    precondition(workout != rings)
}

func testInferredLocationType() {
    let home: RelevantContext.InferredLocation = .home
    precondition(type(of: home) == RelevantContext.InferredLocation.self)
    let values: [RelevantContext.InferredLocation] = [.home, .work, .school, .commute]
    precondition(Set(values).count == 4)
}

func testHeadphonesConditionType() {
    let connected: RelevantContext.HeadphonesCondition = .connected
    precondition(type(of: connected) == RelevantContext.HeadphonesCondition.self)
    precondition(connected == RelevantContext.HeadphonesCondition.connected)
}

func testDateKindType() {
    let informational: RelevantContext.DateKind = .informational
    let defaultKind: RelevantContext.DateKind = .default
    let scheduled: RelevantContext.DateKind = .scheduled
    precondition(type(of: informational) == RelevantContext.DateKind.self)
    precondition(informational != defaultKind)
    precondition(defaultKind != scheduled)
    precondition(scheduled != informational)
    precondition(Set([informational, defaultKind, scheduled]).count == 3)
}

func testSleepConditionWakeup() {
    let wakeup = RelevantContext.SleepCondition.wakeup
    precondition(wakeup == .wakeup)
    precondition(wakeup != .bedtime)
    var hasherA = Hasher()
    var hasherB = Hasher()
    wakeup.hash(into: &hasherA)
    RelevantContext.SleepCondition.wakeup.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testSleepConditionBedtime() {
    let bedtime = RelevantContext.SleepCondition.bedtime
    precondition(bedtime == .bedtime)
    precondition(bedtime != .wakeup)
    precondition(RelevantContext.sleep(bedtime).hostSleepCondition == bedtime)
}

func testFitnessConditionWorkoutActive() {
    let workout = RelevantContext.FitnessCondition.workoutActive
    precondition(workout == .workoutActive)
    precondition(workout != .activityRingsIncomplete)
    precondition(RelevantContext.fitness(workout).hostFitnessCondition == workout)
}

func testFitnessConditionActivityRingsIncomplete() {
    let rings = RelevantContext.FitnessCondition.activityRingsIncomplete
    precondition(rings == .activityRingsIncomplete)
    precondition(rings != .workoutActive)
    precondition(RelevantContext.fitness(rings).hostFitnessCondition == rings)
}

func testInferredLocationHome() {
    let home = RelevantContext.InferredLocation.home
    precondition(home == .home)
    precondition(home != .work)
    precondition(home != .school)
    precondition(home != .commute)
    precondition(RelevantContext.location(inferred: home).hostInferredLocation == home)
}

func testInferredLocationWork() {
    let work = RelevantContext.InferredLocation.work
    precondition(work == .work)
    precondition(work != .home)
    precondition(RelevantContext.location(inferred: work).hostInferredLocation == work)
}

func testInferredLocationSchool() {
    let school = RelevantContext.InferredLocation.school
    precondition(school == .school)
    precondition(school != .commute)
    precondition(RelevantContext.location(inferred: school).hostInferredLocation == school)
}

func testInferredLocationCommute() {
    let commute = RelevantContext.InferredLocation.commute
    precondition(commute == .commute)
    precondition(commute != .home)
    precondition(RelevantContext.location(inferred: commute).hostInferredLocation == commute)
}

func testHeadphonesConditionConnected() {
    let connected = RelevantContext.HeadphonesCondition.connected
    precondition(connected == .connected)
    let context = RelevantContext.hardware(headphones: connected)
    precondition(context.hostHeadphonesCondition == connected)
    precondition(context.hostKind == .headphones)
}

func testDateKindInformational() {
    let kind = RelevantContext.DateKind.informational
    precondition(kind == .informational)
    precondition(kind != .default)
    precondition(kind != .scheduled)
    let stamp = Date(timeIntervalSince1970: 10)
    let context = RelevantContext.date(stamp, kind: kind)
    precondition(context.hostDateKind == kind)
}

func testDateKindDefault() {
    let kind = RelevantContext.DateKind.default
    precondition(kind == .default)
    precondition(kind != .informational)
    precondition(kind != .scheduled)
    let stamp = Date(timeIntervalSince1970: 11)
    precondition(RelevantContext.date(stamp, kind: kind).hostDateKind == kind)
}

func testDateKindScheduled() {
    let kind = RelevantContext.DateKind.scheduled
    precondition(kind == .scheduled)
    precondition(kind != .default)
    let stamp = Date(timeIntervalSince1970: 12)
    precondition(RelevantContext.date(stamp, kind: kind).hostDateKind == kind)
}

func testRelevantContextDateExact() {
    let stamp = Date(timeIntervalSince1970: 1_700_000_100)
    let other = Date(timeIntervalSince1970: 1_700_000_200)
    let context = RelevantContext.date(stamp)
    precondition(context.hostKind == .exactDate)
    precondition(context.hostExactDate == stamp)
    precondition(context.hostDateKind == nil)
    precondition(context == RelevantContext.date(stamp))
    precondition(context != RelevantContext.date(other))
    // Linux payload equality does not treat date(_:) as date(_:kind: .default).
    precondition(context != RelevantContext.date(stamp, kind: .default))
}

func testRelevantContextDateFromTo() {
    let start = Date(timeIntervalSince1970: 1_700_010_000)
    let end = Date(timeIntervalSince1970: 1_700_010_600)
    let context = RelevantContext.date(from: start, to: end)
    precondition(context.hostKind == .dateRange)
    precondition(context.hostRangeStart == start)
    precondition(context.hostRangeEnd == end)
    precondition(context == RelevantContext.date(from: start, to: end))
    precondition(context != RelevantContext.date(from: end, to: start))

    // Inverted bounds are stored as given; this port does not swap them.
    let inverted = RelevantContext.date(from: end, to: start)
    precondition(inverted.hostRangeStart == end)
    precondition(inverted.hostRangeEnd == start)

    // Not the same payload as date(range:kind:) even with matching bounds.
    let rangeContext = RelevantContext.date(range: start...end, kind: .default)
    precondition(context != rangeContext)
}

func testRelevantContextDateExactKind() {
    let stamp = Date(timeIntervalSince1970: 1_700_020_000)
    let scheduled = RelevantContext.date(stamp, kind: .scheduled)
    let informational = RelevantContext.date(stamp, kind: .informational)
    precondition(scheduled.hostKind == .datedExact)
    precondition(scheduled.hostExactDate == stamp)
    precondition(scheduled.hostDateKind == .scheduled)
    precondition(scheduled != informational)
    precondition(scheduled == RelevantContext.date(stamp, kind: .scheduled))
    precondition(scheduled != RelevantContext.date(stamp.addingTimeInterval(1), kind: .scheduled))
}

func testRelevantContextDateIntervalKind() {
    let start = Date(timeIntervalSince1970: 1_700_030_000)
    let interval = DateInterval(start: start, duration: 1_800)
    let context = RelevantContext.date(interval: interval, kind: .informational)
    precondition(context.hostKind == .datedInterval)
    precondition(context.hostDateInterval == interval)
    precondition(context.hostRangeStart == interval.start)
    precondition(context.hostRangeEnd == interval.end)
    precondition(context.hostDateKind == .informational)
    precondition(context == RelevantContext.date(interval: interval, kind: .informational))
    precondition(
        context != RelevantContext.date(interval: interval, kind: .scheduled)
    )
    let other = DateInterval(start: start, duration: 60)
    precondition(context != RelevantContext.date(interval: other, kind: .informational))
}

func testRelevantContextDateRangeKind() {
    let start = Date(timeIntervalSince1970: 1_700_040_000)
    let end = Date(timeIntervalSince1970: 1_700_040_300)
    let range = start...end
    let context = RelevantContext.date(range: range, kind: .scheduled)
    precondition(context.hostKind == .datedRange)
    precondition(context.hostClosedRange == range)
    precondition(context.hostRangeStart == start)
    precondition(context.hostRangeEnd == end)
    precondition(context.hostDateKind == .scheduled)
    precondition(context == RelevantContext.date(range: range, kind: .scheduled))
    precondition(context != RelevantContext.date(range: range, kind: .default))
    let shorter = start...start.addingTimeInterval(1)
    precondition(context != RelevantContext.date(range: shorter, kind: .scheduled))
}

func testRelevantContextSleep() {
    let wakeup = RelevantContext.sleep(.wakeup)
    let bedtime = RelevantContext.sleep(.bedtime)
    precondition(wakeup.hostKind == .sleep)
    precondition(wakeup.hostSleepCondition == .wakeup)
    precondition(bedtime.hostSleepCondition == .bedtime)
    precondition(wakeup != bedtime)
    precondition(wakeup == RelevantContext.sleep(.wakeup))
    precondition(wakeup != RelevantContext.fitness(.workoutActive))
}

func testRelevantContextFitness() {
    let workout = RelevantContext.fitness(.workoutActive)
    let rings = RelevantContext.fitness(.activityRingsIncomplete)
    precondition(workout.hostKind == .fitness)
    precondition(workout.hostFitnessCondition == .workoutActive)
    precondition(rings.hostFitnessCondition == .activityRingsIncomplete)
    precondition(workout != rings)
    precondition(workout == RelevantContext.fitness(.workoutActive))
}

func testRelevantContextHardwareHeadphones() {
    let context = RelevantContext.hardware(headphones: .connected)
    precondition(context.hostKind == .headphones)
    precondition(context.hostHeadphonesCondition == .connected)
    precondition(context == RelevantContext.hardware(headphones: .connected))
    precondition(context != RelevantContext.sleep(.wakeup))
}

func testRelevantContextLocationInferred() {
    let home = RelevantContext.location(inferred: .home)
    let work = RelevantContext.location(inferred: .work)
    let school = RelevantContext.location(inferred: .school)
    let commute = RelevantContext.location(inferred: .commute)
    precondition(home.hostKind == .inferredLocation)
    precondition(home.hostInferredLocation == .home)
    precondition(work.hostInferredLocation == .work)
    precondition(school.hostInferredLocation == .school)
    precondition(commute.hostInferredLocation == .commute)
    precondition(home != work)
    precondition(home != school)
    precondition(home != commute)
    precondition(home == RelevantContext.location(inferred: .home))
}
