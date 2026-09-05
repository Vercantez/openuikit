import Foundation

public struct GCGamepadSnapShotDataV100 {
    public var version: UInt16
    public var size: UInt16
    public var dpadX: Float
    public var dpadY: Float
    public var buttonA: Float
    public var buttonB: Float
    public var buttonX: Float
    public var buttonY: Float
    public var leftShoulder: Float
    public var rightShoulder: Float

    public init(
        version: UInt16,
        size: UInt16,
        dpadX: Float,
        dpadY: Float,
        buttonA: Float,
        buttonB: Float,
        buttonX: Float,
        buttonY: Float,
        leftShoulder: Float,
        rightShoulder: Float
    ) {
        self.version = version
        self.size = size
        self.dpadX = dpadX
        self.dpadY = dpadY
        self.buttonA = buttonA
        self.buttonB = buttonB
        self.buttonX = buttonX
        self.buttonY = buttonY
        self.leftShoulder = leftShoulder
        self.rightShoulder = rightShoulder
    }

    public init() {
        self.init(
            version: 0x100,
            size: 36,
            dpadX: 0, dpadY: 0,
            buttonA: 0, buttonB: 0, buttonX: 0, buttonY: 0,
            leftShoulder: 0, rightShoulder: 0
        )
    }
}

public struct GCExtendedGamepadSnapShotDataV100 {
    public var version: UInt16
    public var size: UInt16
    public var dpadX: Float
    public var dpadY: Float
    public var buttonA: Float
    public var buttonB: Float
    public var buttonX: Float
    public var buttonY: Float
    public var leftShoulder: Float
    public var rightShoulder: Float
    public var leftThumbstickX: Float
    public var leftThumbstickY: Float
    public var rightThumbstickX: Float
    public var rightThumbstickY: Float
    public var leftTrigger: Float
    public var rightTrigger: Float

    public init(
        version: UInt16,
        size: UInt16,
        dpadX: Float,
        dpadY: Float,
        buttonA: Float,
        buttonB: Float,
        buttonX: Float,
        buttonY: Float,
        leftShoulder: Float,
        rightShoulder: Float,
        leftThumbstickX: Float,
        leftThumbstickY: Float,
        rightThumbstickX: Float,
        rightThumbstickY: Float,
        leftTrigger: Float,
        rightTrigger: Float
    ) {
        self.version = version
        self.size = size
        self.dpadX = dpadX
        self.dpadY = dpadY
        self.buttonA = buttonA
        self.buttonB = buttonB
        self.buttonX = buttonX
        self.buttonY = buttonY
        self.leftShoulder = leftShoulder
        self.rightShoulder = rightShoulder
        self.leftThumbstickX = leftThumbstickX
        self.leftThumbstickY = leftThumbstickY
        self.rightThumbstickX = rightThumbstickX
        self.rightThumbstickY = rightThumbstickY
        self.leftTrigger = leftTrigger
        self.rightTrigger = rightTrigger
    }

    public init() {
        self.init(
            version: 0x100,
            size: 68,
            dpadX: 0, dpadY: 0,
            buttonA: 0, buttonB: 0, buttonX: 0, buttonY: 0,
            leftShoulder: 0, rightShoulder: 0,
            leftThumbstickX: 0, leftThumbstickY: 0,
            rightThumbstickX: 0, rightThumbstickY: 0,
            leftTrigger: 0, rightTrigger: 0
        )
    }
}

public struct GCExtendedGamepadSnapshotData {
    public var version: UInt16
    public var size: UInt16
    public var dpadX: Float
    public var dpadY: Float
    public var buttonA: Float
    public var buttonB: Float
    public var buttonX: Float
    public var buttonY: Float
    public var leftShoulder: Float
    public var rightShoulder: Float
    public var leftThumbstickX: Float
    public var leftThumbstickY: Float
    public var rightThumbstickX: Float
    public var rightThumbstickY: Float
    public var leftTrigger: Float
    public var rightTrigger: Float
    public var supportsClickableThumbsticks: ObjCBool
    public var leftThumbstickButton: ObjCBool
    public var rightThumbstickButton: ObjCBool

