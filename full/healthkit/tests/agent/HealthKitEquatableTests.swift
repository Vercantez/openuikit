import Foundation
import HealthKit

private func hkRequire(_ condition: Bool, _ message: String = "") {
    if !condition {
        fputs("HealthKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

private func hkWait(_ body: @escaping @Sendable () async throws -> Void) {
    let lock = DispatchSemaphore(value: 0)
    Task {
        do { try await body() } catch { hkRequire(false, "async \(error)") }
        lock.signal()
    }
    hkRequire(lock.wait(timeout: .now() + 8) == .success, "async timeout")
}

private func hkAuthorize(_ types: Set<HKSampleType>) {
    HKHealthStorePortable._installAuthorizationHandler { _, _ in .sharingAuthorized }
    let lock = DispatchSemaphore(value: 0)
    HKHealthStore().requestAuthorization(toShare: types, read: types) { _, _ in lock.signal() }
    hkRequire(lock.wait(timeout: .now() + 5) == .success, "auth")
}

func testEnumEquatableAndHashable1() {
    var hasher_HKActivityMoveMode = Hasher()
    hkRequire(HKActivityMoveMode.activeEnergy != HKActivityMoveMode.appleMoveTime)
    HKActivityMoveMode.activeEnergy.hash(into: &hasher_HKActivityMoveMode)
    _ = HKActivityMoveMode.activeEnergy.hashValue
    var hasher_HKAppleWalkingSteadinessClassification = Hasher()
    hkRequire(HKAppleWalkingSteadinessClassification.low != HKAppleWalkingSteadinessClassification.ok)
    HKAppleWalkingSteadinessClassification.low.hash(into: &hasher_HKAppleWalkingSteadinessClassification)
    _ = HKAppleWalkingSteadinessClassification.low.hashValue
    var hasher_HKAuthorizationRequestStatus = Hasher()
    hkRequire(HKAuthorizationRequestStatus.shouldRequest != HKAuthorizationRequestStatus.unknown)
    HKAuthorizationRequestStatus.shouldRequest.hash(into: &hasher_HKAuthorizationRequestStatus)
    _ = HKAuthorizationRequestStatus.shouldRequest.hashValue
    var hasher_HKBloodGlucoseMealTime = Hasher()
    hkRequire(HKBloodGlucoseMealTime.postprandial != HKBloodGlucoseMealTime.preprandial)
    HKBloodGlucoseMealTime.postprandial.hash(into: &hasher_HKBloodGlucoseMealTime)
    _ = HKBloodGlucoseMealTime.postprandial.hashValue
    var hasher_HKCategoryValue = Hasher()
    HKCategoryValue.notApplicable.hash(into: &hasher_HKCategoryValue)
    _ = HKCategoryValue.notApplicable.hashValue
    var hasher_HKCategoryValueAppleWalkingSteadinessEvent = Hasher()
    hkRequire(HKCategoryValueAppleWalkingSteadinessEvent.initialLow != HKCategoryValueAppleWalkingSteadinessEvent.initialVeryLow)
    HKCategoryValueAppleWalkingSteadinessEvent.initialLow.hash(into: &hasher_HKCategoryValueAppleWalkingSteadinessEvent)
    _ = HKCategoryValueAppleWalkingSteadinessEvent.initialLow.hashValue
    var hasher_HKCategoryValueContraceptive = Hasher()
    hkRequire(HKCategoryValueContraceptive.implant != HKCategoryValueContraceptive.injection)
    HKCategoryValueContraceptive.implant.hash(into: &hasher_HKCategoryValueContraceptive)
    _ = HKCategoryValueContraceptive.implant.hashValue
    var hasher_HKCategoryValueLowCardioFitnessEvent = Hasher()
    HKCategoryValueLowCardioFitnessEvent.lowFitness.hash(into: &hasher_HKCategoryValueLowCardioFitnessEvent)
    _ = HKCategoryValueLowCardioFitnessEvent.lowFitness.hashValue
    var hasher_HKCategoryValueSeverity = Hasher()
    hkRequire(HKCategoryValueSeverity.mild != HKCategoryValueSeverity.moderate)
    HKCategoryValueSeverity.mild.hash(into: &hasher_HKCategoryValueSeverity)
    _ = HKCategoryValueSeverity.mild.hashValue
    var hasher_HKCyclingFunctionalThresholdPowerTestType = Hasher()
    hkRequire(HKCyclingFunctionalThresholdPowerTestType.maxExercise20Minute != HKCyclingFunctionalThresholdPowerTestType.maxExercise60Minute)
    HKCyclingFunctionalThresholdPowerTestType.maxExercise20Minute.hash(into: &hasher_HKCyclingFunctionalThresholdPowerTestType)
    _ = HKCyclingFunctionalThresholdPowerTestType.maxExercise20Minute.hashValue
    var hasher_HKElectrocardiogram_Lead = Hasher()
    HKElectrocardiogram.Lead.appleWatchSimilarToLeadI.hash(into: &hasher_HKElectrocardiogram_Lead)
    _ = HKElectrocardiogram.Lead.appleWatchSimilarToLeadI.hashValue
    var hasher_HKFitzpatrickSkinType = Hasher()
    hkRequire(HKFitzpatrickSkinType.I != HKFitzpatrickSkinType.II)
    HKFitzpatrickSkinType.I.hash(into: &hasher_HKFitzpatrickSkinType)
    _ = HKFitzpatrickSkinType.I.hashValue
    var hasher_HKHeartRateMotionContext = Hasher()
    hkRequire(HKHeartRateMotionContext.active != HKHeartRateMotionContext.notSet)
    HKHeartRateMotionContext.active.hash(into: &hasher_HKHeartRateMotionContext)
    _ = HKHeartRateMotionContext.active.hashValue
    var hasher_HKInsulinDeliveryReason = Hasher()
    hkRequire(HKInsulinDeliveryReason.basal != HKInsulinDeliveryReason.bolus)
    HKInsulinDeliveryReason.basal.hash(into: &hasher_HKInsulinDeliveryReason)
    _ = HKInsulinDeliveryReason.basal.hashValue
    var hasher_HKMetricPrefix = Hasher()
    hkRequire(HKMetricPrefix.centi != HKMetricPrefix.deca)
    HKMetricPrefix.centi.hash(into: &hasher_HKMetricPrefix)
    _ = HKMetricPrefix.centi.hashValue
    var hasher_HKPhysicalEffortEstimationType = Hasher()
    hkRequire(HKPhysicalEffortEstimationType.activityLookup != HKPhysicalEffortEstimationType.deviceSensed)
    HKPhysicalEffortEstimationType.activityLookup.hash(into: &hasher_HKPhysicalEffortEstimationType)
    _ = HKPhysicalEffortEstimationType.activityLookup.hashValue
    var hasher_HKStateOfMind_Association = Hasher()
    hkRequire(HKStateOfMind.Association.community != HKStateOfMind.Association.currentEvents)
    HKStateOfMind.Association.community.hash(into: &hasher_HKStateOfMind_Association)
    _ = HKStateOfMind.Association.community.hashValue
    var hasher_HKStateOfMind_ValenceClassification = Hasher()
    hkRequire(HKStateOfMind.ValenceClassification.neutral != HKStateOfMind.ValenceClassification.pleasant)
    HKStateOfMind.ValenceClassification.neutral.hash(into: &hasher_HKStateOfMind_ValenceClassification)
    _ = HKStateOfMind.ValenceClassification.neutral.hashValue
    var hasher_HKUserMotionContext = Hasher()
    hkRequire(HKUserMotionContext.active != HKUserMotionContext.notSet)
    HKUserMotionContext.active.hash(into: &hasher_HKUserMotionContext)
    _ = HKUserMotionContext.active.hashValue
    var hasher_HKVisionPrescriptionType = Hasher()
    hkRequire(HKVisionPrescriptionType.contacts != HKVisionPrescriptionType.glasses)
    HKVisionPrescriptionType.contacts.hash(into: &hasher_HKVisionPrescriptionType)
    _ = HKVisionPrescriptionType.contacts.hashValue
    var hasher_HKWheelchairUse = Hasher()
    hkRequire(HKWheelchairUse.no != HKWheelchairUse.notSet)
    HKWheelchairUse.no.hash(into: &hasher_HKWheelchairUse)
    _ = HKWheelchairUse.no.hashValue
    var hasher_HKWorkoutSessionLocationType = Hasher()
    hkRequire(HKWorkoutSessionLocationType.indoor != HKWorkoutSessionLocationType.outdoor)
    HKWorkoutSessionLocationType.indoor.hash(into: &hasher_HKWorkoutSessionLocationType)
    _ = HKWorkoutSessionLocationType.indoor.hashValue
    var hasher_HKWorkoutSwimmingLocationType = Hasher()
    hkRequire(HKWorkoutSwimmingLocationType.openWater != HKWorkoutSwimmingLocationType.pool)
    HKWorkoutSwimmingLocationType.openWater.hash(into: &hasher_HKWorkoutSwimmingLocationType)
    _ = HKWorkoutSwimmingLocationType.openWater.hashValue
}
func testEnumEquatableAndHashable2() {
    var hasher_HKAppleECGAlgorithmVersion = Hasher()
    hkRequire(HKAppleECGAlgorithmVersion.version1 != HKAppleECGAlgorithmVersion.version2)
    HKAppleECGAlgorithmVersion.version1.hash(into: &hasher_HKAppleECGAlgorithmVersion)
    _ = HKAppleECGAlgorithmVersion.version1.hashValue
    var hasher_HKAudiogramConductionType = Hasher()
    HKAudiogramConductionType.air.hash(into: &hasher_HKAudiogramConductionType)
    _ = HKAudiogramConductionType.air.hashValue
    var hasher_HKAuthorizationStatus = Hasher()
    hkRequire(HKAuthorizationStatus.notDetermined != HKAuthorizationStatus.sharingAuthorized)
    HKAuthorizationStatus.notDetermined.hash(into: &hasher_HKAuthorizationStatus)
    _ = HKAuthorizationStatus.notDetermined.hashValue
    var hasher_HKBloodType = Hasher()
    hkRequire(HKBloodType.abNegative != HKBloodType.abPositive)
    HKBloodType.abNegative.hash(into: &hasher_HKBloodType)
    _ = HKBloodType.abNegative.hashValue
    var hasher_HKCategoryValueAppetiteChanges = Hasher()
    hkRequire(HKCategoryValueAppetiteChanges.decreased != HKCategoryValueAppetiteChanges.increased)
    HKCategoryValueAppetiteChanges.decreased.hash(into: &hasher_HKCategoryValueAppetiteChanges)
    _ = HKCategoryValueAppetiteChanges.decreased.hashValue
    var hasher_HKCategoryValueAudioExposureEvent = Hasher()
    HKCategoryValueAudioExposureEvent.loudEnvironment.hash(into: &hasher_HKCategoryValueAudioExposureEvent)
    _ = HKCategoryValueAudioExposureEvent.loudEnvironment.hashValue
    var hasher_HKCategoryValueEnvironmentalAudioExposureEvent = Hasher()
    HKCategoryValueEnvironmentalAudioExposureEvent.momentaryLimit.hash(into: &hasher_HKCategoryValueEnvironmentalAudioExposureEvent)
    _ = HKCategoryValueEnvironmentalAudioExposureEvent.momentaryLimit.hashValue
    var hasher_HKCategoryValueMenstrualFlow = Hasher()
    hkRequire(HKCategoryValueMenstrualFlow.heavy != HKCategoryValueMenstrualFlow.light)
    HKCategoryValueMenstrualFlow.heavy.hash(into: &hasher_HKCategoryValueMenstrualFlow)
    _ = HKCategoryValueMenstrualFlow.heavy.hashValue
    var hasher_HKCategoryValueSleepAnalysis = Hasher()
    hkRequire(HKCategoryValueSleepAnalysis.asleepCore != HKCategoryValueSleepAnalysis.asleepDeep)
    HKCategoryValueSleepAnalysis.asleepCore.hash(into: &hasher_HKCategoryValueSleepAnalysis)
    _ = HKCategoryValueSleepAnalysis.asleepCore.hashValue
    var hasher_HKDevicePlacementSide = Hasher()
    hkRequire(HKDevicePlacementSide.central != HKDevicePlacementSide.left)
    HKDevicePlacementSide.central.hash(into: &hasher_HKDevicePlacementSide)
    _ = HKDevicePlacementSide.central.hashValue
    var hasher_HKElectrocardiogram_SymptomsStatus = Hasher()
    hkRequire(HKElectrocardiogram.SymptomsStatus.none != HKElectrocardiogram.SymptomsStatus.notSet)
    HKElectrocardiogram.SymptomsStatus.none.hash(into: &hasher_HKElectrocardiogram_SymptomsStatus)
    _ = HKElectrocardiogram.SymptomsStatus.none.hashValue
    var hasher_HKGAD7Assessment_Answer = Hasher()
    hkRequire(HKGAD7Assessment.Answer.moreThanHalfTheDays != HKGAD7Assessment.Answer.nearlyEveryDay)
    HKGAD7Assessment.Answer.moreThanHalfTheDays.hash(into: &hasher_HKGAD7Assessment_Answer)
    _ = HKGAD7Assessment.Answer.moreThanHalfTheDays.hashValue
    var hasher_HKHeartRateRecoveryTestType = Hasher()
    hkRequire(HKHeartRateRecoveryTestType.maxExercise != HKHeartRateRecoveryTestType.predictionNonExercise)
    HKHeartRateRecoveryTestType.maxExercise.hash(into: &hasher_HKHeartRateRecoveryTestType)
    _ = HKHeartRateRecoveryTestType.maxExercise.hashValue
    var hasher_HKMedicationDoseEvent_LogStatus = Hasher()
    hkRequire(HKMedicationDoseEvent.LogStatus.notInteracted != HKMedicationDoseEvent.LogStatus.notLogged)
    HKMedicationDoseEvent.LogStatus.notInteracted.hash(into: &hasher_HKMedicationDoseEvent_LogStatus)
    _ = HKMedicationDoseEvent.LogStatus.notInteracted.hashValue
    var hasher_HKPHQ9Assessment_Answer = Hasher()
    hkRequire(HKPHQ9Assessment.Answer.moreThanHalfTheDays != HKPHQ9Assessment.Answer.nearlyEveryDay)
    HKPHQ9Assessment.Answer.moreThanHalfTheDays.hash(into: &hasher_HKPHQ9Assessment_Answer)
    _ = HKPHQ9Assessment.Answer.moreThanHalfTheDays.hashValue
    var hasher_HKPrismBase = Hasher()
    hkRequire(HKPrismBase.down != HKPrismBase.in)
    HKPrismBase.down.hash(into: &hasher_HKPrismBase)
    _ = HKPrismBase.down.hashValue
    var hasher_HKStateOfMind_Kind = Hasher()
    hkRequire(HKStateOfMind.Kind.dailyMood != HKStateOfMind.Kind.momentaryEmotion)
    HKStateOfMind.Kind.dailyMood.hash(into: &hasher_HKStateOfMind_Kind)
    _ = HKStateOfMind.Kind.dailyMood.hashValue
    var hasher_HKSwimmingStrokeStyle = Hasher()
    hkRequire(HKSwimmingStrokeStyle.backstroke != HKSwimmingStrokeStyle.breaststroke)
    HKSwimmingStrokeStyle.backstroke.hash(into: &hasher_HKSwimmingStrokeStyle)
    _ = HKSwimmingStrokeStyle.backstroke.hashValue
    var hasher_HKVO2MaxTestType = Hasher()
    hkRequire(HKVO2MaxTestType.maxExercise != HKVO2MaxTestType.predictionNonExercise)
    HKVO2MaxTestType.maxExercise.hash(into: &hasher_HKVO2MaxTestType)
    _ = HKVO2MaxTestType.maxExercise.hashValue
    var hasher_HKWaterSalinity = Hasher()
    hkRequire(HKWaterSalinity.freshWater != HKWaterSalinity.saltWater)
    HKWaterSalinity.freshWater.hash(into: &hasher_HKWaterSalinity)
    _ = HKWaterSalinity.freshWater.hashValue
    var hasher_HKWorkoutActivityType = Hasher()
    hkRequire(HKWorkoutActivityType.americanFootball != HKWorkoutActivityType.archery)
    HKWorkoutActivityType.americanFootball.hash(into: &hasher_HKWorkoutActivityType)
    _ = HKWorkoutActivityType.americanFootball.hashValue
    var hasher_HKWorkoutSessionState = Hasher()
    hkRequire(HKWorkoutSessionState.ended != HKWorkoutSessionState.notStarted)
    HKWorkoutSessionState.ended.hash(into: &hasher_HKWorkoutSessionState)
    _ = HKWorkoutSessionState.ended.hashValue
}
func testEnumEquatableAndHashable3() {
    var hasher_HKAppleSleepingBreathingDisturbancesClassification = Hasher()
    hkRequire(HKAppleSleepingBreathingDisturbancesClassification.elevated != HKAppleSleepingBreathingDisturbancesClassification.notElevated)
    HKAppleSleepingBreathingDisturbancesClassification.elevated.hash(into: &hasher_HKAppleSleepingBreathingDisturbancesClassification)
    _ = HKAppleSleepingBreathingDisturbancesClassification.elevated.hashValue
    var hasher_HKAudiogramSensitivityTestSide = Hasher()
    hkRequire(HKAudiogramSensitivityTestSide.left != HKAudiogramSensitivityTestSide.right)
    HKAudiogramSensitivityTestSide.left.hash(into: &hasher_HKAudiogramSensitivityTestSide)
    _ = HKAudiogramSensitivityTestSide.left.hashValue
    var hasher_HKBiologicalSex = Hasher()
    hkRequire(HKBiologicalSex.female != HKBiologicalSex.male)
    HKBiologicalSex.female.hash(into: &hasher_HKBiologicalSex)
    _ = HKBiologicalSex.female.hashValue
    var hasher_HKBodyTemperatureSensorLocation = Hasher()
    hkRequire(HKBodyTemperatureSensorLocation.armpit != HKBodyTemperatureSensorLocation.body)
    HKBodyTemperatureSensorLocation.armpit.hash(into: &hasher_HKBodyTemperatureSensorLocation)
    _ = HKBodyTemperatureSensorLocation.armpit.hashValue
    var hasher_HKCategoryValueAppleStandHour = Hasher()
    hkRequire(HKCategoryValueAppleStandHour.idle != HKCategoryValueAppleStandHour.stood)
    HKCategoryValueAppleStandHour.idle.hash(into: &hasher_HKCategoryValueAppleStandHour)
    _ = HKCategoryValueAppleStandHour.idle.hashValue
    var hasher_HKCategoryValueCervicalMucusQuality = Hasher()
    hkRequire(HKCategoryValueCervicalMucusQuality.creamy != HKCategoryValueCervicalMucusQuality.dry)
    HKCategoryValueCervicalMucusQuality.creamy.hash(into: &hasher_HKCategoryValueCervicalMucusQuality)
    _ = HKCategoryValueCervicalMucusQuality.creamy.hashValue
    var hasher_HKCategoryValueHeadphoneAudioExposureEvent = Hasher()
    HKCategoryValueHeadphoneAudioExposureEvent.sevenDayLimit.hash(into: &hasher_HKCategoryValueHeadphoneAudioExposureEvent)
    _ = HKCategoryValueHeadphoneAudioExposureEvent.sevenDayLimit.hashValue
    var hasher_HKCategoryValuePresence = Hasher()
    hkRequire(HKCategoryValuePresence.notPresent != HKCategoryValuePresence.present)
    HKCategoryValuePresence.notPresent.hash(into: &hasher_HKCategoryValuePresence)
    _ = HKCategoryValuePresence.notPresent.hashValue
    var hasher_HKCategoryValueVaginalBleeding = Hasher()
    hkRequire(HKCategoryValueVaginalBleeding.heavy != HKCategoryValueVaginalBleeding.light)
    HKCategoryValueVaginalBleeding.heavy.hash(into: &hasher_HKCategoryValueVaginalBleeding)
    _ = HKCategoryValueVaginalBleeding.heavy.hashValue
    var hasher_HKElectrocardiogram_Classification = Hasher()
    hkRequire(HKElectrocardiogram.Classification.atrialFibrillation != HKElectrocardiogram.Classification.inconclusiveHighHeartRate)
    HKElectrocardiogram.Classification.atrialFibrillation.hash(into: &hasher_HKElectrocardiogram_Classification)
    _ = HKElectrocardiogram.Classification.atrialFibrillation.hashValue
    var hasher_HKError_Code = Hasher()
    hkRequire(HKError.Code.errorAnotherWorkoutSessionStarted != HKError.Code.errorAuthorizationDenied)
    HKError.Code.errorAnotherWorkoutSessionStarted.hash(into: &hasher_HKError_Code)
    _ = HKError.Code.errorAnotherWorkoutSessionStarted.hashValue
    var hasher_HKGAD7Assessment_Risk = Hasher()
    hkRequire(HKGAD7Assessment.Risk.mild != HKGAD7Assessment.Risk.moderate)
    HKGAD7Assessment.Risk.mild.hash(into: &hasher_HKGAD7Assessment_Risk)
    _ = HKGAD7Assessment.Risk.mild.hashValue
    var hasher_HKHeartRateSensorLocation = Hasher()
    hkRequire(HKHeartRateSensorLocation.chest != HKHeartRateSensorLocation.earLobe)
    HKHeartRateSensorLocation.chest.hash(into: &hasher_HKHeartRateSensorLocation)
    _ = HKHeartRateSensorLocation.chest.hashValue
    var hasher_HKMedicationDoseEvent_ScheduleType = Hasher()
    hkRequire(HKMedicationDoseEvent.ScheduleType.asNeeded != HKMedicationDoseEvent.ScheduleType.schedule)
    HKMedicationDoseEvent.ScheduleType.asNeeded.hash(into: &hasher_HKMedicationDoseEvent_ScheduleType)
    _ = HKMedicationDoseEvent.ScheduleType.asNeeded.hashValue
    var hasher_HKPHQ9Assessment_Risk = Hasher()
    hkRequire(HKPHQ9Assessment.Risk.mild != HKPHQ9Assessment.Risk.moderate)
    HKPHQ9Assessment.Risk.mild.hash(into: &hasher_HKPHQ9Assessment_Risk)
    _ = HKPHQ9Assessment.Risk.mild.hashValue
    var hasher_HKQuantityAggregationStyle = Hasher()
    hkRequire(HKQuantityAggregationStyle.cumulative != HKQuantityAggregationStyle.discreteArithmetic)
    HKQuantityAggregationStyle.cumulative.hash(into: &hasher_HKQuantityAggregationStyle)
    _ = HKQuantityAggregationStyle.cumulative.hashValue
    var hasher_HKStateOfMind_Label = Hasher()
    hkRequire(HKStateOfMind.Label.amazed != HKStateOfMind.Label.amused)
    HKStateOfMind.Label.amazed.hash(into: &hasher_HKStateOfMind_Label)
    _ = HKStateOfMind.Label.amazed.hashValue
    var hasher_HKUpdateFrequency = Hasher()
    hkRequire(HKUpdateFrequency.daily != HKUpdateFrequency.hourly)
    HKUpdateFrequency.daily.hash(into: &hasher_HKUpdateFrequency)
    _ = HKUpdateFrequency.daily.hashValue
    var hasher_HKVisionEye = Hasher()
    hkRequire(HKVisionEye.left != HKVisionEye.right)
    HKVisionEye.left.hash(into: &hasher_HKVisionEye)
    _ = HKVisionEye.left.hashValue
    var hasher_HKWeatherCondition = Hasher()
    hkRequire(HKWeatherCondition.blustery != HKWeatherCondition.clear)
    HKWeatherCondition.blustery.hash(into: &hasher_HKWeatherCondition)
    _ = HKWeatherCondition.blustery.hashValue
    var hasher_HKWorkoutEventType = Hasher()
    hkRequire(HKWorkoutEventType.lap != HKWorkoutEventType.marker)
    HKWorkoutEventType.lap.hash(into: &hasher_HKWorkoutEventType)
    _ = HKWorkoutEventType.lap.hashValue
    var hasher_HKWorkoutSessionType = Hasher()
    hkRequire(HKWorkoutSessionType.mirrored != HKWorkoutSessionType.primary)
    HKWorkoutSessionType.mirrored.hash(into: &hasher_HKWorkoutSessionType)
    _ = HKWorkoutSessionType.mirrored.hashValue
}
