import Foundation
import Social

@MainActor
final class AgentShareSheet: SLComposeServiceViewController {
    var configurationLoadCount = 0
    var postSelected = false

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
}

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("SOCIAL_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
        exit(1)
    }
}

await MainActor.run {
    require(
        SLServiceTypeTwitter == "com.apple.social.twitter",
        "twitter service type"
    )
    require(
        SLServiceTypeFacebook == "com.apple.social.facebook",
        "facebook service type"
    )
    require(
        SLServiceTypeSinaWeibo == "com.apple.social.sinaweibo",
        "sina weibo service type"
    )
    require(
        SLServiceTypeTencentWeibo == "com.apple.social.tencentweibo",
        "tencent weibo service type"
    )
    require(
        SLServiceTypeLinkedIn == "com.apple.social.linkedin",
        "linkedin service type"
    )
    require(Set(SocialServiceType.all).count == 5, "unique service types")
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
    require(composer.portableInitialText == "Draft from Linux", "draft text")
    require(composer.setInitialText(nil) == false, "nil initial text")
    require(composer.add(URL(string: "https://example.com/item")) == true, "add url")
    require(composer.portableURLs.count == 1, "url count")
    require(composer.add(UIImage()) == true, "add image")
    require(composer.portableImages.count == 1, "image count")
    require(composer.add(nil as UIImage?) == false, "nil image")
    require(composer.add(nil as URL?) == false, "nil url")
    require(composer.removeAllImages() == true, "remove images")
    require(composer.portableImages.isEmpty, "images cleared")
    require(composer.removeAllURLs() == true, "remove urls")
    require(composer.portableURLs.isEmpty, "urls cleared")

    var completion: SLComposeViewControllerResult?
    composer.completionHandler = { completion = $0 }
    composer.completeDraft(with: .cancelled)
    require(completion == .cancelled, "completion cancelled, never posted")

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
    require(sheet.contentText == "", "empty content")
    sheet.placeholder = "What's happening?"
    require(sheet.placeholder == "What's happening?", "placeholder")
    sheet.charactersRemaining = 140
    require(sheet.charactersRemaining.intValue == 140, "characters remaining")
    sheet.textView.text = "Share extension draft"
    require(sheet.contentText == "Share extension draft", "contentText")
    sheet.validateContent()
    require(sheet.portableContentIsValid, "valid content")
    sheet.textView.text = ""
    sheet.validateContent()
    require(sheet.portableContentIsValid == false, "invalid empty content")
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
    require(sheet.portableConfigurationStackCount == 1, "push config")
    sheet.pushConfigurationViewController(nil)
    require(sheet.portableConfigurationStackCount == 1, "nil push ignored")
    sheet.popConfigurationViewController()
    require(sheet.portableConfigurationStackCount == 0, "pop config")
    sheet.popConfigurationViewController()
    require(sheet.portableConfigurationStackCount == 0, "pop empty")

    sheet.didSelectPost()
    require(sheet.postSelected, "didSelectPost overridable")
    require(sheet.portableDidCancel == false, "post is not cancel")
    sheet.didSelectCancel()
    require(sheet.portableDidCancel, "didSelectCancel calls cancel")

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
    require(get.portableServiceType == SLServiceTypeTwitter, "GET service")
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
    require(postBody.contains("status=hello"), "POST form body")
    require(
        preparedPOST.value(forHTTPHeaderField: "Content-Type")?
            .contains("application/x-www-form-urlencoded") == true,
        "POST content type"
    )

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
    require(post.portableMultipartParts.count == 1, "multipart stored")
    let multipart = post.preparedURLRequest()!
    require(
        multipart.value(forHTTPHeaderField: "Content-Type")?
            .contains("multipart/form-data") == true,
        "multipart content type"
    )
    let multipartBody = String(data: multipart.httpBody ?? Data(), encoding: .utf8) ?? ""
    require(multipartBody.contains("draft.png"), "multipart filename")
    require(multipartBody.contains("image-bytes"), "multipart payload")

    post.account = ACAccount()
    require(post.account != nil, "account placeholder assignable")

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

    print("SOCIAL_AGENT_RUNTIME_OK")
}
