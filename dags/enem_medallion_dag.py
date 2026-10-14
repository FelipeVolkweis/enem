"""ENEM medallion pipeline.

bronze: raw CSVs from the project's Google Drive folder land untouched in MinIO
        (s3://<bucket>/bronze/files/), then load as all-string Iceberg tables in `bronze`.
silver: dbt staging models in dbt/models/staging (typed, cleaned ENEM, questionnaire dictionary and
        Censo Escolar), run by Cosmos as one task per model plus its tests, in the `staging` schema.
gold: dbt marts in dbt/models/marts, the ENEM + Censo Escolar fact constellation (three star schemas
      sharing dim_data, dim_aluno and dim_escola), in the `marts` schema.
"""

import os
from datetime import datetime, timedelta
from pathlib import Path

from airflow.sdk import dag, get_current_context, task
from cosmos import DbtTaskGroup, ExecutionConfig, ProfileConfig, ProjectConfig, RenderConfig

DBT_PROJECT_DIR = Path("/opt/airflow/dbt")

# Source folder: https://drive.google.com/drive/folders/1tti3pju4VrofJ79ZCvNQHAApg7_UoU9f
# The "Microdados Enem 2019 (por estado)" subfolder is a per-UF split of MICRODADOS_ENEM_2019.csv, so it is skipped.
SOURCES = [
    {"table": "enem_microdados_2019", "drive_id": "1sslh9wk1WkVoA2afjb6p9snj-TTJ7jpc",
     "file": "MICRODADOS_ENEM_2019.csv", "delimiter": ",", "encoding": "utf8"},
    {"table": "enem_microdados_2024", "drive_id": "1oNZpHmUrrgDJrYeuNY2zWEPgquioqGdz",
     "file": "MICRODADOS_ENEM_2024.csv", "delimiter": ",", "encoding": "utf8"},
    {"table": "dicionario_questionario_socioeconomico_2019", "drive_id": "1OhrDEKQk8d0078UdgoiyL2BHhHmcknD_",
     "file": "dicionario_questionario_socioeconomico_2019.csv", "delimiter": ",", "encoding": "utf8"},
    {"table": "dicionario_questionario_socioeconomico_2024", "drive_id": "17AyvjRTmglmKMrbBFbR2i5abs2_j_Kdk",
     "file": "dicionario_questionario_socioeconomico_2024.csv", "delimiter": ",", "encoding": "utf8"},
    {"table": "censo_escolar_2019", "drive_id": "1Pq_NRa6VNTgXs6Dr2Gn9v9bg0rcNLJU4",
     "file": "microdados_ed_basica_2019.csv", "delimiter": ";", "encoding": "latin1"},
    {"table": "censo_escolar_2024", "drive_id": "1_WUlptHz9dNcEE5BHB3vVINJOeZZ4adr",
     "file": "microdados_ed_basica_2024.csv", "delimiter": ";", "encoding": "latin1"},
]

BRONZE_NAMESPACE = "bronze"
BUCKET = os.environ.get("WAREHOUSE_BUCKET", "warehouse")
LOAD_BATCH_ROWS = 100_000  # rows buffered per Iceberg write; bounds the load task's memory


def _s3fs():
    from pyarrow import fs

    return fs.S3FileSystem(
        access_key=os.environ["MINIO_ACCESS_KEY"],
        secret_key=os.environ["MINIO_SECRET_KEY"],
        endpoint_override=os.environ.get("MINIO_ENDPOINT", "http://minio:9000"),
        region="us-east-1",
    )


def _catalog():
    from pyiceberg.catalog import load_catalog

    return load_catalog(
        "rest",
        type="rest",
        uri=os.environ.get("ICEBERG_REST_URI", "http://iceberg-rest:8181"),
        **{
            "s3.endpoint": os.environ.get("MINIO_ENDPOINT", "http://minio:9000"),
            "s3.access-key-id": os.environ["MINIO_ACCESS_KEY"],
            "s3.secret-access-key": os.environ["MINIO_SECRET_KEY"],
            "s3.path-style-access": "true",
            "s3.region": "us-east-1",
        },
    )


