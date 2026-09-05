import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

final class MPMediaPickerSink: NSObject, MPMediaPickerControllerDelegate {
    var cancelled = 0
    var picked = 0

    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        _ = mediaPicker
        cancelled += 1
    }

    func mediaPicker(
        _ mediaPicker: MPMediaPickerController,
        didPickMediaItems mediaItemCollection: MPMediaItemCollection
    ) {
        _ = mediaPicker
        _ = mediaItemCollection
        picked += 1
    }
}

func testMediaPickerDefaults() {
    let sem = DispatchSemaphore(value: 0)
    Task { @MainActor in
        let picker = MPMediaPickerController(mediaTypes: .music)
        precondition(picker.mediaTypes == .music)
        precondition(!picker.allowsPickingMultipleItems)
        precondition(picker.showsCloudItems)
        precondition(picker.showsItemsWithProtectedAssets)
        precondition(picker.prompt == nil)
        let sink = MPMediaPickerSink()
        picker.delegate = sink
        let asDel: any MPMediaPickerControllerDelegate = sink
        asDel.mediaPickerDidCancel(picker)
        asDel.mediaPicker(picker, didPickMediaItems: MPMediaItemCollection(items: []))
        precondition(sink.cancelled == 1 && sink.picked == 1)
        sem.signal()
    }
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
}
