# Campaign home and Act IV video

The home screen foregrounds **Start Campaign / Continue Campaign**. The action
opens the current Act at its saved page or resumes the Classic match required
for the next Act. A different unfinished match is replaced only after the player
chooses to start the campaign match.

**Zen Chronicles** sits immediately below the campaign button. **Game Modes**
groups Free Play, Challenges, local multiplayer and Training. The Profile groups
ranks, Worlds, statistics and, after the dimensional reveal, earned achievements.
The Shop remains directly accessible.

The full illustrated explanation lives under **How to Play**. A first campaign
visit offers a skippable three-step interactive tutorial. Gameplay status and
move counters are hidden on the home screen.

## Unlock copy

Each Act card names its destination, the match task and the current progress.
The match task names the preceding, accessible World rather than sending a new
player to a locked destination:

| Destination | Match task | Other requirement |
| --- | --- | --- |
| Act I — Zen Garden | Available immediately | — |
| Act II — Bamboo Path | Win 3 matches on Easy in Zen Garden | Finish Act I |
| Act III — Mountain Temple | Win 5 matches on Medium in Bamboo Path | Finish Act II |
| Act IV — Moon Garden | Win 7 matches on Hard in Mountain Temple | Finish Act III |

The existing difficulty win counters and Act gates remain authoritative. This
update does not add a World-specific win counter or migrate existing results.
The campaign action selects the World and difficulty shown in the task.
All navigation, introduction and unlock copy is localized in DE / EN / PT-PT.

## Video and source base

This update is based on `feature/moon-shadow-video-transition-20261121`, commit
`a135a066d3d081613a3b9771d4e41727b2aec3f2`, which already contains the approved
`assets/video/moon_shadow_3x3_to_4x4.ogv`.

The video runs after the validated Act IV boss result, before page 12 is shown.
It also plays when replaying the turn from page 11 to page 12. Skipping continues
to page 12. The video checkpoint does not grant the Shadow Realm; that follows
the existing final-page completion and awakening sequence.

The normal release build must use the existing full premium media extraction.
The complete unsigned Alpha-update candidate uses Play version **4.0.5 (45)**
and the existing package **com.zencube.game.play**. The candidate workflow
extracts all premium media and verifies the original video inside the bundle.
Signing remains local with the existing upload key; the workflow does not upload
or publish anything to Google Play.

## Validation and previews

Validation uses the project's Godot **4.5.1** runtime, the real scene, connected
buttons, restored matches, saved Manhwa pages and the real Theora video player.
The new navigation test runs in CI alongside the existing engine, localization,
Act and cinematic tests. Physical Android touch and audio playback still need
the normal device check of the resulting build.

When run with a rendering backend, `tests/test_home_navigation.gd` also captures
the real home screen in all three languages and the English unlock cards under
`docs/*preview-*.png`. The generated QA captures are delivered separately.
