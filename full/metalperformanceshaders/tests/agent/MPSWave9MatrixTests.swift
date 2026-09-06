import Foundation
import MetalPerformanceShaders

func mpsWave9Matrix(_ device: MPSHostDevice, rows: Int, columns: Int, values: [Float]) -> MPSMatrix {
    let desc = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * 4, dataType: .float32)
    let matrix = MPSMatrix(device: device, descriptor: desc)
    let pointer = matrix.data.contents.bindMemory(to: Float.self, capacity: values.count)
    for index in 0..<values.count { pointer[index] = values[index] }
    return matrix
}

func mpsWave9Vector(_ device: MPSHostDevice, values: [Float]) -> MPSVector {
    let vector = MPSVector(device: device, descriptor: MPSVectorDescriptor(length: values.count, dataType: .float32))
    let pointer = vector.data.contents.bindMemory(to: Float.self, capacity: values.count)
    for index in 0..<values.count { pointer[index] = values[index] }
    return vector
}

func mpsWave9Read(_ matrix: MPSMatrix, count: Int) -> [Float] {
    let pointer = matrix.data.contents.bindMemory(to: Float.self, capacity: count)
    return (0..<count).map { pointer[$0] }
}

func testMPSMatrixNeuronHost() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let neuron = MPSMatrixNeuron(device: device)
    neuron.sourceNumberOfFeatureVectors = 2
    neuron.sourceInputFeatureChannels = 2
    neuron.alpha = 1
    neuron.setNeuronType(.reLU, parameterA: 0.1, parameterB: 0, parameterC: 0)
    precondition(neuron.neuronType() == .reLU)
    precondition(neuron.neuronParameterA() == 0.1)
    precondition(neuron.neuronParameterB() == 0)
    precondition(neuron.neuronParameterC() == 0)
    var prelu = Float(0.25)
    neuron.setNeuronToPReLUWithParametersA(Data(bytes: &prelu, count: 4))
    precondition(neuron.neuronType() == .pReLU)
    neuron.setNeuronType(.reLU, parameterA: 0, parameterB: 0, parameterC: 0)
    let input = mpsWave9Matrix(device, rows: 2, columns: 2, values: [-2, 3, 4, -5])
    let bias = mpsWave9Vector(device, values: [1, -1])
    let result = mpsWave9Matrix(device, rows: 2, columns: 2, values: [0, 0, 0, 0])
    neuron.encode(commandBuffer: cmd, inputMatrix: input, biasVector: bias, resultMatrix: result)
    // [-2+1, 3-1; 4+1, -5-1] = [-1, 2; 5, -6] ReLU → [0, 2; 5, 0]
    let out = mpsWave9Read(result, count: 4)
    precondition(abs(out[0] - 0) < 1e-5 && abs(out[1] - 2) < 1e-5)
    precondition(abs(out[2] - 5) < 1e-5 && abs(out[3] - 0) < 1e-5)
    let copied = neuron.copy(with: nil, device: device)
    precondition(copied.neuronType() == .reLU)
    precondition(MPSMatrixNeuron(coder: NSCoder(), device: device) == nil)

    let grad = MPSMatrixNeuronGradient(device: device)
    grad.sourceNumberOfFeatureVectors = 2
    grad.sourceInputFeatureChannels = 2
    grad.alpha = 1
    grad.setNeuronType(.reLU, parameterA: 0, parameterB: 0, parameterC: 0)
    precondition(grad.neuronType() == .reLU)
    precondition(grad.neuronParameterA() == 0)
    var leak = Float(0.1)
    grad.setNeuronToPReLUWithParametersA(Data(bytes: &leak, count: 4))
    grad.setNeuronType(.reLU, parameterA: 0, parameterB: 0, parameterC: 0)
    let dY = mpsWave9Matrix(device, rows: 2, columns: 2, values: [1, 1, 1, 1])
    let dX = mpsWave9Matrix(device, rows: 2, columns: 2, values: [9, 9, 9, 9])
    let dB = mpsWave9Vector(device, values: [0, 0])
    grad.encode(
        to: cmd,
        gradientMatrix: dY,
        inputMatrix: input,
        biasVector: bias,
        resultGradientForDataMatrix: dX,
        resultGradientForBiasVector: dB
    )
    // pre = [-1, 2; 5, -6]; ReLU' = [0, 1; 1, 0]; dX = dY * deriv; dB = [0+1, 1+0] = [1, 1]
    let dx = mpsWave9Read(dX, count: 4)
    let db = dB.data.contents.bindMemory(to: Float.self, capacity: 2)
    precondition(abs(dx[0] - 0) < 1e-5 && abs(dx[1] - 1) < 1e-5)
    precondition(abs(dx[2] - 1) < 1e-5 && abs(dx[3] - 0) < 1e-5)
    precondition(abs(db[0] - 1) < 1e-5 && abs(db[1] - 1) < 1e-5)
    _ = grad.copy(with: nil, device: device)
    precondition(MPSMatrixNeuronGradient(coder: NSCoder(), device: device) == nil)
    _ = grad.neuronParameterB()
    _ = grad.neuronParameterC()
}

