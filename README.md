# Dune Dynasty for GFOS

Dune Dynasty 1.6.4 (an enhanced Dune II engine, from OpenDUNE) built for GFOS
(AmigaOS 3.2.3 with GFOpenUp) on a 68040, on amigaallegro: Allegro 5 drawing
through SDL2.module, GL.module and OpenGPU.

## Your Dune II data

Dune II itself is not included. Copy the data files of your own Dune II 1.07
(EU or US) to `SYS:Games/DuneDynasty/data/`; `data/FILELIST.TXT` lists them.
Without them the game stops at start and says where it looked.

## Install

    1> GFOpenUpTool INSTALL Parts/DuneDynasty

installs `SYS:Games/DuneDynasty/` (the game, its campaigns, music sets and
graphics, a sample `dunedynasty.cfg`, licences). Needs a 68040 or 68060.

Music is the built-in AdLib (OPL) player and Dune 2000 AUD files; MIDI
synths, MP3, FLAC/Ogg and network play are not built in yet.

## Build

    STOVE=~/AmiCradle/stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh

`dd.lock` pins Dune Dynasty and amigaallegro by commit; nothing third-party
is kept in this repository. Allegro is built once per commit and kept; a run
that runs out of the stove's time says so, and the next run goes on.

## Tests

    DD_SRC=<dune dynasty checkout> sh tests/test_host.sh

## Licence

GPL-2.0-or-later, like Dune Dynasty (see LICENSE). Port: Copyright (c) 2026
AmiCradle Team.

Designed, tested and delivered by The AmiCradle Team.