    public init(
        version: UInt16,
        size: UInt16,
        dpadX: Float,
        dpadY: Float,
        buttonA: Float,
        buttonB: Float,
        buttonX: Float,
        buttonY: Float,
        leftShoulder: Float,
        rightShoulder: Float,
        leftThumbstickX: Float,
        leftThumbstickY: Float,
        rightThumbstickX: Float,
        rightThumbstickY: Float,
        leftTrigger: Float,
        rightTrigger: Float,
        supportsClickableThumbsticks: ObjCBool,
        leftThumbstickButton: ObjCBool,
        rightThumbstickButton: ObjCBool
    ) {
        self.version = version
        self.size = size
        self.dpadX = dpadX
        self.dpadY = dpadY
        self.buttonA = buttonA
        self.buttonB = buttonB
        self.buttonX = buttonX
        self.buttonY = buttonY
        self.leftShoulder = leftShoulder
        self.rightShoulder = rightShoulder
        self.leftThumbstickX = leftThumbstickX
        self.leftThumbstickY = leftThumbstickY
        self.rightThumbstickX = rightThumbstickX
        self.rightThumbstickY = rightThumbstickY
        self.leftTrigger = leftTrigger
        self.rightTrigger = rightTrigger
        self.supportsClickableThumbsticks = supportsClickableThumbsticks
        self.leftThumbstickButton = leftThumbstickButton
        self.rightThumbstickButton = rightThumbstickButton
    }

    public init() {
        self.init(
            version: UInt16(GCCurrentExtendedGamepadSnapshotDataVersion.rawValue),
            size: 80,
            dpadX: 0, dpadY: 0,
            buttonA: 0, buttonB: 0, buttonX: 0, buttonY: 0,
            leftShoulder: 0, rightShoulder: 0,
            leftThumbstickX: 0, leftThumbstickY: 0,
            rightThumbstickX: 0, rightThumbstickY: 0,
            leftTrigger: 0, rightTrigger: 0,
            supportsClickableThumbsticks: false,
            leftThumbstickButton: false,
            rightThumbstickButton: false
        )
    }
}

public struct GCMicroGamepadSnapShotDataV100 {
    public var version: UInt16
    public var size: UInt16
    public var dpadX: Float
    public var dpadY: Float
    public var buttonA: Float
    public var buttonX: Float

    public init(
        version: UInt16,
        size: UInt16,
        dpadX: Float,
        dpadY: Float,
        buttonA: Float,
        buttonX: Float
    ) {
        self.version = version
        self.size = size
        self.dpadX = dpadX
        self.dpadY = dpadY
        self.buttonA = buttonA
        self.buttonX = buttonX
    }

    public init() {
        self.init(version: 0x100, size: 20, dpadX: 0, dpadY: 0, buttonA: 0, buttonX: 0)
    }
}

public struct GCMicroGamepadSnapshotData {
    public var version: UInt16
    public var size: UInt16
    public var dpadX: Float
    public var dpadY: Float
    public var buttonA: Float
    public var buttonX: Float

    public init(
        version: UInt16,
        size: UInt16,
        dpadX: Float,
        dpadY: Float,
        buttonA: Float,
        buttonX: Float
    ) {
        self.version = version
        self.size = size
        self.dpadX = dpadX
        self.dpadY = dpadY
        self.buttonA = buttonA
        self.buttonX = buttonX
    }

    public init() {
        self.init(
            version: UInt16(GCCurrentMicroGamepadSnapshotDataVersion.rawValue),
            size: 20,
            dpadX: 0, dpadY: 0, buttonA: 0, buttonX: 0
        )
    }
}

/// Portable little-endian snapshot encoding. Apple's on-wire layout is an oracle question.
private func _gcAppendUInt16(_ data: inout Data, _ value: UInt16) {
    var le = value.littleEndian
    withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
}

