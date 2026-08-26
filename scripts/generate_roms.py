#!/usr/bin/env python3
"""Batch-generate .arc/.rom files for released cores from your own MAME ROM zips.

For each core, this finds the parent and alternate/clone sets under releases/mra/, runs `mra` on
each, and copies the matching releases/<target>/*.rbf alongside the results (date suffix
stripped) — into <dest>/<key>/ and again into <dest>/<key>/alternatives/, so either folder works
on its own. See doc/generating-rom-files.md for the full picture and an example.

Needs the `mra` CLI (mist-devel/mra-tools-c) on PATH, or point --mra-bin at it.

Usage: python3 scripts/generate_roms.py <roms_dir> <dest_dir> [--core KEY] [--target TARGET]
                                         [--no-alternatives] [--mra-bin PATH]
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

RBF_DATE_RE = re.compile(r"_\d{8}(?=\.rbf$)")


@dataclass
class Config:
    repo_root: Path
    roms_dir: Path
    target: str
    mra_bin: str
    include_alternatives: bool


@dataclass
class Tally:
    ok: int = 0
    fail: int = 0

    def add(self, success: bool) -> None:
        if success:
            self.ok += 1
        else:
            self.fail += 1

    def __iadd__(self, other: Tally) -> Tally:
        self.ok += other.ok
        self.fail += other.fail
        return self


def strip_rbf_date(filename: str) -> str:
    return RBF_DATE_RE.sub("", filename)


def latest_rbf(rbf_dir: Path) -> Path | None:
    """Picks the newest build if an old dated .rbf was never cleaned up (YYYYMMDD sorts fine as
    a plain string)."""
    rbfs = sorted(rbf_dir.glob("*.rbf"))
    return rbfs[-1] if rbfs else None


def collect_mra_paths(mra_root: Path) -> tuple[list[Path], list[Path]]:
    """Parent and alternate/clone .mra paths, including the mister/ sibling some native cores
    have (same parent-vs-alternatives split, one level down)."""
    parents: list[Path] = []
    alternates: list[Path] = []
    for root in (mra_root, mra_root / "mister"):
        if not root.is_dir():
            continue
        parents.extend(sorted(root.glob("*.mra")))
        alt_dir = root / "alternatives"
        if alt_dir.is_dir():
            alternates.extend(sorted(alt_dir.rglob("*.mra")))
    return parents, alternates


def run_mra(mra_bin: str, mra_path: Path, roms_dir: Path, out_dir: Path) -> bool:
    result = subprocess.run([mra_bin, "-z", str(roms_dir), "-O", str(out_dir), "-A", str(mra_path)])
    return result.returncode == 0


def process_core(key: str, dest_root: Path, config: Config) -> Tally:
    mra_root = config.repo_root / "cores" / key / "releases" / "mra"
    if not mra_root.is_dir():
        return Tally()

    parents, alternates = collect_mra_paths(mra_root)
    if not config.include_alternatives:
        alternates = []
    if not parents and not alternates:
        return Tally()

    print(f"== {key}: {len(parents)} parent set(s), {len(alternates)} alternate set(s) ==")
    out_dir = dest_root / key
    out_dir.mkdir(parents=True, exist_ok=True)

    rbf_dir = config.repo_root / "cores" / key / "releases" / config.target
    rbf = latest_rbf(rbf_dir) if rbf_dir.is_dir() else None
    if rbf:
        shutil.copy2(rbf, out_dir / strip_rbf_date(rbf.name))
    else:
        print(f"  ! no {config.target} .rbf for {key}, skipping bitstream", file=sys.stderr)

    tally = Tally()
    for mra_path in parents:
        tally.add(run_mra(config.mra_bin, mra_path, config.roms_dir, out_dir))

    if alternates:
        alt_out = out_dir / "alternatives"
        alt_out.mkdir(exist_ok=True)
        if rbf:
            # Same .rbf again, so alternatives/ is a self-contained folder too.
            shutil.copy2(rbf, alt_out / strip_rbf_date(rbf.name))
        for mra_path in alternates:
            tally.add(run_mra(config.mra_bin, mra_path, config.roms_dir, alt_out))

    return tally


def core_keys(repo_root: Path, only: str | None) -> list[str]:
    if only:
        if not (repo_root / "cores" / only).is_dir():
            sys.exit(f"error: no such core: {only}")
        return [only]
    return sorted(p.name for p in (repo_root / "cores").iterdir() if p.is_dir())


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("roms_dir", type=Path, help="directory of your own legally-dumped MAME ROM zips")
    parser.add_argument("dest_dir", type=Path, help="output directory; one subfolder is created per core")
    parser.add_argument("--core", help="only this cores.json key (default: every core with a releases/mra/)")
    parser.add_argument("--target", default="neptunoplus", help="which releases/<target>/*.rbf to copy (default: neptunoplus)")
    parser.add_argument("--no-alternatives", action="store_true", help="skip alternate/clone sets, parent sets only")
    parser.add_argument("--mra-bin", default="mra", help="path to the mra CLI (default: 'mra' on PATH)")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if not args.roms_dir.is_dir():
        sys.exit(f"error: {args.roms_dir} is not a directory")
    if shutil.which(args.mra_bin) is None and not Path(args.mra_bin).is_file():
        sys.exit(f"error: mra CLI not found ({args.mra_bin}) — see doc/generating-rom-files.md to build it")

    repo_root = Path(__file__).resolve().parent.parent
    config = Config(
        repo_root=repo_root,
        roms_dir=args.roms_dir,
        target=args.target,
        mra_bin=args.mra_bin,
        include_alternatives=not args.no_alternatives,
    )

    args.dest_dir.mkdir(parents=True, exist_ok=True)

    total = Tally()
    for key in core_keys(repo_root, args.core):
        total += process_core(key, args.dest_dir, config)

    print(f"\n{total.ok} set(s) generated, {total.fail} failed")
    sys.exit(1 if total.fail else 0)


if __name__ == "__main__":
    main()
