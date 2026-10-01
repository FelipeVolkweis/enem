# 05: Migrate to SparkSubmitOperator and Eliminate Direct Docker Daemon Access

**What to build:** Refactor the Airflow-to-Spark orchestration layer to use the official Apache Airflow Spark Provider (`SparkSubmitOperator`) instead of raw Docker daemon socket access (`/var/run/docker.sock`). Completely eliminate the hardcoded host `DOCKER_GID` and custom Docker SDK calls, containerizing Airflow with Java 17 and Spark client binaries while maintaining Python version and network driver compatibility across the lakehouse network.

**Blocked by:** 04: Upgrade to Airflow 3.3.2, Spark 4.1.3, and Iceberg 1.12.0

**Status:** resolved

- [x] Airflow image extended via `airflow/Dockerfile` to include Java 17 runtime and Spark binaries/JARs.
- [x] Docker Compose configured with `additional_contexts` to reuse `/opt/spark` directly from `enem-spark`, avoiding redundant tarball downloads.
- [x] Direct Docker daemon access (`/var/run/docker.sock`) removed from `docker-compose.yml`.
- [x] Hardcoded `DOCKER_GID` removed from `docker-compose.yml` and `.env`.
- [x] `dags/smoke_test_dag.py` refactored to use `SparkSubmitOperator` with `conn_id="spark_default"`.
- [x] Spark driver network host and bind address explicitly configured for multi-container bridge communication.
- [x] Python minor version aligned between Airflow and Spark images (Python 3.13).
- [x] End-to-end smoke test DAG executes and completes with `success` state.
- [x] Documentation in `README.md` updated to reflect the new orchestration and security architecture.

## Answer

Successfully migrated the orchestration layer from Docker-in-Docker to native Airflow Spark Provider:
- Replaced `docker.from_env()` in `dags/smoke_test_dag.py` with `SparkSubmitOperator`.
- Removed `/var/run/docker.sock` mount and `DOCKER_GID` configuration, hardening container security and ensuring portability.
- Built custom `enem-airflow:3.3.2` image with Java 17, `apache-airflow-providers-apache-spark==6.3.2`, and cached Spark distribution from `enem-spark`.
- Updated `enem-spark` to Python 3.13 to maintain driver/worker serialization compatibility.
- Configured client-mode driver networking (`spark.driver.host=enem-airflow`) and AWS S3 region settings.
- Verified DAG execution end-to-end; both connectivity check and Iceberg Spark verification completed successfully.
