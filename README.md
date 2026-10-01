# ENEM Lakehouse & Data Warehouse Infrastructure

A containerized, local modern Lakehouse/Data Warehouse stack running **Apache Airflow 2.10.5**, **Apache Spark 3.5.3**, **Apache Iceberg (REST Catalog)**, and **MinIO (S3-compatible Object Storage)**.

Designed for developing local data pipelines and analytical workloads on datasets such as Brazilian ENEM (Exame Nacional do Ensino Médio) microdata.

---

## 🏛 Architecture Overview

| Component | Service Name | Image | Role | Port(s) |
| :--- | :--- | :--- | :--- | :--- |
| **Airflow** | `enem-airflow` | `apache/airflow:2.10.5` | Standalone DAG orchestration & workflow scheduling | `8080` (Web UI) |
| **Spark Engine** | `enem-spark` | `enem-spark:3.5.3` (Custom) | Pre-baked with Iceberg runtime & Hadoop S3A jars; Spark Master & Worker | `8081` (Master UI)<br>`4040` (App UI)<br>`7077` (Cluster Master) |
| **Iceberg Catalog** | `enem-iceberg-rest` | `tabulario/iceberg-rest:latest` | Open Iceberg REST Catalog managing ACID table commits | `8181` (REST API) |
| **Object Store** | `enem-minio` | `cgr.dev/chainguard/minio:latest` | S3-compatible local lakehouse storage | `9000` (S3 API)<br>`9001` (Web Console) |
| **Bucket Provisioner**| `enem-minio-init` | `cgr.dev/chainguard/minio-client:latest`| Auto-creates `warehouse` bucket on initial boot | — |

---

## 📂 Project Structure

```text
.
├── .env                      # Centralized environment variables, credentials, and ports
├── docker-compose.yml        # Multi-container lakehouse orchestration
├── spark/
│   ├── Dockerfile            # Spark 3.5.3 + Iceberg & S3A jars pre-baked
│   ├── entrypoint.sh         # Starts Spark Master and Worker daemons
│   └── spark-defaults.conf   # Pre-configured REST catalog and MinIO S3 credentials
├── airflow/
│   └── entrypoint.sh         # Standalone Airflow bootloader and user provisioner
├── dags/
│   └── smoke_test_dag.py     # Verification DAG triggering the Spark Iceberg job
├── jobs/
│   └── test_iceberg.py       # PySpark verification script (creates table, inserts, verifies)
├── data/                     # Host mount directory for your raw ENEM CSV/ZIP files
├── logs/                     # Airflow execution logs
└── README.md                 # This guide
```

---

## 🚀 Quickstart

### 1. Start the Stack

```bash
docker compose up -d
```

### 2. Verify Services

Check container status:
```bash
docker compose ps
```

All services will show `Up` (with `enem-minio-init` exiting cleanly with `0` after creating the `warehouse` bucket).

### 3. Service Access & Default Credentials

| Service | URL | Default Credentials |
| :--- | :--- | :--- |
| **Airflow Web UI** | [http://localhost:8080](http://localhost:8080) | Username: `admin`<br>Password: `admin` |
| **MinIO Console** | [http://localhost:9001](http://localhost:9001) | Username: `admin`<br>Password: `password123` |
| **MinIO S3 Endpoint**| [http://localhost:9000](http://localhost:9000) | S3 Access: `admin` / `password123` |
| **Spark Master UI** | [http://localhost:8081](http://localhost:8081) | None |
| **Iceberg REST API** | [http://localhost:8181/v1/config](http://localhost:8181/v1/config) | None |

---

## 🧪 Running the Verification Smoke Test

### Option A: Via Airflow CLI

Trigger the verification DAG from inside the Airflow container:

```bash
docker exec enem-airflow airflow dags trigger iceberg_lakehouse_smoke_test
```

Monitor the run:
```bash
docker exec enem-airflow airflow dags list-runs -d iceberg_lakehouse_smoke_test
```

### Option B: Via Airflow Web UI

1. Open [http://localhost:8080](http://localhost:8080) in your browser.
2. Sign in with `admin` / `admin`.
3. Locate `iceberg_lakehouse_smoke_test` and click the **Trigger DAG** button (Play icon).
4. Inspect the task logs for `run_spark_iceberg_pipeline` to see the live Iceberg table creation, insert, and select execution.

### Option C: Directly via Spark

Run the PySpark script directly inside the Spark container:

```bash
docker exec -it enem-spark /opt/spark/bin/spark-submit /opt/spark/jobs/test_iceberg.py
```

---

## 📊 Inspecting Iceberg Data in MinIO

To view the raw Parquet and metadata files written to MinIO:
1. Open the MinIO Console at [http://localhost:9001](http://localhost:9001) (`admin` / `password123`).
2. Navigate to **Buckets** -> `warehouse`.
3. Inspect `enem_dw/smoke_test/data/` (partitioned Parquet files) and `enem_dw/smoke_test/metadata/` (`.metadata.json` and Avro manifest files).

---

## 🛑 Stopping and Cleaning Up

- **Stop services** (preserving data):
  ```bash
  docker compose down
  ```

- **Stop services and reset warehouse data**:
  ```bash
  docker compose down -v
  ```
