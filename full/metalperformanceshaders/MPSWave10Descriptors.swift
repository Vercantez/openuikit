import Foundation

// MARK: - Validated CNN descriptor kernels

private func mpsPositive(_ value: Int) -> Int { max(value, 1) }

open class MPSCNNNormalization: MPSCNNKernel {
    public var alpha: Float = 1
    public var beta: Float = 0.5
    public var delta: Float = 1

    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        super.init(device: device)
        self.kernelWidth = mpsPositive(kernelWidth)
        self.kernelHeight = mpsPositive(kernelHeight)
    }
    public required init(device: any MTLDevice) { super.init(device: device) }
    public override init?(coder: NSCoder, device: any MTLDevice) { return nil }
}

open class MPSCNNSpatialNormalization: MPSCNNNormalization {}

open class MPSCNNSpatialNormalizationGradient: MPSCNNGradientKernel {
    public var alpha: Float = 1
    public var beta: Float = 0.5
    public var delta: Float = 1
    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) {
        super.init(device: device); self.kernelWidth = mpsPositive(kernelWidth); self.kernelHeight = mpsPositive(kernelHeight)
    }
    public required init(device: any MTLDevice) { super.init(device: device) }
    public override init?(coder: NSCoder, device: any MTLDevice) { return nil }
}

open class MPSCNNSpatialNormalizationNode: MPSNNFilterNode {
    public var kernelWidth: Int
    public var kernelHeight: Int
    public init(source: MPSNNImageNode, kernelSize: Int) { _ = source; kernelWidth = mpsPositive(kernelSize); kernelHeight = mpsPositive(kernelSize); super.init() }
    public convenience init(source: MPSNNImageNode) { self.init(source: source, kernelSize: 5) }
}

open class MPSCNNSpatialNormalizationGradientNode: MPSNNGradientFilterNode {
    public var kernelWidth: Int; public var kernelHeight: Int
    public var alpha: Float = 1; public var beta: Float = 0.5; public var delta: Float = 1
    public init(sourceGradient: MPSNNImageNode, sourceImage: MPSNNImageNode, gradientState: MPSNNGradientStateNode, kernelSize: Int) {
        _ = (sourceGradient, sourceImage, gradientState); kernelWidth = mpsPositive(kernelSize); kernelHeight = mpsPositive(kernelSize); super.init()
    }
}

open class MPSCNNDilatedPoolingMax: MPSCNNPoolingMax {
    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int, dilationRateX: Int, dilationRateY: Int, strideInPixelsX: Int, strideInPixelsY: Int) {
        super.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight, strideInPixelsX: strideInPixelsX, strideInPixelsY: strideInPixelsY)
        self.dilationRateX = mpsPositive(dilationRateX); self.dilationRateY = mpsPositive(dilationRateY)
    }
    public required init(device: any MTLDevice) { super.init(device: device) }
    public override init?(coder: NSCoder, device: any MTLDevice) { return nil }
}

open class MPSCNNPoolingGradient: MPSCNNGradientKernel {
    public var sourceSize = MTLSize(width: 1, height: 1, depth: 1)
    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int, strideInPixelsX: Int, strideInPixelsY: Int) {
        super.init(device: device); self.kernelWidth=mpsPositive(kernelWidth); self.kernelHeight=mpsPositive(kernelHeight); self.strideInPixelsX=mpsPositive(strideInPixelsX); self.strideInPixelsY=mpsPositive(strideInPixelsY)
    }
    public convenience init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int) { self.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight, strideInPixelsX: 1, strideInPixelsY: 1) }
    public required init(device: any MTLDevice) { super.init(device: device) }
    public override init?(coder: NSCoder, device: any MTLDevice) { return nil }
}

open class MPSCNNPoolingAverageGradient: MPSCNNPoolingGradient { public var zeroPadSizeX=0; public var zeroPadSizeY=0 }
open class MPSCNNPoolingMaxGradient: MPSCNNPoolingGradient {}
open class MPSCNNPoolingL2Norm: MPSCNNPooling {}
open class MPSCNNPoolingL2NormGradient: MPSCNNPoolingGradient {}
open class MPSCNNDilatedPoolingMaxGradient: MPSCNNPoolingGradient {
    public init(device: any MTLDevice, kernelWidth: Int, kernelHeight: Int, dilationRateX: Int, dilationRateY: Int, strideInPixelsX: Int, strideInPixelsY: Int) {
        super.init(device: device, kernelWidth: kernelWidth, kernelHeight: kernelHeight, strideInPixelsX: strideInPixelsX, strideInPixelsY: strideInPixelsY)
        self.dilationRateX=mpsPositive(dilationRateX); self.dilationRateY=mpsPositive(dilationRateY)
    }
    public required init(device: any MTLDevice) { super.init(device: device) }
}

