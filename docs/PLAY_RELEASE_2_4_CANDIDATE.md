# ZenCube 3D Play 2.4 draft – 16 November 2026

Branch: release/play-candidate-2.4-2026-11-16 (based on Realm Chronicles PR #3).

**Draft ONLY. Do not merge, sign, upload or publish to Google Play without approval.**

Release preparation: live 3D Cube appears on first screen with Japanese proverb 千里の道も一歩から, romaji, and localized DE/EN/PT translation; language buttons and tutorial remain. 4×4 release gate requires Zen Master rank or permanent 850-leaf purchase. QA shortcuts remain exclusive to isolated debug APK. Existing saves, skins, 12 boss songs and mirror-shatter effect preserved.

**Existing Google Play app only:** Play manifest package com.zencube.game.play (matching prior user-provided listing URL), versionCode 24, versionName 2.4 as candidate values. Confirm these against current Play Console version and registered upload certificate before any signing/upload.

**HD art status (16 Nov 2026): All six approved WebP files are now committed directly to this branch, byte-identical to the approved ZIP (Git blob checksums verified). The following was the original import plan, now completed.**

**Original note:** The six files boss_wind_scribe_hd.webp, boss_bridge_sentinel_hd.webp, boss_sky_archivist_hd.webp, boss_lotus_witness_hd.webp, boss_halo_keeper_hd.webp, boss_fully_aware_hd.webp must be present in assets/realm_chronicles/ before export. New original images are supplied separately as ZenCube_Realm_Boss_HD_2_4.zip in this conversation. They are not in this GitHub branch yet. Godot already prefers these *_hd.webp assets. Import on this branch with bash scripts/import_hd_boss_portraits.sh path/to/ZIP, then push the commit. The Play AAB build is intentionally blocked until this is satisfied.

Before Play release: verify package, increasing versionCode, upload key SHA-256, installability on Samsung S23, three languages and Japanese glyphs, 3D first-screen placement and readability, Realm unlocks (8 Challenges plus 3 bosses), music crossfades, 12 boss pictures, first-unlock mirror shatter with sound, and full 3x3/4x4 regression tests.

## 2026-11-16 – Original HD boss portraits integrated

The six approved 600×900 WebP images are committed as direct game resources. The application now loads them ahead of the low-quality JSON fallbacks, via `_realm_story_art`. Preflight `tests/test_release_hd_boss_assets.py --release` checks all six. The original concept pictures were not altered or substituted. This draft remains unmerged and unpublished.

## End-user APK correction – 16 November 2026
The previous Android download was an **isolated QA app** with all Realms and 4×4 open, so it was not an end-user build. End-user acceptance now uses `ZENCUBE_ENDUSER_PREVIEW=true` on this PR, isolated package `com.zencube.game.enduserpreview` (fresh independent local save; no Play Console listing). The Android *debug* signing key permits local installation but no longer enables gameplay skips. The QA bypass requires BOTH Godot debug and an explicit QA-only project flag. The Play app remains `com.zencube.game.play`, untouched. Only after S23 acceptance do we hand off Play AAB/signing tasks. **Do not publish this preview APK as a new Google Play app.**
