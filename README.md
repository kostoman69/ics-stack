# Containers Folder Structure

This folder contains all containerization assets for this project. Use this as the universal, portable structure for all future projects.

## Structure Overview

```
Containers/
├── composer/
│   ├── orchestrations/          # Project-level orchestrations (multiple environments)
│   │   ├── dev/
│   │   │   ├── docker-compose.yml
│   │   │   └── Caddyfile
│   │   ├── qa/
│   │   └── prod/
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

### Running the Dev Environment

```bash
cd Containers/composer/orchestrations/dev/
docker-compose up -d
```

### Cloning Only This Folder

To clone **only the Containers folder** from the repository (useful for deploying to servers):

```bash
git clone --filter=blob:none --sparse https://ksenofon.ics.forth.gr/DefaultCollection/CeHA/_git/ICS
cd ICS
git sparse-checkout set Containers
```

This will download only the `Containers/` folder, significantly reducing bandwidth and disk usage.

## Conventions

- All paths are relative; you can copy/move this folder anywhere.
- Do not prefix with project name; this folder is meant to be reusable.
- Service-level compositions should be self-contained and portable.
- Orchestration files wire services together for specific environments.

---

**Adopt this structure for all containerized projects for consistency and portability.**