private func _gcAppendFloat(_ data: inout Data, _ value: Float) {
    var bits = value.bitPattern.littleEndian
    withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
}

private func _gcAppendBool(_ data: inout Data, _ value: ObjCBool) {
    data.append(value.boolValue ? 1 : 0)
}

private func _gcReadUInt16(_ data: Data, _ offset: inout Int) -> UInt16? {
    guard offset + 2 <= data.count else { return nil }
    let value = data[offset..<offset + 2].withUnsafeBytes { $0.loadUnaligned(as: UInt16.self) }.littleEndian
    offset += 2
    return value
}

private func _gcReadFloat(_ data: Data, _ offset: inout Int) -> Float? {
    guard offset + 4 <= data.count else { return nil }
    let bits = data[offset..<offset + 4].withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }.littleEndian
    offset += 4
    return Float(bitPattern: bits)
}

private func _gcReadBool(_ data: Data, _ offset: inout Int) -> ObjCBool? {
    guard offset < data.count else { return nil }
    let value = data[offset] != 0
    offset += 1
    return ObjCBool(value)
}

public func NSDataFromGCGamepadSnapShotDataV100(
    _ snapshotData: UnsafeMutablePointer<GCGamepadSnapShotDataV100>?
) -> Data? {
    guard let snapshot = snapshotData?.pointee else { return nil }
    var data = Data()
    _gcAppendUInt16(&data, snapshot.version)
    _gcAppendUInt16(&data, snapshot.size)
    _gcAppendFloat(&data, snapshot.dpadX)
    _gcAppendFloat(&data, snapshot.dpadY)
    _gcAppendFloat(&data, snapshot.buttonA)
    _gcAppendFloat(&data, snapshot.buttonB)
    _gcAppendFloat(&data, snapshot.buttonX)
    _gcAppendFloat(&data, snapshot.buttonY)
    _gcAppendFloat(&data, snapshot.leftShoulder)
    _gcAppendFloat(&data, snapshot.rightShoulder)
    return data
}

public func GCGamepadSnapShotDataV100FromNSData(
    _ snapshotData: UnsafeMutablePointer<GCGamepadSnapShotDataV100>?,
    _ data: Data?
) -> Bool {
    guard let snapshotData, let data else { return false }
    var offset = 0
    guard
        let version = _gcReadUInt16(data, &offset),
        let size = _gcReadUInt16(data, &offset),
        let dpadX = _gcReadFloat(data, &offset),
        let dpadY = _gcReadFloat(data, &offset),
        let buttonA = _gcReadFloat(data, &offset),
        let buttonB = _gcReadFloat(data, &offset),
        let buttonX = _gcReadFloat(data, &offset),
        let buttonY = _gcReadFloat(data, &offset),
        let leftShoulder = _gcReadFloat(data, &offset),
        let rightShoulder = _gcReadFloat(data, &offset)
    else { return false }
    snapshotData.pointee = GCGamepadSnapShotDataV100(
        version: version, size: size, dpadX: dpadX, dpadY: dpadY,
        buttonA: buttonA, buttonB: buttonB, buttonX: buttonX, buttonY: buttonY,
        leftShoulder: leftShoulder, rightShoulder: rightShoulder
    )
    return true
}

public func NSDataFromGCExtendedGamepadSnapShotDataV100(
    _ snapshotData: UnsafeMutablePointer<GCExtendedGamepadSnapShotDataV100>?
) -> Data? {
    guard let snapshot = snapshotData?.pointee else { return nil }
    var data = Data()
    _gcAppendUInt16(&data, snapshot.version)
    _gcAppendUInt16(&data, snapshot.size)
    for value in [
        snapshot.dpadX, snapshot.dpadY, snapshot.buttonA, snapshot.buttonB,
        snapshot.buttonX, snapshot.buttonY, snapshot.leftShoulder, snapshot.rightShoulder,
        snapshot.leftThumbstickX, snapshot.leftThumbstickY, snapshot.rightThumbstickX,
        snapshot.rightThumbstickY, snapshot.leftTrigger, snapshot.rightTrigger
    ] {
        _gcAppendFloat(&data, value)
    }
    return data
}

