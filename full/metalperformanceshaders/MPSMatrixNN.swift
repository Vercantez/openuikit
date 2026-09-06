import Foundation

func mpsApplyNeuron(_ type: MPSCNNNeuronType, _ value: Float, a: Float, b: Float, c: Float) -> Float {
    switch type {
    case .reLU:
        return value < 0 ? a * value : value
    case .linear:
        return a * value + b
    case .sigmoid:
        return 1 / (1 + exp(-value))
    case .hardSigmoid:
        let y = a * value + b
        return min(max(y, 0), 1)
    case .tanH:
        return a * tanh(b * value)
    case .absolute:
        return abs(value)
    case .softPlus:
        return a * log(1 + exp(value))
    case .softSign:
        return value / (1 + abs(value))
    case .ELU:
        return value < 0 ? a * (exp(value) - 1) : value
    case .pReLU:
        return value < 0 ? a * value : value
    case .reLUN:
        return min(max(value, 0), a)
    case .power:
        return a * pow(b * value + c, a)
    case .exponential:
        return a * exp(b * value + c)
    case .logarithm:
        return a * log(b * value + c)
    case .geLU:
        return 0.5 * value * (1 + tanh(0.7978845608 * (value + 0.044715 * value * value * value)))
    default:
        return value
    }
}

func mpsNeuronDerivative(_ type: MPSCNNNeuronType, _ value: Float, a: Float, b: Float, c: Float) -> Float {
    _ = c
    switch type {
    case .reLU, .pReLU:
        return value < 0 ? a : 1
    case .linear:
        return a
    case .sigmoid:
        let y = mpsApplyNeuron(.sigmoid, value, a: a, b: b, c: 0)
        return y * (1 - y)
    case .tanH:
        let y = tanh(b * value)
        return a * b * (1 - y * y)
    case .absolute:
        return value < 0 ? -1 : 1
    default:
        return 1
    }
}

open class MPSMatrixNeuron: MPSKernel {
    public var alpha: Double = 1
    public var sourceInputFeatureChannels: Int = 1
    public var sourceNumberOfFeatureVectors: Int = 1
    private var neuron: MPSCNNNeuronType = .none
    private var neuronA: Float = 0
    private var neuronB: Float = 0
    private var neuronC: Float = 0
    private var preluA: Data?

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func neuronType() -> MPSCNNNeuronType { neuron }
    open func neuronParameterA() -> Float { neuronA }
    open func neuronParameterB() -> Float { neuronB }
    open func neuronParameterC() -> Float { neuronC }

    open func setNeuronType(_ neuronType: MPSCNNNeuronType, parameterA: Float, parameterB: Float, parameterC: Float) {
        neuron = neuronType
        neuronA = parameterA
        neuronB = parameterB
        neuronC = parameterC
    }

    open func setNeuronToPReLUWithParametersA(_ A: Data) {
        preluA = A
        neuron = .pReLU
        if A.count >= 4 {
            neuronA = A.withUnsafeBytes { $0.load(as: Float.self) }
        }
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixNeuron(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.alpha = alpha
        copied.sourceInputFeatureChannels = sourceInputFeatureChannels
        copied.sourceNumberOfFeatureVectors = sourceNumberOfFeatureVectors
        copied.setNeuronType(neuron, parameterA: neuronA, parameterB: neuronB, parameterC: neuronC)
        copied.preluA = preluA
        return copied as! Self
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputMatrix: MPSMatrix,
        biasVector: MPSVector?,
        resultMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard inputMatrix.dataType == .float32, resultMatrix.dataType == .float32 else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixNeuron.encode")
            return
        }
        let rows = sourceNumberOfFeatureVectors > 0 ? sourceNumberOfFeatureVectors : inputMatrix.rows
        let cols = sourceInputFeatureChannels > 0 ? sourceInputFeatureChannels : inputMatrix.columns
        let a = mpsFloatBuffer(inputMatrix.data, offset: inputMatrix.offset)
        let c = mpsFloatBuffer(resultMatrix.data, offset: resultMatrix.offset)
        let lda = max(inputMatrix.rowBytes / 4, 1)
        let ldc = max(resultMatrix.rowBytes / 4, 1)
        let bias = biasVector.flatMap { vector -> UnsafeMutablePointer<Float>? in
            guard vector.dataType == .float32 else { return nil }
            return mpsFloatBuffer(vector.data, offset: vector.offset)
        }
        let scale = Float(alpha)
        for row in 0..<rows {
            for col in 0..<cols {
                var value = scale * a[row * lda + col]
                if let bias {
                    value += bias[col]
                }
                c[row * ldc + col] = mpsApplyNeuron(neuron, value, a: neuronA, b: neuronB, c: neuronC)
            }
        }
    }
}

