#!/usr/bin/env sh
# cd /opt/irrexplorer/frontend/ || exit
# /opt/irrexplorer/.venv/bin/poetry run npx update-browserslist-db@latest
cd /opt/irrexplorer/ || exit
/opt/irrexplorer/.venv/bin/poetry run python3 init-irrexplorer.py
/opt/irrexplorer/.venv/bin/poetry run frontend-install
/opt/irrexplorer/.venv/bin/poetry run frontend-build
/opt/irrexplorer/.venv/bin/poetry run alembic upgrade head
