import Foundation

#if FOUNDATION_GUEST_PORT
let sourceNSError = NSError(
    domain: "Portable.Domain",
    code: 42,
    userInfo: ["k": "v"]
)
let cfError = unsafeBitCast(sourceNSError, to: CFError.self)
#else
let cfError = CFErrorCreate(
    nil,
    "Portable.Domain" as CFString,
    42,
    ["k": "v"] as CFDictionary
)!
#endif

let error: any Error = cfError
precondition(error._domain == "Portable.Domain")
precondition(error._code == 42)
precondition((error._userInfo as? [String: Any])?["k"] as? String == "v")
precondition(error._getEmbeddedNSError() === cfError)

let bridgedNSError = error as NSError
precondition(bridgedNSError.domain == "Portable.Domain")
precondition(bridgedNSError.code == 42)
precondition(bridgedNSError.userInfo["k"] as? String == "v")

print(
    "FOUNDATION_CFERROR_BRIDGE_OK " +
    "domain=Portable.Domain code=42 userInfo=k:v embedded=identity " +
    "nserror=preserved"
)
