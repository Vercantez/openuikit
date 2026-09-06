@_spi(OpenUIKitHost) import TipKit
import Foundation

func testTipViewHoldsTipAndAction() {
    let tip = EligibleHostTip()
    var fired = 0
    let view = TipView(tip) { _ in
        fired += 1
    }
    precondition(view.tip?.id == "eligible-host")
    view.actionHandler(Tips.Action(title: "do"))
    precondition(fired == 1)
    let erased = TipView(tip as (any Tip)?)
    precondition(erased.tip?.id == "eligible-host")
}

func testMiniTipViewStyleMakeBody() {
    let style = MiniTipViewStyle()
    let configuration = TipViewStyleConfiguration(tip: EligibleHostTip())
    let body = style.makeBody(configuration: configuration)
    precondition(body.tip.id == "eligible-host")
    let mini = MiniTipViewStyle.miniTip
    _ = mini.makeBody(configuration: configuration)
}

func testTipViewStyleConfigurationActions() {
    let configuration = TipViewStyleConfiguration(tip: OptionsHostTip())
    precondition(configuration.tip.id == "options-host")
    precondition(configuration.actions.count == 1)
    precondition(configuration.actions[0].id == "ok")
}
