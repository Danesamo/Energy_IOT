# ROADMAP TECHNIQUE - Energy IoT Pipeline

> **Document de référence** pour l'implémentation du projet
>
> Dernière mise à jour : Février 2025

---

## Table des Matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Choix architecturaux justifiés](#2-choix-architecturaux-justifiés)
3. [Phases du projet](#3-phases-du-projet)
4. [Détail des composants](#4-détail-des-composants)
5. [Ordre d'implémentation](#5-ordre-dimplémentation)
6. [Arborescence finale](#6-arborescence-finale)
7. [Critères de succès](#7-critères-de-succès)

---

## 1. Vue d'ensemble

### 1.1 Rappel du problème métier

Les compagnies d'électricité en Afrique perdent **15-30% de leur énergie** à cause de :
- Fraude (branchements pirates, compteurs trafiqués)
- Pertes techniques (câbles défaillants)
- Erreurs de comptage

**Notre solution** : Un pipeline de données qui analyse automatiquement les relevés de compteurs pour détecter les anomalies.

### 1.2 Ce que nous construisons

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ENERGY IoT PIPELINE                                  │
│                                                                              │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐       │
│  │  DATA   │──▶│  INGEST │──▶│TRANSFORM│──▶│VALIDATE │──▶│   ML    │       │
│  │ SOURCE  │   │         │   │  (dbt)  │   │  (GE)   │   │ANOMALY  │       │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘       │
│      CSV         Python         SQL         Python        Python            │
│                                                              │               │
│                                                              ▼               │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐              ┌─────────┐          │
│  │ MONITOR │◀──│VISUALIZE│◀──│ANALYTICS│◀─────────────│ RESULTS │          │
│  │(Grafana)│   │(Superset│   │(ClickH.)│              │  (DB)   │          │
│  └─────────┘   └─────────┘   └─────────┘              └─────────┘          │
│                                                                              │
│  └──────────────────── AIRFLOW (Orchestration) ─────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.3 Résumé des choix techniques

| Aspect | Choix | Justification courte |
|--------|-------|---------------------|
| Pipeline | **ELT** | Transformation dans la base (moderne) |
| Processing | **Batch** | Données historiques, pas de temps réel |
| Storage OLTP | **PostgreSQL** | Robuste, standard, gratuit |
| Storage OLAP | **ClickHouse** | 10-100x plus rapide pour analytics |
| Transformation | **dbt** | SQL versionné, testé, documenté |
| Data Quality | **Great Expectations** | Standard industrie |
| ML | **Isolation Forest** | Non supervisé, adapté aux anomalies |
| Orchestration | **Airflow** | Standard industrie |
| Visualisation | **Superset** | Open-source, puissant |
| Monitoring | **Grafana** | Alertes, dashboards ops |

---

## 2. Choix architecturaux justifiés

### 2.1 Pourquoi ELT et pas ETL ?

#### ETL (Extract-Transform-Load) - L'ancienne approche

```
Source → [Outil externe transforme] → Base de données
              (Talend, SSIS)
```

**Problèmes :**
- Transformation hors de la base = lent
- Outil propriétaire souvent payant
- Difficile à versionner et tester

#### ELT (Extract-Load-Transform) - L'approche moderne

```
Source → Base de données → [Transformation SQL dans la base]
                                    (dbt)
```

**Avantages :**
- La base de données fait le travail (optimisée pour ça)
- dbt = SQL pur, versionnable avec Git
- Tests intégrés
- Documentation auto-générée

**Notre choix : ELT avec dbt**

---

### 2.2 Pourquoi Batch et pas Streaming ?

| Critère | Batch | Streaming |
|---------|-------|-----------|
| **Latence** | Minutes à heures | Secondes |
| **Complexité** | Simple | Élevée (Kafka, Flink) |
| **Coût** | Faible | Élevé |
| **Cas d'usage** | Rapports, analytics | Alertes temps réel |

**Notre contexte :**
- Dataset Smart Meter (Kaggle) = données Smart Meter avec labels anomalies
- Objectif = analyser des patterns, pas réagir en temps réel
- Un DAG Airflow quotidien suffit

**Notre choix : Batch Processing**

> **Note** : En production avec de vrais compteurs IoT, on ajouterait une couche streaming (Kafka) pour les alertes critiques.

---

### 2.3 Pourquoi PostgreSQL + ClickHouse ?

#### Le problème : OLTP vs OLAP

| Type | Optimisé pour | Exemple |
|------|--------------|---------|
| **OLTP** | Écritures, transactions | INSERT, UPDATE fréquents |
| **OLAP** | Lectures analytiques | SELECT avec agrégations |

PostgreSQL est OLTP. Il est bon pour stocker les données brutes, mais lent pour :
```sql
SELECT DATE(reading_time), AVG(power), SUM(consumption)
FROM readings
WHERE year = 2024
GROUP BY DATE(reading_time)
-- Sur 2M lignes : ~5 secondes en PostgreSQL
-- Sur 2M lignes : ~0.1 seconde en ClickHouse
```

#### ClickHouse : Stockage colonnes

```
PostgreSQL (lignes) :          ClickHouse (colonnes) :
┌────┬───────┬───────┐         ┌────┬────┬────┬────┐
│ id │ power │ date  │         │ id │ id │ id │ id │  ← Colonne id
├────┼───────┼───────┤         ├────┴────┴────┴────┤
│ 1  │ 2.5   │ 01/01 │         │2.5 │3.1 │2.8 │4.0 │  ← Colonne power
│ 2  │ 3.1   │ 01/02 │         ├────┴────┴────┴────┤
│ 3  │ 2.8   │ 01/03 │         │01/01│01/02│...    │  ← Colonne date
└────┴───────┴───────┘         └───────────────────┘
```

Quand Superset demande `AVG(power)`, ClickHouse ne lit QUE la colonne `power` → **100x plus rapide**.

**Notre choix : PostgreSQL (staging) + ClickHouse (analytics)**

---

### 2.4 Pourquoi dbt ?

#### Le problème : SQL non géré

Sans dbt, les transformations SQL sont :
- Des scripts éparpillés
- Sans tests
- Sans documentation
- Sans dépendances claires

#### La solution dbt

```
dbt/
├── models/
│   ├── staging/           ← Couche 1 : Nettoyage
│   │   └── stg_readings.sql
│   ├── intermediate/      ← Couche 2 : Agrégations
│   │   └── int_hourly.sql
│   └── marts/             ← Couche 3 : KPIs finaux
│       └── mart_anomalies.sql
└── tests/                 ← Tests automatiques
```

**Ce que dbt apporte :**

| Fonctionnalité | Bénéfice |
|----------------|----------|
| **Modularité** | Un fichier SQL = un modèle |
| **Dépendances** | `ref('stg_readings')` crée automatiquement l'ordre d'exécution |
| **Tests** | `unique`, `not_null`, tests custom |
| **Documentation** | Génération automatique de docs + lineage |
| **Versioning** | Tout est du code, versionné avec Git |

**Notre choix : dbt Core (gratuit)**

---

### 2.5 Pourquoi Great Expectations ?

#### Le problème : Données de mauvaise qualité

Sans validation, on découvre les problèmes trop tard :
- Valeurs nulles
- Doublons
- Valeurs hors plage (tension = -500V ?)
- Format incorrect

#### La solution Great Expectations

```python
# Exemple d'expectation
expect_column_values_to_be_between(
    column="voltage",
    min_value=200,
    max_value=260
)
```

**Ce que GE apporte :**

| Fonctionnalité | Bénéfice |
|----------------|----------|
| **Expectations** | Règles de validation déclaratives |
| **Checkpoints** | Points de contrôle dans le pipeline |
| **Data Docs** | Rapport HTML des validations |
| **Profiling** | Analyse automatique des données |

**Notre choix : Great Expectations avec validations avancées**

---

### 2.6 Pourquoi Isolation Forest pour le ML ?

#### Le contexte

- **Objectif** : Détecter les consommations anormales
- **Contrainte** : Pas de labels (on ne sait pas quelles lignes sont des anomalies)
- **Volume** : 2M lignes

#### Comparaison des algorithmes

| Algorithme | Supervisé ? | Complexité | Performance | Interprétabilité |
|------------|-------------|------------|-------------|------------------|
| Règles Z-score | Non | Très simple | Moyenne | Excellente |
| **Isolation Forest** | **Non** | **Simple** | **Bonne** | **Bonne** |
| Local Outlier Factor | Non | Moyenne | Bonne | Moyenne |
| Autoencoders | Non | Complexe | Excellente | Faible |
| One-Class SVM | Non | Complexe | Bonne | Faible |

#### Pourquoi Isolation Forest ?

**Principe** : Les anomalies sont "isolées" plus facilement que les points normaux.

```
          Normal points (clustered)
                 ●●●
                ●●●●●
               ●●●●●●●
                ●●●●●
                 ●●●

    ○                              ○
 Anomalie                      Anomalie
(facile à isoler)          (facile à isoler)
```

**Avantages pour notre cas :**

1. **Non supervisé** : Pas besoin de données étiquetées
2. **Rapide** : O(n log n), scale bien sur 2M lignes
3. **Peu de paramètres** : `contamination` (% d'anomalies attendu)
4. **Score continu** : Pas juste "anomalie/normal", mais un score de 0 à 1
5. **Robuste** : Fonctionne même si les données d'entraînement contiennent des anomalies

**Notre choix : Isolation Forest via scikit-learn**

---

### 2.7 Architecture Data : Pourquoi pas Data Lake ?

| Architecture | Quand l'utiliser | Notre cas |
|--------------|------------------|-----------|
| **Data Lake** | Données non structurées, Big Data (TB+) | Non - données tabulaires, 130 MB |
| **Data Lakehouse** | Hybride, Delta Lake/Iceberg | Non - over-engineering |
| **Data Warehouse** | Données structurées, analytics | **Oui - adapté** |
| **Data Mart** | Sous-ensemble pour un domaine | **Oui - ClickHouse** |

**Notre choix : Mini Data Warehouse (PostgreSQL) + Data Mart analytique (ClickHouse)**

---

## 3. Phases du projet

### Phase 0 : Fondations (FAIT)
**Objectif** : Structure du projet, documentation de cadrage

| Livrable | Fichier | Statut |
|----------|---------|--------|
| Étude domaine | `docs/01_ETUDE_DOMAINE_ENERGIE.md` | ✅ |
| Étude projet | `docs/02_ETUDE_PROJET.md` | ✅ |
| README | `README.md` | ✅ |
| Gitignore | `.gitignore` | ✅ |
| Variables env | `.env.example` | ✅ |
| Makefile | `Makefile` | ✅ |
| Docker Compose | `docker-compose.yml` | ✅ |
| Requirements | `requirements.txt` | ✅ |
| Config Docker | `docker/` | ✅ |

---

### Phase 1 : Infrastructure
**Objectif** : Environnement Docker fonctionnel

| Livrable | Description | Fichiers |
|----------|-------------|----------|
| PostgreSQL opérationnel | Base raw + schemas | `docker/postgres/init.sql` |
| ClickHouse opérationnel | Base analytics | `docker/clickhouse/` |
| Airflow opérationnel | Interface web accessible | Inclus dans docker-compose |
| Superset opérationnel | Interface web accessible | `docker/superset/` |
| Grafana opérationnel | Interface web accessible | `monitoring/grafana/` |

**Critère de succès** : `docker compose up -d` démarre tous les services sans erreur.

---

### Phase 2 : Ingestion des données
**Objectif** : Charger les données Smart Meter (Kaggle) dans PostgreSQL

| Livrable | Description | Fichiers |
|----------|-------------|----------|
| Script téléchargement | Kaggle CLI download | Dans Makefile (`make download-data`) |
| Script ingestion | CSV → PostgreSQL | `src/ingestion/load_data.py` |
| Validation ingestion | Vérifier le nombre de lignes | Tests SQL |

**Dataset** : [Smart Meter Dataset (Kaggle)](https://www.kaggle.com/datasets/ziya07/smart-meter-electricity-consumption-dataset)

**Colonnes attendues** : Timestamp, Electricity_Consumed, Temperature, Humidity, Wind_Speed, Avg_Past_Consumption, Anomaly_Label

**Critère de succès** : Toutes les lignes du dataset chargées dans `raw_data.meter_readings` (volumétrie à déterminer après téléchargement).

---

### Phase 3 : Transformations dbt
**Objectif** : Pipeline de transformation SQL

| Couche | Modèles | Description |
|--------|---------|-------------|
| **Staging** | `stg_meter_readings` | Nettoyage, typage, filtrage nulls |
| **Intermediate** | `int_readings_hourly` | Agrégation par heure |
| **Intermediate** | `int_readings_daily` | Agrégation par jour |
| **Intermediate** | `int_consumption_features` | Features pour ML |
| **Marts** | `mart_consumption_metrics` | KPIs finaux |
| **Marts** | `mart_anomaly_scores` | Résultats ML |

**Fichiers :**
```
dbt/
├── dbt_project.yml
├── profiles.yml
├── models/
│   ├── staging/
│   │   ├── _staging__models.yml
│   │   └── stg_meter_readings.sql
│   ├── intermediate/
│   │   ├── _intermediate__models.yml
│   │   ├── int_readings_hourly.sql
│   │   ├── int_readings_daily.sql
│   │   └── int_consumption_features.sql
│   └── marts/
│       ├── _marts__models.yml
│       ├── mart_consumption_metrics.sql
│       └── mart_anomaly_scores.sql
├── tests/
│   └── assert_positive_power.sql
└── macros/
    └── calculate_z_score.sql
```

**Critère de succès** : `dbt build` passe sans erreur.

---

### Phase 4 : Data Quality (Great Expectations)
**Objectif** : Validation automatique des données

| Suite | Table validée | Expectations |
|-------|---------------|--------------|
| `raw_readings_suite` | `raw_data.meter_readings` | Complétude, types, ranges |
| `staging_readings_suite` | `staging.stg_meter_readings` | Nulls, unicité |
| `marts_metrics_suite` | `marts.mart_consumption_metrics` | Cohérence KPIs |

**Expectations implémentées :**

```yaml
# raw_readings_suite
- expect_column_to_exist: [timestamp, electricity_consumed, temperature, ...]
- expect_column_values_to_not_be_null: [timestamp, electricity_consumed]
- expect_column_values_to_be_between:
    column: temperature
    min: -50
    max: 60
- expect_column_values_to_be_between:
    column: electricity_consumed
    min: 0
    max: 100
- expect_column_values_to_be_between:
    column: humidity
    min: 0
    max: 100
```

**Fichiers :**
```
great_expectations/
├── great_expectations.yml
├── expectations/
│   ├── raw_readings_suite.json
│   ├── staging_readings_suite.json
│   └── marts_metrics_suite.json
├── checkpoints/
│   └── energy_checkpoint.yml
└── plugins/
```

**Critère de succès** : `great_expectations checkpoint run energy_checkpoint` → toutes validations passent.

---

### Phase 5 : Machine Learning (Anomaly Detection)
**Objectif** : Détecter les consommations anormales

| Composant | Description | Fichier |
|-----------|-------------|---------|
| Feature engineering | Créé par dbt (Phase 3) | `int_consumption_features.sql` |
| Entraînement modèle | Isolation Forest | `src/ml/train_anomaly_model.py` |
| Scoring | Appliquer modèle sur nouvelles données | `src/ml/score_anomalies.py` |
| Stockage résultats | Écrire dans PostgreSQL | Via script |

**Features utilisées pour le ML :**

| Feature | Description | Calcul |
|---------|-------------|--------|
| `avg_consumption_1h` | Consommation moyenne sur 1h | AVG sur fenêtre 1h |
| `avg_consumption_24h` | Consommation moyenne sur 24h | AVG sur fenêtre 24h |
| `std_consumption_24h` | Écart-type sur 24h | STDDEV sur fenêtre 24h |
| `consumption_vs_avg_ratio` | Ratio vs moyenne historique | current / avg_24h |
| `hour_of_day` | Heure (0-23) | EXTRACT(HOUR) |
| `day_of_week` | Jour (0-6) | EXTRACT(DOW) |
| `is_weekend` | Flag weekend | CASE WHEN dow IN (0,6) |
| `temperature` | Température extérieure | Depuis dataset |
| `humidity` | Humidité relative | Depuis dataset |
| `wind_speed` | Vitesse du vent | Depuis dataset |

**Fichiers :**
```
src/ml/
├── __init__.py
├── config.py              # Hyperparamètres
├── features.py            # Chargement features depuis DB
├── train_anomaly_model.py # Entraînement Isolation Forest
├── score_anomalies.py     # Application du modèle
└── utils.py               # Fonctions utilitaires

models/                    # Modèles sérialisés
└── isolation_forest_v1.joblib
```

**Critère de succès** : Table `marts.mart_anomaly_scores` contient des scores d'anomalie pour chaque observation.

---

### Phase 6 : Synchronisation ClickHouse
**Objectif** : Copier les données marts vers ClickHouse pour analytics rapides

| Source (PostgreSQL) | Destination (ClickHouse) |
|---------------------|--------------------------|
| `marts.mart_consumption_metrics` | `energy_analytics.consumption_metrics` |
| `marts.mart_anomaly_scores` | `energy_analytics.anomaly_scores` |

**Fichiers :**
```
src/sync/
├── __init__.py
└── postgres_to_clickhouse.py
```

**Critère de succès** : Données identiques dans ClickHouse, requêtes 10x+ plus rapides.

---

### Phase 7 : Orchestration Airflow
**Objectif** : Automatiser l'exécution quotidienne du pipeline

**DAG principal : `energy_pipeline_daily`**

```
┌─────────────────────────────────────────────────────────────────┐
│                     DAG: energy_pipeline_daily                   │
│                     Schedule: 0 6 * * * (6h UTC)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   [start] ──▶ [check_source] ──▶ [ingest_data]                  │
│                                        │                         │
│                                        ▼                         │
│                                 [dbt_run_staging]                │
│                                        │                         │
│                                        ▼                         │
│                              [dbt_run_intermediate]              │
│                                        │                         │
│                                        ▼                         │
│                                [ge_validate_staging]             │
│                                        │                         │
│                                        ▼                         │
│                                  [ml_score]                      │
│                                        │                         │
│                                        ▼                         │
│                                [dbt_run_marts]                   │
│                                        │                         │
│                                        ▼                         │
│                              [ge_validate_marts]                 │
│                                        │                         │
│                                        ▼                         │
│                              [sync_to_clickhouse]                │
│                                        │                         │
│                                        ▼                         │
│                                     [end]                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Fichiers :**
```
airflow/dags/
├── energy_pipeline_daily.py
├── utils/
│   ├── __init__.py
│   └── slack_alerts.py      # (optionnel) Alertes Slack
└── sql/
    └── check_source.sql
```

**Critère de succès** : DAG exécutable manuellement et sur schedule.

---

### Phase 8 : Visualisation Superset
**Objectif** : Dashboards interactifs

**Dashboards à créer :**

| Dashboard | Contenu | Source |
|-----------|---------|--------|
| **Overview** | KPIs globaux, trends | `consumption_metrics` |
| **Anomalies** | Carte des anomalies, détails | `anomaly_scores` |
| **Patterns** | Heatmaps jour/heure, saisonnalité | `consumption_metrics` |

**Visualisations clés :**

1. **Line chart** : Consommation dans le temps
2. **Heatmap** : Consommation par heure et jour de semaine
3. **Scatter plot** : Anomalies (score vs consommation)
4. **Big Number** : KPIs (conso totale, nb anomalies, %)
5. **Table** : Top 10 anomalies avec détails

**Fichiers :**
```
dashboards/
├── exports/
│   └── energy_dashboards.zip   # Export Superset
└── screenshots/
    ├── overview.png
    ├── anomalies.png
    └── patterns.png
```

**Critère de succès** : 3 dashboards fonctionnels, exportables.

---

### Phase 9 : Monitoring Grafana
**Objectif** : Surveillance opérationnelle

**Dashboards Grafana :**

| Dashboard | Métriques |
|-----------|-----------|
| **Pipeline Health** | Durée DAG, taux de succès, dernière exécution |
| **Data Quality** | Taux de validation GE, nb anomalies détectées |
| **Infrastructure** | CPU, mémoire, espace disque des conteneurs |

**Fichiers :**
```
monitoring/
├── grafana/
│   ├── provisioning/
│   │   ├── dashboards/
│   │   │   └── dashboards.yml
│   │   └── datasources/
│   │       └── datasources.yml
│   └── dashboards/
│       ├── pipeline_health.json
│       └── data_quality.json
└── prometheus/                # (optionnel)
    └── prometheus.yml
```

**Critère de succès** : Dashboards Grafana affichent les métriques en temps réel.

---

### Phase 10 : Documentation & Finalisation
**Objectif** : Projet livrable et compréhensible

| Document | Contenu |
|----------|---------|
| `docs/04_DATA_DICTIONARY.md` | Description de chaque table et colonne |
| `docs/05_RUNBOOK.md` | Guide d'exécution pas à pas |
| `docs/06_ARCHITECTURE_DETAILLEE.md` | Schémas techniques |
| README mis à jour | Screenshots, démo GIF |

**Critère de succès** : Quelqu'un peut cloner le repo et exécuter le projet en suivant le README.

---

## 4. Détail des composants

### 4.1 Flux de données détaillé

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLUX DE DONNÉES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. SOURCE                                                                   │
│  ┌──────────────────────┐                                                   │
│  │ Smart Meter Dataset  │  Format: CSV                                      │
│  │ (Kaggle)             │  Fréquence: 1 mesure / 30 min                     │
│  │                      │  Licence: CC0 Public Domain                       │
│  │  Colonnes:           │                                                   │
│  │  - Timestamp         │  Horodatage                                       │
│  │  - Electricity_Consumed (kWh)                                            │
│  │  - Temperature (°C)  │                                                   │
│  │  - Humidity (%)      │                                                   │
│  │  - Wind_Speed (km/h) │                                                   │
│  │  - Avg_Past_Consumption (kWh)                                            │
│  │  - Anomaly_Label     │  Normal / Anomalie                                │
│  └──────────┬───────────┘                                                   │
│             │                                                                │
│             ▼  Python (pandas)                                               │
│  2. INGESTION                                                                │
│  ┌──────────────────────┐                                                   │
│  │ PostgreSQL           │  Schema: raw_data                                 │
│  │ raw_data.meter_      │  Table: meter_readings                            │
│  │ readings             │  + colonnes: id, ingested_at, source_file         │
│  └──────────┬───────────┘                                                   │
│             │                                                                │
│             ▼  dbt (SQL)                                                     │
│  3. STAGING                                                                  │
│  ┌──────────────────────┐                                                   │
│  │ staging.stg_meter_   │  Transformations:                                 │
│  │ readings             │  - CAST des types                                 │
│  │                      │  - Filtrage des nulls                             │
│  │                      │  - Renommage colonnes                             │
│  │                      │  - Calcul: reading_timestamp                      │
│  └──────────┬───────────┘                                                   │
│             │                                                                │
│             ▼  Great Expectations                                            │
│  4. VALIDATION                                                               │
│  ┌──────────────────────┐                                                   │
│  │ Expectations:        │  - Pas de nulls critiques                         │
│  │ - Complétude         │  - Temperature entre -50 et 60°C                  │
│  │ - Plages valides     │  - Humidity entre 0-100%                          │
│  │ - Cohérence          │  - Dates cohérentes                               │
│  └──────────┬───────────┘                                                   │
│             │                                                                │
│             ▼  dbt (SQL)                                                     │
│  5. INTERMEDIATE                                                             │
│  ┌──────────────────────┐                                                   │
│  │ int_readings_hourly  │  Agrégation par heure:                            │
│  │                      │  - avg_power, max_power, min_power                │
│  │                      │  - total_consumption                              │
│  │                      │  - avg_voltage                                    │
│  ├──────────────────────┤                                                   │
│  │ int_readings_daily   │  Agrégation par jour:                             │
│  │                      │  - daily_consumption                              │
│  │                      │  - peak_hour, peak_power                          │
│  ├──────────────────────┤                                                   │
│  │ int_consumption_     │  Features pour ML:                                │
│  │ features             │  - rolling averages (1h, 24h)                     │
│  │                      │  - std deviations                                 │
│  │                      │  - ratios sub_metering                            │
│  │                      │  - temporal features                              │
│  └──────────┬───────────┘                                                   │
│             │                                                                │
│             ▼  Python (scikit-learn)                                         │
│  6. ML SCORING                                                               │
│  ┌──────────────────────┐                                                   │
│  │ Isolation Forest     │  Input: int_consumption_features                  │
│  │                      │  Output: anomaly_score (0-1)                      │
│  │                      │  Threshold: score > 0.6 = anomalie                │
│  └──────────┬───────────┘                                                   │
│             │                                                                │
│             ▼  dbt (SQL)                                                     │
│  7. MARTS                                                                    │
│  ┌──────────────────────┐                                                   │
│  │ mart_consumption_    │  KPIs:                                            │
│  │ metrics              │  - daily/weekly/monthly consumption               │
│  │                      │  - trends, comparisons                            │
│  ├──────────────────────┤                                                   │
│  │ mart_anomaly_scores  │  Résultats ML:                                    │
│  │                      │  - timestamp, power, score                        │
│  │                      │  - is_anomaly flag                                │
│  │                      │  - anomaly_type (high/low/pattern)                │
│  └──────────┬───────────┘                                                   │
│             │                                                                │
│             ▼  Python (sync script)                                          │
│  8. CLICKHOUSE                                                               │
│  ┌──────────────────────┐                                                   │
│  │ energy_analytics.    │  Copie des marts                                  │
│  │ consumption_metrics  │  Optimisé pour queries BI                         │
│  │ anomaly_scores       │  Stockage colonnes                                │
│  └──────────┬───────────┘                                                   │
│             │                                                                │
│             ▼  SQL queries                                                   │
│  9. VISUALISATION                                                            │
│  ┌──────────────────────┐                                                   │
│  │ Superset Dashboards  │  - Overview                                       │
│  │                      │  - Anomalies                                      │
│  │                      │  - Patterns                                       │
│  └──────────────────────┘                                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Modèle de données

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MODÈLE DE DONNÉES                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  RAW_DATA (PostgreSQL)                                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ meter_readings                                                       │    │
│  ├─────────────────────────────────────────────────────────────────────┤    │
│  │ id                  SERIAL PRIMARY KEY                               │    │
│  │ timestamp           TIMESTAMP NOT NULL                               │    │
│  │ electricity_consumed DECIMAL(10,4)   -- kWh                         │    │
│  │ temperature         DECIMAL(5,2)     -- °C                          │    │
│  │ humidity            DECIMAL(5,2)     -- %                           │    │
│  │ wind_speed          DECIMAL(5,2)     -- km/h                        │    │
│  │ avg_past_consumption DECIMAL(10,4)   -- kWh                         │    │
│  │ anomaly_label       VARCHAR(20)      -- Normal/Anomaly              │    │
│  │ ingested_at         TIMESTAMP DEFAULT NOW()                          │    │
│  │ source_file         VARCHAR(255)                                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  STAGING (PostgreSQL - Vue dbt)                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ stg_meter_readings                                                   │    │
│  ├─────────────────────────────────────────────────────────────────────┤    │
│  │ reading_id          INTEGER (from id)                                │    │
│  │ reading_timestamp   TIMESTAMP                                        │    │
│  │ consumption_kwh     FLOAT                                           │    │
│  │ temperature_c       FLOAT                                           │    │
│  │ humidity_pct        FLOAT                                           │    │
│  │ wind_speed_kmh      FLOAT                                           │    │
│  │ avg_past_consumption_kwh FLOAT                                      │    │
│  │ anomaly_label       VARCHAR                                         │    │
│  │ -- Colonnes calculées                                                │    │
│  │ hour_of_day         INTEGER (0-23)                                   │    │
│  │ day_of_week         INTEGER (0-6)                                    │    │
│  │ is_anomaly          BOOLEAN                                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  INTERMEDIATE (PostgreSQL - Tables dbt)                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ int_readings_hourly                                                  │    │
│  ├─────────────────────────────────────────────────────────────────────┤    │
│  │ hour_start          TIMESTAMP                                        │    │
│  │ avg_power_kw        FLOAT                                           │    │
│  │ max_power_kw        FLOAT                                           │    │
│  │ min_power_kw        FLOAT                                           │    │
│  │ total_consumption_kwh FLOAT                                         │    │
│  │ avg_voltage_v       FLOAT                                           │    │
│  │ reading_count       INTEGER                                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ int_consumption_features                                             │    │
│  ├─────────────────────────────────────────────────────────────────────┤    │
│  │ reading_id          INTEGER                                          │    │
│  │ reading_timestamp   TIMESTAMP                                        │    │
│  │ active_power_kw     FLOAT                                           │    │
│  │ -- Rolling features                                                  │    │
│  │ avg_power_1h        FLOAT                                           │    │
│  │ avg_power_24h       FLOAT                                           │    │
│  │ std_power_24h       FLOAT                                           │    │
│  │ -- Ratios                                                            │    │
│  │ power_vs_avg_ratio  FLOAT                                           │    │
│  │ sub1_ratio          FLOAT                                           │    │
│  │ sub2_ratio          FLOAT                                           │    │
│  │ sub3_ratio          FLOAT                                           │    │
│  │ -- Temporal                                                          │    │
│  │ hour_of_day         INTEGER (0-23)                                   │    │
│  │ day_of_week         INTEGER (0-6)                                    │    │
│  │ is_weekend          BOOLEAN                                          │    │
│  │ month               INTEGER (1-12)                                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  MARTS (PostgreSQL - Tables dbt)                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ mart_anomaly_scores                                                  │    │
│  ├─────────────────────────────────────────────────────────────────────┤    │
│  │ reading_id          INTEGER                                          │    │
│  │ reading_timestamp   TIMESTAMP                                        │    │
│  │ active_power_kw     FLOAT                                           │    │
│  │ anomaly_score       FLOAT (0-1, higher = more anomalous)            │    │
│  │ is_anomaly          BOOLEAN (score > threshold)                      │    │
│  │ anomaly_type        VARCHAR (high_consumption, low_consumption,      │    │
│  │                              unusual_pattern, null)                  │    │
│  │ scored_at           TIMESTAMP                                        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Ordre d'implémentation

### Semaine 1 : Infrastructure + Ingestion

| Jour | Tâches |
|------|--------|
| J1 | Valider docker-compose, démarrer tous les services |
| J2 | Télécharger dataset Smart Meter (Kaggle), explorer les données |
| J3 | Implémenter script d'ingestion Python |
| J4 | Tester ingestion, vérifier données dans PostgreSQL |
| J5 | Documenter, commit |

### Semaine 2 : dbt

| Jour | Tâches |
|------|--------|
| J1 | Setup dbt project, profiles.yml |
| J2 | Modèle staging : stg_meter_readings |
| J3 | Modèles intermediate : hourly, daily |
| J4 | Modèle features pour ML |
| J5 | Tests dbt, documentation |

### Semaine 3 : Great Expectations + ML

| Jour | Tâches |
|------|--------|
| J1 | Setup Great Expectations |
| J2 | Créer expectation suites |
| J3 | Implémenter Isolation Forest |
| J4 | Intégrer scoring dans pipeline |
| J5 | Tests, validation résultats |

### Semaine 4 : Orchestration + Visualisation

| Jour | Tâches |
|------|--------|
| J1 | DAG Airflow principal |
| J2 | Sync PostgreSQL → ClickHouse |
| J3 | Dashboards Superset (Overview) |
| J4 | Dashboards Superset (Anomalies, Patterns) |
| J5 | Dashboard Grafana monitoring |

### Semaine 5 : Finalisation

| Jour | Tâches |
|------|--------|
| J1 | Tests end-to-end |
| J2 | Documentation finale |
| J3 | Screenshots, GIF démo |
| J4 | Review code, cleanup |
| J5 | README final, push GitHub |

---

## 6. Arborescence finale

```
Energy_IoT_Pipeline_Project/
│
├── README.md                          # Documentation principale
├── docker-compose.yml                 # Infrastructure
├── Makefile                          # Commandes utiles
├── requirements.txt                  # Dépendances Python
├── .env.example                      # Variables d'environnement
├── .gitignore                        # Fichiers ignorés
│
├── data/
│   ├── raw/                          # Données brutes (gitignored)
│   │   └── .gitkeep
│   └── processed/                    # Données traitées (gitignored)
│       └── .gitkeep
│
├── docker/
│   ├── postgres/
│   │   └── init.sql                  # Initialisation PostgreSQL
│   ├── clickhouse/
│   │   ├── config.xml
│   │   └── users.xml
│   └── superset/
│       └── superset_config.py
│
├── src/
│   ├── __init__.py
│   ├── ingestion/
│   │   ├── __init__.py
│   │   └── load_data.py              # CSV → PostgreSQL
│   ├── ml/
│   │   ├── __init__.py
│   │   ├── config.py                 # Hyperparamètres
│   │   ├── features.py               # Chargement features
│   │   ├── train_anomaly_model.py    # Entraînement
│   │   └── score_anomalies.py        # Scoring
│   └── sync/
│       ├── __init__.py
│       └── postgres_to_clickhouse.py # Synchronisation
│
├── dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── packages.yml
│   ├── models/
│   │   ├── staging/
│   │   │   ├── _staging__models.yml
│   │   │   ├── _staging__sources.yml
│   │   │   └── stg_meter_readings.sql
│   │   ├── intermediate/
│   │   │   ├── _intermediate__models.yml
│   │   │   ├── int_readings_hourly.sql
│   │   │   ├── int_readings_daily.sql
│   │   │   └── int_consumption_features.sql
│   │   └── marts/
│   │       ├── _marts__models.yml
│   │       ├── mart_consumption_metrics.sql
│   │       └── mart_anomaly_scores.sql
│   ├── tests/
│   │   └── assert_positive_power.sql
│   ├── macros/
│   │   └── calculate_z_score.sql
│   └── seeds/
│       └── .gitkeep
│
├── great_expectations/
│   ├── great_expectations.yml
│   ├── expectations/
│   │   ├── raw_readings_suite.json
│   │   ├── staging_readings_suite.json
│   │   └── marts_metrics_suite.json
│   └── checkpoints/
│       └── energy_checkpoint.yml
│
├── airflow/
│   ├── dags/
│   │   ├── energy_pipeline_daily.py
│   │   └── utils/
│   │       └── __init__.py
│   ├── logs/                         # (gitignored)
│   └── plugins/
│
├── dashboards/
│   ├── exports/
│   │   └── energy_dashboards.zip
│   └── screenshots/
│       ├── overview.png
│       ├── anomalies.png
│       └── patterns.png
│
├── monitoring/
│   └── grafana/
│       ├── provisioning/
│       │   ├── dashboards/
│       │   │   └── dashboards.yml
│       │   └── datasources/
│       │       └── datasources.yml
│       └── dashboards/
│           └── pipeline_health.json
│
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   ├── 02_feature_engineering.ipynb
│   └── 03_anomaly_detection.ipynb
│
├── tests/
│   ├── __init__.py
│   ├── test_ingestion.py
│   ├── test_ml_model.py
│   └── conftest.py
│
├── models/                           # ML models (gitignored except .gitkeep)
│   └── .gitkeep
│
├── configs/
│   └── logging.yml
│
└── docs/
    ├── 01_ETUDE_DOMAINE_ENERGIE.md
    ├── 02_ETUDE_PROJET.md
    ├── 03_ROADMAP_TECHNIQUE.md       # CE DOCUMENT
    ├── 04_DATA_DICTIONARY.md
    ├── 05_RUNBOOK.md
    ├── 06_ARCHITECTURE_DETAILLEE.md
    └── images/
        └── architecture.png
```

---

## 7. Critères de succès

### 7.1 Critères techniques

| Critère | Mesure | Seuil |
|---------|--------|-------|
| Ingestion | Lignes chargées | = 2,075,259 |
| dbt | Tests passants | 100% |
| Great Expectations | Validations passantes | 100% |
| ML | Anomalies détectées | 0.5% - 2% du dataset |
| Performance | Query Superset | < 2 secondes |
| Pipeline | Durée totale DAG | < 30 minutes |

### 7.2 Critères qualité

| Critère | Description |
|---------|-------------|
| **Reproductible** | `docker compose up && make pipeline` fonctionne |
| **Documenté** | Chaque composant expliqué |
| **Testé** | Tests unitaires + tests dbt |
| **Versionné** | Tout dans Git |
| **Compréhensible** | Un non-expert peut comprendre le README |

### 7.3 Livrables finaux

- [ ] Repository GitHub complet
- [ ] README avec screenshots
- [ ] 3 dashboards Superset fonctionnels
- [ ] Pipeline Airflow exécutable
- [ ] Documentation technique complète
- [ ] Modèle ML entraîné et versionné

---

## Annexes

### A. Commandes utiles

```bash
# Démarrer l'infrastructure
docker compose up -d

# Télécharger les données
make download-data

# Exécuter l'ingestion
make ingest

# Exécuter dbt
make dbt-run

# Exécuter les validations
make ge-run

# Pipeline complet
make pipeline

# Voir les logs
make logs
```

### B. URLs des services

| Service | URL | Credentials |
|---------|-----|-------------|
| Superset | http://localhost:8088 | admin / admin |
| Airflow | http://localhost:8080 | admin / H7EpAgSkGXwbhzfR |
| Grafana | http://localhost:3000 | admin / Energy26! |
| ClickHouse | http://localhost:8123 | default / Energy26! |
| PostgreSQL | localhost:5432 | energy_user / Energy26! |

---

**Document maintenu par** : Daniela Samo
**Dernière révision** : Février 2025
