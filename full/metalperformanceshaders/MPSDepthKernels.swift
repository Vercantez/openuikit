import Foundation

open class MPSCNNBinaryKernel: MPSKernel {
    public var clipRect: MTLRegion = MPSRectNoClip
    public var destinationFeatureChannelOffset: Int = 0
    public var destinationImageAllocator: any MPSImageAllocator = MPSImageDefaultAllocator()
    public private(set) var isBackwards: Bool = false
    public private(set) var isStateModified: Bool = false
    public var padding: any MPSNNPadding = MPSNNDefaultPadding(method: .validOnly)
    public private(set) var primaryDilationRateX: Int = 1
    public private(set) var primaryDilationRateY: Int = 1
    public var primaryEdgeMode: MPSImageEdgeMode = .clamp
    public private(set) var primaryKernelHeight: Int = 1
    public private(set) var primaryKernelWidth: Int = 1
    public var primaryOffset: MPSOffset = MPSOffset()
    public var primarySourceFeatureChannelMaxCount: Int = Int.max
    public var primarySourceFeatureChannelOffset: Int = 0
    public var primaryStrideInPixelsX: Int = 1
    public var primaryStrideInPixelsY: Int = 1
    public private(set) var secondaryDilationRateX: Int = 1
    public private(set) var secondaryDilationRateY: Int = 1
    public var secondaryEdgeMode: MPSImageEdgeMode = .clamp
    public private(set) var secondaryKernelHeight: Int = 1
    public private(set) var secondaryKernelWidth: Int = 1
    public var secondaryOffset: MPSOffset = MPSOffset()
    public var secondarySourceFeatureChannelMaxCount: Int = Int.max
    public var secondarySourceFeatureChannelOffset: Int = 0
    public var secondaryStrideInPixelsX: Int = 1
    public var secondaryStrideInPixelsY: Int = 1

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func appendBatchBarrier() -> Bool { false }

    open func isResultStateReusedAcrossBatch() -> Bool { false }

    open func encodingStorageSize(
        primaryImage: MPSImage,
        secondaryImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage?
    ) -> Int {
        _ = (primaryImage, secondaryImage, sourceStates, destinationImage)
        return 0
    }

