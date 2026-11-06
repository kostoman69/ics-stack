# Containers Changelog

## 26.11.1 — 2026-11-07

Status: Draft
Source: After Containers commit c492197 (26.10.7); ICS theme and image-task integration verified locally. No deployment acceptance recorded.

### Changes

- Add dedicated ICS workspace Keycloak build/export/copy/deploy/rollback tasks. Compile the theme locally, validate the ICS login/email JAR, and embed it before optimized Keycloak construction in component image `keycloak:26.7.4-r2`; never rebuild an existing component tag.
- Support protected `ICS_KEYCLOAK_IMAGE` selection, retaining `keycloak:26.7.4-r1` as fallback until an explicit deployment. Keycloak is image-only in Compose; its themed build uses a staged context from the ICS workspace.
- Validate archive checksum, image identity/version, target architecture and Compose ownership before replacement. Recreate only Keycloak with `--no-deps --no-build`; retain the old image identity for an explicit rollback without reloading Caddy or recreating other live services.
- Start the ICS Keycloak theme project in the ICS repository at `icsOps/Keycloak/ics-theme`, using Keycloakify 11, React, TypeScript, Vite and Storybook. Login and email themes share the name `ICS`; the Account and Admin Consoles are outside scope.
- Document local development and JAR packaging for the Keycloak 26.7.4 target. The development foundation and shared browser chrome are implemented; remaining workflow/mobile and native-email acceptance are task work.
- Correct the Containers README's current release identity.
- Apply the App login chrome across Keycloakify login forms: clinician backgrounds, ICS logo, partner footer, responsive panels and interaction/reduced-motion-aware slides. Greek mock contexts and ICS text support local form review; native email styling remains pending.
- Space labels above the white outer focus frames; password focus frames surround both the field and visibility button, with a distinct button background for keyboard focus.
- Integrate the centered eye button into the shared password field surface using adjacent flex items, keeping it visible while typing and focused.
- Reveal passwords only while the eye or Space/Enter is held; release, cancellation, focus loss and document visibility changes restore masking. Replace the upstream visibility hook through a narrow Vite alias and add a regression interaction story.
- Place the centered, bold italic “Κεντρική είσοδος” heading immediately below the italic Greek tagline on every login-theme page, including pages where the upstream title block is conditional.
- Verification: independent frozen-lockfile restore, TypeScript/Vite, static Storybook and login/email JAR packaging passed; archive contents inspected. Login, password-update, MFA and invalid-credential previews inspected in Chrome; a validation contrast issue was fixed. Node 22 live Storybook startup passed. Mobile and live Keycloak workflows remain unverified.
- Image-task verification: 13 offline command tests pass; actual linux/amd64 r2 image built, embedded JAR/hash and Keycloak26.7.4 version inspected, archive exported/validated. Spec/Standards review findings resolved. Placeholder-only Compose validation passed; no remote rollout or workflow acceptance claimed.

### Breaking changes

None.

### Deployment

Propagate reviewed Containers changes to the release-server checkout before running the Keycloak deployment task; the task does not push or pull Git. Build/export locally, then copy/deploy with SSH authentication. The new selector is required and preserves protected `.env` settings. Keycloak restarts briefly; other services are not recreated. Login/email theme selection is a separate action limited to the agreed `ics-theme-test` realm. No remote rollout or realm setting change is recorded.

### Compatibility

User-authenticated inspection confirmed the server runs Keycloak 26.7.4/r1 on amd64. The local r2 image matches that target; workflow and email acceptance remain unverified. The default remains r1; explicit themed delivery selects r2. Operations and other component selectors are unchanged.

---

## 26.10.7 — 2026-10-28

Status: Draft
Source: Working tree after the published 26.10.6 (origin/main a5ca3a9); no deployment acceptance recorded.

### Changes

- Select Operations `26.10.11` instead of `26.10.10`.
- Remove the `/operations` Caddy route: Operations has no browser pages any more.
- Forward `ICS_OPS_OPERATOR_ISSUER` instead of the five `ICS_OPS_DASHBOARD_*` variables (compose and `.env.example`).
- README and script comments describe ITO as the only GUI.

### Breaking changes

- `/operations/**` is no longer routed. The `ICS_OPS_DASHBOARD_*` variables are no longer forwarded.

### Deployment

