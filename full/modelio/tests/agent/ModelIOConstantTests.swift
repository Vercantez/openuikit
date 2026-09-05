import Foundation
import ModelIO

func testVertexAttributeStrings() {
    mdlCheck(MDLVertexAttributeAnisotropy == "anisotropy", "anisotropy")
    mdlCheck(MDLVertexAttributeBinormal == "binormal", "binormal")
    mdlCheck(MDLVertexAttributeBitangent == "bitangent", "bitangent")
    mdlCheck(MDLVertexAttributeColor == "color", "color")
    mdlCheck(MDLVertexAttributeEdgeCrease == "edgeCrease", "edgeCrease")
    mdlCheck(MDLVertexAttributeJointIndices == "jointIndices", "jointIndices")
    mdlCheck(MDLVertexAttributeJointWeights == "jointWeights", "jointWeights")
    mdlCheck(MDLVertexAttributeNormal == "normal", "normal")
    mdlCheck(MDLVertexAttributeOcclusionValue == "occlusionValue", "occlusionValue")
    mdlCheck(MDLVertexAttributePosition == "position", "position")
    mdlCheck(MDLVertexAttributeShadingBasisU == "shadingBasisU", "shadingBasisU")
    mdlCheck(MDLVertexAttributeShadingBasisV == "shadingBasisV", "shadingBasisV")
    mdlCheck(MDLVertexAttributeSubdivisionStencil == "subdivisionStencil", "subdivisionStencil")
    mdlCheck(MDLVertexAttributeTangent == "tangent", "tangent")
    mdlCheck(MDLVertexAttributeTextureCoordinate == "textureCoordinate", "textureCoordinate")
}

func testUTTypeConstants() {
    mdlCheck(!kUTType3dObject.isEmpty, "3d")
    mdlCheck(!kUTTypeAlembic.isEmpty, "abc")
    mdlCheck(!kUTTypePolygon.isEmpty, "polygon")
    mdlCheck(!kUTTypeStereolithography.isEmpty, "stl")
    mdlCheck(!kUTTypeUniversalSceneDescription.isEmpty, "usd")
    mdlCheck(!kUTTypeUniversalSceneDescriptionMobile.isEmpty, "usdz")
    mdlCheck(kUTTypeAlembic != kUTType3dObject, "distinct UTI names")
}
