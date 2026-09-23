// Minimal reproducer (Apple UIKit, stock SDK) for the RxCocoa 4.1.2 overlay; see README.md.
import UIKit

class Base: NSObject, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 0 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { fatalError() }
}
protocol P { func f() }
class Mid<E>: Base {
    typealias CellFactory = (UITableView, Int, E) -> UITableViewCell
    let cellFactory: CellFactory
    init(cellFactory: @escaping CellFactory) { self.cellFactory = cellFactory }
}
class Leaf<S: Sequence>: Mid<S.Iterator.Element>, P {
    override init(cellFactory: @escaping CellFactory) { super.init(cellFactory: cellFactory) }
    func f() {}
}
