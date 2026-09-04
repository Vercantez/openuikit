public func CCRandomGenerateBytes(_ bytes: UnsafeMutableRawPointer!, _ count: Int) -> CCRNGStatus {
    guard let bytes, count >= 0 else {
        return CCRNGStatus(kCCParamError)
    }
    if count == 0 {
        return CCRNGStatus(kCCSuccess)
    }
    var generator = SystemRandomNumberGenerator()
    var output = [UInt8](repeating: 0, count: count)
    for index in 0..<count {
        output[index] = UInt8.random(in: .min ... .max, using: &generator)
    }
    _ccWrite(output, to: bytes)
    return CCRNGStatus(kCCSuccess)
}
