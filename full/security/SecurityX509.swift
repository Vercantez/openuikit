import Foundation

struct _SecParsedCert {
    var der: [UInt8]
    var tbs: [UInt8]
    var serial: [UInt8]
    var issuerDER: [UInt8]
    var subjectDER: [UInt8]
    var issuerCN: String?
    var subjectCN: String?
    var emails: [String]
    var dnsNames: [String]
    var notBefore: Date
    var notAfter: Date
    var spki: [UInt8]
    var signatureAlgorithm: [UInt8]
    var signature: [UInt8]
    var publicKey: _SecStoredKey?
}

enum _SecStoredKey {
    case rsa(_SecRSAKey)
    case ec(_SecECKey)

    var isPrivate: Bool {
        switch self {
        case .rsa(let key): return key.isPrivate
        case .ec(let key): return key.isPrivate
        }
    }

    var keyType: String {
        switch self {
        case .rsa: return kSecAttrKeyTypeRSA
        case .ec: return kSecAttrKeyTypeECSECPrimeRandom
        }
    }

    var keySize: Int {
        switch self {
        case .rsa(let key): return key.n.bitLength
        case .ec(let key): return key.curve.size * 8
        }
    }

    func publicOnly() -> _SecStoredKey {
        switch self {
        case .rsa(let key): return .rsa(key.publicOnly())
        case .ec(let key): return .ec(key.publicOnly())
        }
    }
}

func _secParseCertificate(_ der: [UInt8]) -> _SecParsedCert? {
    guard let root = try? _secDERParse(der), let items = root.children, items.count >= 3 else {
        return nil
    }
    guard case .sequence(let tbsItems) = items[0] else { return nil }
    let tbsBytes = _secDERFirstChildTLV(der) ?? _secDEREncode(items[0])
    var index = 0
    if case .context(let tag, _, _) = tbsItems[index], tag == 0 { index += 1 }
    guard index < tbsItems.count, let serial = tbsItems[index].integerBytes else { return nil }
    index += 1
    guard index + 4 < tbsItems.count else { return nil }
    let sigAlg = tbsItems[index]
    index += 1
    let issuer = tbsItems[index]
    index += 1
    let validity = tbsItems[index]
    index += 1
    let subject = tbsItems[index]
    index += 1
    let spki = tbsItems[index]
    index += 1
    var extensions: [_SecDER] = []
    if index < tbsItems.count, case .context(let tag, _, let body) = tbsItems[index], tag == 3 {
        if let seq = body.first?.children { extensions = seq }
    }
    guard let validityItems = validity.children, validityItems.count == 2,
          let notBefore = _secParseTime(validityItems[0]),
          let notAfter = _secParseTime(validityItems[1]) else { return nil }
    var emails: [String] = []
    var dnsNames: [String] = []
    _secCollectDirectoryNames(subject, emails: &emails, cn: nil)
    var subjectCN: String?
    var issuerCN: String?
    _secCollectDirectoryNames(subject, emails: &emails, cn: &subjectCN)
    _secCollectDirectoryNames(issuer, emails: &emails, cn: &issuerCN)
    for ext in extensions {
        guard let extItems = ext.children, extItems.count >= 2,
              let oid = extItems[0].oid else { continue }
        let value = extItems.last?.octet ?? []
        if oid == _oidSubjectAltName, let san = try? _secDERParse(value), let names = san.children {
            for name in names {
                if case .contextPrimitive(let tag, let bytes) = name {
                    if tag == 2, let text = String(bytes: bytes, encoding: .ascii) {
                        dnsNames.append(text)
                    } else if tag == 1, let text = String(bytes: bytes, encoding: .ascii) {
                        emails.append(text)
                    }
                }
            }
        }
    }
    var signatureBytes: [UInt8] = []
    if case .bitString(_, let bytes) = items[2] { signatureBytes = bytes }
    let publicKey = _secParseSPKI(spki)
    return _SecParsedCert(
        der: der, tbs: tbsBytes, serial: _secStripLeadingZero(serial),
        issuerDER: _secDEREncode(issuer), subjectDER: _secDEREncode(subject),
        issuerCN: issuerCN, subjectCN: subjectCN, emails: emails, dnsNames: dnsNames,
        notBefore: notBefore, notAfter: notAfter, spki: _secDEREncode(spki),
        signatureAlgorithm: _secDEREncode(sigAlg), signature: signatureBytes,
        publicKey: publicKey
    )
}

func _secStripLeadingZero(_ bytes: [UInt8]) -> [UInt8] {
    var value = bytes
    while value.count > 1 && value[0] == 0 { value.removeFirst() }
    return value
}