    open func batchEncodingStorageSize(
        primaryImage: [MPSImage],
        secondaryImage: [MPSImage],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]?
    ) -> Int {
        _ = (primaryImage, secondaryImage, sourceStates, destinationImage)
        return 0
    }

    open func destinationImageDescriptor(
        forSourceImages sourceImages: [MPSImage],
        sourceStates: [MPSState]?
    ) -> MPSImageDescriptor {
        _ = sourceStates
        guard let first = sourceImages.first else {
            return MPSImageDescriptor(channelFormat: .float16, width: 1, height: 1, featureChannels: 1)
        }
        return MPSImageDescriptor(
            channelFormat: first.featureChannelFormat,
            width: first.width,
            height: first.height,
            featureChannels: first.featureChannels
        )
    }

    open func resultState(
        primaryImage: MPSImage,
        secondaryImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSState? {
        _ = (primaryImage, secondaryImage, sourceStates, destinationImage)
        return nil
    }

    open func resultStateBatch(
        primaryImage: [MPSImage],
        secondaryImage: [MPSImage],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSState]? {
        _ = (primaryImage, secondaryImage, sourceStates, destinationImage)
        return nil
    }

    open func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        primaryImage: MPSImage,
        secondaryImage: MPSImage,
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSState? {
        _ = commandBuffer
        return resultState(
            primaryImage: primaryImage,
            secondaryImage: secondaryImage,
            sourceStates: sourceStates,
            destinationImage: destinationImage
        )
    }

    open func temporaryResultStateBatch(
        commandBuffer: any MTLCommandBuffer,
        primaryImage: [MPSImage],
        secondaryImage: [MPSImage],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSState]? {
        _ = commandBuffer
        return resultStateBatch(
            primaryImage: primaryImage,
            secondaryImage: secondaryImage,
            sourceStates: sourceStates,
            destinationImage: destinationImage
        )
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        primaryImage: MPSImage,
        secondaryImage: MPSImage,
        destinationImage: MPSImage
    ) {
        _ = (commandBuffer, primaryImage, secondaryImage, destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSCNNBinaryKernel.encode")
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        primaryImage: MPSImage,
        secondaryImage: MPSImage
    ) -> MPSImage {
        let dest = destinationImageAllocator.image(
            for: commandBuffer,
            imageDescriptor: destinationImageDescriptor(forSourceImages: [primaryImage, secondaryImage], sourceStates: nil),
            kernel: self
        )
        encode(commandBuffer: commandBuffer, primaryImage: primaryImage, secondaryImage: secondaryImage, destinationImage: dest)
        return dest
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        primaryImage: MPSImage,
        secondaryImage: MPSImage,
        destinationState outState: UnsafeMutablePointer<MPSState?>,
        destinationStateIsTemporary isTemporary: Bool
    ) -> MPSImage {
        _ = isTemporary
        outState.pointee = nil
        return encode(commandBuffer: commandBuffer, primaryImage: primaryImage, secondaryImage: secondaryImage)
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        primaryImages: [MPSImage],
        secondaryImages: [MPSImage],
        destinationImages: [MPSImage]
    ) {
        if let primary = primaryImages.first, let secondary = secondaryImages.first, let dest = destinationImages.first {
            encode(commandBuffer: commandBuffer, primaryImage: primary, secondaryImage: secondary, destinationImage: dest)
        } else {
            MPSHostBoundary.refuseGPUEncode("MPSCNNBinaryKernel.encodeBatch")
        }
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        primaryImages primaryImage: [MPSImage],
        secondaryImages secondaryImage: [MPSImage]
    ) -> [MPSImage] {
        zip(primaryImage, secondaryImage).map {
            encode(commandBuffer: commandBuffer, primaryImage: $0, secondaryImage: $1)
        }
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        primaryImages: [MPSImage],
        secondaryImages: [MPSImage],
        destinationStates outState: UnsafeMutablePointer<NSArray?>,
        destinationStateIsTemporary isTemporary: Bool
    ) -> [MPSImage] {
        _ = isTemporary
        outState.pointee = nil
        return encodeBatch(commandBuffer: commandBuffer, primaryImages: primaryImages, secondaryImages: secondaryImages)
    }
}

open class MPSCNNMultiaryKernel: MPSKernel {
    public var clipRect: MTLRegion = MPSRectNoClip
    public var destinationFeatureChannelOffset: Int = 0
    public var destinationImageAllocator: any MPSImageAllocator = MPSImageDefaultAllocator()
    public private(set) var isBackwards: Bool = false
    public private(set) var isStateModified: Bool = false
    public var padding: any MPSNNPadding = MPSNNDefaultPadding(method: .validOnly)
    public private(set) var sourceCount: Int
    private var kernelWidths: [Int]
    private var kernelHeights: [Int]
    private var offsets: [MPSOffset]
    private var edgeModes: [MPSImageEdgeMode]
    private var dilationX: [Int]
    private var dilationY: [Int]
    private var strideX: [Int]
    private var strideY: [Int]
    private var channelOffsets: [Int]
    private var channelMaxCounts: [Int]

    public init(device: any MTLDevice, sourceCount: Int) {
        let count = max(sourceCount, 1)
        self.sourceCount = count
        self.kernelWidths = Array(repeating: 1, count: count)
        self.kernelHeights = Array(repeating: 1, count: count)
        self.offsets = Array(repeating: MPSOffset(), count: count)
        self.edgeModes = Array(repeating: .clamp, count: count)
        self.dilationX = Array(repeating: 1, count: count)
        self.dilationY = Array(repeating: 1, count: count)
        self.strideX = Array(repeating: 1, count: count)
        self.strideY = Array(repeating: 1, count: count)
        self.channelOffsets = Array(repeating: 0, count: count)
        self.channelMaxCounts = Array(repeating: Int.max, count: count)
        super.init(device: device)
    }

    public required init(device: any MTLDevice) {
        self.sourceCount = 1
        self.kernelWidths = [1]
        self.kernelHeights = [1]
        self.offsets = [MPSOffset()]
        self.edgeModes = [.clamp]
        self.dilationX = [1]
        self.dilationY = [1]
        self.strideX = [1]
        self.strideY = [1]
        self.channelOffsets = [0]
        self.channelMaxCounts = [Int.max]
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    private func validIndex(_ index: Int) -> Bool {
        kernelWidths.indices.contains(index)
    }

    open func kernelWidth(at index: Int) -> Int {
        validIndex(index) ? kernelWidths[index] : 0
    }

    open func kernelHeight(at index: Int) -> Int {
        validIndex(index) ? kernelHeights[index] : 0
    }

    open func offset(at index: Int) -> MPSOffset {
        validIndex(index) ? offsets[index] : MPSOffset()
    }

    open func edgeMode(at index: Int) -> MPSImageEdgeMode {
        validIndex(index) ? edgeModes[index] : .zero
    }

    open func dilationRateXatIndex(_ index: Int) -> Int {
        validIndex(index) ? dilationX[index] : 0
    }

    open func dilationRateYatIndex(_ index: Int) -> Int {
        validIndex(index) ? dilationY[index] : 0
    }

    open func stride(inPixelsXatIndex index: Int) -> Int {
        validIndex(index) ? strideX[index] : 0
    }

    open func stride(inPixelsYatIndex index: Int) -> Int {
        validIndex(index) ? strideY[index] : 0
    }

    open func sourceFeatureChannelOffset(at index: Int) -> Int {
        validIndex(index) ? channelOffsets[index] : 0
    }

    open func sourceFeatureChannelMaxCount(at index: Int) -> Int {
        validIndex(index) ? channelMaxCounts[index] : 0
    }

    open func setKernelWidth(_ width: Int, at index: Int) {
        guard validIndex(index) else { return }
        kernelWidths[index] = max(width, 1)
    }

    open func setKernelHeight(_ height: Int, at index: Int) {
        guard validIndex(index) else { return }
        kernelHeights[index] = max(height, 1)
    }

    open func setOffset(_ offset: MPSOffset, at index: Int) {
        guard validIndex(index) else { return }
        offsets[index] = offset
    }

    open func setEdgeMode(_ edgeMode: MPSImageEdgeMode, at index: Int) {
        guard validIndex(index) else { return }
        edgeModes[index] = edgeMode
    }

    open func setDilationRateX(_ dilationRate: Int, at index: Int) {
        guard validIndex(index) else { return }
        dilationX[index] = max(dilationRate, 1)
    }

    open func setDilationRateY(_ dilationRate: Int, at index: Int) {
        guard validIndex(index) else { return }
        dilationY[index] = max(dilationRate, 1)
    }

    open func setStrideInPixelsX(_ stride: Int, at index: Int) {
        guard validIndex(index) else { return }
        strideX[index] = max(stride, 1)
    }

    open func setStrideInPixelsY(_ stride: Int, at index: Int) {
        guard validIndex(index) else { return }
        strideY[index] = max(stride, 1)
    }

    open func setSourceFeatureChannelOffset(_ offset: Int, at index: Int) {
        guard validIndex(index) else { return }
        channelOffsets[index] = max(offset, 0)
    }

    open func setSourceFeatureChannelMaxCount(_ count: Int, at index: Int) {
        guard validIndex(index) else { return }
        channelMaxCounts[index] = max(count, 0)
    }

    open func appendBatchBarrier() -> Bool { false }

    open func isResultStateReusedAcrossBatch() -> Bool { false }

    open func destinationImageDescriptor(
        sourceImages: [MPSImage],
        sourceStates: [MPSState]?
    ) -> MPSImageDescriptor {
        _ = sourceStates
        guard let first = sourceImages.first else {
            return MPSImageDescriptor(channelFormat: .float16, width: 1, height: 1, featureChannels: 1)
        }
        return MPSImageDescriptor(
            channelFormat: first.featureChannelFormat,
            width: first.width,
            height: first.height,
            featureChannels: first.featureChannels
        )
    }

    open func resultState(
        sourceImages: [MPSImage],
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSState? {
        _ = (sourceImages, sourceStates, destinationImage)
        return nil
    }

    open func resultStateBatch(
        sourceImages: [[MPSImage]],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSState]? {
        _ = (sourceImages, sourceStates, destinationImage)
        return nil
    }

    open func temporaryResultState(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImage: [MPSImage],
        sourceStates: [MPSState]?,
        destinationImage: MPSImage
    ) -> MPSState? {
        _ = commandBuffer
        return resultState(sourceImages: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }

    open func temporaryResultStateBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImage: [[MPSImage]],
        sourceStates: [[MPSState]]?,
        destinationImage: [MPSImage]
    ) -> [MPSState]? {
        _ = commandBuffer
        return resultStateBatch(sourceImages: sourceImage, sourceStates: sourceStates, destinationImage: destinationImage)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        destinationImage: MPSImage
    ) {
        _ = (commandBuffer, sourceImages, destinationImage)
        MPSHostBoundary.refuseGPUEncode("MPSCNNMultiaryKernel.encode")
    }

    open func encode(commandBuffer: any MTLCommandBuffer, sourceImages: [MPSImage]) -> MPSImage {
        let dest = destinationImageAllocator.image(
            for: commandBuffer,
            imageDescriptor: destinationImageDescriptor(sourceImages: sourceImages, sourceStates: nil),
            kernel: self
        )
        encode(commandBuffer: commandBuffer, sourceImages: sourceImages, destinationImage: dest)
        return dest
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        destinationState outState: UnsafeMutablePointer<MPSState?>,
        destinationStateIsTemporary isTemporary: Bool
    ) -> MPSImage {
        _ = isTemporary
        outState.pointee = nil
        return encode(commandBuffer: commandBuffer, sourceImages: sourceImages)
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [[MPSImage]],
        destinationImages: [MPSImage]
    ) {
        if let sources = sourceImages.first, let dest = destinationImages.first {
            encode(commandBuffer: commandBuffer, sourceImages: sources, destinationImage: dest)
        } else {
            MPSHostBoundary.refuseGPUEncode("MPSCNNMultiaryKernel.encodeBatch")
        }
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImageBatches: [[MPSImage]]
    ) -> [MPSImage] {
        sourceImageBatches.map { encode(commandBuffer: commandBuffer, sourceImages: $0) }
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages sourceImageBatches: [[MPSImage]],
        destinationStates outState: UnsafeMutablePointer<NSArray?>,
        destinationStateIsTemporary isTemporary: Bool
    ) -> [MPSImage] {
        _ = isTemporary
        outState.pointee = nil
        return encodeBatch(commandBuffer: commandBuffer, sourceImages: sourceImageBatches)
    }
}

open class MPSSVGF: MPSKernel {
    public var bilateralFilterRadius: Int = 2
    public var bilateralFilterSigma: Float = 1
    public var channelCount: Int = 1
    public var channelCount2: Int = 1
    public var depthWeight: Float = 1
    public var luminanceWeight: Float = 1
    public var minimumFramesForVarianceEstimation: Int = 1
    public var normalWeight: Float = 1
    public var reprojectionThreshold: Float = 0.1
    public var temporalReprojectionBlendFactor: Float = 0.2
    public var temporalWeighting: MPSTemporalWeighting = .average
    public var varianceEstimationRadius: Int = 1
    public var varianceEstimationSigma: Float = 1
    public var variancePrefilterRadius: Int = 1
    public var variancePrefilterSigma: Float = 1

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = super.copy(with: zone, device: device)
        copied.bilateralFilterRadius = bilateralFilterRadius
        copied.bilateralFilterSigma = bilateralFilterSigma
        copied.channelCount = channelCount
        copied.channelCount2 = channelCount2
        copied.depthWeight = depthWeight
        copied.luminanceWeight = luminanceWeight
        copied.minimumFramesForVarianceEstimation = minimumFramesForVarianceEstimation
        copied.normalWeight = normalWeight
        copied.reprojectionThreshold = reprojectionThreshold
        copied.temporalReprojectionBlendFactor = temporalReprojectionBlendFactor
        copied.temporalWeighting = temporalWeighting
        copied.varianceEstimationRadius = varianceEstimationRadius
        copied.varianceEstimationSigma = varianceEstimationSigma
        copied.variancePrefilterRadius = variancePrefilterRadius
        copied.variancePrefilterSigma = variancePrefilterSigma
        return copied
    }

    open func encodeReprojection(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture: any MTLTexture,
        previousTexture: any MTLTexture,
        destinationTexture: any MTLTexture,
        previousLuminanceMomentsTexture: any MTLTexture,
        destinationLuminanceMomentsTexture: any MTLTexture,
        previousFrameCount previousFrameCountTexture: any MTLTexture,
        destinationFrameCount destinationFrameCountTexture: any MTLTexture,
        motionVectorTexture: (any MTLTexture)?,
        depthNormalTexture: (any MTLTexture)?,
        previousDepthNormalTexture: (any MTLTexture)?
    ) {
        _ = (
            commandBuffer, sourceTexture, previousTexture, destinationTexture,
            previousLuminanceMomentsTexture, destinationLuminanceMomentsTexture,
            previousFrameCountTexture, destinationFrameCountTexture,
            motionVectorTexture, depthNormalTexture, previousDepthNormalTexture
        )
        MPSHostBoundary.refuseGPUEncode("MPSSVGF.encodeReprojection")
    }

    open func encodeReprojection(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture: any MTLTexture,
        previousTexture: any MTLTexture,
        destinationTexture: any MTLTexture,
        previousLuminanceMomentsTexture: any MTLTexture,
        destinationLuminanceMomentsTexture: any MTLTexture,
        sourceTexture2: (any MTLTexture)?,
        previousTexture2: (any MTLTexture)?,
        destinationTexture2: (any MTLTexture)?,
        previousLuminanceMomentsTexture2: (any MTLTexture)?,
        destinationLuminanceMomentsTexture2: (any MTLTexture)?,
        previousFrameCount previousFrameCountTexture: any MTLTexture,
        destinationFrameCount destinationFrameCountTexture: any MTLTexture,
        motionVectorTexture: (any MTLTexture)?,
        depthNormalTexture: (any MTLTexture)?,
        previousDepthNormalTexture: (any MTLTexture)?
    ) {
        _ = (sourceTexture2, previousTexture2, destinationTexture2, previousLuminanceMomentsTexture2, destinationLuminanceMomentsTexture2)
        encodeReprojection(
            to: commandBuffer,
            sourceTexture: sourceTexture,
            previousTexture: previousTexture,
            destinationTexture: destinationTexture,
            previousLuminanceMomentsTexture: previousLuminanceMomentsTexture,
            destinationLuminanceMomentsTexture: destinationLuminanceMomentsTexture,
            previousFrameCount: previousFrameCountTexture,
            destinationFrameCount: destinationFrameCountTexture,
            motionVectorTexture: motionVectorTexture,
            depthNormalTexture: depthNormalTexture,
            previousDepthNormalTexture: previousDepthNormalTexture
        )
    }

    open func encodeVarianceEstimation(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture: any MTLTexture,
        luminanceMomentsTexture: any MTLTexture,
        destinationTexture: any MTLTexture,
        frameCount frameCountTexture: any MTLTexture,
        depthNormalTexture: (any MTLTexture)?
    ) {
        _ = (commandBuffer, sourceTexture, luminanceMomentsTexture, destinationTexture, frameCountTexture, depthNormalTexture)
        MPSHostBoundary.refuseGPUEncode("MPSSVGF.encodeVarianceEstimation")
    }

    open func encodeVarianceEstimation(
        to commandBuffer: any MTLCommandBuffer,
        sourceTexture: any MTLTexture,
        luminanceMomentsTexture: any MTLTexture,
        destinationTexture: any MTLTexture,
        sourceTexture2: (any MTLTexture)?,
        luminanceMomentsTexture2: (any MTLTexture)?,
        destinationTexture2: (any MTLTexture)?,
        frameCount frameCountTexture: any MTLTexture,
        depthNormalTexture: (any MTLTexture)?
    ) {
        _ = (sourceTexture2, luminanceMomentsTexture2, destinationTexture2)
        encodeVarianceEstimation(
            to: commandBuffer,
            sourceTexture: sourceTexture,
            luminanceMomentsTexture: luminanceMomentsTexture,
            destinationTexture: destinationTexture,
            frameCount: frameCountTexture,
            depthNormalTexture: depthNormalTexture
        )
    }

    open func encodeBilateralFilter(
        to commandBuffer: any MTLCommandBuffer,
        stepDistance: Int,
        sourceTexture: any MTLTexture,
        destinationTexture: any MTLTexture,
        depthNormalTexture: any MTLTexture
    ) {
        _ = (commandBuffer, stepDistance, sourceTexture, destinationTexture, depthNormalTexture)
        MPSHostBoundary.refuseGPUEncode("MPSSVGF.encodeBilateralFilter")
    }

    open func encodeBilateralFilter(
        to commandBuffer: any MTLCommandBuffer,
        stepDistance: Int,
        sourceTexture: any MTLTexture,
        destinationTexture: any MTLTexture,
        sourceTexture2: (any MTLTexture)?,
        destinationTexture2: (any MTLTexture)?,
        depthNormalTexture: any MTLTexture
    ) {
        _ = (sourceTexture2, destinationTexture2)
        encodeBilateralFilter(
            to: commandBuffer,
            stepDistance: stepDistance,
            sourceTexture: sourceTexture,
            destinationTexture: destinationTexture,
            depthNormalTexture: depthNormalTexture
        )
    }
}

open class MPSNDArrayMultiaryBase: MPSKernel {
    public var destinationArrayAllocator: any MPSNDArrayAllocator = MPSNDArrayDefaultAllocator()
    public private(set) var sourceCount: Int
    private var storedOffsets: [MPSNDArrayOffsets]
    private var storedKernelSizes: [MPSNDArraySizes]
    private var storedDilation: [MPSNDArraySizes]
    private var storedStrides: [MPSNDArrayOffsets]
    private var storedEdgeModes: [MPSImageEdgeMode]

    public required init(device: any MTLDevice, sourceCount count: Int) {
        let count = max(count, 1)
        self.sourceCount = count
        self.storedOffsets = Array(repeating: MPSNDArrayOffsets(), count: count)
        self.storedKernelSizes = Array(repeating: MPSNDArraySizes(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)), count: count)
        self.storedDilation = Array(repeating: MPSNDArraySizes(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)), count: count)
        self.storedStrides = Array(repeating: MPSNDArrayOffsets(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)), count: count)
        self.storedEdgeModes = Array(repeating: .clamp, count: count)
        super.init(device: device)
    }

    public required init(device: any MTLDevice) {
        self.sourceCount = 1
        self.storedOffsets = [MPSNDArrayOffsets()]
        self.storedKernelSizes = [MPSNDArraySizes(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))]
        self.storedDilation = [MPSNDArraySizes(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))]
        self.storedStrides = [MPSNDArrayOffsets(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))]
        self.storedEdgeModes = [.clamp]
        super.init(device: device)
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        _ = coder
        self.sourceCount = 1
        self.storedOffsets = [MPSNDArrayOffsets()]
        self.storedKernelSizes = [MPSNDArraySizes(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))]
        self.storedDilation = [MPSNDArraySizes(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))]
        self.storedStrides = [MPSNDArrayOffsets(dimensions: (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))]
        self.storedEdgeModes = [.clamp]
        super.init(device: device)
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = Self.init(device: device ?? self.device, sourceCount: sourceCount)
        copied.options = options
        copied.label = label
        copied.destinationArrayAllocator = destinationArrayAllocator
        copied.storedOffsets = storedOffsets
        copied.storedKernelSizes = storedKernelSizes
        copied.storedDilation = storedDilation
        copied.storedStrides = storedStrides
        copied.storedEdgeModes = storedEdgeModes
        return copied
    }

    open func destinationArrayDescriptor(forSourceArrays sources: [MPSNDArray], sourceState state: MPSState?) -> MPSNDArrayDescriptor {
        _ = state
        if let first = sources.first {
            return first.descriptor()
        }
        return MPSNDArrayDescriptor(dataType: .float32, shape: [1])
    }

    open func offsets(atSourceIndex sourceIndex: Int) -> MPSNDArrayOffsets {
        storedOffsets.indices.contains(sourceIndex) ? storedOffsets[sourceIndex] : MPSNDArrayOffsets()
    }

    open func kernelSizes(forSourceIndex sourceIndex: Int) -> MPSNDArraySizes {
        storedKernelSizes.indices.contains(sourceIndex) ? storedKernelSizes[sourceIndex] : MPSNDArraySizes()
    }

    open func dilationRates(forSourceIndex sourceIndex: Int) -> MPSNDArraySizes {
        storedDilation.indices.contains(sourceIndex) ? storedDilation[sourceIndex] : MPSNDArraySizes()
    }

    open func strides(forSourceIndex sourceIndex: Int) -> MPSNDArrayOffsets {
        storedStrides.indices.contains(sourceIndex) ? storedStrides[sourceIndex] : MPSNDArrayOffsets()
    }

    open func edgeMode(atSourceIndex sourceIndex: Int) -> MPSImageEdgeMode {
        storedEdgeModes.indices.contains(sourceIndex) ? storedEdgeModes[sourceIndex] : .clamp
    }

    open func resultState(
        forSourceArrays sourceArrays: [MPSNDArray],
        sourceStates: [MPSState]?,
        destinationArray: MPSNDArray
    ) -> MPSState? {
        _ = (sourceArrays, sourceStates, destinationArray)
        return nil
    }
}

