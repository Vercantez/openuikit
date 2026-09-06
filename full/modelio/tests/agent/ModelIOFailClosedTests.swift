import Foundation
import ModelIO

func testMeshBakeFailClosed() {
    let mesh = MDLMesh(
        boxWithExtent: SIMD3(1, 1, 1),
        segments: SIMD3<UInt32>(1, 1, 1),
        inwardNormals: false,
        geometryType: .triangles,
        allocator: nil
    )
    mdlCheck(
        !mesh.generateAmbientOcclusionTexture(
            withQuality: 0.5,
            attenuationFactor: 1,
            objectsToConsider: [],
            vertexAttributeNamed: "ao",
            materialPropertyNamed: "ao"
        ),
        "ao tex quality"
    )
    mdlCheck(
        !mesh.generateAmbientOcclusionTexture(
            withSize: SIMD2<Int32>(4, 4),
            raysPerSample: 1,
            attenuationFactor: 1,
            objectsToConsider: [],
            vertexAttributeNamed: "ao",
            materialPropertyNamed: "ao"
        ),
        "ao tex size"
    )
    mdlCheck(
        !mesh.generateAmbientOcclusionVertexColors(
            withQuality: 0.5,
            attenuationFactor: 1,
            objectsToConsider: [],
            vertexAttributeNamed: "ao"
        ),
        "ao verts quality"
    )
    mdlCheck(
        !mesh.generateAmbientOcclusionVertexColors(
            withRaysPerSample: 1,
            attenuationFactor: 1,
            objectsToConsider: [],
            vertexAttributeNamed: "ao"
        ),
        "ao verts rays"
    )
    mdlCheck(
        !mesh.generateLightMapTexture(
            withQuality: 0.5,
            lightsToConsider: [],
            objectsToConsider: [],
            vertexAttributeNamed: "lm",
            materialPropertyNamed: "lm"
        ),
        "lm tex quality"
    )
    mdlCheck(
        !mesh.generateLightMapTexture(
            withTextureSize: SIMD2<Int32>(4, 4),
            lightsToConsider: [],
            objectsToConsider: [],
            vertexAttributeNamed: "lm",
            materialPropertyNamed: "lm"
        ),
        "lm tex size"
    )
    mdlCheck(
        !mesh.generateLightMapVertexColorsWithLights(
            toConsider: [],
            objectsToConsider: [],
            vertexAttributeNamed: "lm"
        ),
        "lm verts"
    )
}
