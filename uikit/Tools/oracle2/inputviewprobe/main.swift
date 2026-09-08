// Runtime oracle: scripts/inputview_probe_sim.sh /tmp/uikit-inputview-oracle
import UIKit

private func rect(_ r: CGRect) -> [Double] { [Double(r.origin.x), Double(r.origin.y), Double(r.width), Double(r.height)] }
private func size(_ s: CGSize) -> [Double] { [Double(s.width), Double(s.height)] }
private func color(_ c: UIColor?) -> Any {
    guard let c else { return NSNull() }
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard c.getRed(&r, green: &g, blue: &b, alpha: &a) else { return String(describing:c) }
    return [Double(r),Double(g),Double(b),Double(a)]
}
private final class NoFeedback: NSObject, UIInputViewAudioFeedback {}
private final class Feedback: NSObject, UIInputViewAudioFeedback {
    let enableInputClicksWhenVisible = true
}
private final class InputViewProbeApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var views: [(String,UIInputView)] = []
    var records: [[String:Any]] = []
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        w.rootViewController = vc
        w.makeKeyAndVisible()
        window = w
        views = [("init",UIInputView()), ("frame", UIInputView(frame:CGRect(x:4,y:6,width:140,height:70))), ("default",UIInputView(frame:CGRect(x:20,y:150,width:300,height:80),inputViewStyle:.default)), ("keyboard",UIInputView(frame:CGRect(x:20,y:300,width:300,height:80),inputViewStyle:.keyboard))]
        for (name,v) in views {
            record(name + ".detached",v)
            v.allowsSelfSizing = true
            record(name + ".selfSizing",v)
            v.allowsSelfSizing = false
            if name == "default" || name == "keyboard" { vc.view.addSubview(v) }
        }
        let absent: UIInputViewAudioFeedback = NoFeedback()
        let present: UIInputViewAudioFeedback = Feedback()
        records.append(["stage":"audioFeedback", "absentProperty":absent.enableInputClicksWhenVisible == nil, "explicitTrue":present.enableInputClicksWhenVisible == true])
        UIDevice.current.playInputClick()
        UIDevice.current.playInputClick()
        records.append(["stage":"playInputClick", "callsReturned":2])
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5) {
            for (name,v) in self.views where name == "default" || name == "keyboard" {
                v.layoutIfNeeded(); self.record(name + ".attached",v)
            }
            self.finish()
        }
        return true
    }
    func record(_ stage:String,_ v:UIInputView) {
        records.append(["stage":stage,"style":v.inputViewStyle.rawValue,"frame":rect(v.frame),"bounds":rect(v.bounds),"selfSizing":v.allowsSelfSizing,"intrinsic":size(v.intrinsicContentSize),"sizeThatFitsZero":size(v.sizeThatFits(.zero)),"sizeThatFitsLarge":size(v.sizeThatFits(CGSize(width:400,height:200))),"opaque":v.isOpaque,"background":color(v.backgroundColor),"clips":v.clipsToBounds,"subviews":v.subviews.map { ["type":String(describing:type(of:$0)),"frame":rect($0.frame)] }])
    }
    func finish() {
        let data = try! JSONSerialization.data(withJSONObject:["systemVersion":UIDevice.current.systemVersion,"screen":rect(UIScreen.main.bounds),"scale":UIScreen.main.scale,"records":records],options:[.prettyPrinted,.sortedKeys])
        let docs = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
        try! data.write(to:docs.appendingPathComponent("inputview.json"))
        print(String(data:data,encoding:.utf8)!)
        exit(0)
    }
}
_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(InputViewProbeApp.self))
