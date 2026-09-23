// See include/OUKProtocols2Scenario.h. Each delegate records the protocol
// methods UIKit sends; a phase prints the distinct set (sorted) plus the
// observable result, so call counts that are UIKit implementation details
// never enter the comparison.
#import "OUKProtocols2Scenario.h"
#import <objc/runtime.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#if OUK_OPENUIKIT
@import CoreGraphics;
#import "UIKitObjCSupport.h"
#import "OpenUIKit-Swift.h"
#import "OpenUIKitObjCBridge-Swift.h"
#else
#import <UIKit/UIKit.h>
#endif

/* Under OpenUIKit only the protocols converted so far are compiled
 * (Tests/ObjCProtocols2Tests compares exactly those sections); the oracle
 * build compiles everything. */
#if OUK_OPENUIKIT
#define OUK_P2_TEXTFIELD 1
#define OUK_P2_TEXTVIEW 1
#define OUK_P2_NAVIGATION 1
#define OUK_P2_PICKER 1
#define OUK_P2_SEARCHBAR 1
#define OUK_P2_TABBARCONTROLLER 1
#else
#define OUK_P2_TEXTFIELD 1
#define OUK_P2_TEXTVIEW 1
#define OUK_P2_NAVIGATION 1
#define OUK_P2_PICKER 1
#define OUK_P2_SEARCHBAR 1
#define OUK_P2_TABBARCONTROLLER 1
#endif

static OUKProtocols2Sink gSink;
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
/* The protocol methods sent since the last reset, in order, adjacent
 * duplicates collapsed. */
static void emitCalls(const char *label) {
    NSMutableArray *seq = [NSMutableArray array];
    for (NSString *s in gCalls) if (![seq.lastObject isEqualToString:s]) [seq addObject:s];
    emit("%s: %s", label, seq.count ? [seq componentsJoinedByString:@" "].UTF8String : "-");
    [gCalls removeAllObjects];
}
__attribute__((unused)) static const char *B(BOOL b) { return b ? "YES" : "NO"; }
__attribute__((unused)) static const char *S(NSString *s) { return s ? s.UTF8String : "nil"; }

__attribute__((unused)) static UIViewController *titled(NSString *t) { UIViewController *vc = [[UIViewController alloc] initWithNibName:nil bundle:nil]; vc.title = t; return vc; }
__attribute__((unused)) static void settle(void) { [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; }
static const char *const kSections[] = {
    "textfield", "textview", "navigation", "picker", "searchbar", "tabbarcontroller", NULL,
};

#if OUK_P2_TEXTFIELD
// MARK: - UITextFieldDelegate

@interface OUKFieldAll : NSObject <UITextFieldDelegate>
@property (nonatomic) BOOL allowBegin, allowEnd, allowChange, allowReturn;
@end
@implementation OUKFieldAll
- (instancetype)init { if ((self = [super init])) { _allowBegin = _allowEnd = _allowChange = _allowReturn = YES; } return self; }
- (BOOL)textFieldShouldBeginEditing:(UITextField *)f { note(_cmd); return self.allowBegin; }
- (void)textFieldDidBeginEditing:(UITextField *)f { note(_cmd); }
- (BOOL)textFieldShouldEndEditing:(UITextField *)f { note(_cmd); return self.allowEnd; }
- (void)textFieldDidEndEditing:(UITextField *)f { note(_cmd); }
- (void)textFieldDidEndEditing:(UITextField *)f reason:(UITextFieldDidEndEditingReason)reason { note(_cmd); }
- (BOOL)textField:(UITextField *)f shouldChangeCharactersInRange:(NSRange)r replacementString:(NSString *)s {
    note(_cmd); return self.allowChange;
}
- (void)textFieldDidChangeSelection:(UITextField *)f { note(_cmd); }
- (BOOL)textFieldShouldReturn:(UITextField *)f { note(_cmd); return self.allowReturn; }
- (BOOL)textFieldShouldClear:(UITextField *)f { note(_cmd); return YES; }
@end

@interface OUKFieldLegacyEnd : NSObject <UITextFieldDelegate>
@end
@implementation OUKFieldLegacyEnd
- (void)textFieldDidEndEditing:(UITextField *)f { note(_cmd); }
@end

@interface OUKFieldReasonEnd : NSObject <UITextFieldDelegate>
@end
@implementation OUKFieldReasonEnd
- (void)textFieldDidEndEditing:(UITextField *)f reason:(UITextFieldDidEndEditingReason)reason {
    note(_cmd); emit("  reason=%ld", (long)reason);
}
@end

@interface OUKFieldNothing : NSObject <UITextFieldDelegate>
@end
@implementation OUKFieldNothing
@end

static UITextField *newField(UIView *host, id<UITextFieldDelegate> delegate) {
    UITextField *f = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 200, 30)];
    f.delegate = delegate;
    [host addSubview:f];
    return f;
}

