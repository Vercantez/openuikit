import Foundation
import PassKit

// MARK: - Synthesized Hashable.hashValue witnesses.
//
// Each check below reads `.hashValue` directly on the corresponding Linux
// port type, so the synthesized `hashValue` witness for that exact symbol is
// exercised. Equal values must hash equally; the values are also inserted
// into Sets to prove the hashes are usable as hash keys. All synchronous.

private func passKitHashValuesEqual<T: Hashable>(_ first: T, _ second: T) -> Bool {
    first.hashValue == second.hashValue
}

func testSynthesizedHashValueEnums() {
    precondition(passKitHashValuesEqual(PKAddIdentityDocumentType.mDL, .mDL))
    precondition(passKitHashValuesEqual(PKAddPassButtonStyle.black, .black))
    precondition(passKitHashValuesEqual(PKAddPaymentPassError.systemCancelled, .systemCancelled))
    precondition(passKitHashValuesEqual(PKAddPaymentPassStyle.payment, .payment))
    precondition(passKitHashValuesEqual(PKAddSecureElementPassError.Code.deviceNotReadyError, .deviceNotReadyError))
    precondition(passKitHashValuesEqual(PKAddShareablePassConfigurationPrimaryAction.add, .add))
    precondition(passKitHashValuesEqual(PKApplePayLaterAvailability.available, .available))
    precondition(passKitHashValuesEqual(PKAutomaticPassPresentationSuppressionResult.denied, .denied))
    precondition(passKitHashValuesEqual(PKBarcodeEventConfigurationDataType.signingKeyMaterial, .signingKeyMaterial))
    precondition(passKitHashValuesEqual(PKDisbursementError.Code.recipientContactInvalidError, .recipientContactInvalidError))
    precondition(passKitHashValuesEqual(PKIdentityButton.Label.verify, .verify))
    precondition(passKitHashValuesEqual(PKIdentityButton.Style.black, .black))
    precondition(passKitHashValuesEqual(PKIdentityError.Code.unknown, .unknown))
    precondition(passKitHashValuesEqual(PKIssuerProvisioningExtensionAuthorizationResult.authorized, .authorized))
    precondition(passKitHashValuesEqual(PKPassKitError.Code.invalidSignature, .invalidSignature))
    precondition(passKitHashValuesEqual(PKPassLibraryAddPassesStatus.shouldReviewPasses, .shouldReviewPasses))
    precondition(passKitHashValuesEqual(PKPassLibrary.AuthorizationStatus.restricted, .restricted))
    precondition(passKitHashValuesEqual(PKPassLibrary.Capability.backgroundAddPasses, .backgroundAddPasses))
    precondition(passKitHashValuesEqual(PKPassType.any, .any))
    precondition(passKitHashValuesEqual(PKPayLaterAction.learnMore, .learnMore))
    precondition(passKitHashValuesEqual(PKPayLaterDisplayStyle.badge, .badge))
    precondition(passKitHashValuesEqual(PKPaymentAuthorizationStatus.pinLockout, .pinLockout))
    precondition(passKitHashValuesEqual(PKPaymentButtonStyle.white, .white))
    precondition(passKitHashValuesEqual(PKPaymentButtonType.plain, .plain))
    precondition(passKitHashValuesEqual(PKPaymentError.Code.billingContactInvalidError, .billingContactInvalidError))
    precondition(passKitHashValuesEqual(PKPaymentMethodType.prepaid, .prepaid))
    precondition(passKitHashValuesEqual(PKPaymentPassActivationState.suspended, .suspended))
    precondition(passKitHashValuesEqual(PKPaymentSummaryItemType.final, .final))
    precondition(passKitHashValuesEqual(PKSecureElementPass.PassActivationState.activating, .activating))
    precondition(passKitHashValuesEqual(PKShareSecureElementPassError.Code.setupError, .setupError))
    precondition(passKitHashValuesEqual(PKShareSecureElementPassResult.shared, .shared))
    precondition(passKitHashValuesEqual(PKShippingContactEditingMode.storePickup, .storePickup))
    precondition(passKitHashValuesEqual(PKShippingType.shipping, .shipping))
    precondition(passKitHashValuesEqual(PKVehicleConnectionErrorCode.unknown, .unknown))
    precondition(passKitHashValuesEqual(PKVehicleConnectionSessionConnectionState.disconnected, .disconnected))
    var enumSet: Set<PKPaymentButtonType> = [.plain]
    enumSet.insert(.buy)
    precondition(enumSet.contains(.plain))
    precondition(enumSet.contains(.buy))
    var modeSet: Set<PKShippingType> = [.shipping]
    modeSet.insert(.delivery)
    precondition(modeSet.contains(.delivery))
}

