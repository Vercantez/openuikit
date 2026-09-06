import CoreFoundation
import OpenAL

func openALDependencyIdentityProbe() {
    let cfName: CFString = OpenALModuleInfo.deviceNameAsCFString
    var chars = [CChar](repeating: 0, count: 128)
    oaRequire(
        CFStringGetCString(
            cfName,
            &chars,
            chars.count,
            CFStringBuiltInEncodings.UTF8.rawValue
        ),
        "CFStringGetCString"
    )
    let device = alcOpenDevice(chars)
    oaRequire(device != nil, "open CFString device name")
    let ctx = alcCreateContext(device, nil)
    oaRequire(ctx != nil, "context")
    oaRequire(alcMakeContextCurrent(ctx) != 0, "current")
    var buffer: ALuint = 0
    alGenBuffers(1, &buffer)
    let payload: [UInt8] = [0, 127, 255, 64]
    let cfData = payload.withUnsafeBufferPointer { bytes in
        CFDataCreate(kCFAllocatorDefault, bytes.baseAddress, bytes.count)!
    }
    alBufferData(
        buffer,
        AL_FORMAT_MONO8,
        CFDataGetBytePtr(cfData),
        ALsizei(CFDataGetLength(cfData)),
        8000
    )
    oaRequire(alGetError() == AL_NO_ERROR, "CFData through alBufferData")
    var size: ALint = 0
    alGetBufferi(buffer, AL_SIZE, &size)
    oaRequire(size == 4, "CFData size")
    _ = CFTimeInterval(0)
    alDeleteBuffers(1, &buffer)
    _ = alcMakeContextCurrent(nil)
    alcDestroyContext(ctx)
    _ = alcCloseDevice(device)
}

#if OPENAL_IDENTITY_MAIN
openALDependencyIdentityProbe()
print("OPENAL_DEPENDENCY_IDENTITY_OK")
#endif
