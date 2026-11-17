#!/bin/sh
# dd.lock pins full commits; $VER and buildcfg.h carry the locked version;
# every patch applies to Dune Dynasty at its commit (DD_SRC=<checkout>).
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$HERE/dd.lock"
for c in "$DD_COMMIT" "$ALLEGRO_COMMIT"; do echo "$c" | grep -Eqx '[0-9a-f]{40}' || { echo "FAIL commit $c"; exit 1; }; done
grep -q "DuneDynasty $DD_VERSION " "$HERE/amiga/amiga_start.c" || { echo "FAIL \$VER"; exit 1; }
grep -q "\"$DD_VERSION\"" "$HERE/amiga/buildcfg.h" || { echo "FAIL buildcfg version"; exit 1; }
if [ -n "${DD_SRC:-}" ]; then
    T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
    cp -R "$DD_SRC/." "$T/"
    for p in "$HERE"/patches/*.patch; do [ -f "$p" ] || continue; patch -s -d "$T" -p1 < "$p" || { echo "FAIL $p"; exit 1; }; done
fi
echo "test_lock: pass"
