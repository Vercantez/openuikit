import OpenAL

func testALBufferDataRoundTrip() {
    withALContext { _, _ in
        var name: ALuint = 0
        let gen: LPALGENBUFFERS = { alGenBuffers($0, $1) }
        gen(1, &name)
        oaRequire(name != 0, "buffer name")
        let isBuffer: LPALISBUFFER = { alIsBuffer($0) }
        oaRequire(isBuffer(name) != 0, "is buffer")
        oaRequire(alIsBuffer(0) == 0, "zero is not a buffer")
        let samples: [Int16] = [1, -2, 3, -4]
        let dataFn: LPALBUFFERDATA = { alBufferData($0, $1, $2, $3, $4) }
        samples.withUnsafeBufferPointer {
            dataFn(name, AL_FORMAT_STEREO16, $0.baseAddress, 8, 22050)
        }
        oaRequire(alGetError() == AL_NO_ERROR, "buffer data")
        var freq: ALint = 0
        var bits: ALint = 0
        var channels: ALint = 0
        var size: ALint = 0
        let geti: LPALGETBUFFERI = { alGetBufferi($0, $1, $2) }
        geti(name, AL_FREQUENCY, &freq)
        geti(name, AL_BITS, &bits)
        geti(name, AL_CHANNELS, &channels)
        geti(name, AL_SIZE, &size)
        oaRequire(freq == 22050 && bits == 16 && channels == 2 && size == 8, "buffer meta")
        var freqf: ALfloat = 0
        let getf: LPALGETBUFFERF = { alGetBufferf($0, $1, $2) }
        getf(name, AL_FREQUENCY, &freqf)
        oaRequire(freqf == 22050, "buffer float freq")
        var iv: ALint = 0
        let getiv: LPALGETBUFFERIV = { alGetBufferiv($0, $1, $2) }
        getiv(name, AL_CHANNELS, &iv)
        oaRequire(iv == 2, "buffer iv")
        var fv: ALfloat = 0
        let getfv: LPALGETBUFFERFV = { alGetBufferfv($0, $1, $2) }
        getfv(name, AL_BITS, &fv)
        oaRequire(fv == 16, "buffer fv")
        let del: LPALDELETEBUFFERS = { alDeleteBuffers($0, $1) }
        del(1, &name)
        oaRequire(alIsBuffer(name) == 0, "deleted buffer")
    }
}

func testALBufferSettersInvalidEnum() {
    withALContext { _, _ in
        var name: ALuint = 0
        alGenBuffers(1, &name)
        let bf: LPALBUFFERF = { alBufferf($0, $1, $2) }
        let bi: LPALBUFFERI = { alBufferi($0, $1, $2) }
        let b3f: LPALBUFFER3F = { alBuffer3f($0, $1, $2, $3, $4) }
        let b3i: LPALBUFFER3I = { alBuffer3i($0, $1, $2, $3, $4) }
        let bfv: LPALBUFFERFV = { alBufferfv($0, $1, $2) }
        let biv: LPALBUFFERIV = { alBufferiv($0, $1, $2) }
        bf(name, AL_GAIN, 1)
        oaRequire(alGetError() == AL_INVALID_ENUM, "bufferf")
        bi(name, AL_GAIN, 1)
        oaRequire(alGetError() == AL_INVALID_ENUM, "bufferi")
        b3f(name, AL_POSITION, 0, 0, 0)
        oaRequire(alGetError() == AL_INVALID_ENUM, "buffer3f")
        b3i(name, AL_POSITION, 0, 0, 0)
        oaRequire(alGetError() == AL_INVALID_ENUM, "buffer3i")
        let fvals: [ALfloat] = [0]
        fvals.withUnsafeBufferPointer { bfv(name, AL_GAIN, $0.baseAddress) }
        oaRequire(alGetError() == AL_INVALID_ENUM, "bufferfv")
        let ivals: [ALint] = [0]
        ivals.withUnsafeBufferPointer { biv(name, AL_GAIN, $0.baseAddress) }
        oaRequire(alGetError() == AL_INVALID_ENUM, "bufferiv")
        let g3f: LPALGETBUFFER3F = { alGetBuffer3f($0, $1, $2, $3, $4) }
        let g3i: LPALGETBUFFER3I = { alGetBuffer3i($0, $1, $2, $3, $4) }
        var x: ALfloat = 0
        var y: ALfloat = 0
        var z: ALfloat = 0
        g3f(name, AL_POSITION, &x, &y, &z)
        oaRequire(alGetError() == AL_INVALID_ENUM, "getbuffer3f")
        var ix: ALint = 0
        var iy: ALint = 0
        var iz: ALint = 0
        g3i(name, AL_POSITION, &ix, &iy, &iz)
        oaRequire(alGetError() == AL_INVALID_ENUM, "getbuffer3i")
        alDeleteBuffers(1, &name)
    }
}

func testALBufferFormats() {
    withALContext { _, _ in
        var names: [ALuint] = [0, 0, 0, 0]
        alGenBuffers(4, &names)
        let mono8: [UInt8] = [0, 255]
        mono8.withUnsafeBufferPointer {
            alBufferData(names[0], AL_FORMAT_MONO8, $0.baseAddress, 2, 8000)
        }
        let mono16: [Int16] = [0, 1]
        mono16.withUnsafeBufferPointer {
            alBufferData(names[1], AL_FORMAT_MONO16, $0.baseAddress, 4, 8000)
        }
        let stereo8: [UInt8] = [0, 1, 2, 3]
        stereo8.withUnsafeBufferPointer {
            alBufferData(names[2], AL_FORMAT_STEREO8, $0.baseAddress, 4, 8000)
        }
        let stereo16: [Int16] = [0, 1]
        stereo16.withUnsafeBufferPointer {
            alBufferData(names[3], AL_FORMAT_STEREO16, $0.baseAddress, 4, 8000)
        }
        var channels: ALint = 0
        var bits: ALint = 0
        alGetBufferi(names[0], AL_CHANNELS, &channels)
        alGetBufferi(names[0], AL_BITS, &bits)
        oaRequire(channels == 1 && bits == 8, "mono8")
        alGetBufferi(names[1], AL_CHANNELS, &channels)
        alGetBufferi(names[1], AL_BITS, &bits)
        oaRequire(channels == 1 && bits == 16, "mono16")
        alGetBufferi(names[2], AL_CHANNELS, &channels)
        alGetBufferi(names[2], AL_BITS, &bits)
        oaRequire(channels == 2 && bits == 8, "stereo8")
        alGetBufferi(names[3], AL_CHANNELS, &channels)
        alGetBufferi(names[3], AL_BITS, &bits)
        oaRequire(channels == 2 && bits == 16, "stereo16")
        alBufferData(names[0], 0x9999, nil, 0, 8000)
        oaRequire(alGetError() == AL_INVALID_ENUM, "bad format")
        alDeleteBuffers(4, &names)
    }
}