public func GCExtendedGamepadSnapShotDataV100FromNSData(
    _ snapshotData: UnsafeMutablePointer<GCExtendedGamepadSnapShotDataV100>?,
    _ data: Data?
) -> Bool {
    guard let snapshotData, let data else { return false }
    var offset = 0
    guard
        let version = _gcReadUInt16(data, &offset),
        let size = _gcReadUInt16(data, &offset)
    else { return false }
    var floats: [Float] = []
    for _ in 0..<14 {
        guard let value = _gcReadFloat(data, &offset) else { return false }
        floats.append(value)
    }
    snapshotData.pointee = GCExtendedGamepadSnapShotDataV100(
        version: version, size: size,
        dpadX: floats[0], dpadY: floats[1],
        buttonA: floats[2], buttonB: floats[3], buttonX: floats[4], buttonY: floats[5],
        leftShoulder: floats[6], rightShoulder: floats[7],
        leftThumbstickX: floats[8], leftThumbstickY: floats[9],
        rightThumbstickX: floats[10], rightThumbstickY: floats[11],
        leftTrigger: floats[12], rightTrigger: floats[13]
    )
    return true
}

public func NSDataFromGCExtendedGamepadSnapshotData(
    _ snapshotData: UnsafeMutablePointer<GCExtendedGamepadSnapshotData>?
) -> Data? {
    guard let snapshot = snapshotData?.pointee else { return nil }
    var data = Data()
    _gcAppendUInt16(&data, snapshot.version)
    _gcAppendUInt16(&data, snapshot.size)
    for value in [
        snapshot.dpadX, snapshot.dpadY, snapshot.buttonA, snapshot.buttonB,
        snapshot.buttonX, snapshot.buttonY, snapshot.leftShoulder, snapshot.rightShoulder,
        snapshot.leftThumbstickX, snapshot.leftThumbstickY, snapshot.rightThumbstickX,
        snapshot.rightThumbstickY, snapshot.leftTrigger, snapshot.rightTrigger
    ] {
        _gcAppendFloat(&data, value)
    }
    _gcAppendBool(&data, snapshot.supportsClickableThumbsticks)
    _gcAppendBool(&data, snapshot.leftThumbstickButton)
    _gcAppendBool(&data, snapshot.rightThumbstickButton)
    return data
}

public func GCExtendedGamepadSnapshotDataFromNSData(
    _ snapshotData: UnsafeMutablePointer<GCExtendedGamepadSnapshotData>?,
    _ data: Data?
) -> Bool {
    guard let snapshotData, let data else { return false }
    var offset = 0
    guard
        let version = _gcReadUInt16(data, &offset),
        let size = _gcReadUInt16(data, &offset)
    else { return false }
    var floats: [Float] = []
    for _ in 0..<14 {
        guard let value = _gcReadFloat(data, &offset) else { return false }
        floats.append(value)
    }
    guard
        let supports = _gcReadBool(data, &offset),
        let leftStick = _gcReadBool(data, &offset),
        let rightStick = _gcReadBool(data, &offset)
    else { return false }
    snapshotData.pointee = GCExtendedGamepadSnapshotData(
        version: version, size: size,
        dpadX: floats[0], dpadY: floats[1],
        buttonA: floats[2], buttonB: floats[3], buttonX: floats[4], buttonY: floats[5],
        leftShoulder: floats[6], rightShoulder: floats[7],
        leftThumbstickX: floats[8], leftThumbstickY: floats[9],
        rightThumbstickX: floats[10], rightThumbstickY: floats[11],
        leftTrigger: floats[12], rightTrigger: floats[13],
        supportsClickableThumbsticks: supports,
        leftThumbstickButton: leftStick,
        rightThumbstickButton: rightStick
    )
    return true
}

