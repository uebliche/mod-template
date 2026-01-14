#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

ORIG_PATH="$PATH"

# Map Windows Java installations into WSL paths (always run Gradle with Java 21 runtime)
JAVA_21="$(wslpath -u 'C:\Program Files\Java\jdk-21')"
select_java_home() {
  echo "$JAVA_21"
}

readarray -t ENTRIES < <(python3 - <<'PY'
import json
import pathlib
import re

root = pathlib.Path('.')
mcmeta_path = (root / "../../web/mcmeta/loom-index.json").resolve()
if not mcmeta_path.exists():
    raise SystemExit(f"mcmeta file '{mcmeta_path}' missing")

def normalize_version(value: str):
    parts = re.split(r"[.]", str(value))
    nums = []
    for part in parts:
        match = re.match(r"(\d+)", part)
        nums.append(int(match.group(1)) if match else 0)
    while len(nums) < 3:
        nums.append(0)
    return tuple(nums[:3])

def is_release_version(value: str) -> bool:
    return bool(re.match(r"^\\d+(\\.\\d+)*$", value))

def read_build_from():
    gradle_path = root / "gradle.properties"
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
    for p in root.iterdir()
    if p.is_dir() and p.name.startswith("loader-")
)

if not loaders:
    raise SystemExit("No loaders found in loader-* directories")

for loader in loaders:
    for mc in versions:
        print("|".join([loader, mc, ""]))
PY
)

if ((${#ENTRIES[@]} == 0)); then
  echo "No loader entries found via mcmeta" >&2
  exit 1
fi

SUMMARY=()
overall_exit=0

for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r loader mc _ <<<"$entry"
  cmd=("./gradlew" ":loader-${loader}:build" "-PmcVersion=${mc}")
  java_home="$(select_java_home "$mc")"
  if [[ ! -d "$java_home" ]]; then
    echo "Java home not found for $mc at $java_home" >&2
    summary="java-missing"
    SUMMARY+=("$loader|$mc|$summary")
    overall_exit=1
    continue
    SUMMARY+=("$loader|$mc|java-missing|$java_home")
    overall_exit=1
    continue
  fi
  echo -e "\n==> ${cmd[*]} (JAVA_HOME=$java_home)"
  if JAVA_HOME="$java_home" PATH="$java_home/bin:$ORIG_PATH" "${cmd[@]}"; then
    status="success"
  else
    status="failure"
    overall_exit=1
  fi
  SUMMARY+=("$loader|$mc|$status|$java_home")
done

echo -e "\nBuild versions:"
printf "%-10s %-10s %-12s %s\n" "Loader" "MC" "Status" "JAVA_HOME"
printf "%-10s %-10s %-12s %s\n" "------" "--------" "------------" "-----------------------------"
for row in "${SUMMARY[@]}"; do
  IFS='|' read -r loader mc status java_home <<<"$row"
  printf "%-10s %-10s %-12s %s\n" "$loader" "$mc" "$status" "$java_home"
done

exit $overall_exit
