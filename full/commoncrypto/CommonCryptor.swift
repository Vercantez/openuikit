private let _ccAESSbox: [UInt8] = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
]

private let _ccAESInvSbox: [UInt8] = {
    var inverse = [UInt8](repeating: 0, count: 256)
    for index in 0..<256 {
        inverse[Int(_ccAESSbox[index])] = UInt8(index)
    }
    return inverse
}()

private let _ccAESRcon: [UInt8] = [
    0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36,
]

private func _ccAESXt(_ value: UInt8) -> UInt8 {
    let shifted = UInt8(truncatingIfNeeded: Int(value) << 1)
    return (value & 0x80) == 0 ? shifted : (shifted ^ 0x1b)
}

private func _ccAESMul(_ value: UInt8, _ factor: UInt8) -> UInt8 {
    var result: UInt8 = 0
    var a = value
    var b = factor
    while b != 0 {
        if (b & 1) != 0 { result ^= a }
        a = _ccAESXt(a)
        b >>= 1
    }
    return result
}

func _ccAESExpandKey(_ key: [UInt8]) -> [[UInt8]] {
    let keyLength = key.count
    let rounds = keyLength == 16 ? 10 : (keyLength == 24 ? 12 : 14)
    let n = keyLength / 4
    var words = [[UInt8]](repeating: [0, 0, 0, 0], count: 4 * (rounds + 1))
    for index in 0..<n {
        words[index] = Array(key[(index * 4)..<(index * 4 + 4)])
    }
    for index in n..<(4 * (rounds + 1)) {
        var temp = words[index - 1]
        if index % n == 0 {
            temp = [temp[1], temp[2], temp[3], temp[0]].map { _ccAESSbox[Int($0)] }
            temp[0] ^= _ccAESRcon[index / n]
        } else if n > 6 && index % n == 4 {
            temp = temp.map { _ccAESSbox[Int($0)] }
        }
        words[index] = zip(words[index - n], temp).map { $0 ^ $1 }
    }
    var roundKeys: [[UInt8]] = []
    for round in 0...rounds {
        var block: [UInt8] = []
        for column in 0..<4 { block.append(contentsOf: words[round * 4 + column]) }
        roundKeys.append(block)
    }
    return roundKeys
}

func _ccAESEncryptBlock(_ input: [UInt8], roundKeys: [[UInt8]]) -> [UInt8] {
    var state = input
    func addRoundKey(_ round: Int) {
        for index in 0..<16 { state[index] ^= roundKeys[round][index] }
    }
    addRoundKey(0)
    for round in 1..<(roundKeys.count - 1) {
        for index in 0..<16 { state[index] = _ccAESSbox[Int(state[index])] }
        state = [
            state[0], state[5], state[10], state[15],
            state[4], state[9], state[14], state[3],
            state[8], state[13], state[2], state[7],
            state[12], state[1], state[6], state[11],
        ]
        var mixed = [UInt8](repeating: 0, count: 16)
        for column in 0..<4 {
            let i = column * 4
            let a = state[i], b = state[i + 1], c = state[i + 2], d = state[i + 3]
            mixed[i] = _ccAESXt(a) ^ _ccAESXt(b) ^ b ^ c ^ d
            mixed[i + 1] = a ^ _ccAESXt(b) ^ _ccAESXt(c) ^ c ^ d
            mixed[i + 2] = a ^ b ^ _ccAESXt(c) ^ _ccAESXt(d) ^ d
            mixed[i + 3] = _ccAESXt(a) ^ a ^ b ^ c ^ _ccAESXt(d)
        }
        state = mixed
        addRoundKey(round)
    }
    for index in 0..<16 { state[index] = _ccAESSbox[Int(state[index])] }
    state = [
        state[0], state[5], state[10], state[15],
        state[4], state[9], state[14], state[3],
        state[8], state[13], state[2], state[7],
        state[12], state[1], state[6], state[11],
    ]
    addRoundKey(roundKeys.count - 1)
    return state
}

