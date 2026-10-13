#!/usr/bin/env bash
# Container entrypoint: prepare the metadata DB and admin user, import the dashboards kept in git,
# then start the stock web server.
set -euo pipefail
shopt -s nullglob

superset db upgrade
superset fab create-admin --username "$SUPERSET_ADMIN_USER" --password "$SUPERSET_ADMIN_PASSWORD" \
    --firstname Admin --lastname User --email admin@localhost
superset init

# Each folder in /app/dashboards is an unzipped Superset export (dashboard + charts + datasets + the
# Trino database). Importing overwrites the copies in the metadata DB, so git is the source of truth.
for bundle in /app/dashboards/*/; do
    zip="/tmp/$(basename "$bundle").zip"
    python - "$bundle" "$zip" <<'PY'
import pathlib, sys, zipfile
src, dst = pathlib.Path(sys.argv[1]), sys.argv[2]
with zipfile.ZipFile(dst, "w") as z:
    for f in sorted(src.rglob("*")):
        if f.is_file():
            z.write(f, pathlib.Path(src.name) / f.relative_to(src))
PY
    superset import-dashboards --path "$zip" --username "$SUPERSET_ADMIN_USER"
done

exec /usr/bin/run-server.sh
