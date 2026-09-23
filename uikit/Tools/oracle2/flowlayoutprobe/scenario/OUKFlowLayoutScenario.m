// See include/OUKFlowLayoutScenario.h. Every trace line is something the
// scenario observes from Objective-C: which overrides UIKit sends, in what
// order, with what arguments, and the geometry that results. The oracle run
// (../run.sh) records Apple's answer; the OpenUIKit test compares.
#import "OUKFlowLayoutScenario.h"
#import <objc/runtime.h>

#if OUK_OPENUIKIT
@import CoreGraphics;
#import "OpenUIKit-Swift.h"
#import "OpenUIKitObjCBridge-Swift.h"
#import "UIKitObjCSupport.h"
#else
#import <UIKit/UIKit.h>
#endif

static NSMutableArray<NSString *> *OUKFlowTrace(void) {
    static NSMutableArray<NSString *> *trace;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ trace = [NSMutableArray array]; });
    return trace;
}

static void L(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
static void L(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    [OUKFlowTrace() addObject:[[NSString alloc] initWithFormat:format arguments:args]];
    va_end(args);
}

static NSString *R(CGRect r) {
    return [NSString stringWithFormat:@"{{%g, %g}, {%g, %g}}", r.origin.x, r.origin.y, r.size.width, r.size.height];
}
static NSString *S(CGSize s) { return [NSString stringWithFormat:@"{%g, %g}", s.width, s.height]; }
static NSString *P(CGPoint p) { return [NSString stringWithFormat:@"{%g, %g}", p.x, p.y]; }
static NSString *IP(NSIndexPath *_Nullable ip) {
    return ip ? [NSString stringWithFormat:@"[%ld,%ld]", (long)ip.section, (long)ip.item] : @"nil";
}
static NSString *Sup(Class _Nullable c) { return c ? NSStringFromClass(class_getSuperclass(c)) : @"nil"; }

// MARK: - Attributes subclass

@interface OUKGridAttributes : UICollectionViewLayoutAttributes
@end
@implementation OUKGridAttributes
@end

// MARK: - Masonry-shaped layout (ARCollectionViewMasonryLayout 2.0.0)

@class OUKMasonryLayout;
@protocol OUKMasonryDelegate <UICollectionViewDelegateFlowLayout>
- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(OUKMasonryLayout *)layout
variableDimensionForItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface OUKMasonryLayout : UICollectionViewFlowLayout
- (instancetype)initWithRank:(NSUInteger)rank;
@property (nonatomic) NSUInteger rank;
@property (nonatomic) CGFloat dimensionLength;
@property (nonatomic) CGSize itemMargins;
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *itemAttributes;
@property (nonatomic, strong, nullable) UICollectionViewLayoutAttributes *headerAttributes;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *columns;
@end

@implementation OUKMasonryLayout
- (instancetype)initWithRank:(NSUInteger)rank {
    L(@"masonry -initWithRank: %lu (enter)", (unsigned long)rank);
    self = [super init];
    if (!self) return nil;
    _rank = rank;
    _dimensionLength = 120;
    _itemMargins = CGSizeMake(10, 10);
    L(@"masonry -initWithRank: (exit) collectionView=%@", self.collectionView ? @"set" : @"nil");
    return self;
}

- (void)setRank:(NSUInteger)rank {
    if (_rank != rank) {
        _rank = rank;
        [self invalidateLayout];
    }
}

- (id<OUKMasonryDelegate>)delegate {
    id d = self.collectionView.delegate;
    return [d conformsToProtocol:@protocol(OUKMasonryDelegate)] ? d : nil;
}

- (void)prepareLayout {
    L(@"masonry -prepareLayout (enter) collectionView=%@", [self.collectionView isKindOfClass:[UICollectionView class]] ? @"UICollectionView" : @"nil");
    [super prepareLayout];
    if (!self.collectionView) return;
    NSInteger count = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    CGFloat width = self.collectionView.frame.size.width;
    CGFloat content = self.rank * self.dimensionLength + (self.rank - 1) * self.itemMargins.width;
    CGFloat centering = width / 2 - content / 2;
    self.itemAttributes = [NSMutableArray array];
    self.columns = [NSMutableArray array];
    CGFloat leading = self.itemMargins.height;

    NSIndexPath *zero = [NSIndexPath indexPathForItem:0 inSection:0];
    CGSize header = CGSizeZero;
    id<OUKMasonryDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
        header = [delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:0];
    }
    if (!CGSizeEqualToSize(header, CGSizeZero)) {
        UICollectionViewLayoutAttributes *h =
            [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                          withIndexPath:zero];
        h.frame = CGRectMake(0, 0, CGRectGetWidth(self.collectionView.bounds), header.height);
        self.headerAttributes = h;
        leading += header.height;
    } else {
        self.headerAttributes = nil;
    }
    for (NSUInteger i = 0; i < self.rank; i++) [self.columns addObject:@(leading)];

    for (NSInteger i = 0; i < count; i++) {
        NSIndexPath *ip = [NSIndexPath indexPathForItem:i inSection:0];
        CGFloat h = ceilf([delegate collectionView:self.collectionView layout:self variableDimensionForItemAtIndexPath:ip]);
        NSUInteger col = 0;
        for (NSUInteger c = 1; c < self.rank; c++) {
            if (self.columns[c].floatValue < self.columns[col].floatValue) col = c;
        }
        CGFloat x = centering + (self.dimensionLength + self.itemMargins.width) * col;
        CGFloat y = self.columns[col].floatValue;
        UICollectionViewLayoutAttributes *a = [OUKGridAttributes layoutAttributesForCellWithIndexPath:ip];
        a.size = CGSizeMake(self.dimensionLength, h);
        a.center = CGPointMake(x + self.dimensionLength / 2, y + h / 2);
        a.frame = CGRectIntegral(a.frame);
        [self.itemAttributes addObject:a];
        CGFloat total = y + h + (i == count - 1 ? 0 : self.itemMargins.height);
        self.columns[col] = @(roundf(total));
    }
    L(@"masonry -prepareLayout (exit) items=%lu", (unsigned long)self.itemAttributes.count);
}

