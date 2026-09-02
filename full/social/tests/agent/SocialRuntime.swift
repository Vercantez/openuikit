@_spi(OpenUIKitHost) import Social
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@MainActor
final class AgentShareSheet: SLComposeServiceViewController {
    var configurationLoadCount = 0
    var postSelected = false
    var didSelectCancelCount = 0

    override func isContentValid() -> Bool {
        let text = contentText ?? ""
        return !text.isEmpty
    }

    override func configurationItems() -> [Any]! {
        configurationLoadCount += 1
        let account = SLComposeSheetConfigurationItem()
        account.title = "Account"
        account.value = "linux-host"
        account.valuePending = false
        return [account]
    }

    override func didSelectPost() {
        postSelected = true
        super.didSelectPost()
    }

    override func didSelectCancel() {
        didSelectCancelCount += 1
        super.didSelectCancel()
    }
}

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("SOCIAL_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
        exit(1)
    }
}

await MainActor.run {
#if SOCIAL_STANDALONE_TEST_FIXTURES
    require(
        SocialStandaloneUnitFixture.marker == "standalone-unit-fixture-only",
        "fixture marker"
    )
    print("SOCIAL_DYLIB_KIND=standalone-unit-fixture-only")
    print("SOCIAL_STANDALONE_UNIT_FIXTURE_ONLY")
#else
    print("SOCIAL_DYLIB_KIND=production")
#endif

    require(!SLServiceTypeTwitter.isEmpty, "twitter constant nonempty")
    require(!SLServiceTypeFacebook.isEmpty, "facebook constant nonempty")
    require(!SLServiceTypeSinaWeibo.isEmpty, "sina weibo constant nonempty")
    require(!SLServiceTypeTencentWeibo.isEmpty, "tencent weibo constant nonempty")
    require(!SLServiceTypeLinkedIn.isEmpty, "linkedin constant nonempty")
    require(
        Set(
            [
                SLServiceTypeTwitter,
                SLServiceTypeFacebook,
                SLServiceTypeSinaWeibo,
                SLServiceTypeTencentWeibo,
                SLServiceTypeLinkedIn,
            ]
        ).count == 5,
        "service constants distinct"
    )
    require(SocialServiceType.all.count == 5, "host service list")
    require(SocialServiceType.isKnown(SLServiceTypeTwitter), "known twitter")
    require(!SocialServiceType.isKnown("not.a.service"), "unknown service")

    require(SLRequestMethod.GET.rawValue == 0, "GET raw value")
    require(SLRequestMethod.POST.rawValue == 1, "POST raw value")
    require(SLRequestMethod.DELETE.rawValue == 2, "DELETE raw value")
    require(SLRequestMethod.PUT.rawValue == 3, "PUT raw value")
    require(SLRequestMethod.GET != .POST, "request method !=")
    require(SLRequestMethod(rawValue: 1) == .POST, "request method raw init")
    require(SLRequestMethod.GET.hashValue == SLRequestMethod.GET.hashValue, "GET hashValue")
    var methodHasher = Hasher()
    SLRequestMethod.PUT.hash(into: &methodHasher)
    _ = methodHasher.finalize()

    require(SLComposeViewControllerResult.cancelled.rawValue == 0, "cancelled raw")
    require(SLComposeViewControllerResult.done.rawValue == 1, "done raw")
    require(
        SLComposeViewControllerResult.cancelled != .done,
        "compose result !="
    )
    require(
        SLComposeViewControllerResult(rawValue: 0) == .cancelled,
        "compose result raw init"
    )
    var resultHasher = Hasher()
    SLComposeViewControllerResult.done.hash(into: &resultHasher)
    _ = resultHasher.finalize()
    require(
        SLComposeViewControllerResult.cancelled.hashValue
            == SLComposeViewControllerResult.cancelled.hashValue,
        "cancelled hashValue"
    )

    for service in SocialServiceType.all {
        require(
            SLComposeViewController.isAvailable(forServiceType: service) == false,
            "availability fail-closed for \(service)"
        )
    }
    require(
        SLComposeViewController.isAvailable(forServiceType: nil) == false,
        "nil service availability"
    )
    require(
        SLComposeViewController(forServiceType: nil) == nil,
        "nil service compose init"
    )
    require(
        SLComposeViewController(forServiceType: "") == nil,
        "empty service compose init"
    )

    let composer = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
    require(composer != nil, "twitter compose init")
    guard let composer else { return }
    require(composer.serviceType == SLServiceTypeTwitter, "composer serviceType")
    require(composer.setInitialText("Draft from Linux") == true, "setInitialText")
    require(composer.hostInitialText == "Draft from Linux", "draft text")
    require(composer.setInitialText(nil) == false, "nil initial text")
    require(composer.add(URL(string: "https://example.com/item")) == true, "add url")
    require(composer.hostURLs.count == 1, "url count")
    require(composer.add(UIImage()) == true, "add image")
    require(composer.hostImages.count == 1, "image count")
    require(composer.add(nil as UIImage?) == false, "nil image")
    require(composer.add(nil as URL?) == false, "nil url")
    require(composer.removeAllImages() == true, "remove images")
    require(composer.hostImages.isEmpty, "images cleared")
    require(composer.removeAllURLs() == true, "remove urls")
    require(composer.hostURLs.isEmpty, "urls cleared")

    var completionCount = 0
    var completion: SLComposeViewControllerResult?
    composer.completionHandler = {
        completionCount += 1
        completion = $0
    }
    composer.completeDraft(with: .cancelled)
    require(completion == .cancelled, "completion cancelled, never posted")
    require(composer.completionHandler == nil, "completionHandler cleared")
    composer.completeDraft(with: .done)
    require(completionCount == 1, "completionHandler invoked at most once")

    let item = SLComposeSheetConfigurationItem()
    item.title = "Visibility"
    item.value = "Public"
    item.valuePending = true
    require(item.title == "Visibility", "config title")
    require(item.value == "Public", "config value")
    require(item.valuePending, "config pending")
    var taps = 0
    let handler: SLComposeSheetConfigurationItemTapHandler = { taps += 1 }
    item.tapHandler = handler
    item.tapHandler()
    require(taps == 1, "config tap")
    item.valuePending = false
    require(item.valuePending == false, "config pending cleared")

    let sheet = AgentShareSheet()
    _ = sheet as any UITextViewDelegate
    require(sheet.contentText == "", "empty content")
    sheet.placeholder = "What's happening?"
    require(sheet.placeholder == "What's happening?", "placeholder")
    sheet.charactersRemaining = 140
    require(sheet.charactersRemaining.intValue == 140, "characters remaining")
    sheet.textView.text = "Share extension draft"
    require(sheet.contentText == "Share extension draft", "contentText")
    sheet.validateContent()
    require(sheet.hostContentIsValid, "valid content")
    sheet.textView.text = ""
    sheet.validateContent()
    require(sheet.hostContentIsValid == false, "invalid empty content")
    sheet.textView.text = "Share extension draft"

    let loaded = sheet.configurationItems() as? [SLComposeSheetConfigurationItem]
    require(loaded?.count == 1, "configuration items")
    require(loaded?.first?.title == "Account", "configuration title")
    sheet.reloadConfigurationItems()
    require(sheet.configurationLoadCount == 2, "reload configuration")

    sheet.presentationAnimationDidFinish()
    require(sheet.loadPreviewView() == nil, "preview fail-closed")
    sheet.autoCompletionViewController = UIViewController(nibName: nil, bundle: nil)
    require(sheet.autoCompletionViewController != nil, "autocomplete controller")

    let pushed = UIViewController(nibName: nil, bundle: nil)
    sheet.pushConfigurationViewController(pushed)
    require(sheet.hostConfigurationControllerCount == 1, "push config")
    sheet.pushConfigurationViewController(UIViewController(nibName: nil, bundle: nil))
    require(sheet.hostConfigurationControllerCount == 1, "second push rejected")
    sheet.pushConfigurationViewController(nil)
    require(sheet.hostConfigurationControllerCount == 1, "nil push ignored")
    sheet.popConfigurationViewController()
    require(sheet.hostConfigurationControllerCount == 0, "pop config")
    sheet.popConfigurationViewController()
    require(sheet.hostConfigurationControllerCount == 0, "pop empty")

    sheet.didSelectPost()
    require(sheet.postSelected, "didSelectPost overridable")
    require(
        sheet.hostExtensionCompletion == .postedWithoutExtensionContext,
        "post completion is partial without extension context"
    )
    sheet.cancel()
    require(sheet.didSelectCancelCount == 1, "cancel triggers didSelectCancel")
    require(
        sheet.hostExtensionCompletion == .cancelledWithoutExtensionContext,
        "cancel completion is partial without extension context"
    )
    sheet.cancel()
    require(sheet.didSelectCancelCount == 2, "second cancel still one-way")

    let missingURL = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .GET,
        url: nil,
        parameters: nil
    )
    require(missingURL == nil, "request requires URL")

    let getURL = URL(string: "https://api.example.com/1.1/statuses/home_timeline.json")!
    let get = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .GET,
        url: getURL,
        parameters: ["count": "1", "trim_user": "true"]
    )
    require(get != nil, "GET request")
    guard let get else { return }
    require(get.requestMethod == .GET, "GET method")
    require(get.url == getURL, "GET url")
    require((get.parameters["count"] as? String) == "1", "GET parameters")
    require(get.hostServiceType == SLServiceTypeTwitter, "GET service")
    let preparedGET = get.preparedURLRequest()
    require(preparedGET != nil, "prepared GET")
    require(preparedGET?.httpMethod == "GET", "GET http method")
    let getQuery = preparedGET?.url?.query ?? ""
    require(getQuery.contains("count=1"), "GET query count")
    require(getQuery.contains("trim_user=true"), "GET query trim")

    let legacy = SLRequest(
        forServiceType: SLServiceTypeFacebook,
        requestMethod: .DELETE,
        URL: URL(string: "https://graph.example.com/v2.0/me/feed/1")!,
        parameters: nil
    )
    require(legacy != nil, "legacy URL: labeled init")
    require(legacy?.preparedURLRequest()?.httpMethod == "DELETE", "DELETE method")

    let post = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .POST,
        url: URL(string: "https://api.example.com/1.1/statuses/update.json")!,
        parameters: ["status": "hello world"]
    )!
    let preparedPOST = post.preparedURLRequest()!
    require(preparedPOST.httpMethod == "POST", "POST method")
    let postBody = String(data: preparedPOST.httpBody ?? Data(), encoding: .utf8) ?? ""
    require(postBody.contains("status=hello+world"), "POST form body uses plus")
    require(!postBody.contains("hello%20world"), "POST form body does not use %20")
    require(
        preparedPOST.value(forHTTPHeaderField: "Content-Type")?
            .contains("application/x-www-form-urlencoded") == true,
        "POST content type"
    )

    func formBody(_ value: String) -> String {
        let request = SLRequest(
            forServiceType: SLServiceTypeTwitter,
            requestMethod: .POST,
            url: URL(string: "https://api.example.com/1.1/statuses/update.json")!,
            parameters: ["q": value]
        )!
        return String(data: request.preparedURLRequest()!.httpBody ?? Data(), encoding: .utf8) ?? ""
    }
    require(formBody("C++") == "q=C%2B%2B", "literal plus encodes as %2B")
    require(formBody("a+b c") == "q=a%2Bb+c", "plus percent-encoded then space as plus")
    require(formBody("café") == "q=caf%C3%A9", "unicode percent-encoded")
    require(formBody("日本語") == "q=%E6%97%A5%E6%9C%AC%E8%AA%9E", "multibyte unicode")
    require(formBody("a&b=c%d") == "q=a%26b%3Dc%25d", "reserved bytes percent-encoded")
    require(!formBody("C++").contains("C++"), "literal plus is not left unencoded")
    require(!formBody("a+b c").contains("a+b+c"), "space substitution does not preserve literal plus")

    let put = SLRequest(
        forServiceType: SLServiceTypeFacebook,
        requestMethod: .PUT,
        url: URL(string: "https://graph.example.com/v2.0/me")!,
        parameters: ["name": "OpenUIKit"]
    )!
    require(put.preparedURLRequest()?.httpMethod == "PUT", "PUT method")

    post.addMultipartData(
        Data("image-bytes".utf8),
        withName: "media[]",
        type: "image/png",
        filename: "draft.png"
    )
    require(post.hostMultipartParts.count == 1, "multipart stored")
    let multipart = post.preparedURLRequest()!
    require(
        multipart.value(forHTTPHeaderField: "Content-Type")?
            .contains("multipart/form-data") == true,
        "multipart content type"
    )
    let multipartHeader = multipart.value(forHTTPHeaderField: "Content-Type") ?? ""
    require(multipartHeader.contains("boundary="), "multipart boundary")
    let multipartBody = String(data: multipart.httpBody ?? Data(), encoding: .utf8) ?? ""
    require(multipartBody.contains("draft.png"), "multipart filename")
    require(multipartBody.contains("image-bytes"), "multipart payload")

    let beforeReject = post.hostMultipartParts.count
    post.addMultipartData(
        Data("bad".utf8),
        withName: "na\nme",
        type: "text/plain",
        filename: "ok.txt"
    )
    post.addMultipartData(
        Data("bad".utf8),
        withName: "name",
        type: "text/pla\"in",
        filename: "ok.txt"
    )
    post.addMultipartData(
        Data("bad".utf8),
        withName: "name",
        type: "text/plain",
        filename: "ok\r.txt"
    )
    require(post.hostMultipartParts.count == beforeReject, "multipart metadata rejected")

    post.account = ACAccount()
    require(post.account != nil, "account assignable")
    require(post.preparedURLRequest() == nil, "account without OAuth signer fails closed")

    var performCalls = 0
    post.perform { data, response, error in
        performCalls += 1
        require(data == nil, "perform data fail-closed")
        require(response == nil, "perform response fail-closed")
        let serviceError = error as? SocialServiceError
        require(
            serviceError?.code == .accountServiceUnavailable,
            "perform account-service error"
        )
    }
    require(performCalls == 1, "perform invoked synchronously")
    post.perform(handler: nil)

    post.account = nil
    require(post.preparedURLRequest() != nil, "unsigned request when account is nil")

    print("SOCIAL_AGENT_RUNTIME_OK")
}
