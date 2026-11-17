#!/bin/sh
# Compiles every source of amiga/sources.txt with the host compiler
# (-fsyntax-only, the language and include flags build-amiga.sh uses)
# against the host's Allegro 5 headers, so a shadowed system header or a
# language-level break shows before a stove run. Skips without host Allegro 5.
#   DD_SRC=<checkout of Dune Dynasty> sh tests/host_syntax.sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
[ -n "${DD_SRC:-}" ] || { echo "host_syntax: skip (no DD_SRC)"; exit 0; }
[ -f /usr/include/allegro5/allegro.h ] || { echo "host_syntax: skip (no host Allegro 5)"; exit 0; }
# the include flags must not put src/ on the path: src/string.h would hide <string.h>
if grep -q -- '-I\$SRC/src' "$HERE/build-amiga.sh"; then echo "FAIL build-amiga.sh puts src/ on the include path"; exit 1; fi
cd "$DD_SRC"; E=$(mktemp); trap 'rm -f "$E"' EXIT; fails=0
while read -r f; do
    case "$f" in
        *.cpp) g++ -std=gnu++11 -fsyntax-only -D_DEFAULT_SOURCE -D__amigaos__ -I"$HERE/amiga" -Iinclude "$f" ;;
        *) gcc -std=gnu99 -fsyntax-only -fno-delete-null-pointer-checks -D_DEFAULT_SOURCE -D__amigaos__ -I"$HERE/amiga" -Iinclude "$f" ;;
    esac 2> "$E" || { fails=$((fails + 1)); echo "FAIL $f"; grep -m3 error "$E"; }
done < "$HERE/amiga/sources.txt"
[ $fails -eq 0 ] || { echo "host_syntax: $fails failed"; exit 1; }
echo "host_syntax: pass ($(wc -l < "$HERE/amiga/sources.txt") sources)"
