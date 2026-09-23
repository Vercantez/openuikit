// cgunifyprobe — the iOS 26.1 facts cg-unify builds on
// (docs/agent_reports/cg-unify.md). run.sh compiles this with the scenario
// files against Apple's UIKit for the simulator; CGUnifyTests compiles the
// same scenario files against OpenUIKit.
import UIKit

MainActor.assumeIsolated {
    for line in cgUnifyTypesTranscript() { print(line) }
    for line in cgUnifyDrawingTranscript() { print(line) }
}
