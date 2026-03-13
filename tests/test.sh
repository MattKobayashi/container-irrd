#!/usr/bin/env bash
timeout=300
interval=10
end=$((SECONDS+timeout))

apt-get update
apt-get install --no-install-recommends --yes curl

echo "Waiting for IRRd to be ready at http://irrd:8080/v1/status ..."
until curl -fsSLX GET http://irrd:8080/v1/status | grep -q "Listening on"; do
  if (( SECONDS >= end )); then
    echo "IRRd not ready within ${timeout}s" >&2
    exit 1
  fi
  echo "IRRd not ready yet; retrying in ${interval}s..."
  sleep ${interval}
done
echo "IRRd is ready."

echo "Waiting for IRR Explorer to be ready at http://irrd:8000/ ..."
until curl -fsSLX GET http://irrd:8000/ | grep -q "<title>IRR explorer</title>"; do
  if (( SECONDS >= end )); then
    echo "IRR Explorer not ready within ${timeout}s" >&2
    exit 1
  fi
  echo "IRR Explorer not ready yet; retrying in ${interval}s..."
  sleep ${interval}
done
echo "IRR Explorer is ready."
