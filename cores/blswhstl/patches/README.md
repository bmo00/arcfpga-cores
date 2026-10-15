# patches: divergence from upstream `jlrh/konami-fpga`

`cores/blswhstl` is vendored from `jlrh/konami-fpga` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-obj-shadow-gate-vs-upstream.diff`

Removes the `.SHADOW_GATE(1)` parameter override on `jtframe_objdraw`.

**Why**: `modules/jtframe`'s `jtframe_objdraw` has no `SHADOW_GATE` parameter, so lint and Quartus fail (`Parameter not found` / `Can't elaborate user hierarchy`). Upstream was written against a newer/different jtframe; if the shadow sprites look wrong in hardware, `SHADOW_GATE` behaviour must be ported into `jtframe_objdraw`.

Pinned base: `jlrh/konami-fpga` commit `9e9817dada52c04ea3285cd16fe775b8759799f1`.

## `mmr-yaml-vs-upstream.diff`

Adds `cfg/mmr.yaml` including simson's `k054000` MMR definition.

**Why**: `files.yaml` pulls `simson/hdl/jtk054000_mmr.v`, but that file is *generated* by `jtframe mmr` from `simson/cfg/mmr.yaml` and only exists when simson itself is built; in a blswhstl-only build it is missing (`did not match any file`). A local `cfg/mmr.yaml` that includes simson's `k054000` register map (same as `cores/tmnt/cfg/mmr.yaml`) makes blswhstl generate its own copy.

## `files-yaml-mmr-vs-upstream.diff`

Removes `jtk054000_mmr.v` from the `simson:` file list in `cfg/files.yaml`.

**Why**: Companion to `mmr-yaml-vs-upstream.diff`: the generated `jtk054000_mmr.v` now lives in blswhstl's own `hdl/` (picked up by its `*.v` glob), so it is no longer fetched from `simson`.
