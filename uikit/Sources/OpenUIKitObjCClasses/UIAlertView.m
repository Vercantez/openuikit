// UIAlertView over OpenUIKit (see include/OpenUIKitObjCClasses.h).
//
// MEASURED kioskrowsprobe `## alertview` (iPad Pro 11-inch M4 / iOS 26.1):
//   initWithTitle:@"Error" message:@"Failed" delegate:nil
//       cancelButtonTitle:@"OK" otherButtonTitles:@"Retry", @"More", nil
//   -> numberOfButtons 3, cancelButtonIndex 0, firstOtherButtonIndex 1,
//      visible NO, buttonTitleAtIndex 0/1/2 = OK / Retry / More;
//   with no cancel and no other titles -> 0 buttons, cancelButtonIndex -1,
//      firstOtherButtonIndex -1.
// `-show` is iOS 9+'s behaviour: an alert-style UIAlertController presented
// from the key window's root view controller, one action per button, the
// cancel button's action with the cancel style; a tap reports
// alertView:clickedButtonAtIndex: then willDismiss / didDismiss to the
// delegate (unmeasured order; the UIAlertView.h documentation order).
#import "OpenUIKitObjCClasses.h"
#import "UIKitObjCSupport.h"
#import "OpenUIKitObjCBridge-Swift.h"

@implementation UIAlertView {
    NSMutableArray<NSString *> *_buttonTitles;
    NSInteger _firstOtherButtonIndex;
    UIAlertController *_controller;
}

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate
            cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    _title = [title copy] ?: @"";
    _message = [message copy];
    _delegate = delegate;
    _buttonTitles = [NSMutableArray array];
    _cancelButtonIndex = -1;
    _firstOtherButtonIndex = -1;
    if (cancelButtonTitle) {
        _cancelButtonIndex = 0;
        [_buttonTitles addObject:cancelButtonTitle];
    }
    if (otherButtonTitles) {
        _firstOtherButtonIndex = (NSInteger)_buttonTitles.count;
        [_buttonTitles addObject:otherButtonTitles];
        va_list args;
        va_start(args, otherButtonTitles);
        NSString *next;
        while ((next = va_arg(args, NSString *))) [_buttonTitles addObject:next];
        va_end(args);
    }
    return self;
}

- (NSInteger)numberOfButtons { return (NSInteger)_buttonTitles.count; }
- (NSInteger)firstOtherButtonIndex { return _firstOtherButtonIndex; }
- (BOOL)isVisible { return _controller != nil; }

- (NSInteger)addButtonWithTitle:(NSString *)title {
    [_buttonTitles addObject:title ?: @""];
    return (NSInteger)_buttonTitles.count - 1;
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex {
    return buttonIndex >= 0 && buttonIndex < (NSInteger)_buttonTitles.count ? _buttonTitles[(NSUInteger)buttonIndex] : nil;
}

- (void)show {
    if (_controller) return;
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:_title message:_message
                                                                 preferredStyle:1 /* Alert */];
    __weak UIAlertView *weakSelf = self;
    for (NSUInteger i = 0; i < _buttonTitles.count; i++) {
        NSInteger index = (NSInteger)i;
        NSInteger style = index == _cancelButtonIndex ? 1 /* Cancel */ : 0 /* Default */;
        [controller addAction:[UIAlertAction actionWithTitle:_buttonTitles[i] style:style handler:^(UIAlertAction *action) {
            [weakSelf _clicked:index];
        }]];
    }
    _controller = controller;
    UIViewController *presenter = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    [presenter presentViewController:controller animated:YES completion:nil];
}

- (void)_clicked:(NSInteger)index {
    id delegate = _delegate;
    if ([delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)])
        [delegate alertView:self clickedButtonAtIndex:index];
    if ([delegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)])
        [delegate alertView:self willDismissWithButtonIndex:index];
    _controller = nil;
    if ([delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)])
        [delegate alertView:self didDismissWithButtonIndex:index];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    UIAlertController *controller = _controller;
    if (!controller) return;
    [controller dismissViewControllerAnimated:animated completion:nil];
    [self _clicked:buttonIndex];
}

@end
