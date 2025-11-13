#!/usr/bin/env sh
cd /opt/irrd/ || exit
uv run python3 init-irrd.py \
&& uv run /opt/irrd/.venv/bin/irrd_database_upgrade --config /opt/irrd/irrd.yaml
