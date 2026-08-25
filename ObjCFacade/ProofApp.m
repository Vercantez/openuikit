/* ProofApp.m — an Objective-C application built against OpenUIKit.
 *
 * It is the proof obligation for the whole prototype:
 *   * builds a view hierarchy out of UIView / UILabel / UIButton,
 *   * SUBCLASSES UIView and overrides -layoutSubviews AND -drawRect:,
 *   * wires target-action with a real @selector, and fires it,
 *   * renders to PNG through OpenUIKit's own renderer.
 *
 * Sources/objcparity/main.swift builds the SAME screen in Swift. The two PNGs
 * must be byte-identical; scripts/objc_facade_verify.sh checks that.
 *
 * Nothing in this file is bridge plumbing. It is what an app author writes.
 */

#import "UIKit.h"

#pragma mark - A UIView subclass, in Objective-C

@interface CardView : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic) NSInteger layoutPasses;
@end

@implementation CardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text = @"Card laid out by ObjC";
    _titleLabel.textColor = [UIColor colorWithRed:0.06 green:0.07 blue:0.11 alpha:1];
    [_titleLabel setFontOfSize:17 weight:OUKFontWeightSemibold];
    [self addSubview:_titleLabel];

    _bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _bodyLabel.text = @"-layoutSubviews positioned these.";
    _bodyLabel.textColor = [UIColor colorWithRed:0.36 green:0.38 blue:0.44 alpha:1];
    [_bodyLabel setFontOfSize:13 weight:OUKFontWeightRegular];
    [self addSubview:_bodyLabel];

    return self;
}

/* THE OVERRIDE. Called by OpenUIKit's Swift layout pass, through the C ABI,
 * through objc_msgSend. `[super layoutSubviews]` reaches the Swift
 * implementation. */
- (void)layoutSubviews {
    [super layoutSubviews];
    _layoutPasses++;
    CGRect b = self.bounds;
    _titleLabel.frame = CGRectMake(16, 14, CGRectGetWidth(b) - 32, 22);
    _bodyLabel.frame  = CGRectMake(16, 40, CGRectGetWidth(b) - 32, 18);
}

/* THE OTHER OVERRIDE. Called from OpenUIKit's render pass with the Swift
 * graphics context already pushed, so UIKit's own drawing spelling works. */
- (void)drawRect:(CGRect)rect {
    [[UIColor colorWithRed:0.20 green:0.45 blue:0.85 alpha:1] setFill];
    UIRectFill(CGRectMake(16, 70, CGRectGetWidth(rect) - 32, 4));

    openuikit_gc_fill_rounded_rect(16, 86, 120, 34, 8,
                                   0.20, 0.45, 0.85, 0.30);
}
@end

#pragma mark - A target-action target, in Objective-C

@interface Screen : NSObject
@property (nonatomic, strong) UIView *root;
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) CardView *card;
@property (nonatomic, strong) UIButton *button;
- (void)build;
- (void)buttonTapped:(id)sender;
@end

@implementation Screen

- (void)build {
    _root = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    _root.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];

    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(16, 20, 288, 30)];
    header.text = @"Objective-C on OpenUIKit";
    header.textColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.07 alpha:1];
    [header setFontOfSize:22 weight:OUKFontWeightSemibold];
    [_root addSubview:header];

    _card = [[CardView alloc] initWithFrame:CGRectMake(16, 64, 288, 150)];
    _card.backgroundColor = [UIColor colorWithRed:0.92 green:0.94 blue:0.98 alpha:1];
    _card.cornerRadius = 14;
    _card.clipsToBounds = YES;
    [_root addSubview:_card];

    _button = [UIButton buttonWithType:UIButtonTypeSystem];
    _button.frame = CGRectMake(16, 232, 180, 44);
    _button.tag = 7;
    [_button setTitle:@"Send action" forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor colorWithRed:0 green:0.48 blue:1 alpha:1]
                  forState:UIControlStateNormal];
    /* A real selector. No dispatch table — the ObjC runtime has one. */
    [_button addTarget:self action:@selector(buttonTapped:)
      forControlEvents:UIControlEventTouchUpInside];
    [_root addSubview:_button];

    _status = [[UILabel alloc] initWithFrame:CGRectMake(16, 288, 288, 22)];
    _status.text = @"(no action yet)";
    _status.textColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.38 alpha:1];
    [_status setFontOfSize:15 weight:OUKFontWeightRegular];
    [_root addSubview:_status];

    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(16, 322, 288, 60)];
    footer.numberOfLines = 3;
    footer.text = @"layoutSubviews and drawRect: are Objective-C overrides, "
                   "called back from the Swift render engine.";
    footer.textColor = [UIColor colorWithRed:0.45 green:0.46 blue:0.50 alpha:1];
    [footer setFontOfSize:13 weight:OUKFontWeightRegular];
    [_root addSubview:footer];
}

