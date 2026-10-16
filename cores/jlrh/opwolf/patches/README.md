# patches: divergence from upstream `jlrh/taito-fpga`

`cores/opwolf` is vendored from `jlrh/taito-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-gun-parameter-keyword-vs-upstream.diff`

Adds the `parameter` keyword before `signed XOFFS`/`YOFFS` in `hdl/opwolf_gun.v`.

**Why**: Same Verilator rule as bbusters: parameter ports of implicit data type need the `parameter` keyword.

Pinned base: `jlrh/taito-fpga` commit `73d06054e90246096064682b069c22a7a906e469`.
