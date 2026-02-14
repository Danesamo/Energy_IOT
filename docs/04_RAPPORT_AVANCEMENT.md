# Rapport d'Avancement - Energy IoT Pipeline

## Informations Projet

| Élément | Détail |
|---------|--------|
| **Projet** | Energy IoT Pipeline |
| **Auteur** | Daniela Samo |
| **Date début** | 13 Février 2026 |
| **Date dernière MAJ** | 14 Février 2026 |
| **Statut global** | 🔄 En cours - Phase 1 |
| **Progression** | Phase 0: ✅ | Phase 1: 🔄 0% |

---

## Résumé Exécutif

Ce document trace l'avancement du projet **Energy IoT Pipeline**, les décisions prises, les résultats obtenus et les problèmes rencontrés. Il sert de journal de bord détaillé et constituera la base du rapport final.

**Contexte métier :** Pipeline de données IoT pour détecter les fraudes de consommation électrique en Afrique (pertes de 15-30% de l'énergie = ~5 milliards USD/an).

**Stack technique :** PostgreSQL, ClickHouse, dbt, Great Expectations, Airflow, Superset, Grafana, Docker.

---

# PHASE 0 : FONDATIONS & DOCUMENTATION

**Statut :** ✅ Terminé | **Période :** 13-14 Février 2026

## Objectifs

- Définir l'architecture complète du projet
- Rédiger la documentation de cadrage (métier, technique)
- Préparer l'infrastructure Docker
- Choisir les données appropriées
- Initialiser Git avec la bonne identité

---

## 0.1 Structure du Projet

**Date :** 13/02/2026

### Réalisations

- [x] Arborescence complète créée (dbt, src, airflow, great_expectations, etc.)
- [x] Fichiers de configuration : `docker-compose.yml`, `Makefile`, `requirements.txt`
- [x] Variables d'environnement : `.env.example` avec tous les services
- [x] Gitignore configuré (secrets, données, cache)

### Structure finale

```
Energy_IoT_Pipeline_Project/
├── README.md
├── Makefile                      # 30+ commandes utiles
├── docker-compose.yml            # Infrastructure complète
├── requirements.txt              # Dépendances Python
├── .env.example                  # Template configuration
├── .gitignore
├── data/
│   ├── raw/                      # Données brutes
│   └── processed/                # Données transformées
├── src/
│   ├── ingestion/                # Scripts de chargement
│   └── ml/                       # Modèles ML
├── dbt/                          # Transformations SQL
│   ├── models/
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   ├── macros/
│   ├── tests/
│   └── seeds/
├── great_expectations/           # Data Quality
├── airflow/dags/                 # Orchestration
├── dashboards/                   # Exports Superset
├── notebooks/                    # Exploration
├── monitoring/                   # Grafana/Prometheus
├── docker/                       # Configs Docker
│   ├── postgres/init.sql
│   ├── clickhouse/
│   └── superset/
├── tests/                        # Tests unitaires
└── docs/                         # Documentation
    ├── 01_ETUDE_DOMAINE_ENERGIE.md
    ├── 02_ETUDE_PROJET.md
    ├── 03_ROADMAP_TECHNIQUE.md
    ├── 04_RAPPORT_AVANCEMENT.md     (ce fichier)
    └── 05_DATA_DICTIONARY.md
```

---

## 0.2 Documentation Métier & Technique

**Date :** 13/02/2026

### Documents rédigés

| Document | Taille | Contenu |
|----------|--------|---------|
| `01_ETUDE_DOMAINE_ENERGIE.md` | ~600 lignes | Secteur énergétique, utilities, smart metering, contexte africain, PAYGO solar |
| `02_ETUDE_PROJET.md` | ~500 lignes | Problématique métier, objectifs, périmètre, stack technique, gaps à combler |
| `03_ROADMAP_TECHNIQUE.md` | ~1000 lignes | Choix architecturaux justifiés (ELT vs ETL, Batch vs Streaming, PostgreSQL+ClickHouse), phases détaillées |
| `README.md` | ~220 lignes | Vue d'ensemble, quick start, architecture, datasets |

**Total documentation initiale :** ~2300 lignes (~100 pages)

### Points clés documentés

- **Secteur énergie** : Chaîne de valeur production → distribution, pertes techniques et non-techniques
- **Contexte africain** : Délestages, prépaiement, PAYGO solar (M-KOPA, BBOXX)
- **Stack justifié** : Pourquoi dbt (SQL versionné), pourquoi Great Expectations (data quality), pourquoi ClickHouse (OLAP)
- **Architecture** : ELT moderne vs ETL legacy, Batch processing adapté aux données historiques
- **KPIs métier** : Taux de pertes, détection de fraude, prévision de charge

---

## 0.3 Infrastructure Docker

**Date :** 13/02/2026

### Services configurés dans docker-compose.yml

| Service | Image | Port | Rôle |
|---------|-------|------|------|
| **PostgreSQL** | postgres:15-alpine | 5432 | Stockage OLTP (données brutes) |
| **ClickHouse** | clickhouse:23.8-alpine | 8123, 9000 | Stockage OLAP (analytics rapides) |
| **Airflow Webserver** | apache/airflow:2.8.1 | 8080 | Interface orchestration |
| **Airflow Scheduler** | apache/airflow:2.8.1 | - | Exécution DAGs |
| **Superset** | apache/superset:latest | 8088 | Dashboards BI |
| **Grafana** | grafana/grafana:latest | 3000 | Monitoring infrastructure |
| **PostgreSQL Airflow** | postgres:15-alpine | - | Métadonnées Airflow |

**Total :** 7 services Docker

### Fichiers de configuration créés

- [x] `docker/postgres/init.sql` - Schémas (raw_data, staging, intermediate, marts, quality)
- [x] `docker/clickhouse/config.xml` - Configuration ClickHouse
- [x] `docker/clickhouse/users.xml` - Utilisateurs ClickHouse
- [x] `docker/superset/superset_config.py` - Configuration Superset

### Healthchecks configurés

Tous les services ont des healthchecks pour vérifier leur disponibilité avant démarrage des services dépendants.

---

## 0.4 Makefile - Automatisation

**Date :** 13/02/2026

### Commandes créées

**Infrastructure :**
- `make setup` - Setup initial (copie .env, crée répertoires)
- `make up` - Démarrer tous les services Docker
- `make down` - Arrêter tous les services
- `make ps` - Statut des conteneurs
- `make logs` - Voir les logs de tous les services
- `make logs-postgres`, `make logs-airflow`, etc.

**Données :**
- `make download-data` - Télécharger dataset Kaggle (via API)
- `make download-data-manual` - Instructions téléchargement manuel
- `make ingest` - Lancer l'ingestion vers PostgreSQL

**dbt :**
- `make dbt-deps` - Installer dépendances dbt
- `make dbt-run` - Exécuter les transformations
- `make dbt-test` - Lancer les tests dbt
- `make dbt-build` - Run + test
- `make dbt-docs` - Générer et servir la documentation

**Great Expectations :**
- `make ge-init` - Initialiser Great Expectations
- `make ge-run` - Lancer les validations
- `make ge-docs` - Documentation qualité

**Développement :**
- `make install` - Installer dépendances Python
- `make test` - Tests unitaires (pytest)
- `make lint` - Linter (ruff)
- `make format` - Formatter le code

**Pipeline complet :**
- `make pipeline` - ingest → dbt → GE
- `make demo` - Setup complet démo

**Total :** 30+ commandes

---

## 0.5 Choix des Données

**Date :** 14/02/2026

### Problématique initiale

Le README initial mentionnait le dataset UCI Household Power Consumption (France, 2006-2010).

**Problème identifié :** Incohérence avec le contexte du projet (Afrique subsaharienne, réseau instable, délestages).

### Alternatives évaluées

| Option | Avantages | Inconvénients | Décision |
|--------|-----------|---------------|----------|
| **UCI Dataset** (France) | Format adapté, 2M lignes | ❌ Contexte européen, obsolète (2006-2010), pas de labels anomalies | ❌ Rejeté |
| **Nigeria Survey 2021** | ✅ Contexte africain, 3599 ménages | ❌ Enquête (pas smart meter), pas de séries temporelles | ⚠️ Référence complémentaire |
| **BBOXX Solar** | ✅ IoT réel, multi-pays africains | ❌ Off-grid (pas réseau), nécessite contact auteurs | ⚠️ Trop complexe |
| **Smart Meter Kaggle** | ✅ Labels anomalies inclus, météo, fréquence adaptée (30 min) | ⚠️ Origine non africaine | ✅ **RETENU** |

### Décision finale

**Dataset choisi :** [Smart Meter Dataset (Kaggle)](https://www.kaggle.com/datasets/ziya07/smart-meter-electricity-consumption-dataset)

**Justification :**
1. ✅ **Labels d'anomalies pré-étiquetés** (Isolation Forest déjà appliqué)
2. ✅ **Données météo** (température, humidité, vent) - facteurs contextuels importants
3. ✅ **Fréquence réaliste** (30 min) vs 1 min (trop granulaire)
4. ✅ **Format propre** (CSV standard)
5. ✅ **Licence libre** (CC0 Public Domain)
6. ✅ **Contextualisation possible** - adapter les seuils au contexte africain

**Approche retenue :** Utiliser Smart Meter comme données principales + documenter l'adaptation au contexte africain + référencer Nigeria Survey 2021 pour validation métier.

### Variables du dataset

| Variable | Type | Description | Utilisation |
|----------|------|-------------|-------------|
| `Timestamp` | TIMESTAMP | Horodatage (intervalle 30 min) | Clé temporelle |
| `Electricity_Consumed` | DECIMAL | Consommation (kWh) | Variable cible |
| `Temperature` | DECIMAL | Température extérieure (°C) | Feature |
| `Humidity` | DECIMAL | Humidité relative (%) | Feature |
| `Wind_Speed` | DECIMAL | Vitesse du vent (km/h) | Feature |
| `Avg_Past_Consumption` | DECIMAL | Moyenne historique (kWh) | Feature |
| `Anomaly_Label` | VARCHAR | Normal / Anomaly | Label pour validation |

### Mises à jour effectuées

- [x] README.md - Section "Données" mise à jour
- [x] README.md - Note sur contextualisation africaine ajoutée
- [x] `03_ROADMAP_TECHNIQUE.md` - Schémas de tables adaptés
- [x] `docker/postgres/init.sql` - Schéma table `meter_readings` adapté
- [x] Makefile - Commandes de téléchargement Kaggle

---

## 0.6 Initialisation Git

**Date :** 14/02/2026

### Problème initial

Premier commit effectué avec mauvais auteur : `smatflow-2024 <dsamo@smatflow.com>`

### Solution appliquée

```bash
# 1. Configuration globale corrigée
git config --global user.name "Danesamo"
git config --global user.email "chouakedaniela@gmail.com"

# 2. Suppression du dépôt local
rm -rf .git

# 3. Réinitialisation
git init
git add .
git commit -m "Initial commit: project structure and documentation"

# 4. Push vers GitHub
git remote add origin https://github.com/Danesamo/Energy_IOT.git
git branch -M main
git push -u origin main --force
```

### Résultat

- ✅ Commit avec la bonne identité : `Danesamo <chouakedaniela@gmail.com>`
- ✅ Hash : `21d266b`
- ✅ 13 fichiers commités
- ✅ GitHub synchronisé : https://github.com/Danesamo/Energy_IOT

### Fichiers commités (Phase 0)

```
.env.example
.gitignore
Makefile
README.md
docker-compose.yml
docker/clickhouse/config.xml
docker/clickhouse/users.xml
docker/postgres/init.sql
docker/superset/superset_config.py
docs/01_ETUDE_DOMAINE_ENERGIE.md
docs/02_ETUDE_PROJET.md
docs/03_ROADMAP_TECHNIQUE.md
requirements.txt
```

---

## Décisions Architecturales (Phase 0)

| Décision | Choix retenu | Alternative rejetée | Justification | Date |
|----------|--------------|---------------------|---------------|------|
| **Pipeline** | ELT (dbt) | ETL (Talend, SSIS) | Transformation dans la DB, SQL versionné, moderne | 13/02 |
| **Processing** | Batch | Streaming (Kafka) | Données historiques, complexité réduite, coût faible | 13/02 |
| **OLTP** | PostgreSQL | MySQL, MongoDB | Robuste, standard, excellentes performances jointures | 13/02 |
| **OLAP** | ClickHouse | BigQuery, Redshift | Open-source, 10-100x plus rapide analytics, stockage colonnes | 13/02 |
| **Data Quality** | Great Expectations | dbt tests seuls | Standard industrie, profiling auto, data docs HTML | 13/02 |
| **ML Anomalies** | Isolation Forest | LSTM, Autoencoders | Non supervisé, rapide, peu de paramètres, interprétable | 13/02 |
| **Orchestration** | Airflow | Dagster, Prefect | Standard industrie, mature, large communauté | 13/02 |
| **BI** | Superset | Metabase, Redash | Open-source, puissant, intégration Airflow | 13/02 |
| **Monitoring** | Grafana | Kibana | Dashboards ops, alertes, compatible Prometheus | 13/02 |
| **Dataset** | Smart Meter Kaggle | UCI France, Nigeria Survey | Labels anomalies inclus, météo, format adapté | 14/02 |

---

## Problèmes Rencontrés & Solutions (Phase 0)

| Problème | Impact | Solution appliquée | Résultat | Date |
|----------|--------|-------------------|----------|------|
| Dataset UCI inadapté au contexte africain | Crédibilité du projet | Choix Smart Meter + contextualisation + référence Nigeria Survey | Dataset pertinent avec labels anomalies | 14/02 |
| Git commit avec mauvais auteur (smatflow-2024) | Identité GitHub incorrecte | Config globale + rm .git + réinit + force push | Historique Git propre (Danesamo) | 14/02 |
| Port 5432 potentiellement occupé | Conflit PostgreSQL | Healthcheck + doc troubleshooting | Configuration robuste | 13/02 |

---

## Métriques Phase 0

| Métrique | Valeur |
|----------|--------|
| **Documentation totale** | ~2500 lignes (~110 pages) |
| **Fichiers de configuration** | 13 fichiers |
| **Services Docker configurés** | 7 services |
| **Commandes Makefile** | 30+ commandes |
| **Commits Git** | 1 commit initial (21d266b) |
| **Temps passé** | ~2 jours |

---

## Livrables Phase 0

- ✅ Documentation complète (4 docs + README)
- ✅ Infrastructure Docker (docker-compose + configs)
- ✅ Makefile automatisation
- ✅ Requirements Python
- ✅ Structure projet complète
- ✅ Git initialisé avec bonne identité
- ✅ Dataset choisi et justifié

---

# PHASE 1 : INFRASTRUCTURE & ENVIRONNEMENT

**Statut :** 🔄 En cours | **Début :** 14/02/2026 | **Progression :** 0%

## Objectifs

- Démarrer tous les services Docker sans erreur
- Installer les dépendances Python
- Télécharger le dataset Smart Meter (Kaggle)
- Vérifier la connectivité à PostgreSQL, ClickHouse
- Accéder aux interfaces web (Airflow, Superset, Grafana)

## Critères de succès

- [ ] `docker compose ps` montre tous les services "healthy"
- [ ] PostgreSQL accessible sur port 5432
- [ ] ClickHouse accessible sur port 8123
- [ ] Airflow UI accessible sur http://localhost:8080
- [ ] Superset UI accessible sur http://localhost:8088
- [ ] Grafana UI accessible sur http://localhost:3000
- [ ] Dataset Smart Meter téléchargé dans `data/raw/`
- [ ] Dépendances Python installées (dbt, great-expectations, pandas, etc.)

## Tâches planifiées

- [ ] 1.1 Setup environnement (`make setup`)
- [ ] 1.2 Installation dépendances Python (`make install`)
- [ ] 1.3 Lancement Docker (`make up`)
- [ ] 1.4 Vérification services (`make ps`)
- [ ] 1.5 Téléchargement données (`make download-data`)
- [ ] 1.6 Tests de connectivité bases de données
- [ ] 1.7 Accès aux interfaces web
- [ ] 1.8 Troubleshooting éventuel

---

## Log des actions

### 14/02/2026 - 10:30

**Action :** Création fichiers de suivi

- Créé `docs/04_RAPPORT_AVANCEMENT.md` (ce fichier)
- Créé `docs/05_DATA_DICTIONARY.md` (structure vide, à remplir après ingestion)

**Prochaine étape :** Lancer `make setup`

---

[À COMPLÉTER AU FUR ET À MESURE DU PROJET]

---

# PHASE 2 : INGESTION DES DONNÉES

**Statut :** ⏳ Pas commencé

[À documenter lors de l'exécution]

---

# PHASE 3 : TRANSFORMATIONS dbt

**Statut :** ⏳ Pas commencé

[À documenter lors de l'exécution]

---

# PHASE 4 : DATA QUALITY (Great Expectations)

**Statut :** ⏳ Pas commencé

[À documenter lors de l'exécution]

---

# PHASE 5 : MACHINE LEARNING

**Statut :** ⏳ Pas commencé

[À documenter lors de l'exécution]

---

# PHASE 6 : SYNCHRONISATION CLICKHOUSE

**Statut :** ⏳ Pas commencé

[À documenter lors de l'exécution]

---

# PHASE 7 : VISUALISATION

**Statut :** ⏳ Pas commencé

[À documenter lors de l'exécution]

---

# PHASE 8 : ORCHESTRATION AIRFLOW

**Statut :** ⏳ Pas commencé

[À documenter lors de l'exécution]

---

# ANNEXES

## A. Références

### Datasets

- [Smart Meter Dataset (Kaggle)](https://www.kaggle.com/datasets/ziya07/smart-meter-electricity-consumption-dataset) - Dataset principal
- [Nigeria Electricity Survey 2021](https://www.nature.com/articles/s41597-023-02185-0) - Référence contextuelle
- [BBOXX Solar Data](https://arxiv.org/html/2502.14630) - Contexte PAYGO

### Documentation

- [dbt Documentation](https://docs.getdbt.com/)
- [Great Expectations](https://docs.greatexpectations.io/)
- [ClickHouse Documentation](https://clickhouse.com/docs)

## B. Glossaire

| Terme | Définition |
|-------|------------|
| **ELT** | Extract-Load-Transform - données transformées dans la base |
| **OLTP** | Online Transaction Processing - optimisé pour écritures |
| **OLAP** | Online Analytical Processing - optimisé pour lectures analytiques |
| **dbt** | Data Build Tool - outil de transformation SQL moderne |
| **Great Expectations** | Framework de validation de données |
| **Isolation Forest** | Algorithme ML non supervisé pour détection d'anomalies |
| **PAYGO** | Pay-As-You-Go - modèle prépayé pour énergie solaire |

---

**Fin du rapport d'avancement - Mise à jour continue**
