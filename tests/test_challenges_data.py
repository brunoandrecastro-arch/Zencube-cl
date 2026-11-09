#!/usr/bin/env python3
"""Independent tactical assertions for ZenCube's 100 offline puzzles.
The generator's paths are NOT trusted: recompute forced threats from 108 lines.
"""
import json
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
p = json.loads((ROOT/'challenges/challenges.json').read_text())
lines = json.loads((ROOT/'reports/lines.json').read_text())
assert p['format']=='zencube-challenges-v2'
assert len(lines)==len(p['lines'])==108
assert {frozenset(l) for l in lines}=={frozenset(l) for l in p['lines']}
assert len(p['challenges'])==100
assert len(p['levels'])==5
for level in range(1,6):
    assert sum(c['level']==level for c in p['challenges'])==20
MASKS = tuple(sum(1<<c for c in l) for l in lines)
ALL = (1<<54)-1

def occupied(cells):return sum(1<<c for c in cells)
def bits(mask):
    while mask:
        b=mask&-mask
        yield b
        mask-=b
@lru_cache(maxsize=350000)
def immediate(x,o):
    result=0
    for lm in MASKS:
        if not (lm&o) and (lm&x).bit_count()==3:
            result |= lm & ~(x|o)
    return result

def force(x,o,depth):
    # Proof only by consecutive forcing threats. Opponent must block each threat
    # or loses immediately; any immediate opponent win invalidates the line.
    if immediate(x,o): return depth==1
    if depth==1:return False
    opponent=immediate(o,x)
    if opponent.bit_count()>1:return False
    options=opponent if opponent else ALL&~(x|o)
    for m in bits(options):
        xx=x|m
        if immediate(o,xx):continue
        threats=immediate(xx,o)
        if threats.bit_count()>=2 and depth==2:return True
        if threats.bit_count()==1 and force(xx,o|threats,depth-1):return True
    return False

def proven_first(x,o,depth):
    opponent=immediate(o,x)
    if opponent.bit_count()>1:return []
    options=opponent if opponent else ALL&~(x|o)
    answers=[]
    for m in bits(options):
        if depth==1:
            if any((lm&(x|m))==lm for lm in MASKS):answers.append(m.bit_length()-1)
            continue
        xx=x|m
        if immediate(o,xx):continue
        tw=immediate(xx,o)
        if tw.bit_count()>=2 and depth==2:
            answers.append(m.bit_length()-1)
        elif tw.bit_count()==1 and force(xx,o|tw,depth-1):
            answers.append(m.bit_length()-1)
    return answers

for i,c in enumerate(p['challenges']):
    assert c['id']==i+1
    x,o=occupied(c['x']),occupied(c['o'])
    assert x&o==0 and x.bit_count()==o.bit_count()
    assert not any((lm&x)==lm or (lm&o)==lm for lm in MASKS),c['id']
    solutions=set(c['solutions'])
    assert solutions and all(0<=k<54 and (x|o)&(1<<k)==0 for k in solutions)
    if c['level']==1:
        if c['kind']=='win':
            assert solutions == {b.bit_length()-1 for b in bits(immediate(x,o))}
        else:
            assert c['kind']=='block'
            assert solutions == {b.bit_length()-1 for b in bits(immediate(o,x))}
            assert not immediate(x,o)
    elif c['level']<=4:
        assert c['kind'] in ['fork','sequence']
        assert not immediate(x,o) and not immediate(o,x)
        expected=proven_first(x,o,c['level'])
        if c['id']<=30: assert solutions.issubset(set(expected)) # Legacy fork puzzles
        else: assert list(solutions)==expected and len(expected)==1
        if c['level']>=3:
            assert not force(x,o,c['level']-1)
        if 'path' in c:
            path=c['path']
            assert len(path)==2*(c['level']-1)
            xx,oo=x,o
            for turn in range(c['level']-1):
                next_move=int(path[2*turn]);assert (xx|oo)&(1<<next_move)==0
                xx|=1<<next_move
                assert not immediate(oo,xx)
                blocking=immediate(xx,oo)
                if turn==c['level']-2:
                    assert isinstance(path[2*turn+1],dict)
                    assert blocking.bit_count()>=2
                    for bot_move in bits(blocking):
                        assert immediate(xx,oo|bot_move),c['id']
                else:
                    bot_move=int(path[2*turn+1]);assert blocking==1<<bot_move
                    oo|=1<<bot_move
    else:
        assert c['kind']=='defense' and len(solutions)==1
        assert not immediate(x,o) and not immediate(o,x)
        safe=[]
        for response in bits(ALL&~(x|o)):
            if not force(o,x|response,2):
                safe.append(response.bit_length()-1)
        assert safe==list(solutions),c['id']
print('OK: 100 puzzles in five groups of 20; forcing threat sequences and 20 unique defenses verified')
