#!/bin/bash
set -e

echo "Running Airflow database migration..."
airflow db migrate

echo "Creating admin user..."
airflow users create \
    --username airflow \
    --password "${AIRFLOW_WWW_USER_PASSWORD:-Energy26!}" \
    --firstname Airflow \
    --lastname Admin \
    --role Admin \
    --email admin@example.com || echo "User already exists"

echo "Airflow initialization complete!"
