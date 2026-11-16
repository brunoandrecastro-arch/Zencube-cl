# Zen Ascend Realm Chronicles boss portraits

The six existing `boss_*.svg` files are **temporary vector placeholders only**. They do **not** match the approved high-quality illustrated portrait concept.

The game automatically prefers the following **six original optimized WebP portraits** when available in this same directory:

| Boss | Preferred filename |
|---|---|
| Mist Guardian | `boss_mist_guardian_hd.webp` |
| Mirror Novice | `boss_mirror_novice_hd.webp` |
| Veil Monk | `boss_veil_monk_hd.webp` |
| Ash Runner | `boss_ash_runner_hd.webp` |
| Banner Guardian | `boss_banner_guardian_hd.webp` |
| High Priest of Embers | `boss_ember_high_priest_hd.webp` |

The six originals are packaged separately in `ZenAscend_6_Original_Bossbilder_fuer_GitHub.zip` for review/upload. **Do not upload the ZIP itself as the game asset**: extract its six WebP images and put them in `assets/realm_chronicles/` on the `feature/zen-ascend-realm-chronicles` branch only.

The application checks `ResourceLoader.exists` before loading `*_hd.webp` assets and retains the SVG fallback for development builds. Adding the preferred high-resolution files does **not** alter 4×4 rules, boss KI, shop skins or any saved game state.

No merge, no Play Store change, no release build without explicit approval.