open class MPSMatrixNeuronGradient: MPSKernel {
    public var alpha: Double = 1
    public var sourceInputFeatureChannels: Int = 1
    public var sourceNumberOfFeatureVectors: Int = 1
    private var neuron: MPSCNNNeuronType = .none
    private var neuronA: Float = 0
    private var neuronB: Float = 0
    private var neuronC: Float = 0
    private var preluA: Data?

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func neuronType() -> MPSCNNNeuronType { neuron }
    open func neuronParameterA() -> Float { neuronA }
    open func neuronParameterB() -> Float { neuronB }
    open func neuronParameterC() -> Float { neuronC }

    open func setNeuronType(_ neuronType: MPSCNNNeuronType, parameterA: Float, parameterB: Float, parameterC: Float) {
        neuron = neuronType
        neuronA = parameterA
        neuronB = parameterB
        neuronC = parameterC
    }

    open func setNeuronToPReLUWithParametersA(_ A: Data) {
        preluA = A
        neuron = .pReLU
        if A.count >= 4 {
            neuronA = A.withUnsafeBytes { $0.load(as: Float.self) }
        }
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixNeuronGradient(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.alpha = alpha
        copied.sourceInputFeatureChannels = sourceInputFeatureChannels
        copied.sourceNumberOfFeatureVectors = sourceNumberOfFeatureVectors
        copied.setNeuronType(neuron, parameterA: neuronA, parameterB: neuronB, parameterC: neuronC)
        copied.preluA = preluA
        return copied as! Self
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        gradientMatrix: MPSMatrix,
        inputMatrix: MPSMatrix,
        biasVector: MPSVector?,
        resultGradientForDataMatrix: MPSMatrix,
        resultGradientForBiasVector: MPSVector?
    ) {
        _ = commandBuffer
        guard gradientMatrix.dataType == .float32,
              inputMatrix.dataType == .float32,
              resultGradientForDataMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixNeuronGradient.encode")
            return
        }
        let rows = sourceNumberOfFeatureVectors > 0 ? sourceNumberOfFeatureVectors : inputMatrix.rows
        let cols = sourceInputFeatureChannels > 0 ? sourceInputFeatureChannels : inputMatrix.columns
        let g = mpsFloatBuffer(gradientMatrix.data, offset: gradientMatrix.offset)
        let x = mpsFloatBuffer(inputMatrix.data, offset: inputMatrix.offset)
        let dx = mpsFloatBuffer(resultGradientForDataMatrix.data, offset: resultGradientForDataMatrix.offset)
        let ldg = max(gradientMatrix.rowBytes / 4, 1)
        let ldx = max(inputMatrix.rowBytes / 4, 1)
        let ldd = max(resultGradientForDataMatrix.rowBytes / 4, 1)
        let bias = biasVector.flatMap { vector -> UnsafeMutablePointer<Float>? in
            guard vector.dataType == .float32 else { return nil }
            return mpsFloatBuffer(vector.data, offset: vector.offset)
        }
        let db = resultGradientForBiasVector.flatMap { vector -> UnsafeMutablePointer<Float>? in
            guard vector.dataType == .float32 else { return nil }
            return mpsFloatBuffer(vector.data, offset: vector.offset)
        }
        if let db {
            for col in 0..<cols { db[col] = 0 }
        }
        let scale = Float(alpha)
        for row in 0..<rows {
            for col in 0..<cols {
                var pre = scale * x[row * ldx + col]
                if let bias {
                    pre += bias[col]
                }
                let deriv = mpsNeuronDerivative(neuron, pre, a: neuronA, b: neuronB, c: neuronC)
                let grad = g[row * ldg + col] * deriv
                dx[row * ldd + col] = scale * grad
                if let db {
                    db[col] += grad
                }
            }
        }
    }
}

