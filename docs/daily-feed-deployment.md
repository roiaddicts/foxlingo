# Daily feed deployment

All nineteen native daily games consume the verified feed. Release preparation is implemented and tested; public hosting and recurring execution are still unconfigured. A Firebase project and dedicated Hosting site must be selected before deployment. `foxlingo-daily` below is a proposed site ID, not a provisioned service.

## Prepare a release

Run from the repository on a macOS runner with Python 3 and Swift installed:

```sh
python3 scripts/refresh_daily_futbol11.py --timezone America/Mexico_City
python3 scripts/prepare_daily_feed.py \
  --feed ref/futbol11-daily \
  --output /tmp/foxlingo-daily-release \
  --site SITE_ID
```

Replace `SITE_ID` with the selected dedicated site. Use a new output directory for each release. Refresh failure must stop the job before preparation or deployment.

Preparation rejects a stale current date in the packet's timezone, invalid checksums, escaping packet paths, missing rollback files and conflicting dates. It validates the exact staged bytes using the app's Core loader: the current packet must support all nineteen native modes; an older rollback may support fewer. A failed preflight produces no publishable release directory. An existing release directory is preserved rather than overwritten.

The prepared directory contains `firebase.json` and only the current packet, optional previous packet and `latest.json` beneath `public/daily`. Provider scripts, archives and credentials are excluded. Preparation never creates a cloud service or deploys anything.

## Deploy after selecting the project and site

Create or select a dedicated Hosting site belonging to the chosen Firebase project. Then, from the prepared release directory:

```sh
firebase deploy --only hosting --project PROJECT_ID --config firebase.json
```

The configuration names the site explicitly and requires no default project alias. A dedicated site keeps this feed separate from other sites in that project. See Firebase's [multiple-site configuration](https://firebase.google.com/docs/hosting/multisites).

The pointer has `Cache-Control: no-store`; dated digest packets have `public, max-age=31536000, immutable`. Both use JSON content types. These custom headers follow Firebase's [Hosting configuration](https://firebase.google.com/docs/hosting/full-config). Local Hosting emulator checks confirmed both cache policies, packet checksum equality and a 404 for missing files.

After deployment, verify the actual HTTPS pointer at `https://SITE_ID.web.app/daily/latest.json`, download its referenced packet and check the full SHA-256. Connect that address in Games → Daily challenge updates and verify installation on the app. The app retains its bundled or last good packet when an update fails.

## Automatic updates

No scheduler or CI workflow is deployed. Configure a macOS job only after the project, dedicated site and production endpoint are verified. Run refresh, preparation and deployment sequentially; every unsuccessful step must prevent the next. Retain feed history between runs so the previous packet remains available for rollback. Select a unique staging directory per run, and schedule against `America/Mexico_City` rather than the runner's default timezone.

The app checks a configured feed on launch and foreground activation when its installed set is not today's set. Fresh hosted publication still requires the scheduled job to succeed. Provider data freshness and the challenge's calendar date are separate properties.

## Validation

```sh
python3 -m unittest discover -s scripts -p 'test_*.py'
```

Release tests cover exact staged bytes, previous-packet retention, checksum and date rejection, native preflight failure, output preservation and symlink escapes. Actual preparation also compiles and runs the app's native validator; the filesystem tests do not substitute for this preflight.
