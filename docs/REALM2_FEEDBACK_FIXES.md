# ZenCube 2.0 Realm – User feedback fixes

Draft PR #12, based on PR #11. NO Google Play action or merge.

## Game flows
- Lock Zen Realm Chronicles Shadow until the same **real Zen Ascend 4x4 unlock** (Zen Master or owned shop item). QA custom features cannot bypass this.
- Central Chronicles library hosts Shadow, Abyss, Ember, and Original Archives including the previous 12-boss legacy story.
- Normal Zen Ascend Realm screen only contains 4 Realm cards and 8 automatic 4x4 challenges per realm; no duplicate Open Story card.
- Classic 3x3 selected puzzles remain **Zen Challenges** (100 puzzle tasks) and are unchanged.
- In Campaign 2.0, all three story bosses + 30-page story + 3 regular Realm Challenge milestones are necessary for the next Realm.
- Shadow 3 milestones use existing Zen Ascend saved bot achievements (`shadow_first`, `shadow_edge`, `shadow_block`), with no duplicate leaf or achievement awards.
- Abyss 3 milestones are earned via regular 4x4 Zen-Bot matches in Abyss free-play: first win, edge win, total three wins. No selectable tactical puzzles or fabricated progress.
- Boss victories resume the Manhwa. The glass break only appears at the first legitimate Realm switch.
- Story result buttons localized in DE/EN/PT and compacted to fit phone screen.

## Artwork staging
ZIP: **ZenCube_2.0_Realm_Artwork.zip** (SHA-256 `b77e7f217916f1159e650eba3f2f9c708679f05ef19cc734c2145bd72292800e`). Four optimized WebP assets:
- `assets/shadow_campaign/arenas/mist_guardian.webp` (1440x2560; upscale from 941x1672 image generation source)
- `assets/shadow_campaign/arenas/mirror_novice.webp` (1440x2560; source 941x1672)
- `assets/shadow_campaign/arenas/veil_monk.webp` (1440x2560; source 941x1672)
- `assets/zen_realm2/ascend_preview.webp` (1600x900; source adapted to 16:9)

These files are not yet in the branch until the ZIP is committed to the branch root using Termux, as was previously done for Abyss media. GitHub Actions automatically extracts it before Godot import. In its absence, the debug APK uses original backgrounds (no claim of HD artwork).

## Android QA
Debug APK label `ZenCube 2.0 Realm`, package `com.zencube.game.realm2`, same cached debug signing key as previous Realm 2.0 APK, separate from the Play app. Test: locked Shadow without entitlement, unlock 4x4, progress 8 Shadow tasks and three selected tasks, finish story, first portal, ordinary Abyss free-play auto milestones, DE/EN/PT dialogs.

## Known work remaining
- Three **independent Abyss boss arena background images** are not available as image files in this branch. The existing cropped Abyss concept art remains a fallback. Replace once original HD arena source art is supplied. Do not claim these have already been installed.
- Up-resized Shadow sources are still sourced from 941x1672 generated images; upscaling does not create additional original detail.
- Verify visual quality and audio on Samsung S23 before any release.

## Safeguards
No production install modifications, no merging previous PRs, no Play upload, no signed release AAB.
