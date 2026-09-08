import Foundation
import Intents

func testWave13ResolutionResultStateMachine() {
    let types: [INIntentResolutionResult.Type] = [
        INAccountTypeResolutionResult.self,
        INAddMediaMediaDestinationResolutionResult.self,
        INAddTasksTargetTaskListResolutionResult.self,
        INAddTasksTemporalEventTriggerResolutionResult.self,
        INBalanceTypeResolutionResult.self,
        INBillTypeResolutionResult.self,
        INCallCapabilityResolutionResult.self,
        INCallDestinationTypeResolutionResult.self,
        INCallRecordResolutionResult.self,
        INCallRecordTypeResolutionResult.self,
        INCarAirCirculationModeResolutionResult.self,
        INCarAudioSourceResolutionResult.self,
        INCarDefrosterResolutionResult.self,
        INCarSeatResolutionResult.self,
        INCarSignalOptionsResolutionResult.self,
        INDateComponentsResolutionResult.self,
        INDateSearchTypeResolutionResult.self,
        INDeleteTasksTaskListResolutionResult.self,
        INDeleteTasksTaskResolutionResult.self,
        INEnergyResolutionResult.self,
        INEnumResolutionResult.self,
        INLengthResolutionResult.self,
        INLocationSearchTypeResolutionResult.self,
        INMassResolutionResult.self,
        INMediaAffinityTypeResolutionResult.self,
        INNoteContentResolutionResult.self,
        INNoteContentTypeResolutionResult.self,
        INOutgoingMessageTypeResolutionResult.self,
        INPaymentAmountResolutionResult.self,
        INPaymentMethodResolutionResult.self,
        INPaymentStatusResolutionResult.self,
        INPlayMediaMediaItemResolutionResult.self,
        INPlayMediaPlaybackSpeedResolutionResult.self,
        INPlaybackQueueLocationResolutionResult.self,
        INPlaybackRepeatModeResolutionResult.self,
        INRadioTypeResolutionResult.self,
        INRelativeReferenceResolutionResult.self,
        INRelativeSettingResolutionResult.self,
        INRequestPaymentCurrencyAmountResolutionResult.self,
        INRequestPaymentPayerResolutionResult.self,
        INRestaurantResolutionResult.self,
        INSearchForMediaMediaItemResolutionResult.self,
        INSendPaymentCurrencyAmountResolutionResult.self,
        INSendPaymentPayeeResolutionResult.self,
        INSetTaskAttributeTemporalEventTriggerResolutionResult.self,
        INSnoozeTasksTaskResolutionResult.self,
        INSpatialEventTriggerResolutionResult.self,
        INSpeedResolutionResult.self,
        INStartCallCallCapabilityResolutionResult.self,
        INStartCallCallRecordToCallBackResolutionResult.self,
        INStartCallContactResolutionResult.self,
        INTaskPriorityResolutionResult.self,
        INTaskStatusResolutionResult.self,
        INTemperatureResolutionResult.self,
        INTemporalEventTriggerResolutionResult.self,
        INTimeIntervalResolutionResult.self,
        INURLResolutionResult.self,
        INUpdateMediaAffinityMediaItemResolutionResult.self,
        INVisualCodeTypeResolutionResult.self,
        INVolumeResolutionResult.self,
    ]

    for (index, type) in types.enumerated() {
        let token = "resolution-\(index)"
        let success = type.init(outcome: .success, value: token)
        precondition(success.outcome == .success)
        precondition(success.resolvedValue as? String == token)
        precondition(Swift.type(of: success) == type)

        let confirmation = type.init(outcome: .confirmationRequired, value: index)
        precondition(confirmation.outcome == .confirmationRequired)
        precondition(confirmation.resolvedValue as? Int == index)

        precondition(type.needsValue().outcome == .needsValue)
        precondition(type.notRequired().outcome == .notRequired)
        precondition(type.unsupported().outcome == .unsupported)
    }
}