open class MPSNDArrayMultiaryKernel: MPSNDArrayMultiaryBase {
    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: count)
    }

    public required init(device: any MTLDevice) {
        super.init(device: device, sourceCount: 1)
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        super.init(coder: coder, device: device)
    }

    open func encode(to cmdBuf: any MTLCommandBuffer, sourceArrays: [MPSNDArray], destinationArray destination: MPSNDArray) {
        _ = (cmdBuf, sourceArrays, destination)
        MPSHostBoundary.refuseGPUEncode("MPSNDArrayMultiaryKernel.encode")
    }

    open func encode(to cmdBuf: any MTLCommandBuffer, sourceArrays: [MPSNDArray]) -> MPSNDArray {
        let dest = destinationArrayAllocator.array(
            for: cmdBuf,
            arrayDescriptor: destinationArrayDescriptor(forSourceArrays: sourceArrays, sourceState: nil),
            kernel: self
        )
        encode(to: cmdBuf, sourceArrays: sourceArrays, destinationArray: dest)
        return dest
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        sourceArrays: [MPSNDArray],
        resultState outGradientState: MPSState?,
        destinationArray destination: MPSNDArray
    ) {
        _ = outGradientState
        encode(to: cmdBuf, sourceArrays: sourceArrays, destinationArray: destination)
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        sourceArrays: [MPSNDArray],
        resultState outGradientState: UnsafeMutablePointer<MPSState?>?,
        outputStateIsTemporary: Bool
    ) -> MPSNDArray {
        _ = outputStateIsTemporary
        outGradientState?.pointee = nil
        return encode(to: cmdBuf, sourceArrays: sourceArrays)
    }

    open func encode(
        to encoder: (any MTLComputeCommandEncoder)?,
        commandBuffer: any MTLCommandBuffer,
        sourceArrays: [MPSNDArray],
        destinationArray destination: MPSNDArray
    ) {
        _ = encoder
        encode(to: commandBuffer, sourceArrays: sourceArrays, destinationArray: destination)
    }
}