- `git pull` on the server, delete the `ICS_OPS_DASHBOARD_*` lines from the protected `.env`, deploy Operations 26.10.11. `docker compose config` resolves; the Caddyfile was not validated locally (needs the custom Caddy image).

---

## 26.10.6 — 2026-10-27

Status: Draft
Source: Working tree after the published 26.10.5 (origin/main 414ee58); no deployment acceptance recorded.

### Changes

- Select Operations `26.10.10` instead of `26.10.9`.
- Fix: `artifact-retention-apply.py` reads JSON BOM-tolerant (`VERSION.json` and manifests are written with a BOM by the build pipeline).
- Safety net: `artifact-retention-apply.py` never deletes more than half of a release root's build folders in one run, whatever the request lists; it records the refused root in `result.json` and exits 1.

### Breaking changes

None.

### Deployment

- `git pull` on the server; the cron line is unchanged. Covered by the Operations test suite (host-script tests); not yet run on the server.

---

## 26.10.5 — 2026-10-27

Status: Draft
Source: Working tree after the published 26.10.4 (origin/main a2be659); no deployment acceptance recorded.

### Changes

- Select Operations `26.10.9` instead of `26.10.8`.
- New `composer/service-level/ics-operations/artifact-retention-apply.py` (root cron, every 10 minutes): executes the build retention run Operations requested in `/data/ics/retention/request.json`, checks every folder again (known root, build folder name, real folder inside the root, not `latest.json`, not the compatibility bridge, not pinned), deletes, rebuilds `versions.json` and writes `result.json`. Python 3 standard library only.
- New `composer/service-level/ics-operations/ics-versions-index.sh`: the one `versions.json` rebuild for every writer; the publish pipeline uploads a copy next to each root's `latest.json`, the retention script uses the copy in this checkout. Writes next to the old index and renames it; mode 644, owner of the root folder when run as root.
- `icsops` mounts `/data/ics/11-desk` and `/data/ics/11-tooling` read-only and `/data/ics/retention` read-write, and forwards `ICS_OPS_RETENTION_KEEP_LINES` (5) and `ICS_OPS_RETENTION_AUTO` (false).
- Container log limits (`json-file`, 3 × 10 MB) for `postgres`, `keycloak`, `caddy`, `openbao` and `icsops`, so container logs cannot fill the disk.

### Breaking changes

None.

### Deployment

- On the server: `sudo mkdir -p /data/ics/retention`, add the cron line from the script header to root's crontab; recreate the containers (`docker compose up -d`) for the log limits to apply.
- Scripts checked in an Ubuntu 24.04 container as root (dash `sh`, ownership kept) and by the Operations test suite; `docker compose config` resolves the orchestration. Not yet run on the server.

---

## 26.10.4 — 2026-10-24

Status: Draft
Source: Working tree after the published 26.10.3 (origin/main 05b7d76, fb1e74b); no deployment acceptance recorded.

### Changes

- Select Operations `26.10.8` instead of `26.10.6`.
- New `composer/service-level/ics-operations/host-disk-report.sh`: run from the server's root cron every 30 minutes, it writes the root filesystem's largest folders (two levels, `du -x`) and `docker system df` (with reclaimable space) to `/data/ics/host-report/disk-report.json`. It only measures; it never deletes.
- Mount `/data/ics/host-report` read-only into `icsops` and forward `ICS_OPS_HOST_DISK_REPORT`, so the dashboard can show where the rest of the disk goes without giving the container access to the host.

### Deployment

- On the server: `sudo mkdir -p /data/ics/host-report`, run the script once by hand, then add the cron line from the script header to root's crontab.
- Needs GNU `du`/`df` (coreutils) on the host; checked in an Alpine container with coreutils and a stub `docker`, valid JSON output. Not yet run on the server.

---

## 26.10.3 — 2026-10-23

Status: Sealed
Source: Containers commit 05b7d76 (changelog headings fb1e74b), pulled and deployed on icsauth.net on 2026-10-23 with Operations 26.10.6; accepted by the user.

### Changes

- Select Operations `26.10.6` instead of `26.10.5` (tickets for CeHA Ops).
- Mount `/data/ics/tickets` into `icsops` for the tickets database and attachments, and forward `ICS_OPS_TICKETS_ROOT`, `ICS_OPS_TICKETS_ATTACHMENT_RETENTION_DAYS` (default 180) and `ICS_OPS_TICKETS_AUDIENCE` (default `ics-operations`).

