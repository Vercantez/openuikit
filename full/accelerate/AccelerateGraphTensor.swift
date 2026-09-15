import Foundation

// MARK: - BNNSGraph symbolic graph construction (wave 11)
//
// Linux has no BNNS graph compiler or executor: `BNNSGraph.makeContext`
// throws `unableToCreateContext` and every C graph execute/get entry point
// returns `BNNSLinuxFailClosedStatus`. What this file implements is the
// *construction* side only, mirroring the Apple declaration semantics
// ("Adds an element-wise ... operation to the current graph"): each
// `Builder` factory and `Tensor` op returns a symbolic `Tensor` handle that
// records the operation chain in its `description`, preserves the input
// `shape`/`stride` (reductions keep the input shape symbolically; real shape
// inference happens at Apple compile time), and reports `T.bnnsDataType`.
// No numeric execution is claimed: reading `tensorData` yields `nil` because
// symbolic nodes own no device memory.
//
// Signatures reproduce the Apple declarations recorded in
// `reference/public-surface.tsv` (Xcode 26.1 iPhoneOS 26.1 SDK).

extension BNNSGraph.Builder.Tensor: BNNSGraph.TensorDescriptor {}

public extension BNNSGraph.Builder {
    func argument<T>(
        name: String? = nil,
        dataType: T.Type,
        shape: [Int],
        intent: BNNSGraph.Builder.Intent = .input
    ) -> BNNSGraph.Builder.Tensor<T> where T: BNNSScalar {
        _ = dataType
        let label = name ?? "argument"
        return BNNSGraph.Builder.Tensor<T>(
            node: "\(label)(shape:\(shape),intent:\(intent))",
            shape: shape
        )
    }

    func constant<T>(
        name: String? = nil,
        value: T
    ) -> BNNSGraph.Builder.Tensor<T> where T: BNNSScalar {
        _ = value
        return BNNSGraph.Builder.Tensor<T>(
            node: "\(name ?? "constant")(scalar)",
            shape: []
        )
    }

    func constant<T>(
        name: String? = nil,
        values: some AccelerateBuffer,
        shape: [Int]? = nil
    ) -> BNNSGraph.Builder.Tensor<T> where T: BNNSScalar {
        BNNSGraph.Builder.Tensor<T>(
            node: "\(name ?? "constant")(count:\(values.count))",
            shape: shape ?? [values.count]
        )
    }

    func constant(
        values: Array<Array<Float>>,
        rowMajor: Bool = false
    ) -> BNNSGraph.Builder.Tensor<Float> {
        let columnCount = values.first?.count ?? 0
        precondition(
            values.allSatisfy { $0.count == columnCount },
            "Accelerate Linux: constant(values:) requires uniform row lengths"
        )
        _ = rowMajor
        return BNNSGraph.Builder.Tensor<Float>(
            node: "constant2D(rows:\(values.count),columns:\(columnCount))",
            shape: [values.count, columnCount]
        )
    }

    func constant(
        values: Array<Array<Float16>>,
        rowMajor: Bool = false
    ) -> BNNSGraph.Builder.Tensor<Float16> {
        let columnCount = values.first?.count ?? 0
        precondition(
            values.allSatisfy { $0.count == columnCount },
            "Accelerate Linux: constant(values:) requires uniform row lengths"
        )
        _ = rowMajor
        return BNNSGraph.Builder.Tensor<Float16>(
            node: "constant2D(rows:\(values.count),columns:\(columnCount))",
            shape: [values.count, columnCount]
        )
    }
}

public extension BNNSGraph.Builder.Tensor {
    private func derived(_ op: String) -> BNNSGraph.Builder.Tensor<T> {
        BNNSGraph.Builder.Tensor<T>(node: "\(description).\(op)", shape: shape, stride: stride)
    }

