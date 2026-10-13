"""Smoke test: runs the dbt project (seed -> models -> tests) on Trino/Iceberg via Cosmos."""

from datetime import datetime
from pathlib import Path

from cosmos import DbtDag, ExecutionConfig, ProfileConfig, ProjectConfig, RenderConfig

DBT_PROJECT_DIR = Path("/opt/airflow/dbt")

dbt_smoke_test = DbtDag(
    dag_id="dbt_smoke_test",
    project_config=ProjectConfig(DBT_PROJECT_DIR),
    profile_config=ProfileConfig(
        profile_name="enem",
        target_name="dev",
        profiles_yml_filepath=DBT_PROJECT_DIR / "profiles.yml",
    ),
    execution_config=ExecutionConfig(dbt_executable_path="/opt/airflow/dbt_venv/bin/dbt"),
    # Only the smoke fixtures; the medallion models run from enem_medallion.
    render_config=RenderConfig(select=["tag:smoke"]),
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["dbt", "trino", "iceberg", "enem"],
)
