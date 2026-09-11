#!/usr/bin/env bash
# Appends a marker to every go.sum so it is obvious whether the committed
# branch contains what this script wrote.
set -euo pipefail

for sum in lib/go.sum app/go.sum; do
  echo "// renovate-post-upgrade-marker" >>"$sum"
  echo "wrote marker to $sum"
done