open class MPSNDArrayBinaryKernel: MPSNDArrayMultiaryKernel {
    public var primaryOffsets: MPSNDArrayOffsets { offsets(atSourceIndex: 0) }
    public var secondaryOffsets: MPSNDArrayOffsets { offsets(atSourceIndex: 1) }
    public var primaryKernelSizes: MPSNDArraySizes { kernelSizes(forSourceIndex: 0) }
    public var secondaryKernelSizes: MPSNDArraySizes { kernelSizes(forSourceIndex: 1) }
    public var primaryDilationRates: MPSNDArraySizes { dilationRates(forSourceIndex: 0) }
    public var secondaryDilationRates: MPSNDArraySizes { dilationRates(forSourceIndex: 1) }
    public var primaryStrides: MPSNDArrayOffsets { strides(forSourceIndex: 0) }
    public var secondaryStrides: MPSNDArrayOffsets { strides(forSourceIndex: 1) }
    public var primaryEdgeMode: MPSImageEdgeMode { edgeMode(atSourceIndex: 0) }
    public var secondaryEdgeMode: MPSImageEdgeMode { edgeMode(atSourceIndex: 1) }

    public required init(device: any MTLDevice) {
        super.init(device: device, sourceCount: 2)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: max(count, 2))
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        super.init(coder: coder, device: device)
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        primarySourceArray: MPSNDArray,
        secondarySourceArray: MPSNDArray,
        destinationArray destination: MPSNDArray
    ) {
        encode(to: cmdBuf, sourceArrays: [primarySourceArray, secondarySourceArray], destinationArray: destination)
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        primarySourceArray: MPSNDArray,
        secondarySourceArray: MPSNDArray
    ) -> MPSNDArray {
        encode(to: cmdBuf, sourceArrays: [primarySourceArray, secondarySourceArray])
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        primarySourceArray: MPSNDArray,
        secondarySourceArray: MPSNDArray,
        resultState outGradientState: MPSState?,
        destinationArray destination: MPSNDArray
    ) {
        encode(
            to: cmdBuf,
            sourceArrays: [primarySourceArray, secondarySourceArray],
            resultState: outGradientState,
            destinationArray: destination
        )
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        primarySourceArray: MPSNDArray,
        secondarySourceArray: MPSNDArray,
        resultState outGradientState: UnsafeMutablePointer<MPSState?>?,
        outputStateIsTemporary: Bool
    ) -> MPSNDArray {
        encode(
            to: cmdBuf,
            sourceArrays: [primarySourceArray, secondarySourceArray],
            resultState: outGradientState,
            outputStateIsTemporary: outputStateIsTemporary
        )
    }
}

