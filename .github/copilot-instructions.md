# Copilot instructions for `container-irrd`

Single image running IRRd and IRR Explorer under s6-overlay. Use this to orient quickly and make safe changes.

## Architecture

- Supervisor: s6-overlay v3; services under `s6-rc.d/`, enabled via `s6-rc.d/user/contents.d/*`.
- IRRd: installed via `pipx install irrd==4.4.4`.
  - Init oneshot: `/opt/irrd/init-irrd.sh` -> `scripts/init-irrd.py` creates DB/role then runs `irrd_database_upgrade`.
  - Longrun: `s6-rc.d/svc-irrd/run` starts `/opt/irrd/bin/irrd --config /opt/irrd/irrd.yaml --foreground`.
- IRR Explorer (FastAPI + frontend via Poetry): pinned source tarball; Poetry install.
  - Init oneshot: `scripts/init-irrexplorer.py` creates DB/role, writes `.env` (DATABASE_URL, IRRD_ENDPOINT, HTTP_PORT/WORKERS, data URLs), and generates supercronic file.
  - Longrun: `s6-rc.d/svc-irrexplorer/run` loads `.env` and starts uvicorn.
- Supercronic: `s6-rc.d/svc-supercronic/run` executes `/usr/local/bin/supercronic /opt/irrexplorer/cron/import-data`.
- External deps: PostgreSQL (`irrd_postgres`), Redis (`irrd_redis`). See `tests/docker-compose.yaml`.
- Config mounts required: `/opt/irrd/irrd.yaml`, `/opt/irrexplorer/irrexplorer.yaml` (see `README.md` for required keys).

## Local build/run (mirrors CI)

- From `tests/`: `docker compose up --detach` then wait (CI uses 300s).
- Verify:
  - IRRd: `curl http://localhost:8080/v1/status` contains "Listening on".
  - IRR Explorer UI: http://localhost:8000/.
- Logs: `docker compose logs irrd`. Shutdown: `docker compose down`.
- Ports: 43 (whois), 8080 (IRRd HTTP/GraphQL), 8000 (Explorer).

## CI/CD

- Tests (`.github/workflows/test.yaml`): build via `tests/docker-compose.yaml`, wait 300s, check IRRd status; run ShellCheck on `*.sh`.
- Publish (`.github/workflows/publish.yaml`): reusable workflow pushes `ghcr.io/mattkobayashi/irrd` on Release.

## Conventions and update points

- Pin and verify versions/hash:
  - Base image digest, Node `NODE_VERSION`, s6-overlay tarballs + `.sha256`, IRRd version, IRR Explorer tarball URL + `IRRE_SOURCE_SHA1SUM`, Poetry version, Supercronic URL + SHA1, compose image digests (Postgres, Redis).
- s6 pattern: `s6-rc.d/<name>/{type,run,up}` with optional `dependencies.d/*`; enable via `user/contents.d/<name>`.
- Config-driven behavior: update `scripts/init-irrexplorer.py` `set_key(...)` when adding new `.env` knobs; `scripts/init-irrd.py` derives DB host/db/creds from `irrd.database_url`.
- Logging: omit `log.logfile_path` in `irrd.yaml` to log to stdout for `docker logs`.

## Key files

- `Dockerfile`, `requirements-*.txt`, `pyproject.toml`; `s6-rc.d/**`, `scripts/*.py|*.sh`; `irrd.yaml`, `irrexplorer.yaml`; `tests/docker-compose.yaml`, `.github/workflows/*.yaml`.
