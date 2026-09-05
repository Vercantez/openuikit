import Foundation
import CoreNFC

func testTagCommandConfiguration() {
    let defaults = NFCTagCommandConfiguration()
    precondition(defaults.maximumRetries == 0)
    precondition(defaults.retryInterval == 0)
    let configured = NFCTagCommandConfiguration(maximumRetries: 3, retryInterval: 0.25)
    precondition(configured.maximumRetries == 3)
    precondition(configured.retryInterval == 0.25)
}

func testISO15693CustomCommandConfiguration() {
    let custom = NFCISO15693CustomCommandConfiguration(
        manufacturerCode: 0x04,
        customCommandCode: 0xA0,
        requestParameters: Data([0xFF])
    )
    precondition(custom.manufacturerCode == 4)
    precondition(custom.customCommandCode == 0xA0)
    precondition(custom.requestParameters == Data([0xFF]))
    precondition(custom.maximumRetries == 0)

    let retried = NFCISO15693CustomCommandConfiguration(
        manufacturerCode: 7,
        customCommandCode: 0xB1,
        requestParameters: nil,
        maximumRetries: 2,
        retryInterval: 0.5
    )
    precondition(retried.requestParameters.isEmpty)
    precondition(retried.maximumRetries == 2)
    precondition(retried.retryInterval == 0.5)
}

func testISO15693ReadMultipleBlocksConfiguration() {
    let basic = NFCISO15693ReadMultipleBlocksConfiguration(
        range: NSRange(location: 1, length: 8),
        chunkSize: 4
    )
    precondition(basic.range.location == 1)
    precondition(basic.range.length == 8)
    precondition(basic.chunkSize == 4)
    precondition(basic.maximumRetries == 0)

    let ranged = NFCISO15693ReadMultipleBlocksConfiguration(
        range: NSRange(location: 0, length: 4),
        chunkSize: 2,
        maximumRetries: 1,
        retryInterval: 0.1
    )
    precondition(ranged.chunkSize == 2)
    precondition(ranged.maximumRetries == 1)
    precondition(ranged.retryInterval == 0.1)
}

func testVASCommandConfiguration() {
    let vas = NFCVASCommandConfiguration(
        vasMode: .normal,
        passTypeIdentifier: "pass.com.example.nfc",
        url: URL(string: "https://example.com")
    )
    precondition(vas.mode == .normal)
    precondition(vas.passTypeIdentifier == "pass.com.example.nfc")
    precondition(vas.url?.absoluteString == "https://example.com")
    let urlOnly = NFCVASCommandConfiguration(
        VASMode: .urlOnly,
        passTypeIdentifier: "pass.com.example.nfc",
        url: nil
    )
    precondition(urlOnly.mode == .urlOnly)
    precondition(urlOnly.url == nil)
}

func testVASResponse() {
    let response = NFCVASResponse(status: .success, vasData: Data([1]), mobileToken: Data([2]))
    precondition(response.status == .success)
    precondition(response.vasData == Data([1]))
    precondition(response.mobileToken == Data([2]))
}
