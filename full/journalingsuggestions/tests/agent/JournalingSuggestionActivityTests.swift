import Foundation
@_spi(OpenUIKitHost)
import JournalingSuggestions

func testMotionActivityFields() {
    let interval = DateInterval(start: Date(timeIntervalSince1970: 1_700_000_100), duration: 1200)
    let icon = URL(fileURLWithPath: "/tmp/steps.png")
    let activity = JournalingSuggestion.MotionActivity(
        movementType: .walking,
        date: interval,
        icon: icon,
        steps: 4321
    )
    precondition(activity.movementType == .walking)
    precondition(activity.date == interval)
    precondition(activity.icon == icon)
    precondition(activity.steps == 4321)
    precondition(JournalingSuggestion.MotionActivity.JournalingSuggestionContent.self == JournalingSuggestion.MotionActivity.self)
}

func testMovementTypeCatalog() {
    let cases: [JournalingSuggestion.MotionActivity.MovementType] = [
        .runningWalking, .running, .walking
    ]
    precondition(cases[0].rawValue == "runningWalking")
    precondition(cases[1].rawValue == "running")
    precondition(cases[2].rawValue == "walking")
    precondition(Set(cases.map(\.rawValue)).count == 3)
}

func testMovementTypeHashing() {
    let a = JournalingSuggestion.MotionActivity.MovementType.running
    let b = JournalingSuggestion.MotionActivity.MovementType.running
    let c = JournalingSuggestion.MotionActivity.MovementType.walking
    precondition(a == b)
    precondition(a != c)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(a.hashValue == b.hashValue)
}

func testMovementTypeCodable() {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for value in [
        JournalingSuggestion.MotionActivity.MovementType.runningWalking,
        .running,
        .walking
    ] {
        let data = try! encoder.encode(value)
        let decoded = try! decoder.decode(
            JournalingSuggestion.MotionActivity.MovementType.self,
            from: data
        )
        precondition(decoded == value)
    }
    do {
        _ = try decoder.decode(
            JournalingSuggestion.MotionActivity.MovementType.self,
            from: Data("\"cycling\"".utf8)
        )
        preconditionFailure("unknown MovementType must fail")
    } catch is DecodingError {
        ()
    } catch {
        preconditionFailure("expected DecodingError")
    }
}

func testWorkoutDetailsFields() {
    let interval = DateInterval(start: Date(timeIntervalSince1970: 1_700_100_000), duration: 2400)
    let distance = HKQuantity(unitIdentifier: "m", doubleValue: 5000)
    let hr = HKQuantity(unitIdentifier: "count/min", doubleValue: 148)
    let energy = HKQuantity(unitIdentifier: "kcal", doubleValue: 420)
    let details = JournalingSuggestion.Workout.Details(
        activityType: .running,
        localizedName: "Run",
        date: interval,
        distance: distance,
        averageHeartRate: hr,
        activeEnergyBurned: energy
    )
    precondition(details.activityType == .running)
    precondition(details.localizedName == "Run")
    precondition(details.date == interval)
    precondition(details.distance?.doubleValue == 5000)
    precondition(details.averageHeartRate?.doubleValue == 148)
    precondition(details.activeEnergyBurned?.doubleValue == 420)
    precondition(JournalingSuggestion.Workout.Details.JournalingSuggestionContent.self == JournalingSuggestion.Workout.Details.self)
}

func testWorkoutFields() {
    let icon = URL(fileURLWithPath: "/tmp/run.png")
    let point = CLLocation(latitude: 37.33, longitude: -122.03)
    let details = JournalingSuggestion.Workout.Details(activityType: .walking)
    let workout = JournalingSuggestion.Workout(icon: icon, route: [point], details: details)
    precondition(workout.icon == icon)
    precondition(workout.route?.count == 1)
    precondition(workout.route?[0].latitude == 37.33)
    precondition(workout.details?.activityType == .walking)
    precondition(JournalingSuggestion.Workout.JournalingSuggestionContent.self == JournalingSuggestion.Workout.self)
}

func testWorkoutGroupFields() {
    let workout = JournalingSuggestion.Workout(details: .init(activityType: .other))
    let hr = HKQuantity(unitIdentifier: "count/min", doubleValue: 120)
    let energy = HKQuantity(unitIdentifier: "kcal", doubleValue: 200)
    let icon = URL(fileURLWithPath: "/tmp/group.png")
    let group = JournalingSuggestion.WorkoutGroup(
        workouts: [workout],
        duration: 1800,
        icon: icon,
        averageHeartRate: hr,
        activeEnergyBurned: energy
    )
    precondition(group.workouts.count == 1)
    precondition(group.duration == 1800)
    precondition(group.icon == icon)
    precondition(group.averageHeartRate?.doubleValue == 120)
    precondition(group.activeEnergyBurned?.doubleValue == 200)
    precondition(JournalingSuggestion.WorkoutGroup.JournalingSuggestionContent.self == JournalingSuggestion.WorkoutGroup.self)
}

func testLocationFields() {
    let date = Date(timeIntervalSince1970: 1_700_200_000)
    let coord = CLLocation(latitude: 40.71, longitude: -74.01)
    let identifier = MKMapItem.Identifier(rawValue: "mk:place:1")
    let location = JournalingSuggestion.Location(
        place: "Library",
        city: "New York",
        date: date,
        isWorkLocation: false,
        location: coord,
        mapKitItemIdentifier: identifier
    )
    precondition(location.place == "Library")
    precondition(location.city == "New York")
    precondition(location.date == date)
    precondition(location.isWorkLocation == false)
    precondition(location.location?.longitude == -74.01)
    precondition(location.mapKitItemIdentifier == identifier)
    precondition(JournalingSuggestion.Location.JournalingSuggestionContent.self == JournalingSuggestion.Location.self)
}

func testLocationGroupFields() {
    let a = JournalingSuggestion.Location(place: "Home")
    let b = JournalingSuggestion.Location(place: "Cafe")
    let group = JournalingSuggestion.LocationGroup(locations: [a, b])
    precondition(group.locations.count == 2)
    precondition(group.locations[0].place == "Home")
    precondition(group.locations[1].place == "Cafe")
    precondition(JournalingSuggestion.LocationGroup.JournalingSuggestionContent.self == JournalingSuggestion.LocationGroup.self)
}

func testStateOfMindFields() {
    let state = HKStateOfMind(valence: 0.4)
    let icon = URL(fileURLWithPath: "/tmp/mood.png")
    let light = Gradient(colors: [Color("light")])
    let dark = Gradient(colors: [Color("dark")])
    let mood = JournalingSuggestion.StateOfMind(
        state: state,
        icon: icon,
        lightBackground: light,
        darkBackground: dark
    )
    precondition(mood.state.valence == 0.4)
    precondition(mood.icon == icon)
    precondition(mood.lightBackground == light)
    precondition(mood.darkBackground == dark)
    precondition(JournalingSuggestion.StateOfMind.JournalingSuggestionContent.self == JournalingSuggestion.StateOfMind.self)
}
