@_spi(OpenUIKitHost) import Social
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("SOCIAL_FORM_URLENCODE_FAIL: \(message)\n", stderr)
        exit(1)
    }
}

let url = URL(string: "https://api.example.com/1.1/statuses/update.json")!

func body(for value: String, key: String = "q") -> String {
    let request = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .POST,
        url: url,
        parameters: [key: value]
    )!
    let prepared = request.preparedURLRequest()!
    require(
        prepared.value(forHTTPHeaderField: "Content-Type")?
            .contains("application/x-www-form-urlencoded") == true,
        "urlencoded content type"
    )
    return String(data: prepared.httpBody ?? Data(), encoding: .utf8) ?? ""
}

require(body(for: "C++") == "q=C%2B%2B", "C++ -> C%2B%2B")
require(body(for: "a+b c") == "q=a%2Bb+c", "a+b c -> a%2Bb+c")
require(body(for: "hello world") == "q=hello+world", "spaces become plus")
require(!body(for: "hello world").contains("%20"), "spaces are not %20")
require(body(for: "café") == "q=caf%C3%A9", "unicode é")
require(body(for: "日本語") == "q=%E6%97%A5%E6%9C%AC%E8%AA%9E", "unicode CJK")
require(body(for: "a&b=c%d") == "q=a%26b%3Dc%25d", "reserved & = %")
require(body(for: "#[]") == "q=%23%5B%5D", "reserved # []")
require(body(for: "star*") == "q=star*", "unreserved star remains")
require(body(for: "C++") != "q=C++", "literal plus is not globally allowed")
require(body(for: "a+b c") != "q=a+b+c", "do not encode after substituting spaces with allowed plus")

print("SOCIAL_FORM_URLENCODE_OK")
