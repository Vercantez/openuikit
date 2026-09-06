// No audio device is exposed to the guest. System-sound requests are silent.
public typealias SystemSoundID = UInt32
public func AudioServicesPlaySystemSound(_ sound: SystemSoundID) {}
