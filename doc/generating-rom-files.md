# Generating `.rom` files

A `.mra` in this project is metadata only: which MAME ROM regions go where in the core's address
space, checksums to verify them, DIP switches and inputs. It contains no game data. Running a core
still needs the real MAME ROM dump for that machine, legally obtained by you, merged with the
`.mra` into the `.rom` file the core loads. This project doesn't provide ROM dumps or point to
where to find them — only the merge step below.

## Background

### Which platforms need this

MiSTer loads a core straight from the `.mra` plus your MAME zip; its own arcade loader merges the
two on the device, so there's no separate `.rom` to build.

MiST, SiDi, SiDi128, and neptUNO+ have no on-device MRA parser. They load a pre-built pair instead:
`.arc` (a small descriptor — which file, where) and `.rom` (the merged game data). Neither works
alone. If you're only targeting MiSTer, skip this doc.

### What the file is

The literal, headerless binary image the core's SDRAM controller expects at boot: every ROM region
from your MAME zip, extracted and laid out exactly as the `.mra`'s `<rom>` map says (which mirrors
the core's own `cfg/mem.yaml` SDRAM layout). No filesystem, no MAME container — just the bytes the
core streams into SDRAM. Two cores with similarly-sized ROM sets can still need very different
`.rom` layouts, since the layout comes from that core's own memory map, not from MAME's.

### What about `.ram` files

Some sets also get a `<setname>.ram` alongside the `.rom`, from the same `mra` run — no extra
step. It only happens when the `.mra` declares an `<nvram>` region: a few arcade boards have a
small battery-backed RAM chip (settings, high scores) that needs a known starting state, and
`.ram` is that state. It's normally a fixed byte pattern written straight into the `.mra`'s own
XML rather than pulled from your zip — `prmr`'s "Premier Soccer" sets, for example, embed a
128-byte block starting `03 F1 FC 0E 91 01 45 41 42 ...` — so it isn't copyrighted MAME data the
way `.rom` is. Most sets have no `<nvram>` tag and produce no `.ram` at all.

Where it exists, it sits alongside `.rbf`, `.arc`, and `.rom` in the same folder, same as those.

## Building

### One set at a time

You need:

- The `.mra` for the set you want (`cores/<core>/releases/mra/`, or `cores/<core>/mra/` in the
  develop checkout).
- Your own legally-dumped MAME zip(s) for that exact set, matching the `.mra`'s `<mameversion>` —
  a different MAME revision can split ROMs differently and break the merge. The `.mra`'s
  `<rom zip="...">` attribute names the zip(s) needed; sometimes two, pipe-separated
  (`zip="rastan.zip|cchip.zip"`), meaning the set also needs its MAME parent's zip.
- The `mra` CLI from [mist-devel/mra-tools-c](https://github.com/mist-devel/mra-tools-c), the same
  tool [doc/building.md](building.md) uses for `.arc`:

  ```sh
  git clone https://github.com/mist-devel/mra-tools-c
  cd mra-tools-c && make -j
  ```

Put your zip(s) in one directory — no renaming needed, `mra` matches by MAME's own zip filenames —
then run:

```sh
/path/to/mra-tools-c/mra -z /path/to/your/zips -O /path/to/output -A "<core>.mra"
```

`-z` is the zip search directory, `-O` the output directory, `-A` also builds the `.arc`. Without
`-o`/`-a` the filenames come from the `.mra` itself (setname for `.rom`, display name for `.arc`).

The result isn't meant to stay where you built it. On an SD card, `.rbf`, `.arc`, and `.rom` sit
flat together in the same folder — that's how a MiST-family loader finds them. The `.rbf` itself
comes from `cores/<core>/releases/<target>/`, dated (`jtrastan_20260820.rbf`); drop the
`_YYYYMMDD` suffix when copying it over, the loader doesn't care about build dates:

```
jtrastan.rbf
Rastan (World Rev 1).arc
rastan.rom
```

Don't commit, distribute, or share a `.rom` built this way — it embeds copyrighted MAME data from
your own zip and carries the same copyright. `cores/<core>/releases/rom/` is where this project
stages one locally; it's gitignored and never part of either repo.

### Every core at once

`scripts/generate_roms.py` runs the merge above across every released core (or one, via `--core`),
given a single flat directory of your MAME zips:

```sh
python3 scripts/generate_roms.py /path/to/your/zips /path/to/dest --target neptunoplus
```

For each core, it finds the parent and alternate/clone sets under `releases/mra/`, runs `mra` on
each, and copies the matching `.rbf` alongside the results — into `<dest>/<core>/` and again into
`<dest>/<core>/alternatives/`, so either folder is playable on its own.

Flags:

- `--core KEY` — only this core, instead of every released one.
- `--target TARGET` — which `releases/<target>/` build to pull the `.rbf` from (default:
  `neptunoplus`).
- `--no-alternatives` — parent sets only, skip alternates and that folder entirely.
- `--mra-bin PATH` — path to the `mra` CLI, if it's not on your `PATH`.

Running it against `mystston` (one parent, two alternates) and `opwolf` (one parent, six
alternates) leaves:

```
dest/
  mystston/
    mystston.rbf
    Mysterious Stones: Dr. John's Adventure.arc
    mystston.rom
    alternatives/
      mystston.rbf
      Mysterious Stones: Dr. Kick in Adventure.arc
      myststono.rom
      Mysterious Stones: Dr. Kick in Adventure (Itisa PCB).arc
      myststonoi.rom
  opwolf/
    opwolf.rbf
    Operation Wolf (World, rev 2, set 1).arc
    opwolf.rom
    alternatives/
      opwolf.rbf
      Operation Wolf (Japan, rev 2).arc
      opwolfj.rom
      ... (5 more alternate .arc/.rom pairs)
```
