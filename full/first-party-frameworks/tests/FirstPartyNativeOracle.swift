import Foundation
import UIKit
import LocalAuthentication
import SafariServices
import Network
import StoreKit
import AudioToolbox
import CoreHaptics
import PassKit

// This is compiled, not called. It pins Focus's exact seven-framework source
// spellings against Apple's iOS 26.1 SDK without starting a browser, purchase,
// authentication, network, audio, haptic, or pass-library operation.
@MainActor
private func compileFocusSurface(
    scene: UIWindowScene,
    data: Data,
    queue: DispatchQueue
) async {
    let context = LAContext()
    _ = context.canEvaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        error: nil
    )
    _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    _ = context.biometryType
    _ = try? await context.evaluatePolicy(
        .deviceOwnerAuthentication,
        localizedReason: "signature only"
    )
    SFContentBlockerManager.getStateOfContentBlocker(
        withIdentifier: "signature.only"
    ) { _, _ in }
    SFContentBlockerManager.reloadContentBlocker(
        withIdentifier: "signature.only"
    ) { _ in }
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { _ in }
    monitor.start(queue: queue)
    monitor.cancel()
    SKStoreReviewController.requestReview(in: scene)
    AudioServicesPlaySystemSound(1519)
    _ = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    if let pass = try? PKPass(data: data) {
        _ = PKPassLibrary().containsPass(pass)
        _ = PKAddPassesViewController(pass: pass)
        _ = pass.passURL
    }
}

@main
private struct FirstPartyNativeOracle {
    @MainActor
    static func main() {
        print(
            "la.policy=\(LAPolicy.deviceOwnerAuthenticationWithBiometrics.rawValue),"
                + "\(LAPolicy.deviceOwnerAuthentication.rawValue)"
        )
        print(
            "la.biometry=\(LABiometryType.none.rawValue),"
                + "\(LABiometryType.touchID.rawValue),"
                + "\(LABiometryType.faceID.rawValue),"
                + "\(LABiometryType.opticID.rawValue)"
        )
        print(
            "la.error=\(LAError.Code.biometryNotAvailable.rawValue),"
                + "\(LAError.Code.notInteractive.rawValue)"
        )

        let safari = SFSafariViewController.Configuration()
        print("safari.reader=\(safari.entersReaderIfAvailable)")
        print("safari.collapse=\(safari.barCollapsingEnabled)")

        print(
            "network.port=\(NWEndpoint.Port.http.rawValue),"
                + "\(NWEndpoint.Port.https.rawValue),"
                + "\(NWEndpoint.Port.any.rawValue)"
        )
        let ipv4Bytes = IPv4Address("127.0.0.1")?.rawValue
            .map(String.init).joined(separator: ".") ?? "nil"
        let ipv6Prefix = IPv6Address("fe80::1")?.rawValue.prefix(2)
            .map(String.init).joined(separator: ".") ?? "nil"
        print(
            "network.ip-addresses=\(ipv4Bytes),"
                + "\(IPv4Address("999.0.0.1") == nil),"
                + "\(ipv6Prefix),\(IPv6Address("not-an-address") == nil)"
        )
        let host: NWEndpoint.Host = "example.invalid"
        let endpoint = NWEndpoint.hostPort(host: host, port: .https)
        print("network.endpoint=\(endpoint.debugDescription)")
        let parameters = NWParameters.tcp
        print("network.peer-to-peer=\(parameters.includePeerToPeer)")
        print("network.reuse=\(parameters.allowLocalEndpointReuse)")

        print(
            "store.error=\(SKError.Code.unknown.rawValue),"
                + "\(SKError.Code.paymentCancelled.rawValue),"
                + "\(SKError.Code.paymentNotAllowed.rawValue)"
        )
        print("store.can-pay=\(SKPaymentQueue.canMakePayments())")

        var format = AudioStreamBasicDescription()
        print(
            "audio.zero=\(format.mSampleRate),\(format.mFormatID),"
                + "\(format.mChannelsPerFrame)"
        )
        format.mFormatID = kAudioFormatLinearPCM
        print("audio.linear-pcm=\(format.mFormatID)")
        print("audio.vibrate=\(kSystemSoundID_Vibrate)")

        let intensity = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: 0.75
        )
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity],
            relativeTime: 0.25,
            duration: 1.5
        )
        let pattern = try! CHHapticPattern(events: [event], parameters: [])
        print("haptics.pattern-duration=\(pattern.duration)")
        print(
            "haptics.ids=\(CHHapticEvent.ParameterID.hapticIntensity.rawValue),"
                + "\(CHHapticEvent.EventType.hapticContinuous.rawValue)"
        )

        let request = PKPaymentRequest()
        print("pass.request-country=\(request.countryCode)")
        print("pass.request-currency=\(request.currencyCode)")
        print("pass.request-networks=\(request.supportedNetworks.count)")
        print("pass.can-pay=\(PKPaymentAuthorizationController.canMakePayments())")
        print("pass.can-add=\(PKAddPassesViewController.canAddPasses())")
        print(
            "pass.networks=\(PKPaymentNetwork.visa.rawValue),"
                + "\(PKPaymentNetwork.masterCard.rawValue),"
                + "\(PKPaymentNetwork.amex.rawValue)"
        )
        print(
            "pass.capabilities=\(PKMerchantCapability.threeDSecure.rawValue),"
                + "\(PKMerchantCapability.credit.rawValue),"
                + "\(PKMerchantCapability.debit.rawValue)"
        )
    }
}