func testWave13PriorityResolutionFactories() {
    var date = DateComponents()
    date.year = 2026
    let dateSuccess = INDateComponentsResolutionResult.success(with: date)
    precondition((dateSuccess.resolvedValue as? DateComponents)?.year == 2026)
    precondition(INDateComponentsResolutionResult.disambiguation(with: [date]).outcome == .disambiguation)
    precondition(INDateComponentsResolutionResult.confirmationRequired(with: date).outcome == .confirmationRequired)

    let energy = Measurement(value: 42, unit: UnitEnergy.kilowattHours)
    precondition(INEnergyResolutionResult.success(with: energy).outcome == .success)
    precondition(INEnergyResolutionResult.disambiguation(with: [energy]).outcome == .disambiguation)
    precondition(INEnergyResolutionResult.confirmationRequired(with: energy).outcome == .confirmationRequired)

    let length = Measurement(value: 3, unit: UnitLength.meters)
    precondition(INLengthResolutionResult.success(with: length).outcome == .success)
    precondition(INLengthResolutionResult.disambiguation(with: [length]).outcome == .disambiguation)

    let mass = Measurement(value: 5, unit: UnitMass.kilograms)
    precondition(INMassResolutionResult.success(with: mass).outcome == .success)
    precondition(INMassResolutionResult.confirmationRequired(with: mass).outcome == .confirmationRequired)

    let amount = INPaymentAmount(amountType: .amountDue, amount: INCurrencyAmount(amount: NSDecimalNumber(string: "9.50"), currencyCode: "USD"))
    precondition(INPaymentAmountResolutionResult.success(with: amount).outcome == .success)
    precondition(INPaymentAmountResolutionResult.disambiguation(with: [amount]).outcome == .disambiguation)

    let method = INPaymentMethod.applePay()
    precondition(INPaymentMethodResolutionResult.success(with: method).outcome == .success)
    precondition(INPaymentMethodResolutionResult.confirmationRequired(with: method).outcome == .confirmationRequired)
}

func testWave13DeclaredIntentAndResponseStorage() {
    let cancel = INCancelRideIntent(rideIdentifier: "ride-13")
    precondition(cancel.rideIdentifier == "ride-13")

    let hangUp = INHangUpCallIntent(callIdentifier: "call-13")
    precondition(hangUp.callIdentifier == "call-13")
    let activity = NSUserActivity(activityType: "org.openui.wave13")
    let hangUpResponse = INHangUpCallIntentResponse(code: .success, userActivity: activity)
    precondition(hangUpResponse.code == .success)
    precondition(hangUpResponse.userActivity === activity)

    let carsResponse = INListCarsIntentResponse(code: .success, userActivity: activity)
    carsResponse.cars = []
    precondition(carsResponse.code == .success)
    precondition(carsResponse.cars?.isEmpty == true)

    let share = INShareFocusStatusIntent(focusStatus: INFocusStatus(isFocused: true))
    precondition(share.focusStatus?.isFocused == true)
    let unsend = INUnsendMessagesIntent(messageIdentifiers: ["message-13"])
    precondition(unsend.messageIdentifiers == ["message-13"])
}

func testWave13FailClosedAndValueSurface() {
    let card = INDefaultCardTemplate(title: "Wave 13")
    card.subtitle = "Linux"
    precondition(card.title == "Wave 13")
    precondition(card.subtitle == "Linux")

    let interval = INDateComponentsRange(start: DateComponents(), end: DateComponents())
    let trigger = INTemporalEventTrigger(dateComponentsRange: interval)
    precondition(trigger.dateComponentsRange === interval)

    let party = INRidePartySizeOption(partySizeRange: NSRange(location: 1, length: 3), sizeDescription: "one to three", priceRange: nil)
    precondition(party.partySizeRange?.location == 1)
    precondition(party.sizeDescription == "one to three")

    let terms = INTermsAndConditions(localizedTermsAndConditionsText: "Terms", privacyPolicyURL: URL(string: "https://example.invalid/privacy")!, termsAndConditionsURL: nil)
    precondition(terms.localizedTermsAndConditionsText == "Terms")
    precondition(terms.privacyPolicyURL?.host == "example.invalid")
}
