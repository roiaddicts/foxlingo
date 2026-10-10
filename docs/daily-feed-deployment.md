# Daily feed deployment

All nineteen native daily games consume the verified feed. Firebase project **Foxlingo** (`foxlingo-daily`) and its dedicated default Hosting site are deployed. The live pointer is [daily/latest.json](https://foxlingo-daily.web.app/daily/latest.json). The app uses this address automatically unless a custom feed is saved; deterministic UI tests leave automatic production networking disabled.

On October 10, 2026, fresh source extraction, native preflight, deployment, hosted checksum/cache checks and the app's actual HTTPS downloader verified all nineteen daily modes. Hosting is public and does not require the Mac to remain online for app downloads.

## Prepare a release

Run from the repository on a macOS runner with Python 3 and Swift installed:

```sh
python3 scripts/refresh_daily_futbol11.py --timezone America/Mexico_City
python3 scripts/prepare_daily_feed.py \
  --feed ref/futbol11-daily \
  --output /tmp/foxlingo-daily-release \
  --site SITE_ID
```

Use `foxlingo-daily` for `SITE_ID`. Use a new output directory for each release. Refresh failure must stop the job before preparation or deployment.

Preparation rejects a stale current date in the packet's timezone, invalid checksums, escaping packet paths, missing rollback files and conflicting dates. It validates the exact staged bytes using the app's Core loader: the current packet must support all nineteen native modes; an older rollback may support fewer. A failed preflight produces no publishable release directory. An existing release directory is preserved rather than overwritten.

The prepared directory contains `firebase.json` and only the current packet, optional previous packet and `latest.json` beneath `public/daily`. Provider scripts, archives and credentials are excluded. Preparation never creates a cloud service or deploys anything.

## Publish a fresh daily release

The normal command combines refresh, exact-byte native validation, dedicated-site deployment and verification:

```sh
python3 scripts/publish_daily_feed.py
```

It requires the local Firebase login and Swift compiler. Working feed history and source archives live in ignored `output/daily-feed/`; a process lock prevents overlapping publishers. Temporary release directories are removed after each run. A failed refresh or native preflight stops before deployment. A post-deployment verification failure is reported explicitly; the publisher does not silently label it successful or automatically roll back a potentially completed deployment.

For a manually prepared release, run from that release directory:

```sh
firebase deploy --only hosting --project foxlingo-daily --config firebase.json
```

The configuration names the site explicitly and requires no default project alias. A dedicated site keeps this feed separate from other sites in that project. See Firebase's [multiple-site configuration](https://firebase.google.com/docs/hosting/multisites).

The pointer has `Cache-Control: no-store`; dated digest packets have `public, max-age=31536000, immutable`. Both use JSON content types. These custom headers follow Firebase's [Hosting configuration](https://firebase.google.com/docs/hosting/full-config). Local Hosting emulator checks confirmed both cache policies, packet checksum equality and a 404 for missing files.

After deployment, verify the actual HTTPS pointer, referenced packet and full SHA-256. `scripts/validate_daily.swift --url URL`, when compiled with the app's Core sources, exercises the actual app download path and requires today's nineteen-mode feed. Games → Daily challenge updates can check the default feed manually or use a custom HTTPS address. The app retains its bundled or last good packet when an update fails.

## Automatic updates

A local Codex heartbeat named **Refresh Foxlingo daily games** (`refresh-foxlingo-daily-games`) is active for 00:15 daily in the client's `America/Mexico_City` timezone. It runs the publication command in this checkout and reports failures requiring attention. Successful routine updates stay quiet.

This is local scheduled execution: the Mac and Codex must be available, with Firebase authentication intact. No always-on cloud scheduler or CI runner is deployed. A sleeping or offline Mac can delay publication; the app keeps its last good set. Moving publication to an always-on service remains a separate infrastructure task.

The app checks a configured feed on launch and foreground activation when its installed set is not today's set. Fresh hosted publication still requires the scheduled job to succeed. Provider data freshness and the challenge's calendar date are separate properties.

## Validation

```sh
python3 -m unittest discover -s scripts -p 'test_*.py'
```

Release tests cover exact staged bytes, previous-packet retention, checksum and date rejection, native preflight failure, output preservation and symlink escapes. Actual preparation also compiles and runs the app's native validator; the filesystem tests do not substitute for this preflight.
