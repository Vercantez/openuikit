import Foundation
import MetalKit

func testViewDelegateDrawInView() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 12, height: 12), device: MTLCreateSystemDefaultDevice())
        let delegate = MetalKitRecordingDelegate()
        view.delegate = delegate
        view.draw()
        precondition(delegate.drawCount == 1)
        view.draw()
        precondition(delegate.drawCount == 2)
    }
}

func testViewDelegateDrawableSizeWillChange() {
    metalKitRunOnMain {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 12, height: 12), device: MTLCreateSystemDefaultDevice())
        let delegate = MetalKitRecordingDelegate()
        view.delegate = delegate
        view.drawableSize = CGSize(width: 48, height: 24)
        precondition(delegate.sizeChanges.last == CGSize(width: 48, height: 24))
    }
}

func testViewDelegateProtocolIdentity() {
    metalKitRunOnMain {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        precondition(view.delegate == nil)
        let delegate = MetalKitRecordingDelegate()
        view.delegate = delegate
        precondition(view.delegate === delegate)
        view.delegate = nil
        precondition(view.delegate == nil)
    }
}
