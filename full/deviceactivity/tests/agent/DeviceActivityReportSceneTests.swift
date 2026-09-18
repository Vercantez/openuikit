import DeviceActivity
import Foundation

private struct DeviceActivityAgentTestScene: DeviceActivityReportScene {
    typealias Configuration = String
    typealias Content = String

    var context: DeviceActivityReport.Context
    var content: (Configuration) -> Content

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> Configuration {
        let iterator = data.makeAsyncIterator()
        var count = 0
        while await iterator.next() != nil {
            count += 1
        }
        return "records:\(count)"
    }
}

private struct DeviceActivityAgentTestExtension: DeviceActivityReportExtension {
    typealias Body = DeviceActivityAgentTestScene

    var body: Body
}

private final class DeviceActivitySceneProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?

    func finish(_ value: String) {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    func snapshot() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private func deviceActivitySceneRunAsync(
    _ operation: @escaping @Sendable () async -> String,
    check: (String) -> Void
) {
    let probe = DeviceActivitySceneProbe()
    Task.detached {
        probe.finish(await operation())
    }
    let deadline = Date().addingTimeInterval(5)
    while Date() < deadline {
        if let value = probe.snapshot() {
            check(value)
            return
        }
        Thread.sleep(forTimeInterval: 0.001)
    }
    fatalError("async DeviceActivity scene probe timed out")
}

private func deviceActivityAgentScene(
    context: String = "scene",
    content: @escaping (String) -> String = { "rendered:\($0)" }
) -> DeviceActivityAgentTestScene {
    DeviceActivityAgentTestScene(
        context: DeviceActivityReport.Context(context),
        content: content
    )
}

func testDeviceActivityReportSceneSurface() {
    let scene = deviceActivityAgentScene()
    deviceActivityRequire(scene.context.rawValue == "scene", "context")
    deviceActivityRequire(scene.content("cfg") == "rendered:cfg", "content")
    deviceActivityRequire(scene.body.context == scene.context, "body default")
    deviceActivityRequire(
        DeviceActivityAgentTestScene.Configuration.self == String.self,
        "Configuration"
    )
    deviceActivityRequire(
        DeviceActivityAgentTestScene.Content.self == String.self,
        "Content"
    )
    let asExistential: any DeviceActivityReportScene = scene
    deviceActivityRequire(
        asExistential.context.rawValue == "scene",
        "protocol existential"
    )
}

func testDeviceActivityReportSceneMakeConfiguration() {
    let day = DateInterval(start: Date(timeIntervalSince1970: 0), duration: 3600)
    let user = DeviceActivityData.User(role: .individual)
    let device = DeviceActivityData.Device(model: .iPhone)
    let record = DeviceActivityData(
        lastUpdatedDate: Date(timeIntervalSince1970: 0),
        segmentInterval: .daily(during: day),
        user: user,
        device: device
    )
    deviceActivitySceneRunAsync(
        {
            let scene = deviceActivityAgentScene()
            return await scene.makeConfiguration(
                representing: DeviceActivityResults([record, record])
            )
        },
        check: { value in
            deviceActivityRequire(value == "records:2", "makeConfiguration")
        }
    )
    deviceActivitySceneRunAsync(
        {
            let scene = deviceActivityAgentScene()
            return await scene.makeConfiguration(
                representing: DeviceActivityResults()
            )
        },
        check: { value in
            deviceActivityRequire(value == "records:0", "empty")
        }
    )
}

func testDeviceActivityReportSceneMakeConfigurationAsync() async {
    let day = DateInterval(start: Date(timeIntervalSince1970: 0), duration: 3600)
    let user = DeviceActivityData.User(role: .individual)
    let device = DeviceActivityData.Device(model: .iPhone)
    let record = DeviceActivityData(
        lastUpdatedDate: Date(timeIntervalSince1970: 0),
        segmentInterval: .daily(during: day),
        user: user,
        device: device
    )
    let scene = deviceActivityAgentScene()
    let two = await scene.makeConfiguration(
        representing: DeviceActivityResults([record, record])
    )
    deviceActivityRequire(two == "records:2", "makeConfiguration")
    let none = await scene.makeConfiguration(
        representing: DeviceActivityResults<DeviceActivityData>()
    )
    deviceActivityRequire(none == "records:0", "empty")
}

func testDeviceActivityReportExtensionSurface() {
    let scene = deviceActivityAgentScene(context: "extension")
    let ext = DeviceActivityAgentTestExtension(body: scene)
    deviceActivityRequire(
        DeviceActivityAgentTestExtension.Body.self
            == DeviceActivityAgentTestScene.self,
        "Body"
    )
    deviceActivityRequire(ext.body.context.rawValue == "extension", "body")
    deviceActivityRequire(
        ext.configuration == ext.body.context,
        "configuration default"
    )
    deviceActivityRequire(
        ext.configuration.rawValue == "extension",
        "configuration value"
    )
}
