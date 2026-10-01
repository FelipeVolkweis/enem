"""
Airflow Smoke Test DAG for Apache Iceberg & Apache Spark Lakehouse Pipeline.
"""

from datetime import datetime, timedelta
import socket

from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.providers.standard.operators.python import PythonOperator

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


with DAG(
    dag_id="iceberg_lakehouse_smoke_test",
    default_args=default_args,
    description="Validates end-to-end Airflow -> Spark -> Iceberg REST -> MinIO pipeline",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["iceberg", "lakehouse", "spark", "enem"],
) as dag:

    t1_health_check = PythonOperator(
        task_id="check_lakehouse_services",
        python_callable=verify_infrastructure,
    )

    t2_spark_iceberg = SparkSubmitOperator(
        task_id="run_spark_iceberg_pipeline",
        application="/opt/airflow/jobs/test_iceberg.py",
        conn_id="spark_default",
        deploy_mode="client",
        properties_file="/opt/spark/conf/spark-defaults.conf",
        conf={
            "spark.driver.host": "enem-airflow",
            "spark.driver.bindAddress": "0.0.0.0",
        },
        name="iceberg-verification",
    )

    t1_health_check >> t2_spark_iceberg
