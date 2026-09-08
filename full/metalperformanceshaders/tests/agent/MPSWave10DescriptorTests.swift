import Foundation
import MetalPerformanceShaders

func testMPSWave10NormalizationPoolingDescriptors() {
    let d=MPSHostDevice.shared, image=MPSNNImageNode(), state=MPSNNGradientStateNode()
    let spatial=MPSCNNSpatialNormalization(device:d,kernelWidth:3,kernelHeight:5); spatial.alpha=2; spatial.beta=3; spatial.delta=4
    precondition(spatial.kernelWidth==3 && spatial.kernelHeight==5 && spatial.alpha==2)
    let sg=MPSCNNSpatialNormalizationGradient(device:d,kernelWidth:7,kernelHeight:9); precondition(sg.kernelWidth==7)
    let sn=MPSCNNSpatialNormalizationNode(source:image,kernelSize:3); precondition(sn.kernelHeight==3)
    let sgn=MPSCNNSpatialNormalizationGradientNode(sourceGradient:image,sourceImage:image,gradientState:state,kernelSize:5); sgn.delta=9; precondition(sgn.kernelWidth==5 && sgn.delta==9)
    let dil=MPSCNNDilatedPoolingMax(device:d,kernelWidth:3,kernelHeight:4,dilationRateX:2,dilationRateY:3,strideInPixelsX:1,strideInPixelsY:2); precondition(dil.dilationRateY==3)
    let dn=MPSCNNDilatedPoolingMaxNode(source:image,kernelWidth:3,kernelHeight:5,strideInPixelsX:2,strideInPixelsY:3,dilationRateX:4,dilationRateY:5); precondition(dn.kernelHeight==5 && dn.dilationRateX==4)
    let p=MPSCNNPoolingAverageGradient(device:d,kernelWidth:3,kernelHeight:2,strideInPixelsX:2,strideInPixelsY:1); p.zeroPadSizeX=4; p.sourceSize=MTLSize(width:9,height:8,depth:1); precondition(p.zeroPadSizeX==4 && p.sourceSize.width==9)
    _=MPSCNNPoolingMaxGradient(device:d,kernelWidth:2,kernelHeight:2)
    _=MPSCNNPoolingL2Norm(device:d,kernelWidth:2,kernelHeight:3,strideInPixelsX:1,strideInPixelsY:1)
    _=MPSCNNPoolingL2NormGradient(device:d,kernelWidth:2,kernelHeight:3)
    let pn=MPSCNNPoolingGradientNode(sourceGradient:image,sourceImage:image,gradientState:state,kernelWidth:3,kernelHeight:4,strideInPixelsX:2,strideInPixelsY:3,paddingPolicy:nil); precondition(pn.kernelWidth==3 && pn.strideInPixelsY==3)
    _=MPSCNNPoolingAverageGradientNode(sourceGradient:image,sourceImage:image,gradientState:state,kernelWidth:1,kernelHeight:1,strideInPixelsX:1,strideInPixelsY:1,paddingPolicy:nil)
}

func testMPSWave10UpsamplingDescriptorsFailClosed() {
    let d=MPSHostDevice.shared, image=MPSNNImageNode(), state=MPSNNGradientStateNode()
    let b=MPSCNNUpsamplingBilinear(device:d,integerScaleFactorX:2,integerScaleFactorY:3,alignCorners:true); precondition(b.scaleFactorX==2 && b.alignCorners)
    let n=MPSCNNUpsamplingNearest(device:d,integerScaleFactorX:4,integerScaleFactorY:5); precondition(n.scaleFactorY==5)
    let bn=MPSCNNUpsamplingBilinearNode(source:image,integerScaleFactorX:2,integerScaleFactorY:4,alignCorners:true); precondition(bn.scaleFactorY==4 && bn.alignCorners)
    let nn=MPSCNNUpsamplingNearestNode(source:image,integerScaleFactorX:3,integerScaleFactorY:2); precondition(nn.scaleFactorX==3)
    _=MPSCNNUpsamplingBilinearGradient(device:d,integerScaleFactorX:2,integerScaleFactorY:2)
    _=MPSCNNUpsamplingNearestGradient(device:d,integerScaleFactorX:3,integerScaleFactorY:3)
    _=MPSCNNUpsamplingBilinearGradientNode(sourceGradient:image,sourceImage:image,gradientState:state,scaleFactorX:2,scaleFactorY:3)
    _=MPSCNNUpsamplingNearestGradientNode(sourceGradient:image,sourceImage:image,gradientState:state,scaleFactorX:4,scaleFactorY:5)
    MPSHostBoundary.reset(); b.encode(commandBuffer:d.makeCommandBuffer(),sourceImage:MPSImage(device:d,imageDescriptor:.init(channelFormat:.unorm8,width:1,height:1,featureChannels:1)),destinationImage:MPSImage(device:d,imageDescriptor:.init(channelFormat:.unorm8,width:2,height:3,featureChannels:1))); precondition(MPSHostBoundary.lastRefusedAPI != nil)
}

