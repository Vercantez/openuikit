import Accelerate
import Foundation

func testSoBNNSRemABatch0() {
    _ = BNNSTensor.self
    let aBNNSTensor = BNNSTensor()
    _ = aBNNSTensor.data
    _ = aBNNSTensor.data_size_in_bytes
    _ = aBNNSTensor.data_type
    _ = aBNNSTensor.name
    _ = aBNNSTensor.rank
    _ = aBNNSTensor.shape
    _ = aBNNSTensor.stride
    _ = BNNSTensor(dataType: BNNSDataType(rawValue: 0), shape: [1], stride: [1])
    _ = bnns_graph_t.self
    let abnns_graph_t = bnns_graph_t()
    _ = abnns_graph_t.data
    _ = abnns_graph_t.size
    _ = bnns_graph_t(data: nil, size: 0)
    _ = bnns_graph_context_t.self
    let abnns_graph_context_t = bnns_graph_context_t()
    _ = abnns_graph_context_t.data
    _ = abnns_graph_context_t.size
    _ = bnns_graph_context_t(data: nil, size: 0)
    _ = bnns_graph_argument_t.self
    let abnns_graph_argument_t = bnns_graph_argument_t()
    _ = abnns_graph_argument_t.data_ptr_size
    _ = BNNSLayerData.self
    let aBNNSLayerData = BNNSLayerData()
    _ = aBNNSLayerData.data
    _ = aBNNSLayerData.data_bias
    _ = aBNNSLayerData.data_scale
    _ = aBNNSLayerData.data_table
    _ = aBNNSLayerData.data_type
    _ = BNNSLayerData(data: nil, data_type: BNNSDataType(rawValue: 0), data_scale: 0, data_bias: 0)
    _ = BNNSActivation.self
    let aBNNSActivation = BNNSActivation()
    _ = aBNNSActivation.alpha
    _ = aBNNSActivation.beta
    _ = aBNNSActivation.function
    _ = aBNNSActivation.ioffset
    _ = aBNNSActivation.ioffset_per_channel
    _ = aBNNSActivation.iscale
    _ = aBNNSActivation.iscale_per_channel
    _ = aBNNSActivation.ishift
    _ = aBNNSActivation.ishift_per_channel
    _ = BNNSActivation(function: BNNSActivationFunction(rawValue: 0), alpha: 0, beta: 0)
    _ = BNNSArithmeticUnary.self
    let aBNNSArithmeticUnary = BNNSArithmeticUnary()
    _ = aBNNSArithmeticUnary.in
    _ = aBNNSArithmeticUnary.in_type
    _ = aBNNSArithmeticUnary.out
    _ = aBNNSArithmeticUnary.out_type
    _ = BNNSArithmeticUnary(in: BNNSNDArrayDescriptor(), in_type: BNNSDescriptorType(rawValue: 0), out: BNNSNDArrayDescriptor(), out_type: BNNSDescriptorType(rawValue: 0))
    _ = BNNSArithmeticBinary.self
    let aBNNSArithmeticBinary = BNNSArithmeticBinary()
    _ = aBNNSArithmeticBinary.in1
    _ = aBNNSArithmeticBinary.in1_type
    _ = aBNNSArithmeticBinary.in2
    _ = aBNNSArithmeticBinary.in2_type
    _ = aBNNSArithmeticBinary.out
    _ = aBNNSArithmeticBinary.out_type
    _ = BNNSArithmeticBinary(in1: BNNSNDArrayDescriptor(), in1_type: BNNSDescriptorType(rawValue: 0), in2: BNNSNDArrayDescriptor(), in2_type: BNNSDescriptorType(rawValue: 0), out: BNNSNDArrayDescriptor(), out_type: BNNSDescriptorType(rawValue: 0))
    _ = BNNSDataType.self
    precondition(BNNSDataType(rawValue: 0).rawValue == 0)
    precondition(BNNSDataType(0) == BNNSDataType(rawValue: 0))
    precondition(BNNSDataType(rawValue: 0) != BNNSDataType(rawValue: 1))
    _ = BNNSNormType.self
    precondition(BNNSNormType(rawValue: 0).rawValue == 0)
    precondition(BNNSNormType(0) == BNNSNormType(rawValue: 0))
    precondition(BNNSNormType(rawValue: 0) != BNNSNormType(rawValue: 1))
    _ = BNNSDataLayout.self
    precondition(BNNSDataLayout(rawValue: 0).rawValue == 0)
    precondition(BNNSDataLayout(0) == BNNSDataLayout(rawValue: 0))
    precondition(BNNSDataLayout(rawValue: 0) != BNNSDataLayout(rawValue: 1))
    _ = BNNSFilterType.self
    precondition(BNNSFilterType(rawValue: 0).rawValue == 0)
    precondition(BNNSFilterType(0) == BNNSFilterType(rawValue: 0))
    precondition(BNNSFilterType(rawValue: 0) != BNNSFilterType(rawValue: 1))
    _ = BNNSLayerFlags.self
    precondition(BNNSLayerFlags(rawValue: 0).rawValue == 0)
    precondition(BNNSLayerFlags(0) == BNNSLayerFlags(rawValue: 0))
    precondition(BNNSLayerFlags(rawValue: 0) != BNNSLayerFlags(rawValue: 1))
    _ = BNNSPaddingMode.self
    precondition(BNNSPaddingMode(rawValue: 0).rawValue == 0)
    precondition(BNNSPaddingMode(0) == BNNSPaddingMode(rawValue: 0))
    precondition(BNNSPaddingMode(rawValue: 0) != BNNSPaddingMode(rawValue: 1))
    _ = BNNSShuffleType.self
    precondition(BNNSShuffleType(rawValue: 0).rawValue == 0)
    precondition(BNNSShuffleType(0) == BNNSShuffleType(rawValue: 0))
    precondition(BNNSShuffleType(rawValue: 0) != BNNSShuffleType(rawValue: 1))
    _ = BNNSLossFunction.self
    precondition(BNNSLossFunction(rawValue: 0).rawValue == 0)
    precondition(BNNSLossFunction(0) == BNNSLossFunction(rawValue: 0))
    precondition(BNNSLossFunction(rawValue: 0) != BNNSLossFunction(rawValue: 1))
    _ = BNNSNDArrayFlags.self
    precondition(BNNSNDArrayFlags(rawValue: 0).rawValue == 0)
    precondition(BNNSNDArrayFlags(0) == BNNSNDArrayFlags(rawValue: 0))
    precondition(BNNSNDArrayFlags(rawValue: 0) != BNNSNDArrayFlags(rawValue: 1))
    _ = BNNSSparsityType.self
    precondition(BNNSSparsityType(rawValue: 0).rawValue == 0)
    precondition(BNNSSparsityType(0) == BNNSSparsityType(rawValue: 0))
    precondition(BNNSSparsityType(rawValue: 0) != BNNSSparsityType(rawValue: 1))
    _ = BNNSTargetSystem.self
    precondition(BNNSTargetSystem(rawValue: 0).rawValue == 0)
    precondition(BNNSTargetSystem(0) == BNNSTargetSystem(rawValue: 0))
    precondition(BNNSTargetSystem(rawValue: 0) != BNNSTargetSystem(rawValue: 1))
}