### Deployment

- Create `/data/ics/tickets` on the server before recreating `icsops` (the container runs as root). Without the mount the tickets would live in the container and be lost on the next redeploy.
- Back up `tickets.db` (SQLite backup API) and `files/` daily; see Operations / working / Operations tickets §8.
- Keycloak: realm role `ito_triage` and the `operations-tickets-audience` mapper on `ics-ito` (ICS repository `icsOps/Keycloak/clients/README.md` §5).
- `docker compose config --quiet` passes locally for `keycloak-artifact-server-openbao` (secrets unset); not yet run on the server.

---

## 26.10.2 — 2026-10-19

Status: Draft
Source: Stack changes in 8e505f1..8263f5e plus release-metadata/documentation corrections; no deployment acceptance recorded.

### Changes

- Select Operations `26.10.5` instead of `26.10.3`.
- Route `/operations` and its child paths to the dashboard without stripping the path. Forward its Keycloak/OIDC and health-probe settings; leave sign-in disabled until the dedicated client is configured.
- Block the internal Caddy certificate-approval callback at the public `/ics/ops` proxy while preserving Caddy's direct internal callback.
- Remove the machine-key header and OIDC callback code/state values from Caddy access logs; disable duplicate raw Uvicorn access logging.

### Breaking changes

- Require a nonempty `ICS_OPS_API_KEY` before Compose deployment. Configure matching App, Tooling and Linux machine credentials before switching to Operations 26.10.5; sensitive reads, downloads, preflight and mutations now require them.

### Deployment

- Update `/home/administrator/ics-stack` to this stack revision before deploying the existing `icsops:26.10.5` image. Configure the protected environment and dedicated Keycloak client before enabling dashboard sign-in.
- Compose validation passed. Callback routing and log filtering passed in a disposable local Caddy 2.11.1 runtime; production Caddy 2.11.4-r1 validation and live deployment acceptance remain pending.
- This release updates stack configuration and metadata; it does not rebuild the Operations image or establish successful deployment.

### Compatibility

- Source documentation correction: configure the App client through `IcsOperations:BaseUrl` and `IcsOperations:ApiKey`; the selected Operations image is not rebuilt.

- Containers version `26.10.2` selects Operations image `icsops:26.10.5`; the two products keep independent versions.
- Existing certificate storage and volumes are preserved. Existing machine callers must supply the shared key.

---

## 26.10.1 — 2026-10-17

Status: Draft
Source: Initial working-tree baseline; no accepted release boundary established.

This first entry records the current stack configuration, not changes reconstructed from earlier releases.

### Changes

- Define the shared release-server stack: Keycloak, PostgreSQL, Caddy, OpenBao and ICS Operations Service.
- Serve release artifacts and the bootstrap page through Caddy alongside Keycloak and OpenBao API/UI routing.
- Route Operations through `/ics/ops` and Caddy certificate callbacks through `icsops:8787`.
- Coordinate Cloudflare DNS-01 certificate issuance with the Operations target-approval endpoint and shared Caddy certificate storage.
- Configure Operations with `ICS_OPS_*` variables while preserving certificate/archive and named-volume storage.
- Track the stack's independent version in `version.json` and release changes in this file.

### Breaking changes

- Deploy the Operations service identity, proxy routes, environment configuration and matching clients together. Existing client URL overrides must target `/ics/ops`.

### Deployment

- Propagate the reviewed stack to the release-server `ics-stack` checkout before running the Operations image-deployment task. Configure its protected environment using the full-stack template.
- Compose model validation and unchanged certificate-storage checks passed locally. Live deployment and Caddy runtime validation remain pending; no accepted stack commit is recorded.
- Preserve named volumes and bind-mounted certificate data. Never use `down -v` for this deployment.
- Use the full `keycloak-artifact-server-openbao` orchestration and its protected `.env`; the image task does not synchronize this separate Git repository.

### Compatibility

- Current source selections: `keycloak:26.7.4-r1`, `caddy:2.11.4-r1`, `openbao/openbao:2.5.4`, `icsops:26.10.3`.
- PostgreSQL currently uses `postgres:latest`. This is a floating reference, not evidence of a reproducible accepted image set; its deployed identity has not been verified for this draft.
- Match the App service URL and Tooling `ICS_OPS_URL` to `https://icsauth.net/ics/ops`, with the configured shared mutation key where required.
