import Foundation

public struct HKQuantityTypeIdentifier: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let activeEnergyBurned = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierActiveEnergyBurned")
    public static let appleExerciseTime = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleExerciseTime")
    public static let appleMoveTime = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleMoveTime")
    public static let appleSleepingBreathingDisturbances = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleSleepingBreathingDisturbances")
    public static let appleSleepingWristTemperature = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleSleepingWristTemperature")
    public static let appleStandTime = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleStandTime")
    public static let appleWalkingSteadiness = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAppleWalkingSteadiness")
    public static let atrialFibrillationBurden = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierAtrialFibrillationBurden")
    public static let basalBodyTemperature = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBasalBodyTemperature")
    public static let basalEnergyBurned = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBasalEnergyBurned")
    public static let bloodAlcoholContent = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBloodAlcoholContent")
    public static let bloodGlucose = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBloodGlucose")
    public static let bloodPressureDiastolic = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBloodPressureDiastolic")
    public static let bloodPressureSystolic = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBloodPressureSystolic")
    public static let bodyFatPercentage = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBodyFatPercentage")
    public static let bodyMass = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBodyMass")
    public static let bodyMassIndex = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBodyMassIndex")
    public static let bodyTemperature = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBodyTemperature")
    public static let crossCountrySkiingSpeed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCrossCountrySkiingSpeed")
    public static let cyclingCadence = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCyclingCadence")
    public static let cyclingFunctionalThresholdPower = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCyclingFunctionalThresholdPower")
    public static let cyclingPower = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCyclingPower")
    public static let cyclingSpeed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierCyclingSpeed")
    public static let dietaryBiotin = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryBiotin")
    public static let dietaryCaffeine = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCaffeine")
    public static let dietaryCalcium = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCalcium")
    public static let dietaryCarbohydrates = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCarbohydrates")
    public static let dietaryChloride = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryChloride")
    public static let dietaryCholesterol = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCholesterol")
    public static let dietaryChromium = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryChromium")
    public static let dietaryCopper = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryCopper")
    public static let dietaryEnergyConsumed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryEnergyConsumed")
    public static let dietaryFatMonounsaturated = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFatMonounsaturated")
    public static let dietaryFatPolyunsaturated = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFatPolyunsaturated")
    public static let dietaryFatSaturated = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFatSaturated")
    public static let dietaryFatTotal = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFatTotal")
    public static let dietaryFiber = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFiber")
    public static let dietaryFolate = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryFolate")
    public static let dietaryIodine = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryIodine")
    public static let dietaryIron = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryIron")
    public static let dietaryMagnesium = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryMagnesium")
    public static let dietaryManganese = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryManganese")
    public static let dietaryMolybdenum = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryMolybdenum")
    public static let dietaryNiacin = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryNiacin")
    public static let dietaryPantothenicAcid = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryPantothenicAcid")
    public static let dietaryPhosphorus = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryPhosphorus")
    public static let dietaryPotassium = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryPotassium")
    public static let dietaryProtein = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryProtein")
    public static let dietaryRiboflavin = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryRiboflavin")
    public static let dietarySelenium = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietarySelenium")
    public static let dietarySodium = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietarySodium")
    public static let dietarySugar = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietarySugar")
    public static let dietaryThiamin = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryThiamin")
    public static let dietaryVitaminA = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminA")
    public static let dietaryVitaminB12 = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminB12")
    public static let dietaryVitaminB6 = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminB6")
    public static let dietaryVitaminC = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminC")
    public static let dietaryVitaminD = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminD")
    public static let dietaryVitaminE = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminE")
    public static let dietaryVitaminK = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryVitaminK")
    public static let dietaryWater = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryWater")
    public static let dietaryZinc = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDietaryZinc")
    public static let distanceCrossCountrySkiing = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceCrossCountrySkiing")
    public static let distanceCycling = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceCycling")
    public static let distanceDownhillSnowSports = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceDownhillSnowSports")
    public static let distancePaddleSports = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistancePaddleSports")
    public static let distanceRowing = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceRowing")
    public static let distanceSkatingSports = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceSkatingSports")
    public static let distanceSwimming = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceSwimming")
    public static let distanceWalkingRunning = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceWalkingRunning")
    public static let distanceWheelchair = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierDistanceWheelchair")
    public static let electrodermalActivity = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierElectrodermalActivity")
    public static let environmentalAudioExposure = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierEnvironmentalAudioExposure")
    public static let environmentalSoundReduction = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierEnvironmentalSoundReduction")
    public static let estimatedWorkoutEffortScore = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierEstimatedWorkoutEffortScore")
    public static let flightsClimbed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierFlightsClimbed")
    public static let forcedExpiratoryVolume1 = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierForcedExpiratoryVolume1")
    public static let forcedVitalCapacity = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierForcedVitalCapacity")
    public static let headphoneAudioExposure = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeadphoneAudioExposure")
    public static let heartRate = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeartRate")
    public static let heartRateRecoveryOneMinute = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeartRateRecoveryOneMinute")
    public static let heartRateVariabilitySDNN = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeartRateVariabilitySDNN")
    public static let height = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeight")
    public static let inhalerUsage = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierInhalerUsage")
    public static let insulinDelivery = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierInsulinDelivery")
    public static let leanBodyMass = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierLeanBodyMass")
    public static let nikeFuel = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierNikeFuel")
    public static let numberOfAlcoholicBeverages = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierNumberOfAlcoholicBeverages")
    public static let numberOfTimesFallen = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierNumberOfTimesFallen")
    public static let oxygenSaturation = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierOxygenSaturation")
    public static let paddleSportsSpeed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPaddleSportsSpeed")
    public static let peakExpiratoryFlowRate = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPeakExpiratoryFlowRate")
    public static let peripheralPerfusionIndex = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPeripheralPerfusionIndex")
    public static let physicalEffort = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPhysicalEffort")
    public static let pushCount = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierPushCount")
    public static let respiratoryRate = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRespiratoryRate")
    public static let restingHeartRate = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRestingHeartRate")
    public static let rowingSpeed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRowingSpeed")
    public static let runningGroundContactTime = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningGroundContactTime")
    public static let runningPower = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningPower")
    public static let runningSpeed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningSpeed")
    public static let runningStrideLength = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningStrideLength")
    public static let runningVerticalOscillation = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierRunningVerticalOscillation")
    public static let sixMinuteWalkTestDistance = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierSixMinuteWalkTestDistance")
    public static let stairAscentSpeed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierStairAscentSpeed")
    public static let stairDescentSpeed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierStairDescentSpeed")
    public static let stepCount = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierStepCount")
    public static let swimmingStrokeCount = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierSwimmingStrokeCount")
    public static let timeInDaylight = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierTimeInDaylight")
    public static let underwaterDepth = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierUnderwaterDepth")
    public static let uvExposure = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierUVExposure")
    public static let vo2Max = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierVO2Max")
    public static let waistCircumference = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWaistCircumference")
    public static let walkingAsymmetryPercentage = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingAsymmetryPercentage")
    public static let walkingDoubleSupportPercentage = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingDoubleSupportPercentage")
    public static let walkingHeartRateAverage = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingHeartRateAverage")
    public static let walkingSpeed = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingSpeed")
    public static let walkingStepLength = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWalkingStepLength")
    public static let waterTemperature = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWaterTemperature")
    public static let workoutEffortScore = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierWorkoutEffortScore")
}

