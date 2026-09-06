import Foundation

open class MPSGraphExecutable: MPSGraphObject {
    public var options: MPSGraphOptions = .default
    public private(set) var feedTensors: [MPSGraphTensor]?
    public private(set) var targetTensors: [MPSGraphTensor]?
    let graph: MPSGraph?
    let loadedFromPackage: Bool

    init(graph: MPSGraph, feeds: [MPSGraphTensor: MPSGraphShapedType], targets: [MPSGraphTensor]) {
        self.graph = graph
        self.feedTensors = Array(feeds.keys)
        self.targetTensors = targets
        self.loadedFromPackage = false
        super.init()
    }

    public init(coreMLPackageAtURL coreMLPackageURL: URL, descriptor compilationDescriptor: MPSGraphCompilationDescriptor?) {
        self.graph = nil
        self.feedTensors = []
        self.targetTensors = []
        self.loadedFromPackage = true
        super.init()
        _ = coreMLPackageURL
        _ = compilationDescriptor
        MPSGraphHostBoundary.refuse(
            "MPSGraphExecutable.init(coreMLPackageAtURL:)",
            reason: "Core ML / MPSGraph packages require Apple runtime services"
        )
    }

    public init(coreMLPackageAtURL coreMLPackageURL: URL, compilationDescriptor: MPSGraphCompilationDescriptor?) {
        self.graph = nil
        self.feedTensors = []
        self.targetTensors = []
        self.loadedFromPackage = true
        super.init()
        _ = coreMLPackageURL
        _ = compilationDescriptor
        MPSGraphHostBoundary.refuse(
            "MPSGraphExecutable.init(coreMLPackageAtURL:compilationDescriptor:)",
            reason: "Core ML / MPSGraph packages require Apple runtime services"
        )
    }

    public init(package mpsgraphPackageURL: URL, descriptor compilationDescriptor: MPSGraphCompilationDescriptor?) {
        self.graph = nil
        self.feedTensors = []
        self.targetTensors = []
        self.loadedFromPackage = true
        super.init()
        _ = mpsgraphPackageURL
        _ = compilationDescriptor
        MPSGraphHostBoundary.refuse(
            "MPSGraphExecutable.init(package:)",
            reason: "serialized MPSGraph packages are not executed on Linux"
        )
    }

    public init(MPSGraphPackageAtURL mpsgraphPackageURL: URL, compilationDescriptor: MPSGraphCompilationDescriptor?) {
        self.graph = nil
        self.feedTensors = []
        self.targetTensors = []
        self.loadedFromPackage = true
        super.init()
        _ = mpsgraphPackageURL
        _ = compilationDescriptor
        MPSGraphHostBoundary.refuse(
            "MPSGraphExecutable.init(MPSGraphPackageAtURL:)",
            reason: "serialized MPSGraph packages are not executed on Linux"
        )
    }

    public func getOutputTypes(
        with device: MPSGraphDevice?,
        inputTypes: [MPSGraphType],
        compilationDescriptor: MPSGraphCompilationDescriptor?
    ) -> [MPSGraphShapedType]? {
        _ = device
        _ = compilationDescriptor
        if loadedFromPackage {
            MPSGraphHostBoundary.refuse("getOutputTypes", reason: "package executable has no CPU type inference")
            return nil
        }
        return targetTensors?.map { tensor in
            MPSGraphShapedType(shape: tensor.shape, dataType: tensor.dataType)
        }
    }

    public func specialize(
        with device: MPSGraphDevice?,
        inputTypes: [MPSGraphType],
        compilationDescriptor: MPSGraphCompilationDescriptor?
    ) {
        _ = device
        _ = inputTypes
        _ = compilationDescriptor
        if loadedFromPackage {
            MPSGraphHostBoundary.refuse("specialize", reason: "package executable cannot specialize without Apple compiler")
        }
    }

    public func serialize(package url: URL, descriptor: MPSGraphExecutableSerializationDescriptor?) {
        _ = url
        _ = descriptor
        MPSGraphHostBoundary.refuse(
            "serialize(package:)",
            reason: "serializing a Metal executable is unavailable on Linux"
        )
    }
}
