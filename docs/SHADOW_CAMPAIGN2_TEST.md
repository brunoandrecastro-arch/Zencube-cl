# Campaign 2.0 – Shadow Realm (The Whispering Veil)

**Status:** Native Godot integration in the draft Shadow branch, based on the Abyss draft. PR #3, PR #9, main and Google Play are unaffected.

## Original source and optimized media

The user-supplied Zen_Chronicles_Chapter1_30_Images(1).zip contains 30 chronological PNG pages, each 941×1672. All 30 were compressed to optimized WebP, preserving page order and art, in **ZenCube_Shadow_Media_Pages.zip** (12.6 MB). Upload that ZIP **unchanged to the ROOT** of feature/campaign-2-shadow-realm; GitHub Actions extracts it before Godot import.

Existing Shadow Realm assets reused without duplicating content:
- Ambient soundtrack: assets/realm_music/shadow_realm.ogg
- Mist Guardian: boss_mist_guardian.json + mist_guardian.ogg + existing 3D BossSkins index 0
- Mirror Novice: boss_mirror_novice.json + mirror_novice.ogg + existing 3D BossSkins index 1
- Veil Monk: boss_veil_monk.json + veil_monk.ogg + existing 3D BossSkins index 2
- Shadow arena: assets/realms/shadow_realm.webp, verified **1440×2560 pixels**, not a crop from a concept montage
- Boss images are existing illustrated WebPs around 640 pixels wide; they are NOT 1536×2048 HD originals. Replace them with approved higher-resolution source art later if desired.

## Playable 30-page sequence

1. Pages 1–4 → Mist Guardian (Medium); victory unlocks page 5.
2. Pages 5–8 → Mirror Novice (Medium); victory unlocks page 9.
3. Pages 9–15 → Veil Monk (Medium); victory unlocks page 16.
4. Pages 16–30 → Shadow chapter ending. The existing story points toward Ember Temple.

All fights reuse the existing rotatable native 4×4 cube: 96 playable cells, 204 win lines, fair alternating starters, own portrait and music, saved unfinished matches, retry after loss/draw, original mirror-shatter ceremony after victories.

Independent save file: user://zencube_shadow_campaign_v1.json. The old Realm Chronicles and Abyss progress files, rewards, shop and normal ranks are NOT changed. Shadow and Abyss both appear in the Zen Chronicles library, on a separate test APK. Original 12 Realm Chronicles bosses still work.

## Termux upload after downloading the media ZIP

Use the same authenticated GitHub Termux installation as the Abyss upload, then run:

    cd ~
    git clone --depth 1 --branch feature/campaign-2-shadow-realm https://github.com/brunoandrecastro-arch/Zencube-cl.git zencube-shadow
    cd ~/zencube-shadow
    cp ~/storage/downloads/ZenCube_Shadow_Media_Pages.zip .
    unzip -t ZenCube_Shadow_Media_Pages.zip
    git add ZenCube_Shadow_Media_Pages.zip
    git commit -m "Add original Shadow Realm 30 Manhwa pages"
    git push origin feature/campaign-2-shadow-realm

GitHub Actions extracts existing Abyss ZIPs plus Shadow ZIP, executes old checks and tests/test_shadow_campaign.gd, validates all media and builds **ZenCube-3D-Shadow-Test.apk**, package **com.zencube.game.shadow**. The Shadow APK runs side-by-side with the real Play install and the Abyss test APK. Before that ZIP upload the workflow deliberately fails at the 30-page media requirement.

## Safety

No merge, release AAB, Play upload, modification to PR #3/#9 or existing branch commits. Temporary QA feature zencube_shadow_test exists only in this debug APK and does not change production Zen Ascend gates. Require complete CI success and on-device visual/gameplay QA before calling this a finished version.