- (CGSize)collectionViewContentSize {
    CGFloat longest = 0;
    for (NSNumber *n in self.columns) longest = MAX(longest, n.floatValue);
    CGSize size = self.collectionView.frame.size;
    size.height = longest;
    L(@"masonry -collectionViewContentSize -> %@", S(size));
    return size;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *all = self.itemAttributes ?: @[];
    if (self.headerAttributes) all = [all arrayByAddingObject:self.headerAttributes];
    NSArray *hits = [all filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *b) {
        return CGRectIntersectsRect(rect, [obj frame]);
    }]];
    L(@"masonry -layoutAttributesForElementsInRect: %@ -> %lu", R(rect), (unsigned long)hits.count);
    return hits;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    L(@"masonry -layoutAttributesForItemAtIndexPath: %@", IP(indexPath));
    if ((NSUInteger)indexPath.item >= self.itemAttributes.count) return nil;
    return self.itemAttributes[indexPath.item];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath {
    L(@"masonry -layoutAttributesForSupplementaryViewOfKind: %@ %@", kind, IP(indexPath));
    return [kind isEqualToString:UICollectionElementKindSectionHeader] ? self.headerAttributes : nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    L(@"masonry -shouldInvalidateLayoutForBoundsChange: %@ -> YES", R(newBounds));
    return YES;
}

- (void)invalidateLayout {
    L(@"masonry -invalidateLayout (enter)");
    [super invalidateLayout];
    L(@"masonry -invalidateLayout (exit)");
}
@end

// MARK: - A flow layout subclass that keeps UIKit's geometry (calls super)

@interface OUKFlowSubclass : UICollectionViewFlowLayout
@end
@implementation OUKFlowSubclass
- (void)prepareLayout {
    L(@"flow -prepareLayout");
    [super prepareLayout];
}
- (CGSize)collectionViewContentSize {
    CGSize s = [super collectionViewContentSize];
    L(@"flow -collectionViewContentSize -> %@", S(s));
    return s;
}
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *a = [super layoutAttributesForElementsInRect:rect];
    L(@"flow -layoutAttributesForElementsInRect: %@ -> %lu", R(rect), (unsigned long)a.count);
    return a;
}
@end

// MARK: - Data source / delegate

