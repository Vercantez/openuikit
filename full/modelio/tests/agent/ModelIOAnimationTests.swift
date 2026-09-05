import Foundation
import ModelIO

func testAnimatedScalar() {
    let value = MDLAnimatedScalar()
    value.interpolation = .linear
    mdlCheck(!value.isAnimated(), "empty not animated")
    value.setFloat(1, atTime: 0)
    value.setDouble(3, atTime: 2)
    mdlCheck(value.floatValue(atTime: 0) == 1, "t0")
    mdlCheck(abs(value.floatValue(atTime: 1) - 2) < 0.01, "lerp")
    mdlCheck(abs(value.doubleValue(atTime: 2) - 3) < 0.01, "double")
    mdlCheck(value.timeSampleCount == 2, "count")
    mdlCheck(value.keyTimes.count == 2, "keyTimes")
    mdlCheck(value.times.count == 2, "times")
    mdlCheck(value.minimumTime == 0 && value.maximumTime == 2, "range")
    mdlCheck(value.precision == .float, "precision")
    mdlCheck(value.isAnimated(), "animated")
    value.reset(floatArray: [4, 5], atTimes: [0, 1])
    mdlCheck(value.floatArray.count == 2, "floatArray")
    value.reset(doubleArray: [1, 2], atTimes: [0, 1])
    mdlCheck(value.doubleArray.count == 2, "doubleArray")
    let clone = value.copy() as! MDLAnimatedScalar
    mdlCheck(clone.interpolation == value.interpolation, "copy")
    value.clear()
    mdlCheck(value.timeSampleCount == 0, "cleared")
}

func testAnimatedVector2() {
    let value = MDLAnimatedVector2()
    value.setFloat2(SIMD2(0, 0), atTime: 0)
    value.setDouble2(SIMD2(2, 2), atTime: 1)
    mdlCheck(mdlNear(value.float2Value(atTime: 0.5).x, 1), "lerp x")
    _ = value.double2Value(atTime: 1)
    value.reset(float2Array: [SIMD2(1, 1)], atTimes: [0])
    mdlCheck(value.float2Array.count == 1, "arr")
    value.reset(double2Array: [SIMD2(3, 3)], atTimes: [0])
    mdlCheck(value.double2Array[0].x == 3, "darr")
}

func testAnimatedVector3() {
    let value = MDLAnimatedVector3()
    value.setFloat3(SIMD3(0, 0, 0), atTime: 0)
    value.setDouble3(SIMD3(2, 0, 0), atTime: 1)
    mdlCheck(mdlNear(value.float3Value(atTime: 0.5).x, 1), "lerp")
    _ = value.double3Value(atTime: 0)
    value.reset(float3Array: [SIMD3(1, 2, 3)], atTimes: [0])
    mdlCheck(value.float3Array[0].y == 2, "arr")
    value.reset(double3Array: [SIMD3(4, 5, 6)], atTimes: [0])
    mdlCheck(value.double3Array[0].z == 6, "darr")
}

func testAnimatedVector4() {
    let value = MDLAnimatedVector4()
    value.setFloat4(SIMD4(0, 0, 0, 0), atTime: 0)
    value.setDouble4(SIMD4(2, 0, 0, 2), atTime: 1)
    mdlCheck(mdlNear(value.float4Value(atTime: 0.5).x, 1), "lerp")
    _ = value.double4Value(atTime: 1)
    value.reset(float4Array: [SIMD4(1, 1, 1, 1)], atTimes: [0])
    mdlCheck(value.float4Array.count == 1, "arr")
    value.reset(double4Array: [SIMD4(2, 2, 2, 2)], atTimes: [0])
    mdlCheck(value.double4Array[0].w == 2, "darr")
}

func testAnimatedQuaternion() {
    let value = MDLAnimatedQuaternion()
    value.setFloatQuaternion(.identity, atTime: 0)
    value.setDoubleQuaternion(.identity, atTime: 1)
    let q = value.floatQuaternionValue(atTime: 0.5)
    mdlCheck(mdlNear(q.vector.w, 1, eps: 0.05), "identity slerp")
    _ = value.doubleQuaternionValue(atTime: 0)
    value.reset(floatQuaternionArray: [.identity], atTimes: [0])
    mdlCheck(value.floatQuaternionArray.count == 1, "arr")
    value.reset(doubleQuaternionArray: [.identity], atTimes: [0])
    mdlCheck(value.doubleQuaternionArray.count == 1, "darr")
}

func testAnimatedMatrix() {
    let value = MDLAnimatedMatrix4x4()
    value.setFloat4x4(.identity, atTime: 0)
    value.setDouble4x4(.identity, atTime: 1)
    mdlCheck(value.float4x4Value(atTime: 0).columns.0.x == 1, "float")
    mdlCheck(value.double4x4Value(atTime: 1).columns.3.w == 1, "double")
    value.reset(float4x4Array: [.identity], atTimes: [0])
    mdlCheck(value.float4x4Array.count == 1, "arr")
    value.reset(double4Array: [.identity], atTimes: [0])
    mdlCheck(value.double4x4Array.count == 1, "darr")
}

