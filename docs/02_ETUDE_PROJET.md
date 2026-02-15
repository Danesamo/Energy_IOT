# Étude de Projet : Energy IoT Pipeline

## 1. INTRODUCTION

### 1.1 Objet du document

Ce document constitue l'étude de cadrage du projet **Energy IoT Pipeline**. Il définit le contexte métier, la problématique, les objectifs, le périmètre et l'approche technique retenue.

Ce document s'inscrit dans une démarche professionnelle de gestion de projet, telle que pratiquée dans les entreprises du secteur énergétique (utilities, smart grid, PAYGO solar).

### 1.2 Public cible

| Public | Ce qu'il trouvera ici |
|--------|----------------------|
| **Recruteurs / Managers** | Vision business, stack technique, livrables |
| **Data Engineers** | Architecture, choix techniques, code |
| **Équipes métier Énergie** | Problématiques, KPIs, use cases |
| **Non-experts** | Sections vulgarisées marquées "Pour les non-experts" |

### 1.3 Documents associés

| Document | Contenu |
|----------|---------|
| `01_ETUDE_DOMAINE.md` | Contexte complet du secteur énergétique |
| `03_ARCHITECTURE.md` | Schémas techniques détaillés |
| `04_DATA_DICTIONARY.md` | Dictionnaire des données |
| `05_RUNBOOK.md` | Guide d'exécution pas à pas |
| `06_RAPPORT_AVANCEMENT.md` | Journal de bord du projet |


## 2. RÉSUMÉ EXÉCUTIF

### Pour les non-experts

> **Le problème :** Les compagnies d'électricité en Afrique perdent 15-30% de leur énergie (vol, erreurs de compteurs, fuites). Cela représente des **milliards de dollars** perdus chaque année.
>
> **La solution :** Un système informatique qui analyse les données des compteurs intelligents pour :
> - Détecter automatiquement les consommations anormales (fraude potentielle)
> - Prévoir la demande d'électricité pour éviter les coupures
> - Fournir des tableaux de bord pour piloter le réseau
>
> **Ce projet :** Construire ce système de A à Z avec des technologies modernes, en utilisant des données publiques gratuites.

### Résumé technique

| Aspect | Description |
|--------|-------------|
| **Domaine** | Énergie / Utilities / Smart Metering |
| **Problématique** | Pertes non-techniques, prévision de charge, qualité des données |
| **Solution** | Pipeline de données IoT avec détection d'anomalies |
| **Stack clé** | PostgreSQL, **dbt**, **Great Expectations**, ClickHouse, Superset, Airflow |
| **Durée estimée** | 3 semaines |
| **Budget** | 0€ (100% open-source) |


## 3. CONTEXTE ET MOTIVATION

### 3.1 Pourquoi ce projet ?

Ce projet s'inscrit dans une stratégie de portfolio ciblant 3 domaines :

