import Foundation

@discardableResult
public func BNNSApplyMultiheadAttention(_ F: BNNSFilter?, _ batch_size: Int, _ query: UnsafeRawPointer, _ query_stride: Int, _ key: UnsafeRawPointer, _ key_stride: Int, _ key_mask: UnsafePointer<BNNSNDArrayDescriptor>?, _ key_mask_stride: Int, _ value: UnsafeRawPointer, _ value_stride: Int, _ output: UnsafeMutableRawPointer, _ output_stride: Int, _ add_to_attention: UnsafePointer<BNNSNDArrayDescriptor>?, _ backprop_cache_size: UnsafeMutablePointer<Int>?, _ backprop_cache: UnsafeMutableRawPointer?, _ workspace_size: UnsafeMutablePointer<Int>?, _ workspace: UnsafeMutableRawPointer?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSApplyMultiheadAttentionBackward(_ F: BNNSFilter?, _ batch_size: Int, _ query: UnsafeRawPointer?, _ query_stride: Int, _ query_param_delta: UnsafeMutablePointer<BNNSMHAProjectionParameters>?, _ key: UnsafeRawPointer?, _ key_stride: Int, _ key_mask: UnsafePointer<BNNSNDArrayDescriptor>?, _ key_mask_stride: Int, _ key_param_delta: UnsafeMutablePointer<BNNSMHAProjectionParameters>?, _ value: UnsafeRawPointer?, _ value_stride: Int, _ value_param_delta: UnsafeMutablePointer<BNNSMHAProjectionParameters>?, _ add_to_attention: UnsafePointer<BNNSNDArrayDescriptor>?, _ key_attn_bias_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ value_attn_bias_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ output: UnsafeRawPointer?, _ output_stride: Int, _ output_param_delta: UnsafeMutablePointer<BNNSMHAProjectionParameters>, _ backprop_cache_size: Int, _ backprop_cache: UnsafeMutableRawPointer?, _ workspace_size: UnsafeMutablePointer<Int>?, _ workspace: UnsafeMutableRawPointer?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSArithmeticFilterApplyBackwardBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ number_of_inputs: Int, _ in: UnsafeMutablePointer<UnsafeRawPointer?>?, _ in_stride: UnsafePointer<Int>?, _ in_delta: UnsafeMutablePointer<UnsafeMutablePointer<BNNSNDArrayDescriptor>>, _ in_delta_stride: UnsafePointer<Int>, _ out: UnsafeRawPointer?, _ out_stride: Int, _ out_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSArithmeticFilterApplyBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ number_of_inputs: Int, _ in: UnsafeMutablePointer<UnsafeRawPointer>, _ in_stride: UnsafePointer<Int>, _ out: UnsafeMutableRawPointer, _ out_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSBandPart(_ num_lower: Int32, _ num_upper: Int32, _ input: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSClipByGlobalNorm(_ dest: UnsafeMutablePointer<UnsafeMutablePointer<BNNSNDArrayDescriptor>>, _ src: UnsafeMutablePointer<UnsafePointer<BNNSNDArrayDescriptor>>, _ count: Int, _ max_norm: Float, _ use_norm: Float) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSClipByNorm(_ dest: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ src: UnsafePointer<BNNSNDArrayDescriptor>, _ max_norm: Float, _ axis_flags: UInt32) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSClipByValue(_ dest: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ src: UnsafePointer<BNNSNDArrayDescriptor>, _ min_val: Float, _ max_val: Float) -> Int32 {
    return _bnnsClipByValueFloat(dest: &dest.pointee, src: src.pointee, minVal: min_val, maxVal: max_val)
}
@discardableResult
public func BNNSCompareTensor(_ in0: UnsafePointer<BNNSNDArrayDescriptor>, _ in1: UnsafePointer<BNNSNDArrayDescriptor>, _ op: BNNSRelationalOperator, _ out: UnsafeMutablePointer<BNNSNDArrayDescriptor>) -> Int32 {
    return _bnnsCompareFloat(in0: in0.pointee, in1: in1.pointee, op: op, out: &out.pointee)
}
@discardableResult
public func BNNSComputeLSTMTrainingCacheCapacity(_ layer_params: UnsafePointer<BNNSLayerParametersLSTM>) -> Int { return 0 }
@discardableResult
public func BNNSComputeNorm(_ dest: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ src: UnsafePointer<BNNSNDArrayDescriptor>, _ norm_type: BNNSNormType, _ axis_flags: UInt32) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSComputeNormBackward(_ in: UnsafeRawPointer, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ out: UnsafeRawPointer, _ out_delta: UnsafePointer<BNNSNDArrayDescriptor>, _ norm_type: BNNSNormType, _ axis_flags: UInt32) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSCopy(_ dest: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ src: UnsafePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 {
    _ = filter_params
    return _bnnsCopyFloat(dest: &dest.pointee, src: src.pointee)
}
@discardableResult
public func BNNSCreateNearestNeighbors(_ max_n_samples: UInt32, _ n_features: UInt32, _ n_neighbors: UInt32, _ data_type: BNNSDataType, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSNearestNeighbors? { return nil }
@discardableResult
public func BNNSCreateRandomGenerator(_ method: BNNSRandomGeneratorMethod, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSRandomGenerator? { return nil }
@discardableResult
public func BNNSCreateRandomGeneratorWithSeed(_ method: BNNSRandomGeneratorMethod, _ seed: UInt64, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSRandomGenerator? { return nil }
@discardableResult
public func BNNSCropResize(_ layer_params: UnsafePointer<BNNSLayerParametersCropResize>, _ input: UnsafePointer<BNNSNDArrayDescriptor>, _ roi: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSCropResizeBackward(_ layer_params: UnsafePointer<BNNSLayerParametersCropResize>, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ roi: UnsafePointer<BNNSNDArrayDescriptor>, _ out_delta: UnsafePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSDataLayoutGetRank(_ layout: BNNSDataLayout) -> Int { return 0 }
public func BNNSDestroyNearestNeighbors(_ knn: BNNSNearestNeighbors?) { }
public func BNNSDestroyRandomGenerator(_ generator: BNNSRandomGenerator?) { }
@discardableResult
public func BNNSDirectApplyActivationBatch(_ layer_params: UnsafePointer<BNNSLayerParametersActivation>, _ filter_params: UnsafePointer<BNNSFilterParameters>?, _ batch_size: Int, _ in_stride: Int, _ out_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
public func BNNSDirectApplyBroadcastMatMul(_ transA: Bool, _ transB: Bool, _ alpha: Float, _ inputA: UnsafePointer<BNNSNDArrayDescriptor>, _ inputB: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) { }
@discardableResult
public func BNNSDirectApplyInTopK(_ K: Int, _ axis: Int, _ batch_size: Int, _ input: UnsafePointer<BNNSNDArrayDescriptor>, _ input_batch_stride: Int, _ test_indices: UnsafePointer<BNNSNDArrayDescriptor>, _ test_indices_batch_stride: Int, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ output_batch_stride: Int, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSDirectApplyLSTMBatchBackward(_ layer_params: UnsafePointer<BNNSLayerParametersLSTM>, _ layer_delta_params: UnsafePointer<BNNSLayerParametersLSTM>, _ filter_params: UnsafePointer<BNNSFilterParameters>?, _ training_cache_ptr: UnsafeRawPointer?, _ training_cache_capacity: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSDirectApplyLSTMBatchTrainingCaching(_ layer_params: UnsafePointer<BNNSLayerParametersLSTM>, _ filter_params: UnsafePointer<BNNSFilterParameters>?, _ training_cache_ptr: UnsafeMutableRawPointer?, _ training_cache_capacity: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSDirectApplyQuantizer(_ layer_params: UnsafePointer<BNNSLayerParametersQuantization>, _ filter_params: UnsafePointer<BNNSFilterParameters>?, _ batch_size: Int, _ input_stride: Int, _ output_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSDirectApplyReduction(_ layer_params: UnsafePointer<BNNSLayerParametersReduction>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSDirectApplyTopK(_ K: Int, _ axis: Int, _ batch_size: Int, _ input: UnsafePointer<BNNSNDArrayDescriptor>, _ input_batch_stride: Int, _ best_values: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ best_values_batch_stride: Int, _ best_indices: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ best_indices_batch_stride: Int, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFilterApply(_ filter: BNNSFilter?, _ in: UnsafeRawPointer, _ out: UnsafeMutableRawPointer) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFilterApplyBackwardBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer?, _ in_stride: Int, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ in_delta_stride: Int, _ out: UnsafeRawPointer?, _ out_stride: Int, _ out_delta: UnsafePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int, _ weights_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ bias_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFilterApplyBackwardTwoInputBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ inA: UnsafeRawPointer?, _ inA_stride: Int, _ inA_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ inA_delta_stride: Int, _ inB: UnsafeRawPointer?, _ inB_stride: Int, _ inB_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ inB_delta_stride: Int, _ out: UnsafeRawPointer?, _ out_stride: Int, _ out_delta: UnsafePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int, _ weights_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ bias_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFilterApplyBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer, _ in_stride: Int, _ out: UnsafeMutableRawPointer, _ out_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFilterApplyTwoInput(_ filter: BNNSFilter?, _ inA: UnsafeRawPointer, _ inB: UnsafeRawPointer, _ out: UnsafeMutableRawPointer) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFilterApplyTwoInputBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ inA: UnsafeRawPointer, _ inA_stride: Int, _ inB: UnsafeRawPointer, _ inB_stride: Int, _ out: UnsafeMutableRawPointer, _ out_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFilterCreateConvolutionLayer(_ in_desc: UnsafePointer<BNNSImageStackDescriptor>, _ out_desc: UnsafePointer<BNNSImageStackDescriptor>, _ layer_params: UnsafePointer<BNNSConvolutionLayerParameters>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateFullyConnectedLayer(_ in_desc: UnsafePointer<BNNSVectorDescriptor>, _ out_desc: UnsafePointer<BNNSVectorDescriptor>, _ layer_params: UnsafePointer<BNNSFullyConnectedLayerParameters>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateFusedLayer(_ number_of_fused_filters: Int, _ filter_type: UnsafePointer<BNNSFilterType>, _ layer_params: UnsafeMutablePointer<UnsafeRawPointer>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerActivation(_ layer_params: UnsafePointer<BNNSLayerParametersActivation>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerArithmetic(_ layer_params: UnsafePointer<BNNSLayerParametersArithmetic>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerBroadcastMatMul(_ layer_params: UnsafePointer<BNNSLayerParametersBroadcastMatMul>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerConvolution(_ layer_params: UnsafePointer<BNNSLayerParametersConvolution>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerDropout(_ layer_params: UnsafePointer<BNNSLayerParametersDropout>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerEmbedding(_ layer_params: UnsafePointer<BNNSLayerParametersEmbedding>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerFullyConnected(_ layer_params: UnsafePointer<BNNSLayerParametersFullyConnected>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerGram(_ layer_params: UnsafePointer<BNNSLayerParametersGram>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerLoss(_ layer_params: UnsafeRawPointer, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerMultiheadAttention(_ layer_params: UnsafePointer<BNNSLayerParametersMultiheadAttention>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerNormalization(_ normType: BNNSFilterType, _ layer_params: UnsafePointer<BNNSLayerParametersNormalization>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerPadding(_ layer_params: UnsafePointer<BNNSLayerParametersPadding>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerPermute(_ layer_params: UnsafePointer<BNNSLayerParametersPermute>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerPooling(_ layer_params: UnsafePointer<BNNSLayerParametersPooling>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerReduction(_ layer_params: UnsafePointer<BNNSLayerParametersReduction>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerResize(_ layer_params: UnsafePointer<BNNSLayerParametersResize>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerTensorContraction(_ layer_params: UnsafePointer<BNNSLayerParametersTensorContraction>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateLayerTransposedConvolution(_ layer_params: UnsafePointer<BNNSLayerParametersConvolution>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreatePoolingLayer(_ in_desc: UnsafePointer<BNNSImageStackDescriptor>, _ out_desc: UnsafePointer<BNNSImageStackDescriptor>, _ layer_params: UnsafePointer<BNNSPoolingLayerParameters>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
@discardableResult
public func BNNSFilterCreateVectorActivationLayer(_ in_desc: UnsafePointer<BNNSVectorDescriptor>, _ out_desc: UnsafePointer<BNNSVectorDescriptor>, _ activation: UnsafePointer<BNNSActivation>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> BNNSFilter? { return nil }
public func BNNSFilterDestroy(_ filter: BNNSFilter?) { }
@discardableResult
public func BNNSFusedFilterApplyBackwardBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer?, _ in_stride: Int, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ in_delta_stride: Int, _ out: UnsafeRawPointer?, _ out_stride: Int, _ out_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int, _ delta_parameters: UnsafeMutablePointer<UnsafeMutablePointer<BNNSNDArrayDescriptor>?>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFusedFilterApplyBackwardMultiInputBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ number_of_inputs: Int, _ in: UnsafeMutablePointer<UnsafeRawPointer?>?, _ in_stride: UnsafePointer<Int>?, _ in_delta: UnsafeMutablePointer<UnsafeMutablePointer<BNNSNDArrayDescriptor>>, _ in_delta_stride: UnsafePointer<Int>, _ out: UnsafeRawPointer?, _ out_stride: Int, _ out_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int, _ delta_parameters: UnsafeMutablePointer<UnsafeMutablePointer<BNNSNDArrayDescriptor>?>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFusedFilterApplyBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer, _ in_stride: Int, _ out: UnsafeMutableRawPointer, _ out_stride: Int, _ training: Bool) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSFusedFilterApplyMultiInputBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ number_of_inputs: Int, _ in: UnsafeMutablePointer<UnsafeRawPointer>, _ in_stride: UnsafePointer<Int>, _ out: UnsafeMutableRawPointer, _ out_stride: Int, _ training: Bool) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGather(_ axis: Int, _ input: UnsafePointer<BNNSNDArrayDescriptor>, _ indices: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGatherND(_ input: UnsafePointer<BNNSNDArrayDescriptor>, _ indices: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGetPointer(_ filter: BNNSFilter?, _ target: BNNSPointerSpecifier) -> BNNSNDArrayDescriptor { return BNNSNDArrayDescriptor() }
@discardableResult
public func BNNSGraphCompileFromFile(_ filename: UnsafePointer<CChar>, _ function: UnsafePointer<CChar>?, _ options: bnns_graph_compile_options_t) -> bnns_graph_t { return bnns_graph_t() }
public func BNNSGraphCompileOptionsDestroy(_ options: bnns_graph_compile_options_t) { }
@discardableResult
public func BNNSGraphCompileOptionsGetGenerateDebugInfo(_ options: bnns_graph_compile_options_t) -> Bool { return false }
@discardableResult
public func BNNSGraphCompileOptionsGetOptimizationPreference(_ options: bnns_graph_compile_options_t) -> BNNSGraphOptimizationPreference { return BNNSGraphOptimizationPreference(rawValue: 0) }
@discardableResult
public func BNNSGraphCompileOptionsGetOutputFD(_ options: bnns_graph_compile_options_t) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphCompileOptionsGetOutputPath(_ options: bnns_graph_compile_options_t) -> UnsafePointer<CChar>? { return nil }
@discardableResult
public func BNNSGraphCompileOptionsGetTargetSingleThread(_ options: bnns_graph_compile_options_t) -> Bool { return false }
@discardableResult
public func BNNSGraphCompileOptionsMakeDefault() -> bnns_graph_compile_options_t { return bnns_graph_compile_options_t() }
public func BNNSGraphCompileOptionsSetGenerateDebugInfo(_ options: bnns_graph_compile_options_t, _ value: Bool) { }
public func BNNSGraphCompileOptionsSetMessageLogCallback(_ options: bnns_graph_compile_options_t, _ log_callback: bnns_graph_compile_message_fn_t, _ additional_logging_arguments: UnsafeMutablePointer<bnns_user_message_data_t>?) { }
public func BNNSGraphCompileOptionsSetMessageLogMask(_ options: bnns_graph_compile_options_t, _ log_level_mask: UInt32) { }
public func BNNSGraphCompileOptionsSetOptimizationPreference(_ options: bnns_graph_compile_options_t, _ preference: BNNSGraphOptimizationPreference) { }
public func BNNSGraphCompileOptionsSetOutputFD(_ options: bnns_graph_compile_options_t, _ fd: Int32) { }
public func BNNSGraphCompileOptionsSetOutputPath(_ options: bnns_graph_compile_options_t, _ path: UnsafePointer<CChar>?) { }
public func BNNSGraphCompileOptionsSetTargetSingleThread(_ options: bnns_graph_compile_options_t, _ value: Bool) { }
public func BNNSGraphContextDestroy(_ context: bnns_graph_context_t) { }
public func BNNSGraphContextEnableNanAndInfChecks(_ context: bnns_graph_context_t, _ enable_check_for_nans_inf: Bool) { }
@discardableResult
public func BNNSGraphContextExecute(_ context: bnns_graph_context_t, _ function: UnsafePointer<CChar>?, _ argument_count: Int, _ arguments: UnsafeMutablePointer<bnns_graph_argument_t>, _ workspace_size: Int, _ workspace: UnsafeMutablePointer<CChar>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextGetTensor(_ context: bnns_graph_context_t, _ function: UnsafePointer<CChar>?, _ argument: UnsafePointer<CChar>, _ fill_known_dynamic_shapes: Bool, _ tensor: UnsafeMutablePointer<BNNSTensor>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextGetWorkspaceSize(_ context: bnns_graph_context_t, _ function: UnsafePointer<CChar>?) -> Int { return 0 }
@discardableResult
public func BNNSGraphContextMake(_ graph: bnns_graph_t) -> bnns_graph_context_t { return bnns_graph_context_t() }
@discardableResult
public func BNNSGraphContextMakeStreaming(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?, _ initial_states_count: Int, _ initial_states: UnsafePointer<BNNSTensor>?) -> bnns_graph_context_t { return bnns_graph_context_t() }
@discardableResult
public func BNNSGraphContextSetArgumentType(_ context: bnns_graph_context_t, _ argument_type: BNNSGraphArgumentType) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextSetBatchSize(_ context: bnns_graph_context_t, _ function: UnsafePointer<CChar>?, _ batch_size: UInt64) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextSetDynamicShapes(_ context: bnns_graph_context_t, _ function: UnsafePointer<CChar>?, _ shapes_count: Int, _ shapes: UnsafeMutablePointer<bnns_graph_shape_t>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextSetMessageLogCallback(_ context: bnns_graph_context_t, _ log_callback_fn: bnns_graph_execute_message_fn_t, _ additional_logging_arguments: UnsafeMutablePointer<bnns_user_message_data_t>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextSetMessageLogMask(_ context: bnns_graph_context_t, _ log_level_mask: UInt32) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextSetOutputAllocationCallback(_ context: bnns_graph_context_t, _ realloc: bnns_graph_realloc_fn_t?, _ free: bnns_graph_free_all_fn_t?, _ user_memory_context_size: Int, _ user_memory_context: UnsafeMutableRawPointer?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextSetStreamingAdvanceCount(_ context: bnns_graph_context_t, _ advance_count: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphContextSetWorkspaceAllocationCallback(_ context: bnns_graph_context_t, _ realloc: bnns_graph_realloc_fn_t?, _ free: bnns_graph_free_all_fn_t?, _ user_memory_context_size: Int, _ user_memory_context: UnsafeMutableRawPointer?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphGetArgumentCount(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?) -> Int { return 0 }
@discardableResult
public func BNNSGraphGetArgumentIntents(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?, _ argument_intents_count: Int, _ argument_intents: UnsafeMutablePointer<BNNSGraphArgumentIntent>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphGetArgumentInterleaveFactors(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?, _ argument_count: Int, _ argument_interleave: UnsafeMutablePointer<UnsafePointer<UInt16>?>, _ argument_interleave_counts: UnsafeMutablePointer<Int>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphGetArgumentNames(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?, _ argument_names_count: Int, _ argument_names: UnsafeMutablePointer<UnsafePointer<CChar>?>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphGetArgumentPosition(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?, _ argument: UnsafePointer<CChar>) -> Int { return 0 }
@discardableResult
public func BNNSGraphGetFunctionCount(_ graph: bnns_graph_t) -> Int { return 0 }
@discardableResult
public func BNNSGraphGetFunctionNames(_ graph: bnns_graph_t, _ function_name_count: Int, _ function_names: UnsafeMutablePointer<UnsafePointer<CChar>?>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphGetInputCount(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?) -> Int { return 0 }
@discardableResult
public func BNNSGraphGetInputNames(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?, _ input_names_count: Int, _ input_names: UnsafeMutablePointer<UnsafePointer<CChar>?>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphGetOutputCount(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?) -> Int { return 0 }
@discardableResult
public func BNNSGraphGetOutputNames(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?, _ output_names_count: Int, _ output_names: UnsafeMutablePointer<UnsafePointer<CChar>?>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSGraphTensorFillStrides(_ graph: bnns_graph_t, _ function: UnsafePointer<CChar>?, _ argument: UnsafePointer<CChar>, _ tensor: UnsafeMutablePointer<BNNSTensor>) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSLossFilterApplyBackwardBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer, _ in_stride: Int, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ in_delta_stride: Int, _ labels: UnsafeRawPointer, _ labels_stride: Int, _ weights: UnsafeRawPointer?, _ weights_size: Int, _ out_delta: UnsafePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSLossFilterApplyBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer, _ in_stride: Int, _ labels: UnsafeRawPointer, _ labels_stride: Int, _ weights: UnsafeRawPointer?, _ weights_size: Int, _ out: UnsafeMutableRawPointer, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ in_delta_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSMatMul(_ transA: Bool, _ transB: Bool, _ alpha: Float, _ inputA: UnsafePointer<BNNSNDArrayDescriptor>, _ inputB: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafePointer<BNNSNDArrayDescriptor>, _ workspace: UnsafeMutableRawPointer?, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 {
    _ = workspace
    _ = filter_params
    return _bnnsMatMulFloat(transA: transA, transB: transB, alpha: alpha, inputA: inputA.pointee, inputB: inputB.pointee, output: output.pointee)
}
@discardableResult
public func BNNSMatMulWorkspaceSize(_ transA: Bool, _ transB: Bool, _ alpha: Float, _ inputA: UnsafePointer<BNNSNDArrayDescriptor>, _ inputB: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int { return 0 }
@discardableResult
public func BNNSNDArrayFullyConnectedSparsifySparseCOO(_ in_dense_shape: UnsafePointer<BNNSNDArrayDescriptor>, _ in_indices: UnsafePointer<BNNSNDArrayDescriptor>, _ in_values: UnsafePointer<BNNSNDArrayDescriptor>, _ out: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ sparse_params: UnsafePointer<BNNSSparsityParameters>?, _ batch_size: Int, _ workspace: UnsafeMutableRawPointer?, _ workspace_size: Int, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSNDArrayFullyConnectedSparsifySparseCSR(_ in_dense_shape: UnsafePointer<BNNSNDArrayDescriptor>, _ in_column_indices: UnsafePointer<BNNSNDArrayDescriptor>, _ in_row_starts: UnsafePointer<BNNSNDArrayDescriptor>, _ in_values: UnsafePointer<BNNSNDArrayDescriptor>, _ out: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ sparse_params: UnsafePointer<BNNSSparsityParameters>?, _ batch_size: Int, _ workspace: UnsafeMutableRawPointer?, _ workspace_size: Int, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSNDArrayGetDataSize(_ array: UnsafePointer<BNNSNDArrayDescriptor>) -> Int {
    return _bnnsNDArrayCount(array.pointee) * MemoryLayout<Float>.size
}
@discardableResult
public func BNNSNearestNeighborsGetInfo(_ knn: BNNSNearestNeighbors?, _ sample_number: Int32, _ indices: UnsafeMutablePointer<Int32>?, _ distances: UnsafeMutableRawPointer?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSNearestNeighborsLoad(_ knn: BNNSNearestNeighbors?, _ n_new_samples: UInt32, _ data_ptr: UnsafeRawPointer) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSNormalizationFilterApplyBackwardBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ in_delta_stride: Int, _ out: UnsafeRawPointer?, _ out_stride: Int, _ out_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int, _ beta_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ gamma_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSNormalizationFilterApplyBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer, _ in_stride: Int, _ out: UnsafeMutableRawPointer, _ out_stride: Int, _ training: Bool) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSOptimizerStep(_ function: BNNSOptimizerFunction, _ OptimizerAlgFields: UnsafeRawPointer, _ number_of_parameters: Int, _ parameters: UnsafeMutablePointer<UnsafeMutablePointer<BNNSNDArrayDescriptor>>, _ gradients: UnsafeMutablePointer<UnsafePointer<BNNSNDArrayDescriptor>>, _ accumulators: UnsafeMutablePointer<UnsafeMutablePointer<BNNSNDArrayDescriptor>?>?, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSPermuteFilterApplyBackwardBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ in_delta_stride: Int, _ out_delta: UnsafePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSPoolingFilterApplyBackwardBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer?, _ in_stride: Int, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ in_delta_stride: Int, _ out: UnsafeRawPointer?, _ out_stride: Int, _ out_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int, _ bias_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ indices: UnsafePointer<Int>?, _ idx_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSPoolingFilterApplyBackwardBatchEx(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer?, _ in_stride: Int, _ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ in_delta_stride: Int, _ out: UnsafeRawPointer?, _ out_stride: Int, _ out_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ out_delta_stride: Int, _ bias_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>?, _ indices_data_type: BNNSDataType, _ indices: UnsafeRawPointer?, _ idx_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSPoolingFilterApplyBatch(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer, _ in_stride: Int, _ out: UnsafeMutableRawPointer, _ out_stride: Int, _ indices: UnsafeMutablePointer<Int>?, _ idx_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSPoolingFilterApplyBatchEx(_ filter: BNNSFilter?, _ batch_size: Int, _ in: UnsafeRawPointer, _ in_stride: Int, _ out: UnsafeMutableRawPointer, _ out_stride: Int, _ indices_data_type: BNNSDataType, _ indices: UnsafeMutableRawPointer?, _ idx_stride: Int) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSRandomFillCategoricalFloat(_ generator: BNNSRandomGenerator?, _ desc: UnsafePointer<BNNSNDArrayDescriptor>, _ probabilities: UnsafePointer<BNNSNDArrayDescriptor>, _ log_probabilities: Bool) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSRandomFillNormalFloat(_ generator: BNNSRandomGenerator?, _ desc: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ mean: Float, _ stddev: Float) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSRandomFillUniformFloat(_ generator: BNNSRandomGenerator?, _ desc: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ a: Float, _ b: Float) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSRandomFillUniformInt(_ generator: BNNSRandomGenerator?, _ desc: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ a: Int64, _ b: Int64) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSRandomGeneratorGetState(_ generator: BNNSRandomGenerator?, _ state_size: Int, _ state: UnsafeMutableRawPointer) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSRandomGeneratorSetState(_ generator: BNNSRandomGenerator?, _ state_size: Int, _ state: UnsafeMutableRawPointer) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSRandomGeneratorStateSize(_ generator: BNNSRandomGenerator?) -> Int { return 0 }
@discardableResult
public func BNNSScatter(_ axis: Int, _ op: BNNSReduceFunction, _ input: UnsafePointer<BNNSNDArrayDescriptor>, _ indices: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSScatterND(_ op: BNNSReduceFunction, _ input: UnsafePointer<BNNSNDArrayDescriptor>, _ indices: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSShuffle(_ type: BNNSShuffleType, _ input: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSTensorGetAllocationSize(_ tensor: UnsafePointer<BNNSTensor>) -> Int { return 0 }
@discardableResult
public func BNNSTile(_ input: UnsafePointer<BNNSNDArrayDescriptor>, _ output: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 {
    _ = filter_params
    return _bnnsTileFloat(dest: &output.pointee, src: input.pointee)
}
@discardableResult
public func BNNSTileBackward(_ in_delta: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ out_delta: UnsafePointer<BNNSNDArrayDescriptor>, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 { return BNNSLinuxFailClosedStatus }
@discardableResult
public func BNNSTranspose(_ dest: UnsafeMutablePointer<BNNSNDArrayDescriptor>, _ src: UnsafePointer<BNNSNDArrayDescriptor>, _ axis0: Int, _ axis1: Int, _ filter_params: UnsafePointer<BNNSFilterParameters>?) -> Int32 {
    _ = filter_params
    return _bnnsTransposeFloat(dest: &dest.pointee, src: src.pointee, axis0: axis0, axis1: axis1)
}
public func SparseCleanup(_ toFree: SparseMatrix_Complex_Double) { }
public func SparseCleanup(_ toFree: SparseMatrix_Complex_Float) { }
public func SparseCleanup(_ toFree: SparseMatrix_Double) { _sparseCleanupDouble(toFree) }
public func SparseCleanup(_ toFree: SparseMatrix_Float) { _sparseCleanupFloat(toFree) }
public func SparseCleanup(_ toFree: SparseOpaqueFactorization_Complex_Double) { }
public func SparseCleanup(_ toFree: SparseOpaqueFactorization_Complex_Float) { }
public func SparseCleanup(_ toFree: SparseOpaqueFactorization_Double) { _sparseReleaseFactorDouble(toFree) }
public func SparseCleanup(_ toFree: SparseOpaqueFactorization_Float) { _sparseReleaseFactorFloat(toFree) }
public func SparseCleanup(_ Preconditioner: SparseOpaquePreconditioner_Complex_Double) { }
public func SparseCleanup(_ Preconditioner: SparseOpaquePreconditioner_Complex_Float) { }
public func SparseCleanup(_ Preconditioner: SparseOpaquePreconditioner_Double) { }
public func SparseCleanup(_ Preconditioner: SparseOpaquePreconditioner_Float) { }
public func SparseCleanup(_ toFree: SparseOpaqueSubfactor_Complex_Double) { }
public func SparseCleanup(_ toFree: SparseOpaqueSubfactor_Complex_Float) { }
public func SparseCleanup(_ toFree: SparseOpaqueSubfactor_Double) { }
public func SparseCleanup(_ toFree: SparseOpaqueSubfactor_Float) { }
public func SparseCleanup(_ toFree: SparseOpaqueSymbolicFactorization) { }
@discardableResult
public func SparseConjugateGradient() -> SparseIterativeMethod {
    var method = SparseIterativeMethod()
    method.method = 1
    return method
}
@discardableResult
public func SparseConjugateGradient(_ options: SparseCGOptions) -> SparseIterativeMethod {
    _ = options
    var method = SparseIterativeMethod()
    method.method = 1
    return method
}
@discardableResult
public func SparseConvertFromCoordinate(_ rowCount: Int32, _ columnCount: Int32, _ blockCount: Int, _ blockSize: UInt8, _ attributes: SparseAttributesComplex_t, _ row: UnsafePointer<Int32>, _ column: UnsafePointer<Int32>, _ data: OpaquePointer) -> SparseMatrix_Complex_Double { return SparseMatrix_Complex_Double() }
@discardableResult
public func SparseConvertFromCoordinate(_ rowCount: Int32, _ columnCount: Int32, _ blockCount: Int, _ blockSize: UInt8, _ attributes: SparseAttributesComplex_t, _ row: UnsafePointer<Int32>, _ column: UnsafePointer<Int32>, _ data: OpaquePointer, _ storage: UnsafeMutableRawPointer, _ workspace: UnsafeMutableRawPointer) -> SparseMatrix_Complex_Double { return SparseMatrix_Complex_Double() }
@discardableResult
public func SparseConvertFromCoordinate(_ rowCount: Int32, _ columnCount: Int32, _ blockCount: Int, _ blockSize: UInt8, _ attributes: SparseAttributesComplex_t, _ row: UnsafePointer<Int32>, _ column: UnsafePointer<Int32>, _ data: OpaquePointer) -> SparseMatrix_Complex_Float { return SparseMatrix_Complex_Float() }
@discardableResult
public func SparseConvertFromCoordinate(_ rowCount: Int32, _ columnCount: Int32, _ blockCount: Int, _ blockSize: UInt8, _ attributes: SparseAttributesComplex_t, _ row: UnsafePointer<Int32>, _ column: UnsafePointer<Int32>, _ data: OpaquePointer, _ storage: UnsafeMutableRawPointer, _ workspace: UnsafeMutableRawPointer) -> SparseMatrix_Complex_Float { return SparseMatrix_Complex_Float() }
@discardableResult
public func SparseConvertFromCoordinate(_ rowCount: Int32, _ columnCount: Int32, _ blockCount: Int, _ blockSize: UInt8, _ attributes: SparseAttributes_t, _ row: UnsafePointer<Int32>, _ column: UnsafePointer<Int32>, _ data: UnsafePointer<Double>) -> SparseMatrix_Double {
    let packed = _sparseConvertFromCoordinate(rowCount: rowCount, columnCount: columnCount, blockCount: blockCount, blockSize: blockSize, attributes: attributes, row: row, column: column, data: data)
    var matrix = SparseMatrix_Double()
    matrix.data.deallocate()
    matrix.structure.columnStarts.deallocate()
    matrix.structure.rowIndices.deallocate()
    matrix.structure = packed.structure
    matrix.data = packed.values
    return matrix
}
@discardableResult
public func SparseConvertFromCoordinate(_ rowCount: Int32, _ columnCount: Int32, _ blockCount: Int, _ blockSize: UInt8, _ attributes: SparseAttributes_t, _ row: UnsafePointer<Int32>, _ column: UnsafePointer<Int32>, _ data: UnsafePointer<Double>, _ storage: UnsafeMutableRawPointer, _ workspace: UnsafeMutableRawPointer) -> SparseMatrix_Double {
    _ = storage
    _ = workspace
    return SparseConvertFromCoordinate(rowCount, columnCount, blockCount, blockSize, attributes, row, column, data)
}
@discardableResult
public func SparseConvertFromCoordinate(_ rowCount: Int32, _ columnCount: Int32, _ blockCount: Int, _ blockSize: UInt8, _ attributes: SparseAttributes_t, _ row: UnsafePointer<Int32>, _ column: UnsafePointer<Int32>, _ data: UnsafePointer<Float>) -> SparseMatrix_Float {
    let packed = _sparseConvertFromCoordinate(rowCount: rowCount, columnCount: columnCount, blockCount: blockCount, blockSize: blockSize, attributes: attributes, row: row, column: column, data: data)
    var matrix = SparseMatrix_Float()
    matrix.data.deallocate()
    matrix.structure.columnStarts.deallocate()
    matrix.structure.rowIndices.deallocate()
    matrix.structure = packed.structure
    matrix.data = packed.values
    return matrix
}
@discardableResult
public func SparseConvertFromCoordinate(_ rowCount: Int32, _ columnCount: Int32, _ blockCount: Int, _ blockSize: UInt8, _ attributes: SparseAttributes_t, _ row: UnsafePointer<Int32>, _ column: UnsafePointer<Int32>, _ data: UnsafePointer<Float>, _ storage: UnsafeMutableRawPointer, _ workspace: UnsafeMutableRawPointer) -> SparseMatrix_Float {
    _ = storage
    _ = workspace
    return SparseConvertFromCoordinate(rowCount, columnCount, blockCount, blockSize, attributes, row, column, data)
}
@discardableResult
public func SparseConvertFromOpaque(_ matrix: sparse_matrix_double) -> SparseMatrix_Double { return SparseMatrix_Double() }
@discardableResult
public func SparseConvertFromOpaque(_ matrix: sparse_matrix_double_complex) -> SparseMatrix_Complex_Double { return SparseMatrix_Complex_Double() }
@discardableResult
public func SparseConvertFromOpaque(_ matrix: sparse_matrix_float) -> SparseMatrix_Float { return SparseMatrix_Float() }
@discardableResult
public func SparseConvertFromOpaque(_ matrix: sparse_matrix_float_complex) -> SparseMatrix_Complex_Float { return SparseMatrix_Complex_Float() }
@discardableResult
public func SparseCreatePreconditioner(_ type: SparsePreconditioner_t, _ A: SparseMatrix_Complex_Double) -> SparseOpaquePreconditioner_Complex_Double { return SparseOpaquePreconditioner_Complex_Double() }
@discardableResult
public func SparseCreatePreconditioner(_ type: SparsePreconditioner_t, _ A: SparseMatrix_Complex_Float) -> SparseOpaquePreconditioner_Complex_Float { return SparseOpaquePreconditioner_Complex_Float() }
@discardableResult
public func SparseCreatePreconditioner(_ type: SparsePreconditioner_t, _ A: SparseMatrix_Double) -> SparseOpaquePreconditioner_Double { return SparseOpaquePreconditioner_Double() }
@discardableResult
public func SparseCreatePreconditioner(_ type: SparsePreconditioner_t, _ A: SparseMatrix_Float) -> SparseOpaquePreconditioner_Float { return SparseOpaquePreconditioner_Float() }
@discardableResult
public func SparseCreateSubfactor(_ subfactor: SparseSubfactor_t, _ Factor: SparseOpaqueFactorization_Complex_Double) -> SparseOpaqueSubfactor_Complex_Double { return SparseOpaqueSubfactor_Complex_Double() }
@discardableResult
public func SparseCreateSubfactor(_ subfactor: SparseSubfactor_t, _ Factor: SparseOpaqueFactorization_Complex_Float) -> SparseOpaqueSubfactor_Complex_Float { return SparseOpaqueSubfactor_Complex_Float() }
@discardableResult
public func SparseCreateSubfactor(_ subfactor: SparseSubfactor_t, _ Factor: SparseOpaqueFactorization_Double) -> SparseOpaqueSubfactor_Double { return SparseOpaqueSubfactor_Double() }
@discardableResult
public func SparseCreateSubfactor(_ subfactor: SparseSubfactor_t, _ Factor: SparseOpaqueFactorization_Float) -> SparseOpaqueSubfactor_Float { return SparseOpaqueSubfactor_Float() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrixStructure) -> SparseOpaqueSymbolicFactorization { return SparseOpaqueSymbolicFactorization() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrixStructure, _ options: SparseSymbolicFactorOptions) -> SparseOpaqueSymbolicFactorization { return SparseOpaqueSymbolicFactorization() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrixStructureComplex) -> SparseOpaqueSymbolicFactorization { return SparseOpaqueSymbolicFactorization() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ MatrixComplex: SparseMatrixStructureComplex, _ options: SparseSymbolicFactorOptions) -> SparseOpaqueSymbolicFactorization { return SparseOpaqueSymbolicFactorization() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrix_Complex_Double) -> SparseOpaqueFactorization_Complex_Double { return SparseOpaqueFactorization_Complex_Double() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrix_Complex_Double, _ options: SparseSymbolicFactorOptions, _ nfoptions: SparseNumericFactorOptions) -> SparseOpaqueFactorization_Complex_Double { return SparseOpaqueFactorization_Complex_Double() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrix_Complex_Float) -> SparseOpaqueFactorization_Complex_Float { return SparseOpaqueFactorization_Complex_Float() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrix_Complex_Float, _ options: SparseSymbolicFactorOptions, _ nfoptions: SparseNumericFactorOptions) -> SparseOpaqueFactorization_Complex_Float { return SparseOpaqueFactorization_Complex_Float() }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrix_Double) -> SparseOpaqueFactorization_Double { _ = type; return _sparseFactorDouble(Matrix) }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrix_Double, _ options: SparseSymbolicFactorOptions, _ nfoptions: SparseNumericFactorOptions) -> SparseOpaqueFactorization_Double { _ = type; _ = options; _ = nfoptions; return _sparseFactorDouble(Matrix) }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrix_Float) -> SparseOpaqueFactorization_Float { _ = type; return _sparseFactorFloat(Matrix) }
@discardableResult
public func SparseFactor(_ type: SparseFactorization_t, _ Matrix: SparseMatrix_Float, _ options: SparseSymbolicFactorOptions, _ nfoptions: SparseNumericFactorOptions) -> SparseOpaqueFactorization_Float { _ = type; _ = options; _ = nfoptions; return _sparseFactorFloat(Matrix) }
@discardableResult
public func SparseFactor(_ SymbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Complex_Double) -> SparseOpaqueFactorization_Complex_Double { return SparseOpaqueFactorization_Complex_Double() }
@discardableResult
public func SparseFactor(_ SymbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Complex_Double, _ nfoptions: SparseNumericFactorOptions) -> SparseOpaqueFactorization_Complex_Double { return SparseOpaqueFactorization_Complex_Double() }
@discardableResult
public func SparseFactor(_ symbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Complex_Double, _ nfoptions: SparseNumericFactorOptions, _ factorStorage: UnsafeMutableRawPointer?, _ workspace: UnsafeMutableRawPointer?) -> SparseOpaqueFactorization_Complex_Double { return SparseOpaqueFactorization_Complex_Double() }
@discardableResult
public func SparseFactor(_ SymbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Complex_Float) -> SparseOpaqueFactorization_Complex_Float { return SparseOpaqueFactorization_Complex_Float() }
@discardableResult
public func SparseFactor(_ SymbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Complex_Float, _ nfoptions: SparseNumericFactorOptions) -> SparseOpaqueFactorization_Complex_Float { return SparseOpaqueFactorization_Complex_Float() }
@discardableResult
public func SparseFactor(_ symbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Complex_Float, _ nfoptions: SparseNumericFactorOptions, _ factorStorage: UnsafeMutableRawPointer?, _ workspace: UnsafeMutableRawPointer?) -> SparseOpaqueFactorization_Complex_Float { return SparseOpaqueFactorization_Complex_Float() }
@discardableResult
public func SparseFactor(_ SymbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Double) -> SparseOpaqueFactorization_Double { _ = SymbolicFactor; return _sparseFactorDouble(Matrix) }
@discardableResult
public func SparseFactor(_ SymbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Double, _ nfoptions: SparseNumericFactorOptions) -> SparseOpaqueFactorization_Double { _ = SymbolicFactor; _ = nfoptions; return _sparseFactorDouble(Matrix) }
@discardableResult
public func SparseFactor(_ symbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Double, _ nfoptions: SparseNumericFactorOptions, _ factorStorage: UnsafeMutableRawPointer?, _ workspace: UnsafeMutableRawPointer?) -> SparseOpaqueFactorization_Double { _ = symbolicFactor; _ = nfoptions; _ = factorStorage; _ = workspace; return _sparseFactorDouble(Matrix) }
@discardableResult
public func SparseFactor(_ SymbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Float) -> SparseOpaqueFactorization_Float { _ = SymbolicFactor; return _sparseFactorFloat(Matrix) }
@discardableResult
public func SparseFactor(_ SymbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Float, _ nfoptions: SparseNumericFactorOptions) -> SparseOpaqueFactorization_Float { _ = SymbolicFactor; _ = nfoptions; return _sparseFactorFloat(Matrix) }
@discardableResult
public func SparseFactor(_ symbolicFactor: SparseOpaqueSymbolicFactorization, _ Matrix: SparseMatrix_Float, _ nfoptions: SparseNumericFactorOptions, _ factorStorage: UnsafeMutableRawPointer?, _ workspace: UnsafeMutableRawPointer?) -> SparseOpaqueFactorization_Float { _ = symbolicFactor; _ = nfoptions; _ = factorStorage; _ = workspace; return _sparseFactorFloat(Matrix) }
@discardableResult
public func SparseGMRES() -> SparseIterativeMethod { var method = SparseIterativeMethod(); method.method = 2; return method }
@discardableResult
public func SparseGMRES(_ options: SparseGMRESOptions) -> SparseIterativeMethod { _ = options; var method = SparseIterativeMethod(); method.method = 2; return method }
@discardableResult
public func SparseGetConjugateTranspose(_ Matrix: SparseMatrix_Complex_Double) -> SparseMatrix_Complex_Double { return SparseMatrix_Complex_Double() }
@discardableResult
public func SparseGetConjugateTranspose(_ Matrix: SparseMatrix_Complex_Float) -> SparseMatrix_Complex_Float { return SparseMatrix_Complex_Float() }
@discardableResult
public func SparseGetConjugateTranspose(_ Factor: SparseOpaqueFactorization_Complex_Double) -> SparseOpaqueFactorization_Complex_Double { return SparseOpaqueFactorization_Complex_Double() }
@discardableResult
public func SparseGetConjugateTranspose(_ Factor: SparseOpaqueFactorization_Complex_Float) -> SparseOpaqueFactorization_Complex_Float { return SparseOpaqueFactorization_Complex_Float() }
@discardableResult
public func SparseGetConjugateTranspose(_ Subfactor: SparseOpaqueSubfactor_Complex_Double) -> SparseOpaqueSubfactor_Complex_Double { return SparseOpaqueSubfactor_Complex_Double() }
@discardableResult
public func SparseGetConjugateTranspose(_ Subfactor: SparseOpaqueSubfactor_Complex_Float) -> SparseOpaqueSubfactor_Complex_Float { return SparseOpaqueSubfactor_Complex_Float() }
@discardableResult
public func SparseGetInertia(_ Factored: SparseOpaqueFactorization_Complex_Double, _ num_positive: UnsafeMutablePointer<Int32>, _ num_zero: UnsafeMutablePointer<Int32>, _ num_negative: UnsafeMutablePointer<Int32>) -> Int32 { return 0 }
@discardableResult
public func SparseGetInertia(_ Factored: SparseOpaqueFactorization_Complex_Float, _ num_positive: UnsafeMutablePointer<Int32>, _ num_zero: UnsafeMutablePointer<Int32>, _ num_negative: UnsafeMutablePointer<Int32>) -> Int32 { return 0 }
@discardableResult
public func SparseGetInertia(_ Factored: SparseOpaqueFactorization_Double, _ num_positive: UnsafeMutablePointer<Int32>, _ num_zero: UnsafeMutablePointer<Int32>, _ num_negative: UnsafeMutablePointer<Int32>) -> Int32 { return 0 }
@discardableResult
public func SparseGetInertia(_ Factored: SparseOpaqueFactorization_Float, _ num_positive: UnsafeMutablePointer<Int32>, _ num_zero: UnsafeMutablePointer<Int32>, _ num_negative: UnsafeMutablePointer<Int32>) -> Int32 { return 0 }
@discardableResult
public func SparseGetStateSize_Complex_Double(_ method: SparseIterativeMethod, _ preconditioner: Bool, _ m: Int32, _ n: Int32, _ nrhs: Int32) -> Int { return 0 }
@discardableResult
public func SparseGetStateSize_Complex_Float(_ method: SparseIterativeMethod, _ preconditioner: Bool, _ m: Int32, _ n: Int32, _ nrhs: Int32) -> Int { return 0 }
@discardableResult
public func SparseGetStateSize_Double(_ method: SparseIterativeMethod, _ preconditioner: Bool, _ m: Int32, _ n: Int32, _ nrhs: Int32) -> Int { return 0 }
@discardableResult
public func SparseGetStateSize_Float(_ method: SparseIterativeMethod, _ preconditioner: Bool, _ m: Int32, _ n: Int32, _ nrhs: Int32) -> Int { return 0 }
@discardableResult
public func SparseGetTranspose(_ Matrix: SparseMatrix_Complex_Double) -> SparseMatrix_Complex_Double { return SparseMatrix_Complex_Double() }
@discardableResult
public func SparseGetTranspose(_ Matrix: SparseMatrix_Complex_Float) -> SparseMatrix_Complex_Float { return SparseMatrix_Complex_Float() }
@discardableResult
public func SparseGetTranspose(_ Matrix: SparseMatrix_Double) -> SparseMatrix_Double { return SparseMatrix_Double() }
@discardableResult
public func SparseGetTranspose(_ Matrix: SparseMatrix_Float) -> SparseMatrix_Float { return SparseMatrix_Float() }
@discardableResult
public func SparseGetTranspose(_ Factor: SparseOpaqueFactorization_Complex_Double) -> SparseOpaqueFactorization_Complex_Double { return SparseOpaqueFactorization_Complex_Double() }
@discardableResult
public func SparseGetTranspose(_ Factor: SparseOpaqueFactorization_Complex_Float) -> SparseOpaqueFactorization_Complex_Float { return SparseOpaqueFactorization_Complex_Float() }
@discardableResult
public func SparseGetTranspose(_ Factor: SparseOpaqueFactorization_Double) -> SparseOpaqueFactorization_Double { return SparseOpaqueFactorization_Double() }
@discardableResult
public func SparseGetTranspose(_ Factor: SparseOpaqueFactorization_Float) -> SparseOpaqueFactorization_Float { return SparseOpaqueFactorization_Float() }
@discardableResult
public func SparseGetTranspose(_ Subfactor: SparseOpaqueSubfactor_Complex_Double) -> SparseOpaqueSubfactor_Complex_Double { return SparseOpaqueSubfactor_Complex_Double() }
@discardableResult
public func SparseGetTranspose(_ Subfactor: SparseOpaqueSubfactor_Complex_Float) -> SparseOpaqueSubfactor_Complex_Float { return SparseOpaqueSubfactor_Complex_Float() }
@discardableResult
public func SparseGetTranspose(_ Subfactor: SparseOpaqueSubfactor_Double) -> SparseOpaqueSubfactor_Double { return SparseOpaqueSubfactor_Double() }
@discardableResult
public func SparseGetTranspose(_ Subfactor: SparseOpaqueSubfactor_Float) -> SparseOpaqueSubfactor_Float { return SparseOpaqueSubfactor_Float() }
public func SparseIterate(_ method: SparseIterativeMethod, _ iteration: Int32, _ converged: UnsafePointer<Bool>, _ state: UnsafeMutableRawPointer, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Complex_Double, DenseMatrix_Complex_Double) -> Void, _ B: DenseMatrix_Complex_Double, _ R: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double) { }
public func SparseIterate(_ method: SparseIterativeMethod, _ iteration: Int32, _ converged: UnsafePointer<Bool>, _ state: UnsafeMutableRawPointer, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Complex_Double, DenseMatrix_Complex_Double) -> Void, _ B: DenseMatrix_Complex_Double, _ R: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double, _ Preconditioner: SparseOpaquePreconditioner_Complex_Double) { }
public func SparseIterate(_ method: SparseIterativeMethod, _ iteration: Int32, _ converged: UnsafePointer<Bool>, _ state: UnsafeMutableRawPointer, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Complex_Float, DenseMatrix_Complex_Float) -> Void, _ B: DenseMatrix_Complex_Float, _ R: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float) { }
public func SparseIterate(_ method: SparseIterativeMethod, _ iteration: Int32, _ converged: UnsafePointer<Bool>, _ state: UnsafeMutableRawPointer, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Complex_Float, DenseMatrix_Complex_Float) -> Void, _ B: DenseMatrix_Complex_Float, _ R: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float, _ Preconditioner: SparseOpaquePreconditioner_Complex_Float) { }
public func SparseIterate(_ method: SparseIterativeMethod, _ iteration: Int32, _ converged: UnsafePointer<Bool>, _ state: UnsafeMutableRawPointer, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Double, DenseMatrix_Double) -> Void, _ B: DenseMatrix_Double, _ R: DenseMatrix_Double, _ X: DenseMatrix_Double) { }
public func SparseIterate(_ method: SparseIterativeMethod, _ iteration: Int32, _ converged: UnsafePointer<Bool>, _ state: UnsafeMutableRawPointer, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Double, DenseMatrix_Double) -> Void, _ B: DenseMatrix_Double, _ R: DenseMatrix_Double, _ X: DenseMatrix_Double, _ Preconditioner: SparseOpaquePreconditioner_Double) { }
public func SparseIterate(_ method: SparseIterativeMethod, _ iteration: Int32, _ converged: UnsafePointer<Bool>, _ state: UnsafeMutableRawPointer, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Float, DenseMatrix_Float) -> Void, _ B: DenseMatrix_Float, _ R: DenseMatrix_Float, _ X: DenseMatrix_Float) { }
public func SparseIterate(_ method: SparseIterativeMethod, _ iteration: Int32, _ converged: UnsafePointer<Bool>, _ state: UnsafeMutableRawPointer, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Float, DenseMatrix_Float) -> Void, _ B: DenseMatrix_Float, _ R: DenseMatrix_Float, _ X: DenseMatrix_Float, _ Preconditioner: SparseOpaquePreconditioner_Float) { }
@discardableResult
public func SparseLSMR() -> SparseIterativeMethod { var method = SparseIterativeMethod(); method.method = 3; return method }
@discardableResult
public func SparseLSMR(_ options: SparseLSMROptions) -> SparseIterativeMethod { _ = options; var method = SparseIterativeMethod(); method.method = 3; return method }
public func SparseMultiply(_ A: SparseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double, _ Y: DenseMatrix_Complex_Double) { }
public func SparseMultiply(_ A: SparseMatrix_Complex_Double, _ x: DenseVector_Complex_Double, _ y: DenseVector_Complex_Double) { }
public func SparseMultiply(_ A: SparseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float, _ Y: DenseMatrix_Complex_Float) { }
public func SparseMultiply(_ A: SparseMatrix_Complex_Float, _ x: DenseVector_Complex_Float, _ y: DenseVector_Complex_Float) { }
public func SparseMultiply(_ A: SparseMatrix_Double, _ X: DenseMatrix_Double, _ Y: DenseMatrix_Double) {
    _sparseCSCMultiplyMatrixD(structure: A.structure, data: A.data, x: X, y: Y, alpha: 1, add: false)
}
public func SparseMultiply(_ A: SparseMatrix_Double, _ x: DenseVector_Double, _ y: DenseVector_Double) {
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: 1, add: false)
}
public func SparseMultiply(_ A: SparseMatrix_Float, _ X: DenseMatrix_Float, _ Y: DenseMatrix_Float) {
    _sparseCSCMultiplyMatrix(structure: A.structure, data: A.data, x: X, y: Y, alpha: 1, add: false)
}
public func SparseMultiply(_ A: SparseMatrix_Float, _ x: DenseVector_Float, _ y: DenseVector_Float) {
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: 1, add: false)
}
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ XY: DenseMatrix_Complex_Double) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ XY: DenseMatrix_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ X: DenseMatrix_Complex_Double, _ Y: DenseMatrix_Complex_Double) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ X: DenseMatrix_Complex_Double, _ Y: DenseMatrix_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ XY: DenseVector_Complex_Double) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ XY: DenseVector_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ X: DenseVector_Complex_Double, _ Y: DenseVector_Complex_Double) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ X: DenseVector_Complex_Double, _ Y: DenseVector_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ XY: DenseMatrix_Complex_Float) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ XY: DenseMatrix_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ X: DenseMatrix_Complex_Float, _ Y: DenseMatrix_Complex_Float) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ X: DenseMatrix_Complex_Float, _ Y: DenseMatrix_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ XY: DenseVector_Complex_Float) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ XY: DenseVector_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ X: DenseVector_Complex_Float, _ Y: DenseVector_Complex_Float) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ X: DenseVector_Complex_Float, _ Y: DenseVector_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Double, _ XY: DenseMatrix_Double) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Double, _ XY: DenseMatrix_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Double, _ X: DenseMatrix_Double, _ Y: DenseMatrix_Double) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Double, _ X: DenseMatrix_Double, _ Y: DenseMatrix_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Double, _ XY: DenseVector_Double) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Double, _ XY: DenseVector_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Double, _ X: DenseVector_Double, _ Y: DenseVector_Double) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Double, _ X: DenseVector_Double, _ Y: DenseVector_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Float, _ XY: DenseMatrix_Float) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Float, _ XY: DenseMatrix_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Float, _ X: DenseMatrix_Float, _ Y: DenseMatrix_Float) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Float, _ X: DenseMatrix_Float, _ Y: DenseMatrix_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Float, _ XY: DenseVector_Float) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Float, _ XY: DenseVector_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Float, _ X: DenseVector_Float, _ Y: DenseVector_Float) { }
public func SparseMultiply(_ Subfactor: SparseOpaqueSubfactor_Float, _ X: DenseVector_Float, _ Y: DenseVector_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseMultiply(_ alpha: Double, _ A: SparseMatrix_Double, _ X: DenseMatrix_Double, _ Y: DenseMatrix_Double) {
    _sparseCSCMultiplyMatrixD(structure: A.structure, data: A.data, x: X, y: Y, alpha: alpha, add: false)
}
public func SparseMultiply(_ alpha: Double, _ A: SparseMatrix_Double, _ x: DenseVector_Double, _ y: DenseVector_Double) {
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: alpha, add: false)
}
public func SparseMultiply(_ alpha: Float, _ A: SparseMatrix_Float, _ X: DenseMatrix_Float, _ Y: DenseMatrix_Float) {
    _sparseCSCMultiplyMatrix(structure: A.structure, data: A.data, x: X, y: Y, alpha: alpha, add: false)
}
public func SparseMultiply(_ alpha: Float, _ A: SparseMatrix_Float, _ x: DenseVector_Float, _ y: DenseVector_Float) {
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: alpha, add: false)
}
public func SparseMultiplyAdd(_ A: SparseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double, _ Y: DenseMatrix_Complex_Double) { }
public func SparseMultiplyAdd(_ A: SparseMatrix_Complex_Double, _ x: DenseVector_Complex_Double, _ y: DenseVector_Complex_Double) { }
public func SparseMultiplyAdd(_ A: SparseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float, _ Y: DenseMatrix_Complex_Float) { }
public func SparseMultiplyAdd(_ A: SparseMatrix_Complex_Float, _ x: DenseVector_Complex_Float, _ y: DenseVector_Complex_Float) { }
public func SparseMultiplyAdd(_ A: SparseMatrix_Double, _ X: DenseMatrix_Double, _ Y: DenseMatrix_Double) {
    _sparseCSCMultiplyMatrixD(structure: A.structure, data: A.data, x: X, y: Y, alpha: 1, add: true)
}
public func SparseMultiplyAdd(_ A: SparseMatrix_Double, _ x: DenseVector_Double, _ y: DenseVector_Double) {
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: 1, add: true)
}
public func SparseMultiplyAdd(_ A: SparseMatrix_Float, _ X: DenseMatrix_Float, _ Y: DenseMatrix_Float) {
    _sparseCSCMultiplyMatrix(structure: A.structure, data: A.data, x: X, y: Y, alpha: 1, add: true)
}
public func SparseMultiplyAdd(_ A: SparseMatrix_Float, _ x: DenseVector_Float, _ y: DenseVector_Float) {
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: 1, add: true)
}
public func SparseMultiplyAdd(_ alpha: Double, _ A: SparseMatrix_Double, _ X: DenseMatrix_Double, _ Y: DenseMatrix_Double) {
    _sparseCSCMultiplyMatrixD(structure: A.structure, data: A.data, x: X, y: Y, alpha: alpha, add: true)
}
public func SparseMultiplyAdd(_ alpha: Double, _ A: SparseMatrix_Double, _ x: DenseVector_Double, _ y: DenseVector_Double) {
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: alpha, add: true)
}
public func SparseMultiplyAdd(_ alpha: Float, _ A: SparseMatrix_Float, _ X: DenseMatrix_Float, _ Y: DenseMatrix_Float) {
    _sparseCSCMultiplyMatrix(structure: A.structure, data: A.data, x: X, y: Y, alpha: alpha, add: true)
}
public func SparseMultiplyAdd(_ alpha: Float, _ A: SparseMatrix_Float, _ x: DenseVector_Float, _ y: DenseVector_Float) {
    _sparseCSCMultiplyVector(structure: A.structure, data: A.data, x: x.data, y: y.data, alpha: alpha, add: true)
}
public func SparseRefactor(_ Matrix: SparseMatrix_Complex_Double, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Double>) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Complex_Double, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Double>, _ nfoptions: SparseNumericFactorOptions) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Complex_Double, _ Factored: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Double>, _ nfoptions: SparseNumericFactorOptions, _ workspace: UnsafeMutableRawPointer) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Complex_Double, _ Factored: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Double>, _ workspace: UnsafeMutableRawPointer) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Complex_Float, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Float>) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Complex_Float, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Float>, _ nfoptions: SparseNumericFactorOptions) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Complex_Float, _ Factored: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Float>, _ nfoptions: SparseNumericFactorOptions, _ workspace: UnsafeMutableRawPointer) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Complex_Float, _ Factored: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Float>, _ workspace: UnsafeMutableRawPointer) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Double, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Double>) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Double, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Double>, _ nfoptions: SparseNumericFactorOptions) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Double, _ Factored: UnsafeMutablePointer<SparseOpaqueFactorization_Double>, _ nfoptions: SparseNumericFactorOptions, _ workspace: UnsafeMutableRawPointer) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Double, _ Factored: UnsafeMutablePointer<SparseOpaqueFactorization_Double>, _ workspace: UnsafeMutableRawPointer) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Float, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Float>) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Float, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Float>, _ nfoptions: SparseNumericFactorOptions) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Float, _ Factored: UnsafeMutablePointer<SparseOpaqueFactorization_Float>, _ nfoptions: SparseNumericFactorOptions, _ workspace: UnsafeMutableRawPointer) { }
public func SparseRefactor(_ Matrix: SparseMatrix_Float, _ Factored: UnsafeMutablePointer<SparseOpaqueFactorization_Float>, _ workspace: UnsafeMutableRawPointer) { }
@discardableResult
public func SparseRetain(_ NumericFactor: SparseOpaqueFactorization_Complex_Double) -> SparseOpaqueFactorization_Complex_Double { return SparseOpaqueFactorization_Complex_Double() }
@discardableResult
public func SparseRetain(_ NumericFactor: SparseOpaqueFactorization_Complex_Float) -> SparseOpaqueFactorization_Complex_Float { return SparseOpaqueFactorization_Complex_Float() }
@discardableResult
public func SparseRetain(_ NumericFactor: SparseOpaqueFactorization_Double) -> SparseOpaqueFactorization_Double { return SparseOpaqueFactorization_Double() }
@discardableResult
public func SparseRetain(_ NumericFactor: SparseOpaqueFactorization_Float) -> SparseOpaqueFactorization_Float { return SparseOpaqueFactorization_Float() }
@discardableResult
public func SparseRetain(_ Subfactor: SparseOpaqueSubfactor_Complex_Double) -> SparseOpaqueSubfactor_Complex_Double { return SparseOpaqueSubfactor_Complex_Double() }
@discardableResult
public func SparseRetain(_ Subfactor: SparseOpaqueSubfactor_Complex_Float) -> SparseOpaqueSubfactor_Complex_Float { return SparseOpaqueSubfactor_Complex_Float() }
@discardableResult
public func SparseRetain(_ Subfactor: SparseOpaqueSubfactor_Double) -> SparseOpaqueSubfactor_Double { return SparseOpaqueSubfactor_Double() }
@discardableResult
public func SparseRetain(_ Subfactor: SparseOpaqueSubfactor_Float) -> SparseOpaqueSubfactor_Float { return SparseOpaqueSubfactor_Float() }
@discardableResult
public func SparseRetain(_ SymbolicFactor: SparseOpaqueSymbolicFactorization) -> SparseOpaqueSymbolicFactorization { return SparseOpaqueSymbolicFactorization() }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Double, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Double, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double, _ Preconditioner: SparsePreconditioner_t) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Double, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double, _ Preconditioner: SparseOpaquePreconditioner_Complex_Double) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Double, _ b: DenseVector_Complex_Double, _ x: DenseVector_Complex_Double) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Double, _ b: DenseVector_Complex_Double, _ x: DenseVector_Complex_Double, _ Preconditioner: SparsePreconditioner_t) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Double, _ b: DenseVector_Complex_Double, _ x: DenseVector_Complex_Double, _ Preconditioner: SparseOpaquePreconditioner_Complex_Double) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Float, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Float, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float, _ Preconditioner: SparsePreconditioner_t) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Float, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float, _ Preconditioner: SparseOpaquePreconditioner_Complex_Float) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Float, _ b: DenseVector_Complex_Float, _ x: DenseVector_Complex_Float) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Float, _ b: DenseVector_Complex_Float, _ x: DenseVector_Complex_Float, _ Preconditioner: SparsePreconditioner_t) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Complex_Float, _ b: DenseVector_Complex_Float, _ x: DenseVector_Complex_Float, _ Preconditioner: SparseOpaquePreconditioner_Complex_Float) -> SparseIterativeStatus_t { _ = method; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Double, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double) -> SparseIterativeStatus_t { _ = method; return _sparseSolveMatrixDouble(A, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Double, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double, _ Preconditioner: SparsePreconditioner_t) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveMatrixDouble(A, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Double, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double, _ Preconditioner: SparseOpaquePreconditioner_Double) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveMatrixDouble(A, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Double, _ b: DenseVector_Double, _ x: DenseVector_Double) -> SparseIterativeStatus_t { _ = method; return _sparseSolveVectorDouble(A, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Double, _ b: DenseVector_Double, _ x: DenseVector_Double, _ Preconditioner: SparsePreconditioner_t) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveVectorDouble(A, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Double, _ b: DenseVector_Double, _ x: DenseVector_Double, _ Preconditioner: SparseOpaquePreconditioner_Double) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveVectorDouble(A, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Float, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float) -> SparseIterativeStatus_t { _ = method; return _sparseSolveMatrixFloat(A, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Float, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float, _ Preconditioner: SparsePreconditioner_t) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveMatrixFloat(A, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Float, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float, _ Preconditioner: SparseOpaquePreconditioner_Float) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveMatrixFloat(A, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Float, _ b: DenseVector_Float, _ x: DenseVector_Float) -> SparseIterativeStatus_t { _ = method; return _sparseSolveVectorFloat(A, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Float, _ b: DenseVector_Float, _ x: DenseVector_Float, _ Preconditioner: SparsePreconditioner_t) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveVectorFloat(A, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ A: SparseMatrix_Float, _ b: DenseVector_Float, _ x: DenseVector_Float, _ Preconditioner: SparseOpaquePreconditioner_Float) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveVectorFloat(A, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Complex_Double, DenseMatrix_Complex_Double) -> Void, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double) -> SparseIterativeStatus_t { _ = method; _ = ApplyOperator; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Complex_Double, DenseMatrix_Complex_Double) -> Void, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double, _ Preconditioner: SparseOpaquePreconditioner_Complex_Double) -> SparseIterativeStatus_t { _ = method; _ = ApplyOperator; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Complex_Float, DenseMatrix_Complex_Float) -> Void, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float) -> SparseIterativeStatus_t { _ = method; _ = ApplyOperator; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Complex_Float, DenseMatrix_Complex_Float) -> Void, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float, _ Preconditioner: SparseOpaquePreconditioner_Complex_Float) -> SparseIterativeStatus_t { _ = method; _ = ApplyOperator; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Double, DenseMatrix_Double) -> Void, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double) -> SparseIterativeStatus_t { _ = method; return _sparseSolveApplyMatrixDouble(ApplyOperator, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Double, DenseMatrix_Double) -> Void, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double, _ Preconditioner: SparseOpaquePreconditioner_Double) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveApplyMatrixDouble(ApplyOperator, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Float, DenseMatrix_Float) -> Void, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float) -> SparseIterativeStatus_t { _ = method; return _sparseSolveApplyMatrixFloat(ApplyOperator, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseMatrix_Float, DenseMatrix_Float) -> Void, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float, _ Preconditioner: SparseOpaquePreconditioner_Float) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveApplyMatrixFloat(ApplyOperator, B, X) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseVector_Complex_Double, DenseVector_Complex_Double) -> Void, _ b: DenseVector_Complex_Double, _ x: DenseVector_Complex_Double) -> SparseIterativeStatus_t { _ = method; _ = ApplyOperator; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseVector_Complex_Double, DenseVector_Complex_Double) -> Void, _ b: DenseVector_Complex_Double, _ x: DenseVector_Complex_Double, _ Preconditioner: SparseOpaquePreconditioner_Complex_Double) -> SparseIterativeStatus_t { _ = method; _ = ApplyOperator; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseVector_Complex_Float, DenseVector_Complex_Float) -> Void, _ b: DenseVector_Complex_Float, _ x: DenseVector_Complex_Float) -> SparseIterativeStatus_t { _ = method; _ = ApplyOperator; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseVector_Complex_Float, DenseVector_Complex_Float) -> Void, _ b: DenseVector_Complex_Float, _ x: DenseVector_Complex_Float, _ Preconditioner: SparseOpaquePreconditioner_Complex_Float) -> SparseIterativeStatus_t { _ = method; _ = ApplyOperator; return SparseIterativeParameterError }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseVector_Double, DenseVector_Double) -> Void, _ b: DenseVector_Double, _ x: DenseVector_Double) -> SparseIterativeStatus_t { _ = method; return _sparseSolveApplyVectorDouble(ApplyOperator, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseVector_Double, DenseVector_Double) -> Void, _ b: DenseVector_Double, _ x: DenseVector_Double, _ Preconditioner: SparseOpaquePreconditioner_Double) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveApplyVectorDouble(ApplyOperator, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseVector_Float, DenseVector_Float) -> Void, _ b: DenseVector_Float, _ x: DenseVector_Float) -> SparseIterativeStatus_t { _ = method; return _sparseSolveApplyVectorFloat(ApplyOperator, b, x) }
@discardableResult
public func SparseSolve(_ method: SparseIterativeMethod, _ ApplyOperator: @escaping (Bool, CBLAS_TRANSPOSE, DenseVector_Float, DenseVector_Float) -> Void, _ b: DenseVector_Float, _ x: DenseVector_Float, _ Preconditioner: SparseOpaquePreconditioner_Float) -> SparseIterativeStatus_t { _ = method; _ = Preconditioner; return _sparseSolveApplyVectorFloat(ApplyOperator, b, x) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Double, _ XB: DenseMatrix_Complex_Double) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Double, _ XB: DenseMatrix_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Double, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Double, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Double, _ xb: DenseVector_Complex_Double) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Double, _ xb: DenseVector_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Double, _ b: DenseVector_Complex_Double, _ x: DenseVector_Complex_Double) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Double, _ b: DenseVector_Complex_Double, _ x: DenseVector_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Float, _ XB: DenseMatrix_Complex_Float) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Float, _ XB: DenseMatrix_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Float, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Float, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Float, _ xb: DenseVector_Complex_Float) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Float, _ xb: DenseVector_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Float, _ b: DenseVector_Complex_Float, _ x: DenseVector_Complex_Float) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Complex_Float, _ b: DenseVector_Complex_Float, _ x: DenseVector_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Double, _ XB: DenseMatrix_Double) { _sparseSolveFactoredInPlaceMatrixDouble(Factored, XB) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Double, _ XB: DenseMatrix_Double, _ workspace: UnsafeMutableRawPointer) { _ = workspace; _sparseSolveFactoredInPlaceMatrixDouble(Factored, XB) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Double, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double) { _ = _sparseSolveFactoredMatrixDouble(Factored, B, X) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Double, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double, _ workspace: UnsafeMutableRawPointer) { _ = workspace; _ = _sparseSolveFactoredMatrixDouble(Factored, B, X) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Double, _ xb: DenseVector_Double) { _sparseSolveFactoredInPlaceVectorDouble(Factored, xb) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Double, _ xb: DenseVector_Double, _ workspace: UnsafeMutableRawPointer) { _ = workspace; _sparseSolveFactoredInPlaceVectorDouble(Factored, xb) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Double, _ b: DenseVector_Double, _ x: DenseVector_Double) { _ = _sparseSolveFactoredVectorDouble(Factored, b, x) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Double, _ b: DenseVector_Double, _ x: DenseVector_Double, _ workspace: UnsafeMutableRawPointer) { _ = workspace; _ = _sparseSolveFactoredVectorDouble(Factored, b, x) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Float, _ XB: DenseMatrix_Float) { _sparseSolveFactoredInPlaceMatrixFloat(Factored, XB) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Float, _ XB: DenseMatrix_Float, _ workspace: UnsafeMutableRawPointer) { _ = workspace; _sparseSolveFactoredInPlaceMatrixFloat(Factored, XB) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Float, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float) { _ = _sparseSolveFactoredMatrixFloat(Factored, B, X) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Float, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float, _ workspace: UnsafeMutableRawPointer) { _ = workspace; _ = _sparseSolveFactoredMatrixFloat(Factored, B, X) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Float, _ xb: DenseVector_Float) { _sparseSolveFactoredInPlaceVectorFloat(Factored, xb) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Float, _ xb: DenseVector_Float, _ workspace: UnsafeMutableRawPointer) { _ = workspace; _sparseSolveFactoredInPlaceVectorFloat(Factored, xb) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Float, _ b: DenseVector_Float, _ x: DenseVector_Float) { _ = _sparseSolveFactoredVectorFloat(Factored, b, x) }
public func SparseSolve(_ Factored: SparseOpaqueFactorization_Float, _ b: DenseVector_Float, _ x: DenseVector_Float, _ workspace: UnsafeMutableRawPointer) { _ = workspace; _ = _sparseSolveFactoredVectorFloat(Factored, b, x) }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ XB: DenseMatrix_Complex_Double) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ XB: DenseMatrix_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ B: DenseMatrix_Complex_Double, _ X: DenseMatrix_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ XB: DenseVector_Complex_Double) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ XB: DenseVector_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ B: DenseVector_Complex_Double, _ X: DenseVector_Complex_Double) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Double, _ B: DenseVector_Complex_Double, _ X: DenseVector_Complex_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ XB: DenseMatrix_Complex_Float) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ XB: DenseMatrix_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ B: DenseMatrix_Complex_Float, _ X: DenseMatrix_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ XB: DenseVector_Complex_Float) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ XB: DenseVector_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ B: DenseVector_Complex_Float, _ X: DenseVector_Complex_Float) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Complex_Float, _ B: DenseVector_Complex_Float, _ X: DenseVector_Complex_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Double, _ XB: DenseMatrix_Double) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Double, _ XB: DenseMatrix_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Double, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Double, _ B: DenseMatrix_Double, _ X: DenseMatrix_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Double, _ XB: DenseVector_Double) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Double, _ XB: DenseVector_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Double, _ B: DenseVector_Double, _ X: DenseVector_Double) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Double, _ B: DenseVector_Double, _ X: DenseVector_Double, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Float, _ XB: DenseMatrix_Float) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Float, _ XB: DenseMatrix_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Float, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Float, _ B: DenseMatrix_Float, _ X: DenseMatrix_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Float, _ XB: DenseVector_Float) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Float, _ XB: DenseVector_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Float, _ B: DenseVector_Float, _ X: DenseVector_Float) { }
public func SparseSolve(_ Subfactor: SparseOpaqueSubfactor_Float, _ B: DenseVector_Float, _ X: DenseVector_Float, _ workspace: UnsafeMutableRawPointer) { }
public func SparseUpdateFactor(_ updateAlgorithm: SparseUpdate_t, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Double>, _ updateCount: Int32, _ updatedIndices: UnsafePointer<Int32>, _ Update: SparseMatrix_Complex_Double) { }
public func SparseUpdateFactor(_ updateAlgorithm: SparseUpdate_t, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Complex_Float>, _ updateCount: Int32, _ updatedIndices: UnsafePointer<Int32>, _ Update: SparseMatrix_Complex_Float) { }
public func SparseUpdateFactor(_ updateAlgorithm: SparseUpdate_t, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Double>, _ updateCount: Int32, _ updatedIndices: UnsafePointer<Int32>, _ Update: SparseMatrix_Double) { }
public func SparseUpdateFactor(_ updateAlgorithm: SparseUpdate_t, _ Factorization: UnsafeMutablePointer<SparseOpaqueFactorization_Float>, _ updateCount: Int32, _ updatedIndices: UnsafePointer<Int32>, _ Update: SparseMatrix_Float) { }
@discardableResult
public func caxpy_(_ n: UnsafeMutablePointer<Int32>!, _ ca: UnsafeMutableRawPointer!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ccopy_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
public func cdotc_(_ ret_val: UnsafeMutableRawPointer!, _ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) { }
public func cdotu_(_ ret_val: UnsafeMutableRawPointer!, _ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) { }
@discardableResult
public func cgbmv_(_ trans: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ kl: UnsafeMutablePointer<Int32>!, _ ku: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cgemm_(_ transa: UnsafeMutablePointer<CChar>!, _ transb: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cgemv_(_ trans: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cgerc_(_ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cgeru_(_ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func chbmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func chemm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func chemv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cher2_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cher2k_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cher_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cherk_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func chpmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ ap: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func chpr2_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutableRawPointer!) -> Int32 { return 0 }
@discardableResult
public func chpr_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutableRawPointer!) -> Int32 { return 0 }
@discardableResult
public func crotg_(_ ca: UnsafeMutableRawPointer!, _ cb: UnsafeMutableRawPointer!, _ c: UnsafeMutablePointer<Float>!, _ cs: UnsafeMutableRawPointer!) -> Int32 { return 0 }
@discardableResult
public func cscal_(_ n: UnsafeMutablePointer<Int32>!, _ ca: UnsafeMutableRawPointer!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func csrot_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ c: UnsafeMutablePointer<Float>!, _ s: UnsafeMutablePointer<Float>!) -> Int32 { return 0 }
@discardableResult
public func csscal_(_ n: UnsafeMutablePointer<Int32>!, _ sa: UnsafeMutablePointer<Float>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func cswap_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func csymm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func csyr2k_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func csyrk_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ctbmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ctbsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ctpmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ctpsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ctrmm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ transa: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ctrmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ctrsm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ transa: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ctrsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dgbmv_(_ trans: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ kl: UnsafeMutablePointer<Int32>!, _ ku: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ y: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dgemm_(_ transa: UnsafeMutablePointer<CChar>!, _ transb: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Double>!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ c__: UnsafeMutablePointer<Double>!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let transa, let transb, let m, let n, let k, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _gemm(transA: transa.pointee, transB: transb.pointee, m: Int(m.pointee), n: Int(n.pointee), k: Int(k.pointee), alpha: alpha.pointee, a: a, lda: Int(lda.pointee), b: b, ldb: Int(ldb.pointee), beta: beta.pointee, c: c__, ldc: Int(ldc.pointee))
}
@discardableResult
public func dgemv_(_ trans: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ y: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let trans, let m, let n, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _gemv(trans: trans.pointee, m: Int(m.pointee), n: Int(n.pointee), alpha: alpha.pointee, a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee), beta: beta.pointee, y: y, incy: Int(incy.pointee))
}
@discardableResult
public func dger_(_ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let m, let n, let alpha, let x, let incx, let y, let incy, let a, let lda else { return -1 }
    let rows = Int(m.pointee); let cols = Int(n.pointee); let al = alpha.pointee
    let ix = Int(incx.pointee); let iy = Int(incy.pointee); let ld = Int(lda.pointee)
    guard rows > 0, cols > 0, ld >= rows else { return 0 }
    var xi = 0
    for i in 0..<rows {
        var yj = 0
        for j in 0..<cols {
            a[i + j * ld] += al * x[xi] * y[yj]
            yj += iy
        }
        xi += ix
    }
    return 0
}
@discardableResult
public func drot_(_ n: UnsafeMutablePointer<Int32>!, _ dx: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ dy: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!, _ c: UnsafeMutablePointer<Double>!, _ s: UnsafeMutablePointer<Double>!) -> Int32 {
    guard let n, let dx, let incx, let dy, let incy, let c, let s else { return -1 }
    return _rot(n: Int(n.pointee), x: dx, incx: Int(incx.pointee), y: dy, incy: Int(incy.pointee), c: c.pointee, s: s.pointee)
}
@discardableResult
public func drotg_(_ da: UnsafeMutablePointer<Double>!, _ db: UnsafeMutablePointer<Double>!, _ c: UnsafeMutablePointer<Double>!, _ s: UnsafeMutablePointer<Double>!) -> Int32 {
    guard let da, let db, let c, let s else { return -1 }
    return _rotg(a: &da.pointee, b: &db.pointee, c: &c.pointee, s: &s.pointee)
}
@discardableResult
public func drotm_(_ n: UnsafeMutablePointer<Int32>!, _ dx: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ dy: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!, _ dparam: UnsafeMutablePointer<Double>!) -> Int32 { return 0 }
@discardableResult
public func drotmg_(_ dd1: UnsafeMutablePointer<Double>!, _ dd2: UnsafeMutablePointer<Double>!, _ dx1: UnsafeMutablePointer<Double>!, _ dy1: UnsafeMutablePointer<Double>!, _ dparam: UnsafeMutablePointer<Double>!) -> Int32 { return 0 }
@discardableResult
public func dsbmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ y: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dsdot_(_ n: UnsafeMutablePointer<Int32>!, _ sx: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ sy: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!) -> Double {
    return sdot_(n, sx, incx, sy, incy)
}
@discardableResult
public func dspmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ ap: UnsafeMutablePointer<Double>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ y: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dspr2_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutablePointer<Double>!) -> Int32 { return 0 }
@discardableResult
public func dspr_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutablePointer<Double>!) -> Int32 { return 0 }
@discardableResult
public func dsymm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Double>!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ c__: UnsafeMutablePointer<Double>!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dsymv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ y: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let n, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _symv(uplo: uplo.pointee, n: Int(n.pointee), alpha: alpha.pointee, a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee), beta: beta.pointee, y: y, incy: Int(incy.pointee))
}
@discardableResult
public func dsyr2_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutablePointer<Double>!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dsyr2k_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Double>!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ c__: UnsafeMutablePointer<Double>!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dsyr_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let a, let lda else { return -1 }
    return _syr(uplo: uplo.pointee, n: Int(n.pointee), alpha: alpha.pointee, x: x, incx: Int(incx.pointee), a: a, lda: Int(lda.pointee))
}
@discardableResult
public func dsyrk_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ c__: UnsafeMutablePointer<Double>!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let beta, let c__, let ldc else { return -1 }
    return _syrk(uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee), alpha: alpha.pointee, a: a, lda: Int(lda.pointee), beta: beta.pointee, c: c__, ldc: Int(ldc.pointee))
}
@discardableResult
public func dtbmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dtbsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dtpmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutablePointer<Double>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dtpsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutablePointer<Double>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dtrmm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ transa: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Double>!, _ ldb: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dtrmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let trans, let diag, let n, let a, let lda, let x, let incx else { return -1 }
    return _trmv(uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee))
}
@discardableResult
public func dtrsm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ transa: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Double>!, _ ldb: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func dtrsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Double>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Double>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let trans, let diag, let n, let a, let lda, let x, let incx else { return -1 }
    return _trsv(uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee))
}
@discardableResult
public func dzasum_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Double { return 0 }
@discardableResult
public func dznrm2_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Double { return 0 }
@discardableResult
public func icamax_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func izamax_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
public func la_add_attributes(_ object: la_object_t, _ attributes: la_attribute_t) { }
@discardableResult
public func la_diagonal_matrix_from_vector(_ vector: la_object_t, _ matrix_diagonal: la_index_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_difference(_ obj_left: la_object_t, _ obj_right: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_elementwise_product(_ obj_left: la_object_t, _ obj_right: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_identity_matrix(_ matrix_size: la_count_t, _ scalar_type: la_scalar_type_t, _ attributes: la_attribute_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_inner_product(_ vector_left: la_object_t, _ vector_right: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_matrix_cols(_ matrix: la_object_t) -> la_count_t { return 0 }
@discardableResult
public func la_matrix_from_double_buffer(_ buffer: UnsafePointer<Double>, _ matrix_rows: la_count_t, _ matrix_cols: la_count_t, _ matrix_row_stride: la_count_t, _ matrix_hint: la_hint_t, _ attributes: la_attribute_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_matrix_from_double_buffer_nocopy(_ buffer: UnsafeMutablePointer<Double>, _ matrix_rows: la_count_t, _ matrix_cols: la_count_t, _ matrix_row_stride: la_count_t, _ matrix_hint: la_hint_t, _ deallocator: la_deallocator_t?, _ attributes: la_attribute_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_matrix_from_float_buffer(_ buffer: UnsafePointer<Float>, _ matrix_rows: la_count_t, _ matrix_cols: la_count_t, _ matrix_row_stride: la_count_t, _ matrix_hint: la_hint_t, _ attributes: la_attribute_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_matrix_from_float_buffer_nocopy(_ buffer: UnsafeMutablePointer<Float>, _ matrix_rows: la_count_t, _ matrix_cols: la_count_t, _ matrix_row_stride: la_count_t, _ matrix_hint: la_hint_t, _ deallocator: la_deallocator_t?, _ attributes: la_attribute_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_matrix_from_splat(_ splat: la_object_t, _ matrix_rows: la_count_t, _ matrix_cols: la_count_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_matrix_product(_ matrix_left: la_object_t, _ matrix_right: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_matrix_rows(_ matrix: la_object_t) -> la_count_t { return 0 }
@discardableResult
public func la_matrix_slice(_ matrix: la_object_t, _ matrix_first_row: la_index_t, _ matrix_first_col: la_index_t, _ matrix_row_stride: la_index_t, _ matrix_col_stride: la_index_t, _ slice_rows: la_count_t, _ slice_cols: la_count_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_matrix_to_double_buffer(_ buffer: UnsafeMutablePointer<Double>, _ buffer_row_stride: la_count_t, _ matrix: la_object_t) -> la_status_t { return 0 }
@discardableResult
public func la_matrix_to_float_buffer(_ buffer: UnsafeMutablePointer<Float>, _ buffer_row_stride: la_count_t, _ matrix: la_object_t) -> la_status_t { return 0 }
@discardableResult
public func la_norm_as_double(_ vector: la_object_t, _ vector_norm: la_norm_t) -> Double { return 0 }
@discardableResult
public func la_norm_as_float(_ vector: la_object_t, _ vector_norm: la_norm_t) -> Float { return 0 }
@discardableResult
public func la_normalized_vector(_ vector: la_object_t, _ vector_norm: la_norm_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_outer_product(_ vector_left: la_object_t, _ vector_right: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
public func la_release(_ object: la_object_t) { }
public func la_remove_attributes(_ object: la_object_t, _ attributes: la_attribute_t) { }
@discardableResult
public func la_retain(_ object: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_scale_with_double(_ matrix: la_object_t, _ scalar: Double) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_scale_with_float(_ matrix: la_object_t, _ scalar: Float) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_solve(_ matrix_system: la_object_t, _ obj_rhs: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_splat_from_double(_ scalar_value: Double, _ attributes: la_attribute_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_splat_from_float(_ scalar_value: Float, _ attributes: la_attribute_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_splat_from_matrix_element(_ matrix: la_object_t, _ matrix_row: la_index_t, _ matrix_col: la_index_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_splat_from_vector_element(_ vector: la_object_t, _ vector_index: la_index_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_status(_ object: la_object_t) -> la_status_t { return 0 }
@discardableResult
public func la_sum(_ obj_left: la_object_t, _ obj_right: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_transpose(_ matrix: la_object_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_vector_from_matrix_col(_ matrix: la_object_t, _ matrix_col: la_count_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_vector_from_matrix_diagonal(_ matrix: la_object_t, _ matrix_diagonal: la_index_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_vector_from_matrix_row(_ matrix: la_object_t, _ matrix_row: la_count_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_vector_from_splat(_ splat: la_object_t, _ vector_length: la_count_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_vector_length(_ vector: la_object_t) -> la_count_t { return 0 }
@discardableResult
public func la_vector_slice(_ vector: la_object_t, _ vector_first: la_index_t, _ vector_stride: la_index_t, _ slice_length: la_count_t) -> la_object_t { return _OpenUIKitLAObject() }
@discardableResult
public func la_vector_to_double_buffer(_ buffer: UnsafeMutablePointer<Double>, _ buffer_stride: la_index_t, _ vector: la_object_t) -> la_status_t { return 0 }
@discardableResult
public func la_vector_to_float_buffer(_ buffer: UnsafeMutablePointer<Float>, _ buffer_stride: la_index_t, _ vector: la_object_t) -> la_status_t { return 0 }
@discardableResult
public func scasum_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Double { return 0 }
@discardableResult
public func scnrm2_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Double { return 0 }
@discardableResult
public func sdsdot_(_ n: UnsafeMutablePointer<Int32>!, _ sb: UnsafeMutablePointer<Float>!, _ sx: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ sy: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!) -> Double {
    guard let sb else { return 0 }
    return Double(sb.pointee) + sdot_(n, sx, incx, sy, incy)
}
@discardableResult
public func sgbmv_(_ trans: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ kl: UnsafeMutablePointer<Int32>!, _ ku: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ y: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func sgemm_(_ transa: UnsafeMutablePointer<CChar>!, _ transb: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Float>!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ c__: UnsafeMutablePointer<Float>!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let transa, let transb, let m, let n, let k, let alpha, let a, let lda, let b, let ldb, let beta, let c__, let ldc else { return -1 }
    return _gemm(transA: transa.pointee, transB: transb.pointee, m: Int(m.pointee), n: Int(n.pointee), k: Int(k.pointee), alpha: alpha.pointee, a: a, lda: Int(lda.pointee), b: b, ldb: Int(ldb.pointee), beta: beta.pointee, c: c__, ldc: Int(ldc.pointee))
}
@discardableResult
public func sgemv_(_ trans: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ y: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let trans, let m, let n, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _gemv(trans: trans.pointee, m: Int(m.pointee), n: Int(n.pointee), alpha: alpha.pointee, a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee), beta: beta.pointee, y: y, incy: Int(incy.pointee))
}
@discardableResult
public func sger_(_ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let m, let n, let alpha, let x, let incx, let y, let incy, let a, let lda else { return -1 }
    let rows = Int(m.pointee); let cols = Int(n.pointee); let al = alpha.pointee
    let ix = Int(incx.pointee); let iy = Int(incy.pointee); let ld = Int(lda.pointee)
    guard rows > 0, cols > 0, ld >= rows else { return 0 }
    var xi = 0
    for i in 0..<rows {
        var yj = 0
        for j in 0..<cols {
            a[i + j * ld] += al * x[xi] * y[yj]
            yj += iy
        }
        xi += ix
    }
    return 0
}
@discardableResult
public func sparse_commit(_ A: UnsafeMutableRawPointer!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_elementwise_norm_double(_ A: sparse_matrix_double!, _ norm: sparse_norm) -> Double { return 0 }
@discardableResult
public func sparse_elementwise_norm_double_complex(_ A: sparse_matrix_double_complex!, _ norm: sparse_norm) -> Double { return 0 }
@discardableResult
public func sparse_elementwise_norm_float(_ A: sparse_matrix_float!, _ norm: sparse_norm) -> Float { return 0 }
@discardableResult
public func sparse_elementwise_norm_float_complex(_ A: sparse_matrix_float_complex!, _ norm: sparse_norm) -> Float { return 0 }
@discardableResult
public func sparse_extract_block_double(_ A: sparse_matrix_double!, _ bi: sparse_index, _ bj: sparse_index, _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ val: UnsafeMutablePointer<Double>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_block_double_complex(_ A: sparse_matrix_double_complex!, _ bi: sparse_index, _ bj: sparse_index, _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ val: OpaquePointer!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_block_float(_ A: sparse_matrix_float!, _ bi: sparse_index, _ bj: sparse_index, _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ val: UnsafeMutablePointer<Float>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_block_float_complex(_ A: sparse_matrix_float_complex!, _ bi: sparse_index, _ bj: sparse_index, _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ val: OpaquePointer!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_sparse_column_double(_ A: sparse_matrix_double!, _ column: sparse_index, _ row_start: sparse_index, _ row_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension, _ val: UnsafeMutablePointer<Double>!, _ indx: UnsafeMutablePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_sparse_column_double_complex(_ A: sparse_matrix_double_complex!, _ column: sparse_index, _ row_start: sparse_index, _ row_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension, _ val: OpaquePointer!, _ indx: UnsafeMutablePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_sparse_column_float(_ A: sparse_matrix_float!, _ column: sparse_index, _ row_start: sparse_index, _ row_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension, _ val: UnsafeMutablePointer<Float>!, _ indx: UnsafeMutablePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_sparse_column_float_complex(_ A: sparse_matrix_float_complex!, _ column: sparse_index, _ row_start: sparse_index, _ row_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension, _ val: OpaquePointer!, _ indx: UnsafeMutablePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_sparse_row_double(_ A: sparse_matrix_double!, _ row: sparse_index, _ column_start: sparse_index, _ column_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension, _ val: UnsafeMutablePointer<Double>!, _ jndx: UnsafeMutablePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_sparse_row_double_complex(_ A: sparse_matrix_double_complex!, _ row: sparse_index, _ column_start: sparse_index, _ column_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension, _ val: OpaquePointer!, _ jndx: UnsafeMutablePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_sparse_row_float(_ A: sparse_matrix_float!, _ row: sparse_index, _ column_start: sparse_index, _ column_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension, _ val: UnsafeMutablePointer<Float>!, _ jndx: UnsafeMutablePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_extract_sparse_row_float_complex(_ A: sparse_matrix_float_complex!, _ row: sparse_index, _ column_start: sparse_index, _ column_end: UnsafeMutablePointer<sparse_index>!, _ nz: sparse_dimension, _ val: OpaquePointer!, _ jndx: UnsafeMutablePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_get_block_dimension_for_col(_ A: UnsafeMutableRawPointer!, _ j: sparse_index) -> Int { return 0 }
@discardableResult
public func sparse_get_block_dimension_for_row(_ A: UnsafeMutableRawPointer!, _ i: sparse_index) -> Int { return 0 }
@discardableResult
public func sparse_get_matrix_nonzero_count(_ A: UnsafeMutableRawPointer!) -> Int { return 0 }
@discardableResult
public func sparse_get_matrix_nonzero_count_for_column(_ A: UnsafeMutableRawPointer!, _ j: sparse_index) -> Int { return 0 }
@discardableResult
public func sparse_get_matrix_nonzero_count_for_row(_ A: UnsafeMutableRawPointer!, _ i: sparse_index) -> Int { return 0 }
@discardableResult
public func sparse_get_matrix_number_of_columns(_ A: UnsafeMutableRawPointer!) -> sparse_dimension { return 0 }
@discardableResult
public func sparse_get_matrix_number_of_rows(_ A: UnsafeMutableRawPointer!) -> sparse_dimension { return 0 }
@discardableResult
public func sparse_get_matrix_property(_ A: UnsafeMutableRawPointer!, _ pname: sparse_matrix_property) -> Int { return 0 }
@discardableResult
public func sparse_get_vector_nonzero_count_double(_ N: sparse_dimension, _ x: UnsafePointer<Double>!, _ incx: sparse_stride) -> Int { return 0 }
@discardableResult
public func sparse_get_vector_nonzero_count_double_complex(_ N: sparse_dimension, _ x: OpaquePointer!, _ incx: sparse_stride) -> Int { return 0 }
@discardableResult
public func sparse_get_vector_nonzero_count_float(_ N: sparse_dimension, _ x: UnsafePointer<Float>!, _ incx: sparse_stride) -> Int { return 0 }
@discardableResult
public func sparse_get_vector_nonzero_count_float_complex(_ N: sparse_dimension, _ x: OpaquePointer!, _ incx: sparse_stride) -> Int { return 0 }
@discardableResult
public func sparse_inner_product_dense_double(_ nz: sparse_dimension, _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!, _ y: UnsafePointer<Double>!, _ incy: sparse_stride) -> Double { return 0 }
@discardableResult
public func sparse_inner_product_dense_float(_ nz: sparse_dimension, _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!, _ y: UnsafePointer<Float>!, _ incy: sparse_stride) -> Float { return 0 }
@discardableResult
public func sparse_inner_product_sparse_double(_ nzx: sparse_dimension, _ nzy: sparse_dimension, _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!, _ y: UnsafePointer<Double>!, _ indy: UnsafePointer<sparse_index>!) -> Double { return 0 }
@discardableResult
public func sparse_inner_product_sparse_float(_ nzx: sparse_dimension, _ nzy: sparse_dimension, _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!, _ y: UnsafePointer<Float>!, _ indy: UnsafePointer<sparse_index>!) -> Float { return 0 }
@discardableResult
public func sparse_insert_block_double(_ A: sparse_matrix_double!, _ val: UnsafePointer<Double>!, _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ bi: sparse_index, _ bj: sparse_index) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_block_double_complex(_ A: sparse_matrix_double_complex!, _ val: OpaquePointer!, _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ bi: sparse_index, _ bj: sparse_index) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_block_float(_ A: sparse_matrix_float!, _ val: UnsafePointer<Float>!, _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ bi: sparse_index, _ bj: sparse_index) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_block_float_complex(_ A: sparse_matrix_float_complex!, _ val: OpaquePointer!, _ row_stride: sparse_dimension, _ col_stride: sparse_dimension, _ bi: sparse_index, _ bj: sparse_index) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_col_double(_ A: sparse_matrix_double!, _ j: sparse_index, _ nz: sparse_dimension, _ val: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_col_double_complex(_ A: sparse_matrix_double_complex!, _ j: sparse_index, _ nz: sparse_dimension, _ val: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_col_float(_ A: sparse_matrix_float!, _ j: sparse_index, _ nz: sparse_dimension, _ val: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_col_float_complex(_ A: sparse_matrix_float_complex!, _ j: sparse_index, _ nz: sparse_dimension, _ val: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_entries_double(_ A: sparse_matrix_double!, _ N: sparse_dimension, _ val: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!, _ jndx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_entries_double_complex(_ A: sparse_matrix_double_complex!, _ N: sparse_dimension, _ val: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ jndx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_entries_float(_ A: sparse_matrix_float!, _ N: sparse_dimension, _ val: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!, _ jndx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_entries_float_complex(_ A: sparse_matrix_float_complex!, _ N: sparse_dimension, _ val: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ jndx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_entry_double(_ A: sparse_matrix_double!, _ val: Double, _ i: sparse_index, _ j: sparse_index) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_entry_float(_ A: sparse_matrix_float!, _ val: Float, _ i: sparse_index, _ j: sparse_index) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_row_double(_ A: sparse_matrix_double!, _ i: sparse_index, _ nz: sparse_dimension, _ val: UnsafePointer<Double>!, _ jndx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_row_double_complex(_ A: sparse_matrix_double_complex!, _ i: sparse_index, _ nz: sparse_dimension, _ val: OpaquePointer!, _ jndx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_row_float(_ A: sparse_matrix_float!, _ i: sparse_index, _ nz: sparse_dimension, _ val: UnsafePointer<Float>!, _ jndx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_insert_row_float_complex(_ A: sparse_matrix_float_complex!, _ i: sparse_index, _ nz: sparse_dimension, _ val: OpaquePointer!, _ jndx: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_block_create_double(_ Mb: sparse_dimension, _ Nb: sparse_dimension, _ k: sparse_dimension, _ l: sparse_dimension) -> sparse_matrix_double! { return nil }
@discardableResult
public func sparse_matrix_block_create_double_complex(_ Mb: sparse_dimension, _ Nb: sparse_dimension, _ k: sparse_dimension, _ l: sparse_dimension) -> sparse_matrix_double_complex! { return nil }
@discardableResult
public func sparse_matrix_block_create_float(_ Mb: sparse_dimension, _ Nb: sparse_dimension, _ k: sparse_dimension, _ l: sparse_dimension) -> sparse_matrix_float! { return nil }
@discardableResult
public func sparse_matrix_block_create_float_complex(_ Mb: sparse_dimension, _ Nb: sparse_dimension, _ k: sparse_dimension, _ l: sparse_dimension) -> sparse_matrix_float_complex! { return nil }
@discardableResult
public func sparse_matrix_create_double(_ M: sparse_dimension, _ N: sparse_dimension) -> sparse_matrix_double! { return nil }
@discardableResult
public func sparse_matrix_create_double_complex(_ M: sparse_dimension, _ N: sparse_dimension) -> sparse_matrix_double_complex! { return nil }
@discardableResult
public func sparse_matrix_create_float(_ M: sparse_dimension, _ N: sparse_dimension) -> sparse_matrix_float! { return nil }
@discardableResult
public func sparse_matrix_create_float_complex(_ M: sparse_dimension, _ N: sparse_dimension) -> sparse_matrix_float_complex! { return nil }
@discardableResult
public func sparse_matrix_destroy(_ A: UnsafeMutableRawPointer!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_product_dense_double(_ order: CBLAS_ORDER, _ transa: CBLAS_TRANSPOSE, _ n: sparse_dimension, _ alpha: Double, _ A: sparse_matrix_double!, _ B: UnsafePointer<Double>!, _ ldb: sparse_dimension, _ C: UnsafeMutablePointer<Double>!, _ ldc: sparse_dimension) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_product_dense_float(_ order: CBLAS_ORDER, _ transa: CBLAS_TRANSPOSE, _ n: sparse_dimension, _ alpha: Float, _ A: sparse_matrix_float!, _ B: UnsafePointer<Float>!, _ ldb: sparse_dimension, _ C: UnsafeMutablePointer<Float>!, _ ldc: sparse_dimension) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_product_sparse_double(_ order: CBLAS_ORDER, _ transa: CBLAS_TRANSPOSE, _ alpha: Double, _ A: sparse_matrix_double!, _ B: sparse_matrix_double!, _ C: UnsafeMutablePointer<Double>!, _ ldc: sparse_dimension) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_product_sparse_float(_ order: CBLAS_ORDER, _ transa: CBLAS_TRANSPOSE, _ alpha: Float, _ A: sparse_matrix_float!, _ B: sparse_matrix_float!, _ C: UnsafeMutablePointer<Float>!, _ ldc: sparse_dimension) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_trace_double(_ A: sparse_matrix_double!, _ offset: sparse_index) -> Double { return 0 }
@discardableResult
public func sparse_matrix_trace_float(_ A: sparse_matrix_float!, _ offset: sparse_index) -> Float { return 0 }
@discardableResult
public func sparse_matrix_triangular_solve_dense_double(_ order: CBLAS_ORDER, _ transt: CBLAS_TRANSPOSE, _ nrhs: sparse_dimension, _ alpha: Double, _ T: sparse_matrix_double!, _ B: UnsafeMutablePointer<Double>!, _ ldb: sparse_dimension) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_triangular_solve_dense_float(_ order: CBLAS_ORDER, _ transt: CBLAS_TRANSPOSE, _ nrhs: sparse_dimension, _ alpha: Float, _ T: sparse_matrix_float!, _ B: UnsafeMutablePointer<Float>!, _ ldb: sparse_dimension) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_variable_block_create_double(_ Mb: sparse_dimension, _ Nb: sparse_dimension, _ K: UnsafePointer<sparse_dimension>!, _ L: UnsafePointer<sparse_dimension>!) -> sparse_matrix_double! { return nil }
@discardableResult
public func sparse_matrix_variable_block_create_double_complex(_ Mb: sparse_dimension, _ Nb: sparse_dimension, _ K: UnsafePointer<sparse_dimension>!, _ L: UnsafePointer<sparse_dimension>!) -> sparse_matrix_double_complex! { return nil }
@discardableResult
public func sparse_matrix_variable_block_create_float(_ Mb: sparse_dimension, _ Nb: sparse_dimension, _ K: UnsafePointer<sparse_dimension>!, _ L: UnsafePointer<sparse_dimension>!) -> sparse_matrix_float! { return nil }
@discardableResult
public func sparse_matrix_variable_block_create_float_complex(_ Mb: sparse_dimension, _ Nb: sparse_dimension, _ K: UnsafePointer<sparse_dimension>!, _ L: UnsafePointer<sparse_dimension>!) -> sparse_matrix_float_complex! { return nil }
@discardableResult
public func sparse_matrix_vector_product_dense_double(_ transa: CBLAS_TRANSPOSE, _ alpha: Double, _ A: sparse_matrix_double!, _ x: UnsafePointer<Double>!, _ incx: sparse_stride, _ y: UnsafeMutablePointer<Double>!, _ incy: sparse_stride) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_matrix_vector_product_dense_float(_ transa: CBLAS_TRANSPOSE, _ alpha: Float, _ A: sparse_matrix_float!, _ x: UnsafePointer<Float>!, _ incx: sparse_stride, _ y: UnsafeMutablePointer<Float>!, _ incy: sparse_stride) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_operator_norm_double(_ A: sparse_matrix_double!, _ norm: sparse_norm) -> Double { return 0 }
@discardableResult
public func sparse_operator_norm_double_complex(_ A: sparse_matrix_double_complex!, _ norm: sparse_norm) -> Double { return 0 }
@discardableResult
public func sparse_operator_norm_float(_ A: sparse_matrix_float!, _ norm: sparse_norm) -> Float { return 0 }
@discardableResult
public func sparse_operator_norm_float_complex(_ A: sparse_matrix_float_complex!, _ norm: sparse_norm) -> Float { return 0 }
@discardableResult
public func sparse_outer_product_dense_double(_ M: sparse_dimension, _ N: sparse_dimension, _ nz: sparse_dimension, _ alpha: Double, _ x: UnsafePointer<Double>!, _ incx: sparse_stride, _ y: UnsafePointer<Double>!, _ indy: UnsafePointer<sparse_index>!, _ C: UnsafeMutablePointer<sparse_matrix_double?>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_outer_product_dense_float(_ M: sparse_dimension, _ N: sparse_dimension, _ nz: sparse_dimension, _ alpha: Float, _ x: UnsafePointer<Float>!, _ incx: sparse_stride, _ y: UnsafePointer<Float>!, _ indy: UnsafePointer<sparse_index>!, _ C: UnsafeMutablePointer<sparse_matrix_float?>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_pack_vector_double(_ N: sparse_dimension, _ nz: sparse_dimension, _ x: UnsafePointer<Double>!, _ incx: sparse_stride, _ y: UnsafeMutablePointer<Double>!, _ indy: UnsafeMutablePointer<sparse_index>!) -> Int { return 0 }
@discardableResult
public func sparse_pack_vector_double_complex(_ N: sparse_dimension, _ nz: sparse_dimension, _ x: OpaquePointer!, _ incx: sparse_stride, _ y: OpaquePointer!, _ indy: UnsafeMutablePointer<sparse_index>!) -> Int { return 0 }
@discardableResult
public func sparse_pack_vector_float(_ N: sparse_dimension, _ nz: sparse_dimension, _ x: UnsafePointer<Float>!, _ incx: sparse_stride, _ y: UnsafeMutablePointer<Float>!, _ indy: UnsafeMutablePointer<sparse_index>!) -> Int { return 0 }
@discardableResult
public func sparse_pack_vector_float_complex(_ N: sparse_dimension, _ nz: sparse_dimension, _ x: OpaquePointer!, _ incx: sparse_stride, _ y: OpaquePointer!, _ indy: UnsafeMutablePointer<sparse_index>!) -> Int { return 0 }
@discardableResult
public func sparse_permute_cols_double(_ A: sparse_matrix_double!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_permute_cols_double_complex(_ A: sparse_matrix_double_complex!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_permute_cols_float(_ A: sparse_matrix_float!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_permute_cols_float_complex(_ A: sparse_matrix_float_complex!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_permute_rows_double(_ A: sparse_matrix_double!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_permute_rows_double_complex(_ A: sparse_matrix_double_complex!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_permute_rows_float(_ A: sparse_matrix_float!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_permute_rows_float_complex(_ A: sparse_matrix_float_complex!, _ perm: UnsafePointer<sparse_index>!) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_set_matrix_property(_ A: UnsafeMutableRawPointer!, _ pname: sparse_matrix_property) -> sparse_status { return sparse_status(rawValue: 0) }
public func sparse_unpack_vector_double(_ N: sparse_dimension, _ nz: sparse_dimension, _ zero: Bool, _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!, _ y: UnsafeMutablePointer<Double>!, _ incy: sparse_stride) { }
public func sparse_unpack_vector_double_complex(_ N: sparse_dimension, _ nz: sparse_dimension, _ zero: Bool, _ x: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ y: OpaquePointer!, _ incy: sparse_stride) { }
public func sparse_unpack_vector_float(_ N: sparse_dimension, _ nz: sparse_dimension, _ zero: Bool, _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!, _ y: UnsafeMutablePointer<Float>!, _ incy: sparse_stride) { }
public func sparse_unpack_vector_float_complex(_ N: sparse_dimension, _ nz: sparse_dimension, _ zero: Bool, _ x: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ y: OpaquePointer!, _ incy: sparse_stride) { }
public func sparse_vector_add_with_scale_dense_double(_ nz: sparse_dimension, _ alpha: Double, _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!, _ y: UnsafeMutablePointer<Double>!, _ incy: sparse_stride) { }
public func sparse_vector_add_with_scale_dense_float(_ nz: sparse_dimension, _ alpha: Float, _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!, _ y: UnsafeMutablePointer<Float>!, _ incy: sparse_stride) { }
@discardableResult
public func sparse_vector_norm_double(_ nz: sparse_dimension, _ x: UnsafePointer<Double>!, _ indx: UnsafePointer<sparse_index>!, _ norm: sparse_norm) -> Double { return 0 }
@discardableResult
public func sparse_vector_norm_double_complex(_ nz: sparse_dimension, _ x: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ norm: sparse_norm) -> Double { return 0 }
@discardableResult
public func sparse_vector_norm_float(_ nz: sparse_dimension, _ x: UnsafePointer<Float>!, _ indx: UnsafePointer<sparse_index>!, _ norm: sparse_norm) -> Float { return 0 }
@discardableResult
public func sparse_vector_norm_float_complex(_ nz: sparse_dimension, _ x: OpaquePointer!, _ indx: UnsafePointer<sparse_index>!, _ norm: sparse_norm) -> Float { return 0 }
@discardableResult
public func sparse_vector_triangular_solve_dense_double(_ transt: CBLAS_TRANSPOSE, _ alpha: Double, _ T: sparse_matrix_double!, _ x: UnsafeMutablePointer<Double>!, _ incx: sparse_stride) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func sparse_vector_triangular_solve_dense_float(_ transt: CBLAS_TRANSPOSE, _ alpha: Float, _ T: sparse_matrix_float!, _ x: UnsafeMutablePointer<Float>!, _ incx: sparse_stride) -> sparse_status { return sparse_status(rawValue: 0) }
@discardableResult
public func srot_(_ n: UnsafeMutablePointer<Int32>!, _ sx: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ sy: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!, _ c: UnsafeMutablePointer<Float>!, _ s: UnsafeMutablePointer<Float>!) -> Int32 {
    guard let n, let sx, let incx, let sy, let incy, let c, let s else { return -1 }
    return _rot(n: Int(n.pointee), x: sx, incx: Int(incx.pointee), y: sy, incy: Int(incy.pointee), c: c.pointee, s: s.pointee)
}
@discardableResult
public func srotg_(_ sa: UnsafeMutablePointer<Float>!, _ sb: UnsafeMutablePointer<Float>!, _ c: UnsafeMutablePointer<Float>!, _ s: UnsafeMutablePointer<Float>!) -> Int32 {
    guard let sa, let sb, let c, let s else { return -1 }
    return _rotg(a: &sa.pointee, b: &sb.pointee, c: &c.pointee, s: &s.pointee)
}
@discardableResult
public func srotm_(_ n: UnsafeMutablePointer<Int32>!, _ sx: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ sy: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!, _ param: UnsafeMutablePointer<Float>!) -> Int32 { return 0 }
@discardableResult
public func srotmg_(_ sd1: UnsafeMutablePointer<Float>!, _ sd2: UnsafeMutablePointer<Float>!, _ sx1: UnsafeMutablePointer<Float>!, _ sy1: UnsafeMutablePointer<Float>!, _ param: UnsafeMutablePointer<Float>!) -> Int32 { return 0 }
@discardableResult
public func ssbmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ y: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func sspmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ ap: UnsafeMutablePointer<Float>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ y: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func sspr2_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutablePointer<Float>!) -> Int32 { return 0 }
@discardableResult
public func sspr_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutablePointer<Float>!) -> Int32 { return 0 }
@discardableResult
public func ssymm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Float>!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ c__: UnsafeMutablePointer<Float>!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ssymv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ y: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let n, let alpha, let a, let lda, let x, let incx, let beta, let y, let incy else { return -1 }
    return _symv(uplo: uplo.pointee, n: Int(n.pointee), alpha: alpha.pointee, a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee), beta: beta.pointee, y: y, incy: Int(incy.pointee))
}
@discardableResult
public func ssyr2_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutablePointer<Float>!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ssyr2k_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Float>!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ c__: UnsafeMutablePointer<Float>!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ssyr_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let n, let alpha, let x, let incx, let a, let lda else { return -1 }
    return _syr(uplo: uplo.pointee, n: Int(n.pointee), alpha: alpha.pointee, x: x, incx: Int(incx.pointee), a: a, lda: Int(lda.pointee))
}
@discardableResult
public func ssyrk_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Float>!, _ c__: UnsafeMutablePointer<Float>!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let trans, let n, let k, let alpha, let a, let lda, let beta, let c__, let ldc else { return -1 }
    return _syrk(uplo: uplo.pointee, trans: trans.pointee, n: Int(n.pointee), k: Int(k.pointee), alpha: alpha.pointee, a: a, lda: Int(lda.pointee), beta: beta.pointee, c: c__, ldc: Int(ldc.pointee))
}
@discardableResult
public func stbmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func stbsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func stpmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutablePointer<Float>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func stpsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutablePointer<Float>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func strmm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ transa: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Float>!, _ ldb: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func strmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let trans, let diag, let n, let a, let lda, let x, let incx else { return -1 }
    return _trmv(uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee))
}
@discardableResult
public func strsm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ transa: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Float>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutablePointer<Float>!, _ ldb: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func strsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutablePointer<Float>!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutablePointer<Float>!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 {
    guard let uplo, let trans, let diag, let n, let a, let lda, let x, let incx else { return -1 }
    return _trsv(uplo: uplo.pointee, trans: trans.pointee, diag: diag.pointee, n: Int(n.pointee), a: a, lda: Int(lda.pointee), x: x, incx: Int(incx.pointee))
}
@discardableResult
public func vDSP_DFT_Interleaved_CreateSetup(_ Previous: vDSP_DFT_Interleaved_Setup?, _ Length: vDSP_Length, _ Direction: vDSP_DFT_Direction, _ RealtoComplex: vDSP_DFT_RealtoComplex) -> vDSP_DFT_Interleaved_Setup? {
    _ = Previous; _ = Direction
    guard RealtoComplex == .interleaved_ComplextoComplex else { return nil }
    let n = Int(Length)
    guard n > 0, n & (n - 1) == 0, let box = _FFTSetupBox(log2n: n.trailingZeroBitCount) else { return nil }
    return _fftRetain(box)
}
@discardableResult
public func vDSP_DFT_Interleaved_CreateSetupD(_ Previous: vDSP_DFT_Interleaved_SetupD?, _ Length: vDSP_Length, _ Direction: vDSP_DFT_Direction, _ RealtoComplex: vDSP_DFT_RealtoComplex) -> vDSP_DFT_Interleaved_SetupD? {
    _ = Previous; _ = Direction
    guard RealtoComplex == .interleaved_ComplextoComplex else { return nil }
    let n = Int(Length)
    guard n > 0, n & (n - 1) == 0, let box = _FFTSetupBox(log2n: n.trailingZeroBitCount) else { return nil }
    return _fftRetain(box)
}
public func vDSP_DFT_Interleaved_DestroySetup(_ Setup: vDSP_DFT_Interleaved_Setup?) { _fftRelease(Setup) }
public func vDSP_DFT_Interleaved_DestroySetupD(_ Setup: vDSP_DFT_Interleaved_SetupD?) { _fftRelease(Setup) }
public func vDSP_DFT_Interleaved_Execute(_ Setup: vDSP_DFT_Interleaved_Setup, _ Iri: UnsafePointer<DSPComplex>, _ Ori: UnsafeMutablePointer<DSPComplex>) {
    guard let box = _fftBox(Setup) else { return }
    let n = box.n
    var real = [Float](repeating: 0, count: n)
    var imag = [Float](repeating: 0, count: n)
    for i in 0..<n { real[i] = Iri[i].real; imag[i] = Iri[i].imag }
    real.withUnsafeMutableBufferPointer { rp in
        imag.withUnsafeMutableBufferPointer { ip in
            _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: false)
        }
    }
    for i in 0..<n { Ori[i] = DSPComplex(real: real[i], imag: imag[i]) }
}
public func vDSP_DFT_Interleaved_ExecuteD(_ Setup: vDSP_DFT_Interleaved_SetupD, _ Iri: UnsafePointer<DSPDoubleComplex>, _ Ori: UnsafeMutablePointer<DSPDoubleComplex>) {
    guard let box = _fftBox(Setup) else { return }
    let n = box.n
    var real = [Double](repeating: 0, count: n)
    var imag = [Double](repeating: 0, count: n)
    for i in 0..<n { real[i] = Iri[i].real; imag[i] = Iri[i].imag }
    real.withUnsafeMutableBufferPointer { rp in
        imag.withUnsafeMutableBufferPointer { ip in
            _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: false)
        }
    }
    for i in 0..<n { Ori[i] = DSPDoubleComplex(real: real[i], imag: imag[i]) }
}
@discardableResult
public func vImageAffineWarpD_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarpD_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarpD_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarpD_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error {
    _ = tempBuffer
    return _vImageAffineWarpU8(src, dest, transform: _vImageAffineFromDouble(transform.pointee), backColor: backColor, bytesPerPixel: 4, flags: flags)
}
@discardableResult
public func vImageAffineWarpD_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarpD_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarpD_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarpD_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error {
    _ = tempBuffer
    var color = backColor
    return _vImageAffineWarpU8(src, dest, transform: _vImageAffineFromDouble(transform.pointee), backColor: &color, bytesPerPixel: 1, flags: flags)
}
@discardableResult
public func vImageAffineWarpD_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform_Double>, _ backColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarp_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarp_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarp_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarp_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error {
    _ = tempBuffer
    return _vImageAffineWarpU8(src, dest, transform: transform.pointee, backColor: backColor, bytesPerPixel: 4, flags: flags)
}
@discardableResult
public func vImageAffineWarp_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarp_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarp_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAffineWarp_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error {
    _ = tempBuffer
    var color = backColor
    return _vImageAffineWarpU8(src, dest, transform: transform.pointee, backColor: &color, bytesPerPixel: 1, flags: flags)
}
@discardableResult
public func vImageAffineWarp_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAlphaBlend_ARGB8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageAlphaBlendARGB8888(srcTop, srcBottom, dest, flags: flags) }
@discardableResult
public func vImageAlphaBlend_ARGBFFFF(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAlphaBlend_NonpremultipliedToPremultiplied_ARGB8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAlphaBlend_NonpremultipliedToPremultiplied_ARGBFFFF(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAlphaBlend_NonpremultipliedToPremultiplied_Planar8(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcTopAlpha: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAlphaBlend_NonpremultipliedToPremultiplied_PlanarF(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcTopAlpha: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAlphaBlend_Planar8(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcTopAlpha: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ srcBottomAlpha: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageAlphaBlend_PlanarF(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcTopAlpha: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ srcBottomAlpha: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageBoxConvolve_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: UInt32, _ kernel_width: UInt32, _ backgroundColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; _ = srcOffsetToROI_X; _ = srcOffsetToROI_Y; _ = backgroundColor; return _vImageBoxConvolvePlanar8(src, dest, kernelWidth: kernel_width, kernelHeight: kernel_height, flags: flags) }
@discardableResult
public func vImageBufferFill_ARGB16F(_ dest: UnsafePointer<vImage_Buffer>, _ color: UnsafePointer<UInt16>, _ flags: vImage_Flags) -> vImage_Error { return _vImageFill(dest, color: UnsafeRawPointer(color), bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageBufferFill_ARGB16S(_ dest: UnsafePointer<vImage_Buffer>, _ color: UnsafePointer<Int16>, _ flags: vImage_Flags) -> vImage_Error { return _vImageFill(dest, color: UnsafeRawPointer(color), bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageBufferFill_ARGB16U(_ dest: UnsafePointer<vImage_Buffer>, _ color: UnsafePointer<UInt16>, _ flags: vImage_Flags) -> vImage_Error { return _vImageFill(dest, color: UnsafeRawPointer(color), bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageBufferFill_ARGB8888(_ dest: UnsafePointer<vImage_Buffer>, _ color: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return _vImageFill(dest, color: UnsafeRawPointer(color), bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageBufferFill_ARGBFFFF(_ dest: UnsafePointer<vImage_Buffer>, _ color: UnsafePointer<Float>, _ flags: vImage_Flags) -> vImage_Error { return _vImageFill(dest, color: UnsafeRawPointer(color), bytesPerPixel: 16, flags: flags) }
@discardableResult
public func vImageBufferFill_CbCr16S(_ dest: UnsafePointer<vImage_Buffer>, _ color: UnsafePointer<Int16>, _ flags: vImage_Flags) -> vImage_Error { return _vImageFill(dest, color: UnsafeRawPointer(color), bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageBufferFill_CbCr16U(_ dest: UnsafePointer<vImage_Buffer>, _ color: UnsafePointer<UInt16>, _ flags: vImage_Flags) -> vImage_Error { return _vImageFill(dest, color: UnsafeRawPointer(color), bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageBufferFill_CbCr8(_ dest: UnsafePointer<vImage_Buffer>, _ color: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return _vImageFill(dest, color: UnsafeRawPointer(color), bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageBuffer_GetSize(_ buf: UnsafePointer<vImage_Buffer>) -> CGSize { return CGSize(width: Double(buf.pointee.width), height: Double(buf.pointee.height)) }
@discardableResult
public func vImageBuffer_Init(_ buf: UnsafeMutablePointer<vImage_Buffer>, _ height: vImagePixelCount, _ width: vImagePixelCount, _ pixelBits: UInt32, _ flags: vImage_Flags) -> vImage_Error {
    let w = Int(width); let h = Int(height)
    guard w >= 0, h >= 0 else { return kvImageInvalidParameter }
    let rowBytes = (w * Int(pixelBits) + 7) / 8
    buf.pointee.width = width
    buf.pointee.height = height
    buf.pointee.rowBytes = rowBytes
    if flags & vImage_Flags(kvImageNoAllocate) != 0 { return kvImageNoError }
    let bytes = max(rowBytes * h, 1)
    buf.pointee.data = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: 16)
    buf.pointee.data.initializeMemory(as: UInt8.self, repeating: 0, count: bytes)
    return kvImageNoError
}
@discardableResult
public func vImageByteSwap_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error {
    _ = flags
    let check = _vImageRequireBuffers(src, dest)
    if check != kvImageNoError { return check }
    let srcLayout = _vImageValidateLayout(src.pointee, bytesPerPixel: 2)
    if srcLayout != kvImageNoError { return srcLayout }
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: 2)
    if destLayout != kvImageNoError { return destLayout }
    let w = Int(src.pointee.width); let h = Int(src.pointee.height)
    let s = src.pointee.data!.assumingMemoryBound(to: UInt16.self)
    let d = dest.pointee.data!.assumingMemoryBound(to: UInt16.self)
    for y in 0..<h {
        for x in 0..<w {
            let v = s[y * (src.pointee.rowBytes / 2) + x]
            d[y * (dest.pointee.rowBytes / 2) + x] = v.byteSwapped
        }
    }
    return kvImageNoError
}
@discardableResult
public func vImageCVImageFormat_Copy(_ format: vImageConstCVImageFormat) -> Unmanaged<vImageCVImageFormat>! { return nil }
@discardableResult
public func vImageCVImageFormat_CopyChannelDescription(_ format: vImageCVImageFormat, _ desc: UnsafePointer<vImageChannelDescription>, _ type: vImageBufferTypeCode) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageCVImageFormat_CopyConversionMatrix(_ format: vImageCVImageFormat, _ matrix: UnsafeRawPointer, _ inType: vImageMatrixType) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageCVImageFormat_GetAlphaHint(_ format: vImageConstCVImageFormat) -> Int32 { return 0 }
@discardableResult
public func vImageCVImageFormat_GetChannelCount(_ format: vImageConstCVImageFormat) -> UInt32 { return 0 }
@discardableResult
public func vImageCVImageFormat_GetChannelDescription(_ format: vImageConstCVImageFormat, _ type: vImageBufferTypeCode) -> UnsafePointer<vImageChannelDescription>! { return nil }
@discardableResult
public func vImageCVImageFormat_GetChannelNames(_ format: vImageConstCVImageFormat) -> UnsafePointer<vImageBufferTypeCode>! { return nil }
@discardableResult
public func vImageCVImageFormat_GetConversionMatrix(_ format: vImageConstCVImageFormat, _ outType: UnsafeMutablePointer<vImageMatrixType>!) -> UnsafeRawPointer! { return nil }
@discardableResult
public func vImageCVImageFormat_GetFormatCode(_ format: vImageConstCVImageFormat) -> UInt32 { return 0 }
@discardableResult
public func vImageCVImageFormat_GetUserData(_ format: vImageConstCVImageFormat) -> UnsafeMutableRawPointer! { return nil }
@discardableResult
public func vImageCVImageFormat_SetAlphaHint(_ format: vImageCVImageFormat, _ alphaIsOne: Int32) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageCVImageFormat_SetUserData(_ format: vImageCVImageFormat, _ userData: UnsafeMutableRawPointer!, _ userDataReleaseCallback: ((vImageCVImageFormat?, UnsafeMutableRawPointer?) -> Void)!) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageClipToAlpha_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageClipToAlpha_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageClipToAlpha_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageClipToAlpha_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageClipToAlpha_RGBA8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageClipToAlpha_RGBAFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageClip_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: Pixel_F, _ minFloat: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageContrastStretch_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageContrastStretch_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageContrastStretch_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageContrastStretch_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_12UTo16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16Fto16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16Fto16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16Q12to16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16Q12to16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16Q12to8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16Q12toF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16SToF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ offset: Float, _ scale: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16UTo12U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16UToF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ offset: Float, _ scale: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16UToPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16Uto16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_16Uto16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(_ srcYp: UnsafePointer<vImage_Buffer>, _ srcCb: UnsafePointer<vImage_Buffer>, _ srcCr: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_420Yp8_CbCr8ToARGB8888(_ srcYp: UnsafePointer<vImage_Buffer>, _ srcCbCr: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_422CbYpCrYp16ToARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt16, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_422CbYpCrYp16ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_422CbYpCrYp8ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_422CbYpCrYp8_AA8ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ srcA: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_422CrYpCbYpCbYpCbYpCrYpCrYp10ToARGB16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: Pixel_16Q12, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_422CrYpCbYpCbYpCbYpCrYpCrYp10ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_422YpCbYpCr8ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_444AYpCbCr16ToARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_444AYpCbCr16ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_444AYpCbCr8ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_444CbYpCrA8ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_444CrYpCb10ToARGB16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: Pixel_16Q12, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_444CrYpCb10ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_444CrYpCb8ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_YpCbCrToARGB>, _ permuteMap: UnsafePointer<UInt8>!, _ alpha: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_8to16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB1555toARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB1555toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ destA: UnsafePointer<vImage_Buffer>, _ destR: UnsafePointer<vImage_Buffer>, _ destG: UnsafePointer<vImage_Buffer>, _ destB: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB1555toRGB565(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16Q12To422CrYpCbYpCbYpCbYpCrYpCrYp10(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16Q12To444CrYpCb10(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16Q12ToARGB2101010(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ RGB101010Min: Int32, _ RGB101010Max: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16Q12ToRGBA1010102(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ RGB101010Min: Int32, _ RGB101010Max: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16Q12ToXRGB2101010(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ RGB101010Min: Int32, _ RGB101010Max: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UTo422CbYpCrYp16(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UTo444AYpCbCr16(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UToARGB2101010(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ copyMask: UInt8, _ backgroundColor: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UToRGBA1010102(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UToXRGB2101010(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UtoARGB8888_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ dither: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UtoPlanar16U(_ argbSrc: UnsafePointer<vImage_Buffer>, _ aDest: UnsafePointer<vImage_Buffer>, _ rDest: UnsafePointer<vImage_Buffer>, _ gDest: UnsafePointer<vImage_Buffer>, _ bDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB16UtoRGB16U(_ argbSrc: UnsafePointer<vImage_Buffer>, _ rgbDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB2101010ToARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB2101010ToARGB16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB2101010ToARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB2101010ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB2101010ToARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To420Yp8_Cb8_Cr8(_ src: UnsafePointer<vImage_Buffer>, _ destYp: UnsafePointer<vImage_Buffer>, _ destCb: UnsafePointer<vImage_Buffer>, _ destCr: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To420Yp8_CbCr8(_ src: UnsafePointer<vImage_Buffer>, _ destYp: UnsafePointer<vImage_Buffer>, _ destCbCr: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To422CbYpCrYp16(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To422CbYpCrYp8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To422CbYpCrYp8_AA8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ destA: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To422CrYpCbYpCbYpCbYpCrYpCrYp10(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To422YpCbYpCr8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To444AYpCbCr16(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To444AYpCbCr8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To444CbYpCrA8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To444CrYpCb10(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888To444CrYpCb8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ info: UnsafePointer<vImage_ARGBToYpCbCr>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888ToARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ copyMask: UInt8, _ backgroundColor: UnsafePointer<UInt16>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888ToARGB2101010(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888ToRGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ copyMask: UInt8, _ backgroundColor: UnsafePointer<Pixel_16U>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888ToRGBA1010102(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888ToXRGB2101010(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888toARGB1555(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888toARGB1555_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888toPlanar16Q12(_ src: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888toPlanar8(_ srcARGB: UnsafePointer<vImage_Buffer>, _ destA: UnsafePointer<vImage_Buffer>, _ destR: UnsafePointer<vImage_Buffer>, _ destG: UnsafePointer<vImage_Buffer>, _ destB: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageConvertARGB8888toPlanar8(srcARGB, destA, destR, destG, destB, flags: flags) }
@discardableResult
public func vImageConvert_ARGB8888toPlanarF(_ src: UnsafePointer<vImage_Buffer>!, _ alpha: UnsafePointer<vImage_Buffer>!, _ red: UnsafePointer<vImage_Buffer>!, _ green: UnsafePointer<vImage_Buffer>!, _ blue: UnsafePointer<vImage_Buffer>!, _ maxFloat: UnsafePointer<Float>!, _ minFloat: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888toRGB565(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888toRGB565_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGB8888toRGB888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGBFFFFToARGB2101010(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGBFFFFToXRGB2101010(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGBFFFFtoARGB8888_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: UnsafePointer<Float>, _ minFloat: UnsafePointer<Float>, _ dither: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGBFFFFtoPlanar8(_ src: UnsafePointer<vImage_Buffer>!, _ alpha: UnsafePointer<vImage_Buffer>!, _ red: UnsafePointer<vImage_Buffer>!, _ green: UnsafePointer<vImage_Buffer>!, _ blue: UnsafePointer<vImage_Buffer>!, _ maxFloat: UnsafePointer<Float>!, _ minFloat: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGBFFFFtoPlanarF(_ srcARGB: UnsafePointer<vImage_Buffer>, _ destA: UnsafePointer<vImage_Buffer>, _ destR: UnsafePointer<vImage_Buffer>, _ destG: UnsafePointer<vImage_Buffer>, _ destB: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGBFFFFtoRGBFFF(_ src: UnsafePointer<vImage_Buffer>!, _ dest: UnsafePointer<vImage_Buffer>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ARGBToYpCbCr_GenerateConversion(_ matrix: UnsafePointer<vImage_ARGBToYpCbCrMatrix>, _ pixelRange: UnsafePointer<vImage_YpCbCrPixelRange>, _ outInfo: UnsafeMutablePointer<vImage_ARGBToYpCbCr>, _ inARGBType: vImageARGBType, _ outYpCbCrType: vImageYpCbCrType, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_AnyToAny(_ converter: vImageConverter, _ srcs: UnsafePointer<vImage_Buffer>, _ dests: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_BGRA16UtoRGB16U(_ bgraSrc: UnsafePointer<vImage_Buffer>, _ rgbDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_BGRA8888toRGB565(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_BGRA8888toRGB565_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_BGRA8888toRGB888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_BGRAFFFFtoRGBFFF(_ src: UnsafePointer<vImage_Buffer>!, _ dest: UnsafePointer<vImage_Buffer>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_BGRX8888ToPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_BGRXFFFFToPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ChunkyToPlanar8(_ srcChannels: UnsafeMutablePointer<UnsafeRawPointer?>, _ destPlanarBuffers: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ channelCount: UInt32, _ srcStrideBytes: Int, _ srcWidth: vImagePixelCount, _ srcHeight: vImagePixelCount, _ srcRowBytes: Int, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_ChunkyToPlanarF(_ srcChannels: UnsafeMutablePointer<UnsafeRawPointer?>, _ destPlanarBuffers: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ channelCount: UInt32, _ srcStrideBytes: Int, _ srcWidth: vImagePixelCount, _ srcHeight: vImagePixelCount, _ srcRowBytes: Int, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_FTo16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ offset: Float, _ scale: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_FTo16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ offset: Float, _ scale: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Fto16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Indexed1toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ colors: UnsafePointer<Pixel_8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Indexed2toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ colors: UnsafePointer<Pixel_8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Indexed4toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ colors: UnsafePointer<Pixel_8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16FtoPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16FtoPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16Q12toARGB16F(_ alpha: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16Q12toARGB8888(_ alpha: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16Q12toRGB16F(_ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16Q12toRGB888(_ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16UtoARGB16U(_ aSrc: UnsafePointer<vImage_Buffer>, _ rSrc: UnsafePointer<vImage_Buffer>, _ gSrc: UnsafePointer<vImage_Buffer>, _ bSrc: UnsafePointer<vImage_Buffer>, _ argbDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16UtoPlanar8_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar16UtoRGB16U(_ rSrc: UnsafePointer<vImage_Buffer>, _ gSrc: UnsafePointer<vImage_Buffer>, _ bSrc: UnsafePointer<vImage_Buffer>, _ rgbDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar1toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar2toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar4toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8To16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8ToARGBFFFF(_ alpha: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: UnsafePointer<Float>!, _ minFloat: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8ToBGRX8888(_ blue: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ alpha: Pixel_8, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8ToBGRXFFFF(_ blue: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ alpha: Pixel_F, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: UnsafePointer<Float>!, _ minFloat: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8ToXRGB8888(_ alpha: Pixel_8, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8ToXRGBFFFF(_ alpha: Pixel_F, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: UnsafePointer<Float>!, _ minFloat: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toARGB1555(_ srcA: UnsafePointer<vImage_Buffer>, _ srcR: UnsafePointer<vImage_Buffer>, _ srcG: UnsafePointer<vImage_Buffer>, _ srcB: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toARGB8888(_ srcA: UnsafePointer<vImage_Buffer>, _ srcR: UnsafePointer<vImage_Buffer>, _ srcG: UnsafePointer<vImage_Buffer>, _ srcB: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageConvertPlanar8toARGB8888(srcA, srcR, srcG, srcB, dest, flags: flags) }
@discardableResult
public func vImageConvert_Planar8toIndexed1(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ colors: UnsafeMutablePointer<Pixel_8>, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toIndexed2(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ colors: UnsafeMutablePointer<Pixel_8>, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toIndexed4(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ colors: UnsafeMutablePointer<Pixel_8>, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toPlanar1(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toPlanar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toPlanar2(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toPlanar4(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: Pixel_F, _ minFloat: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return _vImageConvertPlanar8toPlanarF(src, dest, maxFloat: maxFloat, minFloat: minFloat, flags: flags) }
@discardableResult
public func vImageConvert_Planar8toRGB565(_ srcR: UnsafePointer<vImage_Buffer>, _ srcG: UnsafePointer<vImage_Buffer>, _ srcB: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_Planar8toRGB888(_ planarRed: UnsafePointer<vImage_Buffer>, _ planarGreen: UnsafePointer<vImage_Buffer>, _ planarBlue: UnsafePointer<vImage_Buffer>, _ rgbDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFToARGB8888(_ alpha: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: UnsafePointer<Float>, _ minFloat: UnsafePointer<Float>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFToBGRX8888(_ blue: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ alpha: Pixel_8, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: UnsafePointer<Float>, _ minFloat: UnsafePointer<Float>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFToBGRXFFFF(_ blue: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ alpha: Pixel_F, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFToXRGB8888(_ alpha: Pixel_8, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: UnsafePointer<Float>, _ minFloat: UnsafePointer<Float>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFToXRGBFFFF(_ alpha: Pixel_F, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFtoARGBFFFF(_ srcA: UnsafePointer<vImage_Buffer>, _ srcR: UnsafePointer<vImage_Buffer>, _ srcG: UnsafePointer<vImage_Buffer>, _ srcB: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFtoPlanar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFtoPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: Pixel_F, _ minFloat: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return _vImageConvertPlanarFtoPlanar8(src, dest, maxFloat: maxFloat, minFloat: minFloat, flags: flags) }
@discardableResult
public func vImageConvert_PlanarFtoPlanar8_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: Pixel_F, _ minFloat: Pixel_F, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarFtoRGBFFF(_ planarRed: UnsafePointer<vImage_Buffer>, _ planarGreen: UnsafePointer<vImage_Buffer>, _ planarBlue: UnsafePointer<vImage_Buffer>, _ rgbDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarToChunky8(_ srcPlanarBuffers: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ destChannels: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ channelCount: UInt32, _ destStrideBytes: Int, _ destWidth: vImagePixelCount, _ destHeight: vImagePixelCount, _ destRowBytes: Int, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_PlanarToChunkyF(_ srcPlanarBuffers: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ destChannels: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ channelCount: UInt32, _ destStrideBytes: Int, _ destWidth: vImagePixelCount, _ destHeight: vImagePixelCount, _ destRowBytes: Int, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB16UToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ copyMask: UInt8, _ backgroundColor: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB16UtoARGB16U(_ rgbSrc: UnsafePointer<vImage_Buffer>, _ aSrc: UnsafePointer<vImage_Buffer>!, _ alpha: Pixel_16U, _ argbDest: UnsafePointer<vImage_Buffer>, _ premultiply: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB16UtoBGRA16U(_ rgbSrc: UnsafePointer<vImage_Buffer>, _ aSrc: UnsafePointer<vImage_Buffer>!, _ alpha: Pixel_16U, _ bgraDest: UnsafePointer<vImage_Buffer>, _ premultiply: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB16UtoPlanar16U(_ rgbSrc: UnsafePointer<vImage_Buffer>, _ rDest: UnsafePointer<vImage_Buffer>, _ gDest: UnsafePointer<vImage_Buffer>, _ bDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB16UtoRGB888_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB16UtoRGBA16U(_ rgbSrc: UnsafePointer<vImage_Buffer>, _ aSrc: UnsafePointer<vImage_Buffer>!, _ alpha: Pixel_16U, _ rgbaDest: UnsafePointer<vImage_Buffer>, _ premultiply: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB565toARGB1555(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB565toARGB8888(_ alpha: Pixel_8, _ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB565toBGRA8888(_ alpha: Pixel_8, _ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB565toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ destR: UnsafePointer<vImage_Buffer>, _ destG: UnsafePointer<vImage_Buffer>, _ destB: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB565toRGB888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB565toRGBA5551(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB565toRGBA8888(_ alpha: Pixel_8, _ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB888toARGB8888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>!, _: Pixel_8, _: UnsafePointer<vImage_Buffer>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB888toBGRA8888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>!, _: Pixel_8, _: UnsafePointer<vImage_Buffer>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB888toPlanar16Q12(_ src: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB888toPlanar8(_ rgbSrc: UnsafePointer<vImage_Buffer>, _ redDest: UnsafePointer<vImage_Buffer>, _ greenDest: UnsafePointer<vImage_Buffer>, _ blueDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB888toRGB565_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGB888toRGBA8888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>!, _: Pixel_8, _: UnsafePointer<vImage_Buffer>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA1010102ToARGB16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA1010102ToARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA1010102ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA16UtoRGB16U(_ rgbaSrc: UnsafePointer<vImage_Buffer>, _ rgbDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA5551toRGB565(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA5551toRGBA8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA8888toRGB565(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA8888toRGB565_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA8888toRGB888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA8888toRGBA5551(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBA8888toRGBA5551_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBAFFFFtoRGBFFF(_ src: UnsafePointer<vImage_Buffer>!, _ dest: UnsafePointer<vImage_Buffer>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBFFFtoARGBFFFF(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>!, _: Pixel_F, _: UnsafePointer<vImage_Buffer>, _: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBFFFtoBGRAFFFF(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>!, _: Pixel_F, _: UnsafePointer<vImage_Buffer>, _: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBFFFtoPlanarF(_ rgbSrc: UnsafePointer<vImage_Buffer>, _ redDest: UnsafePointer<vImage_Buffer>, _ greenDest: UnsafePointer<vImage_Buffer>, _ blueDest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBFFFtoRGB888_dithered(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ maxFloat: UnsafePointer<Pixel_F>, _ minFloat: UnsafePointer<Pixel_F>, _ dither: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_RGBFFFtoRGBAFFFF(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>!, _: Pixel_F, _: UnsafePointer<vImage_Buffer>, _: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_XRGB2101010ToARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ alpha: Pixel_F, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_XRGB2101010ToARGB16Q12(_ src: UnsafePointer<vImage_Buffer>, _ alpha: Pixel_16Q12, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_XRGB2101010ToARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ alpha: UInt16, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_XRGB2101010ToARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ alpha: Pixel_8, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_XRGB2101010ToARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ alpha: Pixel_F, _ dest: UnsafePointer<vImage_Buffer>, _ RGB101010RangeMin: Int32, _ RGB101010RangeMax: Int32, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_XRGB8888ToPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_XRGBFFFFToPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ red: UnsafePointer<vImage_Buffer>, _ green: UnsafePointer<vImage_Buffer>, _ blue: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvert_YpCbCrToARGB_GenerateConversion(_ matrix: UnsafePointer<vImage_YpCbCrToARGBMatrix>, _ pixelRange: UnsafePointer<vImage_YpCbCrPixelRange>, _ outInfo: UnsafeMutablePointer<vImage_YpCbCrToARGB>, _ inYpCbCrType: vImageYpCbCrType, _ outARGBType: vImageARGBType, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConverter_GetDestinationBufferOrder(_ converter: vImageConverter) -> UnsafePointer<vImageBufferTypeCode>! { return nil }
@discardableResult
public func vImageConverter_GetNumberOfDestinationBuffers(_ converter: vImageConverter) -> UInt { return 0 }
@discardableResult
public func vImageConverter_GetNumberOfSourceBuffers(_ converter: vImageConverter) -> UInt { return 0 }
@discardableResult
public func vImageConverter_GetSourceBufferOrder(_ converter: vImageConverter) -> UnsafePointer<vImageBufferTypeCode>! { return nil }
@discardableResult
public func vImageConverter_MustOperateOutOfPlace(_ converter: vImageConverter, _ srcs: UnsafePointer<vImage_Buffer>!, _ dests: UnsafePointer<vImage_Buffer>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveFloatKernel_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernelHeight: UInt32, _ kernelWidth: UInt32, _ bias: Float, _ backgroundColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveMultiKernel_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernels: UnsafeMutablePointer<UnsafePointer<Int16>?>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ divisors: UnsafePointer<Int32>!, _ biases: UnsafePointer<Int32>!, _ backgroundColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveMultiKernel_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernels: UnsafeMutablePointer<UnsafePointer<Float>?>, _ kernel_height: UInt32, _ kernel_width: UInt32, _ biases: UnsafePointer<Float>, _ backgroundColor: UnsafePointer<Float>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveWithBias_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ bias: Float, _ backgroundColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveWithBias_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Int16>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ divisor: Int32, _ bias: Int32, _ backgroundColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveWithBias_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ bias: Float, _ backgroundColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveWithBias_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ bias: Float, _ backgroundColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveWithBias_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Int16>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ divisor: Int32, _ bias: Int32, _ backgroundColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolveWithBias_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ bias: Float, _ backgroundColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolve_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ backgroundColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolve_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Int16>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ divisor: Int32, _ backgroundColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolve_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ backgroundColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolve_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ backgroundColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolve_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Int16>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ divisor: Int32, _ backgroundColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageConvolve_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ backgroundColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageCopyBuffer(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ pixelSize: Int, _ flags: vImage_Flags) -> vImage_Error { return _vImageCopyBuffer(src, dest, pixelSize: pixelSize, flags: flags) }
@discardableResult
public func vImageCreateGammaFunction(_ gamma: Float, _ gamma_type: Int32, _ flags: vImage_Flags) -> GammaFunction! { return nil }
public func vImageDestroyGammaFunction(_ f: GammaFunction!) { }
public func vImageDestroyResamplingFilter(_ filter: ResamplingFilter!) { }
@discardableResult
public func vImageDilate_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<UInt8>, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageDilate_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageDilate_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<UInt8>, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageDilate_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageEndsInContrastStretch_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ percent_low: UnsafePointer<UInt32>, _ percent_high: UnsafePointer<UInt32>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageEndsInContrastStretch_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ percent_low: UnsafePointer<UInt32>, _ percent_high: UnsafePointer<UInt32>, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageEndsInContrastStretch_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ percent_low: UInt32, _ percent_high: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageEndsInContrastStretch_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ percent_low: UInt32, _ percent_high: UInt32, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageEqualization_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageEqualization_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageEqualization_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageEqualization_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageErode_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<UInt8>, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageErode_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageErode_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<UInt8>, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageErode_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageExtractChannel_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ channelIndex: Int, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageExtractChannel_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ channelIndex: Int, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageExtractChannel_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ channelIndex: Int, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_ARGB16Q12(_ argbSrc: UnsafePointer<vImage_Buffer>, _ argbDst: UnsafePointer<vImage_Buffer>, _ argbBackgroundColorPtr: UnsafePointer<Int16>, _ isImagePremultiplied: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_ARGB16U(_ argbSrc: UnsafePointer<vImage_Buffer>, _ argbDst: UnsafePointer<vImage_Buffer>, _ argbBackgroundColorPtr: UnsafePointer<UInt16>, _ isImagePremultiplied: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_ARGB8888(_ argbSrc: UnsafePointer<vImage_Buffer>, _ argbDst: UnsafePointer<vImage_Buffer>, _ argbBackgroundColorPtr: UnsafePointer<UInt8>, _ isImagePremultiplied: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_ARGB8888ToRGB888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: UnsafePointer<UInt8>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_ARGBFFFF(_ argbSrc: UnsafePointer<vImage_Buffer>, _ argbDst: UnsafePointer<vImage_Buffer>, _ argbBackgroundColorPtr: UnsafePointer<Float>, _ isImagePremultiplied: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_ARGBFFFFToRGBFFF(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: UnsafePointer<Float>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_BGRA8888ToRGB888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: UnsafePointer<UInt8>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_BGRAFFFFToRGBFFF(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: UnsafePointer<Float>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_RGBA16Q12(_ argbSrc: UnsafePointer<vImage_Buffer>, _ argbDst: UnsafePointer<vImage_Buffer>, _ argbBackgroundColorPtr: UnsafePointer<Int16>, _ isImagePremultiplied: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_RGBA16U(_ rgbaSrc: UnsafePointer<vImage_Buffer>, _ rgbaDst: UnsafePointer<vImage_Buffer>, _ rgbaBackgroundColorPtr: UnsafePointer<UInt16>, _ isImagePremultiplied: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_RGBA8888(_ rgbaSrc: UnsafePointer<vImage_Buffer>, _ rgbaDst: UnsafePointer<vImage_Buffer>, _ rgbaBackgroundColorPtr: UnsafePointer<UInt8>, _ isImagePremultiplied: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_RGBA8888ToRGB888(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: UnsafePointer<UInt8>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_RGBAFFFF(_ rgbaSrc: UnsafePointer<vImage_Buffer>, _ rgbaDst: UnsafePointer<vImage_Buffer>, _ rgbaBackgroundColorPtr: UnsafePointer<Float>, _ isImagePremultiplied: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFlatten_RGBAFFFFToRGBFFF(_: UnsafePointer<vImage_Buffer>, _: UnsafePointer<vImage_Buffer>, _: UnsafePointer<Float>, _: Bool, _: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFloodFill_ARGB16U(_ srcDest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ seedX: vImagePixelCount, _ seedY: vImagePixelCount, _ newValue: UnsafeMutablePointer<UInt16>!, _ connectivity: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFloodFill_ARGB8888(_ srcDest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ seedX: vImagePixelCount, _ seedY: vImagePixelCount, _ newValue: UnsafeMutablePointer<UInt8>!, _ connectivity: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFloodFill_Planar16U(_ srcDest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ seedX: vImagePixelCount, _ seedY: vImagePixelCount, _ newValue: Pixel_16U, _ connectivity: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageFloodFill_Planar8(_ srcDest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ seedX: vImagePixelCount, _ seedY: vImagePixelCount, _ newValue: Pixel_8, _ connectivity: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageGamma_Planar8toPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ gamma: GammaFunction!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageGamma_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ gamma: GammaFunction!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageGamma_PlanarFtoPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ gamma: GammaFunction!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageGetPerspectiveWarp(_ srcPoints: UnsafePointer<(Float, Float)>, _ destPoints: UnsafePointer<(Float, Float)>, _ transform: UnsafeMutablePointer<vImage_PerpsectiveTransform>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageGetResamplingFilterExtent(_ filter: ResamplingFilter, _ flags: vImage_Flags) -> vImagePixelCount { return 0 }
@discardableResult
public func vImageGetResamplingFilterSize(_ scale: Float, _ kernelFunc: ((UnsafePointer<Float>?, UnsafeMutablePointer<Float>?, UInt, UnsafeMutableRawPointer?) -> Void)!, _ kernelWidth: Float, _ flags: vImage_Flags) -> Int { return 0 }
@discardableResult
public func vImageHistogramCalculation_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ histogram: UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHistogramCalculation_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ histogram: UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHistogramCalculation_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ histogram: UnsafeMutablePointer<vImagePixelCount>, _ flags: vImage_Flags) -> vImage_Error { return _vImageHistogramPlanar8(src, histogram: histogram, flags: flags) }
@discardableResult
public func vImageHistogramCalculation_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ histogram: UnsafeMutablePointer<vImagePixelCount>, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHistogramSpecification_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ desired_histogram: UnsafeMutablePointer<UnsafePointer<vImagePixelCount>?>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHistogramSpecification_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ desired_histogram: UnsafeMutablePointer<UnsafePointer<vImagePixelCount>?>!, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHistogramSpecification_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ desired_histogram: UnsafePointer<vImagePixelCount>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHistogramSpecification_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ desired_histogram: UnsafePointer<vImagePixelCount>, _ histogram_entries: UInt32, _ minVal: Pixel_F, _ maxVal: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalReflect_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 16, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 1, flags: flags) }
@discardableResult
public func vImageHorizontalReflect_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectHorizontal(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageHorizontalShearD_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_CbCr16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_CbCr16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShearD_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_CbCr16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_CbCr16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_CbCr8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_Planar16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_16S, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_16U, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageHorizontalShear_XRGB2101010W(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ xTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_32U, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageInterpolatedLookupTable_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<Pixel_F>, _ tableEntries: vImagePixelCount, _ maxFloat: Float, _ minFloat: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_8to64U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ LUT: UnsafePointer<UInt64>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_Planar16(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<Pixel_16U>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_Planar8toPlanar128(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<Pixel_FFFF>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_Planar8toPlanar16(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<Pixel_16U>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_Planar8toPlanar24(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<UInt32>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_Planar8toPlanar48(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<UInt64>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_Planar8toPlanar96(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<Pixel_FFFF>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_Planar8toPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<Pixel_F>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageLookupTable_PlanarFtoPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<Pixel_8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMatrixMultiply_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ matrix: UnsafePointer<Int16>, _ divisor: Int32, _ pre_bias: UnsafePointer<Int16>!, _ post_bias: UnsafePointer<Int32>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMatrixMultiply_ARGB8888ToPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ matrix: UnsafePointer<Int16>, _ divisor: Int32, _ pre_bias: UnsafePointer<Int16>!, _ post_bias: Int32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMatrixMultiply_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ matrix: UnsafePointer<Float>, _ pre_bias: UnsafePointer<Float>!, _ post_bias: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMatrixMultiply_ARGBFFFFToPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ matrix: UnsafePointer<Float>, _ pre_bias: UnsafePointer<Float>!, _ post_bias: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMatrixMultiply_Planar16S(_ srcs: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ dests: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ src_planes: UInt32, _ dest_planes: UInt32, _ matrix: UnsafePointer<Int16>, _ divisor: Int32, _ pre_bias: UnsafePointer<Int16>!, _ post_bias: UnsafePointer<Int32>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMatrixMultiply_Planar8(_ srcs: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ dests: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ src_planes: UInt32, _ dest_planes: UInt32, _ matrix: UnsafePointer<Int16>, _ divisor: Int32, _ pre_bias: UnsafePointer<Int16>!, _ post_bias: UnsafePointer<Int32>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMatrixMultiply_PlanarF(_ srcs: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ dests: UnsafeMutablePointer<UnsafePointer<vImage_Buffer>?>, _ src_planes: UInt32, _ dest_planes: UInt32, _ matrix: UnsafePointer<Float>, _ pre_bias: UnsafePointer<Float>!, _ post_bias: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMax_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMax_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMax_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMax_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMin_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMin_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMin_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMin_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: vImagePixelCount, _ kernel_width: vImagePixelCount, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMultiDimensionalInterpolatedLookupTable_Planar16Q12(_ srcs: UnsafePointer<vImage_Buffer>, _ dests: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ table: vImage_MultidimensionalTable, _ method: vImage_InterpolationMethod, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMultiDimensionalInterpolatedLookupTable_PlanarF(_ srcs: UnsafePointer<vImage_Buffer>, _ dests: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ table: vImage_MultidimensionalTable, _ method: vImage_InterpolationMethod, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMultidimensionalTable_Create(_ tableData: UnsafePointer<UInt16>, _ numSrcChannels: UInt32, _ numDestChannels: UInt32, _ table_entries_per_dimension: UnsafePointer<UInt8>, _ hint: vImageMDTableUsageHint, _ flags: vImage_Flags, _ err: UnsafeMutablePointer<vImage_Error>!) -> vImage_MultidimensionalTable! { return nil }
@discardableResult
public func vImageMultidimensionalTable_Release(_ table: vImage_MultidimensionalTable!) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageMultidimensionalTable_Retain(_ table: vImage_MultidimensionalTable!) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageNewResamplingFilter(_ scale: Float, _ flags: vImage_Flags) -> ResamplingFilter! { return nil }
@discardableResult
public func vImageNewResamplingFilterForFunctionUsingBuffer(_ filter: ResamplingFilter, _ scale: Float, _ kernelFunc: ((UnsafePointer<Float>?, UnsafeMutablePointer<Float>?, UInt, UnsafeMutableRawPointer?) -> Void)!, _ kernelWidth: Float, _ userData: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithPixel_ARGB16U(_ the_pixel: UnsafePointer<UInt16>!, _ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithPixel_ARGB8888(_ the_pixel: UnsafePointer<UInt8>!, _ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithPixel_ARGBFFFF(_ the_pixel: UnsafePointer<Float>!, _ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithScalar_ARGB8888(_ scalar: Pixel_8, _ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithScalar_ARGBFFFF(_ scalar: Pixel_F, _ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithScalar_Planar16F(_ scalar: Pixel_16F, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithScalar_Planar16S(_ scalar: Pixel_16S, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithScalar_Planar16U(_ scalar: Pixel_16U, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithScalar_Planar8(_ scalar: Pixel_8, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannelsWithScalar_PlanarF(_ scalar: Pixel_F, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannels_ARGB8888(_ newSrc: UnsafePointer<vImage_Buffer>, _ origSrc: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageOverwriteChannels_ARGBFFFF(_ newSrc: UnsafePointer<vImage_Buffer>, _ origSrc: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePNGDecompressionFilter(_ buffer: UnsafePointer<vImage_Buffer>!, _ startScanline: vImagePixelCount, _ scanlineCount: vImagePixelCount, _ bitsPerPixel: UInt32, _ filterMethodNumber: UInt32, _ filterType: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePermuteChannelsWithMaskedInsert_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ copyMask: UInt8, _ backgroundColor: UnsafePointer<UInt16>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePermuteChannelsWithMaskedInsert_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ copyMask: UInt8, _ backgroundColor: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePermuteChannelsWithMaskedInsert_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ copyMask: UInt8, _ backgroundColor: UnsafePointer<Float>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePermuteChannels_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePermuteChannels_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePermuteChannels_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error {
    return _vImagePermuteChannelsU8(src, dest, permuteMap: permuteMap, channelCount: 4, flags: flags)
}
@discardableResult
public func vImagePermuteChannels_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePermuteChannels_RGB888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error {
    guard let permuteMap else { return kvImageNullPointerArgument }
    return _vImagePermuteChannelsU8(src, dest, permuteMap: permuteMap, channelCount: 3, flags: flags)
}
@discardableResult
public func vImagePerspectiveWarp_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_PerpsectiveTransform>, _ interpolation: vImage_WarpInterpolation, _ backColor: UnsafeMutablePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePerspectiveWarp_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_PerpsectiveTransform>, _ interpolation: vImage_WarpInterpolation, _ backColor: UnsafeMutablePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePerspectiveWarp_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_PerpsectiveTransform>, _ interpolation: vImage_WarpInterpolation, _ backColor: UnsafeMutablePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePerspectiveWarp_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_PerpsectiveTransform>, _ interpolation: vImage_WarpInterpolation, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePerspectiveWarp_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_PerpsectiveTransform>, _ interpolation: vImage_WarpInterpolation, _ backColor: Pixel_16U, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePerspectiveWarp_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_PerpsectiveTransform>, _ interpolation: vImage_WarpInterpolation, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewiseGamma_Planar16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Pixel_16S, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewiseGamma_Planar16Q12toPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Pixel_16S, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewiseGamma_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewiseGamma_Planar8toPlanar16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewiseGamma_Planar8toPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewiseGamma_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewiseGamma_PlanarFtoPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewisePolynomial_Planar8toPlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ coefficients: UnsafeMutablePointer<UnsafePointer<Float>?>, _ boundaries: UnsafePointer<Float>, _ order: UInt32, _ log2segments: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewisePolynomial_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ coefficients: UnsafeMutablePointer<UnsafePointer<Float>?>, _ boundaries: UnsafePointer<Float>, _ order: UInt32, _ log2segments: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewisePolynomial_PlanarFtoPlanar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ coefficients: UnsafeMutablePointer<UnsafePointer<Float>?>, _ boundaries: UnsafePointer<Float>, _ order: UInt32, _ log2segments: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePiecewiseRational_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ topCoefficients: UnsafeMutablePointer<UnsafePointer<Float>?>, _ bottomCoefficients: UnsafeMutablePointer<UnsafePointer<Float>?>, _ boundaries: UnsafePointer<Float>, _ topOrder: UInt32, _ bottomOrder: UInt32, _ log2segments: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlendDarken_RGBA8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlendLighten_RGBA8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlendMultiply_RGBA8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlendScreen_RGBA8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlendWithPermute_ARGB8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ makeDestAlphaOpaque: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlendWithPermute_RGBA8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ permuteMap: UnsafePointer<UInt8>, _ makeDestAlphaOpaque: Bool, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlend_ARGB8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlend_ARGBFFFF(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlend_BGRA8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlend_BGRAFFFF(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlend_Planar8(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcTopAlpha: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedAlphaBlend_PlanarF(_ srcTop: UnsafePointer<vImage_Buffer>, _ srcTopAlpha: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedConstAlphaBlend_ARGB8888(_ srcTop: UnsafePointer<vImage_Buffer>, _ constAlpha: Pixel_8, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedConstAlphaBlend_ARGBFFFF(_ srcTop: UnsafePointer<vImage_Buffer>, _ constAlpha: Pixel_F, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedConstAlphaBlend_Planar8(_ srcTop: UnsafePointer<vImage_Buffer>, _ constAlpha: Pixel_8, _ srcTopAlpha: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultipliedConstAlphaBlend_PlanarF(_ srcTop: UnsafePointer<vImage_Buffer>, _ constAlpha: Pixel_F, _ srcTopAlpha: UnsafePointer<vImage_Buffer>, _ srcBottom: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_ARGB16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImagePremultiplyARGB8888(src, dest, flags: flags) }
@discardableResult
public func vImagePremultiplyData_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_RGBA16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_RGBA16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_RGBA16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_RGBA8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImagePremultiplyData_RGBAFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRichardsonLucyDeConvolve_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Int16>!, _ kernel2: UnsafePointer<Int16>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ kernel_height2: UInt32, _ kernel_width2: UInt32, _ divisor: Int32, _ divisor2: Int32, _ backgroundColor: UnsafePointer<UInt8>!, _ iterationCount: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRichardsonLucyDeConvolve_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel2: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ kernel_height2: UInt32, _ kernel_width2: UInt32, _ backgroundColor: UnsafePointer<Float>!, _ iterationCount: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRichardsonLucyDeConvolve_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Int16>!, _ kernel2: UnsafePointer<Int16>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ kernel_height2: UInt32, _ kernel_width2: UInt32, _ divisor: Int32, _ divisor2: Int32, _ backgroundColor: Pixel_8, _ iterationCount: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRichardsonLucyDeConvolve_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel: UnsafePointer<Float>!, _ kernel2: UnsafePointer<Float>!, _ kernel_height: UInt32, _ kernel_width: UInt32, _ kernel_height2: UInt32, _ kernel_width2: UInt32, _ backgroundColor: Pixel_F, _ iterationCount: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRotate90_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageRotate90_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: UnsafePointer<Int16>, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageRotate90_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: UnsafePointer<UInt16>, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageRotate90_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: UnsafePointer<UInt8>, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageRotate90_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: UnsafePointer<Float>, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 16, flags: flags) }
@discardableResult
public func vImageRotate90_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageRotate90_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageRotate90_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: Pixel_16U, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageRotate90_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 1, flags: flags) }
@discardableResult
public func vImageRotate90_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ rotationConstant: UInt8, _ backColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return _vImageRotate90(src, dest, rotationConstant: rotationConstant, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageRotate_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRotate_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRotate_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRotate_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error {
    _ = tempBuffer
    return _vImageRotateU8(src, dest, angleInRadians: angleInRadians, backColor: backColor, bytesPerPixel: 4, flags: flags)
}
@discardableResult
public func vImageRotate_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRotate_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRotate_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageRotate_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error {
    _ = tempBuffer
    var color = backColor
    return _vImageRotateU8(src, dest, angleInRadians: angleInRadians, backColor: &color, bytesPerPixel: 1, flags: flags)
}
@discardableResult
public func vImageRotate_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ angleInRadians: Float, _ backColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageScale_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageScale_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageScale_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageScale_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageScaleDispatch(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageScale_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 16, flags: flags) }
@discardableResult
public func vImageScale_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageScale_CbCr16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageScale_CbCr8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageScale_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageScale_Planar16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageScale_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageScale_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageScaleDispatch(src, dest, bytesPerPixel: 1, flags: flags) }
@discardableResult
public func vImageScale_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageScale_XRGB2101010W(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ flags: vImage_Flags) -> vImage_Error { _ = tempBuffer; return _vImageNearestScale(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageSelectChannels_ARGB8888(_ newSrc: UnsafePointer<vImage_Buffer>, _ origSrc: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSelectChannels_ARGBFFFF(_ newSrc: UnsafePointer<vImage_Buffer>, _ origSrc: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ copyMask: UInt8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSepConvolve_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernelX: UnsafePointer<Float>!, _ kernelX_width: UInt32, _ kernelY: UnsafePointer<Float>!, _ kernelY_width: UInt32, _ bias: Float, _ backgroundColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSepConvolve_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernelX: UnsafePointer<Float>!, _ kernelX_width: UInt32, _ kernelY: UnsafePointer<Float>!, _ kernelY_width: UInt32, _ bias: Float, _ backgroundColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSepConvolve_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernelX: UnsafePointer<Float>!, _ kernelX_width: UInt32, _ kernelY: UnsafePointer<Float>!, _ kernelY_width: UInt32, _ bias: Float, _ backgroundColor: Pixel_16U, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSepConvolve_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernelX: UnsafePointer<Float>!, _ kernelX_width: UInt32, _ kernelY: UnsafePointer<Float>!, _ kernelY_width: UInt32, _ bias: Float, _ backgroundColor: Pixel_16U, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSepConvolve_Planar8to16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernelX: UnsafePointer<Float>!, _ kernelX_width: UInt32, _ kernelY: UnsafePointer<Float>!, _ kernelY_width: UInt32, _ scale: Float, _ bias: Float, _ backgroundColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSepConvolve_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernelX: UnsafePointer<Float>!, _ kernelX_width: UInt32, _ kernelY: UnsafePointer<Float>!, _ kernelY_width: UInt32, _ bias: Float, _ backgroundColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSymmetricPiecewiseGamma_Planar16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Pixel_16S, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSymmetricPiecewiseGamma_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ exponentialCoeffs: UnsafePointer<Float>, _ gamma: Float, _ linearCoeffs: UnsafePointer<Float>, _ boundary: Float, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageSymmetricPiecewisePolynomial_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ coefficients: UnsafeMutablePointer<UnsafePointer<Float>?>, _ boundaries: UnsafePointer<Float>, _ order: UInt32, _ log2segments: UInt32, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageTableLookUp_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ alphaTable: UnsafePointer<Pixel_8>!, _ redTable: UnsafePointer<Pixel_8>!, _ greenTable: UnsafePointer<Pixel_8>!, _ blueTable: UnsafePointer<Pixel_8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageTableLookUp_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ table: UnsafePointer<Pixel_8>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageTentConvolve_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: UInt32, _ kernel_width: UInt32, _ backgroundColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error {
    _ = tempBuffer
    _ = srcOffsetToROI_X
    _ = srcOffsetToROI_Y
    _ = backgroundColor
    return _vImageTentConvolveU8(src, dest, kernelWidth: kernel_width, kernelHeight: kernel_height, bytesPerPixel: 4, flags: flags)
}
@discardableResult
public func vImageTentConvolve_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ kernel_height: UInt32, _ kernel_width: UInt32, _ backgroundColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error {
    _ = tempBuffer
    _ = srcOffsetToROI_X
    _ = srcOffsetToROI_Y
    _ = backgroundColor
    return _vImageTentConvolveU8(src, dest, kernelWidth: kernel_width, kernelHeight: kernel_height, bytesPerPixel: 1, flags: flags)
}
@discardableResult
public func vImageUnpremultiplyData_ARGB16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageUnpremultiplyARGB8888(src, dest, flags: flags) }
@discardableResult
public func vImageUnpremultiplyData_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ alpha: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_RGBA16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_RGBA16Q12(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_RGBA16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_RGBA8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageUnpremultiplyData_RGBAFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalReflect_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageVerticalReflect_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageVerticalReflect_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 8, flags: flags) }
@discardableResult
public func vImageVerticalReflect_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageVerticalReflect_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 16, flags: flags) }
@discardableResult
public func vImageVerticalReflect_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageVerticalReflect_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageVerticalReflect_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 2, flags: flags) }
@discardableResult
public func vImageVerticalReflect_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 1, flags: flags) }
@discardableResult
public func vImageVerticalReflect_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ flags: vImage_Flags) -> vImage_Error { return _vImageReflectVertical(src, dest, bytesPerPixel: 4, flags: flags) }
@discardableResult
public func vImageVerticalShearD_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_CbCr16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_CbCr16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShearD_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Double, _ shearSlope: Double, _ filter: ResamplingFilter!, _ backColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_ARGB16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_ARGB16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_ARGB16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_ARGB8888(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_ARGBFFFF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Float>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_CbCr16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_CbCr16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<Int16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_CbCr16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt16>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_CbCr8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: UnsafePointer<UInt8>!, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_Planar16F(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_16F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_Planar16S(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_16S, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_Planar16U(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_16U, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_Planar8(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_8, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_PlanarF(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_F, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vImageVerticalShear_XRGB2101010W(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ srcOffsetToROI_X: vImagePixelCount, _ srcOffsetToROI_Y: vImagePixelCount, _ yTranslate: Float, _ shearSlope: Float, _ filter: ResamplingFilter!, _ backColor: Pixel_32U, _ flags: vImage_Flags) -> vImage_Error { return kvImageInvalidParameter }
@discardableResult
public func vacosf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vacoshf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vasinf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vasinhf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vatan2f(_: vFloat, _: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vatanf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vatanhf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vceilf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vclassifyf(_: vFloat) -> vUInt32 { return vUInt32() }
@discardableResult
public func vcopysignf(_: vFloat, _: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vcosf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vcoshf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vcospif(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vdivf(_: vFloat, _: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vexp2f(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vexpf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vexpm1f(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vfabsf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vfloorf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vfmodf(_: vFloat, _: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vipowf(_: vFloat, _: vSInt32) -> vFloat { return vFloat() }
@discardableResult
public func vlog10f(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vlog1pf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vlog2f(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vlogbf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vlogf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vnextafterf(_: vFloat, _: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vnintf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vpowf(_: vFloat, _: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vrecf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vremainderf(_: vFloat, _: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vremquof(_: vFloat, _: vFloat, _: UnsafeMutablePointer<vUInt32>) -> vFloat { return vFloat() }
@discardableResult
public func vrsqrtf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vscalbf(_: vFloat, _: vSInt32) -> vFloat { return vFloat() }
@discardableResult
public func vsignbitf(_: vFloat) -> vUInt32 { return vUInt32() }
@discardableResult
public func vsincosf(_: vFloat, _: UnsafeMutablePointer<vFloat>) -> vFloat { return vFloat() }
@discardableResult
public func vsinf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vsinhf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vsinpif(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vsqrtf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vtablelookup(_: vSInt32, _: UnsafeMutablePointer<UInt32>) -> vUInt32 { return vUInt32() }
@discardableResult
public func vtanf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vtanhf(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vtanpif(_: vFloat) -> vFloat { return vFloat() }
@discardableResult
public func vtruncf(_: vFloat) -> vFloat { return vFloat() }
public func vvacos(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.acos(x[i]) } }
public func vvacosf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.acos(x[i]) } }
public func vvacosh(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.acosh(x[i]) } }
public func vvacoshf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.acosh(x[i]) } }
public func vvasin(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.asin(x[i]) } }
public func vvasinf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.asin(x[i]) } }
public func vvasinh(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.asinh(x[i]) } }
public func vvasinhf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.asinh(x[i]) } }
public func vvatan(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.atan(x[i]) } }
public func vvatan2(_ z: UnsafeMutablePointer<Double>, _ y: UnsafePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.atan2(y[i], x[i]) } }
public func vvatan2f(_ z: UnsafeMutablePointer<Float>, _ y: UnsafePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.atan2(y[i], x[i]) } }
public func vvatanf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.atan(x[i]) } }
public func vvatanh(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.atanh(x[i]) } }
public func vvatanhf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.atanh(x[i]) } }
public func vvcbrt(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.cbrt(x[i]) } }
public func vvcbrtf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.cbrt(x[i]) } }
public func vvceil(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.ceil(x[i]) } }
public func vvceilf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.ceil(x[i]) } }
public func vvcopysign(_ z: UnsafeMutablePointer<Double>, _ mag: UnsafePointer<Double>, _ sign: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.copysign(mag[i], sign[i]) } }
public func vvcopysignf(_ z: UnsafeMutablePointer<Float>, _ mag: UnsafePointer<Float>, _ sign: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.copysign(mag[i], sign[i]) } }
public func vvcos(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.cos(x[i]) } }
public func vvcosf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.cos(x[i]) } }
public func vvcosh(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.cosh(x[i]) } }
public func vvcoshf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.cosh(x[i]) } }
public func vvcosisin(_: OpaquePointer, _: UnsafePointer<Double>, _: UnsafePointer<Int32>) { }
public func vvcosisinf(_: OpaquePointer, _: UnsafePointer<Float>, _: UnsafePointer<Int32>) { }
public func vvcospi(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.cos(x[i] * .pi) } }
public func vvcospif(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.cos(x[i] * .pi) } }
public func vvdiv(_ z: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ y: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = x[i] / y[i] } }
public func vvdivf(_ z: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ y: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = x[i] / y[i] } }
public func vvexp(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.exp(x[i]) } }
public func vvexp2(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.exp2(x[i]) } }
public func vvexp2f(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.exp2(x[i]) } }
public func vvexpf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.exp(x[i]) } }
public func vvexpm1(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.expm1(x[i]) } }
public func vvexpm1f(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.expm1(x[i]) } }
public func vvfabs(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = (x[i] < 0 ? -x[i] : x[i]) } }
public func vvfabsf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = (x[i] < 0 ? -x[i] : x[i]) } }
public func vvfloor(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.floor(x[i]) } }
public func vvfloorf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.floor(x[i]) } }
public func vvfmod(_ z: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ y: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = x[i].truncatingRemainder(dividingBy: y[i]) } }
public func vvfmodf(_ z: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ y: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = x[i].truncatingRemainder(dividingBy: y[i]) } }
public func vvint(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.trunc(x[i]) } }
public func vvintf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.trunc(x[i]) } }
public func vvlog(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.log(x[i]) } }
public func vvlog10(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.log10(x[i]) } }
public func vvlog10f(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.log10(x[i]) } }
public func vvlog1p(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.log1p(x[i]) } }
public func vvlog1pf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.log1p(x[i]) } }
public func vvlog2(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.log2(x[i]) } }
public func vvlog2f(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.log2(x[i]) } }
public func vvlogb(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.logb(x[i]) } }
public func vvlogbf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.logb(x[i]) } }
public func vvlogf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.log(x[i]) } }
public func vvnextafter(_ z: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ y: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = x[i] < y[i] ? x[i].nextUp : (x[i] > y[i] ? x[i].nextDown : x[i]) } }
public func vvnextafterf(_ z: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ y: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = x[i] < y[i] ? x[i].nextUp : (x[i] > y[i] ? x[i].nextDown : x[i]) } }
public func vvnint(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = x[i].rounded(.toNearestOrEven) } }
public func vvnintf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = x[i].rounded(.toNearestOrEven) } }
public func vvpow(_ z: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ y: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.pow(x[i], y[i]) } }
public func vvpowf(_ z: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ y: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.pow(x[i], y[i]) } }
public func vvpows(_ z: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ y: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.pow(x[i], y[i]) } }
public func vvpowsf(_ z: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ y: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.pow(x[i], y[i]) } }
public func vvrec(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = 1 / x[i] } }
public func vvrecf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = 1 / x[i] } }
public func vvremainder(_ z: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ y: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.remainder(x[i], y[i]) } }
public func vvremainderf(_ z: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ y: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { z[i] = Foundation.remainder(x[i], y[i]) } }
public func vvrsqrt(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = 1 / Foundation.sqrt(x[i]) } }
public func vvrsqrtf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = 1 / Foundation.sqrt(x[i]) } }
public func vvsin(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.sin(x[i]) } }
public func vvsincos(_ sinOut: UnsafeMutablePointer<Double>, _ cosOut: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { sinOut[i] = Foundation.sin(x[i]); cosOut[i] = Foundation.cos(x[i]) } }
public func vvsincosf(_ sinOut: UnsafeMutablePointer<Float>, _ cosOut: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { sinOut[i] = Foundation.sin(x[i]); cosOut[i] = Foundation.cos(x[i]) } }
public func vvsinf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.sin(x[i]) } }
public func vvsinh(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.sinh(x[i]) } }
public func vvsinhf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.sinh(x[i]) } }
public func vvsinpi(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.sin(x[i] * .pi) } }
public func vvsinpif(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.sin(x[i] * .pi) } }
public func vvsqrt(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.sqrt(x[i]) } }
public func vvsqrtf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.sqrt(x[i]) } }
public func vvtan(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.tan(x[i]) } }
public func vvtanf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.tan(x[i]) } }
public func vvtanh(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.tanh(x[i]) } }
public func vvtanhf(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.tanh(x[i]) } }
public func vvtanpi(_ y: UnsafeMutablePointer<Double>, _ x: UnsafePointer<Double>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.tan(x[i] * .pi) } }
public func vvtanpif(_ y: UnsafeMutablePointer<Float>, _ x: UnsafePointer<Float>, _ n: UnsafePointer<Int32>) { let count = Int(n.pointee); for i in 0..<count { y[i] = Foundation.tan(x[i] * .pi) } }
@discardableResult
public func xerbla_(_ srname: UnsafeMutablePointer<CChar>!, _ info: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zaxpy_(_ n: UnsafeMutablePointer<Int32>!, _ ca: UnsafeMutableRawPointer!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zcopy_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
public func zdotc_(_ ret_val: UnsafeMutableRawPointer!, _ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) { }
public func zdotu_(_ ret_val: UnsafeMutableRawPointer!, _ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) { }
@discardableResult
public func zdrot_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ c: UnsafeMutablePointer<Double>!, _ s: UnsafeMutablePointer<Double>!) -> Int32 { return 0 }
@discardableResult
public func zdscal_(_ n: UnsafeMutablePointer<Int32>!, _ sa: UnsafeMutablePointer<Double>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zgbmv_(_ trans: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ kl: UnsafeMutablePointer<Int32>!, _ ku: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zgemm_(_ transa: UnsafeMutablePointer<CChar>!, _ transb: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zgemv_(_ trans: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zgerc_(_ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zgeru_(_ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zhbmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zhemm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zhemv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zher2_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zher2k_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zher_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zherk_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutablePointer<Double>!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zhpmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ ap: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zhpr2_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ y: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutableRawPointer!) -> Int32 { return 0 }
@discardableResult
public func zhpr_(_ uplo: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutablePointer<Double>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutableRawPointer!) -> Int32 { return 0 }
@discardableResult
public func zrotg_(_ ca: UnsafeMutableRawPointer!, _ cb: UnsafeMutableRawPointer!, _ c: UnsafeMutablePointer<Double>!, _ cs: UnsafeMutableRawPointer!) -> Int32 { return 0 }
@discardableResult
public func zscal_(_ n: UnsafeMutablePointer<Int32>!, _ ca: UnsafeMutableRawPointer!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zswap_(_ n: UnsafeMutablePointer<Int32>!, _ cx: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!, _ cy: UnsafeMutableRawPointer!, _ incy: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zsymm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zsyr2k_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func zsyrk_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ beta: UnsafeMutableRawPointer!, _ c__: UnsafeMutableRawPointer!, _ ldc: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ztbmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ztbsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ k: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ztpmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ztpsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ ap: UnsafeMutableRawPointer!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ztrmm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ transa: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ztrmv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ztrsm_(_ side: UnsafeMutablePointer<CChar>!, _ uplo: UnsafeMutablePointer<CChar>!, _ transa: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ m: UnsafeMutablePointer<Int32>!, _ n: UnsafeMutablePointer<Int32>!, _ alpha: UnsafeMutableRawPointer!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ b: UnsafeMutableRawPointer!, _ ldb: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
@discardableResult
public func ztrsv_(_ uplo: UnsafeMutablePointer<CChar>!, _ trans: UnsafeMutablePointer<CChar>!, _ diag: UnsafeMutablePointer<CChar>!, _ n: UnsafeMutablePointer<Int32>!, _ a: UnsafeMutableRawPointer!, _ lda: UnsafeMutablePointer<Int32>!, _ x: UnsafeMutableRawPointer!, _ incx: UnsafeMutablePointer<Int32>!) -> Int32 { return 0 }
