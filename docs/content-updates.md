# Lesson library updates

Settings → Lesson updates can import an English curriculum JSON file through Files or check a supplied HTTPS manifest address. It stages a fully validated replacement for the `foxlingo-favorites-en` library. Quit Foxlingo from the app switcher and reopen it to activate the waiting version. Returning from the Home screen alone does not install it. An active lesson or copied practice deck keeps its current content.

The app has no default published feed. A feed and its lesson file can be served as static HTTPS JSON, including from Firebase hosting/storage. No cloud account, credential, subscription, deployment, or upload is required to use the bundled edition or Files import. Synchronizing personal progress and downloading game packs are separate future work.

## Preparing an update

Start with the bundled `starter-en.json` schema. Keep canonical keys and UUIDs stable, retain supporting sources, and increase `contentVersion`. A changed objective prompt, answer set, referenced fact identity/value, or historical scope requires a higher objective `revision`. An expanded album objective set requires a higher `knowledgeVersion`. Answer keys and memory pairs must agree with the objective's authored aliases. New unsupported exercise mechanics require an app update.

The update remains a complete library, rather than a partial merge. Removed subjects no longer appear in the active library; their earned cards and attempts remain in saved history. Subject and card keys must not be repurposed. Authors must review claims and sources: structural validation and a hash cannot establish factual truth.

Generate a manifest only after review, using the exact bytes that will be hosted:

```sh
python3 scripts/build_update_manifest.py \
  --content Foxlingo/Resources/starter-en.json \
  --content-url https://YOUR_HOST/lessons-v6.json \
  --output /tmp/lesson-manifest.json
```

Replace the example address with the hosted file's actual HTTPS URL. The bundled file is currently version 7; an installed version 7 app needs a higher reviewed version for an update. The command creates a local file and does not publish it. Uploading a JSON file with different whitespace requires regenerating its manifest because the SHA-256 covers the original bytes.

A manifest contains `packKey`, `contentVersion`, `schemaVersion`, `language`, `contentURL`, and `sha256`. Its metadata must agree with the downloaded file. Manifest downloads are limited to 64 KiB; curriculum downloads/imports to 16 MiB, even without an accurate size header. Requests use HTTPS, reject insecure redirects and unsuccessful responses, and carry no provider credentials. The hash detects mismatched bytes; trust still comes from choosing a trusted feed and reviewing authored facts.

## Offline activation and recovery

The library cache is separate from the learner save. Each cached file atomically stores original bytes, an integrity digest, and its activation intent. Interrupted or invalid downloads leave installed and waiting versions intact. Only newer same-family compatible versions stage through import/check. A newer waiting update cannot be replaced by an older one.

On a genuine next launch, the app retains the current working version before installing the waiting one. Previous-version restoration is an explicit confirmed action and also waits for a new launch. Corrupted installed content falls back to the previous compatible library or bundled lessons. A newer app-bundled version takes precedence over an older cache; older data can still establish progress compatibility. Cache persistence failures leave usable lessons available with a notice.

Before learner migration, the original learner JSON is archived on the device. Unchanged lesson resumes retain their board order, matches, attempts, and session ID. Changed or unprovable resumes restart, while their attempts remain historical acquisition attempts. Changed objective sets/revisions retire incompatible lesson completion flags; review corrections schedule a refresh. Earned card tiers, session history, and streaks remain. Repeated launches do not repeat a completed migration. Resetting learning progress preserves the lesson library and waiting update.

This feature does not supply automatic factual verification, content signing, provider integrations, generation on demand, or a production publishing service.

## Competition courses

A competition roadmap uses `subjectID` pointing to a canonical `competition` entity and omits `clubID`. Club roadmaps retain their club ID; player starters retain supported club context. This additive schema-1 extension requires an app edition that understands competition roadmaps. Older app editions reject these packs; the new edition still accepts legacy club-only JSON. Do not publish version 7 to older binaries without distributing the compatible app.

Competition cards enumerate only required course lessons and objectives. Optional club-context chapters use existing lesson IDs; they share memories and resumes without inflating competition completion. Selection preserves the preferred club used by club comparison. The compiler reads `content/competition-roadmaps.json` and `content/competition-lessons.json`; provenance and licensing are recorded separately in `content/competition-artwork.json`.
