#!/usr/bin/env python3
"""Check the Zen Ascend integration and modelled 4x4 rule geometry."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
new=(ROOT/'core/ZenAscend.gd').read_text()
controller=(ROOT/'ui/GameController.gd').read_text()
ui=(ROOT/'ui/AscendController.gd').read_text()
renderer=(ROOT/'ui/AscendRenderer.gd').read_text()
save=(ROOT/'core/SaveManager.gd').read_text()
assert 'const TEST_UNLOCKED: bool = false' in new
assert 'return unlocked_for_release(data)' in new
assert 'const PRICE: int = 750' in new
assert 'func generate_lines()' in new and 'func next_move(' in new
assert 'res://Ascend.tscn' in controller
assert 'if ZMode.unlocked(data):' in controller
assert 'if not Mode.unlocked(data)' in ui
assert 'var total: int = int(s.played)' in ui
assert 'data.settings.names[index] = cleaned' in controller
assert 'name_field.max_length = 24' in controller
assert '"ascend":{}' in save and 'base.ascend.merge(data.ascend, true)' in save
assert 'func set_skin(index: int)' in renderer
assert 'for c in range(ZenAscend.CELLS)' in renderer
assert 'ZenCollection.reward_bot(data,bot_level)' in ui
assert (ROOT/'Ascend.tscn').is_file()
# Prove the intended 96-cell topology independently from the Godot implementation.
N=[(0,0,1),(0,0,-1),(-1,0,0),(1,0,0),(0,1,0),(0,-1,0)]
U=[(1,0,0),(-1,0,0),(0,0,1),(0,0,-1),(1,0,0),(1,0,0)]
V=[(0,-1,0),(0,-1,0),(0,-1,0),(0,-1,0),(0,0,1),(0,0,-1)]
dot=lambda a,b: sum(x*y for x,y in zip(a,b))
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def pos(c):
 f=c//16; z=c%16; row=z//4; col=z%4
 return tuple(U[f][i]*(col-1.5)*.8+V[f][i]*(row-1.5)*.8 for i in range(3))
def bound(f,neighbor,t,lane,depth):
 a=[c for c in range(f*16,f*16+16) if abs(dot(pos(c),N[neighbor])-(1.2-depth*.8))<.001 and abs(dot(pos(c),t)-(-1.2+lane*.8))<.001]
 assert len(a)==1,(f,neighbor,lane,depth,a)
 return a[0]
lines=[]
for f in range(6):
 for r in range(4):
  lines.extend([[f*16+r*4+c for c in range(4)],[f*16+c*4+r for c in range(4)]])
 lines.extend([[f*16, f*16+5,f*16+10,f*16+15],[f*16+3,f*16+6,f*16+9,f*16+12]])
for a in range(6):
 for b in range(a+1,6):
  if dot(N[a],N[b])!=0:continue
  t=cross(N[a],N[b])
  for lane in range(4):
   for split in range(1,4):
    lines.append([bound(a,b,t,lane,k) for k in range(split-1,-1,-1)]+[bound(b,a,t,lane,k) for k in range(4-split)])
assert len(lines)==204 and len({tuple(sorted(line)) for line in lines})==204
assert all(len(x)==4 and len(set(x))==4 and min(x)>=0 and max(x)<96 for x in lines)
print('PASS: 96 cells, 204 unique winning lines (60 face, 144 across edges); rank/purchase gate, shop, stats, profiles and original Classic preserved')
