import Foundation
import HomeKit

// Isolated host probe: pass genuine Foundation values through public HomeKit APIs.
let _uuid: UUID = HMUser.host_make(name: "Pat", uniqueIdentifier: UUID()).uniqueIdentifier
let _data: Data = Data([0x01])
let _token = HMAccessoryOwnershipToken(data: _data)
let _range = HMNumberRange(minValue: NSNumber(value: 1), maxValue: NSNumber(value: 2))
let _error = HMError(.notFound, userInfo: [NSLocalizedDescriptionKey: "missing"])
let _ = (_uuid, _token, _range, _error.errorCode)
