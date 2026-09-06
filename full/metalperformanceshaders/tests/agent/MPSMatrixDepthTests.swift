import Foundation
import MetalPerformanceShaders

func testMPSMatrixExactStridesAndTransposeGEMM() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    // 2x2 float32 with rowBytes=16 (two padding floats per row)
    let desc = MPSMatrixDescriptor(rows: 2, columns: 2, rowBytes: 16, dataType: .float32)
    precondition(desc.rowBytes == 16)
    precondition(MPSMatrixDescriptor.rowBytes(forColumns: 2, dataType: .float32) == 8)
    let left = MPSMatrix(device: device, descriptor: desc)
    let right = MPSMatrix(device: device, descriptor: desc)
    let result = MPSMatrix(device: device, descriptor: desc)
    let lp = left.data.contents.bindMemory(to: Float.self, capacity: 8)
    let rp = right.data.contents.bindMemory(to: Float.self, capacity: 8)
    let cp = result.data.contents.bindMemory(to: Float.self, capacity: 8)
    // row-major with stride 4 floats: [1, 2, pad, pad, 3, 4, pad, pad]
    lp[0] = 1; lp[1] = 2; lp[2] = 99; lp[3] = 99
    lp[4] = 3; lp[5] = 4; lp[6] = 99; lp[7] = 99
    rp[0] = 5; rp[1] = 6; rp[2] = 88; rp[3] = 88
    rp[4] = 7; rp[5] = 8; rp[6] = 88; rp[7] = 88
    cp[0] = 1; cp[1] = 1; cp[4] = 1; cp[5] = 1
    let gemm = MPSMatrixMultiplication(
        device: device,
        transposeLeft: false,
        transposeRight: false,
        resultRows: 2,
        resultColumns: 2,
        interiorColumns: 2,
        alpha: 1,
        beta: 1
    )
    gemm.encode(commandBuffer: cmd, leftMatrix: left, rightMatrix: right, resultMatrix: result)
    // A*B = [19, 22; 43, 50] plus beta*C ones → [20, 23; 44, 51]
    precondition(abs(cp[0] - 20) < 0.001)
    precondition(abs(cp[1] - 23) < 0.001)
    precondition(abs(cp[4] - 44) < 0.001)
    precondition(abs(cp[5] - 51) < 0.001)

    let tDesc = MPSMatrixDescriptor(rows: 2, columns: 2, rowBytes: 8, dataType: .float32)
    let a = MPSMatrix(device: device, descriptor: tDesc)
    let b = MPSMatrix(device: device, descriptor: tDesc)
    let c = MPSMatrix(device: device, descriptor: tDesc)
    let ap = a.data.contents.bindMemory(to: Float.self, capacity: 4)
    let bp = b.data.contents.bindMemory(to: Float.self, capacity: 4)
    let out = c.data.contents.bindMemory(to: Float.self, capacity: 4)
    // A = [1, 2; 3, 4], B = [5, 6; 7, 8], compute A * B^T
    ap[0] = 1; ap[1] = 2; ap[2] = 3; ap[3] = 4
    bp[0] = 5; bp[1] = 6; bp[2] = 7; bp[3] = 8
    let gemmT = MPSMatrixMultiplication(
        device: device,
        transposeLeft: false,
        transposeRight: true,
        resultRows: 2,
        resultColumns: 2,
        interiorColumns: 2,
        alpha: 2,
        beta: 0
    )
    gemmT.encode(commandBuffer: cmd, leftMatrix: a, rightMatrix: b, resultMatrix: c)
    // B^T = [5, 7; 6, 8]; A*B^T = [17, 23; 39, 53]; *2 = [34, 46; 78, 106]
    precondition(abs(out[0] - 34) < 0.001)
    precondition(abs(out[1] - 46) < 0.001)
    precondition(abs(out[2] - 78) < 0.001)
    precondition(abs(out[3] - 106) < 0.001)

    let vec = MPSVector(device: device, descriptor: MPSVectorDescriptor(length: 2, dataType: .float32))
    let y = MPSVector(device: device, descriptor: MPSVectorDescriptor(length: 2, dataType: .float32))
    let xp = vec.data.contents.bindMemory(to: Float.self, capacity: 2)
    xp[0] = 1; xp[1] = 1
    let gemv = MPSMatrixVectorMultiplication(device: device, transpose: true, rows: 2, columns: 2, alpha: 1, beta: 0)
    gemv.encode(commandBuffer: cmd, inputMatrix: a, inputVector: vec, resultVector: y)
    let yp = y.data.contents.bindMemory(to: Float.self, capacity: 2)
    // A^T [1,1] = [4, 6]
    precondition(abs(yp[0] - 4) < 0.001)
    precondition(abs(yp[1] - 6) < 0.001)
}

