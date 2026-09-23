/* OUKPodSurfaceScenario — the UIKit Objective-C surface Eidolon's CocoaPods
 * use (FLKAutoLayout, ORStackView, Artsy+UILabels, Artsy-UIButtons,
 * SDWebImage, UIImageViewAligned, NJKWebViewProgress, XNGMarkdownParser),
 * each line shaped like the pod's own call. Run against Apple's UIKit by
 * Tools/oracle2/podsurfaceprobe/run.sh (iOS 26.1 simulator ->
 * transcript-ios26.1.txt) and against OpenUIKit by Tests/PodSurfaceTests,
 * which compares line for line. */
#ifndef OUK_POD_SURFACE_SCENARIO_H
#define OUK_POD_SURFACE_SCENARIO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*OUKPodSurfaceSink)(const char *line, void *context);

/* Section names in transcript order; NULL past the last. */
const char *_Nullable OUKPodSurfaceSection(int index);
/* Runs section `name` ("view", "label", ...), emitting its lines. */
void OUKPodSurfaceRun(const char *name, OUKPodSurfaceSink sink, void *context);

#ifdef __cplusplus
}
#endif
#endif
