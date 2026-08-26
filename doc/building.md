# Building

The two kinds of core described in the [top-level README](../README.md) build differently:
**jtframe** cores go through JTFRAME's own CLI pipeline end to end; **native** cores skip that
pipeline entirely and synthesize directly from a standalone Quartus project. Both are documented
separately below.

## jtframe cores

Cores follow [jotego/jtcores](https://github.com/jotego/jtcores)' own JTFRAME conventions and
tooling (`jtframe`, `jtutil`, `jtsim`, `jtcore`) — just with an added neptUNO+ target. Every step
below can run as a plain command against a local toolchain, or in Docker to avoid installing one;
only synthesis (Quartus) *requires* Docker, since Quartus itself isn't something these images can
legally redistribute for local install.

### Prerequisites: compiling `jtframe` / `jtutil`

`jtframe` (drives `.mra` generation, target file generation, etc.) and `jtutil` (macro/config
plumbing `jtcore` shells out to) are Go CLIs built from source, once, before anything else —
**`CGO_ENABLED=0` is required, not optional**: a normally-linked binary pulls in the host's glibc,
which is newer than what `jotego/jtcore13`'s older base image ships (confirmed directly: a
non-static build fails inside that image with `version 'GLIBC_2.34' not found`; `jotego/simulator`
happens to tolerate it, `jotego/jtcore13` does not — don't rely on that inconsistency, always build
static):

```sh
cd modules/jtframe/src/jtframe && CGO_ENABLED=0 go build .
cd modules/jtframe/src/jtutil  && CGO_ENABLED=0 go build .
```

Rebuild them (same command) whenever `modules/jtframe` is updated — both `bin/jtframe`/`bin/jtutil`
themselves and this project's own tooling check `.go` mtimes against the binary and rebuild
automatically, but a stale manually-built binary won't self-detect that.

### 1. Lint

Don't hand-roll a `verilator` invocation — a core's real macro set (`JTFRAME_MEMGEN`, per-target
clock timing, etc.) and its generated `mem_ports.inc`/`jtframe_game_ports.inc` includes only exist
once JTFRAME's own environment is initialized, so `lint-one.sh` (which does that via `jtframe
cfgstr`/`jtframe mem` before invoking Verilator) is the only supported entry point:

```sh
source modules/jtframe/bin/setprj.sh   # sets JTROOT/JTFRAME/CORES/MODULES/JTBIN + PATH
lint-one.sh <core>
```

Needs a local `verilator` install. **Docker** (no local Verilator needed) — same script, run
inside `jotego/simulator` with the whole repo bind-mounted so `setprj.sh` resolves paths correctly:

```sh
docker run --rm --entrypoint bash --user "$(id -u):$(id -g)" \
  -v "$PWD":/build -w /build \
  jotego/simulator -c 'source /build/modules/jtframe/bin/setprj.sh && lint-one.sh <core>'
```

`jotego/simulator` is jotego's own CI image — Verilator + Icarus Verilog on top of
`jotego/jtcore-base` (see JTFRAME's [`devops/linter.df`](../modules/jtframe/devops/linter.df)).

### 2. Simulate (`jtsim`)

Same environment requirement as lint, plus `jtsim` must be run from inside the specific ROM set's
own `ver/<setname>/` folder (not the core's root), and needs the real MAME ROM at
`$JTROOT/rom/<setname>.rom` — it fails cleanly with a clear error if that ROM isn't present, which
is expected (ROMs are copyrighted, never bundled in this repo):

```sh
source modules/jtframe/bin/setprj.sh
cd $CORES/<core>/ver/<setname>
jtsim -mister   # or -neptunoplus, -mist, ...
```

**Docker**, same pattern as lint:

```sh
docker run --rm --entrypoint bash --user "$(id -u):$(id -g)" \
  -v "$PWD":/build -w /build \
  jotego/simulator -c 'source /build/modules/jtframe/bin/setprj.sh && cd $CORES/<core>/ver/<setname> && jtsim -mister'