@interface OUKGridSource : NSObject <UICollectionViewDataSource, OUKMasonryDelegate>
@property (nonatomic) NSInteger count;
@property (nonatomic) CGFloat headerHeight;
@end

@implementation OUKGridSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    L(@"source numberOfItemsInSection: %ld -> %ld", (long)section, (long)self.count);
    return self.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    L(@"source cellForItemAtIndexPath: %@", IP(indexPath));
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    L(@"source viewForSupplementaryElementOfKind: %@ %@", kind, IP(indexPath));
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(OUKMasonryLayout *)layout
    variableDimensionForItemAtIndexPath:(NSIndexPath *)indexPath {
    return 40 + 17.5 * (CGFloat)(indexPath.item % 4);
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout
    referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(0, self.headerHeight);
}
@end

// MARK: - Helpers

// OpenUIKit's scroll view never adjusts its content inset for the safe area
// (no contentInsetAdjustmentBehavior; the behaviour is always that of
// UIScrollViewContentInsetAdjustmentNever), so the oracle run pins Never:
// without it iOS 26.1 shifts the offset to -59 (the window's top safe area)
// and re-invalidates the layout on every safe-area change.
static void NoInsetAdjustment(UICollectionView *cv) {
#if !OUK_OPENUIKIT
    cv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#endif
}

static void LogCells(NSString *tag, UICollectionView *cv) {
    NSArray<UICollectionViewCell *> *cells = [cv.visibleCells sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [[cv indexPathForCell:a] compare:[cv indexPathForCell:b]];
    }];
    L(@"%@ visibleCells=%lu contentSize=%@ contentOffset=%@", tag, (unsigned long)cells.count, S(cv.contentSize),
      P(cv.contentOffset));
    for (UICollectionViewCell *cell in cells) {
        L(@"  cell %@ frame=%@ hidden=%d", IP([cv indexPathForCell:cell]), R(cell.frame), cell.hidden);
    }
    UICollectionReusableView *header =
        [cv supplementaryViewForElementKind:UICollectionElementKindSectionHeader
                                atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    L(@"  header %@", header ? R(header.frame) : @"nil");
}

