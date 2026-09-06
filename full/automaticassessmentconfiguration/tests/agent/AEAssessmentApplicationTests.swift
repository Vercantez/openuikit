import Foundation
import AutomaticAssessmentConfiguration

func testApplicationType() {
    let application = AEAssessmentApplication(bundleIdentifier: "com.example.exam")
    aacExpect(type(of: application) == AEAssessmentApplication.self, "type")
    let object: NSObject = application
    aacExpect(object === application, "NSObject")
}

func testApplicationInit() {
    let application = AEAssessmentApplication(bundleIdentifier: "com.apple.calculator")
    aacExpect(application.bundleIdentifier == "com.apple.calculator", "stored")
}

func testApplicationBundleIdentifier() {
    let application = AEAssessmentApplication(bundleIdentifier: "edu.example.quiz")
    aacExpect(application.bundleIdentifier == "edu.example.quiz", "get")
}

func testApplicationEqualityByBundle() {
    let a = AEAssessmentApplication(bundleIdentifier: "com.example.a")
    let b = AEAssessmentApplication(bundleIdentifier: "com.example.a")
    let c = AEAssessmentApplication(bundleIdentifier: "com.example.c")
    aacExpect(a.isEqual(b), "same bundle")
    aacExpect(!a.isEqual(c), "different bundle")
    aacExpect(!a.isEqual(NSObject()), "other type")
}