open class MPSMatrixFullyConnected: MPSKernel {
    public var alpha: Double = 1
    public var sourceInputFeatureChannels: Int = 1
    public var sourceOutputFeatureChannels: Int = 1
    public var sourceNumberOfFeatureVectors: Int = 1
    private var neuron: MPSCNNNeuronType = .none
    private var neuronA: Float = 0
    private var neuronB: Float = 0
    private var neuronC: Float = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func neuronType() -> MPSCNNNeuronType { neuron }
    open func neuronParameterA() -> Float { neuronA }
    open func neuronParameterB() -> Float { neuronB }
    open func neuronParameterC() -> Float { neuronC }

    open func setNeuronType(_ neuronType: MPSCNNNeuronType, parameterA: Float, parameterB: Float, parameterC: Float) {
        neuron = neuronType
        neuronA = parameterA
        neuronB = parameterB
        neuronC = parameterC
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixFullyConnected(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.alpha = alpha
        copied.sourceInputFeatureChannels = sourceInputFeatureChannels
        copied.sourceOutputFeatureChannels = sourceOutputFeatureChannels
        copied.sourceNumberOfFeatureVectors = sourceNumberOfFeatureVectors
        copied.setNeuronType(neuron, parameterA: neuronA, parameterB: neuronB, parameterC: neuronC)
        return copied as! Self
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputMatrix: MPSMatrix,
        weightMatrix: MPSMatrix,
        biasVector: MPSVector?,
        resultMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard inputMatrix.dataType == .float32,
              weightMatrix.dataType == .float32,
              resultMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixFullyConnected.encode")
            return
        }
        let n = sourceNumberOfFeatureVectors > 0 ? sourceNumberOfFeatureVectors : inputMatrix.rows
        let k = sourceInputFeatureChannels > 0 ? sourceInputFeatureChannels : inputMatrix.columns
        let m = sourceOutputFeatureChannels > 0 ? sourceOutputFeatureChannels : resultMatrix.columns
        mpsGEMM(
            left: inputMatrix,
            right: weightMatrix,
            result: resultMatrix,
            transposeLeft: false,
            transposeRight: false,
            m: n,
            n: m,
            k: k,
            alpha: Float(alpha),
            beta: 0,
            leftOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            rightOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            resultOrigin: MTLOrigin(x: 0, y: 0, z: 0)
        )
        let c = mpsFloatBuffer(resultMatrix.data, offset: resultMatrix.offset)
        let ldc = max(resultMatrix.rowBytes / 4, 1)
        let bias = biasVector.flatMap { vector -> UnsafeMutablePointer<Float>? in
            guard vector.dataType == .float32 else { return nil }
            return mpsFloatBuffer(vector.data, offset: vector.offset)
        }
        for row in 0..<n {
            for col in 0..<m {
                var value = c[row * ldc + col]
                if let bias {
                    value += bias[col]
                }
                c[row * ldc + col] = mpsApplyNeuron(neuron, value, a: neuronA, b: neuronB, c: neuronC)
            }
        }
    }
}

open class MPSMatrixFullyConnectedGradient: MPSKernel {
    public var alpha: Double = 1
    public var sourceInputFeatureChannels: Int = 1
    public var sourceOutputFeatureChannels: Int = 1
    public var sourceNumberOfFeatureVectors: Int = 1

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixFullyConnectedGradient(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.alpha = alpha
        copied.sourceInputFeatureChannels = sourceInputFeatureChannels
        copied.sourceOutputFeatureChannels = sourceOutputFeatureChannels
        copied.sourceNumberOfFeatureVectors = sourceNumberOfFeatureVectors
        return copied as! Self
    }

