# 03: Configure Airflow Standalone and End-to-End Orchestration Pipeline

**What to build:** An Apache Airflow service running in lightweight Standalone mode with pre-configured administrative credentials, host UI accessibility, and a verification smoke test DAG. The DAG triggers the PySpark Iceberg job on the Spark engine across the shared execution seam, validating the full end-to-end chain from orchestrator down to catalog and object store.

**Blocked by:** 02: Build Spark Container with Pre-baked Iceberg & S3A Runtimes

**Status:** ready-for-agent

- [ ] Airflow service is declared in `docker-compose.yml` running in Standalone mode with the Web UI exposed on host port 8080.
- [ ] Airflow admin user is pre-configured with default credentials (`admin`/`admin`) defined in `.env` without manual container log inspection.
- [ ] Mount points for `./dags`, `./logs`, `./jobs`, and `./data` are connected to the Airflow container.
- [ ] A verification smoke test DAG is present in `./dags/` that submits and monitors the PySpark Iceberg job execution on the Spark engine.
- [ ] Triggering the smoke test DAG runs to completion with a success state, proving full interoperability across Airflow, Spark, Iceberg REST Catalog, and MinIO.
- [ ] A `README.md` is provided documenting stack startup, teardown, service ports, credential management, and test execution commands.
