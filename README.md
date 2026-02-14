# Energy IoT Pipeline

Pipeline de données IoT pour le smart metering et l'analyse de consommation énergétique.

> **Statut :** 🚧 En développement


## Le Problème (Pour les non-experts)

Les compagnies d'électricité en Afrique perdent **15-30% de leur énergie** à cause de :
- Vol d'électricité (branchements pirates, compteurs trafiqués)
- Erreurs de compteurs
- Pertes dans les câbles

Cela représente **~5 milliards USD perdus chaque année** en Afrique sub-saharienne.

**Ce projet** construit un système qui analyse automatiquement les données des compteurs pour :
- Détecter les consommations anormales (fraude potentielle)
- Fournir des tableaux de bord pour piloter le réseau
- Assurer la qualité des données


## Aperçu

| Aspect | Description |
|--------|-------------|
| **Domaine** | Énergie / Smart Metering / IoT |
| **Stack** | PostgreSQL, **dbt**, **Great Expectations**, ClickHouse, Superset, Airflow |
| **Données** | Smart Meter Dataset (Kaggle) - contextualisé Afrique |
| **ML** | Détection d'anomalies (Isolation Forest) |


## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ENERGY IoT PIPELINE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│   │   CSV    │───▶│ POSTGRES │───▶│   dbt    │───▶│  GREAT   │             │
│   │(Kaggle)  │    │   RAW    │    │ TRANSFORM│    │EXPECTAT. │             │
│   └──────────┘    └──────────┘    └──────────┘    └──────────┘             │
│                                                         │                    │
│                                                         ▼                    │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│   │  GRAFANA │◀───│ SUPERSET │◀───│CLICKHOUSE│◀───│   ML     │             │
│   │MONITORING│    │DASHBOARDS│    │ ANALYTICS│    │ ANOMALY  │             │
│   └──────────┘    └──────────┘    └──────────┘    └──────────┘             │
│       :3000          :8088           :8123                                   │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │                      AIRFLOW (Orchestration) :8080                    │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```


## Stack Technique

| Catégorie | Technologie | Rôle |
|-----------|-------------|------|
| **Stockage OLTP** | PostgreSQL | Données brutes |
| **Transformation** | dbt Core | Nettoyage, agrégation |
| **Data Quality** | Great Expectations | Validation automatique |
| **Stockage OLAP** | ClickHouse | Analytics rapides |
| **Visualisation** | Apache Superset | Dashboards |
| **Orchestration** | Apache Airflow | Automatisation |
| **Monitoring** | Grafana | Supervision |
| **Conteneurs** | Docker Compose | Infrastructure |


## Structure du Projet

```
Energy_IoT_Pipeline_Project/
├── README.md                     # Ce fichier
├── docker-compose.yml            # Infrastructure complète
├── Makefile                      # Commandes utiles
│
├── data/
│   ├── raw/                      # Données brutes (CSV)
│   └── processed/                # Données traitées
│
├── dbt/                          # Transformations SQL
│   ├── models/
│   │   ├── staging/              # Nettoyage
│   │   ├── intermediate/         # Agrégations
│   │   └── marts/                # KPIs finaux
│   └── tests/                    # Tests dbt
│
├── great_expectations/           # Data Quality
│   ├── expectations/             # Règles de validation
│   └── checkpoints/              # Points de contrôle
│
├── src/
│   ├── ingestion/                # Scripts de chargement
│   └── ml/                       # Modèles ML
│
├── airflow/dags/                 # Orchestration
├── dashboards/                   # Exports Superset
├── notebooks/                    # Exploration
├── tests/                        # Tests unitaires
├── monitoring/                   # Config Prometheus/Grafana
├── docs/                         # Documentation
│   ├── 01_ETUDE_DOMAINE.md       # Contexte métier
│   ├── 02_ETUDE_PROJET.md        # Cadrage projet
│   ├── 03_ARCHITECTURE.md        # Détails techniques
│   ├── 04_DATA_DICTIONARY.md     # Dictionnaire données
│   └── 05_RUNBOOK.md             # Guide d'exécution
└── configs/                      # Configuration
```


## Démarrage Rapide

### Prérequis

- Docker et Docker Compose
- Python 3.12+
- Make (optionnel)

### Installation

```bash
# Cloner le dépôt
git clone https://github.com/Danesamo/Energy_IOT.git
cd Energy_IOT

