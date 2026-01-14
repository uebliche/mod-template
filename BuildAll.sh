#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

python3 <<'PY'
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent
mcmeta_path = (ROOT / "../../web/mcmeta/loom-index.json").resolve()
if not mcmeta_path.exists():
    raise SystemExit(f"mcmeta file '{mcmeta_path}' missing")

def normalize_version(value: str):
    parts = re.split(r"[.]", str(value))
    nums = []
    for part in parts:
        match = re.match(r"(\\d+)", part)
        nums.append(int(match.group(1)) if match else 0)
    while len(nums) < 3:
        nums.append(0)
    return tuple(nums[:3])

def is_release_version(value: str) -> bool:
    return bool(re.match(r"^\\d+(\\.\\d+)*$", value))

def read_build_from():
    gradle_path = ROOT / "gradle.properties"
    if not gradle_path.exists():
        return "0.0.0"
    for line in gradle_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("buildFromVersion="):
            return line.split("=", 1)[1].strip()
    return "0.0.0"

payload = json.loads(mcmeta_path.read_text())
versions = payload.get("fabric", {}).get("versions") or payload.get("versions") or []
versions = [v for v in versions if isinstance(v, str) and is_release_version(v)]
versions.sort(key=normalize_version, reverse=True)

build_from = read_build_from()
min_key = normalize_version(build_from) if build_from else (0, 0, 0)
versions = [v for v in versions if normalize_version(v) >= min_key]

if not versions:
    raise SystemExit("No mcmeta versions found for buildFromVersion")

loaders = sorted(
    p.name[len("loader-") :]
    for p in ROOT.iterdir()
    if p.is_dir() and p.name.startswith("loader-")
)

if not loaders:
    raise SystemExit("No loaders found in loader-* directories")

cmds = []
for loader in loaders:
    project = f":loader-{loader}:build"
    for mc in versions:
        args = [str(ROOT / "gradlew"), project, f"-PmcVersion={mc}"]
        cmds.append(args)

for cmd in cmds:
    print("\n==>", " ".join(cmd))
    subprocess.run(cmd, check=True, cwd=ROOT)
PY