open class MPSCNNPoolingGradientNode: MPSNNGradientFilterNode {
    public let kernelWidth:Int, kernelHeight:Int, strideInPixelsX:Int, strideInPixelsY:Int
    public init(sourceGradient:MPSNNImageNode, sourceImage:MPSNNImageNode, gradientState:MPSNNGradientStateNode, kernelWidth:Int, kernelHeight:Int, strideInPixelsX:Int, strideInPixelsY:Int, paddingPolicy:(any MPSNNPadding)?) {
        _=(sourceGradient,sourceImage,gradientState,paddingPolicy); self.kernelWidth=mpsPositive(kernelWidth); self.kernelHeight=mpsPositive(kernelHeight); self.strideInPixelsX=mpsPositive(strideInPixelsX); self.strideInPixelsY=mpsPositive(strideInPixelsY); super.init()
    }
}
open class MPSCNNPoolingAverageGradientNode: MPSCNNPoolingGradientNode {}
open class MPSCNNPoolingMaxGradientNode: MPSCNNPoolingGradientNode {}
open class MPSCNNPoolingL2NormGradientNode: MPSCNNPoolingGradientNode {}

open class MPSCNNDilatedPoolingMaxNode: MPSCNNPoolingNode {
    public let dilationRateX:Int, dilationRateY:Int
    public init(source:MPSNNImageNode,kernelWidth:Int,kernelHeight:Int,strideInPixelsX:Int,strideInPixelsY:Int,dilationRateX:Int,dilationRateY:Int) {
        self.dilationRateX=mpsPositive(dilationRateX); self.dilationRateY=mpsPositive(dilationRateY)
        super.init(source: source, kernelWidth: kernelWidth, kernelHeight: kernelHeight, strideInPixelsX: strideInPixelsX, strideInPixelsY: strideInPixelsY)
    }
    public convenience init(source:MPSNNImageNode,filterSize:Int,stride:Int,dilationRate:Int) { self.init(source:source,kernelWidth:filterSize,kernelHeight:filterSize,strideInPixelsX:stride,strideInPixelsY:stride,dilationRateX:dilationRate,dilationRateY:dilationRate) }
    public convenience init(source:MPSNNImageNode,filterSize:Int) { self.init(source:source,filterSize:filterSize,stride:1,dilationRate:1) }
}

// Descriptor-only upsampling validates scale factors. Its inherited encode path
// remains explicitly refused by MPSCNNKernel on this host.
open class MPSCNNUpsampling: MPSCNNKernel {
    public let scaleFactorX:Double, scaleFactorY:Double, alignCorners:Bool
    public init(device:any MTLDevice, integerScaleFactorX:Int, integerScaleFactorY:Int, alignCorners:Bool=false) { scaleFactorX=Double(mpsPositive(integerScaleFactorX)); scaleFactorY=Double(mpsPositive(integerScaleFactorY)); self.alignCorners=alignCorners; super.init(device:device) }
    public required init(device:any MTLDevice) { scaleFactorX=1; scaleFactorY=1; alignCorners=false; super.init(device:device) }
}
open class MPSCNNUpsamplingBilinear:MPSCNNUpsampling {}
open class MPSCNNUpsamplingNearest:MPSCNNUpsampling {}
open class MPSCNNUpsamplingGradient:MPSCNNGradientKernel { public let scaleFactorX:Double,scaleFactorY:Double; public init(device:any MTLDevice,x:Int,y:Int){scaleFactorX=Double(mpsPositive(x));scaleFactorY=Double(mpsPositive(y));super.init(device:device)}; public required init(device:any MTLDevice){scaleFactorX=1;scaleFactorY=1;super.init(device:device)} }
open class MPSCNNUpsamplingBilinearGradient:MPSCNNUpsamplingGradient { public convenience init(device:any MTLDevice,integerScaleFactorX:Int,integerScaleFactorY:Int){self.init(device:device,x:integerScaleFactorX,y:integerScaleFactorY)} }
open class MPSCNNUpsamplingNearestGradient:MPSCNNUpsamplingGradient { public convenience init(device:any MTLDevice,integerScaleFactorX:Int,integerScaleFactorY:Int){self.init(device:device,x:integerScaleFactorX,y:integerScaleFactorY)} }

