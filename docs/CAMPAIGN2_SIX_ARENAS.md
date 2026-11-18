# ZenCube 3D · Campaign 2.0: six unique Boss arenas

**Draft development integration, NOT a Google Play release.**

This branch adds genuine per-boss background selection for all six fights in the **Shadow Realm** and **Abyss of Memories** Campaign 2.0 chapters. The existing 3D cube, original twelve Realm Chronicles bosses, music loops, saves, shop and regular rank progression are untouched.

| Campaign chapter | Boss | Expected optional image |
|---|---|---|
| Shadow Realm | Mist Guardian | `assets/shadow_campaign/arenas/mist_guardian.webp` |
| Shadow Realm | Mirror Novice | `assets/shadow_campaign/arenas/mirror_novice.webp` |
| Shadow Realm | Veil Monk | `assets/shadow_campaign/arenas/veil_monk.webp` |
| Abyss of Memories | Memory Thief | `assets/abyss_of_memories/arenas/memory_thief.webp` |
| Abyss of Memories | Weeping Blade | `assets/abyss_of_memories/arenas/weeping_blade.webp` |
| Abyss of Memories | Forgotten Shogun | `assets/abyss_of_memories/arenas/forgotten_shogun.webp` |

The image pack is **ZenCube_Campaign2_Boss_Arenas.zip**, containing exactly those six WebPs at these internal paths. Upload that ZIP to the **root of this branch**, not to `main`. GitHub Actions unpacks all six before Godot import and checks their presence. The art is loaded automatically when starting the matching boss.

If the ZIP is not present, Shadow falls back to the original Shadow Realm background, and Abyss to the original safe right-hand crop of the Abyss illustration. There is no broken-texture state. This fallback is a temporary development measure, **not** proof that the HD artwork is deployed.

The six arenas may also be replaced later with approved Manhwa-quality art without changing the game logic or existing saves.

### Exact Android test checklist

1. Install the separate `ZenCube-2.0-Realm.apk` debug artifact **only after a successful action** on this development branch.
2. Open Shadow fights 1, 2 and 3, confirm unique backgrounds and legible real 3D cube.
3. Open Abyss fights 1, 2 and 3; confirm no landscape cropping of Kuze's face, and no identical arena background.
4. Confirm individual boss music, restoration to Realm music, save/restart/resume and loss/retry.
5. Verify the only glass/breakthrough transition occurs at a completed chapter's first Realm entry.
6. Verify original Play `com.zencube.game` installation and normal Classic/Zen Ascend saves are unchanged.

Automated CI checks cannot replace steps 1–6 on a physical Samsung S23.

### Remaining separate campaign work

Ember Temple, Celestial Realm, Shattered Moon Realm and Satori Realm still need their **own approved 30-page illustrated Manhwa chapters**, original Story soundtracks, 3 boss fights each with distinct music/portraits, skins, Arena art, progression gates and Android acceptance. No automated check can magically generate or verify these missing materials.
