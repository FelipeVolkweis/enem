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

echo "Running Airflow Database migrations..."
airflow db migrate

# Attempt FAB user creation if supported by the active auth manager (e.g. Airflow 2 or FAB provider)
if airflow users create --help >/dev/null 2>&1; then
    echo "Ensuring Airflow Admin user exists in database..."
    airflow users create \
        --username "${AIRFLOW_ADMIN_USERNAME:-admin}" \
        --firstname "Admin" \
        --lastname "User" \
        --role "Admin" \
        --email "${AIRFLOW_ADMIN_EMAIL:-admin@example.com}" \
        --password "${AIRFLOW_ADMIN_PASSWORD:-admin}" 2>/dev/null || true
fi

echo "Starting Apache Airflow Standalone..."
exec airflow standalone
