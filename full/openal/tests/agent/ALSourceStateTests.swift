import OpenAL

func testALSourcePlayPauseStopRewind() {
    withALContext { _, _ in
        var source: ALuint = 0
        let gen: LPALGENSOURCES = { alGenSources($0, $1) }
        gen(1, &source)
        oaRequire(source != 0, "gen source")
        let isSource: LPALISSOURCE = { alIsSource($0) }
        oaRequire(isSource(source) != 0, "is source")
        oaRequire(alIsSource(0) == 0, "zero is not a source")
        var state: ALint = 0
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_INITIAL, "initial")
        var type: ALint = 0
        alGetSourcei(source, AL_SOURCE_TYPE, &type)
        oaRequire(type == AL_UNDETERMINED, "undetermined")

        var buffer: ALuint = 0
        alGenBuffers(1, &buffer)
        let silence: [Int16] = [0, 0, 0, 0]
        silence.withUnsafeBufferPointer {
            alBufferData(buffer, AL_FORMAT_MONO16, $0.baseAddress, 8, 8000)
        }
        alSourcei(source, AL_BUFFER, ALint(buffer))
        alGetSourcei(source, AL_SOURCE_TYPE, &type)
        oaRequire(type == AL_STATIC, "static after attach")

        let play: LPALSOURCEPLAY = { alSourcePlay($0) }
        play(source)
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_PLAYING, "playing")
        let pause: LPALSOURCEPAUSE = { alSourcePause($0) }
        pause(source)
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_PAUSED, "paused")
        play(source)
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_PLAYING, "resume")
        let stop: LPALSOURCESTOP = { alSourceStop($0) }
        stop(source)
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_STOPPED, "stopped")
        let rewind: LPALSOURCEREWIND = { alSourceRewind($0) }
        rewind(source)
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_INITIAL, "rewound")

        let sources = [source]
        let playv: LPALSOURCEPLAYV = { alSourcePlayv($0, $1) }
        let pausev: LPALSOURCEPAUSEV = { alSourcePausev($0, $1) }
        let stopv: LPALSOURCESTOPV = { alSourceStopv($0, $1) }
        let rewindv: LPALSOURCEREWINDV = { alSourceRewindv($0, $1) }
        sources.withUnsafeBufferPointer { playv(1, $0.baseAddress) }
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_PLAYING, "playv")
        sources.withUnsafeBufferPointer { pausev(1, $0.baseAddress) }
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_PAUSED, "pausev")
        sources.withUnsafeBufferPointer { stopv(1, $0.baseAddress) }
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_STOPPED, "stopv")
        sources.withUnsafeBufferPointer { rewindv(1, $0.baseAddress) }
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_INITIAL, "rewindv")

        alSourcePlay(source)
        oaRequire(alGetError() == AL_NO_ERROR, "play error")
        let del: LPALDELETESOURCES = { alDeleteSources($0, $1) }
        del(1, &source)
        oaRequire(alIsSource(source) == 0, "deleted")
        alDeleteBuffers(1, &buffer)
    }
}

func testALSourceQueueUnqueue() {
    withALContext { _, _ in
        var source: ALuint = 0
        alGenSources(1, &source)
        var buffers: [ALuint] = [0, 0]
        alGenBuffers(2, &buffers)
        let frame: [UInt8] = [0, 0]
        for i in 0..<2 {
            frame.withUnsafeBufferPointer {
                alBufferData(buffers[i], AL_FORMAT_MONO8, $0.baseAddress, 2, 8000)
            }
        }
        let queue: LPALSOURCEQUEUEBUFFERS = { alSourceQueueBuffers($0, $1, $2) }
        buffers.withUnsafeBufferPointer { queue(source, 2, $0.baseAddress) }
        var queued: ALint = 0
        var processed: ALint = 0
        var type: ALint = 0
        alGetSourcei(source, AL_BUFFERS_QUEUED, &queued)
        alGetSourcei(source, AL_BUFFERS_PROCESSED, &processed)
        alGetSourcei(source, AL_SOURCE_TYPE, &type)
        oaRequire(queued == 2 && processed == 0 && type == AL_STREAMING, "queued streaming")
        alSourcePlay(source)
        var state: ALint = 0
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_PLAYING, "streaming play")
        alGetSourcei(source, AL_BUFFERS_PROCESSED, &processed)
        oaRequire(processed == 0, "no DAC so none processed while playing")
        alSourceStop(source)
        alGetSourcei(source, AL_BUFFERS_PROCESSED, &processed)
        oaRequire(processed == 2, "stop marks queued processed")
        var out: [ALuint] = [0, 0]
        let unqueue: LPALSOURCEUNQUEUEBUFFERS = { alSourceUnqueueBuffers($0, $1, $2) }
        out.withUnsafeMutableBufferPointer { unqueue(source, 2, $0.baseAddress) }
        oaRequire(out[0] == buffers[0] && out[1] == buffers[1], "unqueue order")
        alGetSourcei(source, AL_BUFFERS_QUEUED, &queued)
        oaRequire(queued == 0, "empty queue")
        oaRequire(alGetError() == AL_NO_ERROR, "queue path")
        alDeleteSources(1, &source)
        alDeleteBuffers(2, &buffers)
    }
}

