import OpenAL

func oaRequire(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func oaCString(_ pointer: UnsafePointer<ALchar>?) -> String {
    guard let pointer else { return "" }
    return String(cString: pointer)
}

func withALContext(_ body: (OpaquePointer, OpaquePointer) -> Void) {
    let device = alcOpenDevice(nil)
    oaRequire(device != nil, "alcOpenDevice")
    let ctx = alcCreateContext(device, nil)
    oaRequire(ctx != nil, "alcCreateContext")
    oaRequire(alcMakeContextCurrent(ctx) != 0, "alcMakeContextCurrent")
    _ = alGetError()
    _ = alcGetError(device)
    body(device!, ctx!)
    _ = alcMakeContextCurrent(nil)
    alcDestroyContext(ctx)
    oaRequire(alcCloseDevice(device) != 0, "alcCloseDevice")
}
