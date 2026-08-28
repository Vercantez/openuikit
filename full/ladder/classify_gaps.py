#!/usr/bin/env python3
"""Split each app's missing UIKit types into BLOCKING vs STUB-ABLE.

THIS COLUMN IS JUDGEMENT, AND IT IS LABELLED AS JUDGEMENT. Everything else in
`full/ladder/` is a count; this is an opinion about each type, applied
uniformly by rule so it can be argued with rather than re-guessed per app. The
rules and the reasoning are here in full; disagree by editing this file.

WHY IT IS WORTH HAVING. The corpus-level number is that 220 distinct UIKit
types are referenced across the four census apps, 116 implemented and 104
missing -- and yet frequency-weighted coverage is 91.5%. The missing 104 are
the demand TAIL. A tail is only actionable once you know which of its entries
are walls, so the question per app is not "how many types are missing" but
"which of MY missing types can be a no-op".

THE TEST, stated once and applied everywhere:

  STUB-ABLE  a compiling no-op (or a call-recording no-op, or an object that
             honestly reports "unavailable") leaves the app's SCREENS and its
             STATE MACHINE correct. Typically: hardware with no portable
             referent, system UI we cannot reproduce anyway, or a pure
             optimisation.

  BLOCKING   a no-op changes what appears on screen, drops rows, or wedges the
             app -- a container whose children never present, a layout engine
             that puts cells nowhere, a transition whose completion callback
             never fires, a data source that yields nothing.

THREE CALLS THAT COULD HONESTLY GO EITHER WAY, named rather than buried:
  * `UIPasteboard` -- called STUB-ABLE because a PROCESS-LOCAL pasteboard is
    real, cheap and correct for everything except cross-app copy. Called
    blocking if the app under test is a clipboard manager.
  * `UIViewPropertyAnimator` -- called BLOCKING because apps drive state from
    its completion handler; a no-op that completes INSTANTLY would be
    stub-able, one that never completes wedges the app. The distinction is in
    the stub, not the type.
  * `UIMenuController` / `UIEditMenuInteraction` -- called BLOCKING (visible
    UI), but iOS 26 draws the menu platter in the render server where neither
    oracle can capture it (docs/KNOWN_GAPS.md), so "blocking" here means
    "blocks the app", not "blocks a pixel gate".

    ./classify_gaps.py <ladder-census.json> <uikit-union.json> <out.json>
"""
import json, re, sys
from collections import defaultdict

FREE = {"NSCoder", "NSObject", "NSString", "NSValue"}
OOS = {"UINib", "UIStoryboard", "UIStoryboardSegue", "UIWebView"}

