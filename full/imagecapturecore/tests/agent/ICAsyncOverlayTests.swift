@_spi(OpenUIKitHost) import ImageCaptureCore
import Foundation

func testICDeviceOpenSessionOptionsCompletionFailClosed() {
    let device = ICDevice.hostMakeDevice(type: .camera, name: "Cam")
    var completionError: (any Error)?
    var calls = 0
    device.requestOpenSession(options: nil) { error in
        calls += 1
        completionError = error
    }
    precondition(calls == 1)
    precondition(!device.hasOpenSession)
    precondition((completionError as? ICReturn)?.code == .deviceFailedToOpenSession)
}

func testICDeviceCloseSessionOptionsCompletionFailClosed() {
    let device = ICDevice.hostMakeDevice(type: .camera)
    var completionError: (any Error)?
    var calls = 0
    device.requestCloseSession(options: nil) { error in
        calls += 1
        completionError = error
    }
    precondition(calls == 1)
    precondition(!device.hasOpenSession)
    precondition((completionError as? ICReturn)?.code == .sessionNotOpened)
}

func testICCameraDeviceSendPTPCommandCompletionFailClosed() {
    let camera = ICCameraDevice.hostMakeCamera(name: "EOS")
    var response: Data?
    var outData: Data?
    var completionError: (any Error)?
    var calls = 0
    camera.requestSendPTPCommand(Data([0x10, 0x20]), outData: nil) { first, second, error in
        calls += 1
        response = first
        outData = second
        completionError = error
    }
    precondition(calls == 1)
    precondition(response == nil)
    precondition(outData == nil)
    precondition((completionError as? ICReturnPTPDeviceError)?.code == .failedToSendCommand)
}

func testICCameraFileMetadataDictionaryCompletionFailClosed() {
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: nil)
    var dictionary: [AnyHashable: Any]?
    var completionError: (any Error)?
    var calls = 0
    file.requestMetadataDictionary(options: nil) { value, error in
        calls += 1
        dictionary = value
        completionError = error
    }
    precondition(calls == 1)
    precondition(dictionary == nil)
    precondition((completionError as? ICReturnMetadataError)?.code == .notAvailable)
}

func testICCameraFileReadDataCompletionFailClosed() {
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: nil)
    var data: Data? = Data([0xFF])
    var completionError: (any Error)?
    file.requestReadData(atOffset: 0, length: 16) { value, error in
        data = value
        completionError = error
    }
    precondition(data == nil)
    precondition((completionError as? ICReturnObjectError)?.code == .codeObjectCouldNotBeRead)

    var offsetError: (any Error)?
    file.requestReadData(atOffset: -1, length: 16) { _, error in
        offsetError = error
    }
    precondition((offsetError as? ICReturnObjectError)?.code == .codeObjectDataOffsetInvalid)

    var lengthError: (any Error)?
    file.requestReadData(atOffset: 0, length: 0) { _, error in
        lengthError = error
    }
    precondition((lengthError as? ICReturnObjectError)?.code == .codeObjectDataEmpty)
}

func testICCameraFileThumbnailDataCompletionFailClosed() {
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: nil)
    var data: Data? = Data([0xFF])
    var completionError: (any Error)?
    var calls = 0
    file.requestThumbnailData(options: nil) { value, error in
        calls += 1
        data = value
        completionError = error
    }
    precondition(calls == 1)
    precondition(data == nil)
    precondition((completionError as? ICReturnThumbnailError)?.code == .notAvailable)
}
