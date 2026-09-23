import Foundation

protocol DST { associatedtype Element }

class Base<Element>: NSObject {
    typealias CellFactory = (Int, Element) -> String
    let cellFactory: CellFactory
    init(cellFactory: @escaping CellFactory) { self.cellFactory = cellFactory }
}

class Wrapper<S: Sequence>: Base<S.Iterator.Element>, DST {
    typealias Element = S

}
let w = Wrapper<[Int]>(cellFactory: { (i: Int, e: Int) -> String in "\(e)" }); print(w.cellFactory(0, 3))
