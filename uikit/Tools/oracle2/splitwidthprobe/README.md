# Triple-column display-mode width oracle

Measured 2026-09-07 (America/Chicago), iPad A16, iOS 26.1 / 23B86,
820×1180 @2x. Run from `uikit/` on a private simulator:

```sh
for profile in main boundary primary supplementary secondary resize; do
  SIM_DEVICE_SUFFIX=-uikit-blocking-types4 SPLIT_PROBE_CASE="$profile" \
    scripts/splitwidth_probe_sim.sh "/tmp/splitwidth-$profile"
done
```

Each sample creates a fresh triple-column controller as a child of a real
window's root controller, with the recorded width and a 700 pt height. Its
horizontal size class is regular. Widths beyond the physical screen are
intentional container bounds, not claims of a different simulator device.
The initial preferred mode is assigned before appearance. After mounting,
the probe requests secondary-only and then the tested mode. Immediate and
settled (0.6 s) readings agree. `resize` changes the bounds before and after
that explicit request. Raw JSON is retained verbatim; the focused test
replays all 805 mode/behavior observations.

At the first tiled three-column layout, the primary frame is
`[10,32,240,658]`, supplementary frame `[0,0,490,700]` with left safe area
250, and secondary frame `[490.5,0,464,700]`. The required width is therefore
`240 + 240 + 10 + 0.5 + 464 = 954.5`. Available width rounds to the device
pixel grid: 954.249 does not fit, 954.25 fits. Setting either side minimum to
300 shifts the transition by 60; secondary minimum 500 shifts it by 36.

| Request | Initial appearance / resizing a tiled layout | Explicit mounted request |
| --- | --- | --- |
| automatic | one beside if narrow, two beside if wide | same |
| secondary only / one beside | requested mode | requested mode |
| one over / two over | initially secondary only; resize preserves current overlay visibility | requested overlay |
| two beside / two displace | one beside if narrow, two beside if wide | two over if narrow, two beside if wide |

Wide two-displace resolves to two-beside with actual tile behavior. The
preferred mode is retained. A same-width layout pass does not replay an
explicit request. The implementation is guarded by the iOS cut.

This closes **display-mode resolution** for these samples. Raw column frames
and widths supply the fit measurement; this change does not reproduce those
frames, floating sidebar materials, safe areas or animation pixels. Existing
column-width getter discrepancies, post-appearance edits to sizing
preferences, other preferred/minimum/maximum combinations, compact/regular
containment transitions, and inspector layout remain separate questions.
