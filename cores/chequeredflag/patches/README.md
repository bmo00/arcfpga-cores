# patches: divergence from upstream

## `macros-def-corename-vs-upstream.diff`

Changes `CORENAME=CHEQFLAG` to `CORENAME=CHEQUEREDFLAG` in `cfg/macros.def`.

**Why**: The core directory and all its RTL are named `chequeredflag` (`jtchequeredflag_*`), but upstream sets `CORENAME=CHEQFLAG`; jtframe derives the core directory from `CORENAME`, so the build looked for `cores/cheqflag/` and failed with `Cannot resolve path alias chequeredflag ... /build/cores/cheqflag/cfg/files.yaml`.
