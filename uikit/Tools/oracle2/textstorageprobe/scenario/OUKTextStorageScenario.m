// See include/OUKTextStorageScenario.h. Every line appended to a trace is
// something the scenario can observe from Objective-C; the oracle run
// (Tools/oracle2/textstorageprobe/run.sh) records Apple's answer and the
// OpenUIKit test compares against it line for line. Attribute values are
// NSString / NSNumber only, so the same file compiles against OpenUIKit,
// whose UIFont is a Swift struct with no Objective-C face.
#import "OUKTextStorageScenario.h"
#import <objc/runtime.h>

#if OUK_OPENUIKIT
@import CoreGraphics;
#import "OpenUIKit-Swift.h"
#else
#import <UIKit/UIKit.h>
#endif

static NSMutableArray<NSString *> *gTrace;

static void L(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
static void L(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [gTrace addObject:line];
    const char *dbg = getenv("OUK_TRACE_STDERR");
    if (dbg && *dbg) fprintf(stderr, "%s\n", line.UTF8String);
}

static NSString *R(NSRange r) {
    if (r.location == NSNotFound) return [NSString stringWithFormat:@"{NSNotFound, %lu}", (unsigned long)r.length];
    return [NSString stringWithFormat:@"{%lu, %lu}", (unsigned long)r.location, (unsigned long)r.length];
}
static NSString *M(NSUInteger mask) {
    NSMutableArray *parts = [NSMutableArray array];
    if (mask & NSTextStorageEditedAttributes) [parts addObject:@"attr"];
    if (mask & NSTextStorageEditedCharacters) [parts addObject:@"chars"];
    if (mask & ~(NSUInteger)3) [parts addObject:[NSString stringWithFormat:@"0x%lx", (unsigned long)(mask & ~(NSUInteger)3)]];
    return parts.count ? [parts componentsJoinedByString:@"|"] : @"none";
}
/// Stable rendering of an attribute dictionary (sorted keys).
static NSString *D(NSDictionary *d) {
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *k in [d.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        // iOS's NSTextStorage fixAttributes adds a default NSFont (Helvetica
        // 12) to runs without one; OpenUIKit has no UIFont object to add and
        // does not fix attributes. Reported in the oracle-only section and
        // excluded here so the rest of each line compares.
        if ([k isEqualToString:@"NSFont"]) continue;
        [parts addObject:[NSString stringWithFormat:@"%@=%@", k, d[k]]];
    }
    return [NSString stringWithFormat:@"[%@]", [parts componentsJoinedByString:@","]];
}
/// Every run of `s` as "{loc, len}[k=v,...]".
static NSString *Runs(NSAttributedString *s) {
    NSMutableArray *parts = [NSMutableArray array];
    NSUInteger i = 0;
    while (i < s.length) {
        NSRange r;
        NSDictionary *d = [s attributesAtIndex:i effectiveRange:&r];
        [parts addObject:[NSString stringWithFormat:@"%@%@", R(r), D(d)]];
        i = NSMaxRange(r);
        if (r.length == 0) break;
    }
    return [NSString stringWithFormat:@"\"%@\" %@", s.string, [parts componentsJoinedByString:@" "]];
}
static NSString *Raise(void (^block)(void)) {
    @try { block(); return @"ok"; }
    @catch (NSException *e) { return [NSString stringWithFormat:@"raises %@", e.name]; }
}

// MARK: - Plain attributed strings

NSArray<NSString *> *OUKRunAttributedStringScenarios(void) {
    gTrace = [NSMutableArray array];
    NSString *K = @"OUKKey", *J = @"OUKOther";

    // Coalescing of adjacent equal runs, equal-but-not-identical values.
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithString:@"abcdefgh"];
    [m setAttributes:@{K: @1} range:NSMakeRange(0, 2)];
    [m setAttributes:@{K: @1} range:NSMakeRange(2, 2)];
    L(@"coalesce identical: %@", Runs(m));
    [m setAttributes:@{K: [NSNumber numberWithDouble:1.0]} range:NSMakeRange(4, 2)];
    L(@"coalesce 1 vs 1.0: %@", Runs(m));
    [m setAttributes:@{K: [NSMutableString stringWithString:@"v"]} range:NSMakeRange(0, 4)];
    [m setAttributes:@{K: [NSMutableString stringWithString:@"v"]} range:NSMakeRange(4, 4)];
    L(@"coalesce equal strings: %@", Runs(m));
    [m addAttribute:J value:@"x" range:NSMakeRange(2, 3)];
    L(@"add other: %@", Runs(m));
    [m removeAttribute:J range:NSMakeRange(0, 8)];
    L(@"remove other: %@", Runs(m));
    [m addAttributes:@{} range:NSMakeRange(1, 2)];
    L(@"add empty: %@", Runs(m));

    // Enumeration over K while J splits the runs.
    NSMutableAttributedString *e = [[NSMutableAttributedString alloc] initWithString:@"0123456789"];
    [e addAttribute:K value:@"A" range:NSMakeRange(0, 6)];
    [e addAttribute:J value:@1 range:NSMakeRange(2, 2)];
    [e addAttribute:K value:@"B" range:NSMakeRange(8, 2)];
    L(@"enum base: %@", Runs(e));
    NSMutableArray *parts = [NSMutableArray array];
    [e enumerateAttribute:K inRange:NSMakeRange(0, 10) options:0 usingBlock:^(id v, NSRange r, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", R(r), v ?: @"nil"]];
    }];
    L(@"enumerateAttribute K all: %@", [parts componentsJoinedByString:@" "]);
    [parts removeAllObjects];
    [e enumerateAttribute:K inRange:NSMakeRange(1, 8) options:0 usingBlock:^(id v, NSRange r, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", R(r), v ?: @"nil"]];
    }];
    L(@"enumerateAttribute K {1,8}: %@", [parts componentsJoinedByString:@" "]);
    [parts removeAllObjects];
    [e enumerateAttribute:K inRange:NSMakeRange(0, 10) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id v, NSRange r, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", R(r), v ?: @"nil"]];
    }];
    L(@"enumerateAttribute K notRequired: %@", [parts componentsJoinedByString:@" "]);
    [parts removeAllObjects];
    [e enumerateAttribute:K inRange:NSMakeRange(0, 10) options:NSAttributedStringEnumerationReverse usingBlock:^(id v, NSRange r, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", R(r), v ?: @"nil"]];
    }];
    L(@"enumerateAttribute K reverse: %@", [parts componentsJoinedByString:@" "]);
    [parts removeAllObjects];
    [e enumerateAttribute:K inRange:NSMakeRange(0, 10) options:0 usingBlock:^(id v, NSRange r, BOOL *stop) {
        [parts addObject:R(r)];
        *stop = YES;
    }];
    L(@"enumerateAttribute K stop: %@", [parts componentsJoinedByString:@" "]);
    [parts removeAllObjects];
    [e enumerateAttributesInRange:NSMakeRange(0, 10) options:0 usingBlock:^(NSDictionary *d, NSRange r, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@%@", R(r), D(d)]];
    }];
    L(@"enumerateAttributes all: %@", [parts componentsJoinedByString:@" "]);
    [parts removeAllObjects];
    [e enumerateAttributesInRange:NSMakeRange(3, 0) options:0 usingBlock:^(NSDictionary *d, NSRange r, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@%@", R(r), D(d)]];
    }];
    L(@"enumerateAttributes empty range: %lu calls", (unsigned long)parts.count);
    NSRange lr;
    id lv = [e attribute:K atIndex:3 longestEffectiveRange:&lr inRange:NSMakeRange(0, 10)];
    L(@"longestEffectiveRange K at 3: %@ %@", lv, R(lr));
    lv = [e attribute:K atIndex:3 longestEffectiveRange:&lr inRange:NSMakeRange(1, 4)];
    L(@"longestEffectiveRange K at 3 in {1,4}: %@ %@", lv, R(lr));
    lv = [e attribute:K atIndex:7 longestEffectiveRange:&lr inRange:NSMakeRange(0, 10)];
    L(@"longestEffectiveRange K at 7: %@ %@", lv ?: @"nil", R(lr));
    NSRange er;
    lv = [e attribute:K atIndex:3 effectiveRange:&er];
    L(@"effectiveRange K at 3: %@ %@", lv, R(er));

    // Replacement attributes.
    NSMutableAttributedString *r = [[NSMutableAttributedString alloc] initWithString:@"abc"];
    [r addAttribute:K value:@"first" range:NSMakeRange(0, 1)];
    [r addAttribute:K value:@"last" range:NSMakeRange(1, 2)];
    [r replaceCharactersInRange:NSMakeRange(0, 0) withString:@"<"];
    L(@"insert at 0: %@", Runs(r));
    [r replaceCharactersInRange:NSMakeRange(2, 0) withString:@"|"];
    L(@"insert at 2: %@", Runs(r));
    [r replaceCharactersInRange:NSMakeRange(r.length, 0) withString:@">"];
    L(@"insert at end: %@", Runs(r));
    [r replaceCharactersInRange:NSMakeRange(1, 3) withString:@"XY"];
    L(@"replace {1,3}: %@", Runs(r));
    [r replaceCharactersInRange:NSMakeRange(0, r.length) withString:@""];
    L(@"delete all: %@", Runs(r));
    [r replaceCharactersInRange:NSMakeRange(0, 0) withString:@"new"];
    L(@"insert into empty: %@", Runs(r));
    NSMutableAttributedString *ra = [[NSMutableAttributedString alloc] initWithString:@"ab" attributes:@{K: @"k"}];
    [ra replaceCharactersInRange:NSMakeRange(1, 0) withAttributedString:[[NSAttributedString alloc] initWithString:@"--"]];
    L(@"insert attributed plain: %@", Runs(ra));
    [ra appendAttributedString:[[NSAttributedString alloc] initWithString:@"!" attributes:@{K: @"k"}]];
    L(@"append equal attrs: %@", Runs(ra));
    [ra insertAttributedString:[[NSAttributedString alloc] initWithString:@"^" attributes:@{J: @2}] atIndex:0];
    L(@"insert attributed at 0: %@", Runs(ra));
    [ra deleteCharactersInRange:NSMakeRange(0, 1)];
    L(@"delete {0,1}: %@", Runs(ra));
    [ra setAttributedString:[[NSAttributedString alloc] initWithString:@"z" attributes:@{J: @3}]];
    L(@"setAttributedString: %@", Runs(ra));
    [[ra mutableString] appendString:@"zz"];
    L(@"mutableString append: %@", Runs(ra));
    [[ra mutableString] insertString:@"q" atIndex:0];
    L(@"mutableString insert at 0: %@", Runs(ra));

    // UTF-16 index semantics.
    NSMutableAttributedString *u = [[NSMutableAttributedString alloc] initWithString:@"a\U0001F600bé"];
    L(@"utf16 length: %lu", (unsigned long)u.length);
    [u addAttribute:K value:@"emoji" range:NSMakeRange(1, 2)];
    L(@"utf16 runs: %@", Runs(u));
    NSRange ur;
    [u attributesAtIndex:2 effectiveRange:&ur];
    L(@"utf16 attributes at 2 (low surrogate): %@", R(ur));
    L(@"utf16 substring {1,2}: \"%@\" len %lu", [u attributedSubstringFromRange:NSMakeRange(1, 2)].string,
      (unsigned long)[u attributedSubstringFromRange:NSMakeRange(1, 2)].length);
    NSMutableAttributedString *comp = [[NSMutableAttributedString alloc] initWithString:@"éx"];
    L(@"combining length: %lu", (unsigned long)comp.length);

    // Bounds.
    NSAttributedString *b = [[NSAttributedString alloc] initWithString:@"abc" attributes:@{K: @1}];
    L(@"attributesAtIndex:length: %@", Raise(^{ [b attributesAtIndex:3 effectiveRange:NULL]; }));
    L(@"attribute:atIndex:length: %@", Raise(^{ [b attribute:K atIndex:3 effectiveRange:NULL]; }));
    L(@"attributesAtIndex: on empty: %@", Raise(^{ [[[NSAttributedString alloc] initWithString:@""] attributesAtIndex:0 effectiveRange:NULL]; }));
    L(@"substring past end: %@", Raise(^{ [b attributedSubstringFromRange:NSMakeRange(2, 5)]; }));
    L(@"enumerate past end: %@", Raise(^{ [b enumerateAttribute:K inRange:NSMakeRange(0, 9) options:0 usingBlock:^(id v, NSRange rr, BOOL *s) {}]; }));
    NSMutableAttributedString *mb = [[NSMutableAttributedString alloc] initWithString:@"abc"];
    L(@"addAttribute past end: %@", Raise(^{ [mb addAttribute:K value:@1 range:NSMakeRange(2, 5)]; }));
    L(@"replace past end: %@", Raise(^{ [mb replaceCharactersInRange:NSMakeRange(4, 0) withString:@"x"]; }));

    // Equality and copies.
    NSAttributedString *q1 = [[NSAttributedString alloc] initWithString:@"ab" attributes:@{K: @1}];
    NSMutableAttributedString *q2 = [[NSMutableAttributedString alloc] initWithString:@"a" attributes:@{K: @1}];
    [q2 appendAttributedString:[[NSAttributedString alloc] initWithString:@"b" attributes:@{K: [NSNumber numberWithDouble:1]}]];
    L(@"isEqualToAttributedString split-equal: %d", [q1 isEqualToAttributedString:q2]);
    L(@"isEqual: split-equal: %d", [q1 isEqual:q2]);
    L(@"copy of mutable is mutable: %d", [[q2 copy] isKindOfClass:[NSMutableAttributedString class]]);
    L(@"mutableCopy is mutable: %d", [[q1 mutableCopy] isKindOfClass:[NSMutableAttributedString class]]);
    return gTrace;
}

