#!/usr/bin/env sh
cd /opt/irrexplorer/ || exit
/opt/irrexplorer/bin/poetry run python3 init-irrexplorer.py
/opt/irrexplorer/bin/poetry run frontend-install
/opt/irrexplorer/bin/poetry run frontend-build
/opt/irrexplorer/bin/poetry run alembic upgrade head