# --- STUB-ABLE: no portable referent, or system UI, or pure optimisation ----
STUB_EXACT = {
    # haptics -- no hardware to drive
    "UIImpactFeedbackGenerator", "UINotificationFeedbackGenerator",
    "UISelectionFeedbackGenerator", "UIFeedbackGenerator",
    # home-screen shortcuts -- there is no home screen
    "UIApplicationShortcutItem", "UIApplicationShortcutIcon",
    "UIMutableApplicationShortcutItem",
    # pasteboard -- see the named judgement call above
    "UIPasteboard", "UIPasteControl", "UIPasteConfiguration",
    # scene / activity plumbing the app does not read back
    "UISceneConfiguration", "UIOpenURLContext", "UIUserActivityRestoring",
    "UIViewControllerRestoration", "UIWindowSceneDestructionRequestOptions",
    # system pickers -- system UI we cannot reproduce; report "unavailable"
    "UIImagePickerController", "UIImagePickerControllerDelegate",
    "UIDocumentPickerViewController", "UIDocumentPickerDelegate",
    "UIDocumentMenuViewController", "UIColorPickerViewController",
    "UIColorPickerViewControllerDelegate", "UIActivityViewController",
    "UIReferenceLibraryViewController", "UIDocumentInteractionControllerDelegate",
    # device services with no host analogue
    "UITextChecker", "UILocalizedIndexedCollation", "UIInputViewAudioFeedback",
    "UILocalNotification", "UITextInputPasswordRules", "UITextInputMode",
    "NSItemProvider", "UIScreenshotService", "UIScreenshotServiceDelegate",
    # prefetching -- pure optimisation, correctness is unaffected
    "UICollectionViewDataSourcePrefetching", "UITableViewDataSourcePrefetching",
    # accessibility -- the app still renders and still works
    "UIAccessibilityCustomAction", "UIAccessibilityElement",
    "UIScrollViewAccessibilityDelegate", "UILargeContentViewerInteraction",
    # focus engine (tvOS-shaped); motion effects (parallax polish)
    "UIFocusGuide", "UIFocusUpdateContext", "UIFocusAnimationCoordinator",
    "UICollectionViewFocusUpdateContext", "UIInterpolatingMotionEffect",
    "UIMotionEffectGroup",
    # UIKit Dynamics -- decorative physics
    "UIDynamicAnimator", "UISnapBehavior", "UIPushBehavior", "UIAttachmentBehavior",
    # printing, the two that are not UIPrint*-prefixed
    "UIViewPrintFormatter", "UISimpleTextPrintFormatter",
}
# Prefix families that are stub-able wholesale.
STUB_PREFIX = (
    "UIPointer",          # no pointer device off-device
    "UIDrag", "UIDrop",   # no drag session off-device
    "UIPrint",            # no printer
    "UIPencil", "UIScribble",
    "UIFind", "UISearchToken", "UITextSearchOptions",
)
STUB_CONTAINS = ("DragDelegate", "DropDelegate", "DropCoordinator", "DropProposal",
                 "DragPreview", "PreviewParameters")

# --- BLOCKING: structure or pixels ----------------------------------------
BLOCK_PREFIX = (
    "NSCollectionLayout", "UICollectionViewCompositionalLayout",
    "NSDiffableDataSource", "UITableViewDiffableDataSource",
    "UICollectionViewDiffableDataSource",
    "NSText",             # the whole TextKit family
    "UIText",             # text input system (UIText* not caught by STUB above)
    "UIVisualEffect", "UIBlurEffect", "UIVibrancyEffect", "UIGlass",
    "UIPageViewController", "UISplitViewController", "UISearchController",
    "UISearchResultsUpdating", "UICalendarView", "UICalendarSelection",
    "UIContentConfiguration", "UIContentView", "UIListContentConfiguration",
    "UIBackgroundConfiguration", "UICellConfigurationState", "UIConfigurationState",
    "UICollectionViewListCell", "UICellAccessory", "UICollectionLayoutList",
    "UIMenu", "UIEditMenu", "UICommandAlternate", "UIResponderStandardEditActions",
    "UIContextualAction", "UISwipeActionsConfiguration", "UITableViewRowAction",
    "UIViewControllerTransitionCoordinator", "UIPercentDrivenInteractiveTransition",
    "UIViewControllerInteractiveTransitioning", "UIViewPropertyAnimator",
    "UIViewImplicitlyAnimating", "UISpringTimingParameters", "UICubicTimingParameters",
)
BLOCK_EXACT = {
    "UISwipeGestureRecognizer", "UIPinchGestureRecognizer", "UIRotationGestureRecognizer",
    "UICollectionViewController", "UIContentContainer", "UICoordinateSpace",
    "UIImageAsset", "NSDataAsset", "NSIndexPath", "UIDatePicker",
    "UICollectionViewLayoutInvalidationContext", "UICollectionViewUpdateItem",
    "UICollectionViewFlowLayoutInvalidationContext", "UIInputView",
    "NSToolbarItem", "NSMenuToolbarItem", "UIBarButtonItemGroup",
    "UIBarButtonItemAppearance", "UITabBarItemAppearance", "UIBarItem",
    "UIBarPositioning", "UINavigationBarDelegate", "UIToolbarDelegate",
    "UITab", "UITabAccessory", "UITitlebar", "UICornerConfiguration", "UICornerRadius",
    "UIScrollEdgeEffect", "UIScrollEdgeElementContainerInteraction",
    "UIBackgroundExtensionView", "UIPopoverPresentationControllerSourceItem",
    "UIPreviewTarget", "UITargetedPreview", "UIContentSizeCategoryAdjusting",
    "UIActionSheetDelegate", "UISplitViewControllerDelegate",
    "UIPageViewControllerDelegate", "UIPageViewControllerDataSource",
    "UISearchControllerDelegate", "UIMenuBuilder", "UIMenuSystem",
    "UITraitUserInterfaceIdiom", "UITraitLegibilityWeight", "UITraitLayoutDirection",
    "UITraitTabAccessoryEnvironment", "NSStringDrawingContext", "NSAdaptiveImageGlyph",
    "NSLayoutManager", "NSLayoutManagerDelegate",
}


