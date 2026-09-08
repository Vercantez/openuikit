import UIKit
import Darwin

private var lines: [String] = []
private func emit(_ line: String) { lines.append(line); print(line) }
private final class Space: NSObject, UICoordinateSpace {
    let bounds = CGRect(x: 1, y: 2, width: 300, height: 400)
    func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        emit("custom-point-to input=\(point) target-view=\(coordinateSpace is UIView)")
        return CGPoint(x: 101, y: 102)
    }
    func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        emit("custom-point-from input=\(point) source-view=\(coordinateSpace is UIView)")
        return CGPoint(x: 201, y: 202)
    }
    func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        emit("custom-rect-to input=\(rect) target-view=\(coordinateSpace is UIView)")
        return CGRect(x: 301, y: 302, width: 303, height: 304)
    }
    func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        emit("custom-rect-from input=\(rect) source-view=\(coordinateSpace is UIView)")
        return CGRect(x: 401, y: 402, width: 403, height: 404)
    }
}
private final class ProbeDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        window = win
        win.rootViewController = UIViewController()
        win.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            emit("iOS=\(UIDevice.current.systemVersion) scale=\(UIScreen.main.scale) size=\(win.bounds.size)")
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
            let parent = UIView(frame: CGRect(x: 40, y: 60, width: 200, height: 300))
            let child = UIView(frame: CGRect(x: 10, y: 20, width: 80, height: 100))
            let sibling = UIView(frame: CGRect(x: 150, y: 220, width: 100, height: 100))
            root.addSubview(parent); parent.addSubview(child); root.addSubview(sibling)
            child.bounds.origin = CGPoint(x: 3, y: 4)
            let a: UICoordinateSpace = child
            let b: UICoordinateSpace = sibling
            let point = CGPoint(x: 8, y: 9)
            let rect = CGRect(x: 8, y: 9, width: 30, height: 40)
            emit("bounds=\(a.bounds)")
            emit("point-to=\(a.convert(point,to:b))")
            emit("point-from=\(a.convert(point,from:b))")
            emit("rect-to=\(a.convert(rect,to:b))")
            emit("rect-from=\(a.convert(rect,from:b))")
            emit("identity-point=\(a.convert(point,to:a))")
            emit("identity-rect=\(a.convert(rect,from:a))")
            let space = Space()
            emit("view-to-custom-point=\(a.convert(point,to:space))")
            emit("view-from-custom-point=\(a.convert(point,from:space))")
            emit("view-to-custom-rect=\(a.convert(rect,to:space))")
            emit("view-from-custom-rect=\(a.convert(rect,from:space))")
            child.transform = CGAffineTransform(rotationAngle: .pi / 2)
            emit("rotated-point-to=\(a.convert(point,to:b))")
            emit("rotated-rect-to=\(a.convert(rect,to:b))")
            emit("rotated-rect-from=\(a.convert(rect,from:b))")
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            try! (lines.joined(separator: "\n") + "\n").write(to: docs.appendingPathComponent("coordinate-space.txt"),atomically:true,encoding:.utf8)
            exit(0)
        }
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(ProbeDelegate.self))
