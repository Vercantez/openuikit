import OpenAL

func testALListenerRoundTrip() {
    withALContext { _, _ in
        let lf: LPALLISTENERF = { alListenerf($0, $1) }
        let li: LPALLISTENERI = { alListeneri($0, $1) }
        let l3f: LPALLISTENER3F = { alListener3f($0, $1, $2, $3) }
        let l3i: LPALLISTENER3I = { alListener3i($0, $1, $2, $3) }
        lf(AL_GAIN, 0.5)
        l3f(AL_POSITION, 1, 2, 3)
        l3i(AL_VELOCITY, 4, 5, 6)
        let orient: [ALfloat] = [0, 0, -1, 0, 1, 0]
        let lfv: LPALLISTENERFV = { alListenerfv($0, $1) }
        orient.withUnsafeBufferPointer { lfv(AL_ORIENTATION, $0.baseAddress) }
        li(AL_GAIN, 1)

        var gain: ALfloat = 0
        let gf: LPALGETLISTENERF = { alGetListenerf($0, $1) }
        gf(AL_GAIN, &gain)
        oaRequire(gain == 1, "listener gain")
        var x: ALfloat = 0
        var y: ALfloat = 0
        var z: ALfloat = 0
        let g3f: LPALGETLISTENER3F = { alGetListener3f($0, $1, $2, $3) }
        g3f(AL_POSITION, &x, &y, &z)
        oaRequire(x == 1 && y == 2 && z == 3, "listener position")
        var ix: ALint = 0
        var iy: ALint = 0
        var iz: ALint = 0
        let g3i: LPALGETLISTENER3I = { alGetListener3i($0, $1, $2, $3) }
        g3i(AL_VELOCITY, &ix, &iy, &iz)
        oaRequire(ix == 4 && iy == 5 && iz == 6, "listener velocity")
        var ori = [ALfloat](repeating: 0, count: 6)
        let gfv: LPALGETLISTENERFV = { alGetListenerfv($0, $1) }
        ori.withUnsafeMutableBufferPointer { gfv(AL_ORIENTATION, $0.baseAddress) }
        oaRequire(ori[2] == -1 && ori[4] == 1, "orientation")
        var igain: ALint = 0
        let gi: LPALGETLISTENERI = { alGetListeneri($0, $1) }
        gi(AL_GAIN, &igain)
        oaRequire(igain == 1, "listener i gain")
        let liv: LPALLISTENERIV = { alListeneriv($0, $1) }
        let posi: [ALint] = [7, 8, 9]
        posi.withUnsafeBufferPointer { liv(AL_POSITION, $0.baseAddress) }
        var ipos = [ALint](repeating: 0, count: 3)
        let giv: LPALGETLISTENERIV = { alGetListeneriv($0, $1) }
        ipos.withUnsafeMutableBufferPointer { giv(AL_POSITION, $0.baseAddress) }
        oaRequire(ipos[0] == 7 && ipos[2] == 9, "listeneriv position")
        oaRequire(alGetError() == AL_NO_ERROR, "listener path")
    }
}
