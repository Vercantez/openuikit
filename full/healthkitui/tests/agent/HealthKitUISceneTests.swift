import Foundation
import HealthKitUI

func testShouldHandleActiveWorkoutRecovery() {
    let options = UIScene.ConnectionOptions()
    precondition(!options.shouldHandleActiveWorkoutRecovery)
}
