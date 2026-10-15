# patches: divergence from upstream `jlrh/konami-fpga`

`cores/hotchase` is vendored from `jlrh/konami-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-sub-no-hier-debug-vs-upstream.diff`

Deletes two lines in `hdl/jthotchase_sub.v` that read `u_dtack.delayed`/`u_dtack.recover`.

**Why**: They are a simulation-only profiling counter (inside `ifdef SIMULATION`) that reaches into internal signals of `jtframe_68kdtack`, which no longer has them; lint fails with `Can't find definition of 'delayed'`. The counters `pf_del`/`pf_rec` stay at 0 in the debug printout.

Pinned base: `jlrh/konami-fpga` commit `9e9817dada52c04ea3285cd16fe775b8759799f1`.