@dag(
    dag_id="enem_medallion",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    default_args={"retries": 2, "retry_delay": timedelta(minutes=1)},
    tags=["enem", "bronze", "iceberg"],
)
def enem_medallion():
    # Mapped task instances are labelled with the source file name instead of a bare index.
    @task(max_active_tis_per_dag=2, map_index_template="{{ file_name }}")
    def land(source: dict) -> dict:
        """Stream one Drive file, byte for byte, into the bronze landing area in MinIO."""
        get_current_context()["file_name"] = source["file"]
        import shutil
        import urllib.request

        url = f"https://drive.usercontent.google.com/download?id={source['drive_id']}&export=download&confirm=t"
        key = f"{BUCKET}/bronze/files/{source['file']}"
        with urllib.request.urlopen(url, timeout=120) as resp:
            if resp.headers.get_content_type() == "text/html":
                raise RuntimeError(f"Drive returned an HTML page instead of {source['file']} (quota or permissions?)")
            expected = int(resp.headers.get("Content-Length", -1))
            with _s3fs().open_output_stream(key) as out:
                shutil.copyfileobj(resp, out, length=8 << 20)
        size = _s3fs().get_file_info(key).size
        if expected >= 0 and size != expected:
            raise RuntimeError(f"{key}: wrote {size} bytes, expected {expected}")
        print(f"landed s3://{key} ({size / 1e6:.1f} MB)")
        return {**source, "key": key}

    # SQLite-backed REST catalog allows a single writer, so loads run one at a time.
    @task(max_active_tis_per_dag=1, map_index_template="{{ file_name }}")
    def load(landed: dict) -> None:
        """Rebuild bronze.<table> from the landed CSV: every column a string, names lowercased."""
        get_current_context()["file_name"] = landed["file"]
        from datetime import timezone

        import pyarrow as pa
        from pyarrow import csv

        s3, key = _s3fs(), landed["key"]
        with s3.open_input_file(key) as f:
            header = f.read(1 << 20).decode(landed["encoding"]).lstrip("﻿").splitlines()[0]
        columns = [c.strip().lower() for c in header.split(landed["delimiter"])]

        catalog = _catalog()
        catalog.create_namespace_if_not_exists(BRONZE_NAMESPACE)
        identifier = f"{BRONZE_NAMESPACE}.{landed['table']}"
        if catalog.table_exists(identifier):
            catalog.purge_table(identifier)
        schema = pa.schema(
            [pa.field(c, pa.string()) for c in columns]
            + [pa.field("_source_file", pa.string()), pa.field("_ingested_at", pa.timestamp("us", tz="UTC"))]
        )
        table = catalog.create_table(identifier, schema=schema)

        source_file = f"s3://{key}"
        ingested_at = datetime.now(timezone.utc)
        rows, buffer = 0, []

        def flush(txn):
            batch = pa.Table.from_batches(buffer)
            n = batch.num_rows
            batch = batch.append_column("_source_file", pa.array([source_file] * n, pa.string()))
            batch = batch.append_column("_ingested_at", pa.array([ingested_at] * n, pa.timestamp("us", tz="UTC")))
            txn.append(batch)
            buffer.clear()

        with s3.open_input_stream(key) as stream:
            reader = csv.open_csv(
                stream,
                read_options=csv.ReadOptions(
                    column_names=columns, skip_rows=1, encoding=landed["encoding"], block_size=16 << 20
                ),
                parse_options=csv.ParseOptions(delimiter=landed["delimiter"]),
                convert_options=csv.ConvertOptions(column_types={c: pa.string() for c in columns}),
            )
            with table.transaction() as txn:
                for batch in reader:
                    buffer.append(batch)
                    rows += batch.num_rows
                    if sum(b.num_rows for b in buffer) >= LOAD_BATCH_ROWS:
                        flush(txn)
                if buffer:
                    flush(txn)
        print(f"loaded {rows} rows into {identifier}")

    def dbt_layer(path: str, exclude: list[str] | None = None) -> DbtTaskGroup:
        return DbtTaskGroup(
            group_id=path.split("/")[-1],
            project_config=ProjectConfig(DBT_PROJECT_DIR),
            profile_config=ProfileConfig(
                profile_name="enem",
                target_name="dev",
                profiles_yml_filepath=DBT_PROJECT_DIR / "profiles.yml",
            ),
            execution_config=ExecutionConfig(dbt_executable_path="/opt/airflow/dbt_venv/bin/dbt"),
            # Tests that read two models (the dictionary check, relationships) run once both are built.
            render_config=RenderConfig(
                select=[f"path:{path}"], exclude=exclude or [], should_detach_multiple_parents_tests=True
            ),
        )

    # A test lands in every layer that holds one of its parents; the marts tests also read staging models,
    # so keep them out of the staging layer, where the marts don't exist yet.
    staging = dbt_layer("models/staging", exclude=["path:tests/marts"])
    load.expand(landed=land.expand(source=SOURCES)) >> staging >> dbt_layer("models/marts")


enem_medallion()
