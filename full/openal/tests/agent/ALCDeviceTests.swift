import OpenAL

func testALCDeviceContextLifecycle() {
    oaRequire(alcGetCurrentContext() == nil, "no current context")
    let unknown = alcOpenDevice("not-a-device")
    oaRequire(unknown == nil, "unknown device name")
    oaRequire(alcGetError(nil) == ALC_INVALID_VALUE, "unknown name error")
    oaRequire(alcGetError(nil) == ALC_NO_ERROR, "alc error cleared")

    let open: LPALCOPENDEVICE = { alcOpenDevice($0) }
    let device = open(nil)
    oaRequire(device != nil, "default device")
    let close: LPALCCLOSEDEVICE = { alcCloseDevice($0) }
    let create: LPALCCREATECONTEXT = { alcCreateContext($0, $1) }
    let attrs: [ALCint] = [ALC_FREQUENCY, 22050, ALC_REFRESH, 30, ALC_SYNC, 0, ALC_MONO_SOURCES, 8, ALC_STEREO_SOURCES, 4, 0]
    let ctx = attrs.withUnsafeBufferPointer { create(device, $0.baseAddress) }
    oaRequire(ctx != nil, "create context")
    let make: LPALCMAKECONTEXTCURRENT = { alcMakeContextCurrent($0) }
    oaRequire(make(ctx) != 0, "make current")
    let current: LPALCGETCURRENTCONTEXT = { alcGetCurrentContext() }
    oaRequire(current() == ctx, "get current")
    let contextsDevice: LPALCGETCONTEXTSDEVICE = { alcGetContextsDevice($0) }
    oaRequire(contextsDevice(ctx) == device, "contexts device")
    let process: LPALCPROCESSCONTEXT = { alcProcessContext($0) }
    let suspend: LPALCSUSPENDCONTEXT = { alcSuspendContext($0) }
    suspend(ctx)
    process(ctx)
    let destroy: LPALCDESTROYCONTEXT = { alcDestroyContext($0) }
    oaRequire(close(device) == 0, "close while context lives")
    oaRequire(alcGetError(device) == ALC_INVALID_DEVICE, "busy device")
    _ = make(nil)
    destroy(ctx)
    oaRequire(close(device) != 0, "close after destroy")
}

func testALCGetStringEnumVersion() {
    withALContext { device, _ in
        let getString: LPALCGETSTRING = { alcGetString($0, $1) }
        let defaultName = oaCString(getString(nil, ALC_DEFAULT_DEVICE_SPECIFIER))
        oaRequire(defaultName == OpenALModuleInfo.deviceName, "default specifier")
        let allDefault = oaCString(alcGetString(nil, ALC_DEFAULT_ALL_DEVICES_SPECIFIER))
        oaRequire(allDefault == OpenALModuleInfo.deviceName, "default all")
        let extensions = oaCString(getString(device, ALC_EXTENSIONS))
        oaRequire(extensions.contains("ALC_ENUMERATION_EXT"), "enumeration ext")
        oaRequire(extensions.contains("ALC_EXT_CAPTURE"), "capture ext string")
        let present: LPALCISEXTENSIONPRESENT = { alcIsExtensionPresent($0, $1) }
        oaRequire(present(nil, "ALC_ENUMERATION_EXT") != 0, "enumeration present")
        oaRequire(present(nil, "ALC_ENUMERATE_ALL_EXT") != 0, "enumerate all")
        oaRequire(present(nil, "ALC_EXT_CAPTURE") != 0, "capture API present")
        oaRequire(present(nil, "ALC_EXT_ASA") == 0, "ASA absent")
        let enumValue: LPALCGETENUMVALUE = { alcGetEnumValue($0, $1) }
        oaRequire(enumValue(device, "ALC_FREQUENCY") == ALC_FREQUENCY, "alcGetEnumValue")
        let proc: LPALCGETPROCADDRESS = { alcGetProcAddress($0, $1) }
        oaRequire(proc(device, "alcASASetListener") == nil, "ASA proc nil")
        oaRequire(proc(device, "alcMacOSXRenderingQuality") == nil, "mixer proc nil")
        var major: ALCint = 0
        var minor: ALCint = 0
        let getInt: LPALCGETINTEGERV = { alcGetIntegerv($0, $1, $2, $3) }
        getInt(nil, ALC_MAJOR_VERSION, 1, &major)
        getInt(nil, ALC_MINOR_VERSION, 1, &minor)
        oaRequire(major == 1 && minor == 1, "ALC 1.1")
        var freq: ALCint = 0
        getInt(device, ALC_FREQUENCY, 1, &freq)
        oaRequire(freq == 44100, "default frequency")
        var attrSize: ALCint = 0
        getInt(device, ALC_ATTRIBUTES_SIZE, 1, &attrSize)
        oaRequire(attrSize == 11, "attributes size")
        var attrs = [ALCint](repeating: -1, count: 11)
        attrs.withUnsafeMutableBufferPointer { getInt(device, ALC_ALL_ATTRIBUTES, 11, $0.baseAddress) }
        oaRequire(attrs[0] == ALC_FREQUENCY && attrs[10] == 0, "all attributes terminator")
        let getError: LPALCGETERROR = { alcGetError($0) }
        oaRequire(getError(device) == ALC_NO_ERROR, "no alc error")
    }
}

func testALCaptureFailClosed() {
    let open: LPALCCAPTUREOPENDEVICE = { alcCaptureOpenDevice($0, $1, $2, $3) }
    let handle = open(nil, 44100, AL_FORMAT_MONO16, 4096)
    oaRequire(handle == nil, "no capture hardware")
    oaRequire(alcGetError(nil) == ALC_INVALID_VALUE, "capture open error")
    let start: LPALCCAPTURESTART = { alcCaptureStart($0) }
    let stop: LPALCCAPTURESTOP = { alcCaptureStop($0) }
    let samples: LPALCCAPTURESAMPLES = { alcCaptureSamples($0, $1, $2) }
    let close: LPALCCAPTURECLOSEDEVICE = { alcCaptureCloseDevice($0) }
    start(nil)
    oaRequire(alcGetError(nil) == ALC_INVALID_DEVICE, "start nil")
    stop(nil)
    oaRequire(alcGetError(nil) == ALC_INVALID_DEVICE, "stop nil")
    var scratch: Int16 = 0
    samples(nil, &scratch, 1)
    oaRequire(alcGetError(nil) == ALC_INVALID_DEVICE, "samples nil")
    oaRequire(close(nil) == 0, "close nil")
    oaRequire(alcGetError(nil) == ALC_INVALID_DEVICE, "close nil error")
    oaRequire(alcGetString(nil, ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER) == nil, "no default capture")
}