- (void)buttonTapped:(id)sender {
    UIView *v = (UIView *)sender;
    _status.text = [NSString stringWithFormat:@"action fired, sender tag %ld",
                    (long)v.tag];
}
@end

#pragma mark - A UIViewController subclass, in Objective-C

@interface DetailViewController : UIViewController
@property (nonatomic) BOOL didLoadView;
@property (nonatomic) BOOL didCallViewDidLoad;
@end

@implementation DetailViewController
/* -loadView is called BY the Swift engine's lazy view loading, and must be
 * able to install a view the ObjC side owns. */
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    v.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.view = v;
    _didLoadView = YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _didCallViewDidLoad = YES;
    self.title = @"Detail";
}
@end

#pragma mark - main

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "usage: proofapp <out.png> [resource-root] [font-dir]\n");
            return 2;
        }
        NSString *out = [NSString stringWithUTF8String:argv[1]];
        if (argc > 2) OpenUIKitSetResourceRoot([NSString stringWithUTF8String:argv[2]]);
        if (argc > 3) OpenUIKitSetFontDirectory([NSString stringWithUTF8String:argv[3]]);
        OpenUIKitUseQuartzBackend(getenv("OPENUIKIT_BACKEND") &&
                                  strcmp(getenv("OPENUIKIT_BACKEND"), "quartz") == 0);

        Screen *screen = [[Screen alloc] init];
        [screen build];

        /* Fire the action. This changes rendered text, so a dispatch failure
         * shows up as a pixel difference, not a silent pass. */
        [screen.button sendActionsForControlEvents:UIControlEventTouchUpInside];

        if (![screen.root renderToPNGAtPath:out scale:2.0]) {
            fprintf(stderr, "render failed\n");
            return 1;
        }

        /* Assertions about the bridge itself, printed for the verify script. */
        printf("objc: layout passes = %ld\n", (long)screen.card.layoutPasses);
        printf("objc: status = %s\n", [screen.status.text UTF8String]);
        printf("objc: card superview identity = %s\n",
               screen.card.superview == screen.root ? "OK" : "BROKEN");
        printf("objc: card subview count = %lu\n",
               (unsigned long)screen.card.subviews.count);
        printf("objc: ABI violations = %d\n", openuikit_violation_count());
        printf("objc: wrote %s\n", [out UTF8String]);

        if (screen.card.layoutPasses == 0) {
            fprintf(stderr, "FAIL: -layoutSubviews was never called\n");
            return 1;
        }
        if (screen.card.superview != screen.root) {
            fprintf(stderr, "FAIL: superview identity did not round-trip\n");
            return 1;
        }
        if (openuikit_violation_count() != 0) {
            fprintf(stderr, "FAIL: ABI ownership violations reported\n");
            return 1;
        }

        /* UIViewController: the lazy view-loading callbacks. Kept out of the
         * rendered screen so it cannot influence the byte comparison. */
        DetailViewController *vc = [[DetailViewController alloc] init];
        UIView *vcView = vc.view;               /* triggers loadView + viewDidLoad */
        printf("objc: vc loadView=%d viewDidLoad=%d viewWidth=%g\n",
               vc.didLoadView, vc.didCallViewDidLoad, CGRectGetWidth(vcView.frame));
        if (!vc.didLoadView || !vc.didCallViewDidLoad) {
            fprintf(stderr, "FAIL: UIViewController callbacks did not fire\n");
            return 1;
        }

        /* NEGATIVE CONTROL. A guard-rail nobody has watched fail is not a
         * guard-rail. Break the domination rule on purpose — parent the view
         * through the raw C ABI, bypassing the facade's retaining
         * -addSubview: — and assert the bridge notices. */
        openuikit_set_strict(0);
        int before = openuikit_violation_count();
        @autoreleasepool {
            UIView *orphan = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
            openuikit_view_add_subview(screen.root.openuikitHandle,
                                       orphan.openuikitHandle);
        }   /* orphan deallocs here while the Swift root still owns its view */
        int caught = openuikit_violation_count() - before;
        printf("objc: deliberate ownership violation detected = %d\n", caught);
        if (caught != 1) {
            fprintf(stderr, "FAIL: the ownership check did not fire (%d)\n", caught);
            return 1;
        }
    }
    return 0;
}