public struct HKCategoryTypeIdentifier: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let abdominalCramps = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierAbdominalCramps")
    public static let acne = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierAcne")
    public static let appetiteChanges = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierAppetiteChanges")
    public static let appleStandHour = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierAppleStandHour")
    public static let appleWalkingSteadinessEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierAppleWalkingSteadinessEvent")
    public static let audioExposureEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierAudioExposureEvent")
    public static let bladderIncontinence = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierBladderIncontinence")
    public static let bleedingAfterPregnancy = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierBleedingAfterPregnancy")
    public static let bleedingDuringPregnancy = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierBleedingDuringPregnancy")
    public static let bloating = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierBloating")
    public static let breastPain = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierBreastPain")
    public static let cervicalMucusQuality = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierCervicalMucusQuality")
    public static let chestTightnessOrPain = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierChestTightnessOrPain")
    public static let chills = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierChills")
    public static let constipation = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierConstipation")
    public static let contraceptive = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierContraceptive")
    public static let coughing = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierCoughing")
    public static let diarrhea = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierDiarrhea")
    public static let dizziness = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierDizziness")
    public static let drySkin = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierDrySkin")
    public static let environmentalAudioExposureEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierEnvironmentalAudioExposureEvent")
    public static let fainting = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierFainting")
    public static let fatigue = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierFatigue")
    public static let fever = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierFever")
    public static let generalizedBodyAche = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierGeneralizedBodyAche")
    public static let hairLoss = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierHairLoss")
    public static let handwashingEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierHandwashingEvent")
    public static let headache = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierHeadache")
    public static let headphoneAudioExposureEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierHeadphoneAudioExposureEvent")
    public static let heartburn = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierHeartburn")
    public static let highHeartRateEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierHighHeartRateEvent")
    public static let hotFlashes = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierHotFlashes")
    public static let infrequentMenstrualCycles = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierInfrequentMenstrualCycles")
    public static let intermenstrualBleeding = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierIntermenstrualBleeding")
    public static let irregularHeartRhythmEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierIrregularHeartRhythmEvent")
    public static let irregularMenstrualCycles = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierIrregularMenstrualCycles")
    public static let lactation = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierLactation")
    public static let lossOfSmell = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierLossOfSmell")
    public static let lossOfTaste = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierLossOfTaste")
    public static let lowCardioFitnessEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierLowCardioFitnessEvent")
    public static let lowHeartRateEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierLowHeartRateEvent")
    public static let lowerBackPain = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierLowerBackPain")
    public static let memoryLapse = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierMemoryLapse")
    public static let menstrualFlow = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierMenstrualFlow")
    public static let mindfulSession = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierMindfulSession")
    public static let moodChanges = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierMoodChanges")
    public static let nausea = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierNausea")
    public static let nightSweats = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierNightSweats")
    public static let ovulationTestResult = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierOvulationTestResult")
    public static let pelvicPain = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierPelvicPain")
    public static let persistentIntermenstrualBleeding = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierPersistentIntermenstrualBleeding")
    public static let pregnancy = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierPregnancy")
    public static let pregnancyTestResult = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierPregnancyTestResult")
    public static let progesteroneTestResult = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierProgesteroneTestResult")
    public static let prolongedMenstrualPeriods = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierProlongedMenstrualPeriods")
    public static let rapidPoundingOrFlutteringHeartbeat = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierRapidPoundingOrFlutteringHeartbeat")
    public static let runnyNose = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierRunnyNose")
    public static let sexualActivity = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierSexualActivity")
    public static let shortnessOfBreath = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierShortnessOfBreath")
    public static let sinusCongestion = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierSinusCongestion")
    public static let skippedHeartbeat = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierSkippedHeartbeat")
    public static let sleepAnalysis = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierSleepAnalysis")
    public static let sleepApneaEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierSleepApneaEvent")
    public static let sleepChanges = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierSleepChanges")
    public static let soreThroat = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierSoreThroat")
    public static let toothbrushingEvent = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierToothbrushingEvent")
    public static let vaginalDryness = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierVaginalDryness")
    public static let vomiting = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierVomiting")
    public static let wheezing = HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierWheezing")
}

