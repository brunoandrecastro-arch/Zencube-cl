#!/usr/bin/env python3
"""Strict static coverage for ZenCube's DE, EN and PT-PT UI.
Does not replace a Godot on-device UI test.
"""
from pathlib import Path
import ast, json, re
ROOT=Path(__file__).resolve().parents[1]
locale=(ROOT/'core/ZenLocalization.gd').read_text(encoding='utf-8')
ui=(ROOT/'ui/GameController.gd').read_text(encoding='utf-8')

def table(name):
    # GDScript constant literal dictionary contains only string pairs.
    tail=locale.split(f'const {name}: Dictionary = {{',1)[1]
    body=tail.split('\n}',1)[0]
    return ast.literal_eval('{'+body+'\n}')
EN=table('EN')
PT=table('PT')
assert EN and PT

def strings_from_ui(source):
    keys=set()
    for match in re.finditer(r'\b(?:label|button|premium_button|modal|notify_user|T)\(\s*("(?:[^"\\]|\\.)*")',source):
        keys.add(json.loads(match.group(1)))
    return keys

keys=strings_from_ui(ui)
for file in ('ui/TutorialController.gd','core/CubeGeometry.gd'):
    s=(ROOT/file).read_text(encoding='utf-8')
    # Both arrays are German-localization sources; they are all rendered via T().
    if 'TutorialController' in file:
        arr=s.split('const TEXTS = [',1)[1].split(']',1)[0]
    else:
        arr=s.split('const NAMES = [',1)[1].split(']',1)[0]
    keys.update(json.loads(m.group(0)) for m in re.finditer(r'"(?:[^"\\]|\\.)*"',arr))
keys.update(['Anfänger','Fortgeschritten','Experte','Zen-Meister','Großmeister',
    'Leicht','Mittel','Schwer','Bot: Leicht','Bot: Mittel','Bot: Schwer',
    'Du spielst X  ·  Zen-Bot spielt O',
    'Zen erreicht!','Zen-Schüler','Gewonnen!','Verloren','X gewinnt','O gewinnt','Noch eine Runde?'])
# Proper names, symbols, explicit language endonyms and formatting-only strings.
exempt={'','ZenCube 3D','☰','◀','▶','🌐','Deutsch','English','Português',
        'Deutsch  ·  English  ·  Português','%s: %d / %d'}
keys-=exempt
assert not (keys-set(EN)), 'Missing EN entries: '+repr(sorted(keys-set(EN)))
assert not (keys-set(PT)), 'Missing PT entries: '+repr(sorted(keys-set(PT)))
for key in keys:
    for code,translations in [('en',EN),('pt',PT)]:
        text=translations[key]
        assert text and text.strip(), f'{code} empty for {key!r}'
        assert re.findall(r'%[sd]',key)==re.findall(r'%[sd]',text), f'Placeholder mismatch {code}: {key!r}'
        if key!='Zen-Rätsel' and key not in {'SEITE A','SEITE B','Zen Challenge','Zen-Bot denkt nach …','Du spielst X  ·  Zen-Bot spielt O'}:
            # Keep identical strings only if they're language-neutral (names, numbers, icons).
            assert text!=key or not re.search('[a-zäöüß]',key,re.I), f'{code} untranslated: {key!r}'
assert 'ZenLocale.translate(source, language_code())' in ui
assert 'if not code in ["de", "en", "pt"]' in ui
assert 'language_picker.add_item("Português", 2)' in ui
assert 'if help_text != null: help_text.text = toast' in ui
assert 'challenge_role_label.text = T("Du spielst X  ·  Zen-Bot spielt O")' in ui
assert 'persist() # Saves settings without replacing Classic while in Challenges.' in ui
for bad in ('A calm strategy game of balance, space and focus.',
           'label("Sprache / Language"','"Classic fortsetzen"',
           '"Zen Challenges · 100 Rätsel"','"Zen Challenges · 5 Stufen"'):
    assert bad not in ui, f'Mixed UI wording: {bad}'
for code, sample in [('de','Du spielst X  ·  Zen-Bot spielt O'),
                    ('en',EN['Du spielst X  ·  Zen-Bot spielt O']),
                    ('pt',PT['Du spielst X  ·  Zen-Bot spielt O'])]:
    print(f'{code}: {sample}')
print(f'OK: {len(keys)} UI+Tutorial+Challenge source messages fully covered by EN and PT-PT')
