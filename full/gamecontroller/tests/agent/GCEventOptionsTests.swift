import Foundation
import Dispatch
import GameController

func testEventHandlingOptions() {
    _ = GameControllerEventHandlingOptions()
    _ = GameControllerEventHandlingOptions.receivesEventsInView(true)
    var options = GameControllerEventHandlingOptions()
    options.receivesEventsInView = true
    precondition(options.receivesEventsInView)
    _ = GameControllerEventHandlingOptions.self
}
