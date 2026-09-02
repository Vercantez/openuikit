import Foundation
import XCTest
@_spi(OpenUIKitHost) @testable import OpenUIKit

#if canImport(ObjectiveC)
private final class PhotoLibraryCompletionTarget: NSObject {
    var invocationCount = 0
    var receivedImage: AnyObject?
    var receivedError: NSError?
    var receivedContext: UnsafeMutableRawPointer?

    @objc(savedImage:didFinishSavingWithError:contextInfo:)
    func savedImage(
        _ image: AnyObject,
        didFinishSavingWithError error: NSError?,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        invocationCount += 1
        receivedImage = image
        receivedError = error
        receivedContext = contextInfo
    }
}
#endif

private final class PortablePhotoLibraryCompletionTarget:
    UIImagePhotoLibrarySaveCompletionDispatching {
    var invocationCount = 0
    var receivedName: String?
    var receivedImage: UIImage?
    var receivedError: UIImagePhotoLibrarySaveError?
    var receivedContext: UnsafeMutableRawPointer?

    func _openUIKitPerformPhotoLibrarySaveCompletion(
        _ selectorName: String,
        image: UIImage,
        error: UIImagePhotoLibrarySaveError?,
        contextInfo: UnsafeMutableRawPointer?
    ) -> Bool {
        invocationCount += 1
        receivedName = selectorName
        receivedImage = image
        receivedError = error
        receivedContext = contextInfo
        return true
    }
}

final class PhotoLibrarySaveTests: XCTestCase {
    override func tearDown() {
        OpenUIKitRuntime.photoLibrarySaveHandler = nil
        super.tearDown()
    }

    private func makeImage() -> UIImage {
        let bitmap = Bitmap(width: 2, height: 1)
        bitmap.pixels = [255, 0, 0, 255, 0, 64, 255, 128]
        return UIImage(bitmap: bitmap, scale: 2)
    }

    func testNilCompletionStillHandsOriginalImageToHost() {
        let image = makeImage()
        var received: UIImage?
        OpenUIKitRuntime.photoLibrarySaveHandler = { candidate, completion in
            received = candidate
            completion(.success)
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        XCTAssertTrue(received === image)
    }

    func testHostMayCompleteAsynchronouslyAndContextIsPreserved() {
#if canImport(ObjectiveC)
        let image = makeImage()
        let target = PhotoLibraryCompletionTarget()
        let context = UnsafeMutableRawPointer(bitPattern: 0x13579)
        var finish: ((UIImagePhotoLibrarySaveResult) -> Void)?
        OpenUIKitRuntime.photoLibrarySaveHandler = { candidate, completion in
            XCTAssertTrue(candidate === image)
            finish = completion
        }

        UIImageWriteToSavedPhotosAlbum(
            image,
            target,
            #selector(PhotoLibraryCompletionTarget.savedImage(
                _:didFinishSavingWithError:contextInfo:
            )),
            context
        )

        XCTAssertEqual(target.invocationCount, 0)
        finish?(.success)
        XCTAssertEqual(target.invocationCount, 1)
        XCTAssertTrue(target.receivedImage === image)
        XCTAssertNil(target.receivedError)
        XCTAssertEqual(target.receivedContext, context)
#endif
    }

    func testHostFailureBecomesNSErrorWithStableDomainAndCode() {
#if canImport(ObjectiveC)
        let image = makeImage()
        let target = PhotoLibraryCompletionTarget()
        let failure = UIImagePhotoLibrarySaveError(
            code: .permissionDenied,
            description: "add access denied"
        )
        OpenUIKitRuntime.photoLibrarySaveHandler = { _, completion in
            completion(.failure(failure))
        }

        UIImageWriteToSavedPhotosAlbum(
            image,
            target,
            #selector(PhotoLibraryCompletionTarget.savedImage(
                _:didFinishSavingWithError:contextInfo:
            )),
            nil
        )

        XCTAssertEqual(target.invocationCount, 1)
        XCTAssertEqual(
            target.receivedError?.domain,
            UIImagePhotoLibrarySaveError.errorDomain
        )
        XCTAssertEqual(
            target.receivedError?.code,
            UIImagePhotoLibrarySaveError.Code.permissionDenied.rawValue
        )
#endif
    }

    func testMissingHostFailsClosedInsteadOfReportingSuccess() {
#if canImport(ObjectiveC)
        let target = PhotoLibraryCompletionTarget()
        UIImageWriteToSavedPhotosAlbum(
            makeImage(),
            target,
            #selector(PhotoLibraryCompletionTarget.savedImage(
                _:didFinishSavingWithError:contextInfo:
            )),
            nil
        )

        XCTAssertEqual(target.invocationCount, 1)
        XCTAssertEqual(
            target.receivedError?.code,
            UIImagePhotoLibrarySaveError.Code.unavailable.rawValue
        )
#endif
    }

    func testMisbehavingHostCannotDeliverCompletionTwice() {
#if canImport(ObjectiveC)
        let target = PhotoLibraryCompletionTarget()
        OpenUIKitRuntime.photoLibrarySaveHandler = { _, completion in
            completion(.success)
            completion(.failure(.unavailable))
        }

        UIImageWriteToSavedPhotosAlbum(
            makeImage(),
            target,
            #selector(PhotoLibraryCompletionTarget.savedImage(
                _:didFinishSavingWithError:contextInfo:
            )),
            nil
        )

        XCTAssertEqual(target.invocationCount, 1)
        XCTAssertNil(target.receivedError)
#endif
    }

    func testPortableThreeArgumentSelectorFallback() {
        let image = makeImage()
        let target = PortablePhotoLibraryCompletionTarget()
        let context = UnsafeMutableRawPointer(bitPattern: 0x2468)
        let failure = UIImagePhotoLibrarySaveError(
            code: .writeFailed,
            description: "storage rejected image"
        )
        OpenUIKitRuntime.photoLibrarySaveHandler = { _, completion in
            completion(.failure(failure))
        }

        UIImageWriteToSavedPhotosAlbum(
            image,
            target,
            Selector.named("savedImage:didFinishSavingWithError:contextInfo:"),
            context
        )

        XCTAssertEqual(target.invocationCount, 1)
        XCTAssertEqual(
            target.receivedName,
            "savedImage:didFinishSavingWithError:contextInfo:"
        )
        XCTAssertTrue(target.receivedImage === image)
        XCTAssertEqual(target.receivedError, failure)
        XCTAssertEqual(target.receivedContext, context)
    }

    func testWrongArityFailsClosedWithoutInvokingTarget() {
        let target = PortablePhotoLibraryCompletionTarget()
        OpenUIKitRuntime.photoLibrarySaveHandler = { _, completion in
            completion(.success)
        }

        UIImageWriteToSavedPhotosAlbum(
            makeImage(), target, Selector.named("savedImage:"), nil
        )

        XCTAssertEqual(target.invocationCount, 0)
        XCTAssertNil(target.receivedName)
    }
}
