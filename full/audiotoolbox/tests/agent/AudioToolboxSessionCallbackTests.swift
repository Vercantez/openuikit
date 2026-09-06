import Foundation
import AudioToolbox

// Declaration authority: reference/public-surface.tsv and the sealed symbol graph,
// c:@T@AudioSessionInterruptionListener: client pointer first, UInt32 state second.
// api-crosswalk.tsv records no matching API-digester node for this typedef.
// Direct C callback invocation tests the signature, not system interruption delivery.
private struct ATInterruptionCallbackProbe {
    var calls = 0
    var state: UInt32 = 0
}

func testAudioSessionInterruptionListenerArgumentOrder() {
    let callback: AudioSessionInterruptionListener = { client, interruption in
        guard let client else {
            precondition(interruption == UInt32.max)
            return
        }
        let probe = client.assumingMemoryBound(to: ATInterruptionCallbackProbe.self)
        probe.pointee.calls += 1
        probe.pointee.state = interruption
    }
    var probe = ATInterruptionCallbackProbe()
    withUnsafeMutablePointer(to: &probe) { client in
        for state: UInt32 in [0, 1, UInt32.max] {
            callback(client, state)
            precondition(client.pointee.state == state)
        }
    }
    precondition(probe.calls == 3)
    callback(nil, UInt32.max)
}
