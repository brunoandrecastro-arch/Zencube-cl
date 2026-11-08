"""Independent ZenCube Zen Garden rules reference (4 in a row across 2 faces).

Face order Front, Back, Left, Right, Top, Bottom; 54 separate cells.
Each of 12 physical edges has 3 parallel lanes; each lane has 3 possible
length-four windows spanning the edge: 3+1, 2+2, 1+3.
"""
from collections import Counter
from itertools import combinations, permutations, product
import random

FACES = [
    ('Front', (0, 0, 1), (1, 0, 0), (0, -1, 0)),
    ('Back', (0, 0, -1), (-1, 0, 0), (0, -1, 0)),
    ('Left', (-1, 0, 0), (0, 0, 1), (0, -1, 0)),
    ('Right', (1, 0, 0), (0, 0, -1), (0, -1, 0)),
    ('Top', (0, 1, 0), (1, 0, 0), (0, 0, 1)),
    ('Bottom', (0, -1, 0), (1, 0, 0), (0, 0, -1)),
]

def dot(a,b): return sum(x*y for x,y in zip(a,b))
def negate(a): return tuple(-x for x in a)
def cross(a,b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def side_normal(f,side):
    n,u,v= f[1:]
    return {'left':negate(u),'right':u,'top':negate(v),'bottom':v}[side]
def side_match(face,normal):
    sides = [s for s in ('left','right','top','bottom') if side_normal(face,s)==normal]
    assert len(sides)==1
    return sides[0]
def tangent(f,side): return f[3] if side in ('left','right') else f[2]
def cell(f,side,k,depth=0):
    assert depth in (0,1,2)
    v = depth if side in ('left','top') else 2-depth
    row,col= (k,v) if side in ('left','right') else (v,k)
    return f*9+3*row+col

def generate_lines():
    lines=[]; edges=[]; variants=Counter()
    for i,fa in enumerate(FACES):
        for sa in ('left','right','top','bottom'):
            j = next(idx for idx,fb in enumerate(FACES) if fb[1] == side_normal(fa,sa))
            if i >= j: continue
            fb=FACES[j]; sb=side_match(fb,fa[1]); edges.append((i,j))
            align=dot(tangent(fa,sa),tangent(fb,sb))
            assert align in (-1,1)
            for k in range(3):
                kk = k if align==1 else 2-k
                a2,a1,a0=(cell(i,sa,k,2),cell(i,sa,k,1),cell(i,sa,k))
                b0,b1,b2=(cell(j,sb,kk),cell(j,sb,kk,1),cell(j,sb,kk,2))
                lines.extend([(a2,a1,a0,b0),(a1,a0,b0,b1),(a0,b0,b1,b2)])
                for name in ('3+1','2+2','1+3'): variants[name]+=1
    assert len(edges)==12,edges
    assert len(lines)==108,len(lines)
    assert len(set(tuple(sorted(line)) for line in lines))==108
    assert variants=={'3+1':36,'2+2':36,'1+3':36}
    for line in lines:
        assert len(line)==len(set(line))==4
        fs=Counter(c//9 for c in line)
        assert len(fs)==2 and tuple(sorted(fs.values())) in ((1,3),(2,2))
    return lines

LINES=generate_lines()
LINE_SETS={frozenset(x) for x in LINES}
assert len(LINE_SETS)==108

def winner(b,p): return next((line for line in LINES if all(b[c]==p for c in line)),None)
def threats(b,p):
    return {empty[0] for ln in LINES if (empty:=[x for x in ln if b[x]==0]) and len(empty)==1 and sum(b[x]==p for x in ln)==3}

def center(cellid):
    face=cellid//9; row=(cellid%9)//3;col=cellid%3
    _,n,u,v=FACES[face]
    return tuple(3*n[q]+2*u[q]*(col-1)+2*v[q]*(row-1) for q in range(3))

# Every proper rotation of the cube must preserve the set of winlines.
centers={center(c):c for c in range(54)}
assert len(centers)==54
rots=0
for perm in permutations((0,1,2)):
    sign_perm= (-1 if sum(perm[i]>perm[j] for i in range(3) for j in range(i+1,3))%2 else 1)
    for signs in product((-1,1),repeat=3):
        if sign_perm*signs[0]*signs[1]*signs[2]!=1: continue
        def transform(v): return tuple(v[perm[i]]*signs[i] for i in range(3))
        for ln in LINES:
            mapped=frozenset(centers[transform(center(c))] for c in ln)
            assert mapped in LINE_SETS,(ln,mapped)
        rots+=1
assert rots==24

# Each true line wins for either symbol, and immediate threats point at the fourth cell.
for ln in LINES:
    for player in (1,2):
        b=[0]*54
        for c in ln[:3]: b[c]=player
        assert ln[3] in threats(b,player)
        assert winner(b,player) is None
        b[ln[3]]=player
        assert winner(b,player) is not None

# Negative cases: three on one side, L-shape, across three different faces.
for bad in [(0,1,2),(0,1,3,4),(0,1,2,4),(0,9,18,36),(0,10,19,45)]:
    b=[0]*54
    for c in bad: b[c]=1
    assert winner(b,1) is None,bad

# Four marks cannot win in fewer than seven alternating half-moves.
rng=random.Random(31108)
wins=Counter(); lengths=[]
for _ in range(3000):
    b=[0]*54
    free=list(range(54)); rng.shuffle(free)
    result=0
    for ply,c in enumerate(free,1):
        who = 1 if ply%2 else 2
        b[c] = who
        if (line:=winner(b,who)) is not None:
            assert ply>=7 and ply%2==who%2
            wins[who]+=1
            lengths.append(ply)
            result=who
            break
    if not result:
        wins[0]+=1
        lengths.append(54)

print('OK: 6 faces, 54 distinct cells, 12 edges')
print('OK: 108 unique four-mark cross-face winning lines (36 x 3+1, 36 x 2+2, 36 x 1+3)')
print('OK: rotation invariant under all 24 proper cube rotations')
print('OK: every winning line and its 3-mark threat verified for both symbols')
print('OK: no 3-in-a-row win, invalid multi-face and same-face patterns rejected')
print('OK: 3,000 seeded random matches simulated; no win before ply 7')
print('Random-play illustrative results; NOT proof of mathematical fairness:',dict(wins))
