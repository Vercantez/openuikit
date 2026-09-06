import OpenAL

func testAppleExtensionProcPtrsFailClosed() {
    withALContext { _, _ in
        let notify: alSourceNotificationProc = { _, _, _ in }
        let add: alSourceAddNotificationProcPtr = { _, _, _, _ in AL_INVALID_OPERATION }
        let remove: alSourceRemoveNotificationProcPtr = { _, _, _, _ in }
        var source: ALuint = 0
        alGenSources(1, &source)
        oaRequire(add(source, ALuint(AL_QUEUE_HAS_LOOPED), notify, nil) == AL_INVALID_OPERATION, "add notify fail-closed")
        remove(source, ALuint(AL_SOURCE_STATE), notify, nil)
        let qualitySet: alSourceRenderingQualityProcPtr = { _, _ in }
        let qualityGet: alSourceGetRenderingQualityProcPtr = { _ in 0 }
        qualitySet(source, 0)
        oaRequire(qualityGet(source) == 0, "source quality unused")
        let staticBuf: alBufferDataStaticProcPtr = { _, _, _, _, _ in }
        staticBuf(ALint(source), AL_FORMAT_MONO8, UnsafeRawPointer(bitPattern: 1)!, 0, 8000)
        let channelsSet: alMacOSXRenderChannelCountProcPtr = { _ in }
        let channelsGet: alMacOSXGetRenderChannelCountProcPtr = { 0 }
        channelsSet(0)
        oaRequire(channelsGet() == 0, "channel count unused")
        let asaSetL: alcASASetListenerProcPtr = { _, _, _ in AL_INVALID_OPERATION }
        let asaGetL: alcASAGetListenerProcPtr = { _, _, _ in AL_INVALID_OPERATION }
        let asaSetS: alcASASetSourceProcPtr = { _, _, _, _ in AL_INVALID_OPERATION }
        let asaGetS: alcASAGetSourceProcPtr = { _, _, _, _ in AL_INVALID_OPERATION }
        var size: ALuint = 0
        var room = ALC_ASA_REVERB_ROOM_TYPE_SmallRoom
        oaRequire(asaSetL(0, &room, 4) == AL_INVALID_OPERATION, "ASA set listener")
        oaRequire(asaGetL(0, &room, &size) == AL_INVALID_OPERATION, "ASA get listener")
        oaRequire(asaSetS(0, source, &room, 4) == AL_INVALID_OPERATION, "ASA set source")
        oaRequire(asaGetS(0, source, &room, &size) == AL_INVALID_OPERATION, "ASA get source")
        let mixSet: alcMacOSXMixerMaxiumumBussesProcPtr = { _ in }
        let mixGet: alcMacOSXGetMixerMaxiumumBussesProcPtr = { 0 }
        let rateSet: alcMacOSXMixerOutputRateProcPtr = { _ in }
        let rateGet: alcMacOSXGetMixerOutputRateProcPtr = { 0 }
        let rqSet: alcMacOSXRenderingQualityProcPtr = { _ in }
        let rqGet: alcMacOSXGetRenderingQualityProcPtr = { 0 }
        mixSet(16)
        oaRequire(mixGet() == 0, "mixer buses")
        rateSet(44100)
        oaRequire(rateGet() == 0, "mixer rate")
        rqSet(0)
        oaRequire(rqGet() == 0, "render quality")
        let capPrep: alcOutputCapturerPrepareProcPtr = { _, _, _ in }
        let capStart: alcOutputCapturerStartProcPtr = { }
        let capStop: alcOutputCapturerStopProcPtr = { }
        let capAvail: alcOutputCapturerAvailableSamplesProcPtr = { 0 }
        let capSamples: alcOutputCapturerSamplesProcPtr = { _, _ in }
        capPrep(44100, AL_FORMAT_MONO16, 1024)
        capStart()
        oaRequire(capAvail() == 0, "output capturer empty")
        var sampleScratch: Int16 = 0
        capSamples(&sampleScratch, 0)
        capStop()
        oaRequire(alGetProcAddress("alcASASetListener") == nil, "ASA not exported")
        oaRequire(alcGetProcAddress(nil, "alcOutputCapturerStart") == nil, "output capturer not exported")
        alDeleteSources(1, &source)
    }
}