func _ccAESDecryptBlock(_ input: [UInt8], roundKeys: [[UInt8]]) -> [UInt8] {
    var state = input
    func addRoundKey(_ round: Int) {
        for index in 0..<16 { state[index] ^= roundKeys[round][index] }
    }
    addRoundKey(roundKeys.count - 1)
    for round in stride(from: roundKeys.count - 2, through: 1, by: -1) {
        state = [
            state[0], state[13], state[10], state[7],
            state[4], state[1], state[14], state[11],
            state[8], state[5], state[2], state[15],
            state[12], state[9], state[6], state[3],
        ]
        for index in 0..<16 { state[index] = _ccAESInvSbox[Int(state[index])] }
        addRoundKey(round)
        var mixed = [UInt8](repeating: 0, count: 16)
        for column in 0..<4 {
            let i = column * 4
            let a = state[i], b = state[i + 1], c = state[i + 2], d = state[i + 3]
            mixed[i] = _ccAESMul(a, 14) ^ _ccAESMul(b, 11) ^ _ccAESMul(c, 13) ^ _ccAESMul(d, 9)
            mixed[i + 1] = _ccAESMul(a, 9) ^ _ccAESMul(b, 14) ^ _ccAESMul(c, 11) ^ _ccAESMul(d, 13)
            mixed[i + 2] = _ccAESMul(a, 13) ^ _ccAESMul(b, 9) ^ _ccAESMul(c, 14) ^ _ccAESMul(d, 11)
            mixed[i + 3] = _ccAESMul(a, 11) ^ _ccAESMul(b, 13) ^ _ccAESMul(c, 9) ^ _ccAESMul(d, 14)
        }
        state = mixed
    }
    state = [
        state[0], state[13], state[10], state[7],
        state[4], state[1], state[14], state[11],
        state[8], state[5], state[2], state[15],
        state[12], state[9], state[6], state[3],
    ]
    for index in 0..<16 { state[index] = _ccAESInvSbox[Int(state[index])] }
    addRoundKey(0)
    return state
}

private func _ccAESIncBE(_ counter: inout [UInt8]) {
    var index = counter.count - 1
    while index >= 0 {
        counter[index] &+= 1
        if counter[index] != 0 { return }
        index -= 1
    }
}

final class _CCCryptorBox {
    var op: CCOperation
    var alg: CCAlgorithm
    var mode: CCMode
    var padding: Bool
    var roundKeys: [[UInt8]]
    var iv: [UInt8]
    var remainder: [UInt8] = []
    var finalized = false

    init(
        op: CCOperation,
        alg: CCAlgorithm,
        mode: CCMode,
        padding: Bool,
        key: [UInt8],
        iv: [UInt8]
    ) {
        self.op = op
        self.alg = alg
        self.mode = mode
        self.padding = padding
        self.roundKeys = _ccAESExpandKey(key)
        self.iv = iv.isEmpty ? [UInt8](repeating: 0, count: 16) : iv
        if self.iv.count < 16 {
            self.iv.append(contentsOf: [UInt8](repeating: 0, count: 16 - self.iv.count))
        }
        if self.iv.count > 16 {
            self.iv = Array(self.iv.prefix(16))
        }
    }
}

private func _ccCryptorFrom(_ cryptorRef: CCCryptorRef?) -> _CCCryptorBox? {
    guard let cryptorRef else { return nil }
    return Unmanaged<_CCCryptorBox>.fromOpaque(UnsafeRawPointer(cryptorRef)).takeUnretainedValue()
}

private func _ccMakeCryptorRef(_ box: _CCCryptorBox) -> CCCryptorRef {
    CCCryptorRef(Unmanaged.passRetained(box).toOpaque())
}

func _ccAESKeyValid(_ keyLength: Int) -> Bool {
    keyLength == kCCKeySizeAES128 || keyLength == kCCKeySizeAES192 || keyLength == kCCKeySizeAES256
}