public struct HKCharacteristicTypeIdentifier: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let activityMoveMode = HKCharacteristicTypeIdentifier(rawValue: "HKCharacteristicTypeIdentifierActivityMoveMode")
    public static let biologicalSex = HKCharacteristicTypeIdentifier(rawValue: "HKCharacteristicTypeIdentifierBiologicalSex")
    public static let bloodType = HKCharacteristicTypeIdentifier(rawValue: "HKCharacteristicTypeIdentifierBloodType")
    public static let dateOfBirth = HKCharacteristicTypeIdentifier(rawValue: "HKCharacteristicTypeIdentifierDateOfBirth")
    public static let fitzpatrickSkinType = HKCharacteristicTypeIdentifier(rawValue: "HKCharacteristicTypeIdentifierFitzpatrickSkinType")
    public static let wheelchairUse = HKCharacteristicTypeIdentifier(rawValue: "HKCharacteristicTypeIdentifierWheelchairUse")
}

public struct HKClinicalTypeIdentifier: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let allergyRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierAllergyRecord")
    public static let clinicalNoteRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierClinicalNoteRecord")
    public static let conditionRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierConditionRecord")
    public static let coverageRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierCoverageRecord")
    public static let immunizationRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierImmunizationRecord")
    public static let labResultRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierLabResultRecord")
    public static let medicationRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierMedicationRecord")
    public static let procedureRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierProcedureRecord")
    public static let vitalSignRecord = HKClinicalTypeIdentifier(rawValue: "HKClinicalTypeIdentifierVitalSignRecord")
}

