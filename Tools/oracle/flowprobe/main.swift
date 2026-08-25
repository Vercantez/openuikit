// Flow-layout probe (round 2): what makes UIKit space a LAST line as if it
// were full, versus falling back to the minimum interitem spacing?
import UIKit

final class Cell: UICollectionViewCell {}
final class Supp: UICollectionReusableView {}

final class DS: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let counts: [Int]
    let sizeFor: ((IndexPath) -> CGSize)?
    init(_ c: [Int], sizeFor: ((IndexPath) -> CGSize)? = nil) {
        counts = c
        self.sizeFor = sizeFor
    }
    func numberOfSections(in cv: UICollectionView) -> Int { counts.count }
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { counts[s] }
    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        cv.dequeueReusableCell(withReuseIdentifier: "c", for: ip)
    }
    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt ip: IndexPath) -> CGSize {
        sizeFor?(ip) ?? (layout as! UICollectionViewFlowLayout).itemSize
    }
}

var keep: [AnyObject] = []

func probe(_ name: String, width: CGFloat, height: CGFloat, counts: [Int],
           useDelegate: Bool = true,
           sizeFor: ((IndexPath) -> CGSize)? = nil,
           configure: (UICollectionViewFlowLayout) -> Void) {
    let layout = UICollectionViewFlowLayout()
    configure(layout)
    let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: width, height: height),
                              collectionViewLayout: layout)
    cv.contentInsetAdjustmentBehavior = .never
    cv.register(Cell.self, forCellWithReuseIdentifier: "c")
    let ds = DS(counts, sizeFor: sizeFor)
    keep.append(ds); keep.append(cv)
    cv.dataSource = ds
    if useDelegate { cv.delegate = ds }
    cv.layoutIfNeeded()
    print("== \(name)  contentSize=\(cv.contentSize)")
    for s in 0..<counts.count {
        for i in 0..<counts[s] {
            if let a = layout.layoutAttributesForItem(at: IndexPath(item: i, section: s)) {
                print("   item [\(s),\(i)] \(a.frame)")
            }
        }
    }
}

// X: uniform delegate size that DIFFERS from layout.itemSize.
probe("X uniform 80x40 via delegate, itemSize left at 50x50", width: 375, height: 300,
      counts: [4], sizeFor: { _ in CGSize(width: 80, height: 40) }) { l in
    l.minimumLineSpacing = 10
    l.minimumInteritemSpacing = 10
    l.sectionInset = .zero
}

// Y: same, but the layout's itemSize matches what the delegate returns.
probe("Y uniform 80x40 via delegate, itemSize also 80x40", width: 375, height: 300,
      counts: [4], sizeFor: { _ in CGSize(width: 80, height: 40) }) { l in
    l.itemSize = CGSize(width: 80, height: 40)
    l.minimumLineSpacing = 10
    l.minimumInteritemSpacing = 10
    l.sectionInset = .zero
}

// Z: no delegate at all, itemSize 80x40 (the pure fast path).
probe("Z no delegate, itemSize 80x40", width: 375, height: 300, counts: [4],
      useDelegate: false) { l in
    l.itemSize = CGSize(width: 80, height: 40)
    l.minimumLineSpacing = 10
    l.minimumInteritemSpacing = 10
    l.sectionInset = .zero
}

// AA: last line, equal widths, ONE different height (probe Q, isolated).
probe("AA equal widths, one taller", width: 375, height: 300, counts: [4],
      sizeFor: { ip in CGSize(width: 80, height: ip.item == 1 ? 90 : 40) }) { l in
    l.itemSize = CGSize(width: 80, height: 40)
    l.minimumLineSpacing = 10
    l.minimumInteritemSpacing = 10
    l.sectionInset = .zero
}

// AB: last line, DIFFERENT widths.
probe("AB different widths on the last line", width: 375, height: 300, counts: [3],
      sizeFor: { ip in CGSize(width: [80, 100, 60][ip.item], height: 40) }) { l in
    l.itemSize = CGSize(width: 80, height: 40)
    l.minimumLineSpacing = 10
    l.minimumInteritemSpacing = 10
    l.sectionInset = .zero
}

// AC: two lines, first full and uniform, last line uniform but shorter.
probe("AC 5 uniform items, 4 fit per line", width: 375, height: 300, counts: [5],
      sizeFor: { _ in CGSize(width: 80, height: 40) }) { l in
    l.itemSize = CGSize(width: 80, height: 40)
    l.minimumLineSpacing = 10
    l.minimumInteritemSpacing = 10
    l.sectionInset = .zero
}

// AD: heterogeneous heights, but the line is FULL (5 items of 80 do not fit).
probe("AD full line with one taller item", width: 375, height: 300, counts: [5],
      sizeFor: { ip in CGSize(width: 80, height: ip.item == 1 ? 90 : 40) }) { l in
    l.itemSize = CGSize(width: 80, height: 40)
    l.minimumLineSpacing = 10
    l.minimumInteritemSpacing = 10
    l.sectionInset = .zero
}

// AE: heterogeneous heights only in a LATER section (does uniformity get
// decided per section or per line?).
probe("AE section 0 uniform, section 1 heterogeneous", width: 375, height: 400,
      counts: [3, 3],
      sizeFor: { ip in
    CGSize(width: 80, height: (ip.section == 1 && ip.item == 1) ? 90 : 40)
}) { l in
    l.itemSize = CGSize(width: 80, height: 40)
    l.minimumLineSpacing = 10
    l.minimumInteritemSpacing = 10
    l.sectionInset = .zero
}
