import OpenAL

func testALDistanceDopplerAndStrings() {
    withALContext { _, _ in
        let dist: LPALDISTANCEMODEL = { alDistanceModel($0) }
        dist(AL_LINEAR_DISTANCE)
        let gi: LPALGETINTEGER = { alGetInteger($0) }
        oaRequire(gi(AL_DISTANCE_MODEL) == AL_LINEAR_DISTANCE, "distance model")
        var stored: ALint = 0
        let giv: LPALGETINTEGERV = { alGetIntegerv($0, $1) }
        giv(AL_DISTANCE_MODEL, &stored)
        oaRequire(stored == AL_LINEAR_DISTANCE, "distance integerv")
        dist(AL_INVERSE_DISTANCE_CLAMPED)
        oaRequire(alGetInteger(AL_DISTANCE_MODEL) == AL_INVERSE_DISTANCE_CLAMPED, "default restored")

        let df: LPALDOPPLERFACTOR = { alDopplerFactor($0) }
        let dv: LPALDOPPLERVELOCITY = { alDopplerVelocity($0) }
        let ss: LPALSPEEDOFSOUND = { alSpeedOfSound($0) }
        df(0.5)
        dv(2)
        ss(343.3)
        let gf: LPALGETFLOAT = { alGetFloat($0) }
        oaRequire(gf(AL_DOPPLER_FACTOR) == 0.5, "doppler factor")
        oaRequire(alGetFloat(AL_DOPPLER_VELOCITY) == 2, "doppler velocity")
        var speed: ALfloat = 0
        let gfv: LPALGETFLOATV = { alGetFloatv($0, $1) }
        gfv(AL_SPEED_OF_SOUND, &speed)
        oaRequire(abs(speed - 343.3) < 0.01, "speed of sound")
        let gd: LPALGETDOUBLE = { alGetDouble($0) }
        oaRequire(abs(gd(AL_DOPPLER_FACTOR) - 0.5) < 0.001, "doppler double")
        var dd: ALdouble = 0
        let gdv: LPALGETDOUBLEV = { alGetDoublev($0, $1) }
        gdv(AL_SPEED_OF_SOUND, &dd)
        oaRequire(abs(dd - 343.3) < 0.01, "speed double")

        let getString: LPALGETSTRING = { alGetString($0) }
        oaRequire(oaCString(getString(AL_VENDOR)) == OpenALModuleInfo.vendor, "vendor")
        oaRequire(oaCString(alGetString(AL_VERSION)).contains("1.1"), "version")
        oaRequire(oaCString(alGetString(AL_RENDERER)) == OpenALModuleInfo.renderer, "renderer")
        oaRequire(oaCString(alGetString(AL_EXTENSIONS)).isEmpty, "no AL extensions claimed")

        let enumValue: LPALGETENUMVALUE = { alGetEnumValue($0) }
        oaRequire(enumValue("AL_GAIN") == AL_GAIN, "alGetEnumValue")
        oaRequire(alGetEnumValue("AL_PLAYING") == AL_PLAYING, "playing enum")
        let ext: LPALISEXTENSIONPRESENT = { alIsExtensionPresent($0) }
        oaRequire(ext("AL_EXT_SOURCE_NOTIFICATIONS") == 0, "notifications absent")
        let proc: LPALGETPROCADDRESS = { alGetProcAddress($0) }
        oaRequire(proc("alSourceAddNotification") == nil, "notification proc nil")
        oaRequire(alGetProcAddress("alcOutputCapturerStart") == nil, "output capturer nil")

        let unclamped = openALInverseDistanceGain(
            distance: 4, referenceDistance: 1, rolloff: 1, maxDistance: 100, clamped: false
        )
        oaRequire(abs(unclamped - 0.25) < 0.0001, "inverse distance 1/(1+3)")
        let clamped = openALInverseDistanceGain(
            distance: 0.1, referenceDistance: 1, rolloff: 1, maxDistance: 10, clamped: true
        )
        oaRequire(abs(clamped - 1) < 0.0001, "clamped below ref")
        oaRequire(alGetError() == AL_NO_ERROR, "global path")
    }
}
