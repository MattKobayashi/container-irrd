#!/usr/bin/env sh
cd /opt/irrexplorer/ || exit
/opt/irrexplorer/.venv/bin/poetry run python3 init-irrexplorer.py
/opt/irrexplorer/.venv/bin/poetry run frontend-install
/opt/irrexplorer/.venv/bin/poetry run frontend-build
/opt/irrexplorer/.venv/bin/poetry run alembic upgrade head
