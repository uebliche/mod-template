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
import json, pathlib
matrix = json.loads(pathlib.Path('versions.matrix.json').read_text())
for loader, entries in matrix.items():
    for entry in entries:
        if isinstance(entry, str):
            mc = entry
            props = {}
        elif isinstance(entry, dict):
            mc = entry.get('mc') or entry.get('mcVersion')
            if not mc or entry.get('enabled', True) is False:
                continue
            props = entry.get('properties') or {}
        else:
            continue
        args = ' '.join(f"-P{k}={v}" for k, v in props.items())
        print('|'.join([loader, mc, args]))
PY
)

if ((${#ENTRIES[@]} == 0)); then
  echo "No loader entries found in versions.matrix.json" >&2
  exit 1
fi

SUMMARY=()
overall_exit=0

for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r loader mc args <<<"$entry"
  cmd=("./gradlew" ":loader-${loader}:build" "-PmcVersion=${mc}")
  if [[ -n "$args" ]]; then
    for extra in $args; do
      cmd+=("$extra")
    done
  fi
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

echo -e "\nBuild matrix:"
printf "%-10s %-10s %-12s %s\n" "Loader" "MC" "Status" "JAVA_HOME"
printf "%-10s %-10s %-12s %s\n" "------" "--------" "------------" "-----------------------------"
for row in "${SUMMARY[@]}"; do
  IFS='|' read -r loader mc status java_home <<<"$row"
  printf "%-10s %-10s %-12s %s\n" "$loader" "$mc" "$status" "$java_home"
done

exit $overall_exit
