# Spec: Local Lakehouse Infrastructure for ENEM Analysis

## Problem Statement

The user needs a local data warehouse and lakehouse infrastructure environment to ingest, store, and analyze the Brazilian ENEM (Exame Nacional do Ensino Médio) educational microdata dataset (~10 GB). Manually setting up and configuring Apache Airflow, Apache Spark, Apache Iceberg, and S3-compatible storage with compatible Java versions, Hadoop AWS bundles, and REST catalog endpoints from scratch is error-prone, prone to dependency conflicts, and burdensome. The user requires a containerized, self-contained local lakehouse infrastructure that boots cleanly and provides immediate end-to-end capability to orchestrate and execute Iceberg table operations.

## Solution

Deploy a multi-container local Lakehouse infrastructure orchestrated via Docker Compose, consisting of:
1. **Apache Airflow** running in Standalone mode for lightweight DAG scheduling and workflow management.
2. **Apache Spark** containerized with pre-cached Iceberg and AWS/Hadoop S3A runtime jars for fast, reliable, offline-capable SQL and DataFrame transformations.
3. **Apache Iceberg REST Catalog** providing the industry-standard REST catalog implementation for ACID transactions, metadata management, and schema tracking.
4. **MinIO** providing local, S3-compatible object storage for Iceberg table data and metadata, paired with an automated provisioning container to initialize the warehouse storage bucket.
5. All component web interfaces mapped to host ports for complete observability.
6. A shared job execution pattern and a verification smoke test DAG demonstrating full end-to-end functionality across Airflow, Spark, the REST Catalog, and MinIO.

## User Stories

1. As a data engineer, I want to start the complete data warehouse infrastructure with a single Docker Compose command, so that I can have an environment ready without manual service configuration.
2. As a data engineer, I want an Apache Airflow environment running in Standalone mode, so that I can orchestrate warehouse pipelines with minimal memory and container overhead.
3. As a data engineer, I want predictable, pre-configured development credentials for Airflow and MinIO, so that I can log into local web consoles without inspecting container logs for generated secrets.
4. As a data engineer, I want an Apache Iceberg REST Catalog running locally, so that table metadata and transactions adhere to open lakehouse standards.
5. As a data engineer, I want an S3-compatible MinIO object store running locally, so that my lakehouse architecture mirrors cloud production environments.
6. As a data engineer, I want the primary MinIO warehouse bucket created automatically on container startup, so that I do not need to manually create buckets before executing queries.
7. As a data engineer, I want Apache Spark to have all required Iceberg and AWS/Hadoop runtime jars pre-installed, so that job execution is fast, stable, and independent of external Maven repositories at runtime.
8. As a data engineer, I want Spark pre-configured to communicate with the Iceberg REST Catalog and MinIO S3 storage, so that I can query and create Iceberg tables using standard Spark SQL syntax out of the box.
9. As a data engineer, I want a shared volume between Airflow and Spark, so that Airflow DAGs can easily dispatch job scripts to the Spark compute engine.
10. As a data engineer, I want access to the Airflow Web UI on a host port, so that I can trigger and monitor pipeline DAG runs.
11. As a data engineer, I want access to the Spark Master and application UIs on host ports, so that I can inspect job stages, query plans, and executor performance.
12. As a data engineer, I want access to the MinIO Web Console on a host port, so that I can browse raw datasets, Parquet files, and Iceberg metadata manifests.
13. As a data engineer, I want access to the Iceberg REST Catalog API on a host port, so that I can query catalog namespaces and table metadata programmatically.
14. As a data engineer, I want a dedicated local directory mounted for raw data, so that I can place local ENEM microdata files directly into the environment for processing.
15. As a data engineer, I want an out-of-the-box verification smoke test DAG and PySpark script, so that I can immediately confirm the entire infrastructure pipeline is healthy.
16. As a data engineer, I want the infrastructure to run comfortably within 8 GB of available system memory, so that it does not crash or starve host system resources.
17. As a data engineer, I want clean shutdown and restart capabilities, so that persisted storage and catalog states remain intact across container restarts.

## Implementation Decisions

- **Container Composition & Networking**:
  The stack will consist of four persistent services (Airflow, Spark, Iceberg REST Catalog, MinIO) and one ephemeral initialization service (MinIO Client `mc`) connected across a dedicated Docker bridge network.
- **Airflow Runtime**:
  Airflow will execute in Standalone mode combining the scheduler, webserver, and internal state into a single container process. Default admin credentials will be pre-configured at launch.
- **Compute Engine Isolation**:
  Spark will run in a standalone container derived from a customized image containing the Iceberg Spark runtime and S3A client dependencies. Airflow will trigger Spark tasks using shared job scripts, maintaining clear separation of Python environments and dependencies between orchestrator and compute engine.
- **Catalog Architecture**:
  The REST catalog will implement the official Iceberg REST specification, exposing REST endpoints on port 8181 and referencing the MinIO warehouse bucket for table warehouse roots.
- **Storage & Bucket Provisioning**:
  MinIO will provide S3-compliant object storage. An auxiliary initialization service will configure aliases and ensure the `warehouse` bucket exists before any workload executes.
- **Observability**:
  All major ports (Airflow Web UI, Spark Master UI, Spark App UI, MinIO S3 API, MinIO Console, Iceberg REST API) will be mapped to localhost on the host machine.
- **Project Structure**:
  The project will define separate mount points for DAGs, Spark job scripts, logs, raw data, and persistent storage volumes, cleanly separating code from data.

## Testing Decisions

- **Testing Principle**: Tests must evaluate external system behavior only, never internal container implementations or ephemeral process state.
- **Tested Modules**: The complete integrated system (Airflow scheduler -> Spark job execution -> Iceberg REST Catalog registration -> MinIO object write and read-back).
- **Test Implementation**:
  An end-to-end smoke test DAG in Airflow executing a PySpark script. The script creates an Iceberg table in the catalog, appends sample records, and executes a SQL read verifying record count and schema. Success of the test DAG confirms full stack operational readiness.
- **Prior Art**: Standard Lakehouse and Iceberg integration test patterns used in Apache Iceberg and Tabular reference architectures.

## Out of Scope

- Production high-availability deployments (e.g., multi-node Celery workers, Kubernetes executors, multi-worker distributed Spark clusters).
- Ingestion, parsing, or transformation logic specific to the ENEM dataset (raw microdata ingestion DAGs, data cleansing, medallion architecture transformations).
- External cloud provider catalog/storage integrations (AWS Glue, AWS S3, GCP BigLake, Snowflake).
- BI, semantic layer, or reporting dashboard tools (e.g., Superset, Metabase, Evidence).

## Further Notes

- Memory footprint across all services is estimated at ~3.5 to 4.5 GB RAM, fitting within the host's 8.1 GB available memory.
