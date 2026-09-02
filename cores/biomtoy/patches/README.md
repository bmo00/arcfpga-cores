# patches: divergence from upstream `jlrh/gaelco-fpga`

`cores/biomtoy` is vendored from `jlrh/gaelco-fpga` (see `cores.json`'s `external.repo`/
`external.commit`). These patches document local changes that don't come from that upstream and
must be reapplied after any future re-sync to a newer pinned commit.

## `macros-def-neptunoplus-vs-upstream.diff`

Upstream's `cfg/macros.def` only defines a `[mister]` target section. This repo also builds for
**neptUNO+** (see top-level `CLAUDE.md`), which reuses the same aspect-ratio/CRT-adjust macros as
`mister` — so the section header needs to read `[mister|neptunoplus]` for `jtframe cfgstr`/
`jtframe mem` to apply those macros to a neptUNO+ build too. Without this, a neptUNO+ synthesis
silently misses `JTFRAME_ARX`/`JTFRAME_ARY`/the CRT_ADJUST_* block that `[mister]` alone provides.

**Fix:** change `[mister]` to `[mister|neptunoplus]` in `cfg/macros.def` (see the diff for the
exact one-line change).

## `hdl-fx68k-mem-vs-upstream.diff`

Upstream's own `cfg/files.yaml` declares `fx68k.sv`/`fx68kAlu.sv`/`uaddrPla.sv` as core-local
`hdl/` files (this game's own fork of JTFRAME's `fx68k` M68000 core, vendored directly into the
core instead of pulled from `modules/fx68k`), and upstream's `hdl/` does ship those three
`.sv` files. But upstream's `hdl/` does **not** ship `nanorom.mem`/`microrom.mem` — the two
`$readmem`-loaded microcode/nanocode ROM images `fx68k.sv` requires at its own directory to
elaborate at all. Without them, simulation/synthesis of `fx68k.sv` fails outright (missing
`$readmem` source file).

**Fix:** add `hdl/nanorom.mem` and `hdl/microrom.mem`, copied byte-for-byte from
`modules/fx68k/hdl/` (the same fixed CPU microcode data every `fx68k` instance in this repo uses,
independent of upstream's own commit).

Pinned base: `jlrh/gaelco-fpga` commit `519a50b18960882895c3db7265ed238fb839bae2`.
