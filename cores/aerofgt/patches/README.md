# patches: divergence from upstream `jlrh/videosystem-fpga`

`cores/aerofgt` is vendored from `jlrh/videosystem-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-sound-fm-snd-vs-upstream.diff`

Removes the `.fm_snd()` port connection in `hdl/jtaerofgt_sound.v`.

**Why**: The `jt10` in this repo's `modules/jt12` exposes `fm_left`/`fm_right`, not `fm_snd`; the unconnected `.fm_snd` pin makes Verilator fail with `PINNOTFOUND`. The output was left open anyway, so nothing is lost.

Pinned base: `jlrh/videosystem-fpga` commit `b1f0cd5bf745fbc749b86eff08c97252a3ce3023`.
