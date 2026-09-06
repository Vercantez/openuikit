# Codex Cloud environment for the OpenUIKit Linux platform

Codex Cloud tasks need an *environment*; the CLI can only run tasks inside one
(`codex cloud exec --env <ENV_ID> --branch <branch> "<prompt>"`). Environments
are created in the Codex web UI (chatgpt.com/codex → Environments). This file
is the recipe; `.codex/setup.sh` is the script.

| Field | Value |
|---|---|
| Repository | `Vercantez/openuikit-linux-platform` (the GitHub app must be granted this repo) |
| Container image | universal (Ubuntu 24.04) |
| Setup script | `bash .codex/setup.sh` |
| Environment variables | `LANG=C.UTF-8`, `LC_ALL=C.UTF-8`, `OPENUIKIT_MACIOS_ROOT=/opt/openuikit-evidence/dotnet-macios` |
| Agent internet access | off (the setup phase installs everything; gates run offline) |
| Setup time | ~6–10 minutes cold (apt + the Swift 6.2.4 toolchain + the pinned static-evidence clone) |

The setup script mirrors `.cursor/Dockerfile` (the accepted Swift 6.2 /
Ubuntu 24.04 lab), installs the swift.org **6.2.4** toolchain when the image
carries another version (`.cursor/verify-cloud-environment.sh` refuses any
other), then runs the same two scripts the Cursor environment ran and prints
`CODEX_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` after
Cursor's own `CURSOR_SWIFT_ENVIRONMENT_OK …` marker.

Once the environment exists, a framework campaign submits one task per lane:

```
codex cloud exec --env <ENV_ID> \
  --branch experiment/cursor-framework-fanout-wave<N>-seed-<date> \
  "$(python3 -c 'import json;print(json.load(open("full/framework-fanout/campaign-wave<N>.json"))["frameworks"][0]["prompt"])')"
```

and harvests with `codex cloud status|diff|apply <task>` into a local branch,
which the operator merges with `fw_merge.sh <slug> <branch>` exactly as the
Cursor branches were.
