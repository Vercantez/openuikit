import Accelerate
import Foundation

// Wave 11 declared-remainder conversion: symbolic BNNSGraph.Builder.Tensor
// construction. Linux has no BNNS graph compiler or executor (makeContext
// throws, C graph execute/get returns BNNSLinuxFailClosedStatus), so the
// Builder factories and Tensor ops below record pure construction nodes:
// each call returns a symbolic handle whose description logs the operation
// chain, whose shape/stride are preserved from the input, and whose dataType
// is the scalar's BNNS mapping. No numeric execution is claimed. Every
// precondition below executes real Linux behavior; no test uses
// DispatchQueue.main, RunLoop, semaphores, or await.

struct GraphTensorOperandFloat: BNNSGraph.Builder.OperationParameter {
    typealias Element = Float
}

struct GraphTensorOperandInt32: BNNSGraph.Builder.OperationParameter {
    typealias Element = Int32
}

func testGraphTensorFactories() {
    _ = try? BNNSGraph.makeContext { builder in
        let input: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2]
        )
        precondition(input.shape == [2])
        precondition(input.rank == 1)
        precondition(input.dataType == BNNSDataTypeFloat32)
        precondition(input.tensorData == nil)
        let named: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            name: "x", dataType: Float.self, shape: [2, 3], intent: .inputOutput
        )
        precondition(named.shape == [2, 3])
        precondition(named.description.contains("x"))
        let scalar: BNNSGraph.Builder.Tensor<Float> = builder.constant(
            name: "bias", value: Float(0.5)
        )
        precondition(scalar.description.contains("bias"))
        let weights: BNNSGraph.Builder.Tensor<Float> = builder.constant(
            name: "w", values: [Float(1), Float(2)], shape: [2]
        )
        precondition(weights.shape == [2])
        let inferred: BNNSGraph.Builder.Tensor<Float> = builder.constant(
            values: [Float(3)]
        )
        precondition(inferred.shape == [1])
        let matrix: BNNSGraph.Builder.Tensor<Float> = builder.constant(
            values: [[Float(1), Float(2)], [Float(3), Float(4)]], rowMajor: true
        )
        precondition(matrix.shape == [2, 2])
        let half: BNNSGraph.Builder.Tensor<Float16> = builder.constant(
            values: [[Float16(1)]], rowMajor: false
        )
        precondition(half.shape == [1, 1])
        precondition(half.dataType == BNNSDataTypeFloat16)
        return [input, named, scalar, weights, inferred, matrix]
    }
}

func testGraphTensorElementwiseA() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2]
        )
        let a = t.abs()
        precondition(a.shape == [2] && a.description.contains("abs"))
        let c = t.cos()
        precondition(c.description.contains("cos"))
        let s = t.sin()
        precondition(s.description.contains("sin"))
        let n = t.tan()
        precondition(n.description.contains("tan"))
        let ac = t.acos()
        precondition(ac.description.contains("acos"))
        let asn = t.asin()
        precondition(asn.description.contains("asin"))
        let atn = t.atan()
        precondition(atn.description.contains("atan"))
        return [a, c, s, n, ac, asn, atn]
    }
}

func testGraphTensorElementwiseB() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2]
        )
        let ch = t.cosh()
        precondition(ch.description.contains("cosh"))
        let sh = t.sinh()
        precondition(sh.description.contains("sinh"))
        let th = t.tanh()
        precondition(th.description.contains("tanh"))
        let ach = t.acosh()
        precondition(ach.description.contains("acosh"))
        let ash = t.asinh()
        precondition(ash.description.contains("asinh"))
        let ath = t.atanh()
        precondition(ath.description.contains("atanh"))
        let e = t.exp()
        precondition(e.description.contains("exp"))
        return [ch, sh, th, ach, ash, ath, e]
    }
}

func testGraphTensorElementwiseC() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2]
        )
        let e2 = t.exp2()
        precondition(e2.description.contains("exp2"))
        let er = t.erf()
        precondition(er.description.contains("erf"))
        let sq = t.sqrt()
        precondition(sq.description.contains("sqrt"))
        let ce = t.ceil()
        precondition(ce.description.contains("ceil"))
        let fl = t.floor()
        precondition(fl.description.contains("floor"))
        let ro = t.round()
        precondition(ro.description.contains("round"))
        let re = t.relu()
        precondition(re.description.contains("relu"))
        return [e2, er, sq, ce, fl, ro, re]
    }
}

