/* OUKProtocols2Scenario — the second set of UIKit delegate / data-source
 * protocols as Objective-C adopters implementing different subsets of the
 * OPTIONAL requirements (UITextFieldDelegate, UITextViewDelegate,
 * UINavigationControllerDelegate, UIPickerViewDataSource/Delegate,
 * UISearchBarDelegate, UITabBarControllerDelegate, UIGestureRecognizerDelegate),
 * run inside a real app against Apple's UIKit (Tools/oracle2/
 * objcprotocolprobe2/run.sh, iOS 26.1 simulator) and against OpenUIKit
 * (Tests/ObjCProtocols2Tests). Compared: which optional methods UIKit sends
 * when implemented, and what it does when they are not. */
#ifndef OUK_PROTOCOLS2_SCENARIO_H
#define OUK_PROTOCOLS2_SCENARIO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*OUKProtocols2Sink)(const char *line, void *context);

/* Section names in transcript order; NULL past the last. */
const char *OUKProtocols2Section(int index);
/* Runs section `name` in `host` (a view in a key window), emitting lines. */
void OUKProtocols2Run(const char *name, void *host, OUKProtocols2Sink sink, void *context);

#ifdef __cplusplus
}
#endif
#endif
