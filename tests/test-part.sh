#!/bin/sh
# Unit test for scripts/write-part.sh on a fake part drawer.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
D="$T/Games/DuneDynasty"; mkdir -p "$D/data" "$D/music/d2tm_adlib"
for f in DuneDynasty DuneDynasty.info ReadMe dunedynasty.cfg-sample data/FILELIST.TXT music/d2tm_adlib/x.ini; do : > "$D/$f"; done
sh "$HERE/scripts/write-part.sh" "$T" 1.6.4
fail() { echo "FAIL: $*"; cat "$T/Part"; exit 1; }
[ "$(sed -n 1p "$T/Part")" = "part DuneDynasty 1.6.4" ] || fail header
grep -qx 'needs 68040' "$T/Part" || fail needs
grep -qx 'copy "Games/DuneDynasty/DuneDynasty" "SYS:Games/DuneDynasty/DuneDynasty"' "$T/Part" || fail program
grep -qx 'default "Games/DuneDynasty/DuneDynasty.info" "SYS:Games/DuneDynasty/DuneDynasty.info"' "$T/Part" || fail icon
grep -qx 'default "Games/DuneDynasty/dunedynasty.cfg-sample" "SYS:Games/DuneDynasty/dunedynasty.cfg-sample"' "$T/Part" || fail cfg
grep -qx 'copy "Games/DuneDynasty/data/FILELIST.TXT" "SYS:Games/DuneDynasty/data/FILELIST.TXT"' "$T/Part" || fail data
[ "$(grep -c '^copy\|^default' "$T/Part")" = 6 ] || fail count
echo "test-part: pass"
