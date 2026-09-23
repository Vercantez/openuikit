// See include/OUKProtocolScenario.h. Each delegate / data source below is an
// Objective-C class adopting UIKit's protocol with a different subset of the
// OPTIONAL requirements. Lines record results (row geometry, section count,
// zoom) and the SET of protocol methods UIKit sent in a phase (sorted, no
// counts where UIKit's call count is an implementation detail).
#import "OUKProtocolScenario.h"
#include <stdarg.h>
#include <stdio.h>

#if OUK_OPENUIKIT
@import CoreGraphics;
#import "UIKitObjCSupport.h"
#import "OpenUIKit-Swift.h"
#import "OpenUIKitObjCBridge-Swift.h"
#else
#import <UIKit/UIKit.h>
#endif

static OUKProtocolSink gSink;
static void *gContext;
static NSMutableArray<NSString *> *gCalls;

static void emit(const char *format, ...) __attribute__((format(printf, 1, 2)));
static void emit(const char *format, ...) {
    char line[768];
    va_list args;
    va_start(args, format);
    vsnprintf(line, sizeof line, format, args);
    va_end(args);
    gSink(line, gContext);
}

static void note(SEL sel) { [gCalls addObject:NSStringFromSelector(sel)]; }
static int count(SEL sel) {
    int n = 0;
    for (NSString *s in gCalls) n += [s isEqualToString:NSStringFromSelector(sel)];
    return n;
}
/* The distinct protocol methods sent since the last reset, sorted. */
static void emitCalls(const char *label) {
    NSArray *set = [[[NSSet setWithArray:gCalls] allObjects] sortedArrayUsingSelector:@selector(compare:)];
    emit("%s calls: %s", label, [set componentsJoinedByString:@" "].UTF8String);
    [gCalls removeAllObjects];
}

// MARK: - Scroll view delegates

@interface OUKDidScrollOnly : NSObject <UIScrollViewDelegate>
@end
@implementation OUKDidScrollOnly
- (void)scrollViewDidScroll:(UIScrollView *)scrollView { note(_cmd); }
@end

@interface OUKNoMethods : NSObject <UIScrollViewDelegate>
@end
@implementation OUKNoMethods
@end

@interface OUKZoomDelegate : NSObject <UIScrollViewDelegate>
@property (nonatomic, strong) UIView *zoomView;
@end
@implementation OUKZoomDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { note(_cmd); return self.zoomView; }
- (void)scrollViewDidZoom:(UIScrollView *)scrollView { note(_cmd); }
@end

void OUKProtocolScrollScenario(OUKProtocolSink sink, void *context) {
    gSink = sink; gContext = context; gCalls = [NSMutableArray array];
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    scroll.contentSize = CGSizeMake(100, 1000);
    OUKDidScrollOnly *didScroll = [OUKDidScrollOnly new];
    scroll.delegate = didScroll;
    [gCalls removeAllObjects];
    [scroll setContentOffset:CGPointMake(0, 50) animated:NO];
    emit("didScrollOnly setContentOffset 50: didScroll=%d offset=%g", count(@selector(scrollViewDidScroll:)),
         scroll.contentOffset.y);
    [gCalls removeAllObjects];
    [scroll setContentOffset:CGPointMake(0, 50) animated:NO];
    emit("didScrollOnly same offset again: didScroll=%d", count(@selector(scrollViewDidScroll:)));
    [gCalls removeAllObjects];
    scroll.contentOffset = CGPointMake(0, 80);
    emit("didScrollOnly contentOffset= 80: didScroll=%d", count(@selector(scrollViewDidScroll:)));
    emitCalls("didScrollOnly");

    OUKNoMethods *none = [OUKNoMethods new];
    scroll.delegate = none;
    scroll.contentOffset = CGPointMake(0, 120);
    emit("noMethods contentOffset= 120: offset=%g", scroll.contentOffset.y);

    // Zoom without viewForZoomingInScrollView: UIKit has nothing to zoom.
    scroll.delegate = didScroll;
    scroll.minimumZoomScale = 1;
    scroll.maximumZoomScale = 3;
    [gCalls removeAllObjects];
    [scroll setZoomScale:2 animated:NO];
    emit("zoom without viewForZooming: zoomScale=%g contentSize={%g, %g}", scroll.zoomScale,
         scroll.contentSize.width, scroll.contentSize.height);
    emitCalls("zoom without viewForZooming");

    UIScrollView *zoomer = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [zoomer addSubview:content];
    zoomer.contentSize = CGSizeMake(100, 100);
    zoomer.minimumZoomScale = 1;
    zoomer.maximumZoomScale = 3;
    OUKZoomDelegate *zoomDelegate = [OUKZoomDelegate new];
    zoomDelegate.zoomView = content;
    zoomer.delegate = zoomDelegate;
    [gCalls removeAllObjects];
    [zoomer setZoomScale:2 animated:NO];
    emit("zoom with viewForZooming: zoomScale=%g contentSize={%g, %g} content.frame={%g, %g}",
         zoomer.zoomScale, zoomer.contentSize.width, zoomer.contentSize.height,
         content.frame.size.width, content.frame.size.height);
    emit("zoom with viewForZooming: didZoom sent=%s", count(@selector(scrollViewDidZoom:)) > 0 ? "YES" : "NO");
    [gCalls removeObject:NSStringFromSelector(@selector(scrollViewDidZoom:))];
    emitCalls("zoom with viewForZooming (besides didZoom)");
}

