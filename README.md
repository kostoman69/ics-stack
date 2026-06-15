# ics-stack Folder Structure

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