static void textFieldSection(UIView *host) {
    OUKFieldAll *all = [OUKFieldAll new];
    UITextField *f = newField(host, all);
    BOOL began = [f becomeFirstResponder];
    emitCalls("all: becomeFirstResponder");
    emit("  returned=%s isFirstResponder=%s editing=%s", B(began), B(f.isFirstResponder), B(f.isEditing));
    [f insertText:@"ab"];
    emitCalls("all: insertText ab");
    emit("  text=%s", S(f.text));
    all.allowChange = NO;
    [f insertText:@"c"];
    emitCalls("all: insertText c (shouldChange NO)");
    emit("  text=%s", S(f.text));
    all.allowChange = YES;
    [f deleteBackward];
    emitCalls("all: deleteBackward");
    emit("  text=%s", S(f.text));
    f.text = @"set";
    emitCalls("all: text= (programmatic)");
    [f insertText:@"\n"];
    emitCalls("all: insertText newline");
    emit("  text=%s", S(f.text));
    all.allowEnd = NO;
    BOOL resigned = [f resignFirstResponder];
    emitCalls("all: resign (shouldEnd NO)");
    emit("  returned=%s isFirstResponder=%s", B(resigned), B(f.isFirstResponder));
    all.allowEnd = YES;
    resigned = [f resignFirstResponder];
    emitCalls("all: resign");
    emit("  returned=%s isFirstResponder=%s", B(resigned), B(f.isFirstResponder));
    all.allowBegin = NO;
    began = [f becomeFirstResponder];
    emitCalls("all: becomeFirstResponder (shouldBegin NO)");
    emit("  returned=%s isFirstResponder=%s", B(began), B(f.isFirstResponder));
    [f removeFromSuperview];

    OUKFieldLegacyEnd *legacyDelegate = [OUKFieldLegacyEnd new];
    UITextField *legacy = newField(host, legacyDelegate);
    [legacy becomeFirstResponder];
    [legacy resignFirstResponder];
    emitCalls("legacy didEndEditing only: begin+resign");
    (void)legacyDelegate;
    [legacy removeFromSuperview];

    OUKFieldReasonEnd *reasonDelegate = [OUKFieldReasonEnd new];
    UITextField *reason = newField(host, reasonDelegate);
    [reason becomeFirstResponder];
    [reason resignFirstResponder];
    emitCalls("reason didEndEditing only: begin+resign");
    (void)reasonDelegate;
    [reason removeFromSuperview];

    OUKFieldNothing *nothing = [OUKFieldNothing new];
    UITextField *plain = newField(host, nothing);
    began = [plain becomeFirstResponder];
    [plain insertText:@"xy"];
    [plain insertText:@"\n"];
    emit("nothing: began=%s text=%s isFirstResponder=%s", B(began), S(plain.text), B(plain.isFirstResponder));
    [plain resignFirstResponder];
    [plain removeFromSuperview];
}

#endif

#if OUK_P2_TEXTVIEW
// MARK: - UITextViewDelegate

@interface OUKViewAll : NSObject <UITextViewDelegate>
@property (nonatomic) BOOL allowBegin, allowChange;
@end
@implementation OUKViewAll
- (instancetype)init { if ((self = [super init])) { _allowBegin = _allowChange = YES; } return self; }
- (BOOL)textViewShouldBeginEditing:(UITextView *)v { note(_cmd); return self.allowBegin; }
- (void)textViewDidBeginEditing:(UITextView *)v { note(_cmd); }
- (BOOL)textViewShouldEndEditing:(UITextView *)v { note(_cmd); return YES; }
- (void)textViewDidEndEditing:(UITextView *)v { note(_cmd); }
- (BOOL)textView:(UITextView *)v shouldChangeTextInRange:(NSRange)r replacementText:(NSString *)t {
    note(_cmd); return self.allowChange;
}
- (void)textViewDidChange:(UITextView *)v { note(_cmd); }
- (void)textViewDidChangeSelection:(UITextView *)v { note(_cmd); }
@end