    open func encodeForData(
        to commandBuffer: any MTLCommandBuffer,
        gradientMatrix: MPSMatrix,
        weightMatrix: MPSMatrix,
        resultGradientForDataMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard gradientMatrix.dataType == .float32,
              weightMatrix.dataType == .float32,
              resultGradientForDataMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixFullyConnectedGradient.encodeForData")
            return
        }
        let n = sourceNumberOfFeatureVectors > 0 ? sourceNumberOfFeatureVectors : gradientMatrix.rows
        let outChannels = sourceOutputFeatureChannels > 0 ? sourceOutputFeatureChannels : gradientMatrix.columns
        let inChannels = sourceInputFeatureChannels > 0 ? sourceInputFeatureChannels : weightMatrix.rows
        mpsGEMM(
            left: gradientMatrix,
            right: weightMatrix,
            result: resultGradientForDataMatrix,
            transposeLeft: false,
            transposeRight: true,
            m: n,
            n: inChannels,
            k: outChannels,
            alpha: Float(alpha),
            beta: 0,
            leftOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            rightOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            resultOrigin: MTLOrigin(x: 0, y: 0, z: 0)
        )
    }

    open func encodeForWeightsAndBias(
        to commandBuffer: any MTLCommandBuffer,
        gradientMatrix: MPSMatrix,
        inputMatrix: MPSMatrix,
        resultGradientForWeightMatrix: MPSMatrix,
        resultGradientForBiasVector: MPSVector?
    ) {
        _ = commandBuffer
        guard gradientMatrix.dataType == .float32,
              inputMatrix.dataType == .float32,
              resultGradientForWeightMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixFullyConnectedGradient.encodeForWeightsAndBias")
            return
        }
        let n = sourceNumberOfFeatureVectors > 0 ? sourceNumberOfFeatureVectors : inputMatrix.rows
        let inChannels = sourceInputFeatureChannels > 0 ? sourceInputFeatureChannels : inputMatrix.columns
        let outChannels = sourceOutputFeatureChannels > 0 ? sourceOutputFeatureChannels : gradientMatrix.columns
        mpsGEMM(
            left: inputMatrix,
            right: gradientMatrix,
            result: resultGradientForWeightMatrix,
            transposeLeft: true,
            transposeRight: false,
            m: inChannels,
            n: outChannels,
            k: n,
            alpha: Float(alpha),
            beta: 0,
            leftOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            rightOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            resultOrigin: MTLOrigin(x: 0, y: 0, z: 0)
        )
        if let resultGradientForBiasVector, resultGradientForBiasVector.dataType == .float32 {
            let g = mpsFloatBuffer(gradientMatrix.data, offset: gradientMatrix.offset)
            let ldg = max(gradientMatrix.rowBytes / 4, 1)
            let db = mpsFloatBuffer(resultGradientForBiasVector.data, offset: resultGradientForBiasVector.offset)
            for col in 0..<outChannels {
                var sum: Float = 0
                for row in 0..<n {
                    sum += g[row * ldg + col]
                }
                db[col] = sum
            }
        }
    }
}

open class MPSMatrixBatchNormalization: MPSKernel {
    public var computeStatistics: Bool = true
    public var epsilon: Float = 1e-5
    public var sourceInputFeatureChannels: Int = 1
    public var sourceNumberOfFeatureVectors: Int = 1
    private var neuron: MPSCNNNeuronType = .none
    private var neuronA: Float = 0
    private var neuronB: Float = 0
    private var neuronC: Float = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func neuronType() -> MPSCNNNeuronType { neuron }
    open func neuronParameterA() -> Float { neuronA }
    open func neuronParameterB() -> Float { neuronB }
    open func neuronParameterC() -> Float { neuronC }

