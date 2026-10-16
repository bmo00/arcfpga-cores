# Patches — systemc2 / neptunoplus

Diffs against the vendored `../../hdl/` at `external.commit` (see `cores.json` and
`neptunoplus/NOTES.md`). `hdl/` itself stays pristine — these are applied at build time, never
committed as edits to the vendored tree.

## `sdram-cyclone-iv-device-family.patch`

`hdl/rtl/sdram.sv`'s `altddio_out` instance (the primitive that generates `SDRAM_CLK` from the
controller's own `clk`, a plain DDIO output register — not a fractional/reconfigurable PLL, so this
is unrelated to the `pll`→`pll.v` swap below) hardcodes
`.intended_device_family("Cyclone V")`, matching the upstream board's own `5CEBA2F17A7`. NeptUNO+ is
a Cyclone IV GX (`EP4CGX150DF27I7`) — a real device-family mismatch Quartus would reject at
synthesis (`altddio_out` is available on both families, just not pre-targeted for one from the
other). Fixes by changing the `intended_device_family` string to `"Cyclone IV GX"`; no other part of
the instance changes.