public func NSDataFromGCMicroGamepadSnapShotDataV100(
    _ snapshotData: UnsafeMutablePointer<GCMicroGamepadSnapShotDataV100>?
) -> Data? {
    guard let snapshot = snapshotData?.pointee else { return nil }
    var data = Data()
    _gcAppendUInt16(&data, snapshot.version)
    _gcAppendUInt16(&data, snapshot.size)
    _gcAppendFloat(&data, snapshot.dpadX)
    _gcAppendFloat(&data, snapshot.dpadY)
    _gcAppendFloat(&data, snapshot.buttonA)
    _gcAppendFloat(&data, snapshot.buttonX)
    return data
}

public func GCMicroGamepadSnapShotDataV100FromNSData(
    _ snapshotData: UnsafeMutablePointer<GCMicroGamepadSnapShotDataV100>?,
    _ data: Data?
) -> Bool {
    guard let snapshotData, let data else { return false }
    var offset = 0
    guard
        let version = _gcReadUInt16(data, &offset),
        let size = _gcReadUInt16(data, &offset),
        let dpadX = _gcReadFloat(data, &offset),
        let dpadY = _gcReadFloat(data, &offset),
        let buttonA = _gcReadFloat(data, &offset),
        let buttonX = _gcReadFloat(data, &offset)
    else { return false }
    snapshotData.pointee = GCMicroGamepadSnapShotDataV100(
        version: version, size: size, dpadX: dpadX, dpadY: dpadY, buttonA: buttonA, buttonX: buttonX
    )
    return true
}

public func NSDataFromGCMicroGamepadSnapshotData(
    _ snapshotData: UnsafeMutablePointer<GCMicroGamepadSnapshotData>?
) -> Data? {
    guard let snapshot = snapshotData?.pointee else { return nil }
    var data = Data()
    _gcAppendUInt16(&data, snapshot.version)
    _gcAppendUInt16(&data, snapshot.size)
    _gcAppendFloat(&data, snapshot.dpadX)
    _gcAppendFloat(&data, snapshot.dpadY)
    _gcAppendFloat(&data, snapshot.buttonA)
    _gcAppendFloat(&data, snapshot.buttonX)
    return data
}

public func GCMicroGamepadSnapshotDataFromNSData(
    _ snapshotData: UnsafeMutablePointer<GCMicroGamepadSnapshotData>?,
    _ data: Data?
) -> Bool {
    guard let snapshotData, let data else { return false }
    var offset = 0
    guard
        let version = _gcReadUInt16(data, &offset),
        let size = _gcReadUInt16(data, &offset),
        let dpadX = _gcReadFloat(data, &offset),
        let dpadY = _gcReadFloat(data, &offset),
        let buttonA = _gcReadFloat(data, &offset),
        let buttonX = _gcReadFloat(data, &offset)
    else { return false }
    snapshotData.pointee = GCMicroGamepadSnapshotData(
        version: version, size: size, dpadX: dpadX, dpadY: dpadY, buttonA: buttonA, buttonX: buttonX
    )
    return true
}

open class GCGamepadSnapshot: GCGamepad {
    open var snapshotData: Data {
        didSet { _apply() }
    }

    public init(snapshotData data: Data) {
        self.snapshotData = data
        super.init()
        _apply()
    }

    public required init() {
        self.snapshotData = Data()
        super.init()
    }

    public init(controller: GCController, snapshotData data: Data) {
        self.snapshotData = data
        super.init()
        self.controller = controller
        _apply()
    }

    private func _apply() {
        var parsed = GCGamepadSnapShotDataV100()
        guard GCGamepadSnapShotDataV100FromNSData(&parsed, snapshotData) else { return }
        dpad.setValueForXAxis(parsed.dpadX, yAxis: parsed.dpadY)
        buttonA.setValue(parsed.buttonA)
        buttonB.setValue(parsed.buttonB)
        buttonX.setValue(parsed.buttonX)
        buttonY.setValue(parsed.buttonY)
        leftShoulder.setValue(parsed.leftShoulder)
        rightShoulder.setValue(parsed.rightShoulder)
    }
}

