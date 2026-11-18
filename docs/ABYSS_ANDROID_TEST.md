# ZenCube 3D – Abyss of Memories: Android test APK

**Status:** native Godot story reader and 3 boss battles implemented in Draft PR #9. The package builds on GitHub Actions **only after the real media ZIPs are uploaded**.

## Once-only media upload (GitHub website, no Termux or Work)

1. From the ChatGPT response, save these two archives to your PC:
   - `ZenCube_Abyss_Media_Pages.zip` (30 ordered HD Manhwa pages)
   - `ZenCube_Abyss_Media_Boss_Audio.zip` (3 HD boss portraits + 4 original MP3s + 1 Abyss backdrop)
2. Open `https://github.com/brunoandrecastro-arch/Zencube-cl` and select the branch `feature/campaign-2-abyss-of-memories` (PR #9) via the branch selector. **Do not use main or PR #3.**
3. Choose **Add file → Upload files**. Drag **both ZIPs into the root of this branch** and commit directly to `feature/campaign-2-abyss-of-memories`. Each ZIP is below GitHub's 25 MB browser upload limit.
4. That commit retriggers **Android debug APK** in GitHub Actions. The workflow checks the ZIPs, extracts all 38 media resources *before* Godot import, validates the 30 pages/3 bosses/4 tracks, runs existing regression tests, then signs a distinct debug package.
5. Download the completed **ZenCube-3D-Abyss-Test** artifact ZIP from the successful workflow and extract `ZenCube-3D-Abyss-Test.apk`. Install it on Android (allow local APK installs when prompted).

The APK package is `com.zencube.game.abyss`, app label **ZenCube Abyss Test**. It does not overwrite the main Play installation `com.zencube.game` or the older Realm-Chronicles preview `com.zencube.game.realmchronicles`. No Google Play changes.

## Test walkthrough

- Launch `ZenCube Abyss Test`. Enter **Zen-Chroniken 📖 → Campaign 2.0 · Abyss of Memories**.
- Read or swipe from page 1 through page 6. The next action becomes **⚔ Bosskampf**; this starts a genuine rotatable 96-cell 4x4 cube.
- Boss 1: **The Memory Thief** (Medium, memory-mirror tactical signature). Win, use **Geschichte fortsetzen**. A glass-fracture transition reveals page 7. Loss/draw: retry, starter alternates; reopening restores saved match.
- Repeat after page 15 for **The Weeping Blade** (Hard) and after page 25 for **The Forgotten Shogun** (Master).
- Read pages 26–30 and press **Kapitel abschließen**.
- Verify special 3D cube surfaces and original MP3 loop; return to menu and reopen to confirm the separate save.
- Check languages DE/EN/PT and that regular 3x3 and normal 4x4 saves, skins, shop and title ranks remain untouched.

## Scope and safety

- The order of pages 7, 17, 27, 30 was repaired by reading the actual printed page numbers from the user-supplied ZIP.
- Existing 4×4 rules are reused exactly: six faces, 96 cells, four-in-a-row on face/across edge, 204 winning lines.
- 4 unique **playable, procedural 3D material skins** are implemented in `core/ZenAbyssSkins.gd`. They follow the color/material concepts but are not photorealistic recreations of the concept render.
- `ZenAbyssReader.gd` is a separate full-screen, touch-swipe reader with music suppression/restoration; no interference with original comic chapters.
- Saving uses only `user://zencube_abyss_campaign_v1.json`; it does not update Classic rankings/economy.
- **QA entitlement:** only the dedicated debug APK exports `zencube_abyss_test` as a custom feature. It allows immediate access to the Abyss boss fights without granting permanent Zen Ascend access. Main release debug and Play builds contain no QA feature.
- The existing mirror shatter in `ZenRealmTravelCeremony.gd` is reused for boss victories.
- Existing PR #3 and Google Play remain unchanged; **PR #9 remains Draft**, no merge or release.

## Checks

`tests/test_abyss_campaign.gd` verifies 204 lines, 96-cell board, initial page gates, alternating starts, separate save file, three successful transitions, complete ending and all four procedural skins. The CI build also runs the pre-existing regression suite.

**Known dependency:** While the two supplied media ZIPs are not yet uploaded to the GitHub branch, the final APK check intentionally fails. This is not a gameplay defect; do not mark the app final or report a completed full media build before those files are committed and Android CI succeeds.