NSArray<NSString *> *OUKRunFlowLayoutScenario(void) {
    [OUKFlowTrace() removeAllObjects];
    NSIndexPath *ip3 = [NSIndexPath indexPathForItem:3 inSection:0];
    NSIndexPath *zero = [NSIndexPath indexPathForItem:0 inSection:0];

    L(@"-- 1 classes");
    L(@"UICollectionViewLayout:%@", Sup([UICollectionViewLayout class]));
    L(@"UICollectionViewFlowLayout:%@", Sup([UICollectionViewFlowLayout class]));
    L(@"UICollectionViewLayoutAttributes:%@", Sup([UICollectionViewLayoutAttributes class]));
    L(@"OUKMasonryLayout:%@", Sup([OUKMasonryLayout class]));

    L(@"-- 2 layout attributes");
    UICollectionViewLayoutAttributes *a = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:ip3];
    L(@"cell class=%@ indexPath=%@ frame=%@ center=%@ size=%@", NSStringFromClass([a class]), IP(a.indexPath),
      R(a.frame), P(a.center), S(a.size));
    L(@"cell category=%ld kind=%@ zIndex=%ld alpha=%g hidden=%d", (long)a.representedElementCategory,
      a.representedElementKind ?: @"nil", (long)a.zIndex, a.alpha, a.hidden);
    a.size = CGSizeMake(100, 61);
    L(@"after size frame=%@ center=%@", R(a.frame), P(a.center));
    a.center = CGPointMake(60.5, 40.25);
    L(@"after center frame=%@ center=%@", R(a.frame), P(a.center));
    a.frame = CGRectIntegral(a.frame);
    L(@"after integral frame=%@ center=%@ bounds=%@", R(a.frame), P(a.center), R(a.bounds));
    UICollectionViewLayoutAttributes *h =
        [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                      withIndexPath:zero];
    L(@"header category=%ld kind=%@", (long)h.representedElementCategory, h.representedElementKind);
    UICollectionViewLayoutAttributes *sub = [OUKGridAttributes layoutAttributesForCellWithIndexPath:ip3];
    L(@"subclass factory class=%@ indexPath=%@", NSStringFromClass([sub class]), IP(sub.indexPath));

    L(@"-- 3 flow layout defaults");
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    UIEdgeInsets si = flow.sectionInset;
    L(@"itemSize=%@ lineSpacing=%g interitemSpacing=%g scrollDirection=%ld",
      S(flow.itemSize), flow.minimumLineSpacing, flow.minimumInteritemSpacing,
      (long)flow.scrollDirection);
    L(@"sectionInset={%g, %g, %g, %g} header=%@ footer=%@", si.top, si.left, si.bottom, si.right,
      S(flow.headerReferenceSize), S(flow.footerReferenceSize));
    L(@"unattached collectionView=%@ contentSize=%@ elements=%@", flow.collectionView ? @"set" : @"nil",
      S(flow.collectionViewContentSize),
      [flow layoutAttributesForElementsInRect:CGRectMake(0, 0, 100, 100)] ? @"array" : @"nil");
    UICollectionViewLayout *base = [[UICollectionViewLayout alloc] init];
    L(@"base contentSize=%@ elements=%@ item=%@ shouldInvalidate=%d", S(base.collectionViewContentSize),
      [base layoutAttributesForElementsInRect:CGRectMake(0, 0, 100, 100)] ? @"array" : @"nil",
      [base layoutAttributesForItemAtIndexPath:zero] ? @"attrs" : @"nil",
      [base shouldInvalidateLayoutForBoundsChange:CGRectMake(0, 10, 100, 100)]);

    L(@"-- 4 subclass init and setter invalidation");
    OUKMasonryLayout *layout = [[OUKMasonryLayout alloc] initWithRank:2];
    layout.rank = 3;
    layout.rank = 2;

    L(@"-- 5 collection view in a window");
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    OUKGridSource *source = [OUKGridSource new];
    source.count = 5;
    source.headerHeight = 30;
    UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) collectionViewLayout:layout];
    L(@"created layout.collectionView=%@ cv.layout=%@", layout.collectionView == cv ? @"cv" : @"other",
      cv.collectionViewLayout == layout ? @"layout" : @"other");
    NoInsetAdjustment(cv);
    [cv registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [cv registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
          withReuseIdentifier:@"header"];
    cv.dataSource = source;
    cv.delegate = source;
    L(@"delegate roundtrip=%d dataSource roundtrip=%d", cv.delegate == (id)source, cv.dataSource == (id)source);
    [window addSubview:cv];
    L(@"added to window");
    [cv layoutIfNeeded];
    L(@"after layoutIfNeeded");
    LogCells(@"first", cv);
    L(@"layoutAttributesForItemAtIndexPath: via cv %@",
      R([cv layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]].frame));

    L(@"-- 6 bounds size change");
    cv.frame = CGRectMake(0, 0, 300, 480);
    L(@"frame set");
    [cv layoutIfNeeded];
    LogCells(@"resized", cv);

    L(@"-- 7 scroll");
    cv.contentOffset = CGPointMake(0, 100);
    L(@"offset set");
    [cv layoutIfNeeded];
    LogCells(@"scrolled", cv);

    L(@"-- 8 explicit invalidateLayout");
    source.count = 6;
    [layout invalidateLayout];
    L(@"invalidated");
    [cv layoutIfNeeded];
    LogCells(@"invalidated", cv);

    L(@"-- 9 flow subclass keeps UIKit geometry");
    OUKFlowSubclass *fl = [OUKFlowSubclass new];
    fl.itemSize = CGSizeMake(100, 40);
    fl.minimumInteritemSpacing = 10;
    fl.minimumLineSpacing = 5;
    fl.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    OUKGridSource *source2 = [OUKGridSource new];
    source2.count = 7;
    UICollectionView *cv2 = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 200) collectionViewLayout:fl];
    NoInsetAdjustment(cv2);
    [cv2 registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    cv2.dataSource = source2;
    [window addSubview:cv2];
    [cv2 layoutIfNeeded];
    LogCells(@"flow", cv2);
    L(@"flow item 6 %@", R([fl layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:6 inSection:0]].frame));

    L(@"-- 10 teardown");
    [cv removeFromSuperview];
    L(@"cv removed");
    [cv2 removeFromSuperview];
    L(@"cv2 removed");
    return [OUKFlowTrace() copy];
}
