#!/usr/bin/env bash
# update-readme-badges.sh
set -e

README="README.md"
START_MARKER='<!-- build_test.start -->'
END_MARKER='<!-- build_test.end -->'

# Die Matrix-Versionen als Argument oder aus Datei
if [ -n "$1" ]; then
  VERSIONS=$(echo "$1" | jq -r '.[]')
else
  echo "Usage: $0 '[\"1.16\",\"1.17\"]'"
  exit 1
fi

BADGES="| Minecraft Version | Status |\n|-------------------|--------|\n"
for v in $VERSIONS; do
  BADGES+="| $v | ![Test $v](https://github.com/uebliche/mod-template/actions/workflows/test-matrix.yml/badge.svg?branch=main&event=push&label=$v) |\n"
done

# README ersetzen
awk -v badges="$BADGES" -v start="$START_MARKER" -v end="$END_MARKER" '
  BEGIN {inblock=0}
  {if ($0 ~ start) {print; print badges; inblock=1; next}}
  {if ($0 ~ end) {inblock=0}}
  {if (!inblock) print}
' "$README" > "$README.tmp" && mv "$README.tmp" "$README"

