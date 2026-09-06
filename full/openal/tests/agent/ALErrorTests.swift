import OpenAL

func testALErrorStickyAndClear() {
    withALContext { _, _ in
        let getError: LPALGETERROR = { alGetError() }
        oaRequire(getError() == AL_NO_ERROR, "cleared")
        alEnable(0x1234)
        oaRequire(getError() == AL_INVALID_ENUM, "enable invalid")
        oaRequire(getError() == AL_NO_ERROR, "sticky clear")
        alSourcePlay(9999)
        alListenerf(AL_POSITION, 1)
        oaRequire(getError() == AL_INVALID_NAME, "first error is sticky")
        oaRequire(getError() == AL_NO_ERROR, "cleared after query")
    }
}

func testALEnableDisableInvalid() {
    withALContext { _, _ in
        let enable: LPALENABLE = { alEnable($0) }
        let disable: LPALDISABLE = { alDisable($0) }
        let isEnabled: LPALISENABLED = { alIsEnabled($0) }
        enable(AL_GAIN)
        oaRequire(alGetError() == AL_INVALID_ENUM, "alEnable")
        disable(AL_GAIN)
        oaRequire(alGetError() == AL_INVALID_ENUM, "alDisable")
        oaRequire(isEnabled(AL_GAIN) == 0, "isEnabled false")
        oaRequire(alGetError() == AL_INVALID_ENUM, "alIsEnabled")
        let gb: LPALGETBOOLEAN = { alGetBoolean($0) }
        oaRequire(gb(AL_GAIN) == 0, "getBoolean invalid")
        oaRequire(alGetError() == AL_INVALID_ENUM, "getBoolean error")
        var flag: ALboolean = 1
        let gbv: LPALGETBOOLEANV = { alGetBooleanv($0, $1) }
        gbv(AL_GAIN, &flag)
        oaRequire(alGetError() == AL_INVALID_ENUM, "getBooleanv")
    }
}

func testALInvalidNameAndValue() {
    withALContext { _, _ in
        let n: ALsizei = -1
        var unused: ALuint = 0
        alGenSources(n, &unused)
        oaRequire(alGetError() == AL_INVALID_VALUE, "neg gen")
        alDeleteSources(1, &unused)
        oaRequire(alGetError() == AL_INVALID_NAME, "delete missing")
        alDopplerFactor(-1)
        oaRequire(alGetError() == AL_INVALID_VALUE, "neg doppler")
        alSpeedOfSound(0)
        oaRequire(alGetError() == AL_INVALID_VALUE, "zero speed")
        alDistanceModel(0x123)
        oaRequire(alGetError() == AL_INVALID_ENUM, "bad distance")
    }
}