open class MPSCNNUpsamplingBilinearNode:MPSNNFilterNode { public let scaleFactorX:Double,scaleFactorY:Double,alignCorners:Bool; public init(source:MPSNNImageNode,integerScaleFactorX:Int,integerScaleFactorY:Int,alignCorners:Bool){_=source;scaleFactorX=Double(mpsPositive(integerScaleFactorX));scaleFactorY=Double(mpsPositive(integerScaleFactorY));self.alignCorners=alignCorners;super.init()}; public convenience init(source:MPSNNImageNode,integerScaleFactorX:Int,integerScaleFactorY:Int){self.init(source:source,integerScaleFactorX:integerScaleFactorX,integerScaleFactorY:integerScaleFactorY,alignCorners:false)} }
open class MPSCNNUpsamplingNearestNode:MPSNNFilterNode { public let scaleFactorX:Double,scaleFactorY:Double; public init(source:MPSNNImageNode,integerScaleFactorX:Int,integerScaleFactorY:Int){_=source;scaleFactorX=Double(mpsPositive(integerScaleFactorX));scaleFactorY=Double(mpsPositive(integerScaleFactorY));super.init()} }
open class MPSCNNUpsamplingBilinearGradientNode:MPSNNGradientFilterNode { public let scaleFactorX:Double,scaleFactorY:Double; public init(sourceGradient:MPSNNImageNode,sourceImage:MPSNNImageNode,gradientState:MPSNNGradientStateNode,scaleFactorX:Double,scaleFactorY:Double){_=(sourceGradient,sourceImage,gradientState);self.scaleFactorX=max(scaleFactorX,1);self.scaleFactorY=max(scaleFactorY,1);super.init()} }
open class MPSCNNUpsamplingNearestGradientNode:MPSCNNUpsamplingBilinearGradientNode {}


// MARK: - Legacy neuron descriptors

open class MPSCNNNeuronNode: MPSNNFilterNode {
    public let descriptor: MPSNNNeuronDescriptor
    public var a:Float { descriptor.a }; public var b:Float { descriptor.b }; public var c:Float { descriptor.c }
    public init(source:MPSNNImageNode, descriptor:MPSNNNeuronDescriptor) { _=source; self.descriptor=descriptor.copy() as! MPSNNNeuronDescriptor; super.init() }
}
open class MPSCNNNeuronGradientNode:MPSNNGradientFilterNode { public let descriptor:MPSNNNeuronDescriptor; public init(sourceGradient:MPSNNImageNode,sourceImage:MPSNNImageNode,gradientState:MPSNNGradientStateNode,descriptor:MPSNNNeuronDescriptor){_=(sourceGradient,sourceImage,gradientState);self.descriptor=descriptor.copy() as! MPSNNNeuronDescriptor;super.init()} }