private func _ccCreateCryptor(
    op: CCOperation,
    alg: CCAlgorithm,
    mode: CCMode,
    padding: Bool,
    key: UnsafeRawPointer?,
    keyLength: Int,
    iv: UnsafeRawPointer?
) -> (CCCryptorStatus, CCCryptorRef?) {
    guard Int(alg) == kCCAlgorithmAES || Int(alg) == kCCAlgorithmAES128 else {
        return (CCCryptorStatus(kCCUnimplemented), nil)
    }
    guard Int(op) == kCCEncrypt || Int(op) == kCCDecrypt else {
        return (CCCryptorStatus(kCCParamError), nil)
    }
    switch Int(mode) {
    case kCCModeECB, kCCModeCBC, kCCModeCTR:
        break
    default:
        return (CCCryptorStatus(kCCUnimplemented), nil)
    }
    guard _ccAESKeyValid(keyLength), let key else {
        return (CCCryptorStatus(kCCKeySizeError), nil)
    }
    let keyBytes = _ccCopy(key, keyLength)
    let ivBytes: [UInt8]
    if Int(mode) == kCCModeECB {
        ivBytes = [UInt8](repeating: 0, count: 16)
    } else {
        ivBytes = iv == nil ? [UInt8](repeating: 0, count: 16) : _ccCopy(iv, 16)
    }
    let box = _CCCryptorBox(
        op: op, alg: alg, mode: mode, padding: padding, key: keyBytes, iv: ivBytes
    )
    return (CCCryptorStatus(kCCSuccess), _ccMakeCryptorRef(box))
}

private func _ccProcessBlocks(_ box: _CCCryptorBox, _ data: [UInt8], final: Bool) -> ([UInt8], CCCryptorStatus) {
    var input = box.remainder + data
    box.remainder = []
    var output: [UInt8] = []
    let encrypt = Int(box.op) == kCCEncrypt
    let block = 16

    if Int(box.mode) == kCCModeCTR {
        var counter = box.iv
        var offset = 0
        while offset < input.count {
            let keystream = _ccAESEncryptBlock(counter, roundKeys: box.roundKeys)
            _ccAESIncBE(&counter)
            let take = min(block, input.count - offset)
            for index in 0..<take {
                output.append(input[offset + index] ^ keystream[index])
            }
            offset += take
        }
        box.iv = counter
        return (output, CCCryptorStatus(kCCSuccess))
    }

    if !final {
        let leftover = input.count % block
        if leftover != 0 {
            box.remainder = Array(input.suffix(leftover))
            input = Array(input.dropLast(leftover))
        }
    } else if encrypt && box.padding {
        let pad = UInt8(block - (input.count % block))
        input.append(contentsOf: [UInt8](repeating: pad, count: Int(pad)))
    } else if !encrypt && box.padding {
        if input.count == 0 || (input.count % block) != 0 {
            return ([], CCCryptorStatus(kCCAlignmentError))
        }
    } else if (input.count % block) != 0 {
        return ([], CCCryptorStatus(kCCAlignmentError))
    }

    var chain = box.iv
    var offset = 0
    while offset < input.count {
        var blockBytes = Array(input[offset..<(offset + block)])
        let plain = blockBytes
        if Int(box.mode) == kCCModeCBC && encrypt {
            for index in 0..<block { blockBytes[index] ^= chain[index] }
        }
        let transformed = encrypt
            ? _ccAESEncryptBlock(blockBytes, roundKeys: box.roundKeys)
            : _ccAESDecryptBlock(blockBytes, roundKeys: box.roundKeys)
        var produced = transformed
        if Int(box.mode) == kCCModeCBC && !encrypt {
            for index in 0..<block { produced[index] ^= chain[index] }
            chain = plain
        } else if Int(box.mode) == kCCModeCBC && encrypt {
            chain = transformed
        }
        output.append(contentsOf: produced)
        offset += block
    }
    if Int(box.mode) == kCCModeCBC && encrypt {
        box.iv = chain
    } else if Int(box.mode) == kCCModeCBC && !encrypt {
        box.iv = chain
    }

    if final && !encrypt && box.padding {
        guard let pad = output.last, pad >= 1, pad <= 16, output.count >= Int(pad) else {
            return ([], CCCryptorStatus(kCCDecodeError))
        }
        let padCount = Int(pad)
        if output.suffix(padCount).contains(where: { $0 != pad }) {
            return ([], CCCryptorStatus(kCCDecodeError))
        }
        output.removeLast(padCount)
    }
    return (output, CCCryptorStatus(kCCSuccess))
}