func testAnimatedScalarArray() {
    let array = MDLAnimatedScalarArray(elementCount: 3)
    array.set(floatArray: [1, 2, 3], atTime: 0)
    array.set(doubleArray: [2, 4, 6], atTime: 1)
    mdlCheck(array.elementCount == 3, "count")
    mdlCheck(abs(array.floatArray(atTime: 0.5)[0] - 1.5) < 0.01, "lerp")
    _ = array.doubleArray(atTime: 0)
    array.reset(floatArray: [9], atTimes: [0])
    mdlCheck(array.floatArray.count == 1, "prop")
    array.reset(doubleArray: [8], atTimes: [0])
    mdlCheck(array.doubleArray[0] == 8, "dprop")
    let empty = MDLAnimatedScalarArray()
    mdlCheck(empty.elementCount == 0, "required init")
}

func testAnimatedVector3Array() {
    let array = MDLAnimatedVector3Array(elementCount: 1)
    array.set(float3Array: [SIMD3(1, 0, 0)], atTime: 0)
    array.set(double3Array: [SIMD3(2, 0, 0)], atTime: 1)
    mdlCheck(array.float3Array(atTime: 0)[0].x == 1, "t0")
    _ = array.double3Array(atTime: 1)
    array.reset(float3Array: [SIMD3(3, 0, 0)], atTimes: [0])
    mdlCheck(array.float3Array[0].x == 3, "prop")
    array.reset(double3Array: [SIMD3(4, 0, 0)], atTimes: [0])
    mdlCheck(array.double3Array[0].x == 4, "dprop")
    mdlCheck(MDLAnimatedVector3Array().elementCount == 0, "empty")
}

func testAnimatedQuaternionArray() {
    let array = MDLAnimatedQuaternionArray(elementCount: 1)
    array.set(floatQuaternionArray: [.identity], atTime: 0)
    array.set(doubleQuaternionArray: [.identity], atTime: 1)
    mdlCheck(array.floatQuaternionArray(atTime: 0).count == 1, "t0")
    _ = array.doubleQuaternionArray(atTime: 1)
    array.reset(floatQuaternionArray: [.identity], atTimes: [0])
    mdlCheck(array.floatQuaternionArray.count == 1, "prop")
    array.reset(doubleQuaternionArray: [.identity], atTimes: [0])
    mdlCheck(array.doubleQuaternionArray.count == 1, "dprop")
    mdlCheck(MDLAnimatedQuaternionArray().elementCount == 0, "empty")
}

func testMatrixArray() {
    let array = MDLMatrix4x4Array(elementCount: 2)
    mdlCheck(array.elementCount == 2, "count")
    mdlCheck(array.precision == .float, "precision")
    array.float4x4Array = [.identity, .identity]
    mdlCheck(array.float4x4Array.count == 2, "float")
    array.double4x4Array = [.identity]
    mdlCheck(array.precision == .double, "double precision")
    array.clear()
    mdlCheck(array.float4x4Array.count == 1 || array.elementCount >= 1, "cleared keeps count")
    let clone = array.copy() as! MDLMatrix4x4Array
    mdlCheck(clone.elementCount == array.elementCount, "copy")
}

func testSkeleton() {
    let skeleton = MDLSkeleton(name: "sk", jointPaths: ["/root", "/root/arm"])
    mdlCheck(skeleton.jointPaths.count == 2, "paths")
    mdlCheck(skeleton.jointBindTransforms.elementCount == 2, "bind")
    mdlCheck(skeleton.jointRestTransforms.elementCount == 2, "rest")
    let clone = skeleton.copy() as! MDLSkeleton
    mdlCheck(clone.name == "sk", "copy name")
}

func testPackedJointAnimation() {
    let clip = MDLPackedJointAnimation(name: "walk", jointPaths: ["/root"])
    mdlCheck(clip.jointPaths.count == 1, "paths")
    clip.translations.set(float3Array: [SIMD3()], atTime: 0)
    clip.rotations.set(floatQuaternionArray: [.identity], atTime: 0)
    clip.scales.set(float3Array: [SIMD3(1, 1, 1)], atTime: 0)
    mdlCheck(clip.translations.elementCount == 1, "t")
    let clone = clip.copy() as! MDLPackedJointAnimation
    mdlCheck(clone.name == "walk", "copy")
}

func testAnimationBind() {
    let bind = MDLAnimationBindComponent()
    bind.skeleton = MDLSkeleton(name: "s", jointPaths: ["j"])
    bind.jointAnimation = MDLPackedJointAnimation(name: "a", jointPaths: ["j"])
    bind.jointPaths = ["j"]
    bind.geometryBindTransform = .identity
    mdlCheck(bind.skeleton != nil, "skeleton")
    mdlCheck(bind.jointAnimation != nil, "anim")
    mdlCheck(bind.jointPaths?.first == "j", "paths")
    let clone = bind.copy() as! MDLAnimationBindComponent
    mdlCheck(clone.jointPaths?.first == "j", "copy")
}