func testMPSMatrixFullyConnectedHost() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let fc = MPSMatrixFullyConnected(device: device)
    fc.sourceNumberOfFeatureVectors = 2
    fc.sourceInputFeatureChannels = 2
    fc.sourceOutputFeatureChannels = 2
    fc.alpha = 1
    fc.setNeuronType(.none, parameterA: 0, parameterB: 0, parameterC: 0)
    precondition(fc.neuronType() == .none)
    precondition(fc.neuronParameterA() == 0 && fc.neuronParameterB() == 0 && fc.neuronParameterC() == 0)
    // X = [[1, 2], [3, 4]], W = [[1, 0], [0, 1]], B = [1, -1]
    // Y = XW + B = [[2, 1], [4, 3]]
    let x = mpsWave9Matrix(device, rows: 2, columns: 2, values: [1, 2, 3, 4])
    let w = mpsWave9Matrix(device, rows: 2, columns: 2, values: [1, 0, 0, 1])
    let b = mpsWave9Vector(device, values: [1, -1])
    let y = mpsWave9Matrix(device, rows: 2, columns: 2, values: [0, 0, 0, 0])
    fc.encode(commandBuffer: cmd, inputMatrix: x, weightMatrix: w, biasVector: b, resultMatrix: y)
    let yo = mpsWave9Read(y, count: 4)
    precondition(abs(yo[0] - 2) < 1e-5 && abs(yo[1] - 1) < 1e-5)
    precondition(abs(yo[2] - 4) < 1e-5 && abs(yo[3] - 3) < 1e-5)
    _ = fc.copy(with: nil, device: device)
    precondition(MPSMatrixFullyConnected(coder: NSCoder(), device: device) == nil)

    let gfc = MPSMatrixFullyConnectedGradient(device: device)
    gfc.sourceNumberOfFeatureVectors = 2
    gfc.sourceInputFeatureChannels = 2
    gfc.sourceOutputFeatureChannels = 2
    gfc.alpha = 1
    let dy = mpsWave9Matrix(device, rows: 2, columns: 2, values: [1, 0, 0, 1])
    let dx = mpsWave9Matrix(device, rows: 2, columns: 2, values: [0, 0, 0, 0])
    gfc.encodeForData(to: cmd, gradientMatrix: dy, weightMatrix: w, resultGradientForDataMatrix: dx)
    // dX = dY * W^T = dY (W=I) = [[1, 0], [0, 1]]
    let dxo = mpsWave9Read(dx, count: 4)
    precondition(abs(dxo[0] - 1) < 1e-5 && abs(dxo[1] - 0) < 1e-5)
    precondition(abs(dxo[2] - 0) < 1e-5 && abs(dxo[3] - 1) < 1e-5)
    let dw = mpsWave9Matrix(device, rows: 2, columns: 2, values: [0, 0, 0, 0])
    let db = mpsWave9Vector(device, values: [0, 0])
    gfc.encodeForWeightsAndBias(
        to: cmd,
        gradientMatrix: dy,
        inputMatrix: x,
        resultGradientForWeightMatrix: dw,
        resultGradientForBiasVector: db
    )
    // dW = X^T * dY; X^T=[[1,3],[2,4]]; dY=[[1,0],[0,1]] → [[1, 3], [2, 4]]
    let dwo = mpsWave9Read(dw, count: 4)
    precondition(abs(dwo[0] - 1) < 1e-5 && abs(dwo[1] - 3) < 1e-5)
    precondition(abs(dwo[2] - 2) < 1e-5 && abs(dwo[3] - 4) < 1e-5)
    let dbo = db.data.contents.bindMemory(to: Float.self, capacity: 2)
    precondition(abs(dbo[0] - 1) < 1e-5 && abs(dbo[1] - 1) < 1e-5)
    _ = gfc.copy(with: nil, device: device)
    precondition(MPSMatrixFullyConnectedGradient(coder: NSCoder(), device: device) == nil)
}

