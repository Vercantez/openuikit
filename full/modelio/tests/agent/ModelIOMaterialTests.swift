import Foundation
import ModelIO

func testMaterialPropertyValues() {
    let url = URL(fileURLWithPath: "/tmp/tex.png")
    let fromURL = MDLMaterialProperty(name: "u", semantic: .baseColor, url: url)
    mdlCheck(fromURL.type == .URL, "url type")
    mdlCheck(fromURL.urlValue == url, "url value")
    let fromURL2 = MDLMaterialProperty(name: "U", semantic: .baseColor, URL: url)
    mdlCheck(fromURL2.urlValue == url, "URL:")
    let s = MDLMaterialProperty(name: "s", semantic: .none, string: "hello")
    mdlCheck(s.stringValue == "hello" && s.type == .string, "string")
    let f = MDLMaterialProperty(name: "f", semantic: .roughness, float: 0.3)
    mdlCheck(f.floatValue == 0.3 && f.type == .float, "float")
    let f2 = MDLMaterialProperty(name: "f2", semantic: .bump, float2: SIMD2(1, 2))
    mdlCheck(f2.float2Value.y == 2, "float2")
    let f3 = MDLMaterialProperty(name: "f3", semantic: .baseColor, float3: SIMD3(1, 0, 0))
    mdlCheck(f3.float3Value.x == 1, "float3")
    let f4 = MDLMaterialProperty(name: "f4", semantic: .emission, float4: SIMD4(1, 1, 1, 1))
    mdlCheck(f4.float4Value.w == 1, "float4")
    let m = MDLMaterialProperty(name: "m", semantic: .none, matrix4x4: .identity)
    mdlCheck(m.type == .matrix44, "matrix")
    let sampler = MDLTextureSampler()
    let t = MDLMaterialProperty(name: "t", semantic: .baseColor, textureSampler: sampler)
    mdlCheck(t.textureSamplerValue === sampler, "sampler")
    let named = MDLMaterialProperty(name: "n", semantic: .userDefined)
    named.luminance = 4
    mdlCheck(named.luminance == 4, "luminance")
    named.setProperties(f)
    mdlCheck(named.floatValue == 0.3, "setProperties")
    let clone = named.copy() as! MDLMaterialProperty
    mdlCheck(clone.floatValue == 0.3, "copy")
}

func testMaterialProperties() {
    let scattering = MDLPhysicallyPlausibleScatteringFunction()
    let material = MDLMaterial(name: "mat", scatteringFunction: scattering)
    mdlCheck(material.name == "mat", "name")
    mdlCheck(material.scatteringFunction === scattering, "sf")
    material.materialFace = .doubleSided
    mdlCheck(material.materialFace == .doubleSided, "face")
    let prop = MDLMaterialProperty(name: "rough", semantic: .roughness, float: 0.4)
    material.setProperty(prop)
    mdlCheck(material.count == 1, "count")
    mdlCheck(material.propertyNamed("rough")?.floatValue == 0.4, "named")
    mdlCheck(material.property(with: .roughness)?.floatValue == 0.4, "semantic")
    mdlCheck(material.properties(with: .roughness).count == 1, "properties")
    mdlCheck(material[0]?.name == "rough", "idx")
    mdlCheck(material["rough"]?.floatValue == 0.4, "name sub")
    let child = MDLMaterial()
    child.base = material
    mdlCheck(child.base === material, "base")
    let resolver = MDLPathAssetResolver(path: "/tmp")
    material.loadTextures(using: resolver)
    material.resolveTextures(with: resolver)
    material.remove(prop)
    mdlCheck(material.propertyNamed("rough") == nil, "removed")
    material.setProperty(prop)
    material.removeAllProperties()
    mdlCheck(material.count == 0, "cleared")
}

func testScatteringFunction() {
    let fn = MDLScatteringFunction()
    fn.name = "s"
    mdlCheck(fn.name == "s", "name")
    mdlCheck(fn.baseColor.semantic == .baseColor, "baseColor")
    mdlCheck(fn.emission.semantic == .emission, "emission")
    mdlCheck(fn.specular.semantic == .specular, "specular")
    mdlCheck(fn.materialIndexOfRefraction.floatValue == 1.5, "ior")
    mdlCheck(fn.interfaceIndexOfRefraction.floatValue == 1, "iface")
    mdlCheck(fn.normal.semantic == .tangentSpaceNormal, "normal")
    mdlCheck(fn.ambientOcclusion.floatValue == 1, "ao")
    mdlCheck(fn.ambientOcclusionScale.floatValue == 1, "aoScale")
}

func testPlausibleScattering() {
    let fn = MDLPhysicallyPlausibleScatteringFunction()
    mdlCheck(fn.version == 1, "version")
    mdlCheck(fn.subsurface.semantic == .subsurface, "sub")
    mdlCheck(fn.metallic.semantic == .metallic, "metal")
    mdlCheck(fn.specularAmount.semantic == .specular, "specAmt")
    mdlCheck(fn.specularTint.semantic == .specularTint, "tint")
    mdlCheck(fn.roughness.floatValue == 0.5, "rough")
    mdlCheck(fn.anisotropic.semantic == .anisotropic, "aniso")
    mdlCheck(fn.anisotropicRotation.semantic == .anisotropicRotation, "rot")
    mdlCheck(fn.sheen.semantic == .sheen, "sheen")
    mdlCheck(fn.sheenTint.semantic == .sheenTint, "sheenTint")
    mdlCheck(fn.clearcoat.semantic == .clearcoat, "cc")
    mdlCheck(fn.clearcoatGloss.semantic == .clearcoatGloss, "gloss")
}

func testMaterialGraph() {
    let input = MDLMaterialProperty(name: "in", semantic: .roughness, float: 0)
    let output = MDLMaterialProperty(name: "out", semantic: .roughness, float: 0.8)
    let node = MDLMaterialPropertyNode(inputs: [input], outputs: [output]) { node in
        node.outputs[0].floatValue = node.inputs[0].floatValue
    }
    node.name = "n"
    mdlCheck(node.name == "n", "node name")
    mdlCheck(node.inputs.count == 1, "inputs")
    mdlCheck(node.outputs.count == 1, "outputs")
    let connection = MDLMaterialPropertyConnection(output: output, input: input)
    connection.name = "c"
    mdlCheck(connection.name == "c", "conn name")
    mdlCheck(connection.output === output, "output")
    mdlCheck(connection.input === input, "input")
    let graph = MDLMaterialPropertyGraph(nodes: [node], connections: [connection])
    mdlCheck(graph.nodes.count == 1, "nodes")
    mdlCheck(graph.connections.count == 1, "connections")
    graph.evaluate()
    mdlCheck(input.floatValue == 0.8, "evaluated copy")
}
