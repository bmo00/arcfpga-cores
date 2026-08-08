# Mysterious Stones — Memory Map & I/O

Main CPU (6502A @ 1.5MHz) address space. Source: `board_spec.json`'s `memory_map`, cross-checked
against the real program-ROM bus decode found on the schematic (see
[HARDWARE.md](HARDWARE.md#program-rom-bus)).

## CPU memory map

| Range | Type | Name | Notes |
|-------|------|------|-------|
| `$0000`-`$077F` | RAM | Work RAM | |
| `$0780`-`$07DF` | RAM | Sprite RAM | 96 bytes, 4 bytes/entry, 24 sprites max |
| `$07E0`-`$0FFF` | RAM | Work RAM (extended) | |
| `$1000`-`$17FF` | RAM (video) | Foreground videoram | Code low byte at `tile_index`, code hi bit + unused at `$400+tile_index` |
| `$1800`-`$1FFF` | RAM (video) | Background videoram | Two selectable `$400` pages (`video_control` bit 2); code hi bit at `page\|$200\|tile_index` |
| `$2000` (read) | I/O | IN0 — P1 joystick/buttons/coins | Mirrored every `$10` across `$2000`-`$3fff` (mirror mask `$1f8f`) |
| `$2000` (write) | I/O | Video control register | D0-1 fg text color, D2 bg page select, D4-5 coin counters, D7 screen flip |
| `$2010` (read) | I/O | IN1 — P2 joystick/buttons/start | |
| `$2010` (write) | I/O | IRQ acknowledge | Clears the CPU's maskable IRQ line |
| `$2020` (read) | I/O | DSW0 dipswitches | |
| `$2020` (write) | I/O | Background Y scroll register | Write-only; applied via tilemap `set_scrolly` |
| `$2030` (read) | I/O | DSW1 dipswitches | |
| `$2030` (write) | I/O | AY8910 shared data latch | Combined with the select latch at `$2040` to emulate the discrete BDIR/BC1 bus |
| `$2040` (write) | I/O | AY8910 BDIR/BC1 select latch | bit5/4 -> ay1 BDIR/BC1 edge, bit7/6 -> ay2 BDIR/BC1 edge; no read handler |
| `$2050` | I/O | Unused I/O slot | No read or write handler installed |
| `$2060`-`$207F` | RAM | Palette RAM | 32 bytes, low half of the 64-entry palette (mirror mask `$1f80`) |
| `$4000`-`$FFFF` | ROM | Program ROM | |

The real schematic's program-ROM bus decoder produces dedicated chip-select nets matching this
split directly: `*BACK` (background RAM), `*VRAM` (video RAM), `*ZERO`/`ZERO` (zero-page RAM), and
`*I/O` — confirming this memory map from hardware, not just MAME driver source.

## Interrupts

- **IRQ** (maskable): software-timed, 16 pulses per frame, starting at scanline 8 and repeating
  every 16 lines, cleared by writing `$2010`. The FPGA core's video timing generator reproduces
  this exact cadence rather than a single per-frame vblank pulse.
- **NMI**: hardware-asserted directly on a coin-switch edge (either coin slot), with no software
  acknowledge register — confirmed both on the schematic (a dedicated NMI line crossing both
  PCBs) and in the FPGA core (`mystston_main.v`: `nmi = ~coin[0] | ~coin[1]`).

## Dipswitches

### DSW0 (`$2020` read)

| Bit(s) | Name | Values | Default |
|---|---|---|---|
| 0 | Lives | 3 / 5 | 3 |
| 1 | Difficulty | Easy / Hard | Easy |
| 2 | Demo Sounds | Off / On | On |
| 3-7 | Unused | Off / On | Off |

### DSW1 (`$2030` read)

| Bit(s) | Name | Values | Default |
|---|---|---|---|
| 0-1 | Coin A | 2C/1C, 1C/1C, 1C/2C, 1C/3C | 1 Coin/1 Credit |
| 2-3 | Coin B | 2C/1C, 1C/1C, 1C/2C, 1C/3C | 1 Coin/1 Credit |
| 4 | Unused | Off / On | Off |
| 5 | Flip Screen | Off / On | Off |
| 6 | Cabinet | Upright / Cocktail | Upright |

`video_control` bit 7 (screen flip) is XORed against DSW1 bit 5 on real hardware — cocktail flip
logic combines both sources rather than either alone.

## Inputs

2 players, 4-way joystick each, 2 buttons (Fire, Kick). Real connector pinout, coin conditioning
(2SC1075 transistors + dual NE555 pulse timers) and control-line filtering are documented in
[HARDWARE.md](HARDWARE.md#inputs) — board wiring detail with no bearing on the FPGA core, which
just synchronizes and edge-detects the digital inputs.