func testMPSWave10NeuronDescriptors() {
    let d=MPSHostDevice.shared, image=MPSNNImageNode()
    let kernels:[MPSCNNNeuron] = [MPSCNNNeuronAbsolute(device:d),MPSCNNNeuronELU(device:d,a:2),MPSCNNNeuronExponential(device:d,a:2,b:3,c:4),MPSCNNNeuronHardSigmoid(device:d,a:2,b:3),MPSCNNNeuronLinear(device:d,a:4,b:5),MPSCNNNeuronLogarithm(device:d,a:2,b:3,c:4),MPSCNNNeuronPower(device:d,a:2,b:3,c:4),MPSCNNNeuronReLUN(device:d,a:2,b:6),MPSCNNNeuronSigmoid(device:d),MPSCNNNeuronSoftPlus(device:d,a:2,b:3),MPSCNNNeuronSoftSign(device:d),MPSCNNNeuronTanH(device:d,a:2,b:3)]
    precondition(kernels.map(\.neuronType)==[.absolute,.ELU,.exponential,.hardSigmoid,.linear,.logarithm,.power,.reLUN,.sigmoid,.softPlus,.softSign,.tanH])
    let nodes:[MPSCNNNeuronNode] = [MPSCNNNeuronAbsoluteNode(source:image),MPSCNNNeuronELUNode(source:image,a:2),MPSCNNNeuronExponentialNode(source:image,a:2,b:3,c:4),MPSCNNNeuronGeLUNode(source:image),MPSCNNNeuronHardSigmoidNode(source:image,a:2,b:3),MPSCNNNeuronLinearNode(source:image,a:2,b:3),MPSCNNNeuronLogarithmNode(source:image,a:2,b:3,c:4),MPSCNNNeuronPowerNode(source:image,a:2,b:3,c:4),MPSCNNNeuronReLUNNode(source:image,a:2,b:3),MPSCNNNeuronReLUNode(source:image,a:2),MPSCNNNeuronSigmoidNode(source:image),MPSCNNNeuronSoftPlusNode(source:image,a:2,b:3),MPSCNNNeuronSoftSignNode(source:image),MPSCNNNeuronTanHNode(source:image,a:2,b:3)]
    precondition(nodes.count==14 && nodes[4].a==2)
    var values:[Float]=[1,2,3]; let prelu=values.withUnsafeBufferPointer{MPSCNNNeuronPReLU(device:d,a:$0.baseAddress!,count:$0.count)}; precondition(prelu.coefficients.count==12)
    let pn=MPSCNNNeuronPReLUNode(source:image,aData:Data(bytes:&values,count:12)); precondition(pn.descriptor.data?.count==12)
    let gn=MPSCNNNeuronGradientNode(sourceGradient:image,sourceImage:image,gradientState:MPSNNGradientStateNode(),descriptor:mpsTestNeuronDescriptor()); precondition(gn.descriptor.a==7)
}
private func mpsTestNeuronDescriptor()->MPSNNNeuronDescriptor { .cnnNeuronDescriptor(with:.linear,a:7,b:8,c:9) }

