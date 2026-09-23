/* OUKKioskRowsScenario — the UIKit surface Eidolon's Kiosk target and its
 * Objective-C pods (DZNWebViewController, SDWebImage, SVProgressHUD,
 * XNGMarkdownParser, ARTiledImageView, Artsy+UIFonts) still missed on the
 * iOS triple (docs/agent_reports/eidolon-kiosk.md), each line shaped like the
 * caller's own use. Run against Apple's UIKit inside a UIApplicationMain app
 * by Tools/oracle2/kioskrowsprobe/run.sh (iOS 26.1 simulator ->
 * transcript-ios26.1.txt) and against OpenUIKit by Tests/KioskRowsTests,
 * which compares line for line. */
#ifndef OUK_KIOSK_ROWS_SCENARIO_H
#define OUK_KIOSK_ROWS_SCENARIO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*OUKKioskRowsSink)(const char *line, void *context);

/* Section names in transcript order; NULL past the last. */
const char *_Nullable OUKKioskRowsSection(int index);
/* The font file the "font" section registers the way Artsy+UIFonts does
 * (EBGaramond12-Regular.ttf of Artsy+UIFonts 3.1.3). */
void OUKKioskRowsSetFontPath(const char *path);
/* Runs section `name`, emitting its lines. */
void OUKKioskRowsRun(const char *name, OUKKioskRowsSink sink, void *context);

#ifdef __cplusplus
}
#endif
#endif