// MARK: - NSTextStorage

@interface OUKTSDelegate : NSObject <NSTextStorageDelegate>
@property (nonatomic, copy) NSString *name;
@property (nonatomic) BOOL editDuringWill;
@end

@implementation OUKTSDelegate
- (void)textStorage:(NSTextStorage *)ts willProcessEditing:(NSTextStorageEditActions)mask range:(NSRange)range changeInLength:(NSInteger)delta {
    L(@"  delegate will mask=%@ range=%@ delta=%ld | ts.mask=%@ ts.range=%@ ts.delta=%ld len=%lu",
      M(mask), R(range), (long)delta, M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength, (unsigned long)ts.length);
    if (self.editDuringWill) {
        self.editDuringWill = NO;
        [ts addAttribute:@"OUKWill" value:@1 range:NSMakeRange(0, 1)];
        L(@"  delegate will after edit: ts.mask=%@ ts.range=%@ ts.delta=%ld", M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength);
    }
}
- (void)textStorage:(NSTextStorage *)ts didProcessEditing:(NSTextStorageEditActions)mask range:(NSRange)range changeInLength:(NSInteger)delta {
    L(@"  delegate did mask=%@ range=%@ delta=%ld | ts.mask=%@ ts.range=%@ ts.delta=%ld",
      M(mask), R(range), (long)delta, M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength);
}
@end

