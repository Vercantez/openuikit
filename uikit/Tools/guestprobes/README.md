# Extra guest probes

Each `<Name>.probe.sh` here adds one Mach-O guest executable without
editing `full/scripts/build_full.sh`. A probe file defines only two
functions and has no top-level commands:

* `build_extra_probe_<Name>`. `build_full.sh` sources the file and appends
  `<Name>` to its final executables, then runs this function through
  `run_jobs`/`build_final_executable`. The function can use build_full's
  `compile_app_module`, `link_app_executable`, `CC`, `OUT` and `UIKIT`, plus
  OpenUIKit's generated Objective-C header in `$OUT/objc-include`.
* `run_extra_probe_<Name>`. `uikit/scripts/linux_guest_realapp_verify.sh`
  runs it under the verifier's machorun environment, with `ROOT`, `BUILD`
  and `UIKIT` set. It prints its verdict line and returns non-zero on
  failure. `scripts/ops/local_guest_verify.sh` therefore checks every probe.

`BUILD_FULL_EXTRA_PROBES` names the directory; it defaults to this one.
Setting it to the empty string builds no probes. The probes add
executables and a header only; `render_full` is byte-identical either way.
