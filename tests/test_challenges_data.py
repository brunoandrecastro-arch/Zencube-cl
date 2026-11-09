#!/usr/bin/env python3
"""Check shipped puzzles against the current game's exported 108 winning lines.
Also exhaustively verify every immediate reply to each expert's first move.
No external dependencies; executable in Termux and GitHub Actions.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
pack = json.loads((root / 'challenges/challenges.json').read_text())
original = json.loads((root / 'reports/lines.json').read_text())
assert pack['format'] == 'zencube-challenges-v1'
assert len(pack['lines']) == len(original) == 108
assert {frozenset(l) for l in pack['lines']} == {frozenset(l) for l in original}
assert len(pack['challenges']) == 30
assert [p['kind'] for p in pack['challenges']] == ['win'] * 10 + ['block'] * 10 + ['fork'] * 10

masks = [sum(1 << c for c in line) for line in original]
ALL = (1 << 54) - 1

def mask(a):
    return sum(1 << c for c in a)

def victory(m):
    return any((m & line) == line for line in masks)

def wins(own, opponent):
    available = ALL ^ (own | opponent)
    return {c for c in range(54) if (available >> c) & 1 and victory(own | 1 << c)}

for i, p in enumerate(pack['challenges']):
    x, o = mask(p['x']), mask(p['o'])
    assert not (x & o), i
    assert x.bit_count() == o.bit_count(), i
    assert not victory(x) and not victory(o), i
    assert len(p['solutions']) >= 1
    if p['kind'] == 'win':
        assert set(p['solutions']) == wins(x, o), i
    elif p['kind'] == 'block':
        assert wins(x, o) == set(), i
        assert set(p['solutions']) == wins(o, x), i
        for c in p['solutions']:
            assert not wins(o, x | 1 << c), i
    else:
        assert not wins(x, o) and not wins(o, x), i
        for s in p['solutions']:
            xx = x | 1 << s
            assert not victory(xx), i
            for reply in range(54):
                if ((xx | o) >> reply) & 1:
                    continue
                oo = o | 1 << reply
                assert not victory(oo), (i, s, reply)
                assert wins(xx, oo), (i, s, reply)
print('OK: 108 identical lines, 30 challenges, every response to each expert first move checked')
