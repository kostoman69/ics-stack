# Containers Changelog

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

Status: Draft
Source: Working tree after the published 26.10.2 (origin/main 112870d); no deployment acceptance recorded.

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
