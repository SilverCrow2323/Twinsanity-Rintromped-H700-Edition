#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LOCK="$ROOT/upstream.lock"
WORK=${UPSTREAM_WORK:-"$ROOT/work/upstream"}
. "$LOCK"
if [ -d "$WORK/.git" ]; then
  git -C "$WORK" fetch --depth 1 origin "$tag"
else
  mkdir -p "$(dirname "$WORK")"
  git clone --filter=blob:none --no-checkout "$repository" "$WORK"
  git -C "$WORK" fetch --depth 1 origin "$tag"
fi
git -C "$WORK" checkout --detach "$commit"
ACTUAL=$(git -C "$WORK" rev-parse HEAD)
[ "$ACTUAL" = "$commit" ] || { echo "upstream pin mismatch: expected $commit, got $ACTUAL" >&2; exit 1; }
echo "Upstream checked out at $ACTUAL ($tag): $WORK"