func testSynthesizedHashValueErrorBridging() {
    let passKit = PKPassKitError(.notEntitledError, userInfo: ["reason": "linux"])
    precondition(passKitHashValuesEqual(passKit, PKPassKitError(.notEntitledError, userInfo: ["reason": "linux"])))
    let payment = PKPaymentError(.couponCodeInvalidError, userInfo: ["code": "SAVE"])
    precondition(passKitHashValuesEqual(payment, PKPaymentError(.couponCodeInvalidError, userInfo: ["code": "SAVE"])))
    let identity = PKIdentityError(.cancelled, userInfo: ["n": "1"])
    precondition(passKitHashValuesEqual(identity, PKIdentityError(.cancelled, userInfo: ["n": "1"])))
    let disbursement = PKDisbursementError(.unsupportedCardError, userInfo: ["card": "no"])
    precondition(passKitHashValuesEqual(disbursement, PKDisbursementError(.unsupportedCardError, userInfo: ["card": "no"])))
    let secureElement = PKAddSecureElementPassError(.deviceNotReadyError, userInfo: ["se": "no"])
    precondition(passKitHashValuesEqual(secureElement, PKAddSecureElementPassError(.deviceNotReadyError, userInfo: ["se": "no"])))
    let share = PKShareSecureElementPassError(.setupError, userInfo: ["share": "no"])
    precondition(passKitHashValuesEqual(share, PKShareSecureElementPassError(.setupError, userInfo: ["share": "no"])))
    var errorSet: Set<PKPassKitError> = [passKit]
    errorSet.insert(PKPassKitError(.invalidSignature))
    precondition(errorSet.contains(passKit))
    precondition(errorSet.contains(PKPassKitError(.invalidSignature)))
}

func testSynthesizedHashValueNewtypes() {
    precondition(passKitHashValuesEqual(PKContactField.emailAddress, .emailAddress))
    precondition(passKitHashValuesEqual(PKDisbursementErrorKey.contactFieldUserInfoKey, .contactFieldUserInfoKey))
    precondition(passKitHashValuesEqual(PKEncryptionScheme.ECC_V2, .ECC_V2))
    precondition(passKitHashValuesEqual(PKPassLibraryNotificationKey.serialNumberUserInfoKey, .serialNumberUserInfoKey))
    precondition(passKitHashValuesEqual(PKPassLibraryNotificationName.PKPassLibraryDidChange, .PKPassLibraryDidChange))
    precondition(passKitHashValuesEqual(PKPaymentErrorKey.postalAddressUserInfoKey, .postalAddressUserInfoKey))
    precondition(passKitHashValuesEqual(PKPaymentNetwork.visa, .visa))
    precondition(passKitHashValuesEqual(PKStoredValuePassBalance.BalanceType.cash, .cash))
    var networkSet: Set<PKPaymentNetwork> = [.visa]
    networkSet.insert(.masterCard)
    precondition(networkSet.contains(.visa))
    precondition(networkSet.contains(.masterCard))
    var fieldSet: Set<PKContactField> = [.emailAddress]
    fieldSet.insert(.name)
    precondition(fieldSet.contains(.name))
}