// MARK: - Table view data sources and delegates

@interface OUKMinimalSource : NSObject <UITableViewDataSource>
@end
@implementation OUKMinimalSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    note(_cmd); return 3;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    note(_cmd);
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = @"Row";
    return cell;
}
@end

@interface OUKSectionsSource : OUKMinimalSource
@end
@implementation OUKSectionsSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { note(_cmd); return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    note(_cmd); return 2;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    note(_cmd); return section == 0 ? @"First" : @"Second";
}
@end

@interface OUKSelectOnlyDelegate : NSObject <UITableViewDelegate>
@end
@implementation OUKSelectOnlyDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { note(_cmd); }
@end

@interface OUKHeightDelegate : NSObject <UITableViewDelegate>
@end
@implementation OUKHeightDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    note(_cmd);
    return indexPath.row == 0 ? 60 : indexPath.row == 1 ? UITableViewAutomaticDimension : 50;
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath { note(_cmd); }
@end

static void emitRows(const char *label, UITableView *table) {
    NSInteger sections = [table numberOfSections];
    NSMutableString *rows = [NSMutableString string];
    for (NSInteger s = 0; s < sections; s++) {
        for (NSInteger r = 0; r < [table numberOfRowsInSection:s]; r++) {
            CGRect rect = [table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:s]];
            [rows appendFormat:@"%s[%ld,%ld] y=%g h=%g", rows.length ? " " : "", (long)s, (long)r,
                               rect.origin.y, rect.size.height];
        }
    }
    emit("%s sections=%ld %s", label, (long)sections, rows.UTF8String);
}

static UITableView *laidOutTable(UITableViewStyle style, id<UITableViewDataSource> source,
                                 id<UITableViewDelegate> delegate, CGFloat rowHeight) {
    UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 600) style:style];
    if (rowHeight > 0) table.rowHeight = rowHeight;
    table.delegate = delegate;
    table.dataSource = source;
    [table reloadData];
    [table layoutIfNeeded];
    return table;
}

void OUKProtocolTableScenario(OUKProtocolSink sink, void *context) {
    gSink = sink; gContext = context; gCalls = [NSMutableArray array];
    OUKMinimalSource *minimal = [OUKMinimalSource new];
    OUKSectionsSource *sections = [OUKSectionsSource new];
    OUKSelectOnlyDelegate *selectOnly = [OUKSelectOnlyDelegate new];
    OUKHeightDelegate *height = [OUKHeightDelegate new];

    UITableView *t1 = laidOutTable(UITableViewStylePlain, minimal, nil, 0);
    emit("required-only source, no delegate: rowHeight=%g", t1.rowHeight);
    emitRows("required-only source, no delegate:", t1);
    emitCalls("required-only source, no delegate");

    UITableView *t2 = laidOutTable(UITableViewStylePlain, minimal, selectOnly, 70);
    emitRows("rowHeight 70, delegate without heightForRow:", t2);
    emitCalls("rowHeight 70, delegate without heightForRow");

    UITableView *t3 = laidOutTable(UITableViewStylePlain, minimal, height, 70);
    emitRows("rowHeight 70, heightForRow 60/automatic/50:", t3);
    emitCalls("rowHeight 70, heightForRow 60/automatic/50");

    UITableView *t4 = laidOutTable(UITableViewStylePlain, sections, nil, 44);
    emitRows("numberOfSections 2 + titles, plain, rowHeight 44:", t4);
    emitCalls("numberOfSections 2 + titles, plain");
    (void)t1; (void)t2; (void)t3; (void)t4;
}
