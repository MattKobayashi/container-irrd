#!/usr/bin/env sh
cd /opt/irrd/ || exit
/opt/irrd/.venv/bin/python3 init-irrd.py \
&& /opt/irrd/.venv/bin/irrd_database_upgrade --config /opt/irrd/irrd.yaml
