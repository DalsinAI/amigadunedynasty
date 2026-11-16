#!/bin/sh
# Writes the Part file GFOpenUpTool INSTALL reads (gfopenup src/openuptool.c):
# "copy" for each file under the part drawer, each to SYS:<its path>; the
# config sample and icons as "default", so the player's own stay.
#   write-part.sh <part drawer> <version>
# GPL-2.0-or-later. Copyright (c) 2026 AmiCradle Team.
set -eu
P=$1; V=$2
{
    echo "part DuneDynasty $V"
    echo "; Dune Dynasty: Dune II with a modern interface, on Allegro 5. Copy your own Dune II 1.07 data files to SYS:Games/DuneDynasty/data/"
    echo "needs 68040"
    (cd "$P" && find Games -type f ! -name Part | LC_ALL=C sort) | while read -r f; do
        case "$f" in
            *.info|*/dunedynasty.cfg-sample) echo "default \"$f\" \"SYS:$f\"" ;;
            *) echo "copy \"$f\" \"SYS:$f\"" ;;
        esac
    done
} > "$P/Part"
