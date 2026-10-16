# patches: divergence from upstream `jotego/jtcores`

`cores/ktiger` is vendored from `jotego/jtcores` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `mmr-yaml-wardnr-scroll-vs-upstream.diff`

Replaces `cfg/mmr.yaml`'s `include: {core: wardnr, name: wardnr_scroll}` with a local copy of
wardnr's `scroll` register map, named `wardnr_scroll` with `no_core_name: true`.

**Why**: both builds failed with `Error: imported mmr from "wardnr" missing name(s): wardnr_scroll`.
This repo's `modules/jtframe` keeps an imported block's original name (`scroll` in
`cores/wardnr/cfg/mmr.yaml`), so the name upstream asks for never matches; and even importing
`scroll` would generate `jtktiger_scroll_mmr` (named after the importing core), not the
`jtwardnr_scroll_mmr` that `wardnr/hdl/jtwardnr_scroll.v` instantiates and `cfg/files.yaml` lists.
`no_core_name` makes `jtframe mmr ktiger` emit exactly `jtwardnr_scroll_mmr` — checked to be
identical (comments aside) to the one `jtframe mmr wardnr` generates. Keep the register map in sync
with wardnr's if that ever changes.
