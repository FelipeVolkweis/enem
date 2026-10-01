"""
Airflow Smoke Test DAG for Apache Iceberg & Apache Spark Lakehouse Pipeline.
"""

from datetime import datetime, timedelta
import socket
import docker
from airflow import DAG
from airflow.operators.python import PythonOperator

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(seconds=10),
}


def check_port(host: str, port: int, timeout: float = 3.0) -> bool:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect((host, port))
        sock.close()
        return True
    except Exception as e:
        sock.close()
        raise RuntimeError(f"Service {host}:{port} is unreachable: {e}")


def verify_infrastructure():
    print("Checking Lakehouse services connectivity...")
    check_port("minio", 9000)
    print("MinIO S3 API (minio:9000) is accessible!")

    check_port("iceberg-rest", 8181)
    print("Iceberg REST Catalog (iceberg-rest:8181) is accessible!")

    check_port("spark", 7077)
    print("Spark Master (spark:7077) is accessible!")
    return "All infrastructure services healthy!"


def execute_spark_iceberg_job():
    print("Connecting to Docker daemon to trigger Spark job...")
    client = docker.from_env()
    spark_container = client.containers.get("enem-spark")

    cmd = "/opt/spark/bin/spark-submit /opt/spark/jobs/test_iceberg.py"
    print(f"Executing command inside '{spark_container.name}': {cmd}")

    exec_instance = client.api.exec_create(
        container=spark_container.id,
        cmd=cmd,
        stdout=True,
        stderr=True,
    )
    exec_id = exec_instance["Id"]

    # Stream output in real time to Airflow task logs
    output_stream = client.api.exec_start(exec_id, stream=True)
    for chunk in output_stream:
        print(chunk.decode("utf-8", errors="replace"), end="", flush=True)

    inspect_res = client.api.exec_inspect(exec_id)
    exit_code = inspect_res.get("ExitCode")

    if exit_code != 0:
        raise RuntimeError(f"Spark-submit failed with exit code: {exit_code}")

    print("\nSpark Iceberg job executed successfully!")
    return "SUCCESS"


with DAG(
    dag_id="iceberg_lakehouse_smoke_test",
    default_args=default_args,
    description="Validates end-to-end Airflow -> Spark -> Iceberg REST -> MinIO pipeline",
    schedule_interval=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["iceberg", "lakehouse", "spark", "enem"],
) as dag:

    t1_health_check = PythonOperator(
        task_id="check_lakehouse_services",
        python_callable=verify_infrastructure,
    )

    t2_spark_iceberg = PythonOperator(
        task_id="run_spark_iceberg_pipeline",
        python_callable=execute_spark_iceberg_job,
    )

    t1_health_check >> t2_spark_iceberg
