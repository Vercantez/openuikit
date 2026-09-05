import CoreTelephony
import Foundation

func testErrorDomainConstants() {
    precondition(kCTErrorDomainNoError == 0)
    precondition(kCTErrorDomainPOSIX == 1)
    precondition(kCTErrorDomainMach == 2)
    precondition(kCTErrorDomainNoError != kCTErrorDomainPOSIX)
    precondition(kCTErrorDomainPOSIX != kCTErrorDomainMach)
}

func testCTErrorStructure() {
    let zero = CTError()
    precondition(zero.domain == Int32(kCTErrorDomainNoError))
    precondition(zero.error == 0)

    var err = CTError(domain: Int32(kCTErrorDomainPOSIX), error: 2)
    precondition(err.domain == Int32(kCTErrorDomainPOSIX))
    precondition(err.error == 2)
    err.domain = Int32(kCTErrorDomainMach)
    err.error = 9
    precondition(err.domain == Int32(kCTErrorDomainMach))
    precondition(err.error == 9)
}
