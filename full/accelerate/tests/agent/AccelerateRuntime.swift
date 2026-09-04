import Accelerate
import Foundation

// Optional schema-v1-style runtime probe. The sealed schema-v2 host gate compiles
// tests/agent/*Tests.swift plus AccelerateLoadSmoke.swift and emits the marker
// from generated runner stdout; this file is not part of that isolated compile.

func accelerateAgentRuntimeProbe() {
    precondition(kvImageNoError == 0)
    precondition(vDSP.add([Float(1), 2], [Float(3), 4]) == [4, 6])
    var params = BNNSLayerParametersActivation()
    precondition(BNNSFilterCreateLayerActivation(&params, nil) == nil)
}