    open func setNeuronType(_ neuronType: MPSCNNNeuronType, parameterA: Float, parameterB: Float, parameterC: Float) {
        neuron = neuronType
        neuronA = parameterA
        neuronB = parameterB
        neuronC = parameterC
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixBatchNormalization(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.computeStatistics = computeStatistics
        copied.epsilon = epsilon
        copied.sourceInputFeatureChannels = sourceInputFeatureChannels
        copied.sourceNumberOfFeatureVectors = sourceNumberOfFeatureVectors
        copied.setNeuronType(neuron, parameterA: neuronA, parameterB: neuronB, parameterC: neuronC)
        return copied as! Self
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputMatrix: MPSMatrix,
        meanVector: MPSVector,
        varianceVector: MPSVector,
        gammaVector: MPSVector?,
        betaVector: MPSVector?,
        resultMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard inputMatrix.dataType == .float32,
              meanVector.dataType == .float32,
              varianceVector.dataType == .float32,
              resultMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixBatchNormalization.encode")
            return
        }
        let rows = sourceNumberOfFeatureVectors > 0 ? sourceNumberOfFeatureVectors : inputMatrix.rows
        let cols = sourceInputFeatureChannels > 0 ? sourceInputFeatureChannels : inputMatrix.columns
        let x = mpsFloatBuffer(inputMatrix.data, offset: inputMatrix.offset)
        let y = mpsFloatBuffer(resultMatrix.data, offset: resultMatrix.offset)
        let mean = mpsFloatBuffer(meanVector.data, offset: meanVector.offset)
        let variance = mpsFloatBuffer(varianceVector.data, offset: varianceVector.offset)
        let ldx = max(inputMatrix.rowBytes / 4, 1)
        let ldy = max(resultMatrix.rowBytes / 4, 1)
        let gamma = gammaVector.flatMap { $0.dataType == .float32 ? mpsFloatBuffer($0.data, offset: $0.offset) : nil }
        let beta = betaVector.flatMap { $0.dataType == .float32 ? mpsFloatBuffer($0.data, offset: $0.offset) : nil }
        if computeStatistics {
            for col in 0..<cols {
                var sum: Float = 0
                for row in 0..<rows {
                    sum += x[row * ldx + col]
                }
                mean[col] = rows > 0 ? sum / Float(rows) : 0
                var varSum: Float = 0
                for row in 0..<rows {
                    let d = x[row * ldx + col] - mean[col]
                    varSum += d * d
                }
                variance[col] = rows > 0 ? varSum / Float(rows) : 0
            }
        }
        for row in 0..<rows {
            for col in 0..<cols {
                let invStd = 1 / sqrt(variance[col] + epsilon)
                var value = (x[row * ldx + col] - mean[col]) * invStd
                if let gamma {
                    value *= gamma[col]
                }
                if let beta {
                    value += beta[col]
                }
                y[row * ldy + col] = mpsApplyNeuron(neuron, value, a: neuronA, b: neuronB, c: neuronC)
            }
        }
    }
}

open class MPSMatrixBatchNormalizationGradient: MPSKernel {
    public var epsilon: Float = 1e-5
    public var sourceInputFeatureChannels: Int = 1
    public var sourceNumberOfFeatureVectors: Int = 1
    private var neuron: MPSCNNNeuronType = .none
    private var neuronA: Float = 0
    private var neuronB: Float = 0
    private var neuronC: Float = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func neuronType() -> MPSCNNNeuronType { neuron }
    open func neuronParameterA() -> Float { neuronA }
    open func neuronParameterB() -> Float { neuronB }
    open func neuronParameterC() -> Float { neuronC }

