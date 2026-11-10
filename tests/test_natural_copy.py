#!/usr/bin/env python3
"""ZenCube 9.3: static regression check for natural copy in all languages."""
from pathlib import Path
import ast, re
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'core/ZenLocalization.gd').read_text(encoding='utf-8')
ui=(ROOT/'ui/GameController.gd').read_text(encoding='utf-8')
tut=(ROOT/'ui/TutorialController.gd').read_text(encoding='utf-8')
source=s.split('const NATURAL_COPY: Dictionary = {',1)[1].split('\n}',1)[0]
translations=ast.literal_eval('{'+source+'\n}')
assert len(translations)>=25, 'Too few reviewed text replacements'
for key, values in translations.items():
    # Retain old keys so previously saved copy can still translate on update.
    assert len(values)==3, key
    assert all(isinstance(v,str) and v.strip() for v in values), key
    for v in values:
        assert re.findall(r'%[sd]',key)==re.findall(r'%[sd]',v), key
for key in ('Ein ruhiges Strategiespiel für Balance, Raumgefühl und Konzentration.',
            'Deine Zen-Pause','Willkommen im Zen-Garten',
            'Atme durch. Drehe den Würfel. Entdecke neue Wege zu gewinnen.',
            'Gelöst! Ein Zen-Blatt für dich. 🍃'):
    assert key in translations, key
assert 'if NATURAL_COPY.has(source)' in s
assert '"en": return str(variants[1])' in s
assert '"pt": return str(variants[2])' in s
assert 'version/name="9.4.1-ascension-streaks"' in (ROOT/'export_presets.cfg').read_text()
assert 'version/code=14' in (ROOT/'export_presets.cfg').read_text()
print(f'OK: {len(translations)} natural text replacements in DE, EN and PT-PT')
