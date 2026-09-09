import Foundation
import ProbeHeader
import ProbeImpl

/// The same failure from another module: an app's `class Cell: UITableViewCell`.
final class ClientCell: ProbeLabel {
    override init(frame: CGRect) { super.init(frame: frame) }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}
