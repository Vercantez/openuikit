# Measured in-repo vendor tree pins. Attestation is git rev-parse HEAD:<dir>,
# not an external checkout commit. Advance these only after a gate has consumed
# the new tree; do not edit them to paper over a failing proof.
#
# Current OpenUIKit subtree is 06aaf82bc64672d269064507533e75a86e5a1da3
# ("Drive SwiftUI apps from the paced host loop"), 30 commits after the old
# external pin 62dea0d97a3b9074e5c016820492bd0656b9a35a.
EXPECTED_INREPO_UIKIT_TREE=0d2edf593e4ac2d66d4abf0967d89330fd71ac56
EXPECTED_INREPO_MACHORUN_TREE=76885295ff2f4590038a497e2963edaa18185e6f
