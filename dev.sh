#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

python3 - "$@" <<'PY'
import json
import os
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parent
matrix_path = root / "versions.matrix.json"
if not matrix_path.exists():
    sys.exit(f"Matrix file '{matrix_path}' missing")

matrix = json.loads(matrix_path.read_text())
loaders = sorted(matrix.keys())

if not loaders:
    sys.exit("No loaders found in versions.matrix.json")

loader_map = {name.lower(): name for name in loaders}

def normalize_version(value: str):
    parts = re.split(r"[.]", str(value))
    nums = []
    for part in parts:
        match = re.match(r"(\d+)", part)
        nums.append(int(match.group(1)) if match else 0)
    while len(nums) < 3:
        nums.append(0)
    return tuple(nums[:3])

def build_variants(entries):
    variants = []
    for entry in entries:
        if isinstance(entry, str):
            mc = entry
            props = {}
        elif isinstance(entry, dict):
            mc = entry.get("mc") or entry.get("mcVersion")
            if not mc:
                continue
            if entry.get("enabled") is False:
                continue
            props = entry.get("properties") or {}
        else:
            continue
        args = []
        if isinstance(props, dict):
            for key, value in props.items():
                args.append(f"-P{key}={value}")
        label = mc
        if args:
            label = f"{mc} [{' '.join(args)}]"
        variants.append({"mc": mc, "args": args, "label": label})
    variants.sort(key=lambda v: normalize_version(v["mc"]), reverse=True)
    return variants

def read_choice(prompt, options, display_map=None, default=None):
    input_stream = sys.stdin if sys.stdin.isatty() else None
    if input_stream is None:
        try:
            input_stream = open("/dev/tty")
        except Exception:
            input_stream = None
    if input_stream is None:
        return default if default else options[0]
    while True:
        for idx, opt in enumerate(options):
            label = display_map.get(opt, opt) if display_map else opt
            print(f"[{idx}] {label}")
        default_hint = f" (Enter={default})" if default else ""
        try:
            print(f"{prompt} [0-{len(options)-1} oder Name]{default_hint}: ", end="", flush=True)
            raw = input_stream.readline()
            if raw is None:
                return default if default else options[0]
            raw = raw.strip()
        except EOFError:
            return default if default else options[0]
        if not raw and default:
            return default
        if raw.isdigit():
            num = int(raw)
            if 0 <= num < len(options):
                return options[num]
        if raw in options:
            return raw
        print("Ungueltige Auswahl, bitte erneut versuchen.")

loader = sys.argv[1].strip() if len(sys.argv) > 1 else ""
version = sys.argv[2].strip() if len(sys.argv) > 2 else ""
mode = sys.argv[3].strip() if len(sys.argv) > 3 else ""
if loader:
    loader = loader_map.get(loader.lower(), loader)

loader_display = {}
for name in loaders:
    count = len(build_variants(matrix.get(name, [])))
    loader_display[name] = f"{name} ({count} version(s))"

if not loader or loader not in loaders:
    loader = read_choice("Pick loader", loaders, loader_display, loaders[0])

variants = build_variants(matrix.get(loader, []))
if not variants:
    sys.exit(f"No versions found for loader '{loader}'.")

version_labels = {v["mc"]: v["label"] for v in variants}
default_version = variants[0]["mc"]

if not version:
    print(f"Auto-selecting latest version: {default_version}")
    version = default_version
elif version not in version_labels:
    version = read_choice(
        f"Pick version for {loader}",
        [v["mc"] for v in variants],
        version_labels,
        default_version,
    )

selected = next((v for v in variants if v["mc"] == version), None)
if not selected:
    sys.exit(f"Version '{version}' not found for loader '{loader}'.")

mode_options_by_loader = {
    "fabric": ["client", "server", "build"],
    "forge": ["client", "server", "build"],
    "paper": ["server", "build"],
    "velocity": ["server", "build"],
}
default_modes = {
    "fabric": "client",
    "forge": "client",
    "paper": "server",
    "velocity": "server",
}
if mode:
    mode = mode.lower()
mode_options = mode_options_by_loader.get(loader, ["build"])
if mode and mode not in mode_options:
    sys.exit(f"Unknown mode '{mode}'. Expected one of: {', '.join(mode_options)}")
if not mode:
    mode = read_choice("Pick mode", mode_options, default=default_modes.get(loader, mode_options[0]))

def resolve_task(selected_loader, selected_mode):
    if selected_mode == "build":
        return "build"
    if selected_loader in ("fabric", "forge"):
        return "runClient" if selected_mode == "client" else "runServer"
    if selected_loader == "paper":
        return "runServer"
    if selected_loader == "velocity":
        return "runServer"
    return "build"

task = resolve_task(loader, mode)

cmd = [
    str(root / "gradlew"),
    f":loader-{loader}:{task}",
    f"-PmcVersion={version}",
    f"-PonlyLoader={loader}",
] + selected["args"]
print("")
print("==> " + " ".join(cmd))

env = os.environ.copy()

def java_major(home):
    try:
        version_out = subprocess.check_output(
            [str(pathlib.Path(home) / "bin" / "java"), "-version"],
            stderr=subprocess.STDOUT,
        ).decode(errors="ignore")
    except Exception:
        return None
    for line in version_out.splitlines():
        if "version" in line:
            digits = re.findall(r"(\d+)", line)
            if digits:
                return int(digits[0])
    return None

def resolve_java_home():
    env_home = env.get("JAVA_HOME")
    if env_home and pathlib.Path(env_home).exists():
        if java_major(env_home) == 21:
            return env_home
    if sys.platform == "darwin":
        try:
            out = subprocess.check_output(
                ["/usr/libexec/java_home", "-v", "21"],
                stderr=subprocess.DEVNULL,
            ).decode().strip()
            if out and pathlib.Path(out).exists() and java_major(out) == 21:
                return out
        except Exception:
            pass
    candidates = [
        "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home",
        "/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home",
        "/usr/lib/jvm/temurin-21",
        "/usr/lib/jvm/java-21-openjdk",
        "/usr/lib/jvm/jdk-21",
    ]
    for candidate in candidates:
        if pathlib.Path(candidate).exists() and java_major(candidate) == 21:
            return candidate
    return None

java_home = resolve_java_home()
if not java_home:
    print("Fehler: Kein Java 21 gefunden. Dieses Template benoetigt JDK 21 zum Builden.")
    if sys.platform == "darwin":
        print("macOS: brew install --cask temurin@21")
        print("danach: export JAVA_HOME=$(/usr/libexec/java_home -v 21)")
    else:
        print("Bitte JDK 21 installieren und JAVA_HOME setzen.")
    sys.exit(1)

env["JAVA_HOME"] = java_home
env["ORG_GRADLE_JAVA_HOME"] = java_home
env["PATH"] = f"{java_home}/bin:" + env.get("PATH", "")
print(f"Nutze JAVA_HOME={java_home}")
try:
    major = java_major(java_home)
    if major:
        env["GRADLE_USER_HOME"] = str(root / f".gradle-java{major}")
except Exception:
    pass

result = subprocess.run(cmd, cwd=root, env=env)
if result.returncode != 0:
    print("")
    print("Build fehlgeschlagen.")
    print("Wenn du 'Unsupported class file major version 69' siehst,")
    print("loesche den Gradle-Cache fuer dieses Projekt (z.B. '.gradle' / '.gradle-java21') oder")
    print("nutze ein frisches GRADLE_USER_HOME.")
    sys.exit(result.returncode)
PY
