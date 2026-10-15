# patches: divergence from upstream `jlrh/seibu-fpga`

`cores/deadang` is vendored from `jlrh/seibu-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-ucore-hex-vs-upstream.diff`

Adds `hdl/ucdecode.hex` and `hdl/ucrom.hex`.

**Why**: `v30u_ucrom.sv` loads the V30 microcode tables with `$readmemh`, but upstream's `hdl/` does not ship the `.hex` files, so Quartus aborts with `Can't elaborate user hierarchy ... v30u_biu`. Copied byte-for-byte from `cores/raiden2/hdl/rtl/ucore/` (md5-identical to the copies in Arcade-IremM72 and zeroteamusa — the tables are the same V30 microcode).

Pinned base: `jlrh/seibu-fpga` commit `b6a605b0d9c8026f1849d29f81035f299a6810de`.

## `macros-def-neptunoplus-vs-upstream.diff`

Upstream's `cfg/macros.def` defines `SYNTHESIS` only under `[mister]`. The V30 microcode core (`v30u_*.sv`) guards its simulation-only code (`$test$plusargs`, `$fopen`, `$fwrite`) with `` `ifndef SYNTHESIS ``, and Quartus 13 (the neptUNO+ toolchain) does not define that macro by itself, so a neptUNO+ build failed with `Error (10174): system function "$test$plusargs" is not supported for synthesis`.

**Fix:** `[mister]` becomes `[mister|neptunoplus]` so `SYNTHESIS` (and the other mister-only macros) also reach the neptUNO+ build.