    open func setNeuronType(_ neuronType: MPSCNNNeuronType, parameterA: Float, parameterB: Float, parameterC: Float) {
        neuron = neuronType
        neuronA = parameterA
        neuronB = parameterB
        neuronC = parameterC
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixBatchNormalizationGradient(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.epsilon = epsilon
        copied.sourceInputFeatureChannels = sourceInputFeatureChannels
        copied.sourceNumberOfFeatureVectors = sourceNumberOfFeatureVectors
        copied.setNeuronType(neuron, parameterA: neuronA, parameterB: neuronB, parameterC: neuronC)
        return copied as! Self
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        gradientMatrix: MPSMatrix,
        inputMatrix: MPSMatrix,
        mean meanVector: MPSVector,
        varianceVector: MPSVector,
        gammaVector: MPSVector?,
        betaVector: MPSVector?,
        resultGradientForDataMatrix: MPSMatrix,
        resultGradientForGammaVector: MPSVector?,
        resultGradientForBetaVector: MPSVector?
    ) {
        _ = commandBuffer
        guard gradientMatrix.dataType == .float32,
              inputMatrix.dataType == .float32,
              meanVector.dataType == .float32,
              varianceVector.dataType == .float32,
              resultGradientForDataMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixBatchNormalizationGradient.encode")
            return
        }
        let rows = sourceNumberOfFeatureVectors > 0 ? sourceNumberOfFeatureVectors : inputMatrix.rows
        let cols = sourceInputFeatureChannels > 0 ? sourceInputFeatureChannels : inputMatrix.columns
        let g = mpsFloatBuffer(gradientMatrix.data, offset: gradientMatrix.offset)
        let x = mpsFloatBuffer(inputMatrix.data, offset: inputMatrix.offset)
        let mean = mpsFloatBuffer(meanVector.data, offset: meanVector.offset)
        let variance = mpsFloatBuffer(varianceVector.data, offset: varianceVector.offset)
        let dx = mpsFloatBuffer(resultGradientForDataMatrix.data, offset: resultGradientForDataMatrix.offset)
        let ldg = max(gradientMatrix.rowBytes / 4, 1)
        let ldx = max(inputMatrix.rowBytes / 4, 1)
        let ldd = max(resultGradientForDataMatrix.rowBytes / 4, 1)
        let gamma = gammaVector.flatMap { $0.dataType == .float32 ? mpsFloatBuffer($0.data, offset: $0.offset) : nil }
        let dgamma = resultGradientForGammaVector.flatMap { $0.dataType == .float32 ? mpsFloatBuffer($0.data, offset: $0.offset) : nil }
        let dbeta = resultGradientForBetaVector.flatMap { $0.dataType == .float32 ? mpsFloatBuffer($0.data, offset: $0.offset) : nil }
        _ = betaVector
        let n = Float(max(rows, 1))
        for col in 0..<cols {
            let invStd = 1 / sqrt(variance[col] + epsilon)
            let gammaValue = gamma?[col] ?? 1
            var sumDy: Float = 0
            var sumDyXhat: Float = 0
            for row in 0..<rows {
                let xhat = (x[row * ldx + col] - mean[col]) * invStd
                var dy = g[row * ldg + col]
                if neuron != .none {
                    let pre = xhat * gammaValue
                    dy *= mpsNeuronDerivative(neuron, pre, a: neuronA, b: neuronB, c: neuronC)
                }
                sumDy += dy
                sumDyXhat += dy * xhat
            }
            if let dbeta {
                dbeta[col] = sumDy
            }
            if let dgamma {
                dgamma[col] = sumDyXhat
            }
            for row in 0..<rows {
                let xhat = (x[row * ldx + col] - mean[col]) * invStd
                var dy = g[row * ldg + col]
                if neuron != .none {
                    dy *= mpsNeuronDerivative(neuron, xhat * gammaValue, a: neuronA, b: neuronB, c: neuronC)
                }
                dx[row * ldd + col] = (gammaValue * invStd / n) * (n * dy - sumDy - xhat * sumDyXhat)
            }
        }
    }
}

open class MPSMatrixSoftMaxGradient: MPSMatrixBinaryKernel {
    public var sourceRows: Int = 0
    public var sourceColumns: Int = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixSoftMaxGradient(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copyBinaryConfiguration(to: copied)
        copied.sourceRows = sourceRows
        copied.sourceColumns = sourceColumns
        return copied as! Self
    }

