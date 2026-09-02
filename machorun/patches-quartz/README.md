# patches-quartz — the patches ~/quartz needs to build as Mach-O on Linux

**There are none. This directory is empty, and that is the measurement.**

`scripts/build_quartz.sh` applies `patches-quartz/*.patch` to a copy of
`vendor/quartz` before compiling, and prints the count:

```
== patches applied: 0
== compiling (target arm64-apple-macos11, sysroot /work/sdk)
== compiled 37 objects, 0 failures
== linking darwin/usr/lib/libquartz.dylib
```

Compare `patches-macho/`, which holds the **4** patches Apple's own objc4 needs
for the same treatment. `docs/OBJC4_MACHO.md` argues those four are irreducible
because each says *"this is not a Mac"*. quartz's zero is the other half of that
argument: source that never assumed a platform does not have to be told the
platform changed.

The directory and the loop that reads it exist so that the number stays honest
if a future drop of quartz needs something. A patch here would be a real finding
and should arrive with a header comment saying what upstream assumed and why it
cannot simply be fixed upstream instead.

**A patch added here must be added to the macOS oracle too.**
`scripts/build_quartz_macos.sh` applies the same directory, deliberately: if the
two sides of `scripts/quartz_pixel.sh` compiled different source, the pixel
comparison would be measuring the patch rather than the loader.
