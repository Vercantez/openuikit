#if canImport(Glibc)
import Glibc
#endif
import BrowserEngineCore
import Foundation

func testBeKeventFailsClosed() {
    var change = kevent(ident: 7, filter: -1, flags: 1, fflags: 0, data: 42, udata: nil)
    var event = kevent(ident: 99, filter: 5, flags: 8, fflags: 3, data: 11, udata: nil)
    let before = event
    let rc = withUnsafePointer(to: &change) { changePointer in
        withUnsafeMutablePointer(to: &event) { eventPointer in
            be_kevent(
                3,
                changePointer,
                1,
                eventPointer,
                1,
                UInt32(bitPattern: BE_KEVENT_NO_FLAGS)
            )
        }
    }
    precondition(rc == -1)
    #if canImport(Glibc)
    precondition(errno == ENOSYS)
    #endif
    precondition(event == before)
    precondition(event.ident == 99)
    precondition(event.data == 11)
}

func testBeKevent64FailsClosed() {
    var change = kevent64_s(
        ident: 8,
        filter: -1,
        flags: 1,
        fflags: 0,
        data: 64,
        udata: 12,
        ext: (1, 2)
    )
    var event = kevent64_s(
        ident: 100,
        filter: 4,
        flags: 9,
        fflags: 2,
        data: 33,
        udata: 7,
        ext: (3, 4)
    )
    let before = event
    let rc = withUnsafePointer(to: &change) { changePointer in
        withUnsafeMutablePointer(to: &event) { eventPointer in
            be_kevent64(
                4,
                changePointer,
                1,
                eventPointer,
                1,
                UInt32(bitPattern: BE_KEVENT_RETURN_IMMEDIATELY)
            )
        }
    }
    precondition(rc == -1)
    #if canImport(Glibc)
    precondition(errno == ENOSYS)
    #endif
    precondition(event == before)
    precondition(event.ident == 100)
    precondition(event.ext.0 == 3)
    precondition(event.ext.1 == 4)
}
