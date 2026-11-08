"""Static language, audio, and rule regression checks for ZenCube.
This is NOT a replacement for an on-device audio test.
"""
from pathlib import Path
import json, wave, math, struct
BASE=Path(__file__).resolve().parents[1]
controller=(BASE/'ui/GameController.gd').read_text()
localize=(BASE/'core/ZenLocalization.gd').read_text()
dictionary=json.loads(localize.split('const EN: Dictionary = ',1)[1].split('\nstatic func english',1)[0])
assert len(dictionary)>=95, 'Translations missing'
for key in ('Willkommen im Zen-Garten', 'Einstellungen', 'Neue Partie','Zurück zum Spiel', 'Direkt gegen Zen-Bot spielen','Ruhige Zen-Garten-Musik','Musikprobe abspielen','SEITE A','Du bist am Zug  ·  ', '3+1 · Drei X auf einer Seite und eines auf der Nachbarseite. Setze das letzte X!'):
    assert key in dictionary and dictionary[key]!=key, f'Missing: {key}'
assert '\t' not in controller, 'Tabs break Godot script parsing'
assert 'if not str(data.settings.get("language", "")) in ["de", "en"]' in controller
assert 'func open_language_choice() -> void:' in controller
assert 'language_picker.item_selected.connect' in controller
assert 'translate_ui_tree(ui)' in controller
assert 'music_player.volume_db = -12' in controller
assert 'func music_preview() -> void:' in controller
assert 'ambient.loop_mode = AudioStreamWAV.LOOP_FORWARD' in controller
save=(BASE/'core/SaveManager.gd').read_text()
assert '"music":true,"language":""' in save, 'Default language/audio missing'
assert 'const VERSION = 3' in save, 'Existing saved games must not be wiped'
with wave.open(str(BASE/'assets/zen_ambient.wav'),'rb') as w:
    assert w.getnchannels()==1 and w.getsampwidth()==2
    data=w.readframes(w.getnframes())
    values=struct.unpack('<'+str(len(data)//2)+'h',data)
    rms=math.sqrt(sum(v*v for v in values)/len(values))
    dbfs=20*math.log10(rms/32768)
    assert -24<dbfs<-10, ('Music still inaudible or too loud',dbfs)
    assert max(abs(min(values)),max(values))<31000
print(f'OK: {len(dictionary)} translated strings, first-run language and settings, saved progress, WAV {dbfs:.1f}dBFS')
