import Foundation
import HealthKit

private func requireUnavailable(_ error: Error?) {
    guard let error = error as? HKError else {
        fatalError("expected typed HKError, got \(String(describing: error))")
    }
    precondition(error.code == .errorHealthDataUnavailable)
    precondition(error.errorCode == HKError.errorHealthDataUnavailable.rawValue)
    precondition(HKError.errorDomain == HKErrorDomain)
    precondition(HKErrorDomain == "com.apple.healthkit")
}

enum HealthKitRuntime {
    static func main() async {
        exerciseUnits()
        exerciseQuantities()
        exerciseIdentifiersAndTypes()
        exerciseSamplesAndWorkouts()
        exercisePredicates()
        exerciseEnumsAndConstants()
        await exerciseStoreFailClosed()
        print("HEALTHKIT_AGENT_RUNTIME_OK")
    }

    static func exerciseUnits() {
        let kg = HKUnit.gramUnit(with: .kilo)
        let g = HKUnit.gram()
        precondition(kg.unitString == "kg")
        precondition(g.unitString == "g")
        precondition(kg.isCompatible(with: g))
        precondition(!kg.isNull())

        let meter = HKUnit.meter()
        let cm = HKUnit.meterUnit(with: .centi)
        let km = HKUnit.meterUnit(with: .kilo)
        precondition(cm.unitString == "cm")
        precondition(km.unitString == "km")

        let kcal = HKUnit.kilocalorie()
        let joule = HKUnit.joule()
        precondition(kcal.isCompatible(with: joule))
        precondition(HKUnit.calorie().unitString == "cal")
        precondition(HKUnit.largeCalorie().unitString == "kcal")

        let celsius = HKUnit.degreeCelsius()
        let kelvin = HKUnit.kelvin()
        let fahrenheit = HKUnit.degreeFahrenheit()
        precondition(celsius.isCompatible(with: kelvin))
        precondition(fahrenheit.isCompatible(with: celsius))

        let bpm = HKUnit.count().unitDivided(by: .minute())
        precondition(bpm.unitString == "count/min")
        let hz = HKUnit.hertz()
        precondition(bpm.isCompatible(with: hz))

        let parsed = HKUnit(from: "kg")
        precondition(parsed.unitString == "kg")
        precondition(parsed.isCompatible(with: g))

        let millimole = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
        precondition(millimole.unitString.contains("mol"))
        precondition(HKUnitMolarMassBloodGlucose == 180.155887)

        let formatterUnit = HKUnit.massFormatterUnit(from: kg)
        precondition(formatterUnit == .kilogram)
        let fromFormatter = HKUnit(fromMassFormatterUnit: .pound)
        precondition(fromFormatter.isCompatible(with: g))

        let reciprocal = meter.reciprocal()
        precondition(reciprocal.isCompatible(with: HKUnit.diopter()))
    }

    static func exerciseQuantities() {
        let mass = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: 2)
        precondition(abs(mass.doubleValue(for: .gram()) - 2000) < 1e-6)
        precondition(mass.is(compatibleWith: .pound()))
        let grams = HKQuantity(unit: .gram(), doubleValue: 2000)
        precondition(mass.compare(grams) == .orderedSame)

        let boiling = HKQuantity(unit: .degreeCelsius(), doubleValue: 100)
        let boilingK = boiling.doubleValue(for: .kelvin())
        precondition(abs(boilingK - 373.15) < 1e-6)
        let boilingF = boiling.doubleValue(for: .degreeFahrenheit())
        precondition(abs(boilingF - 212) < 1e-6)

        let kcal = HKQuantity(unit: .kilocalorie(), doubleValue: 1)
        precondition(abs(kcal.doubleValue(for: .joule()) - 4184) < 1e-3)

        let mmHg = HKQuantity(unit: .millimeterOfMercury(), doubleValue: 120)
        precondition(mmHg.is(compatibleWith: .pascal()))

