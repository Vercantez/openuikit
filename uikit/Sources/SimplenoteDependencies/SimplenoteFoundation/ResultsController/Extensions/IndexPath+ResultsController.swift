import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


// MARK: - IndexPath
//
extension IndexPath {

    func transpose(toSection newSection: Int) -> IndexPath {
    #if os(iOS)
        return IndexPath(row: row, section: newSection)
    #elseif os(macOS)
        return IndexPath(item: item, section: newSection)
    #endif
    }

    #if os(macOS)
    init(row: Int, section: Int) {
        self.init(item: row, section: section)
    }
    #endif
}
