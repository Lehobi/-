#!/usr/bin/env python3
"""Install pinned official Linux x86_64 tools with SHA-256 and TLS verification."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import hashlib
import io
import json
import os
import platform
import urllib.request
import zipfile

ROOT = Path(os.environ.get("GOOFY_TOOLS_DIR", Path(__file__).resolve().parents[1] / ".tools")).resolve()
ASSETS = [
    ("JohnnyMorganz/luau-lsp", "1.70.1", "luau-lsp-linux-x86_64.zip",
     "1a2ea1ae4f98f8946cefd970a4b54853e11ab4775e6932faa7f60cf920346567", ["luau-lsp"]),
    ("rojo-rbx/rojo", "v7.7.1", "rojo-7.7.1-linux-x86_64.zip",
     "00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4", ["rojo"]),
    ("luau-lang/luau", "0.741", "luau-ubuntu.zip",
     "134dc762ad26232af83e43f98dec03ff6030dd3a4452f9408b9d50ccea025503",
     ["luau", "luau-analyze", "luau-compile", "luau-ast"]),
    ("JohnnyMorganz/StyLua", "v2.5.2", "stylua-linux-x86_64.zip",
     "bcb0d855e91f102f28a370e850f8566b3b44b79e6274d806ea5246837c0fd5ab", ["stylua"]),
]
DEFINITIONS_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.lua"
DEFINITIONS_SHA = "2857efa8245485f8c25c19c018ee1ef9b46afab4efd2ea70fc3257cd3faf7080"


def verified_download(url, filename, expected_sha):
    path = ROOT / "downloads" / filename
    if path.exists():
        data = path.read_bytes()
    else:
        # urllib's default HTTPS context validates certificates; never disable it.
        with urllib.request.urlopen(url, timeout=60) as response:
            data = response.read()
    if hashlib.sha256(data).hexdigest() != expected_sha:
        raise RuntimeError(f"Integrity mismatch for {filename}; refusing to install")
    path.write_bytes(data)
    return data


def install(asset):
    repository, version, archive_name, sha, executables = asset
    url = f"https://github.com/{repository}/releases/download/{version}/{archive_name}"
    data = verified_download(url, archive_name, sha)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        files = archive.namelist()
        for executable in executables:
            candidates = [name for name in files if Path(name).name == executable]
            if len(candidates) != 1:
                raise RuntimeError(f"Expected one {executable} in {archive_name}")
            # Extract only the named binary, never arbitrary archive paths.
            output = ROOT / "bin" / executable
            output.write_bytes(archive.read(candidates[0]))
            output.chmod(0o755)
    return {"tool": repository, "version": version, "sha256": sha}


def main():
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "AMD64"):
        raise SystemExit("Bootstrap supports Linux x86_64. See README for native Studio/Rojo instructions.")
    (ROOT / "downloads").mkdir(parents=True, exist_ok=True)
    (ROOT / "bin").mkdir(parents=True, exist_ok=True)
    verified_download(DEFINITIONS_URL, "globalTypes.d.lua", DEFINITIONS_SHA)
    print("Verified Roblox definitions (luau-lsp 1.70.1)", flush=True)
    with ThreadPoolExecutor(max_workers=3) as executor:
        for result in executor.map(install, ASSETS):
            print(json.dumps(result), flush=True)
    print(f"Tools ready in {ROOT / 'bin'}", flush=True)


if __name__ == "__main__":
    main()
