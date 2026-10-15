# patches: divergence from upstream `jlrh/gaelco-fpga`

`cores/aligator` is vendored from `jlrh/gaelco-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-fx68k-lint-vs-upstream.diff`

Adds `// verilator lint_off BLKANDNBLK` at the top of `hdl/fx68k.sv`.

**Why**: Upstream's `fx68k.sv` drives fields of the `Nanod` struct both with `assign` and with non-blocking assignments inside `always_ff`; the Verilator used by `lint-one.sh` rejects that as `%Error-BLKANDNBLK` and the whole core fails lint. The logic itself is correct (disjoint fields) and synthesizes fine, so the warning is waived file-wide, same as `cores/squash/hdl/fx68k.sv` already does.

## `hdl-fx68k-mem-vs-upstream.diff`

Adds `hdl/nanorom.mem` and `hdl/microrom.mem`.

**Why**: `fx68k.sv` loads its microcode/nanocode ROMs with `$readmemb("nanorom.mem")`/`("microrom.mem")`, but upstream's `hdl/` does not ship them, so Quartus fails with `Error (10054): can't open Verilog Design File "nanorom.mem"`. They are copied byte-for-byte from `modules/fx68k/hdl/` (fixed CPU data, independent of the upstream commit).

Pinned base: `jlrh/gaelco-fpga` commit `174483c486ff3355adabf3c87cdeb869f4100372`.

## `hdl-volume-table-vs-upstream.diff`

Adds `hdl/volume_table.mem`.

**Why**: `*_gae1_sound.v` loads its 4096-entry volume lookup with `$readmemh("volume_table.mem")`, but upstream's `hdl/` does not ship it, so Quartus fails with `Can't elaborate user hierarchy ... gae1_sound:u_snd`. Copied from the already-published `arcfpga-cores` repo (aligator and wrally2 have identical tables).
