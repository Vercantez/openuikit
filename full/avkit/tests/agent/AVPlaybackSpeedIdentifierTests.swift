import Foundation
import AVKit

func testPlaybackSpeedClassStoresRate() {
    let speed = AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×")
    _ = speed
    precondition(speed.rate == 1.5)
}

func testPlaybackSpeedSystemDefaultSpeedsList() {
    let speeds = AVPlaybackSpeed.systemDefaultSpeeds
    precondition(speeds.count == 5)
    precondition(speeds[0].rate == 2.0)
    precondition(speeds[0].localizedName == "Double")
    precondition(speeds[1].rate == 1.5)
    precondition(speeds[2].rate == 1.25)
    precondition(speeds[3].rate == 1.0)
    precondition(speeds[3].localizedName == "Normal")
    precondition(speeds[4].rate == 0.5)
    precondition(AVPlaybackSpeed.systemDefaultSpeeds[3] === speeds[3])
}

func testPlaybackSpeedInitRateLocalizedName() {
    let speed = AVPlaybackSpeed(rate: 3, localizedName: "custom")
    precondition(speed.rate == 3)
    precondition(speed.localizedName == "custom")
}

func testPlaybackSpeedLocalizedName() {
    let speed = AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×")
    precondition(speed.localizedName == "1.5×")
    precondition(AVPlaybackSpeed.systemDefaultSpeeds[3].localizedName == "Normal")
}

func testPlaybackSpeedLocalizedNumericName() {
    precondition(AVPlaybackSpeed.systemDefaultSpeeds[0].localizedNumericName == "2\u{00D7}")
    precondition(AVPlaybackSpeed.systemDefaultSpeeds[1].localizedNumericName == "1.5\u{00D7}")
    let custom = AVPlaybackSpeed(rate: 3, localizedName: "custom")
    precondition(custom.localizedNumericName == "3\u{00D7}")
    let threeHalves = AVPlaybackSpeed(rate: 2.5, localizedName: "custom")
    precondition(threeHalves.localizedNumericName == "2.5\u{00D7}")
}

func testPlaybackSpeedRate() {
    let speed = AVPlaybackSpeed(rate: 0.5, localizedName: "Half")
    precondition(speed.rate == 0.5)
}