```

### 3. Generate `.mra` / `.arc` from `cfg/mame2mra.toml`

`.mra` comes straight from the `jtframe` binary built above, reading each core's
`cfg/mame2mra.toml` (plus MAME's XML database for the referenced driver/sets). `--skipROM` skips
packing the actual MAME ROM data (needs real ROM zips under `$JTROOT/rom/`, same as `jtsim` above)
and just emits the `.mra` XML — drop it once you do have the ROMs available:

```sh
source modules/jtframe/bin/setprj.sh
jtframe mra <core> --verbose --skipROM
```

Same via Docker (`jotego/simulator`, same `--user`/bind-mount pattern as lint/simulate above).
Output lands in `$JTROOT/release/mra/` (jotego's own default) — copy the result into the core's own
self-contained SOURCE pool `cores/<core>/mra/` in the develop checkout (jtframe cores nest
MiSTer-devel imports under `cores/<core>/mra/mister/`), never renamed/hand-edited in place. A
separate "Publish to release" step (arcfpga-ui) copies a selection of it into
`cores/<core>/releases/mra/` (optionally renaming to the MAME/HBMame description there) — which is
the only tier that exists at all in the production `arcfpga-cores` repo (no separate source pool
there).

`.arc` (the MiST-family equivalent) is then derived from that `.mra` by
[mist-devel/mra-tools-c](https://github.com/mist-devel/mra-tools-c)'s own `mra` CLI — the same
tool jotego's own release process uses (see JTFRAME's `bin/jtbin2sd`). It's not vendored in this
repo — clone and build it separately, wherever you keep local toolchains:

```sh
git clone https://github.com/mist-devel/mra-tools-c
cd mra-tools-c && make -j
```

then, per ROM set:

```sh
/path/to/mra-tools-c/mra -z <romset>.zip -O cores/<core>/arc -A -s -a "<display name>" <core>.mra
```

### 4. Synthesize

FPGA image (`.rbf`) synthesis runs Quartus inside jotego's own per-platform Docker images —
Quartus isn't installed locally at all:

| Target | Image |
|---|---|
| MiSTer | `jotego/jtcore24` |
| MiST / SiDi / neptUNO+ | `jotego/jtcore13` |
| Pocket | `jotego/jtcore20` |

```sh
docker run --rm --entrypoint "" --user "$(id -u):$(id -g)" \
  -v "$PWD/modules":/jtcores:ro \
  -v /path/to/build:/build \
  -v "$PWD/cores/<core>/cfg":/core_cfg:ro \
  -v "$PWD/cores/<core>/hdl":/core_hdl:ro \
  jotego/jtcore13 bash -c '
    mkdir -p /build/modules /build/cores/<core>/cfg /build/cores/<core>/hdl
    cp -rp /jtcores/. /build/modules/
    cp -r /core_cfg/. /build/cores/<core>/cfg/
    cp -r /core_hdl/. /build/cores/<core>/hdl/
    cd /build && git init -q && git -c user.email=a@a -c user.name=a commit --allow-empty -q -m x
    export JTROOT=/build JTFRAME=/build/modules/jtframe CORES=/build/cores MODULES=/build/modules
    export PATH=$PATH:/build/modules/jtframe/bin
    jtcore <core> -neptunoplus --nolinter
  '
```

Output lands in `/build/release/<target>/` — copy the resulting `.rbf` into the core's own
self-contained `cores/<core>/releases/<target>/` (e.g. `cores/<core>/releases/neptunoplus/`); like
`rom/`/`zip/`, this is gitignored in the develop checkout (only the production `arcfpga-cores` repo
commits `.rbf`). A core with a `syn/` override needs the matching
`-v ...cores/<core>/syn:/core_syn:ro` mount too, copied into `/build/cores/<core>/syn/` before
`jtcore` runs — same idea as the `hdl` mount above.

## native cores

Native cores have no `cfg/` — there's nothing to generate before synthesis. Lint runs
Verilator/Icarus directly against the vendored `hdl/` + `neptunoplus/` tree. FPGA image (`.rbf`)
synthesis runs the core's own standalone Quartus project (`neptunoplus/<core>_neptunoplus.qpf`)
with `quartus_sh`, inside Docker — Quartus isn't installed locally at all:

```sh
docker run --rm --entrypoint "" --user "$(id -u):$(id -g)" \
  -v "$PWD/cores/<core>":/build/cores/<core> \
  -v "$PWD/modules":/build/modules:ro \
  raetro/quartus:13.1 bash -c '
    cd /build/cores/<core>/neptunoplus && quartus_sh --flow compile <core>_neptunoplus.qpf
  '
```

`raetro/quartus:13.1` provides Quartus 13.1, the toolchain version neptUNO+/MiST/SiDi synthesis
requires. `modules/` is mounted read-only since a native core's `.qsf` commonly reaches into it
(e.g. a shared CPU core) via a relative path from `neptunoplus/`. Output lands in
`neptunoplus/output_files/<core>_neptunoplus.rbf`. `.mra` for a native core is landed as-is from
its own upstream repo — not generated.
