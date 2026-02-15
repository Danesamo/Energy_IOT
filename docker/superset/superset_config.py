# =============================================================================
# ENERGY IoT PIPELINE - Superset Configuration
# =============================================================================
# Configuration Apache Superset pour le projet Energy IoT
# =============================================================================

import os

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------
SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'your-superset-secret-key')

# -----------------------------------------------------------------------------
# Database - Métadonnées Superset
# -----------------------------------------------------------------------------
SQLALCHEMY_DATABASE_URI = (
    f"postgresql://"
    f"{os.environ.get('DATABASE_USER', 'energy_user')}:"
    f"{os.environ.get('DATABASE_PASSWORD', 'Energy26!')}@"
    f"{os.environ.get('DATABASE_HOST', 'postgres')}:"
    f"{os.environ.get('DATABASE_PORT', '5432')}/"
    f"{os.environ.get('DATABASE_DB', 'energy_db')}"
)

# -----------------------------------------------------------------------------
# Cache - Redis
# -----------------------------------------------------------------------------
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_HOST': 'redis',
    'CACHE_REDIS_PORT': 6379,
    'CACHE_REDIS_DB': 1,
}

DATA_CACHE_CONFIG = CACHE_CONFIG

# -----------------------------------------------------------------------------
# Feature Flags
# -----------------------------------------------------------------------------
FEATURE_FLAGS = {
    'ENABLE_TEMPLATE_PROCESSING': True,
    'DASHBOARD_NATIVE_FILTERS': True,
    'DASHBOARD_CROSS_FILTERS': True,
    'DASHBOARD_NATIVE_FILTERS_SET': True,
    'ALERT_REPORTS': True,
    'EMBEDDABLE_CHARTS': True,
}

# -----------------------------------------------------------------------------
# UI Configuration
# -----------------------------------------------------------------------------
APP_NAME = 'Energy IoT Analytics'
APP_ICON = '/static/assets/images/superset-logo-horiz.png'

# Languages
LANGUAGES = {
    'en': {'flag': 'us', 'name': 'English'},
    'fr': {'flag': 'fr', 'name': 'French'},
}

# Default timezone
DEFAULT_TIMEZONE = 'UTC'

# -----------------------------------------------------------------------------
# SQL Lab
# -----------------------------------------------------------------------------
SQLLAB_TIMEOUT = 300
SUPERSET_WEBSERVER_TIMEOUT = 300

# Allow downloading CSV
CSV_EXPORT = {
    'encoding': 'utf-8',
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
LOG_FORMAT = '%(asctime)s:%(levelname)s:%(name)s:%(message)s'
LOG_LEVEL = 'INFO'

# -----------------------------------------------------------------------------
# Additional database drivers (for ClickHouse)
# -----------------------------------------------------------------------------
# Note: clickhouse-connect doit être installé dans le conteneur
