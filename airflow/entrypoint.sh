#!/bin/bash
set -e

export AIRFLOW__CORE__LOAD_EXAMPLES=False

echo "Running Airflow Database migrations..."
airflow db migrate

echo "Ensuring Airflow Admin user exists..."
airflow users create \
    --username "${AIRFLOW_ADMIN_USERNAME:-admin}" \
    --firstname "Admin" \
    --lastname "User" \
    --role "Admin" \
    --email "${AIRFLOW_ADMIN_EMAIL:-admin@example.com}" \
    --password "${AIRFLOW_ADMIN_PASSWORD:-admin}" 2>/dev/null || true

echo "Starting Apache Airflow Standalone..."
exec airflow standalone
