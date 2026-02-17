#!/bin/bash
set -e

echo "Installing PostgreSQL drivers..."
pip install psycopg2-binary clickhouse-connect

echo "Running Superset database upgrade..."
superset db upgrade

echo "Creating admin user..."
superset fab create-admin \
    --username admin \
    --firstname Admin \
    --lastname User \
    --email admin@example.com \
    --password admin || true

echo "Initializing Superset..."
superset init

echo "Starting Superset server..."
superset run -h 0.0.0.0 -p 8088 --with-threads
