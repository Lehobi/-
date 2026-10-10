#!/usr/bin/env python3
"""Run the complete cloud check suite and build a Studio-openable place.

These checks validate source and pure business logic; they do not run Roblox.
"""
from pathlib import Path
from collections import Counter
import argparse
import json
import shutil
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
TOOLS = Path(os.environ.get("GOOFY_TOOLS_DIR", ROOT / ".tools")).resolve()
BUILD = ROOT / "build"


def run(tool, *args):
    executable = TOOLS / "bin" / tool
    if not executable.is_file():
        raise SystemExit(f"Missing {tool}. Run python3 scripts/bootstrap.py first.")
    print(f"\nChecking: {tool} {' '.join(map(str, args))}", flush=True)
    subprocess.run([str(executable), *map(str, args)], cwd=ROOT, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", action="store_true", help="Also refresh the tracked Studio place in release/")
    args = parser.parse_args()
    BUILD.mkdir(exist_ok=True)
    files = sorted(str(p.relative_to(ROOT)) for folder in ("src", "tests") for p in (ROOT / folder).rglob("*.luau"))
    assert files, "No Luau source found"
    with (ROOT / "default.project.json").open() as source:
        project = json.load(source)
    assert project["tree"]["$className"] == "DataModel"
    run("stylua", "--check", "src", "tests")
    run("luau-compile", "--null", *files)
    run("rojo", "sourcemap", "default.project.json", "--output", "build/sourcemap.json")
    run("luau-lsp", "analyze", "--platform=roblox",
        f"--definitions={TOOLS / 'downloads/globalTypes.d.lua'}",
        "--sourcemap=build/sourcemap.json", "src", "tests")
    tests = sorted((ROOT / "tests").glob("*.spec.luau"))
    assert tests, "Zero test suites found"
    for suite in tests:
        run("luau", suite.relative_to(ROOT))
    run("rojo", "build", "default.project.json", "--output", "build/Steal-a-Goofy-Egg.rbxlx")
    place = ET.parse(BUILD / "Steal-a-Goofy-Egg.rbxlx")
    scripts = place.findall(".//Item[@class='Script']")
    clients = place.findall(".//Item[@class='LocalScript']")
    modules = place.findall(".//Item[@class='ModuleScript']")
    remotes = place.findall(".//Item[@class='RemoteEvent']")
    assert len(scripts) == 1 and len(clients) == 1, "Missing or unexpected game entrypoints"
    source_files = list((ROOT / "src").rglob("*.luau"))
    module_files = [file for file in source_files if not file.name.endswith((".server.luau", ".client.luau"))]
    assert len(modules) == len(module_files), "A game module is missing from the built place"
    assert len(remotes) == 4, "Rojo hierarchy differs from the expected remotes"
    assert len(place.findall(".//Item[@class='RemoteFunction']")) == 1
    packaged_sources = Counter(node.text or "" for node in place.findall(".//Properties/*[@name='Source']"))
    expected_sources = Counter(source.read_text() for source in (ROOT / "src").rglob("*.luau"))
    assert packaged_sources == expected_sources, "Built place does not exactly embed the checked game source"
    if args.release:
        release = ROOT / "release"
        release.mkdir(exist_ok=True)
        shutil.copyfile(BUILD / "Steal-a-Goofy-Egg.rbxlx", release / "Steal-a-Goofy-Egg.rbxlx")
        print("Refreshed release/Steal-a-Goofy-Egg.rbxlx from this checked source tree.")
    print(f"\nPASS: {len(files)} Luau files, {len(tests)} executed suites, Roblox analysis, formatting, and place build.")
    print("Studio gameplay, rendering, touch input, and multiplayer behavior remain untested here.")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