static void textViewSection(UIView *host) {
    OUKViewAll *all = [OUKViewAll new];
    UITextView *v = [[UITextView alloc] initWithFrame:CGRectMake(10, 60, 200, 80)];
    v.delegate = all;
    [host addSubview:v];
    BOOL began = [v becomeFirstResponder];
    emitCalls("all: becomeFirstResponder");
    emit("  returned=%s isFirstResponder=%s", B(began), B(v.isFirstResponder));
    [v insertText:@"ab"];
    emitCalls("all: insertText ab");
    all.allowChange = NO;
    [v insertText:@"c"];
    emitCalls("all: insertText c (shouldChange NO)");
    emit("  text=%s", S(v.text));
    all.allowChange = YES;
    v.text = @"set";
    emitCalls("all: text= (programmatic)");
    [v resignFirstResponder];
    emitCalls("all: resign");
    all.allowBegin = NO;
    began = [v becomeFirstResponder];
    emitCalls("all: becomeFirstResponder (shouldBegin NO)");
    emit("  returned=%s isFirstResponder=%s", B(began), B(v.isFirstResponder));
    [v removeFromSuperview];
}

#endif

#if OUK_P2_NAVIGATION
// MARK: - UINavigationControllerDelegate

@interface OUKNavShowOnly : NSObject <UINavigationControllerDelegate>
@end
@implementation OUKNavShowOnly
- (void)navigationController:(UINavigationController *)n willShowViewController:(UIViewController *)vc animated:(BOOL)a {
    note(_cmd); emit("  willShow top=%s animated=%s", S(vc.title), B(a));
}
- (void)navigationController:(UINavigationController *)n didShowViewController:(UIViewController *)vc animated:(BOOL)a {
    note(_cmd); emit("  didShow top=%s animated=%s", S(vc.title), B(a));
}
@end

@interface OUKNavAnimNil : OUKNavShowOnly
@end
@implementation OUKNavAnimNil
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)n
                                  animationControllerForOperation:(UINavigationControllerOperation)op
                                               fromViewController:(UIViewController *)from
                                                 toViewController:(UIViewController *)to {
    note(_cmd); emit("  animationController op=%ld", (long)op); return nil;
}
@end



static void navigationSection(UIView *host) {
    for (Class cls in @[[OUKNavShowOnly class], [OUKNavAnimNil class]]) {
        id<UINavigationControllerDelegate> d = [cls new];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:titled(@"root")];
        nav.delegate = d;
        nav.view.frame = host.bounds;
        [host addSubview:nav.view];
        [nav.view layoutIfNeeded];
        settle();
        emitCalls([NSString stringWithFormat:@"%s: shown", class_getName(cls)].UTF8String);
        [nav pushViewController:titled(@"second") animated:NO];
        settle();
        emitCalls([NSString stringWithFormat:@"%s: push unanimated", class_getName(cls)].UTF8String);
        [nav popViewControllerAnimated:NO];
        settle();
        emitCalls([NSString stringWithFormat:@"%s: pop unanimated", class_getName(cls)].UTF8String);
        [nav.view removeFromSuperview];
    }
}

#endif

#if OUK_P2_PICKER
// MARK: - UIPickerView

@interface OUKPickerTitles : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>
@end
@implementation OUKPickerTitles
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)p { note(_cmd); return 1; }
- (NSInteger)pickerView:(UIPickerView *)p numberOfRowsInComponent:(NSInteger)c { note(_cmd); return 3; }
- (NSString *)pickerView:(UIPickerView *)p titleForRow:(NSInteger)r forComponent:(NSInteger)c {
    note(_cmd); return [NSString stringWithFormat:@"row %ld", (long)r];
}
- (void)pickerView:(UIPickerView *)p didSelectRow:(NSInteger)r inComponent:(NSInteger)c { note(_cmd); }
@end

