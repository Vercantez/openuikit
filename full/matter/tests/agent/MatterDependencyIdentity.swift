import Foundation
import Matter

let _data: Data = Data([0x01, 0x02])
let _num = NSNumber(value: 20202021)
let _payload = MTRSetupPayload(setupPasscode: _num, discriminator: NSNumber(value: 3840))
let _range = _payload.vendorID
let _err = MTRError(.notFound, userInfo: [NSLocalizedDescriptionKey: "missing"])
let _matterIdentityProbe = (_data, _range, _err.errorCode, MTRArrayValueType)