private func mpsNeuron(_ type:MPSCNNNeuronType,_ a:Float=0,_ b:Float=0,_ c:Float=0)->MPSNNNeuronDescriptor { .cnnNeuronDescriptor(with:type,a:a,b:b,c:c) }
open class MPSCNNNeuronAbsolute:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.absolute))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronELU:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.ELU))}
 public init(device:any MTLDevice,a:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.ELU,a))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronExponential:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.exponential))}
 public init(device:any MTLDevice,a:Float,b:Float,c:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.exponential,a,b,c))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronHardSigmoid:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.hardSigmoid))}
 public init(device:any MTLDevice,a:Float,b:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.hardSigmoid,a,b))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronLinear:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.linear))}
 public init(device:any MTLDevice,a:Float,b:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.linear,a,b))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronLogarithm:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.logarithm))}
 public init(device:any MTLDevice,a:Float,b:Float,c:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.logarithm,a,b,c))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronPower:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.power))}
 public init(device:any MTLDevice,a:Float,b:Float,c:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.power,a,b,c))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronReLUN:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.reLUN))}
 public init(device:any MTLDevice,a:Float,b:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.reLUN,a,b))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronSigmoid:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.sigmoid))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronSoftPlus:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.softPlus))}
 public init(device:any MTLDevice,a:Float,b:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.softPlus,a,b))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronSoftSign:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.softSign))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronTanH:MPSCNNNeuron {
 public required init(device:any MTLDevice){super.init(device:device,neuronDescriptor:mpsNeuron(.tanH))}
 public init(device:any MTLDevice,a:Float,b:Float){super.init(device:device,neuronDescriptor:mpsNeuron(.tanH,a,b))}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}
}
open class MPSCNNNeuronAbsoluteNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode){super.init(source:source,descriptor:mpsNeuron(.absolute))}
}
open class MPSCNNNeuronELUNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float){super.init(source:source,descriptor:mpsNeuron(.ELU,a))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0)}
}
open class MPSCNNNeuronExponentialNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float,b:Float,c:Float){super.init(source:source,descriptor:mpsNeuron(.exponential,a,b,c))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0, b: 0, c: 0)}
}
open class MPSCNNNeuronHardSigmoidNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float,b:Float){super.init(source:source,descriptor:mpsNeuron(.hardSigmoid,a,b))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0, b: 0)}
}
open class MPSCNNNeuronLinearNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float,b:Float){super.init(source:source,descriptor:mpsNeuron(.linear,a,b))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0, b: 0)}
}
open class MPSCNNNeuronLogarithmNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float,b:Float,c:Float){super.init(source:source,descriptor:mpsNeuron(.logarithm,a,b,c))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0, b: 0, c: 0)}
}
open class MPSCNNNeuronPowerNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float,b:Float,c:Float){super.init(source:source,descriptor:mpsNeuron(.power,a,b,c))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0, b: 0, c: 0)}
}
open class MPSCNNNeuronReLUNNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float,b:Float){super.init(source:source,descriptor:mpsNeuron(.reLUN,a,b))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0, b: 0)}
}
open class MPSCNNNeuronSigmoidNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode){super.init(source:source,descriptor:mpsNeuron(.sigmoid))}
}
open class MPSCNNNeuronSoftPlusNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float,b:Float){super.init(source:source,descriptor:mpsNeuron(.softPlus,a,b))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0, b: 0)}
}
open class MPSCNNNeuronSoftSignNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode){super.init(source:source,descriptor:mpsNeuron(.softSign))}
}
open class MPSCNNNeuronTanHNode:MPSCNNNeuronNode {
 public init(source:MPSNNImageNode,a:Float,b:Float){super.init(source:source,descriptor:mpsNeuron(.tanH,a,b))}
 public convenience init(source:MPSNNImageNode){self.init(source:source, a: 0, b: 0)}
}
open class MPSCNNNeuronPReLU:MPSCNNNeuron { public let coefficients:Data; public init(device:any MTLDevice,a:UnsafePointer<Float>,count:Int){coefficients=Data(bytes:a,count:max(count,0)*4);super.init(device:device,neuronDescriptor:.cnnNeuronPReLUDescriptor(with:coefficients,noCopy:false))}; public required init(device:any MTLDevice){coefficients=Data();super.init(device:device)} }
open class MPSCNNNeuronPReLUNode:MPSCNNNeuronNode { public init(source:MPSNNImageNode,aData:Data){super.init(source:source,descriptor:.cnnNeuronPReLUDescriptor(with:aData,noCopy:false))} }
open class MPSCNNNeuronGeLUNode:MPSCNNNeuronNode { public init(source:MPSNNImageNode){super.init(source:source,descriptor:mpsNeuron(.geLU))} }
open class MPSCNNNeuronReLUNode:MPSCNNNeuronNode { public init(source:MPSNNImageNode,a:Float){super.init(source:source,descriptor:mpsNeuron(.reLU,a))}; public convenience init(source:MPSNNImageNode){self.init(source:source,a:0)} }