func testMPSMatrixBatchNormalizationHost() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let bn = MPSMatrixBatchNormalization(device: device)
    bn.sourceNumberOfFeatureVectors = 2
    bn.sourceInputFeatureChannels = 2
    bn.computeStatistics = true
    bn.epsilon = 0
    bn.setNeuronType(.none, parameterA: 0, parameterB: 0, parameterC: 0)
    precondition(bn.neuronType() == .none)
    precondition(bn.neuronParameterA() == 0 && bn.neuronParameterB() == 0 && bn.neuronParameterC() == 0)
    // channel0: 1,3 mean=2 var=1; channel1: 3,5 mean=4 var=1
    let input = mpsWave9Matrix(device, rows: 2, columns: 2, values: [1, 3, 3, 5])
    let mean = mpsWave9Vector(device, values: [0, 0])
    let variance = mpsWave9Vector(device, values: [0, 0])
    let gamma = mpsWave9Vector(device, values: [1, 1])
    let beta = mpsWave9Vector(device, values: [0, 0])
    let result = mpsWave9Matrix(device, rows: 2, columns: 2, values: [0, 0, 0, 0])
    bn.encode(
        commandBuffer: cmd,
        inputMatrix: input,
        meanVector: mean,
        varianceVector: variance,
        gammaVector: gamma,
        betaVector: beta,
        resultMatrix: result
    )
    let yo = mpsWave9Read(result, count: 4)
    precondition(abs(yo[0] + 1) < 1e-5 && abs(yo[1] + 1) < 1e-5)
    precondition(abs(yo[2] - 1) < 1e-5 && abs(yo[3] - 1) < 1e-5)
    let meanP = mean.data.contents.bindMemory(to: Float.self, capacity: 2)
    precondition(abs(meanP[0] - 2) < 1e-5 && abs(meanP[1] - 4) < 1e-5)
    _ = bn.copy(with: nil, device: device)
    precondition(MPSMatrixBatchNormalization(coder: NSCoder(), device: device) == nil)

    let gbn = MPSMatrixBatchNormalizationGradient(device: device)
    gbn.sourceNumberOfFeatureVectors = 2
    gbn.sourceInputFeatureChannels = 2
    gbn.epsilon = 0
    gbn.setNeuronType(.none, parameterA: 0, parameterB: 0, parameterC: 0)
    precondition(gbn.neuronType() == .none)
    precondition(gbn.neuronParameterA() == 0 && gbn.neuronParameterB() == 0 && gbn.neuronParameterC() == 0)
    let dy = mpsWave9Matrix(device, rows: 2, columns: 2, values: [1, 1, 1, 1])
    let dx = mpsWave9Matrix(device, rows: 2, columns: 2, values: [0, 0, 0, 0])
    let dgamma = mpsWave9Vector(device, values: [0, 0])
    let dbeta = mpsWave9Vector(device, values: [0, 0])
    gbn.encode(
        to: cmd,
        gradientMatrix: dy,
        inputMatrix: input,
        mean: mean,
        varianceVector: variance,
        gammaVector: gamma,
        betaVector: beta,
        resultGradientForDataMatrix: dx,
        resultGradientForGammaVector: dgamma,
        resultGradientForBetaVector: dbeta
    )
    // xhat = [-1,-1; 1,1]; dbeta = [2,2]; dgamma = sum dy*xhat = [0,0]
    let dbp = dbeta.data.contents.bindMemory(to: Float.self, capacity: 2)
    let dgp = dgamma.data.contents.bindMemory(to: Float.self, capacity: 2)
    precondition(abs(dbp[0] - 2) < 1e-4 && abs(dbp[1] - 2) < 1e-4)
    precondition(abs(dgp[0]) < 1e-4 && abs(dgp[1]) < 1e-4)
    _ = gbn.copy(with: nil, device: device)
    precondition(MPSMatrixBatchNormalizationGradient(coder: NSCoder(), device: device) == nil)
}

