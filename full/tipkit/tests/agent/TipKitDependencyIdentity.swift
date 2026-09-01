import SwiftUI
import TipKit

// EC2 dependency-identity probe. Isolated host `test_host.sh` does not compile
// this file. A future clean EC2 run must:
//   1. Build guest Foundation and SwiftUI modules/dylibs
//   2. Build TipKit with those -I/-L paths
//   3. Link this client against libSwiftUI.dylib and libTipKit.dylib
//   4. Run with LD_LIBRARY_PATH and confirm both dylibs load
//
// These helpers require the real SwiftUI nominal types. They must not compile
// against a TipKit-local Text/Image/Edge/Binding stand-in.

private func requireSwiftUIText(_ value: Text) -> Text { value }
private func requireSwiftUIImage(_ value: Image) -> Image { value }
private func requireSwiftUIEdge(_ value: Edge) -> Edge { value }
private func requireSwiftUIBinding(_ value: Binding<Bool>) -> Binding<Bool> { value }
private func requireSwiftUIView<V: View>(_ value: V) -> V { value }

private struct IdentityTip: Tip {
    var title: Text { Text("Save as a Favorite") }
    var message: Text? { Text("Favorites stay at the top of the list.") }
    var image: Image? { Image(systemName: "star") }

    var actions: [Tips.Action] {
        Tips.Action(id: "learn-more", title: "Learn More")
    }
}

@MainActor
func tipKitDependencyIdentityMain() {
    let tip = IdentityTip()
    _ = requireSwiftUIText(tip.title)
    _ = requireSwiftUIText(tip.message!)
    _ = requireSwiftUIImage(tip.image!)
    _ = requireSwiftUIText(tip.actions[0].label())

    let erased = AnyTip(tip)
    _ = requireSwiftUIText(erased.title)
    _ = requireSwiftUIImage(erased.image!)

    let presented = requireSwiftUIBinding(Binding.constant(true))
    let edge = requireSwiftUIEdge(.top)
    let inline = TipView(tip, isPresented: presented, arrowEdge: edge)
    _ = requireSwiftUIView(inline)
    _ = requireSwiftUIView(TipView(tip, arrowEdge: .leading))
    _ = requireSwiftUIView(EmptyView().popoverTip(tip, arrowEdge: .bottom))
    _ = requireSwiftUIView(EmptyView().tipViewStyle(.miniTip))
    _ = MiniTipViewStyle.miniTip
    _ = TipViewStyleConfiguration(tip: tip)

    print("TIPKIT_DEPENDENCY_IDENTITY_OK")
}

await tipKitDependencyIdentityMain()
