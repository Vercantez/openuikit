import Foundation

extension MPSGraph {

    public func GRUGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, outputFwd: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, descriptor: MPSGraphGRUDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            _inputs.append(outputFwd)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "GRUGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func GRUGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, outputFwd: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, descriptor: MPSGraphGRUDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            _inputs.append(outputFwd)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "GRUGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func GRUGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, outputFwd: MPSGraphTensor, stateGradient: MPSGraphTensor?, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, mask: MPSGraphTensor?, secondaryBias: MPSGraphTensor?, descriptor: MPSGraphGRUDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            _inputs.append(outputFwd)
            if let stateGradient { _inputs.append(stateGradient) }
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let mask { _inputs.append(mask) }
            if let secondaryBias { _inputs.append(secondaryBias) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "GRUGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func GRU(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, descriptor: MPSGraphGRUDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "GRU", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func GRU(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, descriptor: MPSGraphGRUDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "GRU", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func GRU(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, mask: MPSGraphTensor?, secondaryBias: MPSGraphTensor?, descriptor: MPSGraphGRUDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let mask { _inputs.append(mask) }
            if let secondaryBias { _inputs.append(secondaryBias) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "GRU", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func HammingDistance(primary primaryTensor: MPSGraphTensor, secondary secondaryTensor: MPSGraphTensor, resultDataType: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "HammingDistance", inputs: _inputs, shape: _inputs.first?.shape, dataType: resultDataType, name: name, attributes: _attrs)
        }

    public func HermiteanToRealFFT(_ tensor: MPSGraphTensor, axes: [NSNumber], descriptor: MPSGraphFFTDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axes"] = axes
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "HermiteanToRealFFT", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func HermiteanToRealFFT(_ tensor: MPSGraphTensor, axesTensor: MPSGraphTensor, descriptor: MPSGraphFFTDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axesTensor)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "HermiteanToRealFFT", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func L2NormPooling4DGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "L2NormPooling4DGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func L2NormPooling4D(_ source: MPSGraphTensor, descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "L2NormPooling4D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func LSTMGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, cellOutputFwd: MPSGraphTensor, descriptor: MPSGraphLSTMDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            _inputs.append(cellOutputFwd)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "LSTMGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func LSTMGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, cellOutputFwd: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, initCell: MPSGraphTensor?, descriptor: MPSGraphLSTMDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            _inputs.append(cellOutputFwd)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let initCell { _inputs.append(initCell) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "LSTMGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func LSTMGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, cellOutputFwd: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, initCell: MPSGraphTensor?, mask: MPSGraphTensor?, descriptor: MPSGraphLSTMDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            _inputs.append(cellOutputFwd)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let initCell { _inputs.append(initCell) }
            if let mask { _inputs.append(mask) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "LSTMGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func LSTMGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, cellOutputFwd: MPSGraphTensor, stateGradient: MPSGraphTensor?, cellGradient: MPSGraphTensor?, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, initCell: MPSGraphTensor?, mask: MPSGraphTensor?, peephole: MPSGraphTensor?, descriptor: MPSGraphLSTMDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            _inputs.append(cellOutputFwd)
            if let stateGradient { _inputs.append(stateGradient) }
            if let cellGradient { _inputs.append(cellGradient) }
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let initCell { _inputs.append(initCell) }
            if let mask { _inputs.append(mask) }
            if let peephole { _inputs.append(peephole) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "LSTMGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func LSTM(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, initState: MPSGraphTensor?, initCell: MPSGraphTensor?, descriptor: MPSGraphLSTMDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let initState { _inputs.append(initState) }
            if let initCell { _inputs.append(initCell) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "LSTM", inputs: _inputs, count: (descriptor.produceCell ? 3 : 2), name: name, attributes: _attrs)
        }

    public func LSTM(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, initCell: MPSGraphTensor?, descriptor: MPSGraphLSTMDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let initCell { _inputs.append(initCell) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "LSTM", inputs: _inputs, count: (descriptor.produceCell ? 3 : 2), name: name, attributes: _attrs)
        }

    public func LSTM(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, initCell: MPSGraphTensor?, mask: MPSGraphTensor?, peephole: MPSGraphTensor?, descriptor: MPSGraphLSTMDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let initCell { _inputs.append(initCell) }
            if let mask { _inputs.append(mask) }
            if let peephole { _inputs.append(peephole) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "LSTM", inputs: _inputs, count: (descriptor.produceCell ? 3 : 2), name: name, attributes: _attrs)
        }

    public func absoluteSquare(tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "absoluteSquare", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func absolute(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "absolute", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func acos(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "acos", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func acosh(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "acosh", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func adam(currentLearningRate currentLearningRateTensor: MPSGraphTensor, beta1 beta1Tensor: MPSGraphTensor, beta2 beta2Tensor: MPSGraphTensor, epsilon epsilonTensor: MPSGraphTensor, values valuesTensor: MPSGraphTensor, momentum momentumTensor: MPSGraphTensor, velocity velocityTensor: MPSGraphTensor, maximumVelocity maximumVelocityTensor: MPSGraphTensor?, gradient gradientTensor: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(currentLearningRateTensor)
            _inputs.append(beta1Tensor)
            _inputs.append(beta2Tensor)
            _inputs.append(epsilonTensor)
            _inputs.append(valuesTensor)
            _inputs.append(momentumTensor)
            _inputs.append(velocityTensor)
            if let maximumVelocityTensor { _inputs.append(maximumVelocityTensor) }
            _inputs.append(gradientTensor)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "adam", inputs: _inputs, count: 3, name: name, attributes: _attrs)
        }

    public func adam(learningRate learningRateTensor: MPSGraphTensor, beta1 beta1Tensor: MPSGraphTensor, beta2 beta2Tensor: MPSGraphTensor, epsilon epsilonTensor: MPSGraphTensor, beta1Power beta1PowerTensor: MPSGraphTensor, beta2Power beta2PowerTensor: MPSGraphTensor, values valuesTensor: MPSGraphTensor, momentum momentumTensor: MPSGraphTensor, velocity velocityTensor: MPSGraphTensor, maximumVelocity maximumVelocityTensor: MPSGraphTensor?, gradient gradientTensor: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(learningRateTensor)
            _inputs.append(beta1Tensor)
            _inputs.append(beta2Tensor)
            _inputs.append(epsilonTensor)
            _inputs.append(beta1PowerTensor)
            _inputs.append(beta2PowerTensor)
            _inputs.append(valuesTensor)
            _inputs.append(momentumTensor)
            _inputs.append(velocityTensor)
            if let maximumVelocityTensor { _inputs.append(maximumVelocityTensor) }
            _inputs.append(gradientTensor)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "adam", inputs: _inputs, count: 3, name: name, attributes: _attrs)
        }

    public func addition(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "addition", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func applyStochasticGradientDescent(learningRate learningRateTensor: MPSGraphTensor, variable: MPSGraphVariableOp, gradient gradientTensor: MPSGraphTensor, name: String?) -> MPSGraphOperation
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(learningRateTensor)
            _inputs.append(gradientTensor)
            _attrs["_n"] = _inputs.count
            return recordOperation(kind: "applyStochasticGradientDescent", inputs: _inputs, name: name, attributes: _attrs)
        }

    public func argSort(_ tensor: MPSGraphTensor, axis: Int, descending: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["descending"] = descending
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "argSort", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func argSort(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "argSort", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func argSort(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, descending: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["descending"] = descending
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "argSort", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func argSort(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "argSort", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func asin(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "asin", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func asinh(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "asinh", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func atan2(withPrimaryTensor primaryTensor: MPSGraphTensor, secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "atan2", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func atan(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "atan", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func atanh(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "atanh", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func avgPooling2DGradient(withGradientTensor gradient: MPSGraphTensor, sourceTensor source: MPSGraphTensor, descriptor: MPSGraphPooling2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "avgPooling2DGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func avgPooling2D(withSourceTensor source: MPSGraphTensor, descriptor: MPSGraphPooling2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "avgPooling2D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func avgPooling4DGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "avgPooling4DGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func avgPooling4D(_ source: MPSGraphTensor, descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "avgPooling4D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bandPart(_ inputTensor: MPSGraphTensor, numLower: Int, numUpper: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(inputTensor)
            _attrs["numLower"] = numLower
            _attrs["numUpper"] = numUpper
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bandPart", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bandPart(_ inputTensor: MPSGraphTensor, numLowerTensor: MPSGraphTensor, numUpperTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(inputTensor)
            _inputs.append(numLowerTensor)
            _inputs.append(numUpperTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bandPart", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func batchToSpace(_ tensor: MPSGraphTensor, spatialAxes: [NSNumber], batchAxis: Int, blockDimensions: [NSNumber], usePixelShuffleOrder: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["spatialAxes"] = spatialAxes
            _attrs["batchAxis"] = batchAxis
            _attrs["blockDimensions"] = blockDimensions
            _attrs["usePixelShuffleOrder"] = usePixelShuffleOrder
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "batchToSpace", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func batchToSpace(_ tensor: MPSGraphTensor, spatialAxesTensor: MPSGraphTensor, batchAxisTensor: MPSGraphTensor, blockDimensionsTensor: MPSGraphTensor, usePixelShuffleOrder: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(spatialAxesTensor)
            _inputs.append(batchAxisTensor)
            _inputs.append(blockDimensionsTensor)
            _attrs["usePixelShuffleOrder"] = usePixelShuffleOrder
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "batchToSpace", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bitwiseAND(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bitwiseAND", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bitwiseLeftShift(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bitwiseLeftShift", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bitwiseNOT(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bitwiseNOT", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bitwiseOR(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bitwiseOR", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bitwisePopulationCount(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bitwisePopulationCount", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bitwiseRightShift(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bitwiseRightShift", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bitwiseXOR(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bitwiseXOR", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bottomKGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, axis: Int, k: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["axis"] = axis
            _attrs["k"] = k
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bottomKGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bottomKGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, axisTensor: MPSGraphTensor, kTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _inputs.append(axisTensor)
            _inputs.append(kTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "bottomKGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func bottomK(_ source: MPSGraphTensor, axis: Int, k: Int, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["axis"] = axis
            _attrs["k"] = k
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "bottomK", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func bottomK(_ source: MPSGraphTensor, axisTensor: MPSGraphTensor, kTensor: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(axisTensor)
            _inputs.append(kTensor)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "bottomK", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func broadcast(_ tensor: MPSGraphTensor, shape: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "broadcast", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func broadcast(_ tensor: MPSGraphTensor, shapeTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(shapeTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "broadcast", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func call(symbolName: String, inputTensors: [MPSGraphTensor], outputTypes: [MPSGraphType], name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["symbolName"] = symbolName
            _inputs.append(contentsOf: inputTensors)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "call", inputs: _inputs, count: max(outputTypes.count, 1), name: name, attributes: _attrs)
        }

    public func cast(_ tensor: MPSGraphTensor, to type: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cast", inputs: _inputs, shape: _inputs.first?.shape, dataType: type, name: name, attributes: _attrs)
        }

    public func ceil(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "ceil", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func clamp(_ tensor: MPSGraphTensor, min minValueTensor: MPSGraphTensor, max maxValueTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(minValueTensor)
            _inputs.append(maxValueTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "clamp", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func colToIm(_ source: MPSGraphTensor, outputShape: [NSNumber], descriptor: MPSGraphImToColOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["outputShape"] = outputShape
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "colToIm", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func complexTensor(realTensor: MPSGraphTensor, imaginaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(realTensor)
            _inputs.append(imaginaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "complexTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func concatTensor(_ tensor: MPSGraphTensor, with tensor2: MPSGraphTensor, dimension dimensionIndex: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(tensor2)
            _attrs["dimensionIndex"] = dimensionIndex
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "concatTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func concatTensors(_ tensors: [MPSGraphTensor], dimension dimensionIndex: Int, interleave: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(contentsOf: tensors)
            _attrs["dimensionIndex"] = dimensionIndex
            _attrs["interleave"] = interleave
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "concatTensors", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func concatTensors(_ tensors: [MPSGraphTensor], dimension dimensionIndex: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(contentsOf: tensors)
            _attrs["dimensionIndex"] = dimensionIndex
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "concatTensors", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func conjugate(tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "conjugate", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution2DDataGradient(_ incomingGradient: MPSGraphTensor, weights: MPSGraphTensor, outputShape: [NSNumber], forwardConvolutionDescriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(weights)
            _attrs["outputShape"] = outputShape
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution2DDataGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution2DDataGradient(_ gradient: MPSGraphTensor, weights: MPSGraphTensor, outputShapeTensor: MPSGraphTensor, forwardConvolutionDescriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(weights)
            _inputs.append(outputShapeTensor)
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution2DDataGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution2DWeightsGradient(_ incomingGradient: MPSGraphTensor, source: MPSGraphTensor, outputShape: [NSNumber], forwardConvolutionDescriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(source)
            _attrs["outputShape"] = outputShape
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution2DWeightsGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution2DWeightsGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, outputShapeTensor: MPSGraphTensor, forwardConvolutionDescriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _inputs.append(outputShapeTensor)
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution2DWeightsGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution2D(_ source: MPSGraphTensor, weights: MPSGraphTensor, descriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(weights)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution2D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution3DDataGradient(_ incomingGradient: MPSGraphTensor, weights: MPSGraphTensor, outputShape: [NSNumber], forwardConvolutionDescriptor: MPSGraphConvolution3DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(weights)
            _attrs["outputShape"] = outputShape
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution3DDataGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution3DDataGradient(_ gradient: MPSGraphTensor, weights: MPSGraphTensor, outputShapeTensor: MPSGraphTensor, forwardConvolutionDescriptor: MPSGraphConvolution3DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(weights)
            _inputs.append(outputShapeTensor)
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution3DDataGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution3DWeightsGradient(_ incomingGradient: MPSGraphTensor, source: MPSGraphTensor, outputShape: [NSNumber], forwardConvolutionDescriptor: MPSGraphConvolution3DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(source)
            _attrs["outputShape"] = outputShape
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution3DWeightsGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution3DWeightsGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, outputShapeTensor: MPSGraphTensor, forwardConvolutionDescriptor: MPSGraphConvolution3DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _inputs.append(outputShapeTensor)
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution3DWeightsGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolution3D(_ source: MPSGraphTensor, weights: MPSGraphTensor, descriptor: MPSGraphConvolution3DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(weights)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolution3D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolutionTranspose2DDataGradient(_ incomingGradient: MPSGraphTensor, weights: MPSGraphTensor, outputShape: [NSNumber], forwardConvolutionDescriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(weights)
            _attrs["outputShape"] = outputShape
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolutionTranspose2DDataGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolutionTranspose2DDataGradient(_ incomingGradient: MPSGraphTensor, weights: MPSGraphTensor, outputShapeTensor outputShape: MPSGraphTensor, forwardConvolutionDescriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(weights)
            _inputs.append(outputShape)
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolutionTranspose2DDataGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolutionTranspose2DWeightsGradient(_ incomingGradientTensor: MPSGraphTensor, weights source: MPSGraphTensor, outputShape: [NSNumber], forwardConvolutionDescriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradientTensor)
            _inputs.append(source)
            _attrs["outputShape"] = outputShape
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolutionTranspose2DWeightsGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolutionTranspose2DWeightsGradient(_ incomingGradientTensor: MPSGraphTensor, weights source: MPSGraphTensor, outputShapeTensor outputShape: MPSGraphTensor, forwardConvolutionDescriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradientTensor)
            _inputs.append(source)
            _inputs.append(outputShape)
            _attrs["forwardConvolutionDescriptor"] = forwardConvolutionDescriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolutionTranspose2DWeightsGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolutionTranspose2D(_ source: MPSGraphTensor, weights: MPSGraphTensor, outputShape: [NSNumber], descriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(weights)
            _attrs["outputShape"] = outputShape
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolutionTranspose2D", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func convolutionTranspose2D(_ source: MPSGraphTensor, weights: MPSGraphTensor, outputShapeTensor outputShape: MPSGraphTensor, descriptor: MPSGraphConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(weights)
            _inputs.append(outputShape)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "convolutionTranspose2D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func coordinate(alongAxis axis: Int, withShape shape: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["axis"] = axis
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "coordinate", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func coordinate(alongAxis axis: Int, withShapeTensor shapeTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["axis"] = axis
            _inputs.append(shapeTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "coordinate", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func coordinate(alongAxisTensor axisTensor: MPSGraphTensor, withShape shape: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(axisTensor)
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "coordinate", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func coordinate(alongAxisTensor axisTensor: MPSGraphTensor, withShapeTensor shapeTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(axisTensor)
            _inputs.append(shapeTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "coordinate", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cos(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cos", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cosh(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cosh", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeMaximum(_ tensor: MPSGraphTensor, axis: Int, exclusive: Bool, reverse: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["exclusive"] = exclusive
            _attrs["reverse"] = reverse
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeMaximum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeMaximum(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeMaximum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeMaximum(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, exclusive: Bool, reverse: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["exclusive"] = exclusive
            _attrs["reverse"] = reverse
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeMaximum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeMaximum(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeMaximum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeMinimum(_ tensor: MPSGraphTensor, axis: Int, exclusive: Bool, reverse: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["exclusive"] = exclusive
            _attrs["reverse"] = reverse
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeMinimum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeMinimum(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeMinimum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeMinimum(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, exclusive: Bool, reverse: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["exclusive"] = exclusive
            _attrs["reverse"] = reverse
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeMinimum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeMinimum(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeMinimum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeProduct(_ tensor: MPSGraphTensor, axis: Int, exclusive: Bool, reverse: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["exclusive"] = exclusive
            _attrs["reverse"] = reverse
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeProduct", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeProduct(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeProduct", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeProduct(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, exclusive: Bool, reverse: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["exclusive"] = exclusive
            _attrs["reverse"] = reverse
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeProduct", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeProduct(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeProduct", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeSum(_ tensor: MPSGraphTensor, axis: Int, exclusive: Bool, reverse: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["exclusive"] = exclusive
            _attrs["reverse"] = reverse
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeSum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeSum(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeSum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeSum(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, exclusive: Bool, reverse: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["exclusive"] = exclusive
            _attrs["reverse"] = reverse
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeSum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func cumulativeSum(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "cumulativeSum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func depth(toSpace2DTensor tensor: MPSGraphTensor, widthAxis: Int, heightAxis: Int, depthAxis: Int, blockSize: Int, usePixelShuffleOrder: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["widthAxis"] = widthAxis
            _attrs["heightAxis"] = heightAxis
            _attrs["depthAxis"] = depthAxis
            _attrs["blockSize"] = blockSize
            _attrs["usePixelShuffleOrder"] = usePixelShuffleOrder
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "depth", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func depth(toSpace2DTensor tensor: MPSGraphTensor, widthAxisTensor: MPSGraphTensor, heightAxisTensor: MPSGraphTensor, depthAxisTensor: MPSGraphTensor, blockSize: Int, usePixelShuffleOrder: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(widthAxisTensor)
            _inputs.append(heightAxisTensor)
            _inputs.append(depthAxisTensor)
            _attrs["blockSize"] = blockSize
            _attrs["usePixelShuffleOrder"] = usePixelShuffleOrder
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "depth", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func depthwiseConvolution2DDataGradient(_ incomingGradient: MPSGraphTensor, weights: MPSGraphTensor, outputShape: [NSNumber], descriptor: MPSGraphDepthwiseConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(weights)
            _attrs["outputShape"] = outputShape
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "depthwiseConvolution2DDataGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func depthwiseConvolution2DWeightsGradient(_ incomingGradient: MPSGraphTensor, source: MPSGraphTensor, outputShape: [NSNumber], descriptor: MPSGraphDepthwiseConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(source)
            _attrs["outputShape"] = outputShape
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "depthwiseConvolution2DWeightsGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func depthwiseConvolution2D(_ source: MPSGraphTensor, weights: MPSGraphTensor, descriptor: MPSGraphDepthwiseConvolution2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(weights)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "depthwiseConvolution2D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func depthwiseConvolution3DDataGradient(_ incomingGradient: MPSGraphTensor, weights: MPSGraphTensor, outputShape: [NSNumber]?, descriptor: MPSGraphDepthwiseConvolution3DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(weights)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "depthwiseConvolution3DDataGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func depthwiseConvolution3DWeightsGradient(_ incomingGradient: MPSGraphTensor, source: MPSGraphTensor, outputShape: [NSNumber], descriptor: MPSGraphDepthwiseConvolution3DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradient)
            _inputs.append(source)
            _attrs["outputShape"] = outputShape
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "depthwiseConvolution3DWeightsGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func depthwiseConvolution3D(_ source: MPSGraphTensor, weights: MPSGraphTensor, descriptor: MPSGraphDepthwiseConvolution3DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(weights)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "depthwiseConvolution3D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func dequantize(_ tensor: MPSGraphTensor, LUTTensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(LUTTensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dequantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func dequantize(_ tensor: MPSGraphTensor, LUTTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(LUTTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dequantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func dequantize(_ tensor: MPSGraphTensor, scale: Double, zeroPoint: Double, dataType: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["scale"] = scale
            _attrs["zeroPoint"] = zeroPoint
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dequantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func dequantize(_ tensor: MPSGraphTensor, scaleTensor: MPSGraphTensor, dataType: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(scaleTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dequantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func dequantize(_ tensor: MPSGraphTensor, scaleTensor: MPSGraphTensor, zeroPoint: Double, dataType: MPSDataType, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(scaleTensor)
            _attrs["zeroPoint"] = zeroPoint
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dequantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func dequantize(_ tensor: MPSGraphTensor, scaleTensor: MPSGraphTensor, zeroPointTensor: MPSGraphTensor, dataType: MPSDataType, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(scaleTensor)
            _inputs.append(zeroPointTensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dequantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func dequantize(_ tensor: MPSGraphTensor, scaleTensor: MPSGraphTensor, zeroPointTensor: MPSGraphTensor, dataType: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(scaleTensor)
            _inputs.append(zeroPointTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dequantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func divisionNoNaN(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "divisionNoNaN", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func division(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "division", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func dropout(_ tensor: MPSGraphTensor, rate: Double, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["rate"] = rate
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dropout", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func dropout(_ tensor: MPSGraphTensor, rate: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(rate)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "dropout", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func equal(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "equal", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func erf(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "erf", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func expandDims(_ tensor: MPSGraphTensor, axes: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axes"] = axes
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "expandDims", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func expandDims(_ tensor: MPSGraphTensor, axesTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axesTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "expandDims", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func expandDims(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "expandDims", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func exponentBase10(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "exponentBase10", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func exponentBase2(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "exponentBase2", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func exponent(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "exponent", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func fastFourierTransform(_ tensor: MPSGraphTensor, axes: [NSNumber], descriptor: MPSGraphFFTDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axes"] = axes
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "fastFourierTransform", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func fastFourierTransform(_ tensor: MPSGraphTensor, axesTensor: MPSGraphTensor, descriptor: MPSGraphFFTDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axesTensor)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "fastFourierTransform", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func flatten2D(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "flatten2D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func flatten2D(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "flatten2D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func floorModulo(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "floorModulo", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func floor(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "floor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func gatherAlongAxis(_ axis: Int, updates updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["axis"] = axis
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "gatherAlongAxis", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func gatherAlongAxisTensor(_ axisTensor: MPSGraphTensor, updates updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(axisTensor)
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "gatherAlongAxisTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func gatherND(withUpdatesTensor updatesTensor: MPSGraphTensor, indicesTensor: MPSGraphTensor, batchDimensions: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["batchDimensions"] = batchDimensions
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "gatherND", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func gather(withUpdatesTensor updatesTensor: MPSGraphTensor, indicesTensor: MPSGraphTensor, axis: Int, batchDimensions: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["axis"] = axis
            _attrs["batchDimensions"] = batchDimensions
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "gather", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func greaterThanOrEqualTo(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "greaterThanOrEqualTo", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func greaterThan(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "greaterThan", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func identity(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "identity", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func imToCol(_ source: MPSGraphTensor, descriptor: MPSGraphImToColOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "imToCol", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func imaginaryPartOfTensor(tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "imaginaryPartOfTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func inverse(input inputTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(inputTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "inverse", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func isFinite(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "isFinite", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func isInfinite(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "isInfinite", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func isNaN(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "isNaN", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func leakyReLUGradient(withIncomingGradient gradient: MPSGraphTensor, sourceTensor source: MPSGraphTensor, alphaTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _inputs.append(alphaTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "leakyReLUGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func leakyReLU(with tensor: MPSGraphTensor, alpha: Double, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["alpha"] = alpha
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "leakyReLU", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func leakyReLU(with tensor: MPSGraphTensor, alphaTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(alphaTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "leakyReLU", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func lessThanOrEqualTo(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "lessThanOrEqualTo", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func lessThan(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "lessThan", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logarithmBase10(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logarithmBase10", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logarithmBase2(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logarithmBase2", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logarithm(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logarithm", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logicalAND(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logicalAND", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logicalNAND(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logicalNAND", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logicalNOR(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logicalNOR", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logicalOR(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logicalOR", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logicalXNOR(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logicalXNOR", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func logicalXOR(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "logicalXOR", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func matrixMultiplication(primary primaryTensor: MPSGraphTensor, secondary secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "matrixMultiplication", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maxPooling2DGradient(withGradientTensor gradient: MPSGraphTensor, indicesTensor indices: MPSGraphTensor, outputShape: [NSNumber], descriptor: MPSGraphPooling2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(indices)
            _attrs["outputShape"] = outputShape
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maxPooling2DGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maxPooling2DGradient(withGradientTensor gradient: MPSGraphTensor, indicesTensor indices: MPSGraphTensor, outputShapeTensor outputShape: MPSGraphTensor, descriptor: MPSGraphPooling2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(indices)
            _inputs.append(outputShape)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maxPooling2DGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maxPooling2DGradient(withGradientTensor gradient: MPSGraphTensor, sourceTensor source: MPSGraphTensor, descriptor: MPSGraphPooling2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maxPooling2DGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maxPooling2DReturnIndices(_ source: MPSGraphTensor, descriptor: MPSGraphPooling2DOpDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "maxPooling2DReturnIndices", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func maxPooling2D(withSourceTensor source: MPSGraphTensor, descriptor: MPSGraphPooling2DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maxPooling2D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maxPooling4DGradient(withGradientTensor gradient: MPSGraphTensor, indicesTensor indices: MPSGraphTensor, outputShape: [NSNumber], descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(indices)
            _attrs["outputShape"] = outputShape
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maxPooling4DGradient", inputs: _inputs, shape: Optional(outputShape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maxPooling4DGradient(withGradientTensor gradient: MPSGraphTensor, indicesTensor indices: MPSGraphTensor, outputShapeTensor outputShape: MPSGraphTensor, descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(indices)
            _inputs.append(outputShape)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maxPooling4DGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maxPooling4DGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maxPooling4DGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maxPooling4DReturnIndices(_ source: MPSGraphTensor, descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "maxPooling4DReturnIndices", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func maxPooling4D(_ source: MPSGraphTensor, descriptor: MPSGraphPooling4DOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maxPooling4D", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maximumWithNaNPropagation(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maximumWithNaNPropagation", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func maximum(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "maximum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func mean(of tensor: MPSGraphTensor, axes: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axes"] = axes
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "mean", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func minimumWithNaNPropagation(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "minimumWithNaNPropagation", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func minimum(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "minimum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func modulo(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "modulo", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func multiplication(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "multiplication", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func negative(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "negative", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func nonMaximumSuppression(withBoxesTensor boxesTensor: MPSGraphTensor, scoresTensor: MPSGraphTensor, iouThreshold IOUThreshold: Float, scoreThreshold: Float, perClassSuppression: Bool, coordinateMode: MPSGraphNonMaximumSuppressionCoordinateMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(boxesTensor)
            _inputs.append(scoresTensor)
            _attrs["IOUThreshold"] = IOUThreshold
            _attrs["scoreThreshold"] = scoreThreshold
            _attrs["perClassSuppression"] = perClassSuppression
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "nonMaximumSuppression", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func nonMaximumSuppression(withBoxesTensor boxesTensor: MPSGraphTensor, scoresTensor: MPSGraphTensor, classIndicesTensor: MPSGraphTensor, iouThreshold IOUThreshold: Float, scoreThreshold: Float, perClassSuppression: Bool, coordinateMode: MPSGraphNonMaximumSuppressionCoordinateMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(boxesTensor)
            _inputs.append(scoresTensor)
            _inputs.append(classIndicesTensor)
            _attrs["IOUThreshold"] = IOUThreshold
            _attrs["scoreThreshold"] = scoreThreshold
            _attrs["perClassSuppression"] = perClassSuppression
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "nonMaximumSuppression", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func nonZeroIndices(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "nonZeroIndices", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func normalizationBetaGradient(withIncomingGradientTensor incomingGradientTensor: MPSGraphTensor, sourceTensor: MPSGraphTensor, reductionAxes axes: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradientTensor)
            _inputs.append(sourceTensor)
            _attrs["axes"] = axes
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "normalizationBetaGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func normalizationGammaGradient(withIncomingGradientTensor incomingGradientTensor: MPSGraphTensor, sourceTensor: MPSGraphTensor, mean meanTensor: MPSGraphTensor, varianceTensor: MPSGraphTensor, reductionAxes axes: [NSNumber], epsilon: Float, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradientTensor)
            _inputs.append(sourceTensor)
            _inputs.append(meanTensor)
            _inputs.append(varianceTensor)
            _attrs["axes"] = axes
            _attrs["epsilon"] = epsilon
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "normalizationGammaGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func normalizationGradient(withIncomingGradientTensor incomingGradientTensor: MPSGraphTensor, sourceTensor: MPSGraphTensor, mean meanTensor: MPSGraphTensor, varianceTensor: MPSGraphTensor, gammaTensor gamma: MPSGraphTensor?, gammaGradientTensor gammaGradient: MPSGraphTensor?, betaGradientTensor betaGradient: MPSGraphTensor?, reductionAxes axes: [NSNumber], epsilon: Float, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradientTensor)
            _inputs.append(sourceTensor)
            _inputs.append(meanTensor)
            _inputs.append(varianceTensor)
            if let gamma { _inputs.append(gamma) }
            if let gammaGradient { _inputs.append(gammaGradient) }
            if let betaGradient { _inputs.append(betaGradient) }
            _attrs["axes"] = axes
            _attrs["epsilon"] = epsilon
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "normalizationGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func normalize(_ tensor: MPSGraphTensor, mean: MPSGraphTensor, variance: MPSGraphTensor, gamma: MPSGraphTensor?, beta: MPSGraphTensor?, epsilon: Float, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(mean)
            _inputs.append(variance)
            if let gamma { _inputs.append(gamma) }
            if let beta { _inputs.append(beta) }
            _attrs["epsilon"] = epsilon
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "normalize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func notEqual(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "notEqual", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func not(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "not", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func oneHot(withIndicesTensor indicesTensor: MPSGraphTensor, depth: Int, axis: Int, dataType: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(indicesTensor)
            _attrs["depth"] = depth
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "oneHot", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func oneHot(withIndicesTensor indicesTensor: MPSGraphTensor, depth: Int, axis: Int, dataType: MPSDataType, onValue: Double, offValue: Double, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(indicesTensor)
            _attrs["depth"] = depth
            _attrs["axis"] = axis
            _attrs["onValue"] = onValue
            _attrs["offValue"] = offValue
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "oneHot", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func oneHot(withIndicesTensor indicesTensor: MPSGraphTensor, depth: Int, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(indicesTensor)
            _attrs["depth"] = depth
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "oneHot", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func oneHot(withIndicesTensor indicesTensor: MPSGraphTensor, depth: Int, dataType: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(indicesTensor)
            _attrs["depth"] = depth
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "oneHot", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func oneHot(withIndicesTensor indicesTensor: MPSGraphTensor, depth: Int, dataType: MPSDataType, onValue: Double, offValue: Double, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(indicesTensor)
            _attrs["depth"] = depth
            _attrs["onValue"] = onValue
            _attrs["offValue"] = offValue
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "oneHot", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func oneHot(withIndicesTensor indicesTensor: MPSGraphTensor, depth: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(indicesTensor)
            _attrs["depth"] = depth
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "oneHot", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func padGradient(withIncomingGradientTensor incomingGradientTensor: MPSGraphTensor, sourceTensor: MPSGraphTensor, paddingMode: MPSGraphPaddingMode, leftPadding: [NSNumber], rightPadding: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradientTensor)
            _inputs.append(sourceTensor)
            _attrs["leftPadding"] = leftPadding
            _attrs["rightPadding"] = rightPadding
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "padGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func padTensor(_ tensor: MPSGraphTensor, with paddingMode: MPSGraphPaddingMode, leftPadding: [NSNumber], rightPadding: [NSNumber], constantValue: Double, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["leftPadding"] = leftPadding
            _attrs["rightPadding"] = rightPadding
            _attrs["constantValue"] = constantValue
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "padTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func power(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "power", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func quantize(_ tensor: MPSGraphTensor, scale: Double, zeroPoint: Double, dataType: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["scale"] = scale
            _attrs["zeroPoint"] = zeroPoint
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "quantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func quantize(_ tensor: MPSGraphTensor, scaleTensor: MPSGraphTensor, zeroPoint: Double, dataType: MPSDataType, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(scaleTensor)
            _attrs["zeroPoint"] = zeroPoint
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "quantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func quantize(_ tensor: MPSGraphTensor, scaleTensor: MPSGraphTensor, zeroPointTensor: MPSGraphTensor, dataType: MPSDataType, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(scaleTensor)
            _inputs.append(zeroPointTensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "quantize", inputs: _inputs, shape: _inputs.first?.shape, dataType: dataType, name: name, attributes: _attrs)
        }

    public func randomPhiloxStateTensor(withCounterLow counterLow: Int, counterHigh: Int, key: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["counterLow"] = counterLow
            _attrs["counterHigh"] = counterHigh
            _attrs["key"] = key
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomPhiloxStateTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomPhiloxStateTensor(withSeed seed: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["seed"] = seed
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomPhiloxStateTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomTensor(withShape shape: [NSNumber], descriptor: MPSGraphRandomOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["shape"] = shape
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomTensor", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomTensor(withShape shape: [NSNumber], descriptor: MPSGraphRandomOpDescriptor, seed: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["shape"] = shape
            _attrs["descriptor"] = descriptor
            _attrs["seed"] = seed
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomTensor", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomTensor(withShape shape: [NSNumber], descriptor: MPSGraphRandomOpDescriptor, stateTensor state: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["shape"] = shape
            _attrs["descriptor"] = descriptor
            _inputs.append(state)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "randomTensor", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func randomTensor(withShapeTensor shapeTensor: MPSGraphTensor, descriptor: MPSGraphRandomOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(shapeTensor)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomTensor(withShapeTensor shapeTensor: MPSGraphTensor, descriptor: MPSGraphRandomOpDescriptor, seed: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(shapeTensor)
            _attrs["descriptor"] = descriptor
            _attrs["seed"] = seed
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomTensor(withShapeTensor shapeTensor: MPSGraphTensor, descriptor: MPSGraphRandomOpDescriptor, stateTensor state: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(shapeTensor)
            _attrs["descriptor"] = descriptor
            _inputs.append(state)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "randomTensor", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func randomUniformTensor(withShape shape: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomUniformTensor", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomUniformTensor(withShape shape: [NSNumber], seed: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["shape"] = shape
            _attrs["seed"] = seed
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomUniformTensor", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomUniformTensor(withShape shape: [NSNumber], stateTensor state: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["shape"] = shape
            _inputs.append(state)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "randomUniformTensor", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func randomUniformTensor(withShapeTensor shapeTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(shapeTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomUniformTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomUniformTensor(withShapeTensor shapeTensor: MPSGraphTensor, seed: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(shapeTensor)
            _attrs["seed"] = seed
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "randomUniformTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func randomUniformTensor(withShapeTensor shapeTensor: MPSGraphTensor, stateTensor state: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(shapeTensor)
            _inputs.append(state)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "randomUniformTensor", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func reLUGradient(withIncomingGradient gradient: MPSGraphTensor, sourceTensor source: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reLUGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reLU(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reLU", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func read(_ variable: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(variable)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "read", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func realPartOfTensor(tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "realPartOfTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func realToHermiteanFFT(_ tensor: MPSGraphTensor, axes: [NSNumber], descriptor: MPSGraphFFTDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axes"] = axes
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "realToHermiteanFFT", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func realToHermiteanFFT(_ tensor: MPSGraphTensor, axesTensor: MPSGraphTensor, descriptor: MPSGraphFFTDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axesTensor)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "realToHermiteanFFT", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reciprocalSquareRoot(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reciprocalSquareRoot", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reciprocal(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reciprocal", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionAnd(with tensor: MPSGraphTensor, axes: [NSNumber]?, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionAnd", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionAnd(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionAnd", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionArgMaximum(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionArgMaximum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionArgMinimum(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionArgMinimum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionMaximumPropagateNaN(with tensor: MPSGraphTensor, axes: [NSNumber]?, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionMaximumPropagateNaN", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionMaximumPropagateNaN(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionMaximumPropagateNaN", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionMaximum(with tensor: MPSGraphTensor, axes: [NSNumber]?, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionMaximum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionMaximum(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionMaximum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionMinimumPropagateNaN(with tensor: MPSGraphTensor, axes: [NSNumber]?, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionMinimumPropagateNaN", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionMinimumPropagateNaN(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionMinimumPropagateNaN", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionMinimum(with tensor: MPSGraphTensor, axes: [NSNumber]?, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionMinimum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionMinimum(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionMinimum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionOr(with tensor: MPSGraphTensor, axes: [NSNumber]?, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionOr", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionOr(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionOr", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionProduct(with tensor: MPSGraphTensor, axes: [NSNumber]?, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionProduct", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionProduct(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionProduct", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionSum(with tensor: MPSGraphTensor, axes: [NSNumber]?, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionSum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reductionSum(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reductionSum", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reinterpretCast(_ tensor: MPSGraphTensor, to type: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reinterpretCast", inputs: _inputs, shape: _inputs.first?.shape, dataType: type, name: name, attributes: _attrs)
        }

    public func reshape(_ tensor: MPSGraphTensor, shape: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reshape", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reshape(_ tensor: MPSGraphTensor, shapeTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(shapeTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reshape", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeBilinear(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, centerResult: Bool, alignCorners: Bool, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeBilinear", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeBilinear(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, scaleOffsetTensor scaleOffset: MPSGraphTensor, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _inputs.append(scaleOffset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeBilinear", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeBilinear(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, scale: MPSGraphTensor, offsetTensor offset: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _inputs.append(scale)
            _inputs.append(offset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeBilinear", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeBilinear(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, centerResult: Bool, alignCorners: Bool, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeBilinear", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeBilinear(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, centerResult: Bool, alignCorners: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeBilinear", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeBilinear(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, scaleOffsetTensor scaleOffset: MPSGraphTensor, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _inputs.append(scaleOffset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeBilinear", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeBilinear(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, scaleTensor scale: MPSGraphTensor, offsetTensor offset: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _inputs.append(scale)
            _inputs.append(offset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeBilinear", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeNearest(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, nearestRoundingMode: MPSGraphResizeNearestRoundingMode, centerResult: Bool, alignCorners: Bool, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeNearest", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeNearest(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, scaleOffsetTensor scaleOffset: MPSGraphTensor, nearestRoundingMode: MPSGraphResizeNearestRoundingMode, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _inputs.append(scaleOffset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeNearest", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeNearest(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, scale: MPSGraphTensor, offsetTensor offset: MPSGraphTensor, nearestRoundingMode: MPSGraphResizeNearestRoundingMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _inputs.append(scale)
            _inputs.append(offset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeNearest", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeNearest(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, nearestRoundingMode: MPSGraphResizeNearestRoundingMode, centerResult: Bool, alignCorners: Bool, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeNearest", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeNearest(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, nearestRoundingMode: MPSGraphResizeNearestRoundingMode, centerResult: Bool, alignCorners: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeNearest", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeNearest(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, scaleOffsetTensor scaleOffset: MPSGraphTensor, nearestRoundingMode: MPSGraphResizeNearestRoundingMode, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _inputs.append(scaleOffset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeNearest", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resizeNearest(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, scaleTensor scale: MPSGraphTensor, offsetTensor offset: MPSGraphTensor, nearestRoundingMode: MPSGraphResizeNearestRoundingMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _inputs.append(scale)
            _inputs.append(offset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resizeNearest", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resize(_ imagesTensor: MPSGraphTensor, size: [NSNumber], mode: MPSGraphResizeMode, centerResult: Bool, alignCorners: Bool, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _attrs["size"] = size
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resize(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, mode: MPSGraphResizeMode, centerResult: Bool, alignCorners: Bool, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resize(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, mode: MPSGraphResizeMode, centerResult: Bool, alignCorners: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resize(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, scaleOffsetTensor scaleOffset: MPSGraphTensor, mode: MPSGraphResizeMode, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _inputs.append(scaleOffset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resize(_ imagesTensor: MPSGraphTensor, sizeTensor size: MPSGraphTensor, scaleTensor scale: MPSGraphTensor, offsetTenor offset: MPSGraphTensor, mode: MPSGraphResizeMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(imagesTensor)
            _inputs.append(size)
            _inputs.append(scale)
            _inputs.append(offset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resize(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, mode: MPSGraphResizeMode, centerResult: Bool, alignCorners: Bool, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _attrs["centerResult"] = centerResult
            _attrs["alignCorners"] = alignCorners
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resize(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, scaleOffsetTensor scaleOffset: MPSGraphTensor, mode: MPSGraphResizeMode, layout: MPSGraphTensorNamedDataLayout, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _inputs.append(scaleOffset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func resize(withGradientTensor gradient: MPSGraphTensor, input: MPSGraphTensor, scale: MPSGraphTensor, offsetTensor offset: MPSGraphTensor, mode: MPSGraphResizeMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(input)
            _inputs.append(scale)
            _inputs.append(offset)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "resize", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reverseSquareRoot(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reverseSquareRoot", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reverse(_ tensor: MPSGraphTensor, axes: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axes"] = axes
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reverse", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reverse(_ tensor: MPSGraphTensor, axesTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axesTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reverse", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func reverse(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "reverse", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func rint(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "rint", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func round(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "round", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sampleGrid(withSourceTensor source: MPSGraphTensor, coordinateTensor coordinates: MPSGraphTensor, layout: MPSGraphTensorNamedDataLayout, normalizeCoordinates: Bool, relativeCoordinates: Bool, alignCorners: Bool, paddingMode: MPSGraphPaddingMode, nearestRoundingMode: MPSGraphResizeNearestRoundingMode, constantValue: Double, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(coordinates)
            _attrs["normalizeCoordinates"] = normalizeCoordinates
            _attrs["relativeCoordinates"] = relativeCoordinates
            _attrs["alignCorners"] = alignCorners
            _attrs["constantValue"] = constantValue
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sampleGrid", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sampleGrid(withSourceTensor source: MPSGraphTensor, coordinateTensor coordinates: MPSGraphTensor, layout: MPSGraphTensorNamedDataLayout, normalizeCoordinates: Bool, relativeCoordinates: Bool, alignCorners: Bool, paddingMode: MPSGraphPaddingMode, samplingMode: MPSGraphResizeMode, constantValue: Double, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(coordinates)
            _attrs["normalizeCoordinates"] = normalizeCoordinates
            _attrs["relativeCoordinates"] = relativeCoordinates
            _attrs["alignCorners"] = alignCorners
            _attrs["constantValue"] = constantValue
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sampleGrid", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scaledDotProductAttention(query queryTensor: MPSGraphTensor, key keyTensor: MPSGraphTensor, value valueTensor: MPSGraphTensor, mask maskTensor: MPSGraphTensor?, scale: Float, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(queryTensor)
            _inputs.append(keyTensor)
            _inputs.append(valueTensor)
            if let maskTensor { _inputs.append(maskTensor) }
            _attrs["scale"] = scale
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scaledDotProductAttention", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scaledDotProductAttention(query queryTensor: MPSGraphTensor, key keyTensor: MPSGraphTensor, value valueTensor: MPSGraphTensor, scale: Float, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(queryTensor)
            _inputs.append(keyTensor)
            _inputs.append(valueTensor)
            _attrs["scale"] = scale
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scaledDotProductAttention", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatterAlongAxis(_ axis: Int, data dataTensor: MPSGraphTensor, updates updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, mode: MPSGraphScatterMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["axis"] = axis
            _inputs.append(dataTensor)
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatterAlongAxis", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatterAlongAxis(_ axis: Int, updates updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, shape: [NSNumber], mode: MPSGraphScatterMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["axis"] = axis
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatterAlongAxis", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatterAlongAxisTensor(_ axisTensor: MPSGraphTensor, data dataTensor: MPSGraphTensor, updates updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, mode: MPSGraphScatterMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(axisTensor)
            _inputs.append(dataTensor)
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatterAlongAxisTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatterAlongAxisTensor(_ axisTensor: MPSGraphTensor, updates updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, shape: [NSNumber], mode: MPSGraphScatterMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(axisTensor)
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatterAlongAxisTensor", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatterNDWithData(_ dataTensor: MPSGraphTensor, updates updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, batchDimensions: Int, mode: MPSGraphScatterMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(dataTensor)
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["batchDimensions"] = batchDimensions
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatterNDWithData", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatterND(withUpdatesTensor updatesTensor: MPSGraphTensor, indicesTensor: MPSGraphTensor, shape: [NSNumber], batchDimensions: Int, mode: MPSGraphScatterMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["shape"] = shape
            _attrs["batchDimensions"] = batchDimensions
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatterND", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatterND(withUpdatesTensor updatesTensor: MPSGraphTensor, indicesTensor: MPSGraphTensor, shape: [NSNumber], batchDimensions: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["shape"] = shape
            _attrs["batchDimensions"] = batchDimensions
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatterND", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatterWithData(_ dataTensor: MPSGraphTensor, updates updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, axis: Int, mode: MPSGraphScatterMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(dataTensor)
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatterWithData", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func scatter(_ updatesTensor: MPSGraphTensor, indices indicesTensor: MPSGraphTensor, shape: [NSNumber], axis: Int, mode: MPSGraphScatterMode, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(updatesTensor)
            _inputs.append(indicesTensor)
            _attrs["shape"] = shape
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "scatter", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func select(predicate predicateTensor: MPSGraphTensor, trueTensor truePredicateTensor: MPSGraphTensor, falseTensor falseSelectTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(predicateTensor)
            _inputs.append(truePredicateTensor)
            _inputs.append(falseSelectTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "select", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func shapeOf(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "shapeOf", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sigmoidGradient(withIncomingGradient gradient: MPSGraphTensor, sourceTensor source: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sigmoidGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sigmoid(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sigmoid", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sign(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sign", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func signbit(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "signbit", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sin(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sin", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func singleGateRNNGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, initState: MPSGraphTensor?, descriptor: MPSGraphSingleGateRNNDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            if let initState { _inputs.append(initState) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "singleGateRNNGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func singleGateRNNGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, descriptor: MPSGraphSingleGateRNNDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "singleGateRNNGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func singleGateRNNGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, mask: MPSGraphTensor?, descriptor: MPSGraphSingleGateRNNDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let mask { _inputs.append(mask) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "singleGateRNNGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func singleGateRNNGradients(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, sourceGradient: MPSGraphTensor, zState: MPSGraphTensor, stateGradient: MPSGraphTensor?, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, mask: MPSGraphTensor?, descriptor: MPSGraphSingleGateRNNDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            _inputs.append(sourceGradient)
            _inputs.append(zState)
            if let stateGradient { _inputs.append(stateGradient) }
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let mask { _inputs.append(mask) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "singleGateRNNGradients", inputs: _inputs, count: max(_inputs.count, 2), name: name, attributes: _attrs)
        }

    public func singleGateRNN(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, initState: MPSGraphTensor?, descriptor: MPSGraphSingleGateRNNDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let initState { _inputs.append(initState) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "singleGateRNN", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func singleGateRNN(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, descriptor: MPSGraphSingleGateRNNDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "singleGateRNN", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func singleGateRNN(_ source: MPSGraphTensor, recurrentWeight: MPSGraphTensor, inputWeight: MPSGraphTensor?, bias: MPSGraphTensor?, initState: MPSGraphTensor?, mask: MPSGraphTensor?, descriptor: MPSGraphSingleGateRNNDescriptor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(recurrentWeight)
            if let inputWeight { _inputs.append(inputWeight) }
            if let bias { _inputs.append(bias) }
            if let initState { _inputs.append(initState) }
            if let mask { _inputs.append(mask) }
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "singleGateRNN", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func sinh(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sinh", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceGradientTensor(_ inputGradientTensor: MPSGraphTensor, fwdInShapeTensor: MPSGraphTensor, start startTensor: MPSGraphTensor, end endTensor: MPSGraphTensor, strideTensor: MPSGraphTensor, startMask: UInt32, endMask: UInt32, squeezeMask: UInt32, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(inputGradientTensor)
            _inputs.append(fwdInShapeTensor)
            _inputs.append(startTensor)
            _inputs.append(endTensor)
            _inputs.append(strideTensor)
            _attrs["startMask"] = startMask
            _attrs["endMask"] = endMask
            _attrs["squeezeMask"] = squeezeMask
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceGradientTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceGradientTensor(_ inputGradientTensor: MPSGraphTensor, fwdInShapeTensor: MPSGraphTensor, start startTensor: MPSGraphTensor, sizeTensor: MPSGraphTensor, squeezeMask: UInt32, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(inputGradientTensor)
            _inputs.append(fwdInShapeTensor)
            _inputs.append(startTensor)
            _inputs.append(sizeTensor)
            _attrs["squeezeMask"] = squeezeMask
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceGradientTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceGradientTensor(_ inputGradientTensor: MPSGraphTensor, fwdInShapeTensor: MPSGraphTensor, starts: [NSNumber], ends: [NSNumber], strides: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(inputGradientTensor)
            _inputs.append(fwdInShapeTensor)
            _attrs["starts"] = starts
            _attrs["ends"] = ends
            _attrs["strides"] = strides
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceGradientTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceGradientTensor(_ inputGradientTensor: MPSGraphTensor, fwdInShapeTensor: MPSGraphTensor, starts: [NSNumber], ends: [NSNumber], strides: [NSNumber], startMask: UInt32, endMask: UInt32, squeezeMask: UInt32, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(inputGradientTensor)
            _inputs.append(fwdInShapeTensor)
            _attrs["starts"] = starts
            _attrs["ends"] = ends
            _attrs["strides"] = strides
            _attrs["startMask"] = startMask
            _attrs["endMask"] = endMask
            _attrs["squeezeMask"] = squeezeMask
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceGradientTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceTensor(_ tensor: MPSGraphTensor, dimension dimensionIndex: Int, start: Int, length: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["dimensionIndex"] = dimensionIndex
            _attrs["start"] = start
            _attrs["length"] = length
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceTensor(_ tensor: MPSGraphTensor, start startTensor: MPSGraphTensor, end endTensor: MPSGraphTensor, strideTensor: MPSGraphTensor, startMask: UInt32, endMask: UInt32, squeezeMask: UInt32, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(startTensor)
            _inputs.append(endTensor)
            _inputs.append(strideTensor)
            _attrs["startMask"] = startMask
            _attrs["endMask"] = endMask
            _attrs["squeezeMask"] = squeezeMask
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceTensor(_ tensor: MPSGraphTensor, start startTensor: MPSGraphTensor, sizeTensor: MPSGraphTensor, squeezeMask: UInt32, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(startTensor)
            _inputs.append(sizeTensor)
            _attrs["squeezeMask"] = squeezeMask
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceTensor(_ tensor: MPSGraphTensor, starts: [NSNumber], ends: [NSNumber], strides: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["starts"] = starts
            _attrs["ends"] = ends
            _attrs["strides"] = strides
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceTensor(_ tensor: MPSGraphTensor, starts: [NSNumber], ends: [NSNumber], strides: [NSNumber], startMask: UInt32, endMask: UInt32, squeezeMask: UInt32, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["starts"] = starts
            _attrs["ends"] = ends
            _attrs["strides"] = strides
            _attrs["startMask"] = startMask
            _attrs["endMask"] = endMask
            _attrs["squeezeMask"] = squeezeMask
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceUpdateDataTensor(_ dataTensor: MPSGraphTensor, update updateTensor: MPSGraphTensor, starts: [NSNumber], ends: [NSNumber], strides: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(dataTensor)
            _inputs.append(updateTensor)
            _attrs["starts"] = starts
            _attrs["ends"] = ends
            _attrs["strides"] = strides
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceUpdateDataTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceUpdateDataTensor(_ dataTensor: MPSGraphTensor, update updateTensor: MPSGraphTensor, starts: [NSNumber], ends: [NSNumber], strides: [NSNumber], startMask: UInt32, endMask: UInt32, squeezeMask: UInt32, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(dataTensor)
            _inputs.append(updateTensor)
            _attrs["starts"] = starts
            _attrs["ends"] = ends
            _attrs["strides"] = strides
            _attrs["startMask"] = startMask
            _attrs["endMask"] = endMask
            _attrs["squeezeMask"] = squeezeMask
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceUpdateDataTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceUpdateDataTensor(_ dataTensor: MPSGraphTensor, update updateTensor: MPSGraphTensor, startsTensor: MPSGraphTensor, endsTensor: MPSGraphTensor, stridesTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(dataTensor)
            _inputs.append(updateTensor)
            _inputs.append(startsTensor)
            _inputs.append(endsTensor)
            _inputs.append(stridesTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceUpdateDataTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sliceUpdateDataTensor(_ dataTensor: MPSGraphTensor, update updateTensor: MPSGraphTensor, startsTensor: MPSGraphTensor, endsTensor: MPSGraphTensor, stridesTensor: MPSGraphTensor, startMask: UInt32, endMask: UInt32, squeezeMask: UInt32, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(dataTensor)
            _inputs.append(updateTensor)
            _inputs.append(startsTensor)
            _inputs.append(endsTensor)
            _inputs.append(stridesTensor)
            _attrs["startMask"] = startMask
            _attrs["endMask"] = endMask
            _attrs["squeezeMask"] = squeezeMask
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sliceUpdateDataTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func softMaxCrossEntropyGradient(_ gradientTensor: MPSGraphTensor, source sourceTensor: MPSGraphTensor, labels labelsTensor: MPSGraphTensor, axis: Int, reuctionType reductionType: MPSGraphLossReductionType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradientTensor)
            _inputs.append(sourceTensor)
            _inputs.append(labelsTensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "softMaxCrossEntropyGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func softMaxCrossEntropy(_ sourceTensor: MPSGraphTensor, labels labelsTensor: MPSGraphTensor, axis: Int, reuctionType reductionType: MPSGraphLossReductionType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(sourceTensor)
            _inputs.append(labelsTensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "softMaxCrossEntropy", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func softMaxGradient(withIncomingGradient gradient: MPSGraphTensor, sourceTensor source: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "softMaxGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func softMax(with tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "softMax", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sort(_ tensor: MPSGraphTensor, axis: Int, descending: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["descending"] = descending
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sort", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sort(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sort", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sort(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, descending: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["descending"] = descending
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sort", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sort(_ tensor: MPSGraphTensor, axisTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axisTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sort", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func spaceToBatch(_ tensor: MPSGraphTensor, spatialAxes: [NSNumber], batchAxis: Int, blockDimensions: [NSNumber], usePixelShuffleOrder: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["spatialAxes"] = spatialAxes
            _attrs["batchAxis"] = batchAxis
            _attrs["blockDimensions"] = blockDimensions
            _attrs["usePixelShuffleOrder"] = usePixelShuffleOrder
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "spaceToBatch", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func spaceToBatch(_ tensor: MPSGraphTensor, spatialAxesTensor: MPSGraphTensor, batchAxisTensor: MPSGraphTensor, blockDimensionsTensor: MPSGraphTensor, usePixelShuffleOrder: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(spatialAxesTensor)
            _inputs.append(batchAxisTensor)
            _inputs.append(blockDimensionsTensor)
            _attrs["usePixelShuffleOrder"] = usePixelShuffleOrder
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "spaceToBatch", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func space(toDepth2DTensor tensor: MPSGraphTensor, widthAxis: Int, heightAxis: Int, depthAxis: Int, blockSize: Int, usePixelShuffleOrder: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["widthAxis"] = widthAxis
            _attrs["heightAxis"] = heightAxis
            _attrs["depthAxis"] = depthAxis
            _attrs["blockSize"] = blockSize
            _attrs["usePixelShuffleOrder"] = usePixelShuffleOrder
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "space", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func space(toDepth2DTensor tensor: MPSGraphTensor, widthAxisTensor: MPSGraphTensor, heightAxisTensor: MPSGraphTensor, depthAxisTensor: MPSGraphTensor, blockSize: Int, usePixelShuffleOrder: Bool, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(widthAxisTensor)
            _inputs.append(heightAxisTensor)
            _inputs.append(depthAxisTensor)
            _attrs["blockSize"] = blockSize
            _attrs["usePixelShuffleOrder"] = usePixelShuffleOrder
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "space", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sparseTensor(sparseTensorWithDescriptor sparseDescriptor: MPSGraphCreateSparseOpDescriptor, tensors inputTensorArray: [MPSGraphTensor], shape: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _attrs["sparseDescriptor"] = sparseDescriptor
            _inputs.append(contentsOf: inputTensorArray)
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sparseTensor", inputs: _inputs, shape: Optional(shape), dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func sparseTensor(sparseTensorWithType sparseStorageType: MPSGraphSparseStorageType, tensors inputTensorArray: [MPSGraphTensor], shape: [NSNumber], dataType: MPSDataType, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(contentsOf: inputTensorArray)
            _attrs["shape"] = shape
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "sparseTensor", inputs: _inputs, shape: Optional(shape), dataType: dataType, name: name, attributes: _attrs)
        }

    public func split(_ tensor: MPSGraphTensor, numSplits: Int, axis: Int, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["numSplits"] = numSplits
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "split", inputs: _inputs, count: max(numSplits, 1), name: name, attributes: _attrs)
        }

    public func split(_ tensor: MPSGraphTensor, splitSizes: [NSNumber], axis: Int, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["splitSizes"] = splitSizes
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "split", inputs: _inputs, count: max(splitSizes.count, 1), name: name, attributes: _attrs)
        }

    public func split(_ tensor: MPSGraphTensor, splitSizesTensor: MPSGraphTensor, axis: Int, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(splitSizesTensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "split", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func squareRoot(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "squareRoot", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func square(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "square", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func squeeze(_ tensor: MPSGraphTensor, axes: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axes"] = axes
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "squeeze", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func squeeze(_ tensor: MPSGraphTensor, axesTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(axesTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "squeeze", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func squeeze(_ tensor: MPSGraphTensor, axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "squeeze", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func squeeze(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "squeeze", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func stack(_ inputTensors: [MPSGraphTensor], axis: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(contentsOf: inputTensors)
            _attrs["axis"] = axis
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "stack", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func stencil(withSourceTensor source: MPSGraphTensor, weightsTensor weights: MPSGraphTensor, descriptor: MPSGraphStencilOpDescriptor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(weights)
            _attrs["descriptor"] = descriptor
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "stencil", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func stochasticGradientDescent(learningRate learningRateTensor: MPSGraphTensor, values valuesTensor: MPSGraphTensor, gradient gradientTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(learningRateTensor)
            _inputs.append(valuesTensor)
            _inputs.append(gradientTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "stochasticGradientDescent", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func subtraction(_ primaryTensor: MPSGraphTensor, _ secondaryTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(primaryTensor)
            _inputs.append(secondaryTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "subtraction", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func tan(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "tan", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func tanh(with tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "tanh", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func tileGradient(withIncomingGradientTensor incomingGradientTensor: MPSGraphTensor, sourceTensor: MPSGraphTensor, withMultiplier multiplier: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(incomingGradientTensor)
            _inputs.append(sourceTensor)
            _attrs["multiplier"] = multiplier
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "tileGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func tileTensor(_ tensor: MPSGraphTensor, withMultiplier multiplier: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["multiplier"] = multiplier
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "tileTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func topKGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, axis: Int, k: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["axis"] = axis
            _attrs["k"] = k
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "topKGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func topKGradient(_ gradient: MPSGraphTensor, source: MPSGraphTensor, axisTensor: MPSGraphTensor, kTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _inputs.append(axisTensor)
            _inputs.append(kTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "topKGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func topKGradient(_ gradient: MPSGraphTensor, input source: MPSGraphTensor, k: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _attrs["k"] = k
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "topKGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func topKGradient(_ gradient: MPSGraphTensor, input source: MPSGraphTensor, kTensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(gradient)
            _inputs.append(source)
            _inputs.append(kTensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "topKGradient", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func topK(_ source: MPSGraphTensor, axis: Int, k: Int, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["axis"] = axis
            _attrs["k"] = k
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "topK", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func topK(_ source: MPSGraphTensor, axisTensor: MPSGraphTensor, kTensor: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(axisTensor)
            _inputs.append(kTensor)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "topK", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func topK(_ source: MPSGraphTensor, k: Int, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _attrs["k"] = k
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "topK", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func topK(_ source: MPSGraphTensor, kTensor: MPSGraphTensor, name: String?) -> [MPSGraphTensor]
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(source)
            _inputs.append(kTensor)
            _attrs["_n"] = _inputs.count
            return recordTensors(kind: "topK", inputs: _inputs, count: 2, name: name, attributes: _attrs)
        }

    public func transposeTensor(_ tensor: MPSGraphTensor, dimension dimensionIndex: Int, withDimension dimensionIndex2: Int, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["dimensionIndex"] = dimensionIndex
            _attrs["dimensionIndex2"] = dimensionIndex2
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "transposeTensor", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func transpose(_ tensor: MPSGraphTensor, permutation: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["permutation"] = permutation
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "transpose", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func truncate(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "truncate", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func variance(of tensor: MPSGraphTensor, axes: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _attrs["axes"] = axes
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "variance", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

    public func variance(of tensor: MPSGraphTensor, mean meanTensor: MPSGraphTensor, axes: [NSNumber], name: String?) -> MPSGraphTensor
        {
            var _inputs: [MPSGraphTensor] = []
            var _attrs: [String: Any] = [:]
            _inputs.append(contentsOf: [] as [MPSGraphTensor])
            _inputs.append(tensor)
            _inputs.append(meanTensor)
            _attrs["axes"] = axes
            _attrs["_n"] = _inputs.count
            return recordTensor(kind: "variance", inputs: _inputs, shape: _inputs.first?.shape, dataType: _inputs.first?.dataType ?? .float32, name: name, attributes: _attrs)
        }

}
