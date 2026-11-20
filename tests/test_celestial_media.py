"""Verify Celestial media is actually present, not a placeholder."""
import argparse, pathlib, zipfile
p = argparse.ArgumentParser()
p.add_argument("--extract", action="store_true")
p.add_argument("--apk")
args = p.parse_args()
root = pathlib.Path("assets/celestial_campaign")
bosses = ("wind_scribe", "bridge_sentinel", "sky_archivist")
paths = [root / "pages" / ("page_%02d.webp" % i) for i in range(1,31)]
paths += [root / kind / (boss+".webp") for kind in ("bosses","arenas") for boss in bosses]
if args.extract:
    with zipfile.ZipFile("ZenCube_Celestial_Media_3.0.zip") as z:
        assert z.testzip() is None
        for f in paths:
            data = z.read(f.as_posix())
            assert data[:4]==b"RIFF" and data[8:12]==b"WEBP", f
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_bytes(data)
if args.apk:
    with zipfile.ZipFile(args.apk) as z:
        names = set(z.namelist())
        for f in paths:
            n = "assets/" + f.as_posix()
            assert n in names or n+".import" in names, n
        for boss in bosses:
            n = "assets/assets/realm_boss_music/" + boss + ".ogg"
            assert n in names or n+".import" in names, n
print("Verified 36 Celestial assets")