func _secParseTime(_ node: _SecDER) -> Date? {
    let text: String
    switch node {
    case .utcTime(let value): text = value
    case .generalizedTime(let value): text = value
    default: return nil
    }
    var digits: [Character] = []
    for ch in text {
        if ch >= "0" && ch <= "9" { digits.append(ch) }
    }
    func take(_ count: Int, _ offset: inout Int) -> Int {
        guard offset + count <= digits.count else { return 0 }
        let slice = digits[offset..<(offset + count)]
        offset += count
        return Int(String(slice)) ?? 0
    }
    var offset = 0
    let year: Int
    if case .utcTime = node {
        let yy = take(2, &offset)
        year = yy >= 50 ? 1900 + yy : 2000 + yy
    } else {
        year = take(4, &offset)
    }
    let month = take(2, &offset)
    let day = take(2, &offset)
    let hour = take(2, &offset)
    let minute = take(2, &offset)
    let second = take(2, &offset)
    var components = DateComponents()
    components.calendar = Calendar(identifier: .gregorian)
    components.timeZone = TimeZone(secondsFromGMT: 0)
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    return components.date
}

func _secCollectDirectoryNames(_ name: _SecDER, emails: inout [String], cn: inout String?) {
    guard let rdns = name.children else { return }
    for rdn in rdns {
        guard let atvs = rdn.children else { continue }
        for atv in atvs {
            guard let items = atv.children, items.count >= 2, let oid = items[0].oid else { continue }
            let value: String
            switch items[1] {
            case .utf8String(let text), .printableString(let text), .ia5String(let text):
                value = text
            default:
                continue
            }
            if oid == _oidCommonName { cn = value }
            if oid == _oidEmailAddress { emails.append(value) }
        }
    }
}

func _secCollectDirectoryNames(_ name: _SecDER, emails: inout [String], cn: String?) {
    var ignored = cn
    _secCollectDirectoryNames(name, emails: &emails, cn: &ignored)
}

func _secParseSPKI(_ spki: _SecDER) -> _SecStoredKey? {
    guard let items = spki.children, items.count >= 2 else { return nil }
    guard let alg = items[0].children, let oid = alg.first?.oid else { return nil }
    guard case .bitString(_, let bits) = items[1] else { return nil }
    if oid == _oidRSAEncryption {
        if let key = _SecRSAKey.parsePKCS1(bits) { return .rsa(key) }
    }
    if oid == _oidECPublicKey {
        let curveOID = alg.count >= 2 ? alg[1].oid : nil
        let curve = curveOID.flatMap(_secCurve(forOID:)) ?? _secCurveP256()
        if let key = _SecECKey.parseX963(bits, curve: curve, wantPrivate: false) { return .ec(key) }
    }
    return nil
}

func _secMatchHostname(_ host: String, cert: _SecParsedCert) -> Bool {
    let names = cert.dnsNames.isEmpty ? [cert.subjectCN].compactMap { $0 } : cert.dnsNames
    for name in names where _secRFC6125Match(host, pattern: name) { return true }
    return false
}

func _secRFC6125Match(_ host: String, pattern: String) -> Bool {
    let presented = host.lowercased()
    let reference = pattern.lowercased()
    if presented == reference { return true }
    if reference.hasPrefix("*.") {
        let suffix = String(reference.dropFirst(2))
        if suffix.isEmpty { return false }
        if presented == suffix { return false }
        guard let dot = presented.firstIndex(of: Character(".")) else { return false }
        let rest = String(presented[presented.index(after: dot)...])
        if rest != suffix { return false }
        let left = String(presented[..<dot])
        if left.isEmpty { return false }
        if left.firstIndex(of: Character(".")) != nil { return false }
        return true
    }
    return false
}

func _secVerifyCertSignature(signed: _SecParsedCert, issuerKey: _SecStoredKey) -> Bool {
    let alg = (try? _secDERParse(signed.signatureAlgorithm))?.children?.first?.oid ?? []
    switch issuerKey {
    case .rsa(let key):
        let digest: _SecDigest
        if alg == _oidSha256WithRSA { digest = .sha256 }
        else if alg == _oidSha1WithRSA { digest = .sha1 }
        else { digest = .sha256 }
        let digestInfo = digest.digestInfoPrefix + digest.hash(signed.tbs)
        return _secRSAPKCS1Verify(key: key, digestInfo: digestInfo, signature: signed.signature)
    case .ec(let key):
        let digest: _SecDigest
        if alg == _oidEcdsaWithSHA384 { digest = .sha384 }
        else if alg == _oidEcdsaWithSHA512 { digest = .sha512 }
        else { digest = .sha256 }
        return _secECDSAVerify(key: key, hash: digest.hash(signed.tbs), signature: signed.signature)
    }
}

// MARK: - PKCS#12 (unencrypted bags + optional MAC)

