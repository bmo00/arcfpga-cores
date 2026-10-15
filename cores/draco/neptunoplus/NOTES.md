# Porting notes — draco → neptUNO+

Imported from [`jlrh/cidelsa-fpga`](https://github.com/jlrh/cidelsa-fpga), commit
`8e65f3a460e5d436293fafb702bcd89db4c64722`.

## Architecture notes

- **Template**: `cores/destroyer/neptunoplus/` (same upstream repo, same VIS video/CDP1802 hardware
  family, already bridged). `.qpf`/`.sdc`/`pll.v`/`build_id.v` are copies with names changed; the
  `.qsf` keeps destroyer's pinout/device/MiST-module block and swaps only the game-logic file list.
- **Upstream top read**: `../hdl/mister/Draco.sv` (module `emu`, hps_io-based). `../hdl/rtl/draco_machine.v`
  is protocol-agnostic, so the adapter is a fresh MiST-style wrapper (user_io/data_io/arcade_inputs/
  mist_dual_video/dac) wired to it exactly as `Draco.sv` wires it to hps_io.
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
  `patches/draco_machine-no-synth-readmemh.patch` (see `patches/README.md`).

### Draco-specific

- **Extra enables** (as `Draco.sv`): `ce_cpu`=554kHz (CDP1802), `ce_cop`=126kHz (COP402 sound
  CPU), `ce_ay`=2.012MHz (AY-3-8910).
- **jt49**: upstream's `files_draco.qip` points at `../rtl/jt49/`, a git submodule of
  `jlrh/cidelsa-fpga` that was **not** vendored into `../hdl/`. The `.qsf` uses this repo's
  `modules/jt49/hdl/` instead (jotego/jt49, pinned in `modules.json`); `jt49_bus`'s port list
  matches `draco_sound.v`'s instantiation.
- **Inputs** (as `Draco.sv`): J1 = Start 1P(4), Start 2P(5), Coin(6); two simultaneous 4-way sticks.
  `in0` = ~{6'b0,Start2,Start1}; `in2` = ~{P2 L,R,D,U, P1 L,R,D,U}.
- **Sound ROM download — the one real deviation from upstream.** The `.mra` sends the 16KB program
  ROM as `ioctl_index` 0 and the 2KB COP402 ROM (`dra s 1.ic4`) as `ioctl_index` 1. NeptUNO+ loads a
  single `.rom` built by mra-tools-c, which only contains `<rom index="0">` (it reads index 1 only
  for the `.arc` `MOD=` byte — `src/arc.c`). The bridge therefore accepts the sound ROM both ways:
  `ioctl_index` 1 at 0x000-0x7FF (MiSTer layout), **or** `ioctl_index` 0 at 0x4000-0x47FF (appended
  after the program ROM). **Open issue**: with the current `.mra`, the NeptUNO+ `.rom` has no sound
  ROM, so the game should boot but stay silent. Fixing it needs a neptUNO+ `.rom` with
  `dra s 1.ic4` appended at 0x4000 (e.g. an `.mra` variant that puts that part in `index="0"`
  after the program parts) — not done, since `mra/` files are never hand-edited here.
- Side effect of the same mra-tools-c rule: once `draco.zip` is available, `MOD=` in the generated
  `.arc` becomes the first byte of the sound ROM instead of 0. Harmless here (the bridge ignores
  `core_mod`), but worth knowing.

## Verification status (2026-10-15)

- [x] Lint (Verilator, destroyer's methodology): no real errors. Only the known-benign classes:
  `dac` (VHDL), `RGBtoYPbPr` (module-name != filename, listed explicitly in the `.qsf`),
  `PINMISSING` on `mist_dual_video`'s unused SDRAM/rotation ports, `TIMESCALEMOD`, width warnings.
- [x] Quartus 13.1 full compile (`raetro/quartus:13.1`, staged + patched exactly like arcfpga-ui's
  native build): first attempt **did not fit** (174,083 registers vs 149,760) because upstream reads
  `rom`/`dram` asynchronously (Cyclone V MLAB) — fixed by `patches/draco_machine-sync-rom-read.patch`.
  With it: **success**, `.rbf` produced. 55,591 LEs (37%), 34,820 registers, 291,072 memory bits
  (4%). All TimeQuest slacks positive (worst 0.088ns). Still built from registers (async read,
  small): COP402 `rom` (2KB) and `vis_vram` `page_mem_v`. Only critical warning: `CLOCK_27[1]`
  (intentional `VIRTUAL_PIN`, same as destroyer).
- [ ] Real NeptUNO+ hardware: boot, video, controls, sound, DIP switches, coin1/coin2, flip.
- [ ] Update `cores.json` `releases.neptunoplus` once a real build lands.
