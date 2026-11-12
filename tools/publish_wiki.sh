#!/bin/sh
set -eu

REPO_URL="https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition.wiki.git"
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/wiki-source"
TEMP_ROOT="$(mktemp -d)"
WIKI_DIR="$TEMP_ROOT/wiki"

cleanup() { rm -rf "$TEMP_ROOT"; }
trap cleanup EXIT HUP INT TERM

if ! git clone "$REPO_URL" "$WIKI_DIR"; then
    cat >&2 <<'MSG'
The GitHub Wiki repository is not available yet.

GitHub creates the special .wiki.git repository after its first page is
saved. Open the project Wiki, create a page titled "Home", paste
wiki-source/Home.md, save it, then rerun this script.
MSG
    exit 2
fi

for page in "$SOURCE_DIR"/*.md; do
    [ -f "$page" ] || continue
    [ "$(basename "$page")" = "README.md" ] && continue
    cp "$page" "$WIKI_DIR/"
done

cd "$WIKI_DIR"
git add -- *.md
if git diff --cached --quiet; then
    echo "Wiki is already up to date."
    exit 0
fi

git -c user.name="TwinsanityEvolved Wiki Publisher" \
    -c user.email="twinsanity-wiki@users.noreply.github.com" \
    commit -m "docs: publish practical TwinsanityEvolved Wiki"
git push origin HEAD
echo "TwinsanityEvolved Wiki pages published."
