import Foundation
import ModelIO

func testNamedProtocol() {
    let named: any MDLNamed = MDLObject()
    named.name = "named"
    mdlCheck(named.name == "named", "MDLNamed.name")
}

func testComponentProtocol() {
    let component: any MDLComponent = MDLAnimationBindComponent()
    mdlCheck(component is MDLAnimationBindComponent, "MDLComponent")
}

func testJointAnimationProtocol() {
    let animation: any MDLJointAnimation = MDLPackedJointAnimation(name: "a", jointPaths: ["j"])
    mdlCheck(animation is MDLPackedJointAnimation, "MDLJointAnimation")
}

func testAssetResolverProtocol() {
    let resolver: any MDLAssetResolver = MDLPathAssetResolver(path: "/tmp")
    mdlCheck(!resolver.canResolveAssetNamed("missing-modelio-asset"), "missing")
    let url = resolver.resolveAssetNamed("file.bin")
    mdlCheck(url.path.contains("file.bin"), "resolve")
}
