import Foundation
import Accessibility

func testLiveAudioGraphStateMachine() {
    AXLiveAudioGraph.stop()
    AXLiveAudioGraph.updateValue(3.5)
    AXLiveAudioGraph.start()
    AXLiveAudioGraph.updateValue(1.25)
    AXLiveAudioGraph.stop()
    AXLiveAudioGraph.start()
    AXLiveAudioGraph.stop()
    _ = AXLiveAudioGraph.self
}