func _secPKCS12Import(_ data: [UInt8], password: String) -> (identity: (cert: _SecParsedCert, key: _SecStoredKey)?, certs: [_SecParsedCert])? {
    guard let root = try? _secDERParse(data), let items = root.children, items.count >= 2 else {
        return nil
    }
    guard case .sequence(let content) = items[1],
          let oid = content.first?.oid, oid == _oidPkcs7Data else { return nil }
    var authBytes: [UInt8] = []
    for node in content.dropFirst() {
        if case .context(_, _, let body) = node, let first = body.first {
            if case .octetString(let bytes) = first { authBytes = bytes }
            else if case .contextPrimitive(_, let bytes) = first { authBytes = bytes }
        }
        if case .octetString(let bytes) = node { authBytes = bytes }
    }
    if authBytes.isEmpty {
        if case .context(_, _, let body) = content.last, let first = body.first, case .octetString(let bytes) = first {
            authBytes = bytes
        }
    }
    guard !authBytes.isEmpty else { return nil }
    var certs: [_SecParsedCert] = []
    var keys: [_SecStoredKey] = []
    if let safe = try? _secDERParse(authBytes), let cis = safe.children {
        for ci in cis {
            _secPKCS12WalkContent(ci, certs: &certs, keys: &keys, password: password)
        }
    } else if let many = try? _secDERParseAll(authBytes) {
        for ci in many { _secPKCS12WalkContent(ci, certs: &certs, keys: &keys, password: password) }
    }
    var identity: (cert: _SecParsedCert, key: _SecStoredKey)?
    if let firstKey = keys.first {
        for cert in certs {
            if let pub = cert.publicKey, _secKeysMatch(pub, firstKey.publicOnly()) {
                identity = (cert, firstKey)
                break
            }
        }
        if identity == nil, let cert = certs.first {
            identity = (cert, firstKey)
        }
    }
    return (identity, certs)
}

func _secKeysMatch(_ left: _SecStoredKey, _ right: _SecStoredKey) -> Bool {
    switch (left, right) {
    case (.rsa(let a), .rsa(let b)): return a.n == b.n && a.e == b.e
    case (.ec(let a), .ec(let b)):
        return a.publicPoint.x == b.publicPoint.x && a.publicPoint.y == b.publicPoint.y
    default: return false
    }
}

func _secPKCS12WalkContent(_ ci: _SecDER, certs: inout [_SecParsedCert], keys: inout [_SecStoredKey], password: String) {
    guard let items = ci.children, let oid = items.first?.oid else { return }
    var payload: [UInt8] = []
    for node in items.dropFirst() {
        if case .context(_, _, let body) = node, let first = body.first, case .octetString(let bytes) = first {
            payload = bytes
        }
    }
    guard oid == _oidPkcs7Data, !payload.isEmpty else { return }
    guard let bagsRoot = try? _secDERParse(payload) else { return }
    let bags = bagsRoot.children ?? [bagsRoot]
    for bag in bags {
        guard let bagItems = bag.children, let bagOID = bagItems.first?.oid else { continue }
        var bagValue: _SecDER?
        for node in bagItems.dropFirst() {
            if case .context(_, _, let body) = node { bagValue = body.first }
        }
        guard let value = bagValue else { continue }
        if bagOID == _oidPkcs12CertBag {
            if let certItems = value.children, certItems.count >= 2,
               certItems[0].oid == _oidX509Certificate {
                var certBytes: [UInt8] = []
                if case .context(_, _, let body) = certItems[1], let first = body.first, case .octetString(let bytes) = first {
                    certBytes = bytes
                } else if case .octetString(let bytes) = certItems[1] {
                    certBytes = bytes
                }
                if let parsed = _secParseCertificate(certBytes) { certs.append(parsed) }
            }
        } else if bagOID == _oidPkcs12KeyBag || bagOID == _oidPkcs12ShroudedKeyBag {
            if let key = _secParsePrivateKeyInfo(_secDEREncode(value), password: password) {
                keys.append(key)
            }
        }
    }
}

func _secParsePrivateKeyInfo(_ der: [UInt8], password: String) -> _SecStoredKey? {
    _ = password
    guard let root = try? _secDERParse(der) else { return nil }
    if let rsa = _SecRSAKey.parsePKCS1(der) { return .rsa(rsa) }
    guard let items = root.children, items.count >= 3 else {
        return _SecRSAKey.parsePKCS1(der).map { .rsa($0) }
    }
    let alg = items[1].children ?? []
    let oid = alg.first?.oid ?? []
    var keyBytes: [UInt8] = []
    if case .octetString(let bytes) = items[2] { keyBytes = bytes }
    if oid == _oidRSAEncryption || oid.isEmpty {
        if let rsa = _SecRSAKey.parsePKCS1(keyBytes) { return .rsa(rsa) }
        if let rsa = _SecRSAKey.parsePKCS1(der) { return .rsa(rsa) }
    }
    if oid == _oidECPublicKey {
        let curve = (alg.count >= 2 ? alg[1].oid : nil).flatMap(_secCurve(forOID:)) ?? _secCurveP256()
        if let inner = try? _secDERParse(keyBytes), let innerItems = inner.children {
            var dBytes: [UInt8] = []
            if innerItems.count >= 2, case .octetString(let bytes) = innerItems[1] { dBytes = bytes }
            if let key = _SecECKey.parseX963(dBytes, curve: curve, wantPrivate: true) { return .ec(key) }
        }
        if let key = _SecECKey.parseX963(keyBytes, curve: curve, wantPrivate: true) { return .ec(key) }
    }
    return nil
}
