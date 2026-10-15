# patches: divergence from upstream `jlrh/konami-fpga`

`cores/konamigt` is vendored from `jlrh/konami-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `mame2mra-skip-vs-upstream.diff`

In `cfg/mame2mra.toml`: adds `bs_twinbee` to `skip.setnames`.

**Why**: `bs_twinbee` is a vertical game and the core does not define `JTFRAME_VERTICAL`, so `jtframe mra` fails with `Game bs_twinbee is vertical but JTFRAME_VERTICAL is not set`. Side effect: the TwinBee (Bubble System) MRA is no longer generated.

Pinned base: `jlrh/konami-fpga` commit `863d697519f73969791ae793b881fe4a90a0945d`.

## `files-yaml-jt49-vs-upstream.diff`

Replaces the bare `jt49:` entry in `cfg/files.yaml` with an explicit file list.

**Why**: Upstream ends `cfg/files.yaml` with a bare `jt49:`, which makes jtframe read `modules/jt49/cfg/files.yaml`; that file does not exist in this repo's `modules/jt49`, so the neptUNO+ build aborts with `did not match any file` before synthesis. The `jt49_*.v` files plus `filter/jt49_dcrm2.v` (used by `jtkonamigt_game.v`) are now listed explicitly; `jt49_exp.v` is left out because the core supplies its own via `JT49_EXP=nemesis_jt49_exp`.

## `hdl-jt49-exp-wrapper-vs-upstream.diff`

Adds `hdl/jt49_exp.v`, a module named `jt49_exp` that forwards to the core's own
`nemesis_jt49_exp` (passing `comp[1:0]`).

**Why**: upstream sets `JT49_EXP=nemesis_jt49_exp` in `cfg/macros.def`, expecting a jt49 whose `jt49.v`
instantiates `` `JT49_EXP `` instead of the stock `jt49_exp`. This repo's `modules/jt49` always
instantiates `jt49_exp` and ignores the macro, so with `files-yaml-jt49-vs-upstream.diff` alone the
build failed with `Error (12006): Node instance "u_exp" instantiates undefined entity "jt49_exp"`.
Including the stock `modules/jt49/hdl/jt49_exp.v` would also build, but with the generic volume
curve; this wrapper keeps the Nemesis-specific LUT upstream intended. The stock `jt49_exp.v` must
stay out of `cfg/files.yaml` (duplicate module). `nemesis_jt49_exp` has a 2-bit `comp` and `jt49`
drives 3 bits; `nemesis_sound.v` uses `COMP=2'b01`, so bit 2 is always 0.
