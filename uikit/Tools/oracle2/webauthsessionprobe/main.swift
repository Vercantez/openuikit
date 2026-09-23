// ASWebAuthenticationSession surface used by NetNewsWire
// Account/Feedly/OAuthAccountAuthorizationOperation.swift.
//
// Build as an app (UIApplicationMain is needed for presentation), run on the
// iPhone 16 / iOS 26.1 simulator; prints facts then exits.
import AuthenticationServices
import UIKit

final class Provider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let window: UIWindow
    init(_ w: UIWindow) { window = w }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { window }
}

func report(_ tag: String, _ url: URL?, _ error: Error?) {
    if let e = error as NSError? {
        print("\(tag) callback url=\(url?.absoluteString ?? "nil") domain=\(e.domain) code=\(e.code) isSessionError=\(error is ASWebAuthenticationSessionError)")
    } else {
        print("\(tag) callback url=\(url?.absoluteString ?? "nil") error=nil")
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var keep: [AnyObject] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = UIViewController()
        w.makeKeyAndVisible()
        window = w

        print("errorDomain=\(ASWebAuthenticationSessionErrorDomain)")
        print("codes canceledLogin=\(ASWebAuthenticationSessionError.Code.canceledLogin.rawValue) presentationContextNotProvided=\(ASWebAuthenticationSessionError.Code.presentationContextNotProvided.rawValue) presentationContextInvalid=\(ASWebAuthenticationSessionError.Code.presentationContextInvalid.rawValue)")
        print("ASPresentationAnchor is UIWindow: \(ASPresentationAnchor.self == UIWindow.self)")

        let url = URL(string: "https://example.invalid/oauth")!
        // (a) no presentation context provider
        let a = ASWebAuthenticationSession(url: url, callbackURLScheme: "nnwprobe") { u, e in report("a", u, e) }
        print("a prefersEphemeral default=\(a.prefersEphemeralWebBrowserSession) canStart=\(a.canStart)")
        print("a start()=\(a.start())")
        keep.append(a)
        // (b) with provider, cancelled right after start
        let b = ASWebAuthenticationSession(url: url, callbackURLScheme: "nnwprobe") { u, e in report("b", u, e) }
        let p = Provider(w)
        b.presentationContextProvider = p
        keep.append(p)
        print("b canStart=\(b.canStart)")
        print("b start()=\(b.start())")
        print("b start() again=\(b.start())")
        keep.append(b)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            b.cancel()
            print("b cancel() called")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("done")
                exit(0)
            }
        }
        return true
    }
}
