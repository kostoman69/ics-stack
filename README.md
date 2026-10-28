# ics-stack Folder Structure

## Release identity

`version.json` owns this stack's independent calendar version, currently `26.10.2`. `CHANGELOG.md`
records changes, breaking changes, deployment and compatibility in one file. Individual container
images retain their own versions. Each stack release has its own section; the 26.10.1 entry is
preserved below the 26.10.2 changes. Draft status does not establish deployment acceptance.

When working from the ICS repository, use `containers update changelog extend` or
`containers update changelog seam and bump version`. Authoritative action definitions are in
`.github/instructions/operations-releases.instructions.md` in that repository. Sealing requires
the accepted commit from this separate Containers repository, not a commit from its parent checkout.

This repository contains all containerization assets for this project. Use this as the universal, portable structure for all future projects.

## Structure Overview

```
ics-stack/
├── composer/
│   ├── orchestrations/          # Project-level orchestrations (multiple environments)
│   │   ├── keycloak-artifact-server/
│   │   └── keycloak-artifact-server-openbao/
│   └── service-level/           # Service-level compositions (atomic service groups)
│       ├── keycloak/            # Keycloak stack (keycloak + caddy + postgres)
│       ├── caddy/               # Caddy reverse proxy
│       └── registry/            # Container registry
├── images/                      # All image build contexts
│   └── keycloak/
│       └── Dockerfile
├── env/                         # Environment-specific overrides
├── scripts/                     # Helper scripts
└── README.md
```

## Usage

### Running an Orchestration

For the release server, follow the ordered deployment section below. For an already prepared
environment with its required images, secrets, volumes and network available:

```bash
cd composer/orchestrations/keycloak-artifact-server-openbao/
docker compose up -d
```

### Cloning From GitHub

To clone the repository from GitHub:

```bash
git clone https://github.com/kostoman69/ics-stack.git
cd ics-stack
```

If you only need part of the repository, you can enable sparse checkout after cloning.

## Conventions

- All paths are relative; you can copy/move this folder anywhere.
- Do not prefix with project name; this folder is meant to be reusable.
- Service-level compositions should be self-contained and portable.
- Orchestration files wire services together for specific environments.

---

**Adopt this structure for all containerized projects for consistency and portability.**

## Operations Service

The full orchestration includes `icsops`, an image-based ICS Operations Service at port 8787.
Its service definition is `composer/service-level/ics-operations/docker-compose.yml`; image
selection uses `ICS_OPS_IMAGE=icsops:26.10.11`. The public Caddy prefix is `/ics/ops`.

Operations has no screens of its own: ITO is its only GUI and calls the API under `/ics/ops`. Calls made for a person
carry the operator's access token from `ICS_OPS_OPERATOR_ISSUER`, with the custom audience `ics-operations`
(`icsOps/Keycloak/clients/README.md`).

The application image is built from `icsOps/Forth.Ics.Operations` in the ICS source repository.
Propagate this container repository to the release-server checkout before running the Operations
image deployment task. The task never pushes or pulls this repository. Keep the protected stack
`.env` configured with `ICS_OPS_*` variables and existing `ICS_OPENBAO_*` credentials. Named volumes
and certificate/config bind mounts must be preserved.

Procedure: Operations / working / ICS Operations Service deployment.

## Release-server deployment

### 1. Publish the reviewed stack and update the server checkout

This folder is a separate Git repository. After its reviewed changes have been committed and
pushed to `ics-stack`, run on the release server:

```sh
cd /home/administrator/ics-stack
git status --short
git pull --ff-only
# It reads version.json in the current directory and prints its "version" value.
python3 -c 'import json; print(json.load(open("version.json"))["version"])'
```

Resolve local configuration-source changes before pulling; do not discard them or overwrite a
protected environment file to make the pull succeed. Updating the parent ICS repository alone
does not update this checkout. The Operations image task does not push/pull it either.

### 2. Prepare the protected environment

```sh
cd composer/orchestrations/keycloak-artifact-server-openbao
test -f .env || install -m 600 .env.example .env
```

Edit `.env` with the real deployment values before continuing. Preserve existing database/admin,
Cloudflare and OpenBao credentials. Configure `ICS_OPS_IMAGE=icsops:26.10.11`, the actual
`ICS_OPS_PLATFORM`, the `/ics/ops` public base URL, the intended ACME policy and the required `ICS_OPS_API_KEY`. Configure matching App, Tooling
and Linux machine credentials before rollout; sensitive reads and downloads now require them. The template is a checklist, not a file to copy over an existing live `.env`.
Do not commit or print secrets. Keep OpenBao unsealed for Operations readiness.

```sh
docker compose config --quiet
docker compose config --services
```

Expect `keycloak`, `postgres`, `caddy`, `openbao` and `icsops`. Review every service before using
`--remove-orphans`: it removes project containers absent from this full orchestration.
Keep the existing `ics-network`, named volumes, target catalog and certificate archives. On a
fresh host, create the external `ics-network` and `icscert-volume` and follow the complete
OpenBao/bootstrap runbook before expecting the stack to be ready.

### 3. Make images available and apply the intended services

For this Operations rollout, first complete the image build/export/copy/deploy steps in
`icsOps/Forth.Ics.Operations/README.md` from the ICS repository. Its deployment script recreates
`icsops`, applies/reloads Caddy, and verifies the new service. It does not deliberately restart
Keycloak, PostgreSQL or OpenBao. Caddy recreation briefly interrupts proxied routes.

For a separate full-stack update, after every selected image has been built, loaded or pulled
as appropriate, run from the server orchestration directory:

```sh
docker compose up -d --remove-orphans
docker compose exec -T caddy caddy validate --config /etc/caddy/Caddyfile
docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile
docker compose ps
```

A full-stack update may recreate Keycloak and other changed services; schedule the interruption.
Do not use `down -v`. Image selection and the stack version are independent: changing
`version.json` does not build, load or deploy any image.

### 4. Verify and retain rollback material

```sh
curl --fail --silent --show-error https://icsauth.net/ics/ops/version -H "X-ICS-OPS-Key: ${ICS_OPS_API_KEY:?Set the protected Operations key}"
curl --fail --silent --show-error https://icsauth.net/ics/ops/health/ready -H "X-ICS-OPS-Key: ${ICS_OPS_API_KEY:?Set the protected Operations key}"
```

Expect Operations version `26.10.11` and readiness `ok`. Verify Keycloak login, OpenBao availability,
artifact downloads and the matching App/Tooling clients. Keep the preceding accepted stack
revision, protected configuration backups and images. Roll back matched stack/proxy/client
configuration together when their contract changes; restore data only through the appropriate
database/OpenBao backup procedure, never by deleting volumes.

Host disk report (ITO «Πού πάει ο υπόλοιπος δίσκος»): `sudo mkdir -p /data/ics/host-report`, run
`composer/service-level/ics-operations/host-disk-report.sh` once as root, then add the cron line from its header
to root's crontab. It writes `/data/ics/host-report/disk-report.json`, which `icsops` mounts read-only.

Build retention (ITO «Διατήρηση builds»): `sudo mkdir -p /data/ics/retention`, then add the cron line from the header
of `composer/service-level/ics-operations/artifact-retention-apply.py` to root's crontab. It executes the run requests
that `icsops` writes there, checks each folder again, deletes and rebuilds `versions.json` with
`ics-versions-index.sh` beside it. Operations / working / Build retention on the release server.

Full operational context: Operations / working / ICS Operations Service deployment and
Containers / working / ICS Release Server Container Stack.
