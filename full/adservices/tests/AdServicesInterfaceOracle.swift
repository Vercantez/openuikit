import AdServices

let signature: () throws -> String = AAAttribution.attributionToken
_ = signature

print("domain=\(AAAttributionErrorDomain)")
print(
    "codes=network:\(AAAttributionError.Code.networkError.rawValue)," +
    "internal:\(AAAttributionError.Code.internalError.rawValue)," +
    "platform:\(AAAttributionError.Code.platformNotSupported.rawValue)"
)
print("signature=() throws -> String")
