# ENEM Lakehouse & Data Warehouse Infrastructure

A containerized local lakehouse running **Apache Airflow 3.3.2** + **Astronomer Cosmos** orchestrating **dbt** on **Trino**, with tables stored as **Apache Iceberg** (REST catalog) on **MinIO**.

Designed for developing local data pipelines and analytical workloads on datasets such as Brazilian ENEM (Exame Nacional do Ensino Médio) microdata.

---

## 🏛 Architecture Overview

| Component | Container | Image | Role | Host port(s) |
| :--- | :--- | :--- | :--- | :--- |
| **Airflow** | `enem-airflow` | `apache/airflow:3.3.2` + Cosmos + dbt-trino | Standalone orchestration; Cosmos renders the dbt project as Airflow tasks | `8080` |
| **Trino** | `enem-trino` | `trinodb/trino:483` | SQL engine for dbt; Iceberg connector pointed at the REST catalog | `8085` |
| **Iceberg Catalog** | `enem-iceberg-rest` | `apache/iceberg-rest-fixture:1.10.1` | Iceberg REST catalog (SQLite-backed, persisted in a volume) | `8181` |
| **Object Store** | `enem-minio` | `cgr.dev/chainguard/minio:latest` | S3-compatible storage for Iceberg data/metadata | `9000` (S3), `9001` (console) |
| **Bucket Provisioner** | `enem-minio-init` | `cgr.dev/chainguard/minio-client:latest` | Creates the `warehouse` bucket on boot | — |

Every service uses an upstream image. The only image built locally is a three-line extension of the official Airflow image. It installs `astronomer-cosmos` and puts `dbt-trino` in a separate venv (`/opt/airflow/dbt_venv`), which is the layout Cosmos recommends to keep dbt's dependencies apart from Airflow's.

---

## 📂 Project Structure

```text
.
├── .env                         # Credentials and host ports
├── docker-compose.yml
├── airflow/
│   ├── Dockerfile               # FROM apache/airflow + Cosmos + dbt venv
│   └── requirements.txt
├── trino/catalog/
│   └── iceberg.properties       # Trino → Iceberg REST + MinIO
├── dbt/                         # dbt project (mounted at /opt/airflow/dbt)
│   ├── dbt_project.yml
│   ├── profiles.yml             # Trino target, catalog `iceberg`, schema `enem_dw`
│   ├── seeds/
│   ├── macros/                  # silver cast helpers, schema naming
│   ├── tests/silver/            # cross-model data tests
│   └── models/
│       ├── sources.yml          # bronze tables
│       ├── silver/              # medallion silver layer (schema `silver`)
│       └── {staging,marts}/     # smoke-test fixtures (tag `smoke`)
├── dags/
│   ├── enem_medallion_dag.py    # bronze load -> Cosmos DbtTaskGroup for silver
│   └── dbt_smoke_test_dag.py    # Cosmos DbtDag over the `smoke` models
├── data/                        # Mounted at /opt/airflow/data for raw ENEM files
└── logs/                        # Airflow logs
```

---

## 🚀 Quickstart

```bash
docker compose up -d --build
```

| Service | URL | Credentials |
| :--- | :--- | :--- |
| **Airflow UI** | <http://localhost:8080> | none (local dev: everyone is admin) |
| **Trino UI** | <http://localhost:8085> | any username |
| **MinIO Console** | <http://localhost:9001> | `admin` / `password123` |
| **Iceberg REST API** | <http://localhost:8181/v1/config> | none |

---

## 🥈 Silver Layer

`enem_medallion` lands the Drive CSVs into `iceberg.bronze` (all varchar), then runs `dbt/models/silver` through a Cosmos task group into `iceberg.silver`:

| Table | Grain | What silver does |
| :--- | :--- | :--- |
| `enem_participantes` | participant (2019 + 2024) | Types every column, blanks → NULL, `"42.0"` → `42`, repairs 2019 double-encoded names (`SÃ£o` → `São`), NULLs the 18 cells the 2019 per-state join truncated. `q024`/`q025` exist only for 2019. |
| `dicionario_questionario` | (year, question, option) | Both questionnaire dictionaries. Q-codes change meaning between years (2019 `q006` = family income, 2024 `q006` = has income), so always join on `nu_ano` + `questao`. |
| `censo_escolar` | school × census year | Both census layouts unioned by column name (missing → NULL), typed by INEP prefix (`co_/in_/tp_/qt_` int, `dt_` date). |

`enem_participantes.co_escola` joins to `censo_escolar.co_entidade` (the EDA notebook's São Carlos check reproduces: 37 schools in ENEM 2024, 34 found in the census).

```bash
docker exec enem-airflow airflow dags trigger enem_medallion
docker exec -it enem-trino trino --execute "select nu_ano, count(*) from iceberg.silver.enem_participantes group by 1"
```

Trino is capped at `mem_limit: 3g`: its stock JVM config takes 80% of visible RAM, and without a cap the kernel OOM-kills it during the silver builds on small hosts.

---

## 🧪 Smoke Test

`dbt_smoke_test` is a Cosmos `DbtDag`. Each dbt seed, model and test becomes its own Airflow task: seed `smoke_students` → view `stg_students` → table `score_by_uf`, with tests after each model.

```bash
docker exec enem-airflow airflow dags trigger dbt_smoke_test
docker exec enem-airflow airflow dags list-runs dbt_smoke_test
```

Check the result in Trino:

```bash
docker exec -it enem-trino trino --execute "select * from iceberg.enem_dw.score_by_uf"
```

Run dbt by hand inside the Airflow container:

```bash
docker exec -it -w /opt/airflow/dbt enem-airflow /opt/airflow/dbt_venv/bin/dbt build --profiles-dir . \
    --target-path /tmp/dbt/target --log-path /tmp/dbt/logs   # the mount is read-only for the airflow uid
```

---

## 🛑 Stopping and Cleaning Up

```bash
docker compose down      # keep data
docker compose down -v   # also wipe MinIO data and the Iceberg catalog
```
