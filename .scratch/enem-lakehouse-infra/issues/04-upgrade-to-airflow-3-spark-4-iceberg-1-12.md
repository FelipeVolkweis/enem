# 04: Upgrade to Airflow 3.3.2, Spark 4.1.3, and Iceberg 1.12.0

**What to build:** Upgrade the entire local Lakehouse stack to the latest modern versions: Apache Airflow 3.3.2, Apache Spark 4.1.3 (Scala 2.13 runtime), and Apache Iceberg 1.12.0 with Hadoop 3.4 AWS runtimes. Ensure all breaking changes in Airflow 3 (FastAPI API-server, SimpleAuthManager credential management, `schedule=None` syntax) and Spark 4 (Scala 2.13 runtime jars) are seamlessly integrated without breaking any dependency chains or smoke test orchestration.

**Blocked by:** 03: Configure Airflow Standalone and End-to-End Orchestration Pipeline

**Status:** resolved

- [x] Spark container is upgraded to `apache/spark:4.1.3` with pre-baked `iceberg-spark-runtime-4.1_2.13:1.12.0`, `iceberg-aws-bundle:1.12.0`, and `hadoop-aws:3.4.2`.
- [x] Airflow container is upgraded to `apache/airflow:3.3.2` running standalone mode with FastAPI API server.
- [x] Airflow credentials provisioned deterministically for Airflow 3's `SimpleAuthManager` via static password configuration.
- [x] `dags/smoke_test_dag.py` updated to use `schedule=None` and `airflow.providers.standard.operators.python.PythonOperator`.
- [x] End-to-end smoke test DAG triggers and completes with status `success` on the upgraded stack.
- [x] `README.md` and environment configurations updated to reflect the new versions and CLI syntax.

## Answer

Successfully upgraded stack to bleeding-edge releases:
- Upgraded Spark to `4.1.3` (Scala 2.13 runtime) with Iceberg `1.12.0` and Hadoop AWS `3.4.2`.
- Upgraded Airflow to `3.3.2` using SimpleAuthManager with deterministic admin credentials.
- Updated `smoke_test_dag.py` to Airflow 3 standards (`schedule=None` and standard provider operators).
- Executed end-to-end verification via Airflow CLI; all tasks passed cleanly.
