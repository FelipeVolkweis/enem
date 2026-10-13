# Loaded by Superset from PYTHONPATH (/app/pythonpath). Local dev setup: SQLite metadata DB, no Redis/Celery.
import os

SECRET_KEY = os.environ["SUPERSET_SECRET_KEY"]

# Charts, dashboards and users live in the superset_home volume; the dashboards themselves are
# re-imported from ./superset/dashboards on every boot (see bootstrap.sh).
SQLALCHEMY_DATABASE_URI = "sqlite:////app/superset_home/superset.db?check_same_thread=false"

# Trino runs one query at a time (trino/etc/resource-groups.json), so keep chart results for a day
# instead of re-querying on every dashboard load. The marts only change when enem_medallion runs.
DATA_CACHE_CONFIG = {"CACHE_TYPE": "SimpleCache", "CACHE_DEFAULT_TIMEOUT": 86400}

# Plain http on localhost.
TALISMAN_ENABLED = False