public func CCCryptorCreate(
    _ op: CCOperation,
    _ alg: CCAlgorithm,
    _ options: CCOptions,
    _ key: UnsafeRawPointer!,
    _ keyLength: Int,
    _ iv: UnsafeRawPointer!,
    _ cryptorRef: UnsafeMutablePointer<CCCryptorRef?>!
) -> CCCryptorStatus {
    guard let cryptorRef else { return CCCryptorStatus(kCCParamError) }
    let mode: CCMode = ((Int(options) & kCCOptionECBMode) != 0)
        ? CCMode(kCCModeECB)
        : CCMode(kCCModeCBC)
    let padding = (Int(options) & kCCOptionPKCS7Padding) != 0
    let (status, ref) = _ccCreateCryptor(
        op: op, alg: alg, mode: mode, padding: padding, key: key, keyLength: keyLength, iv: iv
    )
    cryptorRef.pointee = ref
    return status
}

public func CCCryptorCreateFromData(
    _ op: CCOperation,
    _ alg: CCAlgorithm,
    _ options: CCOptions,
    _ key: UnsafeRawPointer!,
    _ keyLength: Int,
    _ iv: UnsafeRawPointer!,
    _ data: UnsafeRawPointer!,
    _ dataLength: Int,
    _ cryptorRef: UnsafeMutablePointer<CCCryptorRef?>!,
    _ dataUsed: UnsafeMutablePointer<Int>!
) -> CCCryptorStatus {
    if dataLength < 64 {
        return CCCryptorStatus(kCCBufferTooSmall)
    }
    let status = CCCryptorCreate(op, alg, options, key, keyLength, iv, cryptorRef)
    if status == kCCSuccess, let dataUsed {
        dataUsed.pointee = 64
    }
    _ = data
    return status
}

public func CCCryptorCreateWithMode(
    _ op: CCOperation,
    _ mode: CCMode,
    _ alg: CCAlgorithm,
    _ padding: CCPadding,
    _ iv: UnsafeRawPointer!,
    _ key: UnsafeRawPointer!,
    _ keyLength: Int,
    _ tweak: UnsafeRawPointer!,
    _ tweakLength: Int,
    _ numRounds: Int32,
    _ options: CCModeOptions,
    _ cryptorRef: UnsafeMutablePointer<CCCryptorRef?>!
) -> CCCryptorStatus {
    _ = options
    if tweakLength != 0 && tweak != nil {
        return CCCryptorStatus(kCCUnimplemented)
    }
    if numRounds != 0 {
        return CCCryptorStatus(kCCUnimplemented)
    }
    guard let cryptorRef else { return CCCryptorStatus(kCCParamError) }
    let usePadding = Int(padding) == ccPKCS7Padding
    let (status, ref) = _ccCreateCryptor(
        op: op, alg: alg, mode: mode, padding: usePadding, key: key, keyLength: keyLength, iv: iv
    )
    cryptorRef.pointee = ref
    return status
}

public func CCCryptorRelease(_ cryptorRef: CCCryptorRef!) -> CCCryptorStatus {
    guard let cryptorRef else { return CCCryptorStatus(kCCParamError) }
    Unmanaged<_CCCryptorBox>.fromOpaque(UnsafeRawPointer(cryptorRef)).release()
    return CCCryptorStatus(kCCSuccess)
}

public func CCCryptorReset(_ cryptorRef: CCCryptorRef!, _ iv: UnsafeRawPointer!) -> CCCryptorStatus {
    guard let box = _ccCryptorFrom(cryptorRef) else { return CCCryptorStatus(kCCParamError) }
    if Int(box.mode) != kCCModeCBC {
        return CCCryptorStatus(kCCUnimplemented)
    }
    box.iv = iv == nil ? [UInt8](repeating: 0, count: 16) : _ccCopy(iv, 16)
    if box.iv.count < 16 {
        box.iv.append(contentsOf: [UInt8](repeating: 0, count: 16 - box.iv.count))
    }
    box.remainder = []
    box.finalized = false
    return CCCryptorStatus(kCCSuccess)
}

