// The Kingfisher stand-in must fail closed: no prefetch, cache lookup or
// processor ever produces an image the app did not already hold, and the
// `Stripe` umbrella must re-export both Stripe modules.
import Foundation
import XCTest
import Kingfisher
import KingfisherWebP
import KickstarterStripe
import UIKit

final class KingfisherStandInTests: XCTestCase {
    func testPrefetchReportsEveryResourceFailed() {
        let urls = [URL(string: "https://example.invalid/a.png")!, URL(string: "https://example.invalid/b.webp")!]
        let done = expectation(description: "prefetch completes")
        let prefetcher = ImagePrefetcher(resources: urls, options: [.processor(WebPProcessor.default)]) {
            skipped, failed, completed in
            XCTAssertTrue(skipped.isEmpty)
            XCTAssertTrue(completed.isEmpty)
            XCTAssertEqual(failed.map(\.cacheKey), urls.map(\.absoluteString))
            done.fulfill()
        }
        prefetcher.start()
        wait(for: [done], timeout: 5)
    }

    func testCacheIsAlwaysAMiss() {
        let done = expectation(description: "retrieve completes")
        ImageCache.default.retrieveImage(forKey: "https://example.invalid/a.png") { result in
            switch result {
            case .success(let r): XCTAssertNil(r.image)
            case .failure: XCTFail("a miss is .success(.none), as upstream reports it")
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
    }

    func testWebPDataDecodesToNothingAndIsNeverEncoded() {
        var riff = Data("RIFF".utf8)
        riff.append(Data([0, 0, 0, 0]))
        riff.append(Data("WEBPVP8 ".utf8))
        XCTAssertTrue(riff.isWebPFormat)
        let options = KingfisherParsedOptionsInfo(nil)
        XCTAssertNil(WebPProcessor.default.process(item: .data(riff), options: options))
        XCTAssertNil(WebPSerializer.default.image(with: riff, options: options))
        XCTAssertFalse(Data("not an image".utf8).isWebPFormat)
    }

    func testSourceKeepsTheNetworkURL() {
        let url = URL(string: "https://example.invalid/p.jpg")!
        let source = Source.network(url)
        XCTAssertEqual(source.url, url)
        XCTAssertEqual(source.cacheKey, url.absoluteString)
    }

    func testStripeUmbrellaReexportsBothModules() {
        // Compiles only if `import KickstarterStripe` (the `Stripe` umbrella)
        // re-exports StripePayments and StripeApplePay.
        let _: STPPaymentHandler.Type = STPPaymentHandler.self
        let _: STPApplePayContext.Type = STPApplePayContext.self
    }
}
