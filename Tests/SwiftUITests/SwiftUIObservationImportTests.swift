// This file intentionally imports SwiftUI but not Combine/OpenCombine. It is
// the source-shape proof for Focus's OnboardingViewModel and views, which rely
// on SwiftUI to make ObservableObject and Published visible.

import XCTest
import OpenUIKit
import SwiftUI

private final class ImportOnlyModel: ObservableObject {
    @Published var value = 1
}

private struct ImportOnlyView: View {
    @ObservedObject var model: ImportOnlyModel

    init(model: ImportOnlyModel) {
        self.model = model
    }

    var body: some View {
        Text("\(model.value)")
    }

    var valueBinding: Binding<Int> {
        $model.value
    }
}

@MainActor
final class SwiftUIObservationImportTests: XCTestCase {
    func testSwiftUIOnlyImportProvidesTheWholeFocusObservationSurface() {
        let model = ImportOnlyModel()
        let view = ImportOnlyView(model: model)

        XCTAssertEqual(view.valueBinding.wrappedValue, 1)
        view.valueBinding.wrappedValue = 4
        XCTAssertEqual(model.value, 4)
    }
}
