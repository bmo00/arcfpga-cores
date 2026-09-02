# patches: divergence from upstream `jlrh/konami-fpga`

`cores/ssriders` is vendored from `jlrh/konami-fpga` (see `cores.json`'s `external.repo`/
`external.commit`). This patch documents a local change that doesn't come from that upstream and
must be reapplied after any future re-sync to a newer pinned commit.

## `macros-def-neptunoplus-vs-upstream.diff`

Upstream's `cfg/macros.def` only defines a `[mister]` target section (there is a separate
`[mist|sidi]` section right after it, unaffected by this patch). This repo also builds for
**neptUNO+** (see top-level `CLAUDE.md`), which reuses the same aspect-ratio/CRT-adjust macros as
`mister` — so the section header needs to read `[mister|neptunoplus]` for `jtframe cfgstr`/
`jtframe mem` to apply those macros to a neptUNO+ build too. Without this, a neptUNO+ synthesis
silently misses `JTFRAME_ARX`/`JTFRAME_ARY`/the CRT_ADJUST_* block that `[mister]` alone provides.

**Fix:** change `[mister]` to `[mister|neptunoplus]` in `cfg/macros.def` (see the diff for the
exact one-line change).

Pinned base: `jlrh/konami-fpga` commit `1a6838f75d613234a1f57c5e053df1d8b63a3876`.
