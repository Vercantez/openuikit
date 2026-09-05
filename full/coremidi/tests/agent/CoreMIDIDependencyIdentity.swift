import CoreMIDI
import CoreFoundation

/// Central ARM64 identity probe. Isolated host gate does not compile this file;
/// it only requires the import lines. Do not introduce module-local stand-ins
/// for CoreFoundation types.

func coreMIDIPassCanonicalCoreFoundation(_ name: CFString) -> OSStatus {
    var client: MIDIClientRef = 0
    return MIDIClientCreate(name, nil, nil, &client)
}

func coreMIDIPassCanonicalRunLoop() -> CFRunLoop {
    MIDIGetDriverIORunLoop().takeUnretainedValue()
}

func coreMIDIPassCanonicalCFData(_ data: CFData) -> OSStatus {
    var connection: MIDIThruConnectionRef = 0
    return MIDIThruConnectionCreate(nil, data, &connection)
}