# Copier le fichier d'environnement
cp .env.example .env

# Télécharger les données
make download-data

# Démarrer l'infrastructure
docker compose up -d

# Exécuter le pipeline dbt
make dbt-run

# Lancer les tests de qualité
make ge-run
```

### Services disponibles

| Service | URL | Credentials |
|---------|-----|-------------|
| **Superset** | http://localhost:8088 | admin / admin |
| **Airflow** | http://localhost:8080 | airflow / airflow |
| **Grafana** | http://localhost:3000 | admin / admin |
| **ClickHouse** | http://localhost:8123 | - |


## Données

**Source :** [Smart Meter Dataset (Kaggle)](https://www.kaggle.com/datasets/ziya07/smart-meter-electricity-consumption-dataset)

| Métrique | Valeur |
|----------|--------|
| **Fréquence** | 1 mesure / 30 min |
| **Variables** | Consommation, température, humidité, vent, anomalies |
| **Labels** | Anomalies pré-étiquetées (Isolation Forest) |
| **Licence** | CC0 Public Domain |

### Note sur les données

Ce projet utilise un dataset open-source pour démontrer le pipeline technique. Les seuils et patterns sont adaptés au **contexte africain** (délestages, pics de soirée, consommation tropicale).

**En production**, le système serait alimenté par les données des utilities locales (SENELEC, ENEO, SBEE) ou systèmes PAYGO (M-KOPA, BBOXX).

**Référence contextuelle** : [Nigeria Electricity Survey 2021](https://www.nature.com/articles/s41597-023-02185-0) - 3,599 ménages, qualité réseau, patterns de consommation.


## Modèles dbt

| Couche | Modèle | Description |
|--------|--------|-------------|
| staging | `stg_readings` | Données nettoyées |
| intermediate | `int_readings_hourly` | Agrégation horaire |
| intermediate | `int_readings_daily` | Agrégation journalière |
| marts | `mart_consumption_metrics` | KPIs consommation |
| marts | `mart_anomaly_flags` | Détection anomalies |


## Documentation

| Document | Description |
|----------|-------------|
| [Étude du Domaine](docs/01_ETUDE_DOMAINE.md) | Contexte métier énergie, smart metering |
| [Étude du Projet](docs/02_ETUDE_PROJET.md) | Objectifs, périmètre, planning |
| [Architecture](docs/03_ARCHITECTURE.md) | Schémas techniques détaillés |
| [Dictionnaire de Données](docs/04_DATA_DICTIONARY.md) | Description des tables et colonnes |
| [Runbook](docs/05_RUNBOOK.md) | Guide d'exécution pas à pas |


## Pourquoi ce projet ?

Ce projet fait partie d'un portfolio ciblant 3 domaines :

| # | Domaine | Projet | Statut |
|---|---------|--------|--------|
| 1 | **Finance** | Credit Risk Scoring | ✅ Terminé |
| 2 | **Énergie** | Energy IoT Pipeline | 🚧 En cours |
| 3 | **Telecoms** | Churn Analytics | ⏳ À venir |

**Objectif :** Démontrer des compétences Data Engineering sur des problématiques métier réelles.


## Auteur

**Daniela Samo** | Data Engineer

- [LinkedIn](https://www.linkedin.com/in/daniela-samo/)
- [GitHub](https://github.com/Danesamo)


## Licence

Ce projet est à but éducatif et de démonstration (portfolio).
Données sous licence CC0 Public Domain (Kaggle).
