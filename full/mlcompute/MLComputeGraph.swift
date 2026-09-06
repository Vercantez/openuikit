import Foundation

private struct MLCGraphEdge {
    var layer: MLCLayer
    var sources: [MLCTensor]
    var results: [MLCTensor]
    var disableUpdate: Bool
    var lossLabels: [MLCTensor]
}

open class MLCGraph: NSObject {
    public private(set) var device: MLCDevice?
    public internal(set) var layers: [MLCLayer] = []
    private var edges: [ObjectIdentifier: MLCGraphEdge] = [:]
    private var boundInputs: [String: MLCTensor] = [:]

    public override init() {
        super.init()
    }

    public var summarizedDOTDescription: String {
        var lines = ["digraph MLCGraph {"]
        for layer in layers {
            let sources = sourceTensors(for: layer).map { "t\($0.tensorID)" }.joined(separator: ",")
            let results = resultTensors(for: layer).map { "t\($0.tensorID)" }.joined(separator: ",")
            lines.append("  \"\(layer.label)#\(layer.layerID)\" [sources=\(sources) results=\(results)];")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    public func node(with layer: MLCLayer, source: MLCTensor) -> MLCTensor? {
        node(with: layer, sources: [source])
    }

    public func node(with layer: MLCLayer, sources: [MLCTensor]) -> MLCTensor? {
        node(with: layer, sources: sources, disableUpdate: false)
    }

    public func node(with layer: MLCLayer, sources: [MLCTensor], disableUpdate: Bool) -> MLCTensor? {
        node(with: layer, sources: sources, disableUpdate: disableUpdate, lossLabels: [])
    }

    public func node(with layer: MLCLayer, sources: [MLCTensor], lossLabels: [MLCTensor]) -> MLCTensor? {
        node(with: layer, sources: sources, disableUpdate: false, lossLabels: lossLabels)
    }

    private func node(
        with layer: MLCLayer,
        sources: [MLCTensor],
        disableUpdate: Bool,
        lossLabels: [MLCTensor]
    ) -> MLCTensor? {
        guard let result = mlcInferResultTensor(layer: layer, sources: sources) else { return nil }
        if !layers.contains(where: { $0 === layer }) {
            layers.append(layer)
        }
        edges[ObjectIdentifier(layer)] = MLCGraphEdge(
            layer: layer,
            sources: sources,
            results: [result],
            disableUpdate: disableUpdate,
            lossLabels: lossLabels
        )
        return result
    }

    public func sourceTensors(for layer: MLCLayer) -> [MLCTensor] {
        edges[ObjectIdentifier(layer)]?.sources ?? []
    }

    public func resultTensors(for layer: MLCLayer) -> [MLCTensor] {
        edges[ObjectIdentifier(layer)]?.results ?? []
    }

    public func concatenate(sources: [MLCTensor], dimension: Int) -> MLCTensor? {
        node(with: MLCConcatenationLayer(dimension: dimension), sources: sources)
    }

    public func split(source: MLCTensor, splitCount: Int, dimension: Int) -> [MLCTensor]? {
        guard let layer = Optional(MLCSplitLayer(splitCount: splitCount, dimension: dimension)) else { return nil }
        return linuxSplit(source: source, layer: layer)
    }

    public func split(source: MLCTensor, splitSectionLengths: [Int], dimension: Int) -> [MLCTensor]? {
        linuxSplit(source: source, layer: MLCSplitLayer(splitSectionLengths: splitSectionLengths, dimension: dimension))
    }

    public func reshape(shape: [Int], source: MLCTensor) -> MLCTensor? {
        guard let layer = MLCReshapeLayer(shape: shape) else { return nil }
        return node(with: layer, source: source)
    }

    public func transpose(dimensions: [Int], source: MLCTensor) -> MLCTensor? {
        guard let layer = MLCTransposeLayer(dimensions: dimensions) else { return nil }
        return node(with: layer, source: source)
    }

    public func gather(withDimension dimension: Int, source: MLCTensor, indices: MLCTensor) -> MLCTensor? {
        node(with: MLCGatherLayer(dimension: dimension), sources: [source, indices])
    }

    public func scatter(
        withDimension dimension: Int,
        source: MLCTensor,
        indices: MLCTensor,
        copyFrom: MLCTensor,
        reductionType: MLCReductionType
    ) -> MLCTensor? {
        guard let layer = MLCScatterLayer(dimension: dimension, reductionType: reductionType) else { return nil }
        return node(with: layer, sources: [source, indices, copyFrom])
    }

    public func bindAndWriteData(
        _ inputsData: [String: MLCTensorData],
        forInputs inputTensors: [String: MLCTensor],
        to device: MLCDevice,
        synchronous: Bool
    ) -> Bool {
        bindAndWriteData(inputsData, forInputs: inputTensors, to: device, batchSize: 0, synchronous: synchronous)
    }

    public func bindAndWriteData(
        _ inputsData: [String: MLCTensorData],
        forInputs inputTensors: [String: MLCTensor],
        to device: MLCDevice,
        batchSize: Int,
        synchronous: Bool
    ) -> Bool {
        _ = batchSize
        _ = synchronous
        guard device.actualDeviceType == .cpu else { return false }
        var ok = true
        for (name, tensor) in inputTensors {
            guard let data = inputsData[name] else { continue }
            if !tensor.bindAndWriteData(data, to: device) {
                ok = false
            }
        }
        boundInputs = inputTensors
        self.device = device
        return ok
    }

    private func linuxSplit(source: MLCTensor, layer: MLCSplitLayer) -> [MLCTensor]? {
        let dim = layer.dimension
        guard dim >= 0, dim < source.descriptor.shape.count else { return nil }
        let lengths: [Int]
        if let explicit = layer.splitSectionLengths {
            lengths = explicit
        } else {
            let size = source.descriptor.shape[dim]
            guard layer.splitCount > 0, size % layer.splitCount == 0 else { return nil }
            lengths = Array(repeating: size / layer.splitCount, count: layer.splitCount)
        }
        var outputs: [MLCTensor] = []
        for length in lengths {
            var shape = source.descriptor.shape
            shape[dim] = length
            guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: source.descriptor.dataType) else {
                return nil
            }
            outputs.append(MLCTensor(descriptor: descriptor))
        }
        if !layers.contains(where: { $0 === layer }) {
            layers.append(layer)
        }
        edges[ObjectIdentifier(layer)] = MLCGraphEdge(
            layer: layer,
            sources: [source],
            results: outputs,
            disableUpdate: false,
            lossLabels: []
        )
        return outputs
    }
}

func mlcInferResultTensor(layer: MLCLayer, sources: [MLCTensor]) -> MLCTensor? {
    guard let first = sources.first else { return nil }
    let dataType = first.descriptor.dataType
    if let activation = layer as? MLCActivationLayer {
        _ = activation
        return MLCTensor(descriptor: first.descriptor)
    }
    if let arithmetic = layer as? MLCArithmeticLayer {
        _ = arithmetic
        return MLCTensor(descriptor: first.descriptor)
    }
    if let comparison = layer as? MLCComparisonLayer {
        _ = comparison
        guard let descriptor = MLCTensorDescriptor(shape: first.descriptor.shape, dataType: .boolean) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let concat = layer as? MLCConcatenationLayer {
        var shape = first.descriptor.shape
        let dim = concat.dimension
        guard dim >= 0, dim < shape.count else { return nil }
        shape[dim] = sources.reduce(0) { $0 + (dim < $1.descriptor.shape.count ? $1.descriptor.shape[dim] : 0) }
        guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let reshape = layer as? MLCReshapeLayer {
        var inferred = reshape.shape
        if let minus = inferred.firstIndex(of: -1) {
            let known = inferred.filter { $0 >= 0 }.reduce(1, *)
            let volume = mlcShapeVolume(first.descriptor.shape)
            guard known > 0, volume % known == 0 else { return nil }
            inferred[minus] = volume / known
        }
        guard let descriptor = MLCTensorDescriptor(shape: inferred, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let transpose = layer as? MLCTransposeLayer {
        let dims = transpose.dimensions
        let shape = first.descriptor.shape
        guard dims.count == shape.count else { return nil }
        var permuted = Array(repeating: 0, count: shape.count)
        for (destination, sourceIndex) in dims.enumerated() {
            guard sourceIndex >= 0, sourceIndex < shape.count else { return nil }
            permuted[destination] = shape[sourceIndex]
        }
        guard let descriptor = MLCTensorDescriptor(shape: permuted, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let softmax = layer as? MLCSoftmaxLayer {
        _ = softmax
        return MLCTensor(descriptor: first.descriptor)
    }
    if let conv = layer as? MLCConvolutionLayer {
        let desc = conv.descriptor
        let input = first.descriptor.shape
        guard input.count == 4 else { return MLCTensor(descriptor: first.descriptor) }
        let spatial = desc.linuxOutputSpatial(inputHeight: input[2], inputWidth: input[3])
        let shape = [input[0], desc.outputFeatureChannelCount, spatial.0, spatial.1]
        guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let pool = layer as? MLCPoolingLayer {
        let desc = pool.descriptor
        let input = first.descriptor.shape
        guard input.count == 4 else { return MLCTensor(descriptor: first.descriptor) }
        let height = mlcSpatialOutput(
            input: input[2],
            kernel: desc.kernelSizes.height,
            stride: desc.strides.y,
            dilation: desc.dilationRates.y,
            padding: desc.paddingPolicy,
            isHeight: true
        ) ?? input[2]
        let width = mlcSpatialOutput(
            input: input[3],
            kernel: desc.kernelSizes.width,
            stride: desc.strides.x,
            dilation: desc.dilationRates.x,
            padding: desc.paddingPolicy,
            isHeight: false
        ) ?? input[3]
        let shape = [input[0], input[1], height, width]
        guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let fc = layer as? MLCFullyConnectedLayer {
        let batch = first.descriptor.shape.first ?? 1
        let out = fc.descriptor.outputFeatureChannelCount
        guard let descriptor = MLCTensorDescriptor(shape: [batch, out], dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let dropout = layer as? MLCDropoutLayer {
        _ = dropout
        return MLCTensor(descriptor: first.descriptor)
    }
    if let pad = layer as? MLCPaddingLayer {
        var shape = first.descriptor.shape
        if shape.count >= 4 {
            shape[2] += pad.paddingTop + pad.paddingBottom
            shape[3] += pad.paddingLeft + pad.paddingRight
        }
        guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let upsample = layer as? MLCUpsampleLayer {
        var shape = first.descriptor.shape
        if shape.count >= 4, upsample.shape.count >= 2 {
            shape[2] = upsample.shape[0]
            shape[3] = upsample.shape[1]
        }
        guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let reduction = layer as? MLCReductionLayer {
        var shape = first.descriptor.shape
        for dim in reduction.dimensions.sorted(by: >) {
            if dim >= 0, dim < shape.count {
                shape[dim] = 1
            }
        }
        guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let slice = layer as? MLCSliceLayer {
        var shape = first.descriptor.shape
        for index in slice.start.indices where index < shape.count {
            let step = slice.stride?[index] ?? 1
            let start = slice.start[index]
            let end = slice.end[index]
            shape[index] = max((end - start + step - 1) / max(step, 1), 0)
        }
        guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: dataType) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if let embed = layer as? MLCEmbeddingLayer {
        var shape = first.descriptor.shape
        shape.append(embed.descriptor.embeddingDimension)
        guard let descriptor = MLCTensorDescriptor(shape: shape, dataType: .float32) else { return nil }
        return MLCTensor(descriptor: descriptor)
    }
    if layer is MLCBatchNormalizationLayer
        || layer is MLCInstanceNormalizationLayer
        || layer is MLCGroupNormalizationLayer
        || layer is MLCLayerNormalizationLayer
        || layer is MLCGramMatrixLayer
        || layer is MLCMatMulLayer
        || layer is MLCLossLayer
        || layer is MLCLSTMLayer
        || layer is MLCMultiheadAttentionLayer
        || layer is MLCSelectionLayer
        || layer is MLCGatherLayer
        || layer is MLCScatterLayer
    {
        return MLCTensor(descriptor: first.descriptor)
    }
    return MLCTensor(descriptor: first.descriptor)
}

private let mlcExecuteFailure = MLComputeError.executeFailed(
    "MLCompute compile/execute requires BNNS or Metal Performance Shaders, which are not available on Linux"
)

open class MLCInferenceGraph: MLCGraph {
    public private(set) var deviceMemorySize: Int = 0
    private var graphObjects: [MLCGraph]
    private var inputs: [String: MLCTensor] = [:]
    private var outputs: [String: MLCTensor] = [:]
    private var compiled = false

    public override convenience init() {
        self.init(graphObjects: [])
    }

    public init(graphObjects: [MLCGraph]) {
        self.graphObjects = graphObjects
        super.init()
        for graph in graphObjects {
            layers.append(contentsOf: graph.layers)
        }
    }

    public func addInputs(_ inputs: [String: MLCTensor]) -> Bool {
        addInputs(inputs, lossLabels: nil, lossLabelWeights: nil)
    }

    public func addInputs(
        _ inputs: [String: MLCTensor],
        lossLabels: [String: MLCTensor]?,
        lossLabelWeights: [String: MLCTensor]?
    ) -> Bool {
        _ = lossLabels
        _ = lossLabelWeights
        guard !inputs.isEmpty else { return false }
        self.inputs.merge(inputs) { _, new in new }
        return true
    }

    public func addOutputs(_ outputs: [String: MLCTensor]) -> Bool {
        guard !outputs.isEmpty else { return false }
        self.outputs.merge(outputs) { _, new in new }
        return true
    }

    public func compile(options: MLCGraphCompilationOptions = [], device: MLCDevice) -> Bool {
        compile(options: options, device: device, inputTensors: nil, inputTensorsData: nil)
    }

    public func compile(
        options: MLCGraphCompilationOptions = [],
        device: MLCDevice,
        inputTensors: [String: MLCTensor]?,
        inputTensorsData: [String: MLCTensorData]?
    ) -> Bool {
        _ = options
        _ = inputTensors
        _ = inputTensorsData
        compiled = false
        deviceMemorySize = 0
        _ = compiled
        guard device.actualDeviceType == .cpu else { return false }
        return false
    }

    public func link(with graphs: [MLCInferenceGraph]) -> Bool {
        graphObjects.append(contentsOf: graphs)
        return !graphs.isEmpty
    }

    @discardableResult
    public func execute(
        inputsData: [String: MLCTensorData],
        batchSize: Int,
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        execute(
            inputsData: inputsData,
            lossLabelsData: nil,
            lossLabelWeightsData: nil,
            outputsData: nil,
            batchSize: batchSize,
            options: options,
            completionHandler: completionHandler
        )
    }

    @discardableResult
    public func execute(
        inputsData: [String: MLCTensorData],
        outputsData: [String: MLCTensorData]?,
        batchSize: Int,
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        execute(
            inputsData: inputsData,
            lossLabelsData: nil,
            lossLabelWeightsData: nil,
            outputsData: outputsData,
            batchSize: batchSize,
            options: options,
            completionHandler: completionHandler
        )
    }

    @discardableResult
    public func execute(
        inputsData: [String: MLCTensorData],
        lossLabelsData: [String: MLCTensorData]?,
        lossLabelWeightsData: [String: MLCTensorData]?,
        batchSize: Int,
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        execute(
            inputsData: inputsData,
            lossLabelsData: lossLabelsData,
            lossLabelWeightsData: lossLabelWeightsData,
            outputsData: nil,
            batchSize: batchSize,
            options: options,
            completionHandler: completionHandler
        )
    }

    @discardableResult
    public func execute(
        inputsData: [String: MLCTensorData],
        lossLabelsData: [String: MLCTensorData]?,
        lossLabelWeightsData: [String: MLCTensorData]?,
        outputsData: [String: MLCTensorData]?,
        batchSize: Int,
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        _ = inputsData
        _ = lossLabelsData
        _ = lossLabelWeightsData
        _ = outputsData
        _ = batchSize
        _ = options
        completionHandler?(nil, mlcFailClosedError(mlcExecuteFailure), 0)
        return false
    }

    @discardableResult
    public func execute(
        inputsData: [String: MLCTensorData],
        lossLabelsData: [String: MLCTensorData]? = nil,
        lossLabelWeightsData: [String: MLCTensorData]? = nil,
        outputsData: [String: MLCTensorData]? = nil,
        batchSize: Int,
        options: MLCExecutionOptions = []
    ) async throws -> (result: MLCTensor?, executionTime: TimeInterval) {
        _ = inputsData
        _ = lossLabelsData
        _ = lossLabelWeightsData
        _ = outputsData
        _ = batchSize
        _ = options
        throw mlcExecuteFailure
    }
}

open class MLCTrainingGraph: MLCGraph {
    public private(set) var optimizer: MLCOptimizer?
    public private(set) var deviceMemorySize: Int = 0
    private var graphObjects: [MLCGraph]
    private var lossLayer: MLCLayer?
    private var inputs: [String: MLCTensor] = [:]
    private var outputs: [String: MLCTensor] = [:]
    private var stopGradient: [MLCTensor] = []

    public init(graphObjects: [MLCGraph], lossLayer: MLCLayer?, optimizer: MLCOptimizer?) {
        self.graphObjects = graphObjects
        self.lossLayer = lossLayer
        self.optimizer = optimizer
        super.init()
        for graph in graphObjects {
            layers.append(contentsOf: graph.layers)
        }
        if let lossLayer, !layers.contains(where: { $0 === lossLayer }) {
            layers.append(lossLayer)
        }
    }

    public func addInputs(_ inputs: [String: MLCTensor], lossLabels: [String: MLCTensor]?) -> Bool {
        addInputs(inputs, lossLabels: lossLabels, lossLabelWeights: nil)
    }

    public func addInputs(
        _ inputs: [String: MLCTensor],
        lossLabels: [String: MLCTensor]?,
        lossLabelWeights: [String: MLCTensor]?
    ) -> Bool {
        _ = lossLabels
        _ = lossLabelWeights
        guard !inputs.isEmpty else { return false }
        self.inputs.merge(inputs) { _, new in new }
        return true
    }

    public func addOutputs(_ outputs: [String: MLCTensor]) -> Bool {
        guard !outputs.isEmpty else { return false }
        self.outputs.merge(outputs) { _, new in new }
        return true
    }

    public func compile(options: MLCGraphCompilationOptions = [], device: MLCDevice) -> Bool {
        compile(options: options, device: device, inputTensors: nil, inputTensorsData: nil)
    }

    public func compile(
        options: MLCGraphCompilationOptions = [],
        device: MLCDevice,
        inputTensors: [String: MLCTensor]?,
        inputTensorsData: [String: MLCTensorData]?
    ) -> Bool {
        _ = options
        _ = inputTensors
        _ = inputTensorsData
        _ = device
        deviceMemorySize = 0
        return false
    }

    public func compileOptimizer(_ optimizer: MLCOptimizer) -> Bool {
        self.optimizer = optimizer
        return false
    }

    public func link(with graphs: [MLCTrainingGraph]) -> Bool {
        graphObjects.append(contentsOf: graphs)
        return !graphs.isEmpty
    }

    public func allocateUserGradient(for tensor: MLCTensor) -> MLCTensor? {
        MLCTensor(descriptor: tensor.descriptor)
    }

    public func bindOptimizerData(
        _ data: [MLCTensorData],
        deviceData: [MLCTensorOptimizerDeviceData]?,
        with tensor: MLCTensor
    ) -> Bool {
        tensor.bindOptimizerData(data, deviceData: deviceData)
    }

    public func gradientData(forParameter parameter: MLCTensor, layer: MLCLayer) -> Data? {
        _ = layer
        return parameter.data
    }

    public func gradientTensor(forInput input: MLCTensor) -> MLCTensor? {
        MLCTensor(descriptor: input.descriptor)
    }

    public func resultGradientTensors(for layer: MLCLayer) -> [MLCTensor] {
        resultTensors(for: layer).map { MLCTensor(descriptor: $0.descriptor) }
    }

    public func sourceGradientTensors(for layer: MLCLayer) -> [MLCTensor] {
        sourceTensors(for: layer).map { MLCTensor(descriptor: $0.descriptor) }
    }

    public func setTrainingTensorParameters(_ parameters: [MLCTensorParameter]) -> Bool {
        !parameters.isEmpty
    }

    public func stopGradient(for tensors: [MLCTensor]) -> Bool {
        stopGradient.append(contentsOf: tensors)
        return !tensors.isEmpty
    }

    public func synchronizeUpdates() {}

    @discardableResult
    public func executeForward(
        batchSize: Int,
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        executeForward(batchSize: batchSize, options: options, outputsData: nil, completionHandler: completionHandler)
    }

    @discardableResult
    public func executeForward(
        batchSize: Int,
        options: MLCExecutionOptions = [],
        outputsData: [String: MLCTensorData]?,
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        _ = batchSize
        _ = options
        _ = outputsData
        completionHandler?(nil, mlcFailClosedError(mlcExecuteFailure), 0)
        return false
    }

    @discardableResult
    public func executeGradient(
        batchSize: Int,
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        executeGradient(batchSize: batchSize, options: options, outputsData: nil, completionHandler: completionHandler)
    }

    @discardableResult
    public func executeGradient(
        batchSize: Int,
        options: MLCExecutionOptions = [],
        outputsData: [String: MLCTensorData]?,
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        _ = batchSize
        _ = options
        _ = outputsData
        completionHandler?(nil, mlcFailClosedError(mlcExecuteFailure), 0)
        return false
    }

    @discardableResult
    public func executeOptimizerUpdate(
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        _ = options
        completionHandler?(nil, mlcFailClosedError(mlcExecuteFailure), 0)
        return false
    }

    @discardableResult
    public func execute(
        inputsData: [String: MLCTensorData],
        lossLabelsData: [String: MLCTensorData]?,
        lossLabelWeightsData: [String: MLCTensorData]?,
        batchSize: Int,
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        execute(
            inputsData: inputsData,
            lossLabelsData: lossLabelsData,
            lossLabelWeightsData: lossLabelWeightsData,
            outputsData: nil,
            batchSize: batchSize,
            options: options,
            completionHandler: completionHandler
        )
    }

    @discardableResult
    public func execute(
        inputsData: [String: MLCTensorData],
        lossLabelsData: [String: MLCTensorData]?,
        lossLabelWeightsData: [String: MLCTensorData]?,
        outputsData: [String: MLCTensorData]?,
        batchSize: Int,
        options: MLCExecutionOptions = [],
        completionHandler: MLCGraphCompletionHandler? = nil
    ) -> Bool {
        _ = inputsData
        _ = lossLabelsData
        _ = lossLabelWeightsData
        _ = outputsData
        _ = batchSize
        _ = options
        completionHandler?(nil, mlcFailClosedError(mlcExecuteFailure), 0)
        return false
    }

    @discardableResult
    public func executeForward(
        batchSize: Int,
        options: MLCExecutionOptions = [],
        outputsData: [String: MLCTensorData]? = nil
    ) async throws -> (result: MLCTensor?, executionTime: TimeInterval) {
        _ = batchSize
        _ = options
        _ = outputsData
        throw mlcExecuteFailure
    }

    @discardableResult
    public func executeGradient(
        batchSize: Int,
        options: MLCExecutionOptions = [],
        outputsData: [String: MLCTensorData]? = nil
    ) async throws -> TimeInterval {
        _ = batchSize
        _ = options
        _ = outputsData
        throw mlcExecuteFailure
    }

    @discardableResult
    public func executeOptimizerUpdate(options: MLCExecutionOptions = []) async throws -> TimeInterval {
        _ = options
        throw mlcExecuteFailure
    }
}
