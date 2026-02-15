# =============================================================================
# ENERGY IoT PIPELINE - Superset 4.1.1 avec drivers PostgreSQL et ClickHouse
# =============================================================================
FROM apache/superset:4.1.1

USER root

# Installation des drivers de base de données
RUN pip install --no-cache-dir \
    psycopg2-binary==2.9.11 \
    clickhouse-connect==0.11.0

USER superset