    func abs() -> BNNSGraph.Builder.Tensor<T> { derived("abs()") }
    func cos() -> BNNSGraph.Builder.Tensor<T> { derived("cos()") }
    func sin() -> BNNSGraph.Builder.Tensor<T> { derived("sin()") }
    func tan() -> BNNSGraph.Builder.Tensor<T> { derived("tan()") }
    func acos() -> BNNSGraph.Builder.Tensor<T> { derived("acos()") }
    func asin() -> BNNSGraph.Builder.Tensor<T> { derived("asin()") }
    func atan() -> BNNSGraph.Builder.Tensor<T> { derived("atan()") }
    func cosh() -> BNNSGraph.Builder.Tensor<T> { derived("cosh()") }
    func sinh() -> BNNSGraph.Builder.Tensor<T> { derived("sinh()") }
    func tanh() -> BNNSGraph.Builder.Tensor<T> { derived("tanh()") }
    func acosh() -> BNNSGraph.Builder.Tensor<T> { derived("acosh()") }
    func asinh() -> BNNSGraph.Builder.Tensor<T> { derived("asinh()") }
    func atanh() -> BNNSGraph.Builder.Tensor<T> { derived("atanh()") }
    func exp() -> BNNSGraph.Builder.Tensor<T> { derived("exp()") }
    func exp2() -> BNNSGraph.Builder.Tensor<T> { derived("exp2()") }
    func erf() -> BNNSGraph.Builder.Tensor<T> { derived("erf()") }
    func sqrt() -> BNNSGraph.Builder.Tensor<T> { derived("sqrt()") }
    func ceil() -> BNNSGraph.Builder.Tensor<T> { derived("ceil()") }
    func floor() -> BNNSGraph.Builder.Tensor<T> { derived("floor()") }
    func round() -> BNNSGraph.Builder.Tensor<T> { derived("round()") }
    func relu() -> BNNSGraph.Builder.Tensor<T> { derived("relu()") }
    func silu() -> BNNSGraph.Builder.Tensor<T> { derived("silu()") }
    func sigmoid() -> BNNSGraph.Builder.Tensor<T> { derived("sigmoid()") }
    func softsign() -> BNNSGraph.Builder.Tensor<T> { derived("softsign()") }
    func hardSwish() -> BNNSGraph.Builder.Tensor<T> { derived("hardSwish()") }

    func elu(alpha: Float) -> BNNSGraph.Builder.Tensor<T> { derived("elu(alpha:\(alpha))") }
    func softplus(alpha: Float) -> BNNSGraph.Builder.Tensor<T> { derived("softplus(alpha:\(alpha))") }
    func scaledTanh(alpha: Float, beta: Float) -> BNNSGraph.Builder.Tensor<T> {
        derived("scaledTanh(alpha:\(alpha),beta:\(beta))")
    }
    func hardSigmoid(alpha: Float, beta: Float) -> BNNSGraph.Builder.Tensor<T> {
        derived("hardSigmoid(alpha:\(alpha),beta:\(beta))")
    }

    func log(epsilon: Float = .ulpOfOne.squareRoot()) -> BNNSGraph.Builder.Tensor<T> {
        derived("log(epsilon:\(epsilon))")
    }
    func reciprocal(epsilon: Float = .ulpOfOne.squareRoot()) -> BNNSGraph.Builder.Tensor<T> {
        derived("reciprocal(epsilon:\(epsilon))")
    }
    func rsqrt(epsilon: Float = .ulpOfOne.squareRoot()) -> BNNSGraph.Builder.Tensor<T> {
        derived("rsqrt(epsilon:\(epsilon))")
    }
    func l2Norm(epsilon: Float = .ulpOfOne.squareRoot()) -> BNNSGraph.Builder.Tensor<T> {
        derived("l2Norm(epsilon:\(epsilon))")
    }

