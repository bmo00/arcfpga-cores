# patches: divergence from upstream `jlrh/snk-fpga`

`cores/mechatt` is vendored from `jlrh/snk-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-opn-flag-mask-vs-upstream.diff`

Removes the `flag_mask` wire and the `.flag_mask()` port connection on `jt12_mmr` in `hdl/jtmechatt_opn.v`.

**Why**: `modules/jt12`'s `jt12_mmr` has no `flag_mask` port (only `flag_ctl`); Quartus fails with `Port "flag_mask" does not exist in macrofunction "u_mmr"`. The wire was not used anywhere else.

## `mame2mra-regions-vs-upstream.diff`

In `cfg/mame2mra.toml`: drops the `ymsnd:internal` region and sets `width=16` on `sprites`.

**Why**: `ymsnd:internal` is not a MAME region in any mechatt set (the board uses a YM2203, no internal rhythm ROM), so `jtframe mra` aborts. The clone sets interleave sprite ROMs at odd offsets, which needs `width=16` or the parser reports `ROM start overcome` warnings and mis-places the data.

Pinned base: `jlrh/snk-fpga` commit `37333320deafee67ea8fa8158421059be933b75c`.