func testMPSMatrixSoftMaxGradientAndRandom() {
    let device = MPSHostDevice.shared
    let cmd = device.makeCommandBuffer()
    let y = mpsWave9Matrix(device, rows: 1, columns: 2, values: [0.25, 0.75])
    let g = mpsWave9Matrix(device, rows: 1, columns: 2, values: [1, 0])
    let dx = mpsWave9Matrix(device, rows: 1, columns: 2, values: [0, 0])
    let soft = MPSMatrixSoftMaxGradient(device: device)
    soft.sourceRows = 1
    soft.sourceColumns = 2
    soft.encode(to: cmd, gradientMatrix: g, forwardOutputMatrix: y, resultMatrix: dx)
    // dot = 0.25; dx = y * (g - dot) = [0.25*0.75, 0.75*(-0.25)] = [0.1875, -0.1875]
    let out = mpsWave9Read(dx, count: 2)
    precondition(abs(out[0] - 0.1875) < 1e-5)
    precondition(abs(out[1] + 0.1875) < 1e-5)
    _ = soft.copy(with: nil, device: device)
    precondition(MPSMatrixSoftMaxGradient(coder: NSCoder(), device: device) == nil)

    let uniform = MPSMatrixRandomDistributionDescriptor.uniformDistributionDescriptor(withMinimum: -1, maximum: 1)
    precondition(uniform.distributionType.contains(.uniform))
    precondition(uniform.minimum == -1 && uniform.maximum == 1)
    let normal = MPSMatrixRandomDistributionDescriptor.normalDistributionDescriptor(withMean: 0, standardDeviation: 1)
    precondition(normal.distributionType.contains(.normal))
    precondition(normal.mean == 0 && normal.standardDeviation == 1)
    let clipped = MPSMatrixRandomDistributionDescriptor.normalDistributionDescriptor(
        withMean: 0,
        standardDeviation: 1,
        minimum: -2,
        maximum: 2
    )
    precondition(clipped.minimum == -2 && clipped.maximum == 2)
    let def = MPSMatrixRandomDistributionDescriptor.default()
    precondition(def.minimum == 0 && def.maximum == 1)
    _ = MPSMatrixRandomDistributionDescriptor()

    let mt = MPSMatrixRandomMTGP32(device: device, destinationDataType: .float32, seed: 7, distributionDescriptor: uniform)
    precondition(mt.destinationDataType == .float32)
    precondition(mt.distributionType.contains(.uniform))
    mt.batchSize = 1
    mt.batchStart = 0
    let dest = mpsWave9Matrix(device, rows: 2, columns: 2, values: [0, 0, 0, 0])
    mt.encode(commandBuffer: cmd, destinationMatrix: dest)
    let samples = mpsWave9Read(dest, count: 4)
    for sample in samples {
        precondition(sample >= -1 && sample <= 1)
    }
    let vec = mpsWave9Vector(device, values: [0, 0])
    mt.encode(commandBuffer: cmd, destinationVector: vec)
    mt.synchronizeState(on: cmd)
    _ = MPSMatrixRandomMTGP32(device: device)
    _ = MPSMatrixRandomMTGP32(device: device, destinationDataType: .float32, seed: 1)
    precondition(MPSMatrixRandomMTGP32(coder: NSCoder(), device: device) == nil)
    let philox = MPSMatrixRandomPhilox(device: device, destinationDataType: .float32, seed: 3, distributionDescriptor: def)
    philox.encode(commandBuffer: cmd, destinationMatrix: dest)
    _ = MPSMatrixRandomPhilox(device: device)
    _ = MPSMatrixRandomPhilox(device: device, destinationDataType: .uInt32, seed: 2)
    precondition(MPSMatrixRandomPhilox(coder: NSCoder(), device: device) == nil)
    let base = MPSMatrixRandom(device: device)
    precondition(base.destinationDataType == .float32)
    precondition(MPSMatrixRandom(coder: NSCoder(), device: device) == nil)
}
