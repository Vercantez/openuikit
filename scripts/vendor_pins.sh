# Measured in-repo vendor tree pins. Attestation is git rev-parse HEAD:<dir>,
# not an external checkout commit. Advance these only after a gate has consumed
# the new tree; do not edit them to paper over a failing proof.
#
# Current OpenUIKit subtree is 06aaf82bc64672d269064507533e75a86e5a1da3
# ("Drive SwiftUI apps from the paced host loop"), 30 commits after the old
# external pin 62dea0d97a3b9074e5c016820492bd0656b9a35a.
EXPECTED_INREPO_UIKIT_TREE=8ce87c1aef592553336aadf9101ec2bb4ebe6aaa
EXPECTED_INREPO_MACHORUN_TREE=42d42ace9c6ff7a4ae7c25c3a8e466f82d5f70c8