// MARK: - Reduction configuration
open class MPSNNReduceUnary:MPSCNNKernel { public var clipRectSource=MPSRectNoClip }
open class MPSNNReduceBinary:MPSCNNBinaryKernel { public var primarySourceClipRect=MPSRectNoClip; public var secondarySourceClipRect=MPSRectNoClip }
open class MPSNNReduceColumnMax:MPSNNReduceUnary {}
open class MPSNNReduceColumnMean:MPSNNReduceUnary {}
open class MPSNNReduceColumnMin:MPSNNReduceUnary {}
open class MPSNNReduceColumnSum:MPSNNReduceUnary {}
open class MPSNNReduceFeatureChannelsAndWeightsMean:MPSNNReduceUnary {}
open class MPSNNReduceFeatureChannelsArgumentMax:MPSNNReduceUnary {}
open class MPSNNReduceFeatureChannelsArgumentMin:MPSNNReduceUnary {}
open class MPSNNReduceFeatureChannelsMax:MPSNNReduceUnary {}
open class MPSNNReduceFeatureChannelsMean:MPSNNReduceUnary {}
open class MPSNNReduceFeatureChannelsMin:MPSNNReduceUnary {}
open class MPSNNReduceRowMax:MPSNNReduceUnary {}
open class MPSNNReduceRowMean:MPSNNReduceUnary {}
open class MPSNNReduceRowMin:MPSNNReduceUnary {}
open class MPSNNReduceRowSum:MPSNNReduceUnary {}
open class MPSNNReduceFeatureChannelsSum:MPSNNReduceUnary { public var weight:Float=1 }
open class MPSNNReduceFeatureChannelsAndWeightsSum:MPSNNReduceUnary { public let doWeightedSumByNonZeroWeights:Bool; public init(device:any MTLDevice,doWeightedSumByNonZeroWeights:Bool){self.doWeightedSumByNonZeroWeights=doWeightedSumByNonZeroWeights;super.init(device:device)}; public required init(device:any MTLDevice){doWeightedSumByNonZeroWeights=false;super.init(device:device)} }
open class MPSNNReductionColumnMaxNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionColumnMeanNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionColumnMinNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionColumnSumNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionFeatureChannelsArgumentMaxNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionFeatureChannelsArgumentMinNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionFeatureChannelsMaxNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionFeatureChannelsMeanNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionFeatureChannelsMinNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionRowMaxNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionRowMeanNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionRowMinNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionRowSumNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionSpatialMeanNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionFeatureChannelsSumNode:MPSNNFilterNode { public var weight:Float=1; public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSNNReductionSpatialMeanGradientNode:MPSNNGradientFilterNode { public init(sourceGradient:MPSNNImageNode,sourceImage:MPSNNImageNode,gradientState:MPSNNGradientStateNode){_=(sourceGradient,sourceImage,gradientState);super.init()} }

open class MPSCNNAdd:MPSCNNBinaryKernel {}
open class MPSCNNDivide:MPSCNNBinaryKernel {}
open class MPSCNNMultiply:MPSCNNBinaryKernel {}
open class MPSCNNSubtract:MPSCNNBinaryKernel {}
open class MPSCNNAddGradient:MPSCNNArithmeticGradient {}
open class MPSCNNMultiplyGradient:MPSCNNArithmeticGradient {}
open class MPSCNNSubtractGradient:MPSCNNArithmeticGradient {}
open class MPSCNNSoftMax:MPSCNNKernel {}
open class MPSCNNLogSoftMax:MPSCNNKernel {}
open class MPSCNNSoftMaxGradient:MPSCNNGradientKernel {}
open class MPSCNNLogSoftMaxGradient:MPSCNNGradientKernel {}
open class MPSCNNSoftMaxNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSCNNLogSoftMaxNode:MPSNNFilterNode { public init(source:MPSNNImageNode){_=source;super.init()} }
open class MPSCNNSoftMaxGradientNode:MPSNNGradientFilterNode { public init(sourceGradient:MPSNNImageNode,sourceImage:MPSNNImageNode,gradientState:MPSNNGradientStateNode){_=(sourceGradient,sourceImage,gradientState);super.init()} }
open class MPSCNNLogSoftMaxGradientNode:MPSNNGradientFilterNode { public init(sourceGradient:MPSNNImageNode,sourceImage:MPSNNImageNode,gradientState:MPSNNGradientStateNode){_=(sourceGradient,sourceImage,gradientState);super.init()} }

open class MPSTemporalAA:MPSKernel,NSSecureCoding {
 public static var supportsSecureCoding:Bool { true }; public var blendFactor:Float=0.1
 public required init(device:any MTLDevice){super.init(device:device)}
 public override init?(coder:NSCoder,device:any MTLDevice){return nil}; public required override init?(coder:NSCoder){return nil}; public func encode(with coder:NSCoder){_=coder}
 open override func copy(with zone:NSZone?=nil,device:(any MTLDevice)?=nil)->Self { let x=MPSTemporalAA(device:device ?? self.device);x.blendFactor=blendFactor;return x as! Self }
 open func encode(commandBuffer:any MTLCommandBuffer,sourceTexture:any MTLTexture,previousTexture:any MTLTexture,destinationTexture:any MTLTexture,motionVectorTexture:any MTLTexture,depthTexture:any MTLTexture){_=(commandBuffer,sourceTexture,previousTexture,destinationTexture,motionVectorTexture,depthTexture);MPSHostBoundary.refuseGPUEncode("MPSTemporalAA.encode")}
}