/// The shape of Simplenote's SPInteractiveTextStorage: a backing store, the
/// four primitives, `edited:` from inside begin/endEditing, and a
/// processEditing override that edits attributes before calling super.
@interface OUKObjCTextStorage : NSTextStorage
@property (nonatomic, strong) NSMutableAttributedString *backing;
@property (nonatomic) BOOL restyleInProcessEditing;
@property (nonatomic) BOOL logPrimitives;
@end

@implementation OUKObjCTextStorage
- (instancetype)init {
    self = [super init];
    if (self) { _backing = [[NSMutableAttributedString alloc] init]; }
    return self;
}
- (NSString *)string { return _backing.string; }
- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [_backing attributesAtIndex:location effectiveRange:range];
}
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    if (self.logPrimitives) L(@"  prim replaceCharactersInRange:%@ withString:\"%@\"", R(range), str);
    [self beginEditing];
    [_backing replaceCharactersInRange:range withString:str];
    [self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:range changeInLength:(NSInteger)str.length - (NSInteger)range.length];
    [self endEditing];
}
- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range {
    if (self.logPrimitives) L(@"  prim setAttributes:%@ range:%@", D(attrs ?: @{}), R(range));
    [self beginEditing];
    [_backing setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}
- (void)processEditing {
    L(@"  sub processEditing (enter) mask=%@ range=%@ delta=%ld", M(self.editedMask), R(self.editedRange), (long)self.changeInLength);
    if (self.restyleInProcessEditing) {
        self.restyleInProcessEditing = NO;
        [self addAttributes:@{@"OUKStyle": @"head"} range:NSMakeRange(0, MIN((NSUInteger)2, self.length))];
        L(@"  sub processEditing after restyle mask=%@ range=%@ delta=%ld", M(self.editedMask), R(self.editedRange), (long)self.changeInLength);
    }
    [super processEditing];
    L(@"  sub processEditing (exit) mask=%@ range=%@ delta=%ld", M(self.editedMask), R(self.editedRange), (long)self.changeInLength);
}
- (void)fixAttributesInRange:(NSRange)range {
    if (self.logPrimitives) L(@"  sub fixAttributesInRange:%@", R(range));
    [super fixAttributesInRange:range];
}
@end

id OUKMakeObjCTextStorage(void) { return [[OUKObjCTextStorage alloc] init]; }

static id gWillObserver, gDidObserver;
static void Observe(NSTextStorage *ts) {
    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    if (gWillObserver) [nc removeObserver:gWillObserver];
    if (gDidObserver) [nc removeObserver:gDidObserver];
    gWillObserver = [nc addObserverForName:NSTextStorageWillProcessEditingNotification object:ts queue:nil usingBlock:^(NSNotification *n) {
        NSTextStorage *s = n.object;
        L(@"  note will mask=%@ range=%@ delta=%ld userInfo=%lu", M(s.editedMask), R(s.editedRange), (long)s.changeInLength, (unsigned long)n.userInfo.count);
    }];
    gDidObserver = [nc addObserverForName:NSTextStorageDidProcessEditingNotification object:ts queue:nil usingBlock:^(NSNotification *n) {
        NSTextStorage *s = n.object;
        L(@"  note did mask=%@ range=%@ delta=%ld userInfo=%lu", M(s.editedMask), R(s.editedRange), (long)s.changeInLength, (unsigned long)n.userInfo.count);
    }];
}
static void After(NSTextStorage *ts) {
    L(@"  after mask=%@ range=%@ delta=%ld runs=%@", M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength, Runs(ts));
}

static void DriveStorage(NSTextStorage *ts, OUKTSDelegate *d, BOOL emptyProcessEditing) {
    ts.delegate = d;
    Observe(ts);
    L(@"replace {0,0} \"Hello world\"");
    [ts replaceCharactersInRange:NSMakeRange(0, 0) withString:@"Hello world"];
    After(ts);
    L(@"addAttribute {6,5}");
    [ts addAttribute:@"OUKKey" value:@"w" range:NSMakeRange(6, 5)];
    After(ts);
    L(@"setAttributes {0,5}");
    [ts setAttributes:@{@"OUKKey": @"h"} range:NSMakeRange(0, 5)];
    After(ts);
    L(@"removeAttribute {0,11}");
    [ts removeAttribute:@"OUKKey" range:NSMakeRange(0, 11)];
    After(ts);
    L(@"begin; insert 0 \"A\"; addAttribute {3,2}; delete {1,1}; end");
    [ts beginEditing];
    [ts replaceCharactersInRange:NSMakeRange(0, 0) withString:@"A"];
    L(@"  inside mask=%@ range=%@ delta=%ld", M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength);
    [ts addAttribute:@"OUKKey" value:@1 range:NSMakeRange(3, 2)];
    L(@"  inside mask=%@ range=%@ delta=%ld", M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength);
    [ts deleteCharactersInRange:NSMakeRange(1, 1)];
    L(@"  inside mask=%@ range=%@ delta=%ld", M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength);
    [ts endEditing];
    After(ts);
    L(@"begin; insert 8 \"xyz\"; delete {0,2}; end");
    [ts beginEditing];
    [ts replaceCharactersInRange:NSMakeRange(8, 0) withString:@"xyz"];
    [ts deleteCharactersInRange:NSMakeRange(0, 2)];
    L(@"  inside mask=%@ range=%@ delta=%ld", M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength);
    [ts endEditing];
    After(ts);
    L(@"begin; begin; addAttribute {0,1}; end; end");
    [ts beginEditing];
    [ts beginEditing];
    [ts addAttribute:@"OUKKey" value:@2 range:NSMakeRange(0, 1)];
    [ts endEditing];
    L(@"  after inner end mask=%@ range=%@", M(ts.editedMask), R(ts.editedRange));
    [ts endEditing];
    After(ts);
    L(@"begin; end (nothing edited)");
    [ts beginEditing];
    [ts endEditing];
    After(ts);
    if (emptyProcessEditing) {
        // Not for the backing-store subclass: iOS 26.1 raises NSRangeException
        // (NSMutableRLEArray objectAtIndex:effectiveRange:) there.
        L(@"processEditing (nothing edited)");
        [ts processEditing];
        After(ts);
    }
    L(@"edited:attr {2,3} 0 (direct)");
    [ts edited:NSTextStorageEditedAttributes range:NSMakeRange(2, 3) changeInLength:0];
    After(ts);
    L(@"begin; edited:attr {0,1}; processEditing; end");
    [ts beginEditing];
    [ts edited:NSTextStorageEditedAttributes range:NSMakeRange(0, 1) changeInLength:0];
    [ts processEditing];
    L(@"  after explicit processEditing mask=%@ range=%@ delta=%ld", M(ts.editedMask), R(ts.editedRange), (long)ts.changeInLength);
    [ts endEditing];
    After(ts);
    L(@"delegate edits during will");
    d.editDuringWill = YES;
    [ts addAttribute:@"OUKKey" value:@3 range:NSMakeRange(4, 1)];
    After(ts);
    L(@"setAttributedString");
    [ts setAttributedString:[[NSAttributedString alloc] initWithString:@"new" attributes:@{@"OUKKey": @"n"}]];
    After(ts);
    L(@"appendAttributedString");
    [ts appendAttributedString:[[NSAttributedString alloc] initWithString:@"++"]];
    After(ts);
    L(@"mutableString appendString");
    [[ts mutableString] appendString:@"!"];
    After(ts);
    L(@"replace with same attrs no-op range {0,0} \"\"");
    [ts replaceCharactersInRange:NSMakeRange(0, 0) withString:@""];
    After(ts);
    L(@"addAttribute zero-length {1,0}");
    [ts addAttribute:@"OUKKey" value:@9 range:NSMakeRange(1, 0)];
    After(ts);
    ts.delegate = nil;
    [NSNotificationCenter.defaultCenter removeObserver:gWillObserver];
    [NSNotificationCenter.defaultCenter removeObserver:gDidObserver];
    gWillObserver = gDidObserver = nil;
}

NSArray<NSString *> *OUKRunTextStorageScenarios(void) {
    gTrace = [NSMutableArray array];
    L(@"superclass NSTextStorage: %@", NSStringFromClass(class_getSuperclass([NSTextStorage class])));
    L(@"NSTextStorage isKindOf NSMutableAttributedString: %d", [[NSTextStorage alloc] init] != nil && [[[NSTextStorage alloc] init] isKindOfClass:[NSMutableAttributedString class]]);
    L(@"NSTextStorage isKindOf NSAttributedString: %d", [[[NSTextStorage alloc] init] isKindOfClass:[NSAttributedString class]]);
    NSTextStorage *fresh = [[NSTextStorage alloc] initWithString:@"init" attributes:@{@"OUKKey": @0}];
    L(@"initWithString:attributes: runs=%@ mask=%@ range=%@ delta=%ld", Runs(fresh), M(fresh.editedMask), R(fresh.editedRange), (long)fresh.changeInLength);
    NSTextStorage *fromAttr = [[NSTextStorage alloc] initWithAttributedString:fresh];
    L(@"initWithAttributedString: runs=%@", Runs(fromAttr));
    L(@"layoutManagers initially: %lu", (unsigned long)fresh.layoutManagers.count);
    L(@"delegate initially: %@", fresh.delegate ? @"set" : @"nil");
    L(@"string is NSString: %d", [fresh.string isKindOfClass:[NSString class]]);

    L(@"## base NSTextStorage");
    DriveStorage([[NSTextStorage alloc] init], [OUKTSDelegate new], YES);

    L(@"## Objective-C subclass");
    OUKObjCTextStorage *sub = [[OUKObjCTextStorage alloc] init];
    L(@"subclass superclass: %@", NSStringFromClass(class_getSuperclass([OUKObjCTextStorage class])));
    L(@"subclass length initially: %lu", (unsigned long)sub.length);
    DriveStorage(sub, [OUKTSDelegate new], NO);

    L(@"## subclass primitives");
    OUKObjCTextStorage *p = [[OUKObjCTextStorage alloc] init];
    p.logPrimitives = YES;
    L(@"appendAttributedString (attrs)");
    [p appendAttributedString:[[NSAttributedString alloc] initWithString:@"ab" attributes:@{@"OUKKey": @1}]];
    L(@"addAttribute");
    [p addAttribute:@"OUKOther" value:@2 range:NSMakeRange(0, 1)];
    L(@"addAttributes");
    [p addAttributes:@{@"OUKOther": @3, @"OUKKey": @4} range:NSMakeRange(1, 1)];
    L(@"removeAttribute");
    [p removeAttribute:@"OUKOther" range:NSMakeRange(0, 2)];
    L(@"insertAttributedString");
    [p insertAttributedString:[[NSAttributedString alloc] initWithString:@"<"] atIndex:0];
    L(@"deleteCharactersInRange");
    [p deleteCharactersInRange:NSMakeRange(0, 1)];
    L(@"replaceCharactersInRange:withAttributedString:");
    [p replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:[[NSAttributedString alloc] initWithString:@"XY" attributes:@{@"OUKKey": @5}]];
    L(@"setAttributedString");
    [p setAttributedString:[[NSAttributedString alloc] initWithString:@"s"]];
    L(@"mutableString appendString");
    [[p mutableString] appendString:@"t"];
    L(@"final runs=%@", Runs(p));
    L(@"attributedSubstring {0,1}: %@", Runs([p attributedSubstringFromRange:NSMakeRange(0, 1)]));
    L(@"isEqualToAttributedString self copy: %d", [p isEqualToAttributedString:[[NSAttributedString alloc] initWithAttributedString:p]]);

    L(@"## processEditing restyle");
    OUKObjCTextStorage *s = [[OUKObjCTextStorage alloc] init];
    OUKTSDelegate *sd = [OUKTSDelegate new];
    s.delegate = sd;
    Observe(s);
    s.restyleInProcessEditing = YES;
    L(@"replace {0,0} \"Title\\nbody\"");
    [s replaceCharactersInRange:NSMakeRange(0, 0) withString:@"Title\nbody"];
    After(s);
    s.restyleInProcessEditing = YES;
    L(@"insert 7 \"X\"");
    [s replaceCharactersInRange:NSMakeRange(7, 0) withString:@"X"];
    After(s);
    s.delegate = nil;
    [NSNotificationCenter.defaultCenter removeObserver:gWillObserver];
    [NSNotificationCenter.defaultCenter removeObserver:gDidObserver];
    gWillObserver = gDidObserver = nil;
    return gTrace;
}
