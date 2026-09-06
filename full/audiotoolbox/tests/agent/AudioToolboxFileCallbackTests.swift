import Foundation
import AudioToolbox

// Declaration authority: reference/public-surface.tsv, c:@T@AudioFile_*Proc.
// These C callback typedefs have no exact-USR nodes in api-digester.json.
// The fixtures below test calling the exported types, not AudioFile callback I/O.
// Positions/sizes above UInt32.max detect truncation; payloads/statuses are test
// inputs, not claims about an Apple file format, error code, or callback timing.
private struct ATFileCallbackProbe {
    var position: Int64 = 0
    var requested: UInt32 = 0
    var size: Int64 = 0
    var calls = 0
    var bytes: [UInt8] = []
    var result: Int32 = 0
}

func testAudioFileReadProcPartialTransfer() {
    let callback: AudioFile_ReadProc = { client, position, requested, buffer, actual in
        let state = client.assumingMemoryBound(to: ATFileCallbackProbe.self)
        state.pointee.calls += 1
        state.pointee.position = position
        state.pointee.requested = requested
        if state.pointee.result != 0 {
            actual.pointee = 0
            return state.pointee.result
        }
        let bytes = buffer.assumingMemoryBound(to: UInt8.self)
        bytes[0] = 0x12
        bytes[1] = 0xAB
        actual.pointee = 2
        return 0
    }
    var state = ATFileCallbackProbe()
    var bytes: [UInt8] = [0xCC, 0xCC, 0xCC, 0xCC]
    var actual: UInt32 = 99
    let position: Int64 = (1 << 40) + 7
    withUnsafeMutablePointer(to: &state) { client in
        bytes.withUnsafeMutableBytes { buffer in
            precondition(callback(client, position, 4, buffer.baseAddress!, &actual) == 0)
            precondition(actual == 2)
            client.pointee.result = -123
            precondition(callback(client, position, 4, buffer.baseAddress!, &actual) == -123)
            precondition(actual == 0)
        }
    }
    precondition(state.calls == 2 && state.position == position && state.requested == 4)
    precondition(bytes == [0x12, 0xAB, 0xCC, 0xCC])
}

func testAudioFileWriteProcPartialTransfer() {
    let callback: AudioFile_WriteProc = { client, position, requested, buffer, actual in
        let state = client.assumingMemoryBound(to: ATFileCallbackProbe.self)
        state.pointee.calls += 1
        state.pointee.position = position
        state.pointee.requested = requested
        if state.pointee.result != 0 {
            actual.pointee = 0
            return state.pointee.result
        }
        let bytes = buffer.assumingMemoryBound(to: UInt8.self)
        state.pointee.bytes = [bytes[0], bytes[1]]
        actual.pointee = 2
        return 0
    }
    var state = ATFileCallbackProbe()
    let bytes: [UInt8] = [0x34, 0xCD, 0x56, 0xEF]
    var actual: UInt32 = 99
    let position: Int64 = (1 << 40) + 11
    withUnsafeMutablePointer(to: &state) { client in
        bytes.withUnsafeBytes { buffer in
            precondition(callback(client, position, 4, buffer.baseAddress!, &actual) == 0)
            precondition(actual == 2)
            client.pointee.result = -456
            precondition(callback(client, position, 4, buffer.baseAddress!, &actual) == -456)
            precondition(actual == 0)
        }
    }
    precondition(state.calls == 2 && state.position == position && state.requested == 4)
    precondition(state.bytes == [0x34, 0xCD])
    precondition(bytes == [0x34, 0xCD, 0x56, 0xEF])
}

func testAudioFileGetSizeProcWideResult() {
    let callback: AudioFile_GetSizeProc = { client in
        let state = client.assumingMemoryBound(to: ATFileCallbackProbe.self)
        state.pointee.calls += 1
        return state.pointee.size
    }
    var state = ATFileCallbackProbe()
    let sizes: [Int64] = [0, (1 << 40) + 13, Int64.max]
    withUnsafeMutablePointer(to: &state) { client in
        for size in sizes {
            client.pointee.size = size
            precondition(callback(client) == size)
        }
    }
    precondition(state.calls == sizes.count)
}

func testAudioFileSetSizeProcWideArgument() {
    let callback: AudioFile_SetSizeProc = { client, size in
        let state = client.assumingMemoryBound(to: ATFileCallbackProbe.self)
        state.pointee.calls += 1
        if state.pointee.result != 0 { return state.pointee.result }
        state.pointee.size = size
        return 0
    }
    var state = ATFileCallbackProbe()
    let sizes: [Int64] = [0, (1 << 40) + 17, Int64.max]
    withUnsafeMutablePointer(to: &state) { client in
        for size in sizes {
            precondition(callback(client, size) == 0)
            precondition(client.pointee.size == size)
        }
        client.pointee.result = -789
        precondition(callback(client, 0) == -789)
        precondition(client.pointee.size == Int64.max)
    }
    precondition(state.calls == sizes.count + 1)
}