func testGraphTensorElementwiseD() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2]
        )
        let si = t.silu()
        precondition(si.description.contains("silu"))
        let sg = t.sigmoid()
        precondition(sg.description.contains("sigmoid"))
        let ss = t.softsign()
        precondition(ss.description.contains("softsign"))
        let hs = t.hardSwish()
        precondition(hs.description.contains("hardSwish"))
        let el = t.elu(alpha: Float(1))
        precondition(el.description.contains("elu"))
        let sp = t.softplus(alpha: Float(1))
        precondition(sp.description.contains("softplus"))
        let st = t.scaledTanh(alpha: Float(1), beta: Float(2))
        precondition(st.description.contains("scaledTanh"))
        let hsg = t.hardSigmoid(alpha: Float(1), beta: Float(2))
        precondition(hsg.description.contains("hardSigmoid"))
        return [si, sg, ss, hs, el, sp, st, hsg]
    }
}

func testGraphTensorEpsilonOps() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2]
        )
        let lo = t.log()
        precondition(lo.description.contains("log"))
        let loExplicit = t.log(epsilon: Float(0.25))
        precondition(loExplicit.description.contains("0.25"))
        let re = t.reciprocal()
        precondition(re.description.contains("reciprocal"))
        let rs = t.rsqrt(epsilon: Float(0.5))
        precondition(rs.description.contains("rsqrt"))
        let ln = t.l2Norm()
        precondition(ln.description.contains("l2Norm"))
        return [lo, loExplicit, re, rs, ln]
    }
}

func testGraphTensorBinaryOps() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2]
        )
        let operand = GraphTensorOperandFloat()
        let mx = t.max(y: operand)
        precondition(mx.shape == [2] && mx.description.contains("max"))
        let mn = t.min(y: operand)
        precondition(mn.description.contains("min"))
        let pw = t.pow(y: operand)
        precondition(pw.description.contains("pow"))
        let li = t.linear(weight: operand)
        precondition(li.description.contains("linear"))
        let lb = t.linear(weight: operand, bias: operand)
        precondition(lb.description.contains("linear"))
        return [mx, mn, pw, li, lb]
    }
}

func testGraphTensorReductions() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2, 3]
        )
        let su = t.sum(axes: [1], keepDimensions: false)
        precondition(su.description.contains("sum"))
        let me = t.mean(axes: [1], keepDimensions: true)
        precondition(me.description.contains("mean"))
        let pr = t.product(axes: [0], keepDimensions: false)
        precondition(pr.description.contains("product"))
        let mi = t.minimum(axes: [0], keepDimensions: true)
        precondition(mi.description.contains("minimum"))
        let ma = t.maximum(axes: [1], keepDimensions: false)
        precondition(ma.description.contains("maximum"))
        let ls = t.logSumExp(axes: [1], keepDimensions: true)
        precondition(ls.description.contains("logSumExp"))
        let sq = t.sumOfSquares(axes: [0], keepDimensions: false)
        precondition(sq.description.contains("sumOfSquares"))
        let l2 = t.l2Norm(axes: [1], keepDimensions: true)
        precondition(l2.description.contains("l2Norm"))
        return [su, me, pr, mi, ma, ls, sq, l2]
    }
}

func testGraphTensorShapeOps() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            dataType: Float.self, shape: [2, 3]
        )
        let sm = t.softmax(axis: 1)
        precondition(sm.description.contains("softmax"))
        let ls = t.logSoftmax(axis: 0)
        precondition(ls.description.contains("logSoftmax"))
        let tr = t.transpose(axes: [1, 0])
        precondition(tr.description.contains("transpose"))
        let cl = t.clip(to: Float(0)...Float(1))
        precondition(cl.description.contains("clip"))
        let th = t.threshold(to: Float(0.5))
        precondition(th.description.contains("threshold"))
        let pd = t.pad(.constant(value: Float(0)), padding: [1, 1, 0, 0])
        precondition(pd.description.contains("pad"))
        let idx = GraphTensorOperandInt32()
        let ga = t.gather(indices: idx, axis: 0, batchDimensionCount: 1)
        precondition(ga.description.contains("gather"))
        let am: BNNSGraph.Builder.Tensor<Int32> = t.argMax(axis: 1, keepDimension: false)
        precondition(am.description.contains("argMax"))
        precondition(am.dataType == Int32.bnnsDataType)
        let an: BNNSGraph.Builder.Tensor<Int32> = t.argMin(axis: 0, keepDimension: true)
        precondition(an.description.contains("argMin"))
        return [sm, ls, tr, cl, th, pd, ga]
    }
}

func testGraphTensorProperties() {
    _ = try? BNNSGraph.makeContext { builder in
        let t: BNNSGraph.Builder.Tensor<Float> = builder.argument(
            name: "props", dataType: Float.self, shape: [4]
        )
        let data: UnsafeMutableRawPointer? = t.tensorData
        precondition(data == nil)
        let text: String = t.description
        precondition(text.contains("props"))
        let chained = t.abs()
        precondition(chained.description.contains("props") && chained.description.contains("abs"))
        let dtype: BNNSDataType? = t.dataType
        precondition(dtype == BNNSDataTypeFloat32)
        precondition(dtype == Float.bnnsDataType)
        return [t, chained]
    }
}
