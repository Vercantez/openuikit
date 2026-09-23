/* OUKProtocolScenario — UIKit's delegate / data-source protocols adopted by
 * Objective-C classes that implement different subsets of the OPTIONAL
 * requirements, run against Apple's UIKit (Tools/oracle2/objcprotocolprobe/
 * run.sh, iOS 26.1 simulator) and against OpenUIKit (Tests/
 * ObjCProtocolTests). What is compared is presence semantics: which optional
 * methods UIKit calls when they are implemented, and what it does when they
 * are not (default section count, row heights, zoom). */
#ifndef OUK_PROTOCOL_SCENARIO_H
#define OUK_PROTOCOL_SCENARIO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*OUKProtocolSink)(const char *line, void *context);

/* "## scroll": UIScrollViewDelegate with only scrollViewDidScroll:, then one
 * with nothing; zooming without viewForZoomingInScrollView:. */
void OUKProtocolScrollScenario(OUKProtocolSink sink, void *context);
/* "## table": UITableViewDataSource with only the two required methods, then
 * numberOfSectionsInTableView: / titles; UITableViewDelegate with and without
 * tableView:heightForRowAtIndexPath: against an explicit rowHeight. */
void OUKProtocolTableScenario(OUKProtocolSink sink, void *context);

#ifdef __cplusplus
}
#endif
#endif
