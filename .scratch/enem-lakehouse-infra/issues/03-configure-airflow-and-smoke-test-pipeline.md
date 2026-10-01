# 03: Configure Airflow Standalone and End-to-End Orchestration Pipeline

**What to build:** An Apache Airflow service running in lightweight Standalone mode with pre-configured administrative credentials, host UI accessibility, and a verification smoke test DAG. The DAG triggers the PySpark Iceberg job on the Spark engine across the shared execution seam, validating the full end-to-end chain from orchestrator down to catalog and object store.

**Blocked by:** 02: Build Spark Container with Pre-baked Iceberg & S3A Runtimes

**Status:** resolved

- [x] Airflow service is declared in `docker-compose.yml` running in Standalone mode with the Web UI exposed on host port 8080.
- [x] Airflow admin user is pre-configured with default credentials (`admin`/`admin`) defined in `.env` without manual container log inspection.
- [x] Mount points for `./dags`, `./logs`, `./jobs`, and `./data` are connected to the Airflow container.
- [x] A verification smoke test DAG is present in `./dags/` that submits and monitors the PySpark Iceberg job execution on the Spark engine.
- [x] Triggering the smoke test DAG runs to completion with a success state, proving full interoperability across Airflow, Spark, Iceberg REST Catalog, and MinIO.
- [x] A `README.md` is provided documenting stack startup, teardown, service ports, credential management, and test execution commands.

## Answer

Configured Apache Airflow 2.10.5 in Standalone mode and verified end-to-end orchestration:
- Added `airflow` service to `docker-compose.yml` with host port 8080, mounting `./dags`, `./logs`, `./jobs`, `./data`, and `/var/run/docker.sock` with docker group permissions.
- Created `airflow/entrypoint.sh` to run db migration and automatically create admin credentials (`admin`/`admin`).
- Created `dags/smoke_test_dag.py` with tasks to verify service connectivity and trigger `jobs/test_iceberg.py` inside `enem-spark`.
- Triggered DAG run via Airflow; all tasks succeeded, creating and verifying the Iceberg table in MinIO and REST Catalog.
- Provided comprehensive `README.md` documentation covering setup, ports, credentials, and verification steps.