func testSoBNNSRemABatch1() {
    _ = BNNSDescriptorType.self
    precondition(BNNSDescriptorType(rawValue: 0).rawValue == 0)
    precondition(BNNSDescriptorType(0) == BNNSDescriptorType(rawValue: 0))
    precondition(BNNSDescriptorType(rawValue: 0) != BNNSDescriptorType(rawValue: 1))
    _ = BNNSEmbeddingFlags.self
    precondition(BNNSEmbeddingFlags(rawValue: 0).rawValue == 0)
    precondition(BNNSEmbeddingFlags(0) == BNNSEmbeddingFlags(rawValue: 0))
    precondition(BNNSEmbeddingFlags(rawValue: 0) != BNNSEmbeddingFlags(rawValue: 1))
    _ = BNNSReduceFunction.self
    precondition(BNNSReduceFunction(rawValue: 0).rawValue == 0)
    precondition(BNNSReduceFunction(0) == BNNSReduceFunction(rawValue: 0))
    precondition(BNNSReduceFunction(rawValue: 0) != BNNSReduceFunction(rawValue: 1))
    _ = BNNSPointerSpecifier.self
    precondition(BNNSPointerSpecifier(rawValue: 0).rawValue == 0)
    precondition(BNNSPointerSpecifier(0) == BNNSPointerSpecifier(rawValue: 0))
    precondition(BNNSPointerSpecifier(rawValue: 0) != BNNSPointerSpecifier(rawValue: 1))
    _ = BNNSBoxCoordinateMode.self
    precondition(BNNSBoxCoordinateMode(rawValue: 0).rawValue == 0)
    precondition(BNNSBoxCoordinateMode(0) == BNNSBoxCoordinateMode(rawValue: 0))
    precondition(BNNSBoxCoordinateMode(rawValue: 0) != BNNSBoxCoordinateMode(rawValue: 1))
    _ = BNNSGraphArgumentType.self
    precondition(BNNSGraphArgumentType(rawValue: 0).rawValue == 0)
    precondition(BNNSGraphArgumentType(0) == BNNSGraphArgumentType(rawValue: 0))
    precondition(BNNSGraphArgumentType(rawValue: 0) != BNNSGraphArgumentType(rawValue: 1))
    _ = BNNSGraphMessageLevel.self
    precondition(BNNSGraphMessageLevel(rawValue: 0).rawValue == 0)
    precondition(BNNSGraphMessageLevel(0) == BNNSGraphMessageLevel(rawValue: 0))
    precondition(BNNSGraphMessageLevel(rawValue: 0) != BNNSGraphMessageLevel(rawValue: 1))
    _ = BNNSOptimizerFunction.self
    precondition(BNNSOptimizerFunction(rawValue: 0).rawValue == 0)
    precondition(BNNSOptimizerFunction(0) == BNNSOptimizerFunction(rawValue: 0))
    precondition(BNNSOptimizerFunction(rawValue: 0) != BNNSOptimizerFunction(rawValue: 1))
    _ = BNNSQuantizerFunction.self
    precondition(BNNSQuantizerFunction(rawValue: 0).rawValue == 0)
    precondition(BNNSQuantizerFunction(0) == BNNSQuantizerFunction(rawValue: 0))
    precondition(BNNSQuantizerFunction(rawValue: 0) != BNNSQuantizerFunction(rawValue: 1))
    _ = BNNSPoolingFunction.self
    precondition(BNNSPoolingFunction(rawValue: 0).rawValue == 0)
    precondition(BNNSPoolingFunction(0) == BNNSPoolingFunction(rawValue: 0))
    precondition(BNNSPoolingFunction(rawValue: 0) != BNNSPoolingFunction(rawValue: 1))
    _ = BNNSFilterParameters.self
    let bBNNSFilterParameters = BNNSFilterParameters()
    _ = bBNNSFilterParameters.alloc_memory
    _ = bBNNSFilterParameters.flags
    _ = bBNNSFilterParameters.free_memory
    _ = bBNNSFilterParameters.n_threads
    _ = BNNSFilterParameters(options: BNNSFlags(), threadCount: 0, allocator: nil, deallocator: nil)
    _ = BNNSFilterParameters.self
    let b2BNNSFilterParameters = BNNSFilterParameters()
    _ = b2BNNSFilterParameters.alloc_memory
    _ = b2BNNSFilterParameters.flags
    _ = b2BNNSFilterParameters.free_memory
    _ = b2BNNSFilterParameters.n_threads
    _ = BNNSFilterParameters(flags: 0, n_threads: 0, alloc_memory: nil, free_memory: nil)
    _ = BNNSVectorDescriptor.self
    let bBNNSVectorDescriptor = BNNSVectorDescriptor()
    _ = bBNNSVectorDescriptor.data_bias
    _ = bBNNSVectorDescriptor.data_scale
    _ = bBNNSVectorDescriptor.data_type
    _ = bBNNSVectorDescriptor.size
    _ = BNNSVectorDescriptor(size: 0, data_type: BNNSDataType(rawValue: 0))
    _ = BNNSVectorDescriptor.self
    let b2BNNSVectorDescriptor = BNNSVectorDescriptor()
    _ = b2BNNSVectorDescriptor.data_bias
    _ = b2BNNSVectorDescriptor.data_scale
    _ = b2BNNSVectorDescriptor.data_type
    _ = b2BNNSVectorDescriptor.size
    _ = BNNSVectorDescriptor(size: 0, data_type: BNNSDataType(rawValue: 0), data_scale: 0, data_bias: 0)
    _ = BNNSNDArrayDescriptor.self
    let bBNNSNDArrayDescriptor = BNNSNDArrayDescriptor()
    _ = bBNNSNDArrayDescriptor.data
    _ = bBNNSNDArrayDescriptor.data_bias
    _ = bBNNSNDArrayDescriptor.data_scale
    _ = bBNNSNDArrayDescriptor.data_type
    _ = bBNNSNDArrayDescriptor.flags
    _ = bBNNSNDArrayDescriptor.layout
    _ = bBNNSNDArrayDescriptor.size
    _ = bBNNSNDArrayDescriptor.stride
    _ = bBNNSNDArrayDescriptor.table_data
    _ = bBNNSNDArrayDescriptor.table_data_type
    _ = BNNSNDArrayDescriptor(flags: BNNSNDArrayFlags(rawValue: 0), layout: BNNSDataLayout(rawValue: 0), size: (0, 0, 0, 0, 0, 0, 0, 0), stride: (0, 0, 0, 0, 0, 0, 0, 0), data: nil, data_type: BNNSDataType(rawValue: 0), table_data: nil, table_data_type: BNNSDataType(rawValue: 0), data_scale: 0, data_bias: 0)
    _ = BNNSArithmeticTernary.self
    let bBNNSArithmeticTernary = BNNSArithmeticTernary()
    _ = bBNNSArithmeticTernary.in1
    _ = bBNNSArithmeticTernary.in1_type
    _ = bBNNSArithmeticTernary.in2
    _ = bBNNSArithmeticTernary.in2_type
    _ = bBNNSArithmeticTernary.in3
    _ = bBNNSArithmeticTernary.in3_type
    _ = bBNNSArithmeticTernary.out
    _ = bBNNSArithmeticTernary.out_type
    _ = bnns_graph_shape_t.self
    let bbnns_graph_shape_t = bnns_graph_shape_t()
    _ = bbnns_graph_shape_t.rank
    _ = bbnns_graph_shape_t.shape
}
