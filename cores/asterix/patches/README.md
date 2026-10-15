# patches: divergence from upstream `jlrh/konami-fpga`

`cores/asterix` is vendored from `jlrh/konami-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-obj-shadow-gate-vs-upstream.diff`

Removes the `.SHADOW_GATE(1)` parameter override on `jtframe_objdraw`.

**Why**: `modules/jtframe`'s `jtframe_objdraw` has no `SHADOW_GATE` parameter, so lint and Quartus fail (`Parameter not found` / `Can't elaborate user hierarchy`). Upstream was written against a newer/different jtframe; if the shadow sprites look wrong in hardware, `SHADOW_GATE` behaviour must be ported into `jtframe_objdraw`.

Pinned base: `jlrh/konami-fpga` commit `9e9817dada52c04ea3285cd16fe775b8759799f1`.
