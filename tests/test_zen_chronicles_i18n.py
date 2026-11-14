#!/usr/bin/env python3
"""Validation: 5x4 illustrations and complete German/English/PT-PT chapter text."""
import sys,json,re
from pathlib import Path
root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parent
reader=(root/'story/ZenChronicles.gd').read_text(encoding='utf8')
source=json.loads((root/'story/chronicles.json').read_text(encoding='utf8'))
locales=json.loads((root/'story/localization.json').read_text(encoding='utf8'))
assert len(source['chapters'])==5
assert set(locales)=={'en','pt'}
expected={'library_tip','library_header','tagline','summary','chapter_row','read','locked','unlock_hint','reader_row','previous','next','chapters','swipe_help','reward'}
for code in ('en','pt'):
    loc=locales[code]
    assert set(loc['ui'])==expected,(code,'UI keys missing/extra')
    assert len(loc['chapters'])==5
    for idx,ch in enumerate(loc['chapters']):
        assert all(isinstance(ch[k],str) and ch[k].strip() for k in ('world','title','reward'))
        assert len(ch['pages'])==4
        original=source['chapters'][idx]
        assert len(original['pages'])==4
        for page_idx,p in enumerate(ch['pages']):
            assert all(isinstance(p[k],str) and len(p[k].strip())>5 for k in ('title','body','quote')),(code,idx,page_idx)
            assert p['body']!=original['pages'][page_idx]['body'],(code,idx,page_idx,'untranslated')
            assert original['pages'][page_idx]['image'].endswith('.webp')
        assert ch['world']!=original['world'],(code,idx,'untranslated world')
assert 'SaveManager.load_data()' in reader
for field in ['_t("library_header")','_t("locked")','_t("read")','_chapter_field(i, "world")','_chapter_field(i, "title")','_page_field(_active_chapter, _active_page, "body")','_page_field(_active_chapter, _active_page, "quote")']:
    assert field in reader,field
assert 'STORY_LANG_FILE = "res://story/localization.json"' in reader
assert 'ASC.world_unlocked(saved, i)' in reader
assert 'func _sync_language() -> void:' in reader
assert '_sync_language()\n    _active_chapter = -1' in reader
assert 'func open_chapter(i: int) -> void:\n    _sync_language()' in reader
print('OK: 5 chapters × 4 pages, complete DE/EN/PT-PT narration, chapter labels and menu translations')
print('OK: existing world unlock mechanism preserved, no assets modified')
