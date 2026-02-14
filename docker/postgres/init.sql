-- =============================================================================
-- ENERGY IoT PIPELINE - PostgreSQL Initialization
-- =============================================================================
-- Ce script s'exécute automatiquement au premier démarrage du conteneur
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SCHEMA: raw_data - Données brutes ingérées
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS raw_data;

-- Table des lectures de compteurs (Smart Meter Dataset - Kaggle)
CREATE TABLE IF NOT EXISTS raw_data.meter_readings (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    electricity_consumed DECIMAL(10,4),     -- Consommation (kWh)
    temperature DECIMAL(5,2),                -- Température extérieure (°C)
    humidity DECIMAL(5,2),                   -- Humidité (%)
    wind_speed DECIMAL(5,2),                 -- Vitesse du vent (km/h)
    avg_past_consumption DECIMAL(10,4),     -- Moyenne historique (kWh)
    anomaly_label VARCHAR(20),               -- Normal / Anomaly
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file VARCHAR(255)
);

-- Index pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_readings_timestamp ON raw_data.meter_readings(timestamp);
CREATE INDEX IF NOT EXISTS idx_readings_anomaly ON raw_data.meter_readings(anomaly_label);

-- -----------------------------------------------------------------------------
-- SCHEMA: staging - Données nettoyées (créé par dbt)
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS staging;

-- -----------------------------------------------------------------------------
-- SCHEMA: intermediate - Données agrégées (créé par dbt)
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS intermediate;

-- -----------------------------------------------------------------------------
-- SCHEMA: marts - Données finales pour BI (créé par dbt)
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS marts;

-- -----------------------------------------------------------------------------
-- SCHEMA: quality - Métadonnées de qualité des données
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS quality;

-- Table de suivi des validations Great Expectations
CREATE TABLE IF NOT EXISTS quality.validation_results (
    id SERIAL PRIMARY KEY,
    run_id VARCHAR(255) NOT NULL,
    expectation_suite VARCHAR(255) NOT NULL,
    success BOOLEAN NOT NULL,
    statistics JSONB,
    validated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Commentaires pour documentation
-- -----------------------------------------------------------------------------
COMMENT ON SCHEMA raw_data IS 'Données brutes ingérées depuis les fichiers sources';
COMMENT ON SCHEMA staging IS 'Données nettoyées et typées (couche dbt staging)';
COMMENT ON SCHEMA intermediate IS 'Données agrégées (couche dbt intermediate)';
COMMENT ON SCHEMA marts IS 'Métriques finales pour dashboards (couche dbt marts)';
COMMENT ON SCHEMA quality IS 'Métadonnées de validation et qualité des données';

COMMENT ON TABLE raw_data.meter_readings IS 'Lectures de compteurs électriques - Smart Meter Dataset (Kaggle)';
COMMENT ON COLUMN raw_data.meter_readings.timestamp IS 'Horodatage de la mesure (intervalle 30 min)';
COMMENT ON COLUMN raw_data.meter_readings.electricity_consumed IS 'Consommation électrique en kilowatt-heures (kWh)';
COMMENT ON COLUMN raw_data.meter_readings.temperature IS 'Température extérieure en degrés Celsius';
COMMENT ON COLUMN raw_data.meter_readings.humidity IS 'Humidité relative en pourcentage';
COMMENT ON COLUMN raw_data.meter_readings.wind_speed IS 'Vitesse du vent en kilomètres par heure';
COMMENT ON COLUMN raw_data.meter_readings.avg_past_consumption IS 'Moyenne mobile de consommation passée (kWh)';
COMMENT ON COLUMN raw_data.meter_readings.anomaly_label IS 'Label anomalie: Normal ou Anomaly (pré-étiqueté)';

-- -----------------------------------------------------------------------------
-- Vérification
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE 'Energy IoT Pipeline - PostgreSQL initialized successfully!';
    RAISE NOTICE 'Schemas created: raw_data, staging, intermediate, marts, quality';
END $$;
