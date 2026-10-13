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
├── trino/
│   ├── catalog/iceberg.properties  # Trino → Iceberg REST + MinIO
│   └── etc/                     # small-host tuning: lazy heap, 1 query at a time, spill
├── dbt/                         # dbt project (mounted at /opt/airflow/dbt)
│   ├── dbt_project.yml
│   ├── profiles.yml             # Trino target, catalog `iceberg`, schema `enem_dw`
│   ├── macros/                  # staging cast helpers, mart keys, schema naming
│   ├── tests/staging/           # cross-model data tests
│   ├── seeds/smoke/             # smoke-test fixture CSV
│   └── models/
│       ├── staging/             # silver layer: stg_<source>__<entity> (schema `staging`)
│       │   ├── _sources.yml     # bronze tables
│       │   ├── enem/
│       │   └── censo_escolar/
│       ├── marts/               # gold layer: dim_* / fato_* constellation (schema `marts`)
│       │   └── intermediate/    # ephemeral int_* filters giving the facts' grains
│       └── smoke/               # smoke-test fixtures (tag `smoke`, schema `enem_dw`)
├── dags/
│   ├── enem_medallion_dag.py    # bronze load -> Cosmos task groups for staging, then marts
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

## 🥈 Silver Layer (dbt staging)

`enem_medallion` lands the Drive CSVs into `iceberg.bronze` (all varchar), then runs `dbt/models/staging` through a Cosmos task group into `iceberg.staging`, and `dbt/models/marts` into `iceberg.marts` (see Gold below).

| Table | Grain | What staging does |
| :--- | :--- | :--- |
| `stg_enem__participantes` | participant (2019 + 2024) | Types every column, blanks → NULL, `"42.0"` → `42`, repairs 2019 double-encoded names (`SÃ£o` → `São`), NULLs the 18 cells the 2019 per-state join truncated. `q024`/`q025` exist only for 2019. |
| `stg_enem__dicionario_questionario` | (year, question, option) | Both questionnaire dictionaries. Q-codes change meaning between years (2019 `q006` = family income, 2024 `q006` = has income), so always join on `nu_ano` + `questao`. |
| `stg_censo_escolar__escolas` | school × census year | Both census layouts unioned by column name (missing → NULL), typed by INEP prefix (`co_/in_/tp_/qt_` int, `dt_` date). |

`stg_enem__participantes.co_escola` joins to `stg_censo_escolar__escolas.co_entidade` (the EDA notebook's São Carlos check reproduces: 37 schools in ENEM 2024, 34 found in the census).

```bash
docker exec enem-airflow airflow dags trigger enem_medallion
docker exec -it enem-trino trino --execute "select nu_ano, count(*) from iceberg.staging.stg_enem__participantes group by 1"
```

Sized for an 8 GB machine: every container has a memory cap in `.env` (`TRINO_MEM_LIMIT=1536m`, `AIRFLOW_MEM_LIMIT=1536m`, `MINIO_MEM_LIMIT=512m`, `ICEBERG_REST_MEM_LIMIT=384m`, about 3.9 GB in total), and the stack never takes more than their sum. Trino is tuned for that cap in `trino/etc/`. `jvm.config` starts the heap at 10% of the cap instead of 80%, so idle Trino doesn't hold most of its cap. `resource-groups.json` runs one query at a time and queues the rest, whether they come from dbt threads, Airflow tasks or the CLI, so `config.properties` can give that query 700MB. The same file limits parallelism to 4 threads and 2 Parquet writers, since scans and writes can't spill, and turns on spill-to-disk for joins and aggregations. Keep `TRINO_MEM_LIMIT` at 1.2g or more, or that 700MB no longer fits and Trino won't start. Airflow runs with `core.parallelism=2` (2 LocalExecutor workers instead of 32), and the bronze load buffers 100k rows per write. dbt uses 2 threads. Apply a changed cap with `docker compose up -d`. Note that recreating the Airflow container resets `airflow standalone`'s SQLite metadata DB (run history), but not the warehouse.

---

## 🥇 Gold Layer (dbt marts)

A fact constellation: three star schemas sharing `dim_data`, `dim_aluno` and `dim_escola` (from *Esquemas Estrela: ENEM e INEP*).

| Fact | Grain | Dimensions |
| :--- | :--- | :--- |
| `fato_desempenho_enem` | participation × ENEM edition, absentees included (missed test → score 0) | aluno, data, escola |
| `fato_questionario` | participant × question answered × edition (`qt_resposta` = 1) | aluno, escola, data, questionario |
| `fato_censo_escolar` | active school (`tp_situacao_funcionamento = 1`) × census year | escola, data, localizacao, infraestrutura, tecnologia, profissionais |

- Keys are sequential positive `integer`s ordered by the natural key (`sequential_key` macro), and facts look them up by natural key. `0` is the unknown member, and `chave_data` is `yyyymmdd`.
- NULLs: dimensions never hold one. Codes (`tp_`/`in_`) use `9`, INEP's own "não sabe / não informado" code, here also meaning "não se aplica" (e.g. `tp_categoria_escola_privada` of a public school). Identifiers use `0` and names `'NÃO INFORMADO'`. Facts have no NULLs either. In `fato_desempenho_enem` a missed test scores 0 (booklet 0, essay status 0 = "ausente"), so filter score analyses on `tp_presenca_<area> = 1` (essay: `tp_presenca_lc = 1`). A plain `avg()` counts absentees as 0, and real zeros exist (blank essays). Blank census enrollment/teacher/class counts are 0, since INEP writes no zero counts.
- `fato_censo_escolar` keeps only active schools, because INEP 2024 publishes no details for paralisadas/extintas. They still appear in `dim_escola`.
- An edition is filed under ENEM's first exam day or the census reference date (`enem_data_prova` / `censo_data_referencia` vars in `dbt_project.yml`).
- `dim_escola` merges ENEM's `*_esc` attributes with the census attributes, and each side fills in for the other, using the latest non-NULL year. `chave_escola = 0` is the "no school informed" row most participants point to.
- `dim_infraestrutura`, `dim_tecnologia` and `dim_profissionais` are junk dimensions: one row per distinct combination of their indicators.
- `dim_aluno.nu_sequencial` holds `NU_INSCRICAO`, since the microdata has no `NU_SEQUENCIAL`. `dim_localizacao`'s intermediate/immediate geographic regions exist only in the 2024 census.

```bash
docker exec -it enem-trino trino --execute "
  select d.ano, e.sg_uf_esc, avg(f.nu_nota_mt) from iceberg.marts.fato_desempenho_enem f
  join iceberg.marts.dim_data d using (chave_data) join iceberg.marts.dim_escola e using (chave_escola)
  where f.chave_escola <> 0 and f.tp_presenca_mt = 1 group by 1, 2 order by 1, 2"
```

---

## 🧪 Smoke Test

`dbt_smoke_test` is a Cosmos `DbtDag`. Each dbt seed, model and test becomes its own Airflow task: seed `smoke_students` → view `stg_students` → table `score_by_uf` (all under `models/smoke` and `seeds/smoke`), with tests after each model.

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
