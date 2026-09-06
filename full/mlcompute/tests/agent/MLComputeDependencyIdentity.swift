import Foundation
import MLCompute

func mlcomputeDependencyIdentityProbe() {
    let payload = Data([0, 1, 2, 3, 4, 5, 6, 7])
    let tensorData = MLCTensorData(linuxCopying: payload)
    precondition(tensorData.length == payload.count)
    let number = NSNumber(value: Float(2.5))
    let tensor = MLCTensor(shape: [2, 2], fillWithData: number, dataType: .float32)
    precondition(tensor.descriptor.dataType == .float32)
    precondition(tensor.data?.count == 16)
    let error = MLComputeError.executeFailed("dependency identity").nsError
    precondition(error.domain == MLComputeErrorDomain)
    precondition(error.userInfo[NSLocalizedDescriptionKey] is String)
}
