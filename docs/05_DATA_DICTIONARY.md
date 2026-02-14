# Data Dictionary - Energy IoT Pipeline

> **Dictionnaire de données** - Référence technique complète des tables, colonnes et relations
>
> Dernière mise à jour : 14 Février 2026

---

## Table des Matières

1. [Introduction](#introduction)
2. [Vue d'ensemble](#vue-densemble)
3. [Schéma raw_data](#schéma-raw_data)
4. [Schéma staging](#schéma-staging)
5. [Schéma intermediate](#schéma-intermediate)
6. [Schéma marts](#schéma-marts)
7. [Schéma quality](#schéma-quality)
8. [Relations entre tables](#relations-entre-tables)
9. [Index et performances](#index-et-performances)
10. [Règles de gestion](#règles-de-gestion)

---

## Introduction

### Objet du document

Ce document décrit la structure complète des données du projet Energy IoT Pipeline. Il sert de référence pour :
- Comprendre l'organisation des données
- Connaître les types et contraintes de chaque colonne
- Identifier les relations entre tables
- Documenter les transformations dbt

### Conventions

| Convention | Description |
|------------|-------------|
| **PK** | Primary Key (clé primaire) |
| **FK** | Foreign Key (clé étrangère) |
| **NOT NULL** | Valeur obligatoire |
| **UNIQUE** | Valeur unique dans la table |
| **DEFAULT** | Valeur par défaut |

---

## Vue d'ensemble

### Architecture des schémas

```
┌─────────────────────────────────────────────────────────────┐
│                     POSTGRESQL DATABASE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  raw_data           ──▶   staging        ──▶  intermediate  │
│  (données brutes)         (nettoyées)        (agrégées)     │
│                                                              │
│                              │                               │
│                              ▼                               │
│                                                              │
│                            marts                             │
│                        (KPIs finaux)                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Schémas PostgreSQL

| Schéma | Rôle | Tables | Créé par |
|--------|------|--------|----------|
| **raw_data** | Données brutes ingérées | `meter_readings` | Script Python |
| **staging** | Données nettoyées | `stg_meter_readings` | dbt |
| **intermediate** | Agrégations intermédiaires | `int_readings_hourly`, `int_readings_daily`, `int_consumption_features` | dbt |
| **marts** | KPIs finaux pour BI | `mart_consumption_metrics`, `mart_anomaly_flags` | dbt |
| **quality** | Métadonnées qualité | `ge_validations`, `dbt_test_results` | Great Expectations, dbt |

---

## Schéma raw_data

### Table : raw_data.meter_readings

**Description :** Données brutes des compteurs intelligents (Smart Meter Dataset Kaggle)

**Source :** Ingestion CSV via `src/ingestion/load_data.py`

**Fréquence d'alimentation :** Une fois (données historiques)

**Volumétrie estimée :** TBD après téléchargement

#### Structure

| Colonne | Type | Contraintes | Description | Exemple |
|---------|------|-------------|-------------|---------|
| `id` | SERIAL | PK, NOT NULL | Identifiant unique auto-incrémenté | 1, 2, 3... |
| `timestamp` | TIMESTAMP | NOT NULL | Horodatage de la mesure (intervalle 30 min) | 2024-01-15 14:30:00 |
| `electricity_consumed` | DECIMAL(10,4) | | Consommation électrique en kWh | 2.3450 |
| `temperature` | DECIMAL(5,2) | | Température extérieure en degrés Celsius | 28.50 |
| `humidity` | DECIMAL(5,2) | | Humidité relative en pourcentage | 65.00 |
| `wind_speed` | DECIMAL(5,2) | | Vitesse du vent en km/h | 12.30 |
| `avg_past_consumption` | DECIMAL(10,4) | | Moyenne mobile de consommation passée (kWh) | 2.1000 |
| `anomaly_label` | VARCHAR(20) | | Label pré-étiqueté : Normal ou Anomaly | Normal, Anomaly |
| `ingested_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Date/heure d'ingestion dans la base | 2026-02-14 10:30:00 |
| `source_file` | VARCHAR(255) | | Nom du fichier source CSV | smart_meter_data.csv |

#### Index

| Nom de l'index | Colonnes | Type | Objectif |
|----------------|----------|------|----------|
| `idx_readings_timestamp` | `timestamp` | B-tree | Requêtes temporelles (WHERE, ORDER BY) |
| `idx_readings_anomaly` | `anomaly_label` | B-tree | Filtrage par type d'anomalie |

#### Règles de validation

| Règle | Description | Validé par |
|-------|-------------|------------|
| Timestamp unique | Pas de doublons sur timestamp | Great Expectations |
| Consommation >= 0 | Valeurs négatives impossibles | Great Expectations |
| Température plausible | -50°C <= temp <= 60°C | Great Expectations |
| Humidité plausible | 0% <= humidity <= 100% | Great Expectations |

#### Exemple de données

```sql
SELECT * FROM raw_data.meter_readings LIMIT 3;
```

| id | timestamp | electricity_consumed | temperature | humidity | wind_speed | avg_past_consumption | anomaly_label | ingested_at | source_file |
|----|-----------|---------------------|-------------|----------|------------|---------------------|---------------|-------------|-------------|
| 1 | 2024-01-01 00:00:00 | 2.3450 | 22.50 | 65.00 | 10.50 | 2.1000 | Normal | 2026-02-14 10:30:00 | smart_meter_data.csv |
| 2 | 2024-01-01 00:30:00 | 2.1200 | 22.30 | 66.00 | 11.00 | 2.1500 | Normal | 2026-02-14 10:30:00 | smart_meter_data.csv |
| 3 | 2024-01-01 01:00:00 | 5.8000 | 22.00 | 67.00 | 12.00 | 2.2000 | Anomaly | 2026-02-14 10:30:00 | smart_meter_data.csv |

---

## Schéma staging

> **Note :** Tables créées par dbt (Phase 3). Structure à documenter après implémentation.

### Table : staging.stg_meter_readings

**Description :** Données nettoyées et typées à partir de raw_data.meter_readings

**Source :** dbt model `models/staging/stg_meter_readings.sql`

**Transformations appliquées :**
- Filtrage des valeurs NULL
- Typage explicite
- Calcul de colonnes dérivées (heure, jour de la semaine)
- Conversion anomaly_label en booléen

#### Structure (à implémenter)

| Colonne | Type | Description |
|---------|------|-------------|
| `reading_id` | INTEGER | Copie de raw_data.id |
| `reading_timestamp` | TIMESTAMP | Horodatage |
| `consumption_kwh` | FLOAT | Consommation nettoyée |
| `temperature_c` | FLOAT | Température Celsius |
| `humidity_pct` | FLOAT | Humidité % |
| `wind_speed_kmh` | FLOAT | Vitesse vent km/h |
| `avg_past_consumption_kwh` | FLOAT | Moyenne historique |
| `anomaly_label` | VARCHAR | Label original |
| `is_anomaly` | BOOLEAN | TRUE si Anomaly, FALSE si Normal |
| `hour_of_day` | INTEGER | Heure (0-23) |
| `day_of_week` | INTEGER | Jour (0-6, 0=Dimanche) |
| `is_weekend` | BOOLEAN | TRUE si samedi/dimanche |

---

## Schéma intermediate

> **Note :** Tables créées par dbt (Phase 3). Structure à documenter après implémentation.

### Table : intermediate.int_readings_hourly

**Description :** Agrégation des lectures par heure

**Source :** dbt model `models/intermediate/int_readings_hourly.sql`

#### Structure (à implémenter)

| Colonne | Type | Description |
|---------|------|-------------|
| `hour_timestamp` | TIMESTAMP | Début de l'heure |
| `avg_consumption_kwh` | FLOAT | Consommation moyenne sur l'heure |
| `max_consumption_kwh` | FLOAT | Consommation max |
| `min_consumption_kwh` | FLOAT | Consommation min |
| `std_consumption_kwh` | FLOAT | Écart-type |
| `count_readings` | INTEGER | Nombre de mesures (normalement 2 par heure) |
| `count_anomalies` | INTEGER | Nombre d'anomalies détectées |
| `anomaly_rate_pct` | FLOAT | Taux d'anomalies (%) |

---

### Table : intermediate.int_readings_daily

**Description :** Agrégation des lectures par jour

**Source :** dbt model `models/intermediate/int_readings_daily.sql`

#### Structure (à implémenter)

| Colonne | Type | Description |
|---------|------|-------------|
| `date` | DATE | Date |
| `total_consumption_kwh` | FLOAT | Consommation totale journalière |
| `avg_consumption_kwh` | FLOAT | Consommation moyenne |
| `peak_consumption_kwh` | FLOAT | Pic de consommation |
| `peak_hour` | INTEGER | Heure du pic |
| `avg_temperature_c` | FLOAT | Température moyenne |
| `count_anomalies` | INTEGER | Nombre d'anomalies |

---

### Table : intermediate.int_consumption_features

**Description :** Features pour le modèle ML de détection d'anomalies

**Source :** dbt model `models/intermediate/int_consumption_features.sql`

#### Structure (à implémenter)

| Colonne | Type | Description |
|---------|------|-------------|
| `reading_id` | INTEGER | Référence vers staging |
| `reading_timestamp` | TIMESTAMP | Horodatage |
| `consumption_kwh` | FLOAT | Consommation |
| `avg_1h` | FLOAT | Moyenne glissante 1h |
| `avg_24h` | FLOAT | Moyenne glissante 24h |
| `std_24h` | FLOAT | Écart-type 24h |
| `consumption_vs_avg_ratio` | FLOAT | Ratio consommation / moyenne |
| `hour_of_day` | INTEGER | Heure |
| `day_of_week` | INTEGER | Jour |
| `is_weekend` | BOOLEAN | Weekend |

---

## Schéma marts

> **Note :** Tables créées par dbt (Phase 3). Structure à documenter après implémentation.

### Table : marts.mart_consumption_metrics

**Description :** KPIs de consommation pour dashboards Superset

**Source :** dbt model `models/marts/mart_consumption_metrics.sql`

#### Structure (à implémenter)

| Colonne | Type | Description |
|---------|------|-------------|
| `metric_date` | DATE | Date de la métrique |
| `total_consumption_kwh` | FLOAT | Consommation totale |
| `avg_consumption_kwh` | FLOAT | Consommation moyenne |
| `peak_consumption_kwh` | FLOAT | Pic |
| `peak_hour` | INTEGER | Heure du pic |
| `consumption_variance` | FLOAT | Variance |
| `anomaly_count` | INTEGER | Nombre d'anomalies |
| `anomaly_rate_pct` | FLOAT | Taux d'anomalies |
| `total_loss_estimate_kwh` | FLOAT | Estimation pertes dues aux anomalies |

---

### Table : marts.mart_anomaly_flags

**Description :** Flags d'anomalies détectées pour analyse métier

**Source :** dbt model `models/marts/mart_anomaly_flags.sql`

#### Structure (à implémenter)

| Colonne | Type | Description |
|---------|------|-------------|
| `reading_id` | INTEGER | Référence lecture |
| `reading_timestamp` | TIMESTAMP | Horodatage |
| `consumption_kwh` | FLOAT | Consommation |
| `is_anomaly_labeled` | BOOLEAN | Label dataset Kaggle |
| `is_anomaly_ml` | BOOLEAN | Détection ML (si implémenté) |
| `anomaly_score` | FLOAT | Score ML (0-1) |
| `anomaly_type` | VARCHAR | Type : spike, drop, drift |
| `severity` | VARCHAR | Sévérité : low, medium, high |

---

## Schéma quality

> **Note :** Tables créées par Great Expectations et dbt (Phase 4). Structure à documenter après implémentation.

### Table : quality.ge_validations

**Description :** Résultats des validations Great Expectations

#### Structure (à implémenter)

| Colonne | Type | Description |
|---------|------|-------------|
| `validation_id` | SERIAL | PK |
| `run_timestamp` | TIMESTAMP | Date/heure validation |
| `checkpoint_name` | VARCHAR | Nom checkpoint GE |
| `expectation_suite` | VARCHAR | Suite d'expectations |
| `table_name` | VARCHAR | Table validée |
| `success` | BOOLEAN | Validation réussie |
| `failed_expectations` | INTEGER | Nombre d'expectations échouées |
| `details` | JSONB | Détails échecs |

---

## Relations entre tables

### Diagramme ERD (simplifié)

```
raw_data.meter_readings (1)
         │
         │ (transformations dbt)
         ▼
staging.stg_meter_readings (1)
         │
         ├──▶ intermediate.int_readings_hourly (agrégation)
         │
         ├──▶ intermediate.int_readings_daily (agrégation)
         │
         └──▶ intermediate.int_consumption_features (features ML)
                    │
                    └──▶ marts.mart_consumption_metrics (KPIs)
                    └──▶ marts.mart_anomaly_flags (anomalies)
```

### Clés de jointure

| Table source | Table cible | Clé de jointure | Cardinalité |
|--------------|-------------|-----------------|-------------|
| raw_data.meter_readings | staging.stg_meter_readings | id = reading_id | 1:1 |
| staging.stg_meter_readings | intermediate.int_consumption_features | reading_id | 1:1 |

---

## Index et performances

### Index créés

| Table | Index | Colonnes | Type | Objectif |
|-------|-------|----------|------|----------|
| raw_data.meter_readings | idx_readings_timestamp | timestamp | B-tree | Requêtes temporelles |
| raw_data.meter_readings | idx_readings_anomaly | anomaly_label | B-tree | Filtrage anomalies |

### Recommandations futures

- Index composite sur (timestamp, anomaly_label) si requêtes fréquentes
- Partitionnement par mois sur raw_data.meter_readings si volume > 10M lignes
- Index sur marts.mart_consumption_metrics(metric_date) pour dashboards

---

## Règles de gestion

### Gestion des valeurs NULL

| Champ | Règle NULL | Action si NULL |
|-------|------------|----------------|
| timestamp | NOT NULL | Rejet de la ligne |
| electricity_consumed | Autorisé | Imputation par médiane (dbt) |
| temperature | Autorisé | Imputation par médiane |
| humidity | Autorisé | Imputation par médiane |
| wind_speed | Autorisé | Imputation par médiane |

### Gestion des doublons

| Table | Critère unicité | Action si doublon |
|-------|-----------------|-------------------|
| raw_data.meter_readings | timestamp | Garder la première occurrence |

### Gestion des outliers

| Champ | Plage valide | Action hors plage |
|-------|--------------|-------------------|
| electricity_consumed | >= 0 | Rejet ou imputation |
| temperature | -50°C à 60°C | Rejet ou imputation |
| humidity | 0% à 100% | Rejet ou imputation |
| wind_speed | >= 0 | Rejet ou imputation |

---

## Évolutions futures

### Phase 2 : Ingestion
- [ ] Documenter volumétrie réelle après téléchargement
- [ ] Ajouter exemples de données réelles
- [ ] Documenter temps d'ingestion

### Phase 3 : dbt
- [ ] Compléter structure tables staging/intermediate/marts
- [ ] Documenter transformations SQL appliquées
- [ ] Ajouter schémas de lineage dbt

### Phase 4 : Great Expectations
- [ ] Documenter expectations configurées
- [ ] Ajouter résultats validations
- [ ] Documenter table quality.ge_validations

### Phase 5 : Machine Learning
- [ ] Documenter table résultats ML
- [ ] Ajouter colonnes scores anomalies
- [ ] Documenter features utilisées

---

**Fin du Data Dictionary - Mise à jour continue au fur et à mesure des phases**
