# Patches — mariobros / neptunoplus

Diffs against the vendored `../../hdl/rtl/*.v` at `external.commit` (see `cores.json` and
`neptunoplus/NOTES.md`). `hdl/` itself stays pristine — these are applied at build time, never
committed as edits to the vendored tree.

## `mario_top-duplicate-i_anlg_vol.patch`

`mario_top.v`'s own `mario_sound` instantiation connects `.I_ANLG_VOL()` twice — once with the
real `I_ANLG_VOL` signal, then again immediately after with an empty reference. Verilator hard-errors
on this (`Duplicate pin connection`); Quartus would very likely reject it too. Fixes by dropping the
redundant empty connection.

## `mario_roms-DLROMB-unused-param-default.patch`

`DLROMB`'s generic template parameters (`AW`/`DW`) have no default value, which is only a real
problem for lint tooling that force-compiles `mario_roms.v` as a standalone unit to resolve its
differently-named wrapper modules (`MAIN_ROM`/`VID_ROM`/etc — see `NOTES.md`'s own "Lint" section)
and then also tries to elaborate the raw generic templates with nothing bound. Gives them defaults
so that force-compile doesn't hard-error.

## `m58715ip-p2_low_imp_o-port-mismatch.patch`

Fixes a port-width/connection mismatch on `m58715ip.v`'s `P2_low_imp_o` signal (the M58715/T48
sound MCU wrapper) uncovered while lint-checking this core.

## `mario_hv_generator-neptunoplus-hcenter-shift.patch`

`mario_hv_generator.v`'s stock HSync position (`V_CL_P=576`, `V_CL_W=640`) puts a 65-count front
porch against a 127-count back porch inside the fixed 511..767 blanking window. On a real CRT
through NeptUNO+'s analog output this lands the image **~3cm right of center** — confirmed on real
hardware, and independently reproduced by a second, unrelated MiST-based bridge of this same core
(so it's a property of this core's native timing meeting NeptUNO+'s analog chain, not a bug
introduced by either bridge's own wrapper).

Not an OSD-adjustable fix (unlike e.g. `vball`'s/`vastar`'s upstream-native H/V Center controls —
`mario_top.v` has no centering input of its own to wire up): moves `V_CL_P`/`V_CL_W` later inside
the *same* blanking window by a fixed +56 H_CNT counts (632/696), shrinking the back porch from 127
to 71 while leaving the sync pulse width (64) and the active video window (`0..H_BL_P-1`)
completely untouched — so it only repositions where the HSync pulse fires, nothing else about the
picture. **Not yet re-verified on real hardware** (the +56 delta is a first estimate from the ~3cm
symptom, not a measured value) — if it moves the picture the wrong way or overshoots/undershoots,
retune by adjusting both `V_CL_P` and `V_CL_W` by the same delta (larger delta = less back porch =
image further left; smaller/negative = more back porch = image further right; `576`/`640` is
upstream's untouched native value).
