#!/usr/bin/env bash
# On Termux or desktop: bash scripts/import_hd_boss_portraits.sh /path/to/ZenCube_Realm_Boss_HD_2_4.zip
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $# == 1 && -f "$1" ]] || { echo "Usage: $0 /path/to/Zip" >&2; exit 2; }
branch="$(git branch --show-current)"
[[ "$branch" == release/play-candidate-2.4-2026-11-16 ]] || { echo "Wrong branch: $branch" >&2; exit 2; }
for file in boss_wind_scribe_hd.webp boss_bridge_sentinel_hd.webp boss_sky_archivist_hd.webp boss_lotus_witness_hd.webp boss_halo_keeper_hd.webp boss_fully_aware_hd.webp; do
  unzip -p "$1" "$file" > "assets/realm_chronicles/$file"
done
python3 tests/test_release_hd_boss_assets.py --release
git add assets/realm_chronicles/boss_*_hd.webp
git commit -m "art(realm chronicles): six HD boss portraits"
echo "Now push to origin release/play-candidate-2.4-2026-11-16 when ready."
