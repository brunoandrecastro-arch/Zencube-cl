# Campaign 2.0 – Abyss of Memories (preparation)

**Status (18 November 2026):** This branch is a draft based on `feature/zen-ascend-realm-chronicles`. It contains the corrected 30-page manifest and a separate GDScript progression/save model. **The native Godot reader, 4x4 battle adapter, portraits, music and 30 story images are not yet wired/imported into the Android app.** An independent playable browser prototype + the supplied media have been prepared as a separate downloadable ZIP in the chat.

## Verified file-order correction

The upload contains all 30 PNG files, but four **filenames do not match the page numbers printed on the images**:

| Display page | Source ZIP filename |
|---|---|
| 07 | `Abyss_of_Memories_Seite_30.png` |
| 17 | `Abyss_of_Memories_Seite_07.png` |
| 27 | `Abyss_of_Memories_Seite_17.png` |
| 30 | `Abyss_of_Memories_Seite_27.png` |

All other image numbers match their printed page numbers. The companion preview ZIP provides correctly ordered `page_01.webp` through `page_30.webp` at 941×1672.

## Gameplay flow

1. Read pages **1–6**. Intercept Next at page 6; launch **The Memory Thief**, Medium, own music/portrait. After an actual win, unlock page 7.
2. Read pages **7–15**. Intercept Next at page 15; launch **The Weeping Blade**, Hard, own music/portrait. After an actual win, unlock page 16.
3. Read pages **16–25**. Intercept Next at page 25; launch **The Forgotten Shogun**, Master, own music/portrait. After an actual win, unlock pages 26–30 and the chapter ending.
4. On loss or draw: stay at the same gate and offer retry. On leaving: preserve the in-progress match. On success: animate mirror fracture, resume the comic at the next unlocked page.

**Game engine:** Reuse the existing 4×4 Godot cube with 96 playable cells, 204 win lines, four-in-a-row on faces and across edges, and fair alternating first turns. Do not implement a second production board/rules engine.

**Save isolation:** `user://zencube_abyss_campaign_v1.json` (separate from the existing `user://zencube_realm_chronicles_v1.json`). Persist current page, three boss victories, attempts and any in-progress 96-cell game.

**Music:** `Echoes of a Forgotten Life` on story pages; `The Memory Thief`, `The Weeping Blade`, and `The Forgotten Shogun` only for corresponding boss encounters. Restore the earlier game audio when leaving Campaign 2.0. Browser preview uses original uploaded MP3 audio; optimize to looping Godot-ready audio when the Android integration is done.

**Art:** 30 narrative pages and 3 approved boss portraits are in the separate media ZIP. Four cube skins are currently concept visuals only (Abyss Main, Memory Thief, Weeping Blade, Forgotten Shogun), **not yet production 3D materials**. Do not claim finished skins or Android build.

**Next integration tasks:** Move media from prototype `assets` into Godot `res://assets/abyss_of_memories/`; use `story/ZenAbyssCampaign.gd` to control comic page gating; wire a separate menu entry in `story/ZenChronicles.gd`; add Campaign-2 routing in `ui/AscendController.gd` using the existing native cube, independent AI strength, audio, win/loss, and save. Add Godot headless tests and compile a *separately installable* debug APK. Test on device before considering any merge.

**Invariants:** Existing 3×3 campaign, 4×4 base realm gates, twelve Realm Chronicles bosses, skins, shop, earned currency, ranked progression, title rewards, official package name and Google Play builds remain **unchanged**. Do not merge, publish or upload a release AAB without explicit approval.
