# ZenCube 3D 2.0 — Final code candidate

## Source and release boundaries
- Baseline: annotated Git tag `zencube-3d-2.0`, plus subsequent localized mode-picker corrections.
- Candidate: this branch, validated using the complete Android/Godot test workflow.
- Android review APK: **com.zencube.game.uitest**, app name **ZenCube 3D 2.0**. Its update signing key is restored from the existing UI-test CI cache.
- Do not change the current Google Play closed-test package **com.zencube.game.play** in this candidate. Upload requires separately signed Play AAB, increasing Play versionCode and the owner's explicit publishing approval.
- PR #5 and PR #3 remain drafts; do not merge into main from automated CI.

## Changes included
- Sakura-Gold unified 3×3 and 4×4 UI, including readable Settings controls and fixed Done footer.
- True in-game 3D cube and legally generated win example in language selection.
- Read-only post-game rotation and zoom in Classic and Zen Ascend, with result reopening.
- Correct earned title in 4×4 statistics, achievements separate from Realm challenges, precise localized unlock conditions.
- 12 Realm Chronicles boss opponents and individualized assets and music, progress gates, and mirrored breakthrough.
- Shadow bosses minimally strengthened without changing tier.
- Mixed-language Realm selector corrected, together with statistics, challenges, secret achievements and achievement titles/quotes/hints across DE/EN/PT.
- Realm player/bot starting turns alternate across completed 4×4 matches; campaign bosses alternate by stage, and retries flip the opener. Story-save backwards compatibility preserved.

## Approval checklist
- [x] Godot headless build and automated regression suite
- [x] Realm selection, stats, achievements, hint text translated in DE / EN / PT
- [x] Normal and story start-order fairness regression
- [x] Android APK package and existing UI-test signing path retained
- [ ] Final installation and on-device walk-through (manual)
- [ ] Upload-key-signed AAB and Play Console release (requires separate approval)

The internal **ZenCube 3D 2.0** milestone is a product snapshot, not a downgrade of the existing Play Alpha 2.3 version number.
