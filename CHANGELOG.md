# Containers Changelog

## 26.10.1

Status: Draft
Source: Initial working-tree baseline; no accepted release boundary established.
Baseline date: 2026-10-17

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
- Match App `IcsPki:ProvisioningBaseUrl` and Tooling `ICS_OPS_URL` to `https://icsauth.net/ics/ops`, with the configured shared mutation key where required.
