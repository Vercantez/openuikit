// Oracle driver: run the shared scenario against Apple's UIKit and print it,
// then the oracle-only facts (types OpenUIKit has no Objective-C face for:
// UIFont, NSLayoutManager subclasses, UITextView).
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "OUKTextStorageScenario.h"

static NSString *R(NSRange r) { return [NSString stringWithFormat:@"{%lu, %lu}", (unsigned long)r.location, (unsigned long)r.length]; }

static NSMutableArray<NSString *> *gOracle;

@interface OUKProbeLayoutManager : NSLayoutManager
@end
@implementation OUKProbeLayoutManager
- (void)processEditingForTextStorage:(NSTextStorage *)ts edited:(NSTextStorageEditActions)mask range:(NSRange)newCharRange changeInLength:(NSInteger)delta invalidatedRange:(NSRange)invalidatedCharRange {
    [gOracle addObject:[NSString stringWithFormat:@"  layoutManager processEditing mask=%lu range=%@ delta=%ld invalidated=%@",
                        (unsigned long)mask, R(newCharRange), (long)delta, R(invalidatedCharRange)]];
    [super processEditingForTextStorage:ts edited:mask range:newCharRange changeInLength:delta invalidatedRange:invalidatedCharRange];
}
@end

@interface OUKProbeDelegate : NSObject <NSTextStorageDelegate>
@end
@implementation OUKProbeDelegate
- (void)textStorage:(NSTextStorage *)ts willProcessEditing:(NSTextStorageEditActions)m range:(NSRange)r changeInLength:(NSInteger)d {
    [gOracle addObject:[NSString stringWithFormat:@"  delegate will %@", R(r)]];
}
- (void)textStorage:(NSTextStorage *)ts didProcessEditing:(NSTextStorageEditActions)m range:(NSRange)r changeInLength:(NSInteger)d {
    [gOracle addObject:[NSString stringWithFormat:@"  delegate did %@", R(r)]];
}
@end

@interface OUKFixStorage : NSTextStorage
@property (nonatomic, strong) NSMutableAttributedString *backing;
@end
@implementation OUKFixStorage
- (instancetype)init { if ((self = [super init])) _backing = [NSMutableAttributedString new]; return self; }
- (NSString *)string { return _backing.string; }
- (NSDictionary *)attributesAtIndex:(NSUInteger)i effectiveRange:(NSRangePointer)r { return [_backing attributesAtIndex:i effectiveRange:r]; }
- (void)replaceCharactersInRange:(NSRange)r withString:(NSString *)s {
    [self beginEditing]; [_backing replaceCharactersInRange:r withString:s];
    [self edited:NSTextStorageEditedCharacters range:r changeInLength:(NSInteger)s.length - (NSInteger)r.length]; [self endEditing];
}
- (void)setAttributes:(NSDictionary *)a range:(NSRange)r {
    [self beginEditing]; [_backing setAttributes:a range:r];
    [self edited:NSTextStorageEditedAttributes range:r changeInLength:0]; [self endEditing];
}
- (void)fixAttributesInRange:(NSRange)r {
    [gOracle addObject:[NSString stringWithFormat:@"  fixAttributesInRange:%@", R(r)]];
    [super fixAttributesInRange:r];
}
- (void)invalidateAttributesInRange:(NSRange)r {
    [gOracle addObject:[NSString stringWithFormat:@"  invalidateAttributesInRange:%@", R(r)]];
    [super invalidateAttributesInRange:r];
}
@end

static NSString *FontRuns(NSAttributedString *s) {
    NSMutableArray *parts = [NSMutableArray array];
    [s enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, s.length) options:0 usingBlock:^(UIFont *f, NSRange r, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", R(r), f ? [NSString stringWithFormat:@"%@ %g", f.fontName, f.pointSize] : @"nil"]];
    }];
    return [parts componentsJoinedByString:@" "];
}

