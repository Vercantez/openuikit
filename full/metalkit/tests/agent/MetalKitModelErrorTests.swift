import Foundation
import MetalKit

func testModelErrorDomainAndKey() {
    precondition(MTKModelError.domain.rawValue == "MTKModelErrorDomain")
    precondition(MTKModelError.key.rawValue == "MTKModelErrorKey")
    precondition(MTKModelError.domain != MTKModelError.key)
}

func testModelErrorRawValueInit() {
    let custom = MTKModelError(rawValue: "custom.model.error")
    precondition(custom.rawValue == "custom.model.error")
    precondition(MTKModelError(rawValue: "MTKModelErrorDomain") == MTKModelError.domain)
}

func testModelErrorInequality() {
    precondition(MTKModelError.domain != MTKModelError.key)
    precondition(!(MTKModelError.domain != MTKModelError.domain))
}

func testModelErrorHashValue() {
    precondition(MTKModelError.domain.hashValue == MTKModelError(rawValue: "MTKModelErrorDomain").hashValue)
    precondition(MTKModelError.domain.hashValue != MTKModelError.key.hashValue)
}

func testModelErrorHashInto() {
    var hasher = Hasher()
    MTKModelError.domain.hash(into: &hasher)
    let first = hasher.finalize()
    var hasher2 = Hasher()
    MTKModelError.domain.hash(into: &hasher2)
    precondition(first == hasher2.finalize())
}