def klass(t):
    if t in STUB_EXACT:
        return "stub-able"
    if any(t.startswith(p) for p in STUB_PREFIX):
        return "stub-able"
    if any(c in t for c in STUB_CONTAINS):
        return "stub-able"
    if t in BLOCK_EXACT:
        return "blocking"
    if any(t.startswith(p) for p in BLOCK_PREFIX):
        return "blocking"
    return "unclassified"


def main():
    L = json.load(open(sys.argv[1]))["apps"]
    U = json.load(open(sys.argv[2]))["types"]

    out = {"_note": "JUDGEMENT column -- see classify_gaps.py docstring", "apps": {}}
    for a, v in sorted(L.items()):
        buckets = defaultdict(list)
        for t, c in v["uikit"]["missing"]:
            if t in FREE or t in OOS:
                continue
            buckets[klass(t)].append((t, c))
        for k in buckets:
            buckets[k].sort(key=lambda x: -x[1])
        out["apps"][a] = {k: {"types": len(v2), "uses": sum(c for _, c in v2),
                              "list": v2} for k, v2 in buckets.items()}

    print(f"{'app':<20}{'BLOCKING':>10}{'uses':>7}{'stub-able':>11}{'uses':>7}"
          f"{'unclf':>7}{'uses':>7}   biggest BLOCKING")
    for a, b in out["apps"].items():
        bl = b.get("blocking", {"types": 0, "uses": 0, "list": []})
        st = b.get("stub-able", {"types": 0, "uses": 0})
        un = b.get("unclassified", {"types": 0, "uses": 0})
        top = ", ".join(f"{t}({c})" for t, c in bl["list"][:4])
        print(f"{a:<20}{bl['types']:>10}{bl['uses']:>7}{st['types']:>11}{st['uses']:>7}"
              f"{un['types']:>7}{un['uses']:>7}   {top}")

    # Union, so the punch list can be ordered by "blocking for how many apps".
    ua, uu = defaultdict(set), defaultdict(int)
    for t, d in U.items():
        if d["ours"] or t in FREE or t in OOS:
            continue
        ua[klass(t)].add(t)
        uu[klass(t)] += d["uses"]
    print(f"\nUNION over {len(L)} apps:")
    for k in ("blocking", "stub-able", "unclassified"):
        print(f"  {k:<14}{len(ua[k]):>4} types{uu[k]:>7} uses")
    blocking_by_apps = sorted(
        ((t, U[t]["apps"], U[t]["uses"]) for t in ua["blocking"]),
        key=lambda x: (-x[1], -x[2]))
    print("\n  BLOCKING types by app-reach:")
    for t, ap, us in blocking_by_apps[:25]:
        print(f"    {t:<44}{ap:>3}{us:>7}")
    out["_union"] = {k: {"types": sorted(ua[k]), "uses": uu[k]} for k in ua}
    json.dump(out, open(sys.argv[3], "w"), indent=1)


main()
