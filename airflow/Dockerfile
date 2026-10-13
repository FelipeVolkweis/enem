FROM apache/airflow:3.3.2

COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt

# dbt lives in its own venv so its dependencies never clash with Airflow's (Cosmos-recommended layout).
RUN python -m venv /opt/airflow/dbt_venv && \
    /opt/airflow/dbt_venv/bin/pip install --no-cache-dir dbt-trino==1.10.6
