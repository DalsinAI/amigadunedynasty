#!/usr/bin/env python3
"""amiga/sources.txt is Dune Dynasty's cmake/FileList.cmake for our options
(no Win32/macOS/ALSA MIDI, no ENet, no FluidSynth, no MAD, AUD on), and every
file in it exists. Needs DD_SRC=<dune dynasty checkout at dd.lock's commit>."""
import os, re, sys
here = os.path.dirname(os.path.abspath(__file__))
src = os.environ.get('DD_SRC')
ours = open(os.path.join(here, '..', 'amiga', 'sources.txt')).read().split()
assert len(ours) == len(set(ours)), 'duplicate sources'
assert 'src/audio/midi_none.c' in ours and 'src/net/net_none.c' in ours
for bad in ('midi_alsa', 'midi_win32', 'net_enet', 'allegro_mad', 'allegro_midi', 'errorlog_win32'):
    assert not any(bad in f for f in ours), bad
if src:
    s = open(os.path.join(src, 'cmake', 'FileList.cmake')).read()
    base = re.findall(r'src/\S+\.(?:cpp|c)\b', s.split('if(WIN32)')[0])
    want = base + ['src/audio/midi_none.c', 'src/net/net_none.c', 'src/audio/audlib/audlib_a5.c', 'src/crashlog/errorlog_std.c']
    assert ours == want, sorted(set(ours) ^ set(want))
    for f in ours:
        assert os.path.isfile(os.path.join(src, f)), f
    print('test_sources: pass (against %s)' % src)
else:
    print('test_sources: pass (list only; set DD_SRC to check against upstream)')
