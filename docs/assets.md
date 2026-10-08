# App assets

## Sounds

Original clips live in `sounds/`. The app bundles identical copies in `Foxlingo/Resources/Sounds/`, registered as an Xcode folder resource. Copy changed originals into the bundled folder before shipping. The eight clips total under 600 KiB; no download or provider account is required.

The catalog and cue profiles are defined in `Foxlingo/Core/SoundAssets.swift`. Preview the full files in **Settings → Assets → Sounds**. Playback uses the existing Sound preference; switching it off immediately stops playback and disables previews.

| Moment | Clip |
| --- | --- |
| Correct lesson or typed recall answer | success.mp3 |
| Mini-game connection or matching pair | small-win.mp3 |
| Mini-game mistake or memory mismatch | small-defeat.mp3 |
| Incorrect lesson or typed recall answer | wrong.mp3 |
| Completed session, album card unlock or earned tier upgrade | level-up.mp3 |
| Memory reveal, clue reveal, bingo skip or answer reveal | ui-interface.mp3 |
| Available in the preview library for future modes | game-over.mp3, sad-trumpet.mp3 |

Revealed recall answers use an interface cue rather than an incorrect-answer cue. Unknown mystery comparisons remain neutral. A game's final move plays one completion cue instead of stacking a small win and a celebration. Haptics retain their independent preference.

Playback uses AVAudioSession's ambient category, respecting the device's Silent Mode and mixing with other audio. There is one active player; new events replace prior ones. Short interaction cues are bounded to 0.24 seconds, retry/setback cues to 0.9 seconds, and level-up feedback to 2.8 seconds, with a short fade. Preview playback uses the full duration. Volumes are modest per-clip gains, not loudness normalization. Leaving the foreground or the preview page stops playback. Missing or undecodable clips fail quietly without blocking learning; a failed preview shows a message.

Competition marks are cached in three `entity-competition-*` image sets. See `content/competition-artwork.json` for original URLs, author credits and licenses. The UEFA mark comes from its 2018–21 media archive. The Bundesliga lockup is rendered to PNG and its red emblem is framed in native layout. Liga MX uses Hectortoro2019’s unmodified Commons file under CC BY-SA 4.0; its credit/license appears in Settings sources. Competition marks are not original Foxlingo artwork.

Four supporting career-club badges are cached for Irapuato, Veracruz, América de Cali and Shanghai Shenhua. Their credits also appear in the content pack's source list. `content/player-career-artwork.json` records the original links, bitmap checks, rights information and badge-period limits. Irapuato and América use club-site marks; Shenhua is extracted from the AFC 2024/25 technical report; Veracruz uses a historical club crest identified in its Wikipedia file record. These identify the clubs illustratively and do not assert the exact badge worn in the taught historical season. The two América clubs have distinct entities and assets.
