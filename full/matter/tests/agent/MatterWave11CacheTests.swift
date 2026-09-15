import Foundation
import Dispatch
import Matter

func testAttributeCacheContainerReadWave11() {
    let container = MTRAttributeCacheContainer()
    container.readAttribute(
        withEndpointId: n(1), clusterId: n(6), attributeId: n(0),
        clientQueue: DispatchQueue.global(),
        completion: { values, err in
            mtrRequire(values == nil, "no values without a fabric")
            mtrExpectInvalidState(err)
        }
    )
}