func testMPSMatrixSoftMaxAndFindTopK() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let desc = MPSMatrixDescriptor(rows: 1, columns: 3, rowBytes: 12, dataType: .float32)
    let input = MPSMatrix(device: device, descriptor: desc)
    let output = MPSMatrix(device: device, descriptor: desc)
    let p = input.data.contents.bindMemory(to: Float.self, capacity: 3)
    p[0] = 1; p[1] = 2; p[2] = 3
    let softmax = MPSMatrixSoftMax(device: device)
    softmax.sourceRows = 1
    softmax.sourceColumns = 3
    softmax.encode(commandBuffer: cmd, inputMatrix: input, resultMatrix: output)
    let o = output.data.contents.bindMemory(to: Float.self, capacity: 3)
    let e1 = exp(Float(1 - 3))
    let e2 = exp(Float(2 - 3))
    let e3 = exp(Float(0))
    let sum = e1 + e2 + e3
    precondition(abs(o[0] - e1 / sum) < 0.0001)
    precondition(abs(o[1] - e2 / sum) < 0.0001)
    precondition(abs(o[2] - e3 / sum) < 0.0001)
    let copied = softmax.copy(with: nil, device: device)
    precondition(copied.sourceColumns == 3)
    precondition(MPSMatrixSoftMax(coder: NSCoder(), device: device) == nil)

    let idxDesc = MPSMatrixDescriptor(rows: 1, columns: 2, rowBytes: 8, dataType: .uInt32)
    let valDesc = MPSMatrixDescriptor(rows: 1, columns: 2, rowBytes: 8, dataType: .float32)
    let indices = MPSMatrix(device: device, descriptor: idxDesc)
    let values = MPSMatrix(device: device, descriptor: valDesc)
    let topk = MPSMatrixFindTopK(device: device, numberOfTopKValues: 2)
    topk.sourceRows = 1
    topk.sourceColumns = 3
    topk.indexOffset = 10
    topk.encode(
        commandBuffer: cmd,
        inputMatrix: input,
        resultIndexMatrix: indices,
        resultValueMatrix: values
    )
    let vp = values.data.contents.bindMemory(to: Float.self, capacity: 2)
    let ip = indices.data.contents.bindMemory(to: UInt32.self, capacity: 2)
    precondition(abs(vp[0] - 3) < 0.001 && abs(vp[1] - 2) < 0.001)
    precondition(ip[0] == 12 && ip[1] == 11)
    let topCopy = topk.copy(with: nil, device: device)
    precondition(topCopy.numberOfTopKValues == 2)
    precondition(MPSMatrixFindTopK(coder: NSCoder(), device: device) == nil)
}

func testMPSMatrixSum() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let desc = MPSMatrixDescriptor(rows: 2, columns: 2, rowBytes: 8, dataType: .float32)
    let a = MPSMatrix(device: device, descriptor: desc)
    let b = MPSMatrix(device: device, descriptor: desc)
    let result = MPSMatrix(device: device, descriptor: desc)
    let ap = a.data.contents.bindMemory(to: Float.self, capacity: 4)
    let bp = b.data.contents.bindMemory(to: Float.self, capacity: 4)
    ap[0] = 1; ap[1] = 2; ap[2] = 3; ap[3] = 4
    bp[0] = 10; bp[1] = 20; bp[2] = 30; bp[3] = 40
    let sum = MPSMatrixSum(device: device, count: 2, rows: 2, columns: 2, transpose: false)
    precondition(sum.count == 2 && sum.rows == 2 && sum.columns == 2)
    precondition(!sum.transpose)
    sum.resultMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    sum.setNeuronType(.none, parameterA: 0, parameterB: 0, parameterC: 0)
    precondition(sum.neuronType() == .none)
    precondition(sum.neuronParameterA == 0 && sum.neuronParameterB == 0 && sum.neuronParameterC == 0)
    let scale = MPSVector(device: device, descriptor: MPSVectorDescriptor(length: 2, dataType: .float32))
    let sp = scale.data.contents.bindMemory(to: Float.self, capacity: 2)
    sp[0] = 1; sp[1] = 0.5
    sum.encode(
        commandBuffer: cmd,
        sourceMatrices: [a, b],
        resultMatrix: result,
        scaleVector: scale,
        offsetVector: nil,
        biasVector: nil,
        startIndex: 0
    )
    let rp = result.data.contents.bindMemory(to: Float.self, capacity: 4)
    // 1*[1,2;3,4] + 0.5*[10,20;30,40] = [6, 12; 18, 24]
    precondition(abs(rp[0] - 6) < 0.001)
    precondition(abs(rp[1] - 12) < 0.001)
    precondition(abs(rp[2] - 18) < 0.001)
    precondition(abs(rp[3] - 24) < 0.001)
    _ = MPSMatrixSum(device: device)
    precondition(MPSMatrixSum(coder: NSCoder(), device: device) == nil)
}