open class MPSNDArrayUnaryKernel: MPSNDArrayMultiaryKernel {
    public var offsets: MPSNDArrayOffsets { offsets(atSourceIndex: 0) }
    public var kernelSizes: MPSNDArraySizes { kernelSizes(forSourceIndex: 0) }
    public var dilationRates: MPSNDArraySizes { dilationRates(forSourceIndex: 0) }
    public var strides: MPSNDArrayOffsets { strides(forSourceIndex: 0) }
    public var edgeMode: MPSImageEdgeMode { edgeMode(atSourceIndex: 0) }

    public required init(device: any MTLDevice) {
        super.init(device: device, sourceCount: 1)
    }

    public required init(device: any MTLDevice, sourceCount count: Int) {
        super.init(device: device, sourceCount: max(count, 1))
    }

    public override init(coder: NSCoder, device: any MTLDevice) {
        super.init(coder: coder, device: device)
    }

    open func encode(to cmdBuf: any MTLCommandBuffer, sourceArray: MPSNDArray, destinationArray destination: MPSNDArray) {
        encode(to: cmdBuf, sourceArrays: [sourceArray], destinationArray: destination)
    }

    open func encode(to cmdBuf: any MTLCommandBuffer, sourceArray: MPSNDArray) -> MPSNDArray {
        encode(to: cmdBuf, sourceArrays: [sourceArray])
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        sourceArray: MPSNDArray,
        resultState outGradientState: MPSState?,
        destinationArray destination: MPSNDArray
    ) {
        encode(to: cmdBuf, sourceArrays: [sourceArray], resultState: outGradientState, destinationArray: destination)
    }

    open func encode(
        to cmdBuf: any MTLCommandBuffer,
        sourceArray: MPSNDArray,
        resultState outGradientState: UnsafeMutablePointer<MPSState?>?,
        outputStateIsTemporary: Bool
    ) -> MPSNDArray {
        encode(
            to: cmdBuf,
            sourceArrays: [sourceArray],
            resultState: outGradientState,
            outputStateIsTemporary: outputStateIsTemporary
        )
    }
}
