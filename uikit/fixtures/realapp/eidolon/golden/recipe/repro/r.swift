import Foundation

protocol DST { associatedtype Element }

class Base<Element>: NSObject {
    typealias CellFactory = (Int, Element) -> String
    let cellFactory: CellFactory
    init(cellFactory: @escaping CellFactory) { self.cellFactory = cellFactory }
}

class Wrapper<S: Sequence>: Base<S.Iterator.Element>, DST {
    typealias Element = S
    override init(cellFactory: @escaping CellFactory) { super.init(cellFactory: cellFactory) }
}
