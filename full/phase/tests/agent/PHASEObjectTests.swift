@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testObjectAxes() {
    expect(PHASEObject.right == simd_float3(1, 0, 0), "right")
    expect(PHASEObject.up == simd_float3(0, 1, 0), "up")
    expect(PHASEObject.forward == simd_float3(0, 0, -1), "forward")
}

func testObjectChildGraph() {
    let engine = PHASEEngine(updateMode: .manual)
    let parent = PHASEObject(engine: engine)
    let child = PHASEObject(engine: engine)
    try! parent.addChild(child)
    expect(parent.children.count == 1, "one child")
    expect(child.parent === parent, "parent link")
    parent.removeChild(child)
    expect(parent.children.isEmpty, "removed")
    expect(child.parent == nil, "cleared")
}

func testObjectRejectsSelfChild() {
    let engine = PHASEEngine(updateMode: .manual)
    let object = PHASEObject(engine: engine)
    do {
        try object.addChild(object)
        preconditionFailure("self child")
    } catch let error as PHASEError {
        expect(error.code == .invalidObject, "invalidObject")
    } catch {
        preconditionFailure("unexpected")
    }
}

func testObjectRejectsCycle() {
    let engine = PHASEEngine(updateMode: .manual)
    let a = PHASEObject(engine: engine)
    let b = PHASEObject(engine: engine)
    try! a.addChild(b)
    do {
        try b.addChild(a)
        preconditionFailure("cycle")
    } catch let error as PHASEError {
        expect(error.code == .invalidObject, "invalidObject")
    } catch {
        preconditionFailure("unexpected")
    }
}

func testObjectRemoveChildren() {
    let engine = PHASEEngine(updateMode: .manual)
    let parent = PHASEObject(engine: engine)
    let c1 = PHASEObject(engine: engine)
    let c2 = PHASEObject(engine: engine)
    try! parent.addChild(c1)
    try! parent.addChild(c2)
    parent.removeChildren()
    expect(parent.children.isEmpty, "cleared")
    expect(c1.parent == nil && c2.parent == nil, "orphaned")
}

func testObjectTransformIdentity() {
    let engine = PHASEEngine(updateMode: .manual)
    let object = PHASEObject(engine: engine)
    expect(object.transform == simd_float4x4.identity, "local identity")
    expect(object.worldTransform == simd_float4x4.identity, "world identity")
}

func testObjectWorldTransformParented() {
    let engine = PHASEEngine(updateMode: .manual)
    let parent = PHASEObject(engine: engine)
    let child = PHASEObject(engine: engine)
    var translated = simd_float4x4.identity
    translated.columns.3 = SIMD4<Float>(4, 0, 0, 1)
    parent.transform = translated
    try! parent.addChild(child)
    expect(child.worldTransform.columns.3.x == 4, "inherited translation")
    var local = simd_float4x4.identity
    local.columns.3 = SIMD4<Float>(1, 0, 0, 1)
    child.transform = local
    expect(abs(child.worldTransform.columns.3.x - 5) < 1e-5, "composed world")
    child.worldTransform = translated
    expect(abs(child.transform.columns.3.x) < 1e-4, "set world undoes parent")
}

func testListenerGainAndFlags() {
    let engine = PHASEEngine(updateMode: .manual)
    let listener = PHASEListener(engine: engine)
    expect(listener.gain == 1, "default gain")
    listener.gain = 0.25
    expect(listener.gain == 0.25, "set gain")
    listener.automaticHeadTrackingFlags = [.orientation]
    expect(listener.automaticHeadTrackingFlags.contains(.orientation), "flags")
}

func testSourceShapesAndGain() {
    let engine = PHASEEngine(updateMode: .manual)
    let source = PHASESource(engine: engine)
    expect(source.gain == 1, "default")
    source.gain = 0.5
    expect(source.gain == 0.5, "set")
    expect(source.shapes.isEmpty, "no shapes")
    let shaped = PHASESource(engine: engine, shapes: [])
    expect(shaped.shapes.isEmpty, "empty shapes")
}

func testOccluderShapes() {
    let engine = PHASEEngine(updateMode: .manual)
    let occluder = PHASEOccluder(engine: engine, shapes: [])
    expect(occluder.shapes.isEmpty, "empty")
}

func testMaterialPresetInit() {
    let engine = PHASEEngine(updateMode: .manual)
    let material = PHASEMaterial(engine: engine, preset: .wood)
    expect(material.preset == .wood, "wood")
}

func testShapeHostElements() {
    let engine = PHASEEngine(updateMode: .manual)
    let shape = PHASEShape(engine: engine, hostElementCount: 2)
    expect(shape.elements.count == 2, "two elements")
    let material = PHASEMaterial(engine: engine, preset: .glass)
    shape.elements[0].material = material
    expect(shape.elements[0].material === material, "assigned")
    expect(shape.elements[1].material == nil, "unset")
}