        let heartRate = HKQuantity(
            unit: HKUnit.count().unitDivided(by: .minute()),
            doubleValue: 60
        )
        precondition(abs(heartRate.doubleValue(for: .hertz()) - 1) < 1e-9)
    }

    static func exerciseIdentifiersAndTypes() {
        let heartRate = HKQuantityTypeIdentifier.heartRate
        precondition(heartRate.rawValue == "HKQuantityTypeIdentifierHeartRate")
        let vo2 = HKQuantityTypeIdentifier.vo2Max
        precondition(vo2.rawValue == "HKQuantityTypeIdentifierVO2Max")
        precondition(HKQuantityTypeIdentifier.uvExposure.rawValue == "HKQuantityTypeIdentifierUVExposure")

        let quantityType = HKQuantityType(.heartRate)
        precondition(quantityType.identifier == heartRate.rawValue)
        precondition(quantityType.aggregationStyle == .discreteArithmetic)
        let steps = HKQuantityType(.stepCount)
        precondition(steps.aggregationStyle == .cumulative)
        precondition(quantityType.is(compatibleWith: HKUnit.count().unitDivided(by: .minute())))

        let sleep = HKCategoryType(.sleepAnalysis)
        precondition(sleep.identifier == "HKCategoryTypeIdentifierSleepAnalysis")
        let sex = HKCharacteristicType(.biologicalSex)
        precondition(sex.identifier == "HKCharacteristicTypeIdentifierBiologicalSex")
        let food = HKCorrelationType(.food)
        precondition(food.identifier == "HKCorrelationTypeIdentifierFood")
        precondition(HKObjectType.workoutType().identifier == HKWorkoutTypeIdentifier)
        precondition(HKSeriesType.heartbeat().identifier == HKDataTypeIdentifierHeartbeatSeries)
        precondition(HKObjectType.quantityType(forIdentifier: .bodyMass)?.identifier == HKQuantityTypeIdentifier.bodyMass.rawValue)

        let hashed = Set([heartRate, .stepCount, heartRate])
        precondition(hashed.count == 2)
    }

    static func exerciseSamplesAndWorkouts() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(60)
        let type = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: 70)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: end)
        precondition(sample.quantityType.identifier == type.identifier)
        precondition(sample.quantity.doubleValue(for: .gramUnit(with: .kilo)) == 70)
        precondition(sample.count == 1)
        precondition(sample.startDate == start)

        let sleepType = HKCategoryType(.sleepAnalysis)
        let category = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            start: start,
            end: end
        )
        precondition(category.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue)
        precondition(HKCategoryValueSleepAnalysis.allAsleepValues.contains(.asleepCore))
        precondition(HKCategoryValueSleepAnalysis.asleep == .asleepUnspecified)

        let device = HKDevice.local()
        precondition(device.name == "Linux")
        let source = HKSource.default()
        precondition(!source.bundleIdentifier.isEmpty)

        let workout = HKWorkout(
            activityType: .running,
            start: start,
            end: end,
            duration: 60,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 10),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: 1000),
            device: device,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        precondition(workout.workoutActivityType == .running)
        precondition(workout.duration == 60)
        precondition(workout.totalDistance?.doubleValue(for: .meter()) == 1000)

        let event = HKWorkoutEvent(type: .pause, date: start)
        precondition(event.type == .pause)

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .swimming
        configuration.locationType = .indoor
        configuration.swimmingLocationType = .pool
        precondition(configuration.activityType == .swimming)

        let correlation = HKCorrelation(
            type: HKCorrelationType(.bloodPressure),
            start: start,
            end: end,
            objects: [
                HKQuantitySample(
                    type: HKQuantityType(.bloodPressureSystolic),
                    quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 120),
                    start: start,
                    end: end
                )
            ]
        )
        precondition(correlation.objects.count == 1)
    }

    static func exercisePredicates() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let sample = HKQuantitySample(
            type: HKQuantityType(.stepCount),
            quantity: HKQuantity(unit: .count(), doubleValue: 100),
            start: start,
            end: start.addingTimeInterval(10)
        )
        let uuidPredicate = HKQuery.predicateForObject(with: sample.uuid)
        precondition(uuidPredicate.evaluate(with: sample))
        precondition(!uuidPredicate.evaluate(with: HKSource.default()))

        let window = HKQuery.predicateForSamples(
            withStart: start.addingTimeInterval(-5),
            end: start.addingTimeInterval(20),
            options: [.strictStartDate, .strictEndDate]
        )
        precondition(window.evaluate(with: sample))
        let miss = HKQuery.predicateForSamples(
            withStart: start.addingTimeInterval(50),
            end: start.addingTimeInterval(60),
            options: .strictStartDate
        )
        precondition(!miss.evaluate(with: sample))
    }

    static func exerciseEnumsAndConstants() {
        precondition(HKAuthorizationStatus.notDetermined.rawValue == 0)
        precondition(HKAuthorizationStatus.sharingDenied.rawValue == 1)
        precondition(HKAuthorizationStatus.sharingAuthorized.rawValue == 2)
        precondition(HKBiologicalSex.female.rawValue == 1)
        precondition(HKWorkoutActivityType.running.rawValue == 37)
        precondition(HKWorkoutActivityType.other.rawValue == 3000)
        precondition(HKMetricPrefix.kilo.rawValue == 9)
        precondition(HKError.Code.errorHealthDataUnavailable.rawValue == 1)
        precondition(HKError.Code.noError == .unknownError)
        precondition(HKObjectQueryNoLimit == 0)
        precondition(HKMetadataKeyWasUserEntered == "HKMetadataKeyWasUserEntered")
        precondition(HKPredicateKeyPathStartDate == "HKPredicateKeyPathStartDate")
        var options: HKQueryOptions = [.strictStartDate]
        options.insert(.strictEndDate)
        precondition(options.contains(.strictStartDate))
        precondition(HKStatisticsOptions.cumulativeSum.rawValue == 1 << 4)
        precondition(NSNotification.Name.HKUserPreferencesDidChange.rawValue == "HKUserPreferencesDidChangeNotification")
        precondition(HKError.Code.errorHealthDataUnavailable ~= HKError(.errorHealthDataUnavailable))
    }

    static func exerciseStoreFailClosed() async {
        precondition(HKHealthStore.isHealthDataAvailable() == false)
        let store = HKHealthStore()
        precondition(store.supportsHealthRecords() == false)
        let type = HKQuantityType(.heartRate)
        precondition(store.authorizationStatus(for: type) == .notDetermined)

        do {
            try await store.save(
                HKQuantitySample(
                    type: type,
                    quantity: HKQuantity(
                        unit: HKUnit.count().unitDivided(by: .minute()),
                        doubleValue: 60
                    ),
                    start: Date(),
                    end: Date()
                )
            )
            fatalError("save must fail closed")
        } catch {
            requireUnavailable(error)
        }

        do {
            _ = try store.biologicalSex()
            fatalError("characteristic reads must fail closed")
        } catch {
            requireUnavailable(error)
        }

        let finished = await withCheckedContinuation { continuation in
            store.requestAuthorization(toShare: [type], read: [type]) { success, error in
                continuation.resume(returning: (success, error))
            }
        }
        precondition(finished.0 == false)
        requireUnavailable(finished.1)

        let queryDone = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                continuation.resume(returning: (samples, error))
            }
            store.execute(query)
        }
        precondition(queryDone.0 == nil)
        requireUnavailable(queryDone.1)
    }
}

await HealthKitRuntime.main()

