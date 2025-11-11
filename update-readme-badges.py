import os
import sys
import requests
import json
import logging

logging.basicConfig(level=logging.WARNING)
README = "README.md"
START_MARKER = "<!-- build_test.start -->"
END_MARKER = "<!-- build_test.end -->"
REPO = os.environ.get("GITHUB_REPOSITORY")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

missing = []
if not REPO:
    missing.append("GITHUB_REPOSITORY")
if not GITHUB_TOKEN:
    missing.append("GITHUB_TOKEN")
if missing:
    message = f"Missing environment variables: {', '.join(missing)}"
    if os.environ.get("CI"):
        print(message, file=sys.stderr)
    else:
        logging.warning(message)
    sys.exit(1)

if len(sys.argv) < 2:
    print("Usage: update-readme-badges.py '[\"1.16\",\"1.17\"]'")
    sys.exit(1)

versions = json.loads(sys.argv[1])

# Get jobs for the latest run
def get_jobs(run_id):
    url = f"https://api.github.com/repos/{REPO}/actions/runs/{run_id}/jobs"
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}", "Accept": "application/vnd.github+json"}
    r = requests.get(url, headers=headers)
    r.raise_for_status()
    return r.json()["jobs"]

run_id = os.environ.get("GITHUB_RUN_ID")
if not run_id:
    print("GITHUB_RUN_ID not set.")
    sys.exit(1)
jobs = get_jobs(run_id)

# Map version to status
def get_status(version):
    for job in jobs:
        if job["name"].endswith(version):
            return job["conclusion"]
    return "skipped"

BADGES = ""
for v in reversed(versions):
    status = get_status(v)
    color = "brightgreen" if status == "success" else ("red" if status == "failure" else "lightgrey")
    BADGES += f"![Test {v}](https://img.shields.io/badge/{v}-{status}-{color}?style=flat) "

# README ersetzen
with open(README, encoding="utf-8") as f:
    lines = f.readlines()

with open(README + ".tmp", "w", encoding="utf-8") as f:
    inblock = False
    for line in lines:
        if START_MARKER in line:
            f.write(line)
            f.write(BADGES + "\n")
            inblock = True
            continue
        if END_MARKER in line:
            inblock = False
        if not inblock:
            f.write(line)

os.replace(README + ".tmp", README)