func testMPSWave10ReductionDescriptors() {
    let d=MPSHostDevice.shared, image=MPSNNImageNode()
    let kernels:[MPSNNReduceUnary]=[MPSNNReduceColumnMax(device:d),MPSNNReduceColumnMean(device:d),MPSNNReduceColumnMin(device:d),MPSNNReduceColumnSum(device:d),MPSNNReduceFeatureChannelsAndWeightsMean(device:d),MPSNNReduceFeatureChannelsArgumentMax(device:d),MPSNNReduceFeatureChannelsArgumentMin(device:d),MPSNNReduceFeatureChannelsMax(device:d),MPSNNReduceFeatureChannelsMean(device:d),MPSNNReduceFeatureChannelsMin(device:d),MPSNNReduceRowMax(device:d),MPSNNReduceRowMean(device:d),MPSNNReduceRowMin(device:d),MPSNNReduceRowSum(device:d)]
    kernels[0].offset=MPSOffset(x:2,y:3,z:4); kernels[0].clipRectSource=MTLRegion(origin:.init(x:1,y:2,z:0),size:.init(width:3,height:4,depth:1)); precondition(kernels.count==14 && kernels[0].offset.y==3)
    let sum=MPSNNReduceFeatureChannelsSum(device:d); sum.weight=2.5; precondition(sum.weight==2.5)
    let weighted=MPSNNReduceFeatureChannelsAndWeightsSum(device:d,doWeightedSumByNonZeroWeights:true); precondition(weighted.doWeightedSumByNonZeroWeights)
    let nodes:[MPSNNFilterNode]=[MPSNNReductionColumnMaxNode(source:image),MPSNNReductionColumnMeanNode(source:image),MPSNNReductionColumnMinNode(source:image),MPSNNReductionColumnSumNode(source:image),MPSNNReductionFeatureChannelsArgumentMaxNode(source:image),MPSNNReductionFeatureChannelsArgumentMinNode(source:image),MPSNNReductionFeatureChannelsMaxNode(source:image),MPSNNReductionFeatureChannelsMeanNode(source:image),MPSNNReductionFeatureChannelsMinNode(source:image),MPSNNReductionRowMaxNode(source:image),MPSNNReductionRowMeanNode(source:image),MPSNNReductionRowMinNode(source:image),MPSNNReductionRowSumNode(source:image),MPSNNReductionSpatialMeanNode(source:image)]
    precondition(nodes.count==14)
    let sn=MPSNNReductionFeatureChannelsSumNode(source:image); sn.weight=4; precondition(sn.weight==4)
    _=MPSNNReductionSpatialMeanGradientNode(sourceGradient:image,sourceImage:image,gradientState:MPSNNGradientStateNode())
    let binary=MPSNNReduceBinary(device:d); binary.primaryOffset=MPSOffset(x:1,y:0,z:0); precondition(binary.primaryOffset.x==1)
}

func testMPSWave10ArithmeticSoftmaxFailClosed() {
 let d=MPSHostDevice.shared,image=MPSNNImageNode(),state=MPSNNGradientStateNode()
 let binaries:[MPSCNNBinaryKernel]=[MPSCNNAdd(device:d),MPSCNNDivide(device:d),MPSCNNMultiply(device:d),MPSCNNSubtract(device:d)]; precondition(binaries.count==4)
 let gradients=[MPSCNNAddGradient(device:d,isSecondarySourceFilter:true),MPSCNNMultiplyGradient(device:d,isSecondarySourceFilter:false),MPSCNNSubtractGradient(device:d,isSecondarySourceFilter:true)];precondition(gradients[0].isSecondarySourceFilter && !gradients[1].isSecondarySourceFilter)
 _=MPSCNNSoftMax(device:d);_=MPSCNNLogSoftMax(device:d);_=MPSCNNSoftMaxGradient(device:d);_=MPSCNNLogSoftMaxGradient(device:d)
 _=MPSCNNSoftMaxNode(source:image);_=MPSCNNLogSoftMaxNode(source:image);_=MPSCNNSoftMaxGradientNode(sourceGradient:image,sourceImage:image,gradientState:state);_=MPSCNNLogSoftMaxGradientNode(sourceGradient:image,sourceImage:image,gradientState:state)
}
func testMPSTemporalAAFailClosed() {
 let d=MPSHostDevice.shared,k=MPSTemporalAA(device:d);k.blendFactor=0.25;precondition(k.copy(with:nil,device:d).blendFactor==0.25)
 let t=MPSHostTexture(device:d,descriptor:MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.rgba8Unorm,width:1,height:1,mipmapped:false));MPSHostBoundary.reset();k.encode(commandBuffer:d.makeCommandBuffer(),sourceTexture:t,previousTexture:t,destinationTexture:t,motionVectorTexture:t,depthTexture:t);precondition(MPSHostBoundary.lastRefusedAPI=="MPSTemporalAA.encode")
}