func testALSourcePropertiesRoundTrip() {
    withALContext { _, _ in
        var source: ALuint = 0
        alGenSources(1, &source)
        let sf: LPALSOURCEF = { alSourcef($0, $1, $2) }
        let si: LPALSOURCEI = { alSourcei($0, $1, $2) }
        let s3f: LPALSOURCE3F = { alSource3f($0, $1, $2, $3, $4) }
        let s3i: LPALSOURCE3I = { alSource3i($0, $1, $2, $3, $4) }
        sf(source, AL_PITCH, 1.5)
        sf(source, AL_GAIN, 0.25)
        sf(source, AL_MIN_GAIN, 0.1)
        sf(source, AL_MAX_GAIN, 0.9)
        sf(source, AL_REFERENCE_DISTANCE, 2)
        sf(source, AL_ROLLOFF_FACTOR, 0.5)
        sf(source, AL_MAX_DISTANCE, 100)
        sf(source, AL_CONE_INNER_ANGLE, 45)
        sf(source, AL_CONE_OUTER_ANGLE, 90)
        sf(source, AL_CONE_OUTER_GAIN, 0.2)
        sf(source, AL_SEC_OFFSET, 0.5)
        si(source, AL_LOOPING, AL_TRUE)
        si(source, AL_SOURCE_RELATIVE, AL_TRUE)
        s3f(source, AL_POSITION, 1, 2, 3)
        s3i(source, AL_VELOCITY, 4, 5, 6)
        let dir: [ALfloat] = [0, 1, 0]
        let sfv: LPALSOURCEFV = { alSourcefv($0, $1, $2) }
        dir.withUnsafeBufferPointer { sfv(source, AL_DIRECTION, $0.baseAddress) }
        let siv: LPALSOURCEIV = { alSourceiv($0, $1, $2) }
        let sampleOff: [ALint] = [12]
        sampleOff.withUnsafeBufferPointer { siv(source, AL_SAMPLE_OFFSET, $0.baseAddress) }

        var pitch: ALfloat = 0
        let gf: LPALGETSOURCEF = { alGetSourcef($0, $1, $2) }
        gf(source, AL_PITCH, &pitch)
        oaRequire(pitch == 1.5, "pitch")
        var gain: ALfloat = 0
        alGetSourcef(source, AL_GAIN, &gain)
        oaRequire(gain == 0.25, "gain")
        var looping: ALint = 0
        let gi: LPALGETSOURCEI = { alGetSourcei($0, $1, $2) }
        gi(source, AL_LOOPING, &looping)
        oaRequire(looping == AL_TRUE, "looping")
        var relative: ALint = 0
        alGetSourcei(source, AL_SOURCE_RELATIVE, &relative)
        oaRequire(relative == AL_TRUE, "relative")
        var x: ALfloat = 0
        var y: ALfloat = 0
        var z: ALfloat = 0
        let g3f: LPALGETSOURCE3F = { alGetSource3f($0, $1, $2, $3, $4) }
        g3f(source, AL_POSITION, &x, &y, &z)
        oaRequire(x == 1 && y == 2 && z == 3, "position")
        var ix: ALint = 0
        var iy: ALint = 0
        var iz: ALint = 0
        let g3i: LPALGETSOURCE3I = { alGetSource3i($0, $1, $2, $3, $4) }
        g3i(source, AL_VELOCITY, &ix, &iy, &iz)
        oaRequire(ix == 4 && iy == 5 && iz == 6, "velocity")
        var direction: [ALfloat] = [0, 0, 0]
        let gfv: LPALGETSOURCEFV = { alGetSourcefv($0, $1, $2) }
        direction.withUnsafeMutableBufferPointer { gfv(source, AL_DIRECTION, $0.baseAddress) }
        oaRequire(direction[1] == 1, "direction")
        var sample: ALint = 0
        let giv: LPALGETSOURCEIV = { alGetSourceiv($0, $1, $2) }
        giv(source, AL_SAMPLE_OFFSET, &sample)
        oaRequire(sample == 12, "sample offset")
        var byteOff: ALint = 0
        alGetSourcei(source, AL_BYTE_OFFSET, &byteOff)
        oaRequire(alGetError() == AL_NO_ERROR, "source props")
        alDeleteSources(1, &source)
    }
}

func testALSourcePlayEmptyStops() {
    withALContext { _, _ in
        var source: ALuint = 0
        alGenSources(1, &source)
        alSourcePlay(source)
        var state: ALint = 0
        alGetSourcei(source, AL_SOURCE_STATE, &state)
        oaRequire(state == AL_STOPPED, "play with no buffer stops")
        alDeleteSources(1, &source)
    }
}
