#!/usr/bin/env sh
cd /opt/irrd/ || exit
python3 init-irrd.py \
&& /opt/irrd/bin/irrd_database_upgrade --config /opt/irrd/irrd.yaml
