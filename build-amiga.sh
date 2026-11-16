#!/bin/sh
# Builds Dune Dynasty 1.6.4 for GFOS (AmigaOS 3.2.3 with GFOpenUp) with a
# stove, on amigaallegro (Allegro 5 over SDL2.module, GL.module and OpenGPU):
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# Dune Dynasty and amigaallegro are fetched at what dd.lock gives; nothing
# third-party is kept here. Allegro is built once and kept; if a run ends
# out of time it says so, and the next run goes on from there.
# OUT gets Parts/DuneDynasty, a GFOpenUp part:
#   GFOpenUpTool INSTALL Parts/DuneDynasty  -> SYS:Games/DuneDynasty/
# The Dune II 1.07 data files are the player's own: copy them to
# SYS:Games/DuneDynasty/data/ (FILELIST.TXT there lists them).
# GPL-2.0-or-later, like Dune Dynasty. Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/dd.lock"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
WORK="${WORK:-$HOME/.cache/amigadunedynasty/build}"; OUT="${OUT:-$WORK/out}"
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 4)}; export JOBS
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)
m68k-amigaos-gcc --version | head -n 1

# --- amigaallegro (kept between runs) --------------------------------------------
set +e
ALLEGRO_BUDGET=$(( ${BUDGET_TOTAL:-840} - 60 )) sh "$HERE/scripts/build-allegro.sh" "$STOVE" "$WORK" "$ALLEGRO_GIT" "$ALLEGRO_COMMIT" > "$WORK/allegro.out"
rc=$?
PFX=$(tail -n 1 "$WORK/allegro.out")
set -e
[ $rc -eq 3 ] && { echo "out of time in allegro, run again to go on"; exit 0; }
[ $rc -eq 0 ] || exit $rc
echo "allegro: $PFX ($(( $(date +%s) - t0 )) s)"

# --- Dune Dynasty at its pinned commit, with patches/ -------------------------------
SRC="$WORK/dunedynasty"
PSUM=$(cat "$HERE"/patches/*.patch 2>/dev/null | sha256sum | cut -c1-16)
if [ "$(cat "$SRC/.patched" 2>/dev/null)" != "$DD_COMMIT-$PSUM" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"; git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$DD_GIT" "$DD_COMMIT"; git -C "$SRC" checkout -q FETCH_HEAD
    for p in "$HERE"/patches/*.patch; do
        [ -f "$p" ] || continue
        patch -s -d "$SRC" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
    done
    echo "$DD_COMMIT-$PSUM" > "$SRC/.patched"
    rm -rf "$WORK/obj"
fi

# --- compile (as Dune Dynasty's CMake: C99, its own include/, our buildcfg.h) ------
SYSROOT="$TC/m68k-amigaos"
ARCH="-mcrt=nix20 -m68040 -m68881 -pthread"
CF="$ARCH -O2 -fomit-frame-pointer -fno-delete-null-pointer-checks -D_DEFAULT_SOURCE -DALLEGRO_STATICLINK=1 -D__AMIGAOS3__=1 -I$HERE/amiga -I$SRC/include -I$SRC/src -I$PFX/include -I$SYSROOT/include"
O="$WORK/obj"; mkdir -p "$O"
export CF O SRC
set +e
left=$(( ${BUDGET_TOTAL:-840} - ($(date +%s) - t0) ))
[ "$left" -gt 30 ] || { echo "out of time after allegro, run again to go on"; exit 0; }
timeout "$left" xargs -P "$JOBS" -I{} sh -c '
    f=$SRC/{}; o=$O/$(echo "{}" | tr "/" "_").o
    [ -f "$o" ] && [ "$o" -nt "$f" ] && exit 0
    case "$f" in *.cpp) c="m68k-amigaos-g++ -std=gnu++11" ;; *) c="m68k-amigaos-gcc -std=gnu99" ;; esac
    nice -n 19 $c $CF -c "$f" -o "$o.tmp" > "$o.log" 2>&1 && mv "$o.tmp" "$o" && rm -f "$o.log"
' < "$HERE/amiga/sources.txt"
rc=$?
set -e
n=$(wc -l < "$HERE/amiga/sources.txt"); have=$(find "$O" -name '*.o' | wc -l)
echo "compile: $have of $n objects, $(( $(date +%s) - t0 )) s"
fails=$(find "$O" -name '*.o.log' | LC_ALL=C sort)
if [ -n "$fails" ]; then
    for l in $fails; do grep -q 'error' "$l" || continue; echo "== $(basename "$l" .o.log)"; grep -m 8 'error' "$l"; done
    grep -l 'error' $fails >/dev/null 2>&1 && exit 1
fi
[ "$have" -eq "$n" ] || { echo "out of time while compiling, run again to go on"; exit 0; }
m68k-amigaos-gcc $CF -c "$HERE/amiga/amiga_start.c" -o "$WORK/amiga_start.o"

# --- link -----------------------------------------------------------------------------
DEPS="$SYSROOT/port-deps"
m68k-amigaos-g++ $ARCH -o "$WORK/DuneDynasty.debug" "$O"/*.o "$WORK/amiga_start.o" \
    "$PFX/lib/liballegro_monolith-static.a" "$SYSROOT/lib/libSDL2.a" "$SYSROOT/lib/libGL.a" \
    "$DEPS/lib/libpng.a" "$DEPS/lib/libz.a" -lm -lpthread

# --- the GFOpenUp part: Parts/DuneDynasty -----------------------------------------------
P="$OUT/Parts/DuneDynasty"; D="$P/Games/DuneDynasty"; rm -rf "$P"; mkdir -p "$D"
m68k-amigaos-strip -o "$D/DuneDynasty" "$WORK/DuneDynasty.debug"
for d in campaign data gfx music; do cp -R "$SRC/static/general/$d" "$D/"; done
cp "$SRC/static/general/dunedynasty.cfg-sample" "$D/"
cp "$SRC/LICENSE.txt" "$D/License.txt"; cp "$SRC/README.txt" "$D/ReadMe-DuneDynasty.txt"
cp "$SRC/enhancement.txt" "$D/"; cp -R "$SRC/licences" "$D/"
cp "$HERE/README.md" "$D/ReadMe"
cp "$HERE/amiga/icons/DuneDynasty.info" "$HERE/amiga/icons/ReadMe.info" "$D/"
cp "$HERE/amiga/icons/DuneDynasty-drawer.info" "$P/Games/DuneDynasty.info"
sh "$HERE/scripts/write-part.sh" "$P" "$DD_VERSION"
ls -l "$D/DuneDynasty"
strings "$D/DuneDynasty" | grep -q 'DuneDynasty 1.6.4 (16.11.2026) GFOS' || { echo "no \$VER"; exit 1; }
echo "part: $(grep -c '^copy\|^default' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "total: $(( $(date +%s) - t0 )) s"