```
┌─────────────────────────────────────────────────────────────┐
│                    PORTFOLIO DATA ENGINEER                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ✅ Projet 1 : FINANCE (Credit Risk)      → TERMINÉ        │
│                                                              │
│   🎯 Projet 2 : ÉNERGIE (IoT Pipeline)     → CE PROJET      │
│                                                              │
│   ⏳ Projet 3 : TELECOMS (Churn Analytics) → À VENIR        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Alignement avec le marché

| Critère | Justification |
|---------|---------------|
| **Marché africain** | Eneo (Cameroun), CIE (Côte d'Ivoire), Senelec (Sénégal) cherchent des profils Data |
| **Technologies demandées** | dbt et Great Expectations = compétences les plus demandées en 2026 |
| **Secteur en croissance** | Transition énergétique + digitalisation des utilities |
| **PAYGO Solar** | M-Kopa, BBOXX = entreprises tech à fort volume de données |

### 3.3 Gaps techniques à combler

| Technologie | Status actuel | Après ce projet |
|-------------|---------------|-----------------|
| **dbt** | Non maîtrisé | ✅ Maîtrisé |
| **Great Expectations** | Non maîtrisé | ✅ Maîtrisé |
| PostgreSQL | ✅ Solide | ✅ Renforcé |
| ClickHouse | ✅ Solide | ✅ Renforcé |
| Airflow | ✅ Solide | ✅ Renforcé |


## 4. PROBLÉMATIQUE MÉTIER

### 4.1 Les pertes d'électricité : un problème à milliards

#### Pour les non-experts

> Imaginez que vous vendez 100 litres d'eau mais que seulement 70-85 litres arrivent chez vos clients. Les 15-30 litres perdus, c'est soit :
> - De l'eau qui fuit (pertes techniques = câbles, transformateurs)
> - De l'eau volée (pertes non-techniques = fraude, compteurs trafiqués)
>
> Pour l'électricité, c'est pareil. Et ça coûte des **milliards** aux compagnies.

#### Chiffres clés

| Région | Pertes moyennes | Coût estimé |
|--------|-----------------|-------------|
| Europe | 5-8% | Milliards EUR |
| **Afrique Sub-Saharienne** | **15-30%** | **~5 milliards USD/an** |
| Cameroun (Eneo) | ~18% | Centaines de millions USD |

### 4.2 Les 3 problèmes que nous adressons

| # | Problème | Impact business | Notre solution |
|---|----------|-----------------|----------------|
| 1 | **Détection de fraude** | Pertes financières directes | Anomaly detection ML |
| 2 | **Prévision de charge** | Blackouts, surproduction coûteuse | Load forecasting |
| 3 | **Qualité des données** | Décisions erronées | Data quality checks |

### 4.3 Pourquoi les smart meters changent tout

```
AVANT (Compteur mécanique)          APRÈS (Smart Meter)
────────────────────────            ────────────────────
- Relevé manuel 1x/mois             - Lecture automatique toutes les 15 min
- Erreurs humaines                  - Données précises
- Fraude difficile à détecter       - Anomalies détectables en temps réel
- Pas de visibilité                 - Dashboard temps réel
```


## 5. OBJECTIFS DU PROJET

### 5.1 Objectifs métier (Business)

| # | Objectif | Indicateur de succès |
|---|----------|---------------------|
| 1 | Détecter les consommations anormales | Précision > 80% sur anomalies |
| 2 | Permettre l'analyse des patterns de consommation | Dashboard avec KPIs |
| 3 | Assurer la qualité des données | 100% des données validées |
| 4 | Fournir des agrégations temporelles | Heure, Jour, Mois disponibles |

### 5.2 Objectifs techniques (Data Engineering)

| # | Objectif | Indicateur de succès |
|---|----------|---------------------|
| 1 | Implémenter des transformations avec **dbt** | Modèles staging/intermediate/marts |
| 2 | Mettre en place **Great Expectations** | Suite de tests automatisés |
| 3 | Créer un pipeline orchestré | DAG Airflow fonctionnel |
| 4 | Déployer des dashboards | Superset avec KPIs énergie |
| 5 | Conteneuriser l'infrastructure | `docker-compose up` fonctionne |

### 5.3 Objectifs portfolio (Personnel)

| # | Objectif | Livrable |
|---|----------|----------|
| 1 | Démontrer dbt + Great Expectations | Repo GitHub public |
| 2 | Avoir un projet Énergie visible | README professionnel |
| 3 | Prouver la compréhension métier | Documentation claire |
| 4 | Visibilité professionnelle | Post LinkedIn avec démo |


## 6. PÉRIMÈTRE DU PROJET

### 6.1 Ce qui est inclus (IN SCOPE)

| Composant | Description | Technologie |
|-----------|-------------|-------------|
| **Ingestion** | Chargement des données CSV dans PostgreSQL | Python, psycopg2 |
| **Transformation** | Nettoyage, agrégation, features | **dbt Core** |
| **Data Quality** | Validation automatique des données | **Great Expectations** |
| **Stockage Analytics** | Base optimisée pour les requêtes | ClickHouse |
| **Visualisation** | Dashboards interactifs | Apache Superset |
| **Détection anomalies** | ML pour identifier les consommations suspectes | Python, scikit-learn |
| **Orchestration** | Automatisation du pipeline | Airflow |
| **Conteneurisation** | Infrastructure reproductible | Docker Compose |

### 6.2 Ce qui est exclu (OUT OF SCOPE)

| Élément | Raison |
|---------|--------|
| Streaming temps réel (Kafka) | Dataset statique, pas de flux continu |
| Déploiement cloud (AWS) | Projet suivant (Telecom Churn) |
| Prédiction de charge avancée | Focus sur détection d'anomalies |
| Interface utilisateur custom | Superset suffit pour la démo |

### 6.3 Contraintes

| Contrainte | Impact | Mitigation |
|------------|--------|------------|
| **Budget : 0€** | Outils open-source uniquement | dbt Core (gratuit) vs dbt Cloud |
| **Dataset public** | Pas de données réelles utilities | Kaggle datasets (Smart Meter) |
| **Ressources locales** | Machine personnelle | Docker pour optimiser |
| **Temps : 3 semaines** | Périmètre limité | Focus sur les essentiels |


## 7. DONNÉES

### 7.1 Source : Smart Meter Dataset (Kaggle)

**Lien :** https://www.kaggle.com/datasets/ziya07/smart-meter-electricity-consumption-dataset

**Pourquoi ce dataset ?**

| Critère | Évaluation |
|---------|------------|
| **Granularité** | 1 mesure toutes les 30 minutes |
| **Labels d'anomalies** | ✅ Pré-étiquetés (Isolation Forest déjà appliqué) |
| **Données météo** | ✅ Température, humidité, vitesse du vent |
| **Format** | CSV standard, propre |
| **Licence** | CC0 Public Domain (gratuit) |
| **Contexte** | Adapté pour démonstration détection anomalies |

### 7.2 Structure des données

| Colonne | Type | Description | Unité |
|---------|------|-------------|-------|
| `Timestamp` | TIMESTAMP | Horodatage de la mesure | yyyy-mm-dd hh:mm:ss |
| `Electricity_Consumed` | DECIMAL(10,4) | Consommation électrique | kWh |
| `Temperature` | DECIMAL(5,2) | Température extérieure | °C |
| `Humidity` | DECIMAL(5,2) | Humidité relative | % |
| `Wind_Speed` | DECIMAL(5,2) | Vitesse du vent | km/h |
| `Avg_Past_Consumption` | DECIMAL(10,4) | Moyenne mobile historique | kWh |
| `Anomaly_Label` | VARCHAR(20) | Label : Normal ou Anomaly | - |

### 7.3 Volume et caractéristiques

| Métrique | Valeur |
|----------|--------|
| **Nombre de lignes** | À déterminer après téléchargement |
| **Fréquence** | 30 minutes (48 mesures/jour) |
| **Anomalies pré-labellisées** | Oui (détection Isolation Forest) |
| **Facteurs contextuels** | Météo (température, humidité, vent) |
| **Format** | CSV |

### 7.4 Contextualisation africaine

**Note importante :** Ce dataset ne provient pas d'Afrique subsaharienne, mais il est adapté pour notre démonstration car :

1. **Labels d'anomalies** : Permet de valider notre modèle ML
2. **Facteurs météo** : Essentiels pour le contexte africain (forte chaleur, humidité variable)
3. **Fréquence adaptée** : 30 min = compromis entre granularité et volume de données
4. **Référence complémentaire** : [Nigeria Electricity Survey 2021](https://www.nature.com/articles/s41597-023-02185-0) pour validation métier


## 8. ARCHITECTURE TECHNIQUE

### 8.1 Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ENERGY IoT PIPELINE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│   │   CSV    │───▶│ POSTGRES │───▶│   dbt    │───▶│  GREAT   │             │
│   │ (Kaggle) │    │   RAW    │    │ TRANSFORM│    │EXPECTAT. │             │
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
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │                      DOCKER COMPOSE (Infrastructure)                  │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Flux de données détaillé

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA FLOW                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. INGESTION                                                                │
│   CSV (Kaggle) ────────────────────────────▶ PostgreSQL (raw_readings)      │
│                                                                              │
│  2. TRANSFORMATION (dbt)                                                     │
│     raw_readings ──▶ stg_readings ──▶ int_hourly ──▶ mart_daily_metrics    │
│                          │                │               │                  │
│                    (clean data)    (aggregate)    (KPIs ready)              │
│                                                                              │
│  3. VALIDATION (Great Expectations)                                          │
│     Chaque étape ──▶ Tests automatiques ──▶ Pass/Fail ──▶ Alertes          │
│                                                                              │
│  4. ANALYTICS                                                                │
│     PostgreSQL ────────────────────────────▶ ClickHouse (OLAP optimisé)     │
│                                                                              │
│  5. VISUALISATION                                                            │
│     ClickHouse ──────────────────────────────▶ Superset (Dashboards)        │
│                                                                              │
│  6. ML                                                                       │
│     mart_daily_metrics ──▶ Anomaly Detection ──▶ Flagged records            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.3 Modèles dbt prévus

| Couche | Modèle | Description |
|--------|--------|-------------|
| **staging** | `stg_readings` | Données nettoyées, types corrigés |
| **intermediate** | `int_readings_hourly` | Agrégation horaire |
| **intermediate** | `int_readings_daily` | Agrégation journalière |
| **intermediate** | `int_readings_monthly` | Agrégation mensuelle |
| **marts** | `mart_consumption_metrics` | KPIs de consommation |
| **marts** | `mart_anomaly_flags` | Consommations suspectes |
| **marts** | `mart_load_profile` | Profils de charge |


## 9. STACK TECHNIQUE

### 9.1 Choix technologiques

| Catégorie | Technologie | Version | Justification |
|-----------|-------------|---------|---------------|
| **Langage** | Python | 3.12+ | Standard industrie |
| **BDD OLTP** | PostgreSQL | 15+ | Robuste, SQL standard |
| **BDD OLAP** | ClickHouse | 24+ | Performant pour analytics |
| **Transformation** | **dbt Core** | 1.7+ | Standard industrie 2026 |
| **Data Quality** | **Great Expectations** | 0.18+ | Validation automatisée |
| **Visualisation** | Apache Superset | 3.0+ | Open-source, puissant |
| **Orchestration** | Apache Airflow | 2.8+ | Standard orchestration |
| **Monitoring** | Grafana | 10+ | Dashboards monitoring |
| **Conteneurs** | Docker Compose | 2.0+ | Reproductibilité |

### 9.2 Pourquoi dbt ?

| Avantage | Description |
|----------|-------------|
| **SQL-first** | Transformations en SQL pur (pas de Python complexe) |
| **Tests intégrés** | `unique`, `not_null`, tests custom |
| **Documentation auto** | Schéma et lineage générés automatiquement |
| **Modularité** | Modèles réutilisables avec `ref()` |
| **Standard industrie** | Demandé dans 60%+ des offres DE en 2026 |
| **Gratuit** | dbt Core est open-source |

### 9.3 Pourquoi Great Expectations ?

| Avantage | Description |
|----------|-------------|
| **Data contracts** | Définir les attentes sur les données |
| **Tests automatisés** | Valider à chaque exécution du pipeline |
| **Documentation** | Data docs auto-générées |
| **Intégration** | Compatible dbt, Airflow, etc. |
| **Alertes** | Notification si données non conformes |


## 10. LIVRABLES

### 10.1 Livrables techniques

| # | Livrable | Description | Validation |
|---|----------|-------------|------------|
| 1 | **Repo GitHub** | Code source complet | Public, README complet |
| 2 | **Pipeline dbt** | Modèles staging → marts | `dbt run` fonctionne |
| 3 | **Suite GE** | Tests de qualité | `great_expectations checkpoint run` OK |
| 4 | **Dashboards** | KPIs énergie dans Superset | Screenshots dans README |
| 5 | **DAG Airflow** | Pipeline orchestré | Exécution automatique |
| 6 | **Docker Compose** | Infrastructure complète | `docker compose up` fonctionne |

### 10.2 Livrables documentaires

| # | Document | Contenu |
|---|----------|---------|
| 1 | `README.md` | Vue d'ensemble, démarrage rapide, screenshots |
| 2 | `01_ETUDE_DOMAINE.md` | Contexte métier énergie |
| 3 | `02_ETUDE_PROJET.md` | Ce document |
| 4 | `03_ARCHITECTURE.md` | Schémas techniques détaillés |
| 5 | `04_DATA_DICTIONARY.md` | Dictionnaire des données |
| 6 | `05_RUNBOOK.md` | Guide pas à pas |
| 7 | `06_RAPPORT_AVANCEMENT.md` | Journal de bord |


## 11. PLANNING

### 11.1 Vue d'ensemble (3 semaines)

```
Semaine 1                 Semaine 2                 Semaine 3
─────────────────────────────────────────────────────────────────
│ Infrastructure │        │ dbt + GE │             │ ML + Polish │
│ + Ingestion    │        │ + ClickHouse │         │ + Docs      │
─────────────────────────────────────────────────────────────────
```

### 11.2 Planning détaillé

| Jour | Tâches | Livrable |
|------|--------|----------|
| **J1-J2** | Structure projet, Docker Compose, PostgreSQL | Infra de base |
| **J3-J4** | Ingestion données Smart Meter, exploration | Données dans PostgreSQL |
| **J5-J7** | Modèles dbt (staging, intermediate) | Transformations OK |
| **J8-J9** | Modèles dbt (marts) + tests | Pipeline dbt complet |
| **J10-J11** | Great Expectations setup + suites | Data quality OK |
| **J12-J13** | ClickHouse + Superset | Dashboards fonctionnels |
| **J14-J15** | Anomaly detection ML | Détection OK |
| **J16-J17** | Airflow DAG | Orchestration OK |
| **J18-J19** | Documentation, README, screenshots | Docs complètes |
| **J20-J21** | Tests finaux, polish, post LinkedIn | Projet terminé |


## 12. RISQUES ET MITIGATION

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| **dbt learning curve** | Moyenne | Moyen | Tutoriel dbt Fundamentals (gratuit) |
| **Great Expectations complexité** | Moyenne | Moyen | Commencer simple, itérer |
| **Ressources Docker limitées** | Moyenne | Moyen | Limiter services simultanés |
| **Dataset trop simple** | Faible | Faible | Ajouter features synthétiques si besoin |
| **Superset configuration** | Moyenne | Faible | Utiliser images Docker officielles |


## 13. CRITÈRES DE SUCCÈS

### 13.1 Métriques techniques

| Métrique | Seuil minimum | Cible |
|----------|---------------|-------|
| **Pipeline dbt** | Tous les modèles run | + tests passent |
| **Data Quality** | 5 expectations | 10+ expectations |
| **Dashboards** | 1 dashboard | 3 dashboards |
| **Documentation** | README basique | Documentation complète |
| **Tests** | Manuels | Automatisés (CI) |

### 13.2 Checklist finale

- [ ] `docker compose up` démarre tous les services
- [ ] `dbt run` exécute sans erreur
- [ ] `dbt test` passe tous les tests
- [ ] Great Expectations checkpoint OK
- [ ] Dashboards Superset fonctionnels
- [ ] DAG Airflow s'exécute correctement
- [ ] README avec screenshots
- [ ] Documentation complète
- [ ] Post LinkedIn préparé


## 14. GLOSSAIRE

| Terme | Définition |
|-------|------------|
| **AMI** | Advanced Metering Infrastructure - Infrastructure de compteurs intelligents |
| **dbt** | Data Build Tool - Outil de transformation de données en SQL |
| **Great Expectations** | Framework de validation de qualité des données |
| **kW** | Kilowatt - Unité de puissance |
| **kWh** | Kilowatt-heure - Unité d'énergie consommée |
| **Load Profile** | Profil de charge - Pattern de consommation dans le temps |
| **MDMS** | Meter Data Management System - Système de gestion des données compteurs |
| **NTL** | Non-Technical Losses - Pertes non-techniques (fraude, erreurs) |
| **OLAP** | Online Analytical Processing - Traitement analytique |
| **OLTP** | Online Transaction Processing - Traitement transactionnel |
| **Smart Meter** | Compteur intelligent avec communication bidirectionnelle |
| **Staging** | Zone de données nettoyées dans dbt |
| **Mart** | Zone de données prêtes pour l'analytics dans dbt |


## 15. CONCLUSION

Ce projet **Energy IoT Pipeline** permet de :

1. **Combler des gaps techniques critiques** : dbt et Great Expectations
2. **Démontrer une expertise métier** : Secteur énergétique et utilities
3. **Construire un portfolio cohérent** : Finance → Énergie → Telecoms
4. **Cibler le marché africain** : Aligné avec Eneo, CIE, Senelec, M-Kopa

C'est un projet **réaliste** (3 semaines, 0€) qui apporte une **valeur différenciante** sur le marché de l'emploi Data Engineering en 2026.



**Document rédigé le :** 13 Février 2026

**Auteur :** Daniela Samo

**Version :** 1.0

**Statut :** À valider

**Prochain document :** `03_ARCHITECTURE.md`
