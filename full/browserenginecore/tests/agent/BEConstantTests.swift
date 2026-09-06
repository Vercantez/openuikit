import BrowserEngineCore
import Foundation

func testBEJITWriteProtectTagLinuxOverlay() {
    let tag: Int = BE_JIT_WRITE_PROTECT_TAG
    precondition(tag == 0)
    precondition(BE_JIT_WRITE_PROTECT_TAG == tag)
    precondition(type(of: BE_JIT_WRITE_PROTECT_TAG) == Int.self)
}

func testBEKeventNoFlagsValue() {
    let flags: Int32 = BE_KEVENT_NO_FLAGS
    precondition(flags == 0x0)
    precondition(flags == 0)
    precondition(type(of: BE_KEVENT_NO_FLAGS) == Int32.self)
}

func testBEKeventReturnImmediatelyValue() {
    let flags: Int32 = BE_KEVENT_RETURN_IMMEDIATELY
    precondition(flags == 0x1)
    precondition(flags == 1)
    precondition(flags != BE_KEVENT_NO_FLAGS)
    precondition(type(of: BE_KEVENT_RETURN_IMMEDIATELY) == Int32.self)
}
