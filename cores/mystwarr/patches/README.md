# patches: divergence from upstream `jlrh/konami-fpga`

`cores/mystwarr` is vendored from `jlrh/konami-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `mame2mra-skip-vs-upstream.diff`

In `cfg/mame2mra.toml`: replaces the `skip.setnames` list with all 26 non-mystwarr sets of `mystwarr.cpp`.

**Why**: Current MAME's `mystwarr.cpp` also defines metamorphic force, violent storm, martial champion, monster maulers and others (new sets such as `mtlchamp*`, `mmaulers*`, `viostormeb`). Upstream's shorter skip list lets them through and `jtframe mra` fails with `Unknown ROM length for ROM 128a08.1h`. `[parse] machines=` is not honoured by this jtframe, so the exclusion list is the only filter.

Pinned base: `jlrh/konami-fpga` commit `9e9817dada52c04ea3285cd16fe775b8759799f1`.
