#!/usr/bin/env python3
"""Static checks for exactly one original quote per Classic World in three languages."""
from pathlib import Path
import ast, re
ROOT=Path(__file__).resolve().parents[1]
ui=(ROOT/'ui/GameController.gd').read_text(encoding='utf-8')
loc=(ROOT/'core/ZenLocalization.gd').read_text(encoding='utf-8')
worlds=(ROOT/'core/ZenAscension.gd').read_text(encoding='utf-8')
quotes=re.search(r'const WORLD_QUOTES: Array\[String\] = \[\n(.*?)\n\]',ui,re.S)
assert quotes, 'missing five world quote constants'
items=ast.literal_eval('['+quotes.group(1)+']')
assert len(items)==5 and len(set(items))==5, 'one distinct fixed quote per world'
assert all(len(q)>20 and len(q)<90 for q in items)
assert 'const WORLDS = ["Zen-Garten", "Bambuspfad", "Bergtempel", "Mondgarten", "Himmelsgarten"]' in worlds
for lang in ('EN','PT'):
    table=loc.split('const '+lang+': Dictionary = {',1)[1].split('\n}',1)[0]
    values=ast.literal_eval('{'+table+'\n}')
    for quote in items:
        assert values.get(quote) and values[quote]!=quote, (lang,quote)
assert 'world_title_label = label("Zen-Garten",brand,27' in ui
assert 'var sub = label("ZenCube 3D",brand,12' in ui
assert 'world_quote_label = label(WORLD_QUOTES[0],legend_panel,12' in ui
assert 'world_title_label.text = T(Asc.WORLDS[active_world])' in ui
assert 'world_quote_label.text = T(WORLD_QUOTES[active_world])' in ui
assert '"6 SEITEN · 54 FELDER · 108 VIERERLINIEN",legend_panel' not in ui
assert 'apply_world()' in ui and 'func select_world(number: int)' in ui
assert 'const VERSION = 3' in (ROOT/'core/SaveManager.gd').read_text()
assert 'const PRICE: int = 850' in (ROOT/'core/ZenAscend.gd').read_text()
print('PASS: five fixed Zen quotes; live world heading; DE/EN/PT-PT; Classic saves and 4x4 gate preserved')
