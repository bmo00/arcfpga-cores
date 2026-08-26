# Attribution

Source: https://github.com/gyurco/Mist_FPGA (`common`).

Pinned commit: `a0c20087982c384dd75c9696f45e3f3cd75c2385`.

This is gyurco's own shared CPU/Sound/IO/Memory/TTL/mist library — the code his own per-game cores
(Arcade_MiST/...) are actually written and tested against. Prefer this over `modules/jtframe`,
`modules/jtopl`, etc. (jotego's own lineage) for shared dependencies of native cores ported from
gyurco/Mist_FPGA, to avoid API drift between the two lineages (e.g. differing parameter names/casing,
differing port names on ostensibly the same module) — see `doc/porting-a-native-core.md`.
