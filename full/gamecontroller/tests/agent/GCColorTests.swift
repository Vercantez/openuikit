import Foundation
import Dispatch
import GameController

func testGCColorComponents() {
    let color = GCColor(red: 0.1, green: 0.2, blue: 0.3)
    precondition(color.red == 0.1)
    precondition(color.green == 0.2)
    precondition(color.blue == 0.3)
    do {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        color.encode(with: coder)
        let data = coder.encodedData
        let decoder = try NSKeyedUnarchiver(forReadingFrom: data)
        _ = GCColor(coder: decoder)
    } catch {
        _ = error
    }
    _ = GCColor.self
}
