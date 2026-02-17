#!/usr/bin/env python3
"""
Energy IoT Pipeline - Script d'Ingestion des Données
====================================================
Charge le dataset Smart Meter depuis CSV vers PostgreSQL raw_data.meter_readings.

Utilisation:
    python src/ingestion/load_data.py
    ou
    make ingest
"""

import os
import sys
import logging
from pathlib import Path
from datetime import datetime

import pandas as pd
import psycopg2
from psycopg2.extras import execute_batch

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)


class DataIngestion:
    """Gère l'ingestion des données Smart Meter vers PostgreSQL."""

    def __init__(self):
        """Initialise les paramètres de connexion depuis les variables d'environnement."""
        self.db_params = {
            'host': os.getenv('POSTGRES_HOST', 'localhost'),
            'port': os.getenv('POSTGRES_PORT', '5432'),
            'database': os.getenv('POSTGRES_DB', 'energy_db'),
            'user': os.getenv('POSTGRES_USER', 'energy_user'),
            'password': os.getenv('POSTGRES_PASSWORD', 'Energy26!')
        }
        self.data_file = Path('data/raw/smart_meter_data.csv')
        self.conn = None
        self.cursor = None

    def connect(self):
        """Établit la connexion à PostgreSQL."""
        try:
            logger.info(f"Connecting to PostgreSQL at {self.db_params['host']}:{self.db_params['port']}...")
            self.conn = psycopg2.connect(**self.db_params)
            self.cursor = self.conn.cursor()
            logger.info("✓ Database connection established")
            return True
        except psycopg2.Error as e:
            logger.error(f"✗ Failed to connect to database: {e}")
            return False

    def disconnect(self):
        """Ferme la connexion à la base de données."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        logger.info("Database connection closed")

    def load_csv(self):
        """Charge le fichier CSV dans un DataFrame pandas."""
        try:
            if not self.data_file.exists():
                logger.error(f"✗ Data file not found: {self.data_file}")
                logger.info("Please run 'make download-data' first to download the dataset")
                return None

            logger.info(f"Loading CSV file: {self.data_file}")
            df = pd.read_csv(self.data_file)

            # Afficher les informations du fichier
            file_size_kb = self.data_file.stat().st_size / 1024
            logger.info(f"✓ CSV loaded successfully")
            logger.info(f"  - Rows: {len(df):,}")
            logger.info(f"  - Columns: {len(df.columns)}")
            logger.info(f"  - File size: {file_size_kb:.1f} KB")
            logger.info(f"  - Columns: {', '.join(df.columns.tolist())}")

            # Valider les colonnes attendues
            expected_cols = [
                'Timestamp', 'Electricity_Consumed', 'Temperature',
                'Humidity', 'Wind_Speed', 'Avg_Past_Consumption', 'Anomaly_Label'
            ]
            if not all(col in df.columns for col in expected_cols):
                logger.error(f"✗ Missing expected columns")
                logger.error(f"  Expected: {expected_cols}")
                logger.error(f"  Found: {df.columns.tolist()}")
                return None

            # Parser le timestamp
            df['Timestamp'] = pd.to_datetime(df['Timestamp'])

            # Vérifications qualité des données
            logger.info("Data quality summary:")
            logger.info(f"  - Date range: {df['Timestamp'].min()} to {df['Timestamp'].max()}")
            logger.info(f"  - Null values: {df.isnull().sum().sum()}")
            logger.info(f"  - Anomaly distribution: {df['Anomaly_Label'].value_counts().to_dict()}")

            return df

        except Exception as e:
            logger.error(f"✗ Error loading CSV: {e}")
            return None

    def truncate_table(self):
        """Vide la table cible pour permettre un chargement idempotent."""
        try:
            logger.info("Truncating raw_data.meter_readings table...")
            self.cursor.execute("TRUNCATE TABLE raw_data.meter_readings RESTART IDENTITY;")
            self.conn.commit()
            logger.info("✓ Table truncated")
            return True
        except psycopg2.Error as e:
            logger.error(f"✗ Failed to truncate table: {e}")
            self.conn.rollback()
            return False

    def insert_data(self, df):
        """Insère le DataFrame dans PostgreSQL via insertion par lots."""
        try:
            logger.info("Inserting data into PostgreSQL...")

            # Préparer la requête d'insertion
            insert_query = """
                INSERT INTO raw_data.meter_readings (
                    timestamp,
                    electricity_consumed,
                    temperature,
                    humidity,
                    wind_speed,
                    avg_past_consumption,
                    anomaly_label,
                    source_file
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """

            # Préparer les tuples de données
            source_file = self.data_file.name
            data_tuples = [
                (
                    row['Timestamp'],
                    float(row['Electricity_Consumed']),
                    float(row['Temperature']),
                    float(row['Humidity']),
                    float(row['Wind_Speed']),
                    float(row['Avg_Past_Consumption']),
                    str(row['Anomaly_Label']),
                    source_file
                )
                for _, row in df.iterrows()
            ]

            # Exécuter l'insertion par lots (beaucoup plus rapide que des insertions individuelles)
            execute_batch(self.cursor, insert_query, data_tuples, page_size=1000)
            self.conn.commit()

            logger.info(f"✓ Successfully inserted {len(data_tuples):,} rows")
            return True

        except psycopg2.Error as e:
            logger.error(f"✗ Failed to insert data: {e}")
            self.conn.rollback()
            return False
        except Exception as e:
            logger.error(f"✗ Unexpected error during insertion: {e}")
            self.conn.rollback()
            return False

    def validate_insertion(self):
        """Valide que les données ont été insérées correctement."""
        try:
            logger.info("Validating data insertion...")

            # Compter les lignes
            self.cursor.execute("SELECT COUNT(*) FROM raw_data.meter_readings;")
            row_count = self.cursor.fetchone()[0]
            logger.info(f"  - Total rows in table: {row_count:,}")

            # Vérifier la plage de dates
            self.cursor.execute("""
                SELECT
                    MIN(timestamp) as min_date,
                    MAX(timestamp) as max_date
                FROM raw_data.meter_readings;
            """)
            min_date, max_date = self.cursor.fetchone()
            logger.info(f"  - Date range: {min_date} to {max_date}")

            # Vérifier la distribution des anomalies
            self.cursor.execute("""
                SELECT anomaly_label, COUNT(*)
                FROM raw_data.meter_readings
                GROUP BY anomaly_label;
            """)
            anomaly_counts = self.cursor.fetchall()
            logger.info(f"  - Anomaly distribution:")
            for label, count in anomaly_counts:
                percentage = (count / row_count) * 100
                logger.info(f"    • {label}: {count:,} ({percentage:.1f}%)")

            # Vérifier les valeurs nulles
            self.cursor.execute("""
                SELECT
                    COUNT(*) - COUNT(electricity_consumed) as null_consumed,
                    COUNT(*) - COUNT(temperature) as null_temp,
                    COUNT(*) - COUNT(humidity) as null_humidity,
                    COUNT(*) - COUNT(wind_speed) as null_wind,
                    COUNT(*) - COUNT(avg_past_consumption) as null_avg
                FROM raw_data.meter_readings;
            """)
            null_counts = self.cursor.fetchone()
            total_nulls = sum(null_counts)
            logger.info(f"  - Null values: {total_nulls}")

            logger.info("✓ Validation complete")
            return True

        except psycopg2.Error as e:
            logger.error(f"✗ Validation failed: {e}")
            return False

    def run(self):
        """Exécute le pipeline complet d'ingestion."""
        logger.info("=" * 70)
        logger.info("Energy IoT Pipeline - Data Ingestion")
        logger.info("=" * 70)

        try:
            # Étape 1: Connexion à la base de données
            if not self.connect():
                return False

            # Étape 2: Chargement du CSV
            df = self.load_csv()
            if df is None:
                return False

            # Étape 3: Vidage de la table
            if not self.truncate_table():
                return False

            # Étape 4: Insertion des données
            if not self.insert_data(df):
                return False

            # Étape 5: Validation
            if not self.validate_insertion():
                return False

            logger.info("=" * 70)
            logger.info("✓ Ingestion completed successfully!")
            logger.info("=" * 70)
            return True

        except Exception as e:
            logger.error(f"✗ Ingestion failed with unexpected error: {e}")
            return False

        finally:
            self.disconnect()


def main():
    """Point d'entrée principal."""
    ingestion = DataIngestion()
    success = ingestion.run()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
