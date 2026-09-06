import CoreFoundation
import Foundation

/// Linux starting point for Apple's public `OpenGLES` Clang overlay, seeded from
/// the Xcode 26.1 iPhoneOS symbol graph.
///
/// CPU-side types, Khronos token values, EAGL context identity, and a software
/// GLES state machine are real. GPU command execution, CAEAGLLayer drawables,
/// IOSurface texturing, and GLSL compilation stay fail-closed.
public enum OpenGLESModuleInfo {
    public static let moduleName = "OpenGLES"
    public static let renderer = "OpenUIKit software GLES"
}
