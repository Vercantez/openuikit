import Foundation

public func SecAccessControlCreateWithFlags(_ allocator: CFAllocator?, _ protection: CFTypeRef, _ flags: SecAccessControlCreateFlags, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecAccessControl? {
    _ = allocator
    _ = protection
    _ = flags
    error?.pointee = nil
    return SecAccessControl()
}

public func SecAccessControlGetTypeID() -> CFTypeID {
    return _secTypeAccessControl()
}

public func SecAddSharedWebCredential(_ fqdn: CFString, _ account: CFString, _ password: CFString?, _ completionHandler: @escaping (CFError?) -> Void) {
    _ = account
    _ = password
    _ = completionHandler
    completionHandler(_securityFailClosedError())
}

public func SecCertificateCopyCommonName(_ certificate: SecCertificate, _ commonName: UnsafeMutablePointer<CFString?>) -> OSStatus {
    _ = commonName
    return errSecUnimplemented
}

public func SecCertificateCopyData(_ certificate: SecCertificate) -> CFData {
    return certificate.data
}

public func SecCertificateCopyEmailAddresses(_ certificate: SecCertificate, _ emailAddresses: UnsafeMutablePointer<CFArray?>) -> OSStatus {
    _ = emailAddresses
    return errSecUnimplemented
}

public func SecCertificateCopyKey(_ certificate: SecCertificate) -> SecKey? {
    return nil
}

public func SecCertificateCopyNormalizedIssuerSequence(_ certificate: SecCertificate) -> CFData? {
    return nil
}

public func SecCertificateCopyNormalizedSubjectSequence(_ certificate: SecCertificate) -> CFData? {
    return nil
}

public func SecCertificateCopyNotValidAfterDate(_ certificate: SecCertificate) -> CFDate? {
    return nil
}

public func SecCertificateCopyNotValidBeforeDate(_ certificate: SecCertificate) -> CFDate? {
    return nil
}

public func SecCertificateCopyPublicKey(_ certificate: SecCertificate) -> SecKey? {
    return nil
}

public func SecCertificateCopySerialNumber(_ certificate: SecCertificate) -> CFData? {
    return nil
}

public func SecCertificateCopySerialNumberData(_ certificate: SecCertificate, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
    _ = error
    return nil
}

public func SecCertificateCopySubjectSummary(_ certificate: SecCertificate) -> CFString? {
    return nil
}

public func SecCertificateCreateWithData(_ allocator: CFAllocator?, _ data: CFData) -> SecCertificate? {
    _ = data
    return SecCertificate(data: data)
}

public func SecCertificateGetTypeID() -> CFTypeID {
    return _secTypeCertificate()
}

public func SecCreateSharedWebCredentialPassword() -> CFString? {
    return nil
}

public func SecIdentityCopyCertificate(_ identityRef: SecIdentity, _ certificateRef: UnsafeMutablePointer<SecCertificate?>) -> OSStatus {
    _ = certificateRef
    return errSecUnimplemented
}

public func SecIdentityCopyPrivateKey(_ identityRef: SecIdentity, _ privateKeyRef: UnsafeMutablePointer<SecKey?>) -> OSStatus {
    _ = privateKeyRef
    return errSecUnimplemented
}

public func SecIdentityCreate(_ allocator: CFAllocator?, _ certificate: SecCertificate, _ privateKey: SecKey) -> SecIdentity? {
    _ = certificate
    _ = privateKey
    return SecIdentity(certificate: certificate, privateKey: privateKey)
}

public func SecIdentityGetTypeID() -> CFTypeID {
    return _secTypeIdentity()
}

public func SecKeyCopyAttributes(_ key: SecKey) -> CFDictionary? {
    return nil
}

public func SecKeyCopyExternalRepresentation(_ key: SecKey, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
    _ = error
    return nil
}

public func SecKeyCopyKeyExchangeResult(_ privateKey: SecKey, _ algorithm: SecKeyAlgorithm, _ publicKey: SecKey, _ parameters: CFDictionary, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
    _ = algorithm
    _ = publicKey
    _ = parameters
    _ = error
    return nil
}

public func SecKeyCopyPublicKey(_ key: SecKey) -> SecKey? {
    return nil
}

public func SecKeyCreateDecryptedData(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ ciphertext: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
    _ = algorithm
    _ = ciphertext
    _ = error
    return nil
}

public func SecKeyCreateEncryptedData(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ plaintext: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
    _ = algorithm
    _ = plaintext
    _ = error
    return nil
}

public func SecKeyCreateRandomKey(_ parameters: CFDictionary, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey? {
    _ = error
    return nil
}

public func SecKeyCreateSignature(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ dataToSign: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
    _ = algorithm
    _ = dataToSign
    _ = error
    return nil
}

public func SecKeyCreateWithData(_ keyData: CFData, _ attributes: CFDictionary, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey? {
    _ = attributes
    _ = error
    return nil
}

public func SecKeyDecrypt(_ key: SecKey, _ padding: SecPadding, _ cipherText: UnsafePointer<UInt8>, _ cipherTextLen: Int, _ plainText: UnsafeMutablePointer<UInt8>, _ plainTextLen: UnsafeMutablePointer<Int>) -> OSStatus {
    _ = padding
    _ = cipherText
    _ = cipherTextLen
    _ = plainText
    _ = plainTextLen
    return errSecUnimplemented
}

public func SecKeyEncrypt(_ key: SecKey, _ padding: SecPadding, _ plainText: UnsafePointer<UInt8>, _ plainTextLen: Int, _ cipherText: UnsafeMutablePointer<UInt8>, _ cipherTextLen: UnsafeMutablePointer<Int>) -> OSStatus {
    _ = padding
    _ = plainText
    _ = plainTextLen
    _ = cipherText
    _ = cipherTextLen
    return errSecUnimplemented
}

public func SecKeyGeneratePair(_ parameters: CFDictionary, _ publicKey: UnsafeMutablePointer<SecKey?>?, _ privateKey: UnsafeMutablePointer<SecKey?>?) -> OSStatus {
    _ = publicKey
    _ = privateKey
    return errSecUnimplemented
}

public func SecKeyGetBlockSize(_ key: SecKey) -> Int {
    return 0
}

public func SecKeyGetTypeID() -> CFTypeID {
    return _secTypeKey()
}

public func SecKeyIsAlgorithmSupported(_ key: SecKey, _ operation: SecKeyOperationType, _ algorithm: SecKeyAlgorithm) -> Bool {
    _ = operation
    _ = algorithm
    return false
}

public func SecKeyRawSign(_ key: SecKey, _ padding: SecPadding, _ dataToSign: UnsafePointer<UInt8>, _ dataToSignLen: Int, _ sig: UnsafeMutablePointer<UInt8>, _ sigLen: UnsafeMutablePointer<Int>) -> OSStatus {
    _ = padding
    _ = dataToSign
    _ = dataToSignLen
    _ = sig
    _ = sigLen
    return errSecUnimplemented
}

public func SecKeyRawVerify(_ key: SecKey, _ padding: SecPadding, _ signedData: UnsafePointer<UInt8>, _ signedDataLen: Int, _ sig: UnsafePointer<UInt8>, _ sigLen: Int) -> OSStatus {
    _ = padding
    _ = signedData
    _ = signedDataLen
    _ = sig
    _ = sigLen
    return errSecUnimplemented
}

public func SecKeyVerifySignature(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ signedData: CFData, _ signature: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Bool {
    _ = algorithm
    _ = signedData
    _ = signature
    _ = error
    return false
}

public func SecPKCS12Import(_ pkcs12_data: CFData, _ options: CFDictionary, _ items: UnsafeMutablePointer<CFArray?>) -> OSStatus {
    _ = options
    _ = items
    return errSecUnimplemented
}

public func SecPolicyCopyProperties(_ policyRef: SecPolicy) -> CFDictionary? {
    return nil
}

public func SecPolicyCreateBasicX509() -> SecPolicy {
    return SecPolicy(identifier: "basic")
}

public func SecPolicyCreateRevocation(_ revocationFlags: CFOptionFlags) -> SecPolicy? {
    return nil
}

public func SecPolicyCreateSSL(_ server: Bool, _ hostname: CFString?) -> SecPolicy {
    _ = server
    _ = hostname
    return SecPolicy(identifier: "ssl", properties: hostname.map { ["name": $0] } ?? [:])
}

public func SecPolicyCreateWithProperties(_ policyIdentifier: CFTypeRef, _ properties: CFDictionary?) -> SecPolicy? {
    _ = properties
    return nil
}

public func SecPolicyGetTypeID() -> CFTypeID {
    return _secTypePolicy()
}

public func SecRequestSharedWebCredential(_ fqdn: CFString?, _ account: CFString?, _ completionHandler: @escaping (CFArray?, CFError?) -> Void) {
    _ = account
    _ = completionHandler
    completionHandler(nil, _securityFailClosedError())
}

public func SecTrustCopyCertificateChain(_ trust: SecTrust) -> CFArray? {
    return nil
}

public func SecTrustCopyCustomAnchorCertificates(_ trust: SecTrust, _ anchors: UnsafeMutablePointer<CFArray?>) -> OSStatus {
    _ = anchors
    return errSecUnimplemented
}

public func SecTrustCopyExceptions(_ trust: SecTrust) -> CFData? {
    return nil
}

public func SecTrustCopyKey(_ trust: SecTrust) -> SecKey? {
    return nil
}

public func SecTrustCopyPolicies(_ trust: SecTrust, _ policies: UnsafeMutablePointer<CFArray?>) -> OSStatus {
    _ = policies
    return errSecUnimplemented
}

public func SecTrustCopyProperties(_ trust: SecTrust) -> CFArray? {
    return nil
}

public func SecTrustCopyPublicKey(_ trust: SecTrust) -> SecKey? {
    return nil
}

public func SecTrustCopyResult(_ trust: SecTrust) -> CFDictionary? {
    return nil
}

public func SecTrustCreateWithCertificates(_ certificates: CFTypeRef, _ policies: CFTypeRef?, _ trust: UnsafeMutablePointer<SecTrust?>) -> OSStatus {
    _ = certificates
    _ = policies
    let wrapped = SecTrust(certificates: [], policies: [])
    trust.pointee = wrapped
    return errSecSuccess
}

public func SecTrustEvaluate(_ trust: SecTrust, _ result: UnsafeMutablePointer<SecTrustResultType>) -> OSStatus {
    _ = result
    result.pointee = .invalid
    return errSecUnimplemented
}

public func SecTrustEvaluateWithError(_ trust: SecTrust, _ error: UnsafeMutablePointer<CFError?>?) -> Bool {
    _ = error
    return false
}

public func SecTrustGetCertificateAtIndex(_ trust: SecTrust, _ ix: CFIndex) -> SecCertificate? {
    _ = ix
    return nil
}

public func SecTrustGetCertificateCount(_ trust: SecTrust) -> CFIndex {
    return 0
}

public func SecTrustGetNetworkFetchAllowed(_ trust: SecTrust, _ allowFetch: UnsafeMutablePointer<DarwinBoolean>) -> OSStatus {
    _ = allowFetch
    allowFetch.pointee = DarwinBoolean(false)
    return errSecUnimplemented
}

public func SecTrustGetTrustResult(_ trust: SecTrust, _ result: UnsafeMutablePointer<SecTrustResultType>) -> OSStatus {
    _ = result
    result.pointee = .invalid
    return errSecUnimplemented
}

public func SecTrustGetTypeID() -> CFTypeID {
    return _secTypeTrust()
}

public func SecTrustGetVerifyTime(_ trust: SecTrust) -> CFAbsoluteTime {
    return 0
}

public func SecTrustSetAnchorCertificates(_ trust: SecTrust, _ anchorCertificates: CFArray?) -> OSStatus {
    _ = anchorCertificates
    return errSecUnimplemented
}

public func SecTrustSetAnchorCertificatesOnly(_ trust: SecTrust, _ anchorCertificatesOnly: Bool) -> OSStatus {
    _ = anchorCertificatesOnly
    return errSecUnimplemented
}

public func SecTrustSetExceptions(_ trust: SecTrust, _ exceptions: CFData?) -> Bool {
    _ = exceptions
    return false
}

public func SecTrustSetNetworkFetchAllowed(_ trust: SecTrust, _ allowFetch: Bool) -> OSStatus {
    _ = allowFetch
    return errSecUnimplemented
}

public func SecTrustSetOCSPResponse(_ trust: SecTrust, _ responseData: CFTypeRef?) -> OSStatus {
    _ = responseData
    return errSecUnimplemented
}

public func SecTrustSetPolicies(_ trust: SecTrust, _ policies: CFTypeRef) -> OSStatus {
    _ = policies
    return errSecUnimplemented
}

public func SecTrustSetSignedCertificateTimestamps(_ trust: SecTrust, _ sctArray: CFArray?) -> OSStatus {
    _ = sctArray
    return errSecUnimplemented
}

public func SecTrustSetVerifyDate(_ trust: SecTrust, _ verifyDate: CFDate) -> OSStatus {
    _ = verifyDate
    return errSecUnimplemented
}

public func sec_certificate_copy_ref(_ certificate: sec_certificate_t) -> Unmanaged<SecCertificate> {
    return (certificate as? _OSSecCertificate).map { Unmanaged.passUnretained($0.certificate) } ?? Unmanaged.passUnretained(SecCertificate(data: Data()))
}

public func sec_certificate_create(_ certificate: SecCertificate) -> sec_certificate_t? {
    return _OSSecCertificate(certificate: certificate)
}

public func sec_identity_access_certificates(_ identity: sec_identity_t, _ handler: @escaping (sec_certificate_t) -> Void) -> Bool {
    _ = handler
    return false
}

public func sec_identity_copy_ref(_ identity: sec_identity_t) -> Unmanaged<SecIdentity>? {
    return (identity as? _OSSecIdentity).map { Unmanaged.passUnretained($0.identity) }
}

public func sec_identity_create(_ identity: SecIdentity) -> sec_identity_t? {
    return _OSSecIdentity(identity: identity)
}

public func sec_identity_create_with_certificates(_ identity: SecIdentity, _ certificates: CFArray) -> sec_identity_t? {
    _ = certificates
    return nil
}

public func sec_protocol_metadata_access_peer_certificate_chain(_ metadata: sec_protocol_metadata_t, _ handler: @escaping (sec_certificate_t) -> Void) -> Bool {
    _ = handler
    return false
}

public func sec_protocol_metadata_access_supported_signature_algorithms(_ metadata: sec_protocol_metadata_t, _ handler: @escaping (UInt16) -> Void) -> Bool {
    _ = handler
    return false
}

public func sec_protocol_metadata_challenge_parameters_are_equal(_ metadataA: sec_protocol_metadata_t, _ metadataB: sec_protocol_metadata_t) -> Bool {
    _ = metadataB
    return metadataA === metadataB
}

public func sec_protocol_metadata_copy_negotiated_protocol(_ metadata: sec_protocol_metadata_t) -> UnsafePointer<CChar>? {
    return nil
}

public func sec_protocol_metadata_copy_server_name(_ metadata: sec_protocol_metadata_t) -> UnsafePointer<CChar>? {
    return nil
}

public func sec_protocol_metadata_get_early_data_accepted(_ metadata: sec_protocol_metadata_t) -> Bool {
    return false
}

public func sec_protocol_metadata_get_negotiated_ciphersuite(_ metadata: sec_protocol_metadata_t) -> SSLCipherSuite {
    return 0
}

public func sec_protocol_metadata_get_negotiated_protocol(_ metadata: sec_protocol_metadata_t) -> UnsafePointer<CChar>? {
    return nil
}

public func sec_protocol_metadata_get_negotiated_protocol_version(_ metadata: sec_protocol_metadata_t) -> SSLProtocol {
    return .sslProtocolUnknown
}

public func sec_protocol_metadata_get_negotiated_tls_ciphersuite(_ metadata: sec_protocol_metadata_t) -> tls_ciphersuite_t {
    return .RSA_WITH_AES_128_GCM_SHA256
}

public func sec_protocol_metadata_get_negotiated_tls_protocol_version(_ metadata: sec_protocol_metadata_t) -> tls_protocol_version_t {
    return .TLSv12
}

public func sec_protocol_metadata_get_server_name(_ metadata: sec_protocol_metadata_t) -> UnsafePointer<CChar>? {
    return nil
}

public func sec_protocol_metadata_peers_are_equal(_ metadataA: sec_protocol_metadata_t, _ metadataB: sec_protocol_metadata_t) -> Bool {
    _ = metadataB
    return metadataA === metadataB
}

public func sec_protocol_options_add_tls_application_protocol(_ options: sec_protocol_options_t, _ application_protocol: UnsafePointer<CChar>) {
    _ = application_protocol
}

public func sec_protocol_options_add_tls_ciphersuite(_ options: sec_protocol_options_t, _ ciphersuite: SSLCipherSuite) {
    _ = ciphersuite
}

public func sec_protocol_options_add_tls_ciphersuite_group(_ options: sec_protocol_options_t, _ group: SSLCiphersuiteGroup) {
    _ = group
}

public func sec_protocol_options_append_tls_ciphersuite(_ options: sec_protocol_options_t, _ ciphersuite: tls_ciphersuite_t) {
    _ = ciphersuite
}

public func sec_protocol_options_append_tls_ciphersuite_group(_ options: sec_protocol_options_t, _ group: tls_ciphersuite_group_t) {
    _ = group
}

public func sec_protocol_options_are_equal(_ optionsA: sec_protocol_options_t, _ optionsB: sec_protocol_options_t) -> Bool {
    _ = optionsB
    return optionsA === optionsB
}

public func sec_protocol_options_get_default_max_dtls_protocol_version() -> tls_protocol_version_t {
    return .DTLSv12
}

public func sec_protocol_options_get_default_max_tls_protocol_version() -> tls_protocol_version_t {
    return .TLSv13
}

public func sec_protocol_options_get_default_min_dtls_protocol_version() -> tls_protocol_version_t {
    return .DTLSv12
}

public func sec_protocol_options_get_default_min_tls_protocol_version() -> tls_protocol_version_t {
    return .TLSv12
}

public func sec_protocol_options_set_local_identity(_ options: sec_protocol_options_t, _ identity: sec_identity_t) {
    _ = identity
}

public func sec_protocol_options_set_max_tls_protocol_version(_ options: sec_protocol_options_t, _ version: tls_protocol_version_t) {
    _ = version
}

public func sec_protocol_options_set_min_tls_protocol_version(_ options: sec_protocol_options_t, _ version: tls_protocol_version_t) {
    _ = version
}

public func sec_protocol_options_set_peer_authentication_required(_ options: sec_protocol_options_t, _ peer_authentication_required: Bool) {
    _ = peer_authentication_required
}

public func sec_protocol_options_set_tls_false_start_enabled(_ options: sec_protocol_options_t, _ false_start_enabled: Bool) {
    _ = false_start_enabled
}

public func sec_protocol_options_set_tls_is_fallback_attempt(_ options: sec_protocol_options_t, _ is_fallback_attempt: Bool) {
    _ = is_fallback_attempt
}

public func sec_protocol_options_set_tls_max_version(_ options: sec_protocol_options_t, _ version: SSLProtocol) {
    _ = version
}

public func sec_protocol_options_set_tls_min_version(_ options: sec_protocol_options_t, _ version: SSLProtocol) {
    _ = version
}

public func sec_protocol_options_set_tls_ocsp_enabled(_ options: sec_protocol_options_t, _ ocsp_enabled: Bool) {
    _ = ocsp_enabled
}

public func sec_protocol_options_set_tls_renegotiation_enabled(_ options: sec_protocol_options_t, _ renegotiation_enabled: Bool) {
    _ = renegotiation_enabled
}

public func sec_protocol_options_set_tls_resumption_enabled(_ options: sec_protocol_options_t, _ resumption_enabled: Bool) {
    _ = resumption_enabled
}

public func sec_protocol_options_set_tls_sct_enabled(_ options: sec_protocol_options_t, _ sct_enabled: Bool) {
    _ = sct_enabled
}

public func sec_protocol_options_set_tls_server_name(_ options: sec_protocol_options_t, _ server_name: UnsafePointer<CChar>) {
    _ = server_name
}

public func sec_protocol_options_set_tls_tickets_enabled(_ options: sec_protocol_options_t, _ tickets_enabled: Bool) {
    _ = tickets_enabled
}

public func sec_release(_ obj: UnsafeMutableRawPointer!) {
    return
}

public func sec_retain(_ obj: UnsafeMutableRawPointer!) -> UnsafeMutableRawPointer! {
    return obj
}

public func sec_trust_copy_ref(_ trust: sec_trust_t) -> Unmanaged<SecTrust> {
    return (trust as? _OSSecTrust).map { Unmanaged.passUnretained($0.trust) } ?? Unmanaged.passUnretained(SecTrust(certificates: [], policies: []))
}

public func sec_trust_create(_ trust: SecTrust) -> sec_trust_t? {
    return _OSSecTrust(trust: trust)
}
