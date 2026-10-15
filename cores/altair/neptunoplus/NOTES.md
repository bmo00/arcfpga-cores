# Porting notes — altair → neptUNO+

Imported from [`jlrh/cidelsa-fpga`](https://github.com/jlrh/cidelsa-fpga), commit
`8e65f3a460e5d436293fafb702bcd89db4c64722`. One bitstream (`altair_neptunoplus`) runs both
`altair` and `altair2` (same `altair_machine`, different `.rom`).

## Architecture notes

- **Template**: `cores/destroyer/neptunoplus/` (same upstream repo, same VIS video/CDP1802 hardware
  family, already bridged). `.qpf`/`.sdc`/`pll.v`/`build_id.v` are copies with names changed; the
  `.qsf` keeps destroyer's pinout/device/MiST-module block and swaps only the game-logic file list.
- **Upstream top read**: `../hdl/mister/Altair.sv` (module `emu`, hps_io-based). `../hdl/rtl/altair_machine.v`
  is protocol-agnostic, so the adapter is a fresh MiST-style wrapper (user_io/data_io/arcade_inputs/
  mist_dual_video/dac) wired to it exactly as `Altair.sv` wires it to hps_io.
- **Clock**: no SDRAM, no core-owned PLL. The bridge PLL is destroyer's 50MHz -> 30MHz `altpll`.
  Upstream's own MiSTer PLL runs at 28.132MHz, but every enable is a phase accumulator computed from
  `CLK_KHZ`, so only `CLK_KHZ` changes (30000 vs 28130) — same enable rates as upstream.
  `coin_debounce`'s cycle counts are rescaled the same way (30000 / 1500000 -> same 1ms / 50ms).
- **DIP switches**: `../mra/*.mra` use `<switches default="0xff" base="16">` and `../arc/*.arc` use
  `DEFAULT=0xFF0000`, so the DIP byte is `status[23:16]` -> `in1`, as in destroyer.
- **OSD (`CONF_STR`)**: same final layout as destroyer after its real-hardware fixes — options first,
  `"DIP;"` just before the `J1`/Reset tail, no `"-;"` immediately before `"DIP;"`,
  `.BIG_OSD(1'b1)`. Status bits: 8 aspect, 9 OSD orientation, 10-11 scanlines, 12 reset,
  13 swap joysticks, 14 flip 180 (`.flip` port — new vs destroyer, whose machine has no flip).
- **Video**: raw pass-through (`rotate_screen=0`, real rotation needs SDRAM); blanking derived from
  `hcount`/`vcount` with the same thresholds as upstream (30/324, 10/304). 888 RGB.
- **Audio**: signed PCM -> offset binary (`{~audio[15], audio[14:0]}`) into `dac.vhd`, as destroyer.
- **Coins**: per-joystick EF lines (`ef_ext[3]`=Coin1, `ef_ext[2]`=Coin2) through `coin_debounce`,
  swapped with "Swap Joysticks", keyboard coin OR-ed in.
- **ROM init**: synthesis-time `$readmemh` removed by
  `patches/altair_machine-no-synth-readmemh.patch` (see `patches/README.md`).

### Altair-specific

- **Inputs** (as `Altair.sv`): J1 = Fire(4), Fire 2(5), Start 1P(6), Start 2P(7), Coin(8).
  `in0` = ~{0,0,Fire,Left,Right,Start2,Start1,0}; `in2` = ~{5'b0,Fire 2,Down,Up}. Upstream drives
  all player controls from `joystick_0` only (alternating 2P); kept that way (`player1`, plus
  keyboard via `arcade_inputs`).
- **ROM**: single `ioctl_index` 0 download, 14-bit address (16KB) — matches the `.mra` and the
  NeptUNO+ `.rom` layout directly.

## Verification status (2026-10-15)

- [x] Lint (Verilator, destroyer's methodology): no real errors. Only the known-benign classes:
  `dac` (VHDL), `RGBtoYPbPr` (module-name != filename, listed explicitly in the `.qsf`),
  `PINMISSING` on `mist_dual_video`'s unused SDRAM/rotation ports, `TIMESCALEMOD`, width warnings.
- [x] Quartus 13.1 full compile (`raetro/quartus:13.1`, staged + patched exactly like arcfpga-ui's
  native build): **success**, `.rbf` produced. 14,687 LEs (10%), 9,573 registers, 235,520 memory
  bits (4%), 1 PLL. All TimeQuest slacks positive. Only critical warning: `CLOCK_27[1]` has no pin
  location (intentional `VIRTUAL_PIN`, same as destroyer).
- [ ] Real NeptUNO+ hardware: boot, video, controls, sound, DIP switches, coin1/coin2, flip.
- [ ] Update `cores.json` `releases.neptunoplus` once a real build lands.