    open func encode(
        to commandBuffer: any MTLCommandBuffer,
        gradientMatrix: MPSMatrix,
        forwardOutputMatrix: MPSMatrix,
        resultMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard gradientMatrix.dataType == .float32,
              forwardOutputMatrix.dataType == .float32,
              resultMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixSoftMaxGradient.encode")
            return
        }
        let rows = sourceRows > 0 ? sourceRows : forwardOutputMatrix.rows
        let columns = sourceColumns > 0 ? sourceColumns : forwardOutputMatrix.columns
        let zero = MTLOrigin(x: 0, y: 0, z: 0)
        guard hasHostOrigins, sourceRows >= 0, sourceColumns >= 0,
              [gradientMatrix, forwardOutputMatrix, resultMatrix].allSatisfy({
                  mpsHostMatrixRegionFits($0, rows: rows, columns: columns, origin: zero,
                      batchStart: batchStart, batchSize: batchSize)
              }), resultMatrix.data !== gradientMatrix.data,
              resultMatrix.data !== forwardOutputMatrix.data
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixSoftMaxGradient.encode")
            return
        }
        // BatchedCPUTests: y=[1/4,3/4], g=[2,6] gives [-3/4,3/4];
        // y=[1/2,1/2], g=[8,-4] gives [3,-3], with independent matrix strides.
        for batch in batchStart..<(batchStart + batchSize) {
            let g = mpsFloatBuffer(gradientMatrix.data,
                offset: gradientMatrix.offset + batch * gradientMatrix.matrixBytes)
            let y = mpsFloatBuffer(forwardOutputMatrix.data,
                offset: forwardOutputMatrix.offset + batch * forwardOutputMatrix.matrixBytes)
            let dx = mpsFloatBuffer(resultMatrix.data,
                offset: resultMatrix.offset + batch * resultMatrix.matrixBytes)
            let ldg = max(gradientMatrix.rowBytes / 4, 1)
            let ldy = max(forwardOutputMatrix.rowBytes / 4, 1)
            let ldd = max(resultMatrix.rowBytes / 4, 1)
            for row in 0..<rows {
                var dot: Float = 0
                for col in 0..<columns {
                    dot += y[row * ldy + col] * g[row * ldg + col]
                }
                for col in 0..<columns {
                    dx[row * ldd + col] = y[row * ldy + col] * (g[row * ldg + col] - dot)
                }
            }
        }
    }
}

open class MPSMatrixRandomDistributionDescriptor: NSObject {
    public var distributionType: MPSMatrixRandomDistribution = .default
    public var minimum: Float = 0
    public var maximum: Float = 1
    public var mean: Float = 0
    public var standardDeviation: Float = 1

    public override init() {
        super.init()
    }

    open class func `default`() -> MPSMatrixRandomDistributionDescriptor {
        let descriptor = MPSMatrixRandomDistributionDescriptor()
        descriptor.distributionType = .default
        descriptor.minimum = 0
        descriptor.maximum = 1
        return descriptor
    }

    open class func uniformDistributionDescriptor(withMinimum minimum: Float, maximum: Float) -> MPSMatrixRandomDistributionDescriptor {
        let descriptor = MPSMatrixRandomDistributionDescriptor()
        descriptor.distributionType = .uniform
        descriptor.minimum = minimum
        descriptor.maximum = maximum
        return descriptor
    }

    open class func normalDistributionDescriptor(withMean mean: Float, standardDeviation: Float) -> MPSMatrixRandomDistributionDescriptor {
        let descriptor = MPSMatrixRandomDistributionDescriptor()
        descriptor.distributionType = .normal
        descriptor.mean = mean
        descriptor.standardDeviation = standardDeviation
        return descriptor
    }

    open class func normalDistributionDescriptor(
        withMean mean: Float,
        standardDeviation: Float,
        minimum: Float,
        maximum: Float
    ) -> MPSMatrixRandomDistributionDescriptor {
        let descriptor = normalDistributionDescriptor(withMean: mean, standardDeviation: standardDeviation)
        descriptor.minimum = minimum
        descriptor.maximum = maximum
        return descriptor
    }
}

open class MPSMatrixRandom: MPSKernel {
    public var batchSize: Int = 1
    public var batchStart: Int = 0
    public private(set) var destinationDataType: MPSDataType
    public private(set) var distributionType: MPSMatrixRandomDistribution
    public private(set) var seed: UInt64
    fileprivate var distribution: MPSMatrixRandomDistributionDescriptor

    public required init(device: any MTLDevice) {
        self.destinationDataType = .float32
        self.distributionType = .default
        self.seed = 0
        self.distribution = .default()
        super.init(device: device)
    }

    fileprivate init(
        device: any MTLDevice,
        destinationDataType: MPSDataType,
        seed: Int,
        distributionDescriptor: MPSMatrixRandomDistributionDescriptor
    ) {
        self.destinationDataType = destinationDataType
        self.distributionType = distributionDescriptor.distributionType
        self.seed = UInt64(truncatingIfNeeded: seed)
        self.distribution = distributionDescriptor
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(commandBuffer: any MTLCommandBuffer, destinationMatrix: MPSMatrix) {
        _ = commandBuffer
        mpsFillRandom(matrix: destinationMatrix, seed: &seed, distribution: distribution, dataType: destinationDataType)
    }

    open func encode(commandBuffer: any MTLCommandBuffer, destinationVector: MPSVector) {
        _ = commandBuffer
        mpsFillRandomVector(vector: destinationVector, seed: &seed, distribution: distribution, dataType: destinationDataType)
    }
}

open class MPSMatrixRandomMTGP32: MPSMatrixRandom {
    public convenience required init(device: any MTLDevice) {
        self.init(device: device, destinationDataType: .float32, seed: 0, distributionDescriptor: .default())
    }

