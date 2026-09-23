/* OUKSurfaceScenario — the Objective-C surface a real app's Objective-C
 * code uses on UIFont, CALayer and UIColor.CGColor, run the same way against
 * Apple's UIKit (Tools/oracle2/objcsurfaceprobe/run.sh, iOS 26.1 simulator)
 * and against OpenUIKit (Tests/ObjCSurfaceTests on the Apple toolchain,
 * uikit/scripts/objc_surface_guest_probe.sh under machorun + objc4).
 *
 * The API is plain C (a line sink), so the Foundation-hidden Mach-O guest,
 * which has objc4 but no NSString, can drive it too. OUK_NO_FOUNDATION
 * (the guest) leaves out every line that needs NSString, CoreGraphics'
 * CGColor or a UIView subclass. */
#ifndef OUK_SURFACE_SCENARIO_H
#define OUK_SURFACE_SCENARIO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*OUKSurfaceSink)(const char *line, void *context);

/* "## superclasses": class_getSuperclass facts for the converted classes. */
void OUKSurfaceSuperclassFacts(OUKSurfaceSink sink, void *context);
/* "## font": UIFont factories, equality/hash, a category on UIFont. */
void OUKSurfaceFontScenario(OUKSurfaceSink sink, void *context);
/* "## layer": a plain CALayer's defaults and geometry, and the sublayer tree. */
void OUKSurfaceLayerScenario(OUKSurfaceSink sink, void *context);
/* "## layersubclass": an Objective-C subclass of CALayer (init,
 * layoutSublayers) and, with Foundation, a UIView whose +layerClass is it. */
void OUKSurfaceLayerSubclassScenario(OUKSurfaceSink sink, void *context);
#ifndef OUK_NO_FOUNDATION
/* "## cgcolor": UIColor.CGColor and CALayer's CGColorRef properties. */
void OUKSurfaceColorScenario(OUKSurfaceSink sink, void *context);
#endif

#ifdef __cplusplus
}
#endif
#endif
