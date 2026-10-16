# patches: divergence from upstream `jotego/jtcores`

`cores/prmr` is vendored from `jotego/jtcores` (see `cores.json`'s `external.repo`/`external.commit`). These patches document local changes that don't come from that upstream and must be reapplied after any future re-sync to a newer pinned commit (`applyCorePatches` in arcfpga-ui does it automatically; paths are `-p1` relative to the core directory).

## `hdl-jt539-stub-vs-upstream.diff`

Adds `hdl/jt539_single.v`: silent placeholder modules with the same port list as jotego's `jt539` (Konami
K054539 PCM chip).

**Why**: `jt539` is a private beta module — upstream's own `cfg/files.yaml` has it commented out
(`#jt539:`) and `modules/jt539` is empty in the public jtcores tree — so lint and both builds failed
with `Cannot find file containing module: 'jt539_...'` / `Node instance ... instantiates undefined
entity "jt539_..."`. The stubs keep register reads at 0, the ROM ports idle and the timer output
inactive, and pass the chip's `aux` input straight to its output. prmr reuses `cores/rungun/hdl/jtrungun_sound.v` with `PRMR=1` (single chip) but pulls only specific files from rungun, so it needs its own copy of `jt539_single.v`. The PCM path is silent, and the sound Z80 gets no NMI: `jtrungun_sound.v` drives it from the K054539 timer (`eff_nmin = tima` when `PRMR==1`), and the stub holds `timeout` inactive. If the game waits for the sound CPU at boot, this is the first thing to check.

Remove this patch (and the stub files) once `jt539` is public.