    public convenience init(device: any MTLDevice, destinationDataType: MPSDataType, seed: Int) {
        self.init(device: device, destinationDataType: destinationDataType, seed: seed, distributionDescriptor: .default())
    }

    public override init(
        device: any MTLDevice,
        destinationDataType: MPSDataType,
        seed: Int,
        distributionDescriptor: MPSMatrixRandomDistributionDescriptor
    ) {
        super.init(device: device, destinationDataType: destinationDataType, seed: seed, distributionDescriptor: distributionDescriptor)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func synchronizeState(on commandBuffer: any MTLCommandBuffer) {
        _ = commandBuffer
    }
}

open class MPSMatrixRandomPhilox: MPSMatrixRandom {
    public convenience required init(device: any MTLDevice) {
        self.init(device: device, destinationDataType: .float32, seed: 0, distributionDescriptor: .default())
    }

    public convenience init(device: any MTLDevice, destinationDataType: MPSDataType, seed: Int) {
        self.init(device: device, destinationDataType: destinationDataType, seed: seed, distributionDescriptor: .default())
    }

    public override init(
        device: any MTLDevice,
        destinationDataType: MPSDataType,
        seed: Int,
        distributionDescriptor: MPSMatrixRandomDistributionDescriptor
    ) {
        super.init(device: device, destinationDataType: destinationDataType, seed: seed, distributionDescriptor: distributionDescriptor)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }
}

func mpsLCG(_ seed: inout UInt64) -> UInt32 {
    seed = seed &* 6364136223846793005 &+ 1
    return UInt32(truncatingIfNeeded: seed >> 32)
}

func mpsUnitFloat(_ seed: inout UInt64) -> Float {
    Float(mpsLCG(&seed)) / Float(UInt32.max)
}

func mpsRandomSample(_ seed: inout UInt64, distribution: MPSMatrixRandomDistributionDescriptor) -> Float {
    if distribution.distributionType.contains(.normal) {
        let u1 = max(mpsUnitFloat(&seed), 1e-7)
        let u2 = mpsUnitFloat(&seed)
        let z = sqrt(-2 * log(u1)) * cos(2 * Float.pi * u2)
        let value = distribution.mean + distribution.standardDeviation * z
        if distribution.minimum < distribution.maximum {
            return min(max(value, distribution.minimum), distribution.maximum)
        }
        return value
    }
    let unit = mpsUnitFloat(&seed)
    return distribution.minimum + (distribution.maximum - distribution.minimum) * unit
}

func mpsFillRandom(
    matrix: MPSMatrix,
    seed: inout UInt64,
    distribution: MPSMatrixRandomDistributionDescriptor,
    dataType: MPSDataType
) {
    guard dataType == .float32, matrix.dataType == .float32 else {
        MPSHostBoundary.refuseGPUEncode("MPSMatrixRandom.encode(matrix)")
        return
    }
    let pointer = mpsFloatBuffer(matrix.data, offset: matrix.offset)
    let lda = max(matrix.rowBytes / 4, 1)
    for row in 0..<matrix.rows {
        for col in 0..<matrix.columns {
            pointer[row * lda + col] = mpsRandomSample(&seed, distribution: distribution)
        }
    }
}

func mpsFillRandomVector(
    vector: MPSVector,
    seed: inout UInt64,
    distribution: MPSMatrixRandomDistributionDescriptor,
    dataType: MPSDataType
) {
    guard dataType == .float32, vector.dataType == .float32 else {
        MPSHostBoundary.refuseGPUEncode("MPSMatrixRandom.encode(vector)")
        return
    }
    let pointer = mpsFloatBuffer(vector.data, offset: vector.offset)
    for index in 0..<vector.length {
        pointer[index] = mpsRandomSample(&seed, distribution: distribution)
    }
}
