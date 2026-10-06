#!/usr/bin/env bash
# Everything a change should pass: parse check, unit tests, input scenarios.
set -e
cd "$(dirname "$0")/.."
tools/check.sh
tools/test.sh
for s in drag travel loop; do
  tools/scenario.sh "$s"
done
