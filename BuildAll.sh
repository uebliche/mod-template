#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

matrix_json=$(python3 <<'PY'
import json, os, pathlib
matrix = json.loads(pathlib.Path('versions.matrix.json').read_text())
print(json.dumps(matrix))
PY
)

run() {
  echo -e "\n==> $*"
  "$@"
}

if [[ -z "$matrix_json" ]]; then
  echo "versions.matrix.json is empty" >&2
  exit 1
fi

python3 <<'PY'
import json, subprocess, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parent
matrix = json.loads(pathlib.Path('versions.matrix.json').read_text())
cmds = []
for loader, entries in matrix.items():
    project = f":loader-{loader}:build"
    for entry in entries:
        if isinstance(entry, str):
            mc = entry
            props = {}
        elif isinstance(entry, dict):
            mc = entry.get('mc') or entry.get('mcVersion')
            if not mc:
                continue
            props = entry.get('properties') or {}
            if entry.get('enabled', True) is False:
                continue
        else:
            continue
        args = [str(ROOT / 'gradlew'), project, f"-PmcVersion={mc}"]
        for key, value in props.items():
            args.append(f"-P{key}={value}")
        cmds.append(args)
for cmd in cmds:
    print("\n==>", " ".join(cmd))
    subprocess.run(cmd, check=True, cwd=ROOT)
PY