public struct HKCorrelationTypeIdentifier: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let bloodPressure = HKCorrelationTypeIdentifier(rawValue: "HKCorrelationTypeIdentifierBloodPressure")
    public static let food = HKCorrelationTypeIdentifier(rawValue: "HKCorrelationTypeIdentifierFood")
}

public struct HKDocumentTypeIdentifier: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let CDA = HKDocumentTypeIdentifier(rawValue: "HKDocumentTypeIdentifierCDA")
}

public struct HKScoredAssessmentTypeIdentifier: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let GAD7 = HKScoredAssessmentTypeIdentifier(rawValue: "HKScoredAssessmentTypeIdentifierGAD7")
    public static let PHQ9 = HKScoredAssessmentTypeIdentifier(rawValue: "HKScoredAssessmentTypeIdentifierPHQ9")
}

public struct HKFHIRRelease: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let dstu2 = HKFHIRRelease(rawValue: "HKFHIRReleaseDSTU2")
    public static let r4 = HKFHIRRelease(rawValue: "HKFHIRReleaseR4")
    public static let unknown = HKFHIRRelease(rawValue: "HKFHIRReleaseUnknown")
}

public struct HKFHIRResourceType: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let allergyIntolerance = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeAllergyIntolerance")
    public static let condition = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeCondition")
    public static let coverage = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeCoverage")
    public static let diagnosticReport = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeDiagnosticReport")
    public static let documentReference = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeDocumentReference")
    public static let immunization = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeImmunization")
    public static let medicationDispense = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeMedicationDispense")
    public static let medicationOrder = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeMedicationOrder")
    public static let medicationRequest = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeMedicationRequest")
    public static let medicationStatement = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeMedicationStatement")
    public static let observation = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeObservation")
    public static let procedure = HKFHIRResourceType(rawValue: "HKFHIRResourceTypeProcedure")
}

public struct HKHealthConceptDomain: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let medication = HKHealthConceptDomain(rawValue: "HKHealthConceptDomainMedication")
}

public struct HKMedicationGeneralForm: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let capsule = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormCapsule")
    public static let cream = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormCream")
    public static let device = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormDevice")
    public static let drops = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormDrops")
    public static let foam = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormFoam")
    public static let gel = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormGel")
    public static let inhaler = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormInhaler")
    public static let injection = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormInjection")
    public static let liquid = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormLiquid")
    public static let lotion = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormLotion")
    public static let ointment = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormOintment")
    public static let patch = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormPatch")
    public static let powder = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormPowder")
    public static let spray = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormSpray")
    public static let suppository = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormSuppository")
    public static let tablet = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormTablet")
    public static let topical = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormTopical")
    public static let unknown = HKMedicationGeneralForm(rawValue: "HKMedicationGeneralFormUnknown")
}

public struct HKVerifiableClinicalRecordCredentialType: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let covid19 = HKVerifiableClinicalRecordCredentialType(rawValue: "HKVerifiableClinicalRecordCredentialTypeCOVID19")
    public static let immunization = HKVerifiableClinicalRecordCredentialType(rawValue: "HKVerifiableClinicalRecordCredentialTypeImmunization")
    public static let laboratory = HKVerifiableClinicalRecordCredentialType(rawValue: "HKVerifiableClinicalRecordCredentialTypeLaboratory")
    public static let recovery = HKVerifiableClinicalRecordCredentialType(rawValue: "HKVerifiableClinicalRecordCredentialTypeRecovery")
}

public struct HKVerifiableClinicalRecordSourceType: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let euDigitalCOVIDCertificate = HKVerifiableClinicalRecordSourceType(rawValue: "HKVerifiableClinicalRecordSourceTypeEUDigitalCOVIDCertificate")
    public static let smartHealthCard = HKVerifiableClinicalRecordSourceType(rawValue: "HKVerifiableClinicalRecordSourceTypeSMARTHealthCard")
}

