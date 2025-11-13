#!/usr/bin/env sh
cd /opt/irrexplorer/ || exit
uv run /opt/irrd/.venv/bin/poetry run python3 init-irrexplorer.py
uv run /opt/irrd/.venv/bin/poetry run frontend-install
uv run /opt/irrd/.venv/bin/poetry run frontend-build
uv run /opt/irrd/.venv/bin/poetry run alembic upgrade head