public func CCCryptorGetOutputLength(
    _ cryptorRef: CCCryptorRef!,
    _ inputLength: Int,
    _ final: Bool
) -> Int {
    guard let box = _ccCryptorFrom(cryptorRef) else { return 0 }
    let total = box.remainder.count + inputLength
    if Int(box.mode) == kCCModeCTR {
        return total
    }
    if final && box.padding && Int(box.op) == kCCEncrypt {
        return ((total / 16) + 1) * 16
    }
    return (total / 16) * 16 + ((total % 16 == 0) ? 0 : 16)
}

public func CCCryptorUpdate(
    _ cryptorRef: CCCryptorRef!,
    _ dataIn: UnsafeRawPointer!,
    _ dataInLength: Int,
    _ dataOut: UnsafeMutableRawPointer!,
    _ dataOutAvailable: Int,
    _ dataOutMoved: UnsafeMutablePointer<Int>!
) -> CCCryptorStatus {
    guard let box = _ccCryptorFrom(cryptorRef), let dataOutMoved else {
        return CCCryptorStatus(kCCParamError)
    }
    if box.finalized { return CCCryptorStatus(kCCCallSequenceError) }
    let input = dataInLength == 0 ? [] : _ccCopy(dataIn, dataInLength)
    let (output, status) = _ccProcessBlocks(box, input, final: false)
    if status != kCCSuccess { return status }
    if output.count > dataOutAvailable { return CCCryptorStatus(kCCBufferTooSmall) }
    _ccWrite(output, to: dataOut)
    dataOutMoved.pointee = output.count
    return CCCryptorStatus(kCCSuccess)
}

public func CCCryptorFinal(
    _ cryptorRef: CCCryptorRef!,
    _ dataOut: UnsafeMutableRawPointer!,
    _ dataOutAvailable: Int,
    _ dataOutMoved: UnsafeMutablePointer<Int>!
) -> CCCryptorStatus {
    guard let box = _ccCryptorFrom(cryptorRef), let dataOutMoved else {
        return CCCryptorStatus(kCCParamError)
    }
    if box.finalized { return CCCryptorStatus(kCCCallSequenceError) }
    let (output, status) = _ccProcessBlocks(box, [], final: true)
    if status != kCCSuccess { return status }
    if output.count > dataOutAvailable { return CCCryptorStatus(kCCBufferTooSmall) }
    _ccWrite(output, to: dataOut)
    dataOutMoved.pointee = output.count
    box.finalized = true
    return CCCryptorStatus(kCCSuccess)
}

public func CCCrypt(
    _ op: CCOperation,
    _ alg: CCAlgorithm,
    _ options: CCOptions,
    _ key: UnsafeRawPointer!,
    _ keyLength: Int,
    _ iv: UnsafeRawPointer!,
    _ dataIn: UnsafeRawPointer!,
    _ dataInLength: Int,
    _ dataOut: UnsafeMutableRawPointer!,
    _ dataOutAvailable: Int,
    _ dataOutMoved: UnsafeMutablePointer<Int>!
) -> CCCryptorStatus {
    var cryptor: CCCryptorRef?
    let created = CCCryptorCreate(op, alg, options, key, keyLength, iv, &cryptor)
    if created != kCCSuccess { return created }
    defer { _ = CCCryptorRelease(cryptor) }
    var moved = 0
    let updated = CCCryptorUpdate(cryptor, dataIn, dataInLength, dataOut, dataOutAvailable, &moved)
    if updated != kCCSuccess { return updated }
    let remaining = dataOutAvailable - moved
    let finalOut = remaining == 0 ? dataOut : dataOut?.advanced(by: moved)
    var finalMoved = 0
    let finished = CCCryptorFinal(cryptor, finalOut, remaining, &finalMoved)
    if finished != kCCSuccess { return finished }
    dataOutMoved?.pointee = moved + finalMoved
    return CCCryptorStatus(kCCSuccess)
}
