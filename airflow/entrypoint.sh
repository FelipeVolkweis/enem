#!/bin/bash
set -e

export AIRFLOW__CORE__LOAD_EXAMPLES=False

PASSWORDS_FILE="${AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_PASSWORDS_FILE:-${AIRFLOW_HOME:-/opt/airflow}/simple_auth_manager_passwords.json}"
export AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_PASSWORDS_FILE="${PASSWORDS_FILE}"
export AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_USERS="${AIRFLOW_ADMIN_USERNAME:-admin}:admin"

echo "Configuring Airflow credentials..."
cat <<EOF > "${PASSWORDS_FILE}"
{"${AIRFLOW_ADMIN_USERNAME:-admin}": "${AIRFLOW_ADMIN_PASSWORD:-admin}"}
EOF
chmod 600 "${PASSWORDS_FILE}" 2>/dev/null || true

if [ "$#" -gt 0 ]; then
    if [ "$1" = "airflow" ] && [ "$2" = "standalone" ] || [ "$1" = "standalone" ]; then
        echo "Running Airflow Database migrations..."
        airflow db migrate
    fi
    exec "$@"
fi

echo "Running Airflow Database migrations..."
airflow db migrate

echo "Starting Apache Airflow Standalone..."
exec airflow standalone