    func max(y: some BNNSGraph.Builder.OperationParameter<T>) -> BNNSGraph.Builder.Tensor<T> {
        _ = y
        return derived("max(y:)")
    }
    func min(y: some BNNSGraph.Builder.OperationParameter<T>) -> BNNSGraph.Builder.Tensor<T> {
        _ = y
        return derived("min(y:)")
    }
    func pow(y: some BNNSGraph.Builder.OperationParameter<T>) -> BNNSGraph.Builder.Tensor<T> {
        _ = y
        return derived("pow(y:)")
    }
    func linear(
        weight: some BNNSGraph.Builder.OperationParameter<T>
    ) -> BNNSGraph.Builder.Tensor<T> {
        _ = weight
        return derived("linear(weight:)")
    }
    func linear(
        weight: some BNNSGraph.Builder.OperationParameter<T>,
        bias: some BNNSGraph.Builder.OperationParameter<T>
    ) -> BNNSGraph.Builder.Tensor<T> {
        _ = weight
        _ = bias
        return derived("linear(weight:bias:)")
    }
    func gather(
        indices: some BNNSGraph.Builder.OperationParameter<Int32>,
        axis: Int,
        batchDimensionCount: Int
    ) -> BNNSGraph.Builder.Tensor<T> {
        _ = indices
        return BNNSGraph.Builder.Tensor<T>(
            node: "\(description).gather(axis:\(axis),batch:\(batchDimensionCount))",
            shape: shape,
            stride: stride
        )
    }

    func pad(
        _ type: BNNSGraph.Builder.Padding,
        padding: [Int]
    ) -> BNNSGraph.Builder.Tensor<T> {
        BNNSGraph.Builder.Tensor<T>(
            node: "\(description).pad(\(type),\(padding))",
            shape: shape,
            stride: stride
        )
    }
    func clip(to bounds: ClosedRange<Float>) -> BNNSGraph.Builder.Tensor<T> {
        derived("clip(to:\(bounds))")
    }
    func threshold(to lowerBound: Float) -> BNNSGraph.Builder.Tensor<T> {
        derived("threshold(to:\(lowerBound))")
    }
    func transpose(axes: [Int]) -> BNNSGraph.Builder.Tensor<T> {
        derived("transpose(axes:\(axes))")
    }
    func softmax(axis: Int) -> BNNSGraph.Builder.Tensor<T> {
        derived("softmax(axis:\(axis))")
    }
    func logSoftmax(axis: Int) -> BNNSGraph.Builder.Tensor<T> {
        derived("logSoftmax(axis:\(axis))")
    }

    func sum(axes: [Int], keepDimensions: Bool) -> BNNSGraph.Builder.Tensor<T> {
        derived("sum(axes:\(axes),keep:\(keepDimensions))")
    }
    func mean(axes: [Int], keepDimensions: Bool) -> BNNSGraph.Builder.Tensor<T> {
        derived("mean(axes:\(axes),keep:\(keepDimensions))")
    }
    func product(axes: [Int], keepDimensions: Bool) -> BNNSGraph.Builder.Tensor<T> {
        derived("product(axes:\(axes),keep:\(keepDimensions))")
    }
    func minimum(axes: [Int], keepDimensions: Bool) -> BNNSGraph.Builder.Tensor<T> {
        derived("minimum(axes:\(axes),keep:\(keepDimensions))")
    }
    func maximum(axes: [Int], keepDimensions: Bool) -> BNNSGraph.Builder.Tensor<T> {
        derived("maximum(axes:\(axes),keep:\(keepDimensions))")
    }
    func logSumExp(axes: [Int], keepDimensions: Bool) -> BNNSGraph.Builder.Tensor<T> {
        derived("logSumExp(axes:\(axes),keep:\(keepDimensions))")
    }
    func sumOfSquares(axes: [Int], keepDimensions: Bool) -> BNNSGraph.Builder.Tensor<T> {
        derived("sumOfSquares(axes:\(axes),keep:\(keepDimensions))")
    }
    func l2Norm(axes: [Int], keepDimensions: Bool) -> BNNSGraph.Builder.Tensor<T> {
        derived("l2Norm(axes:\(axes),keep:\(keepDimensions))")
    }

    func argMax(axis: Int, keepDimension: Bool) -> BNNSGraph.Builder.Tensor<Int32> {
        BNNSGraph.Builder.Tensor<Int32>(
            node: "\(description).argMax(axis:\(axis),keep:\(keepDimension))",
            shape: shape,
            stride: stride
        )
    }
    func argMin(axis: Int, keepDimension: Bool) -> BNNSGraph.Builder.Tensor<Int32> {
        BNNSGraph.Builder.Tensor<Int32>(
            node: "\(description).argMin(axis:\(axis),keep:\(keepDimension))",
            shape: shape,
            stride: stride
        )
    }
}
