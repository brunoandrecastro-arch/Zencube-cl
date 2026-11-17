# Realm Chronicles 4x4 – 12 Boss Battle Themes

**Status: Audio loader is wired; the 12 OGG assets have not yet been uploaded into this GitHub branch.** Until the OGG assets arrive, the game falls back to its existing Realm/Shop soundtrack.

This directory is reserved exclusively for the original music from the user's `ZenCampaign Ascen Boss.rar`. Put the **loop-ready OGG files** from `ZenCube_Bossmusik_12_Tracks_Godot_Ready.zip` directly into this directory, retaining the filenames below.

| Story stage | Boss ID / required file | Original song |
|---|---|---|
| 1 | `mist_guardian.ogg` | Whispers of Doubt |
| 2 | `mirror_novice.ogg` | Mirror of Regret |
| 3 | `veil_monk.ogg` | The Mask of Fear |
| 4 | `ash_runner.ogg` | Ashes of Anger |
| 5 | `banner_guardian.ogg` | Burning Resolve |
| 6 | `ember_high_priest.ogg` | Heart of the Inferno |
| 7 | `wind_scribe.ogg` | Wings of Silence |
| 8 | `bridge_sentinel.ogg` | The Celestial Trial |
| 9 | `sky_archivist.ogg` | Keeper of the Stars |
| 10 | `lotus_witness.ogg` | Stillness Before Dawn |
| 11 | `halo_keeper.ogg` | The Weight of Self |
| 12 | `fully_aware.ogg` | Beyond the Self |

Runtime mapping: `core/ZenRealmBossMusic.gd`; use `ui/AscendController.gd`. The boss track plays only when `realm_story_active`, including with user-selected music; on direct return to normal 4×4 Zen Ascend, the original music is restored. Tracks have 2-second loop-boundary crossfades. All normal Shop music, IDs and unlock rules are unchanged.

**Do not merge PR #3 or deploy a Play Store build without explicit approval.** Test on a real Android device after adding assets.