static NSArray<NSString *> *OracleOnly(void) {
    gOracle = [NSMutableArray array];
    [gOracle addObject:[NSString stringWithFormat:@"[NSTextStorage alloc] class: %@", NSStringFromClass([[NSTextStorage alloc] class])]];
    [gOracle addObject:[NSString stringWithFormat:@"[[NSTextStorage alloc] init] class: %@", NSStringFromClass([[[NSTextStorage alloc] init] class])]];
    [gOracle addObject:[NSString stringWithFormat:@"superclass chain: %@ < %@ < %@",
                        NSStringFromClass(class_getSuperclass([NSTextStorage class])),
                        NSStringFromClass(class_getSuperclass([NSMutableAttributedString class])),
                        NSStringFromClass(class_getSuperclass([NSAttributedString class]))]];
    [gOracle addObject:[NSString stringWithFormat:@"NSParagraphStyle superclass: %@", NSStringFromClass(class_getSuperclass([NSParagraphStyle class]))]];
    [gOracle addObject:[NSString stringWithFormat:@"NSTextAttachment superclass: %@", NSStringFromClass(class_getSuperclass([NSTextAttachment class]))]];
    NSTextStorage *plain = [NSTextStorage new];
    [gOracle addObject:[NSString stringWithFormat:@"NSTextStorage fixesAttributesLazily: %d", plain.fixesAttributesLazily]];
    OUKFixStorage *fs = [OUKFixStorage new];
    [gOracle addObject:[NSString stringWithFormat:@"subclass fixesAttributesLazily: %d", fs.fixesAttributesLazily]];

    // fixAttributes: fonts over characters the font lacks.
    UIFont *h = [UIFont fontWithName:@"Helvetica" size:17];
    NSDictionary *fa = @{NSFontAttributeName: h};
    [gOracle addObject:@"## fixAttributes (Helvetica 17 over a, emoji, CJK)"];
    NSString *mixed = @"a\U0001F600中z";
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:mixed attributes:fa];
    [gOracle addObject:[NSString stringWithFormat:@"NSMutableAttributedString no fix: %@", FontRuns(mas)]];
    [mas fixAttributesInRange:NSMakeRange(0, mas.length)];
    [gOracle addObject:[NSString stringWithFormat:@"NSMutableAttributedString after fixAttributesInRange: %@", FontRuns(mas)]];
    NSTextStorage *ts = [[NSTextStorage alloc] initWithString:mixed attributes:fa];
    [gOracle addObject:[NSString stringWithFormat:@"NSTextStorage initWithString: %@", FontRuns(ts)]];
    [ts replaceCharactersInRange:NSMakeRange(ts.length, 0) withString:@"日"];
    [gOracle addObject:[NSString stringWithFormat:@"NSTextStorage after edit (no layout manager): %@", FontRuns(ts)]];
    [ts ensureAttributesAreFixedInRange:NSMakeRange(0, ts.length)];
    [gOracle addObject:[NSString stringWithFormat:@"NSTextStorage after ensureAttributesAreFixedInRange: %@", FontRuns(ts)]];
    [gOracle addObject:@"subclass edit with fixAttributes logging:"];
    [fs replaceCharactersInRange:NSMakeRange(0, 0) withString:mixed];
    [fs setAttributes:fa range:NSMakeRange(0, fs.length)];
    [gOracle addObject:[NSString stringWithFormat:@"subclass after edits: %@", FontRuns(fs)]];

    // Layout manager ordering.
    [gOracle addObject:@"## layout manager ordering"];
    NSTextStorage *lts = [NSTextStorage new];
    OUKProbeDelegate *pd = [OUKProbeDelegate new];
    lts.delegate = pd;
    OUKProbeLayoutManager *lm = [OUKProbeLayoutManager new];
    NSTextContainer *tc = [[NSTextContainer alloc] initWithSize:CGSizeMake(200, 1000)];
    [lm addTextContainer:tc];
    [lts addLayoutManager:lm];
    [gOracle addObject:[NSString stringWithFormat:@"after addLayoutManager: layoutManagers=%lu lm.textStorage==ts %d", (unsigned long)lts.layoutManagers.count, lm.textStorage == lts]];
    id willObs = [NSNotificationCenter.defaultCenter addObserverForName:NSTextStorageWillProcessEditingNotification object:lts queue:nil usingBlock:^(NSNotification *n) { [gOracle addObject:@"  note will"]; }];
    id didObs = [NSNotificationCenter.defaultCenter addObserverForName:NSTextStorageDidProcessEditingNotification object:lts queue:nil usingBlock:^(NSNotification *n) { [gOracle addObject:@"  note did"]; }];
    [gOracle addObject:@"replace {0,0} \"Hello\""];
    [lts replaceCharactersInRange:NSMakeRange(0, 0) withString:@"Hello"];
    [gOracle addObject:@"addAttribute {1,2}"];
    [lts addAttribute:NSForegroundColorAttributeName value:UIColor.redColor range:NSMakeRange(1, 2)];
    [gOracle addObject:@"removeLayoutManager"];
    [lts removeLayoutManager:lm];
    [gOracle addObject:[NSString stringWithFormat:@"after removeLayoutManager: layoutManagers=%lu lm.textStorage=%@", (unsigned long)lts.layoutManagers.count, lm.textStorage ? @"set" : @"nil"]];
    [lts replaceCharactersInRange:NSMakeRange(0, 0) withString:@"X"];
    [NSNotificationCenter.defaultCenter removeObserver:willObs];
    [NSNotificationCenter.defaultCenter removeObserver:didObs];

    // UITextView's storage.
    [gOracle addObject:@"## UITextView"];
    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 100) textContainer:nil];
    [gOracle addObject:[NSString stringWithFormat:@"UITextView.textStorage class: %@ isKindOf NSTextStorage %d delegate=%@",
                        NSStringFromClass(tv.textStorage.class), [tv.textStorage isKindOfClass:NSTextStorage.class],
                        tv.textStorage.delegate ? NSStringFromClass([(NSObject *)tv.textStorage.delegate class]) : @"nil"]];
    tv.text = @"abc";
    [gOracle addObject:[NSString stringWithFormat:@"after text=abc: textStorage.string=%@ length=%lu", tv.textStorage.string, (unsigned long)tv.textStorage.length]];
    [tv.textStorage replaceCharactersInRange:NSMakeRange(3, 0) withString:@"d"];
    [gOracle addObject:[NSString stringWithFormat:@"after textStorage edit: tv.text=%@ attributedText.length=%lu", tv.text, (unsigned long)tv.attributedText.length]];
    return gOracle;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        printf("# textstorageprobe — iOS %s\n", UIDevice.currentDevice.systemVersion.UTF8String);
        printf("## attributed\n");
        for (NSString *line in OUKRunAttributedStringScenarios()) printf("%s\n", line.UTF8String);
        printf("## textstorage\n");
        for (NSString *line in OUKRunTextStorageScenarios()) printf("%s\n", [line stringByReplacingOccurrencesOfString:@"## " withString:@"### "].UTF8String);
        printf("## oracle-only\n");
        for (NSString *line in OracleOnly()) printf("%s\n", [line stringByReplacingOccurrencesOfString:@"## " withString:@"### "].UTF8String);
    }
    return 0;
}