static void pickerSection(UIView *host) {
    OUKPickerTitles *d = [OUKPickerTitles new];
    UIPickerView *p = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 150, 320, 216)];
    p.dataSource = d;
    p.delegate = d;
    [host addSubview:p];
    [p layoutIfNeeded];
    settle();
    NSMutableArray *seen = [NSMutableArray array];
    for (NSString *s in [[NSSet setWithArray:gCalls] allObjects]) [seen addObject:s];
    [gCalls removeAllObjects];
    emit("titles: shown calls (set): %s",
         [[seen sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@" "].UTF8String);
    emit("  components=%ld rows=%ld selected=%ld", (long)p.numberOfComponents,
         (long)[p numberOfRowsInComponent:0], (long)[p selectedRowInComponent:0]);
    [p selectRow:2 inComponent:0 animated:NO];
    emitCalls("titles: selectRow:2 (programmatic)");
    emit("  selected=%ld", (long)[p selectedRowInComponent:0]);
    [p removeFromSuperview];
}

#endif

#if OUK_P2_SEARCHBAR
// MARK: - UISearchBarDelegate

@interface OUKSearchAll : NSObject <UISearchBarDelegate>
@end
@implementation OUKSearchAll
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)b { note(_cmd); return YES; }
- (void)searchBarTextDidBeginEditing:(UISearchBar *)b { note(_cmd); }
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)b { note(_cmd); return YES; }
- (void)searchBarTextDidEndEditing:(UISearchBar *)b { note(_cmd); }
- (void)searchBar:(UISearchBar *)b textDidChange:(NSString *)t { note(_cmd); }
- (BOOL)searchBar:(UISearchBar *)b shouldChangeTextInRange:(NSRange)r replacementText:(NSString *)t { note(_cmd); return YES; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)b { note(_cmd); }
@end

static void searchBarSection(UIView *host) {
    OUKSearchAll *d = [OUKSearchAll new];
    UISearchBar *b = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 380, 320, 56)];
    b.delegate = d;
    [host addSubview:b];
    b.text = @"set";
    emitCalls("all: text= (programmatic)");
    BOOL began = [b becomeFirstResponder];
    emitCalls("all: becomeFirstResponder");
    emit("  returned=%s", B(began));
    [b resignFirstResponder];
    emitCalls("all: resign");
    [b removeFromSuperview];
}

#endif

#if OUK_P2_TABBARCONTROLLER
// MARK: - UITabBarControllerDelegate

@interface OUKTabAll : NSObject <UITabBarControllerDelegate>
@end
@implementation OUKTabAll
- (BOOL)tabBarController:(UITabBarController *)t shouldSelectViewController:(UIViewController *)vc { note(_cmd); return YES; }
- (void)tabBarController:(UITabBarController *)t didSelectViewController:(UIViewController *)vc { note(_cmd); }
@end

static void tabBarControllerSection(UIView *host) {
    OUKTabAll *d = [OUKTabAll new];
    UITabBarController *t = [UITabBarController new];
    t.delegate = d;
    t.viewControllers = @[titled(@"a"), titled(@"b")];
    t.view.frame = host.bounds;
    [host addSubview:t.view];
    [t.view layoutIfNeeded];
    emitCalls("all: shown");
    t.selectedIndex = 1;
    emitCalls("all: selectedIndex=1 (programmatic)");
    emit("  selectedIndex=%ld", (long)t.selectedIndex);
    t.selectedViewController = t.viewControllers[0];
    emitCalls("all: selectedViewController= (programmatic)");
    [t.view removeFromSuperview];
}

#endif

const char *OUKProtocols2Section(int index) {
    return index >= 0 && index < (int)(sizeof kSections / sizeof kSections[0]) ? kSections[index] : NULL;
}

void OUKProtocols2Run(const char *name, void *hostPointer, OUKProtocols2Sink sink, void *context) {
    gSink = sink;
    gContext = context;
    gCalls = [NSMutableArray array];
    UIView *host = (__bridge UIView *)hostPointer;
#if OUK_P2_TEXTFIELD
    if (!strcmp(name, "textfield")) { textFieldSection(host); return; }
#endif
#if OUK_P2_TEXTVIEW
    if (!strcmp(name, "textview")) { textViewSection(host); return; }
#endif
#if OUK_P2_NAVIGATION
    if (!strcmp(name, "navigation")) { navigationSection(host); return; }
#endif
#if OUK_P2_PICKER
    if (!strcmp(name, "picker")) { pickerSection(host); return; }
#endif
#if OUK_P2_SEARCHBAR
    if (!strcmp(name, "searchbar")) { searchBarSection(host); return; }
#endif
#if OUK_P2_TABBARCONTROLLER
    if (!strcmp(name, "tabbarcontroller")) { tabBarControllerSection(host); return; }
#endif
}
