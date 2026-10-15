# patches: divergence from upstream `jlrh/snk-fpga`

`cores/bbusters` is vendored from `jlrh/snk-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-video-parameter-keyword-vs-upstream.diff`

Adds the `parameter` keyword before `[10:0] PF1_BASE`/`OBJ1_BASE` in `hdl/jtbbusters_video.v`.

**Why**: The parameter list uses an implicit-type declaration without the `parameter` keyword, which the current Verilator rejects (IEEE 1800-2023 6.20.1). `cores/mechatt` instantiates this same file, so it hits the same error.

Pinned base: `jlrh/snk-fpga` commit `b2de276a92466c4279f192d7935ef2a089a7a0dc`.

## `hdl-sound-fm-snd-vs-upstream.diff`

Removes the `.fm_snd()` port connection in `hdl/jtbbusters_sound.v`.

**Why**: The `jt10` in this repo's `modules/jt12` has no `fm_snd` port (it exposes `fm_left`/`fm_right`); Verilator fails with `PINNOTFOUND`. The output was left open anyway.