open class GCExtendedGamepadSnapshot: GCExtendedGamepad {
    open var snapshotData: Data {
        didSet { _apply() }
    }

    public init(snapshotData data: Data) {
        self.snapshotData = data
        super.init()
        _apply()
    }

    public required init() {
        self.snapshotData = Data()
        super.init()
    }

    public init(controller: GCController, snapshotData data: Data) {
        self.snapshotData = data
        super.init()
        self.controller = controller
        _apply()
    }

    private func _apply() {
        var parsed = GCExtendedGamepadSnapshotData()
        if GCExtendedGamepadSnapshotDataFromNSData(&parsed, snapshotData) {
            dpad.setValueForXAxis(parsed.dpadX, yAxis: parsed.dpadY)
            buttonA.setValue(parsed.buttonA)
            buttonB.setValue(parsed.buttonB)
            buttonX.setValue(parsed.buttonX)
            buttonY.setValue(parsed.buttonY)
            leftShoulder.setValue(parsed.leftShoulder)
            rightShoulder.setValue(parsed.rightShoulder)
            leftThumbstick.setValueForXAxis(parsed.leftThumbstickX, yAxis: parsed.leftThumbstickY)
            rightThumbstick.setValueForXAxis(parsed.rightThumbstickX, yAxis: parsed.rightThumbstickY)
            leftTrigger.setValue(parsed.leftTrigger)
            rightTrigger.setValue(parsed.rightTrigger)
            leftThumbstickButton?.setValue(parsed.leftThumbstickButton.boolValue ? 1 : 0)
            rightThumbstickButton?.setValue(parsed.rightThumbstickButton.boolValue ? 1 : 0)
            return
        }
        var legacy = GCExtendedGamepadSnapShotDataV100()
        guard GCExtendedGamepadSnapShotDataV100FromNSData(&legacy, snapshotData) else { return }
        dpad.setValueForXAxis(legacy.dpadX, yAxis: legacy.dpadY)
        buttonA.setValue(legacy.buttonA)
        buttonB.setValue(legacy.buttonB)
        buttonX.setValue(legacy.buttonX)
        buttonY.setValue(legacy.buttonY)
        leftShoulder.setValue(legacy.leftShoulder)
        rightShoulder.setValue(legacy.rightShoulder)
        leftThumbstick.setValueForXAxis(legacy.leftThumbstickX, yAxis: legacy.leftThumbstickY)
        rightThumbstick.setValueForXAxis(legacy.rightThumbstickX, yAxis: legacy.rightThumbstickY)
        leftTrigger.setValue(legacy.leftTrigger)
        rightTrigger.setValue(legacy.rightTrigger)
    }
}

open class GCMicroGamepadSnapshot: GCMicroGamepad {
    open var snapshotData: Data {
        didSet { _apply() }
    }

    public init(snapshotData data: Data) {
        self.snapshotData = data
        super.init()
        _apply()
    }

    public required init() {
        self.snapshotData = Data()
        super.init()
    }

    public init(controller: GCController, snapshotData data: Data) {
        self.snapshotData = data
        super.init()
        self.controller = controller
        _apply()
    }

    private func _apply() {
        var parsed = GCMicroGamepadSnapshotData()
        if GCMicroGamepadSnapshotDataFromNSData(&parsed, snapshotData) {
            dpad.setValueForXAxis(parsed.dpadX, yAxis: parsed.dpadY)
            buttonA.setValue(parsed.buttonA)
            buttonX.setValue(parsed.buttonX)
            return
        }
        var legacy = GCMicroGamepadSnapShotDataV100()
        guard GCMicroGamepadSnapShotDataV100FromNSData(&legacy, snapshotData) else { return }
        dpad.setValueForXAxis(legacy.dpadX, yAxis: legacy.dpadY)
        buttonA.setValue(legacy.buttonA)
        buttonX.setValue(legacy.buttonX)
    }
}
