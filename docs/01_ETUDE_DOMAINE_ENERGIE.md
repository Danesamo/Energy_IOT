# Etude du Domaine : Energie, Utilities & IoT
## Projet Energy IoT Pipeline - Document de Reference

---

## TABLE DES MATIERES

1. [Introduction au Secteur Energetique](#1-introduction-au-secteur-energetique)
2. [La Chaine de Valeur de l'Electricite](#2-la-chaine-de-valeur-de-lelectricite)
3. [Problematiques Business des Utilities](#3-problematiques-business-des-utilities)
4. [Smart Metering & IoT](#4-smart-metering--iot)
5. [Contexte Africain](#5-contexte-africain)
6. [Pay-As-You-Go Solar (PAYGO)](#6-pay-as-you-go-solar-paygo)
7. [Architecture Data dans l'Energie](#7-architecture-data-dans-lenergie)
8. [Use Cases Data Engineering](#8-use-cases-data-engineering)
9. [KPIs et Metriques du Secteur](#9-kpis-et-metriques-du-secteur)
10. [Datasets Disponibles](#10-datasets-disponibles)
11. [Technologies et Outils](#11-technologies-et-outils)
12. [Application au Projet](#12-application-au-projet)

---

## 1. INTRODUCTION AU SECTEUR ENERGETIQUE

### 1.1 Vue d'ensemble

Le secteur energetique englobe la **production**, la **transmission**, la **distribution** et la **consommation** d'energie (electricite, gaz, eau). C'est un secteur critique pour l'economie et le developpement.

### 1.2 Acteurs principaux

| Acteur | Role | Exemples |
|--------|------|----------|
| **Producteurs** | Generation d'electricite | Centrales thermiques, hydrauliques, solaires |
| **Gestionnaires de reseau (TSO)** | Transport haute tension | RTE (France), Eskom (Afrique du Sud) |
| **Distributeurs (DSO)** | Distribution basse/moyenne tension | Enedis, Eneo, CIE |
| **Fournisseurs** | Vente au client final | EDF, Orange Energy, BBOXX |
| **Consommateurs** | Utilisation finale | Menages, industries, commerces |

### 1.3 Types de marches

| Type | Caracteristiques | Exemples |
|------|-----------------|----------|
| **Monopole integre** | Un seul acteur gere tout | Eneo (Cameroun), beaucoup de pays africains |
| **Marche liberalise** | Concurrence entre fournisseurs | France, UK, Allemagne |
| **Hybride** | Production ouverte, distribution monopole | Afrique du Sud |

### 1.4 Pourquoi la data est critique dans l'energie

| Defi | Impact | Solution Data |
|------|--------|---------------|
| Equilibre offre/demande | Blackouts si desequilibre | Load forecasting |
| Pertes financieres | Jusqu'a 30% de pertes en Afrique | Detection de fraude |
| Infrastructure vieillissante | Pannes frequentes | Maintenance predictive |
| Transition energetique | Integration renouvelables | Analytics temps reel |
| Facturation | Erreurs, litiges | Smart metering |

---

## 2. LA CHAINE DE VALEUR DE L'ELECTRICITE

### 2.1 Schema simplifie

```
PRODUCTION          TRANSPORT           DISTRIBUTION         CONSOMMATION
    |                   |                    |                    |
[Centrales]  -->  [Reseau HT]  -->  [Reseau MT/BT]  -->  [Clients]
    |                   |                    |                    |
 Turbines          400kV-225kV           20kV-400V          Menages
 Panneaux          Lignes HT             Transformateurs    Industries
 Eoliennes         Postes sources        Compteurs          Commerces
```

### 2.2 Niveaux de tension

| Niveau | Tension | Usage |
|--------|---------|-------|
| **Tres Haute Tension (THT)** | 225-400 kV | Transport longue distance |
| **Haute Tension (HT)** | 63-90 kV | Transport regional |
| **Moyenne Tension (MT)** | 10-20 kV | Distribution urbaine |
| **Basse Tension (BT)** | 230-400 V | Distribution finale |

### 2.3 Flux de donnees dans la chaine

```
[Capteurs Production] --> [SCADA] --> [Systeme de Gestion Energie]
         |                              |
         v                              v
[Compteurs Clients] --> [MDM] --> [Systeme Facturation]
         |                              |
         v                              v
[IoT Reseau] --> [Data Lake] --> [Analytics/ML]
```

---

## 3. PROBLEMATIQUES BUSINESS DES UTILITIES

### 3.1 Les pertes d'electricite

#### Definition
Les pertes representent la difference entre l'energie produite/achetee et l'energie facturee aux clients.

```
Pertes = Energie Injectee - Energie Facturee
```

#### Types de pertes

| Type | Cause | Exemple | % typique |
|------|-------|---------|-----------|
| **Pertes Techniques** | Physique (resistance, chaleur) | Cables, transformateurs | 5-10% |
| **Pertes Non-Techniques (NTL)** | Fraude, erreurs | Vol, compteurs defaillants | 5-25% |

#### Impact financier

| Region | Pertes moyennes | Cout annuel |
|--------|-----------------|-------------|
| Europe | 5-8% | Milliards EUR |
| Afrique Sub-Saharienne | 15-30% | ~5 milliards USD |
| Cameroun (Eneo) | ~18% | Plusieurs centaines M USD |
| Afrique du Sud | ~15% | ~1.5 milliard USD |

> **Chiffre cle** : En Afrique, seulement 4 utilities sur le continent ont des pertes < 10% (standard "bon").

### 3.2 La fraude a l'electricite

#### Methodes de fraude courantes

| Methode | Description | Detection |
|---------|-------------|-----------|
| **Bypass du compteur** | Connexion directe sans passer par le compteur | Ecart energie entree/sortie |
| **Manipulation du compteur** | Ralentir ou bloquer le compteur | Anomalie dans les patterns |
| **Corruption d'employes** | Modification des releves | Audit croise des donnees |
| **Connexion illegale** | Branchement pirate sur le reseau | Inspection + analytics |

#### Indicateurs de fraude (features pour ML)

| Feature | Description | Signal |
|---------|-------------|--------|
| Chute soudaine de consommation | Baisse > 50% sans raison | Fort indicateur |
| Consommation anormalement basse | vs historique ou voisins | Suspect |
| Pattern irregulier | Pic puis zero | Manipulation |
| Ecart compteur/transformateur | Somme clients != transformateur | Zone a risque |

### 3.3 L'equilibre offre-demande

#### Le defi
L'electricite ne se stocke pas facilement. A chaque instant :
```
Production = Consommation + Pertes
```

Si desequilibre → frequence instable → blackout potentiel.

#### Load Forecasting (Prevision de charge)

| Horizon | Usage | Precision cible |
|---------|-------|-----------------|
| **Tres court terme** (heures) | Dispatch des centrales | < 2% MAPE |
| **Court terme** (jours) | Maintenance, achats | < 5% MAPE |
| **Moyen terme** (semaines) | Planification | < 8% MAPE |
| **Long terme** (annees) | Investissements | < 15% MAPE |

> **Cas Eneo Cameroun** : Avec SAS, ils sont passes de 8% d'ecart a < 2% entre prevision et realite.

#### Facteurs influencant la demande

| Facteur | Impact | Donnee necessaire |
|---------|--------|-------------------|
| **Meteo** | Temperature → climatisation/chauffage | API meteo |
| **Calendrier** | Jours feries, week-ends | Calendrier local |
| **Evenements** | Matchs TV, discours presidentiels | Evenements speciaux |
| **Economie** | Activite industrielle | PIB, indices |
| **Saison** | Ete/hiver, saison des pluies | Date |

### 3.4 La facturation

#### Problemes courants

| Probleme | Cause | Impact |
|----------|-------|--------|
| Erreurs de releve | Releve manuel, erreur humaine | Litiges clients |
| Estimation abusive | Pas d'acces au compteur | Mecontentement |
| Fraude interne | Employes corrompus | Pertes revenus |
| Retards de facturation | Processus lents | Tresorerie |

#### Solution : Smart Metering

Le compteur intelligent elimine ces problemes par la **telereleve automatique**.

---

## 4. SMART METERING & IoT

### 4.1 Qu'est-ce qu'un compteur intelligent ?

Un compteur intelligent (smart meter) est un dispositif qui :
- Mesure la consommation en temps reel (ou quasi-reel)
- Communique automatiquement avec le gestionnaire
- Permet la coupure/remise a distance
- Enregistre des donnees granulaires (toutes les 15min, 30min, 1h)

### 4.2 Architecture AMI (Advanced Metering Infrastructure)

```
[Compteurs intelligents]
        |
        | Communication (PLC, RF, GPRS, NB-IoT, LoRaWAN)
        v
[Concentrateurs de donnees]
        |
        | Reseau telecom
        v
[Head-End System / DCU]
        |
        v
[MDMS - Meter Data Management System]
        |
        +---> [Systeme Facturation]
        +---> [Analytics & BI]
        +---> [Detection Fraude]
        +---> [Load Forecasting]
```

### 4.3 Technologies de communication

| Technologie | Portee | Debit | Avantages | Usage |
|-------------|--------|-------|-----------|-------|
| **PLC** (Power Line) | Via cables electriques | Faible | Pas de nouveau reseau | Zones denses |
| **RF Mesh** | Quelques km | Moyen | Auto-organisation | Zones urbaines |
| **GPRS/3G/4G** | Cellulaire | Eleve | Couverture large | Zones etendues |
| **NB-IoT** | Cellulaire | Faible | Batterie longue duree | Smart meters |
| **LoRaWAN** | 10-15 km | Faible | Longue portee, bas cout | Rural, IoT |

### 4.4 Donnees collectees par un smart meter

| Donnee | Frequence typique | Usage |
|--------|-------------------|-------|
| **Energie active (kWh)** | 15-60 min | Facturation, profil |
| **Energie reactive (kVAR)** | 15-60 min | Qualite reseau |
| **Puissance max (kW)** | Journalier | Abonnement, penalites |
| **Tension (V)** | Continu ou evenements | Qualite alimentation |
| **Evenements** | Temps reel | Coupures, alertes |
| **Statut compteur** | Periodique | Maintenance |

### 4.5 Volume de donnees

Calcul pour une utility de 1 million de compteurs :

```
1 compteur = 96 lectures/jour (toutes les 15 min)
1 compteur = 96 x 365 = 35,040 lectures/an
1 million compteurs = 35 milliards de lignes/an

Avec 10 colonnes x 50 bytes = 500 bytes/ligne
Volume = 35 milliards x 500 bytes = ~17 TB/an (brut)
```

> **Defi Data Engineering** : Gerer ce volume avec ingestion temps reel, stockage efficient, et analytics rapides.

---

## 5. CONTEXTE AFRICAIN

### 5.1 Chiffres cles

| Indicateur | Afrique Sub-Saharienne | Monde |
|------------|------------------------|-------|
| Acces a l'electricite | ~50% | ~90% |
| Capacite installee | 48 GW (hors Afrique du Sud) | 8,000+ GW |
| Lignes de transmission | 247 km/million habitants | 610 km (Bresil) |
| Pertes distribution | 15-30% | 6-8% |

### 5.2 Utilities majeures - Afrique Francophone

| Pays | Utility | Clients | Defis |
|------|---------|---------|-------|
| **Cameroun** | Eneo | 1.2 million | Pertes ~18%, blackouts |
| **Cote d'Ivoire** | CIE | 2+ millions | Croissance demande |
| **Senegal** | Senelec | 1.5 million | Mix energetique |
| **Maroc** | ONEE | 6+ millions | Transition renouvelable |

### 5.3 Cas Eneo Cameroun - Analytics en action

Eneo utilise **SAS Analytics** pour :

| Use Case | Avant | Apres | Impact |
|----------|-------|-------|--------|
| Load Forecasting | 8% erreur | < 2% erreur | Economies millions USD |
| Detection fraude | Manuel | Analytics | Reduction pertes |
| Segmentation clients | Basique | Avancee | Marketing cible |
| Dashboards | Inexistants | Temps reel | Decisions rapides |

> **Citation Eneo** : "Analytics is becoming a daily fixture for hundreds of Eneo employees"

### 5.4 Defis specifiques a l'Afrique

| Defi | Description | Solution potentielle |
|------|-------------|---------------------|
| **Infrastructure vetuste** | Equipements vieux, pannes | Maintenance predictive |
| **Vol d'electricite eleve** | Connexions illegales | Smart metering + ML |
| **Reseau fragile** | Blackouts frequents | Load forecasting |
| **Faible couverture** | Zones rurales non electrifiees | Off-grid solar (PAYGO) |
| **Manque de donnees** | Compteurs mecaniques | Digitalisation |
| **Capacite limitee** | Peu de data engineers | Formation, outils simples |

---

## 6. PAY-AS-YOU-GO SOLAR (PAYGO)

### 6.1 Le modele PAYGO

Pour les populations sans acces au reseau electrique (600+ millions en Afrique), le modele **Pay-As-You-Go Solar** offre une alternative :

```
[Panneau solaire + Batterie + Compteur IoT]
                    |
                    | Paiement Mobile Money
                    v
          [Activation a distance]
                    |
                    v
    [Electricite pour eclairage, TV, telephone]
```

### 6.2 Acteurs majeurs

| Entreprise | Pays | Clients | Technologie |
|------------|------|---------|-------------|
| **M-Kopa** | Kenya, Nigeria, Uganda | 5+ millions | IoT + Mobile Money |
| **BBOXX** | Rwanda, Kenya, DRC | 500k+ | SMART Solar IoT |
| **Sun King** | Pan-africain | Millions | Off-grid systems |
| **Zola Electric** | Tanzanie, Nigeria | 100k+ | Battery + solar |
| **Fenix/Engie** | Uganda, Zambie | 500k+ | ReadyPay |

### 6.3 Donnees generees par PAYGO

| Donnee | Frequence | Usage |
|--------|-----------|-------|
| Consommation energie | Temps reel | Facturation, sizing |
| Etat batterie | Continu | Maintenance predictive |
| Paiements | Evenement | Credit scoring |
| Localisation | Installation | Logistique, SAV |
| Statut device | Periodique | Gestion flotte |

### 6.4 M-Kopa - Un geant de la data

| Metrique | Valeur |
|----------|--------|
| Points de donnees/mois | 1.5 milliard |
| Credits accordes | $1.5 milliard cumulatif |
| Impact carbone | 1.5 million tonnes CO2 evitees |
| Infrastructure | "Largest Microsoft Azure user in Africa" |

#### Use cases data chez M-Kopa :
1. **Credit scoring** : Historique paiements → eligibilite nouveaux produits
2. **Prediction defaut** : ML pour anticiper non-paiements
3. **Sizing optimal** : Adapter capacite batterie au usage
4. **Maintenance predictive** : Anticiper pannes equipements

---

## 7. ARCHITECTURE DATA DANS L'ENERGIE

### 7.1 Architecture de reference

```
                            DATA SOURCES
    +----------------------------------------------------------+
    |                                                          |
[Smart Meters]  [SCADA]  [Weather API]  [IoT Sensors]  [CRM/ERP]
    |              |           |              |             |
    +------+-------+-----------+------+-------+-------------+
           |                          |
           v                          v
    +-------------+            +-------------+
    |   KAFKA     |            |   BATCH     |
    |  Streaming  |            |   Ingestion |
    +------+------+            +------+------+
           |                          |
           +------------+-------------+
                        |
                        v
              +-----------------+
              |   DATA LAKE     |
              | (S3/HDFS/GCS)   |
              | Raw Zone        |
              +-----------------+
                        |
                        v
              +-----------------+
              |   dbt / Spark   |
              | Transformations |
              +-----------------+
                        |
           +------------+------------+
           |                         |
           v                         v
    +--------------+         +--------------+
    | DATA QUALITY |         | DATA QUALITY |
    | Great Expect.|         | Soda         |
    +--------------+         +--------------+
           |                         |
           +------------+------------+
                        |
                        v
              +-----------------+
              | DATA WAREHOUSE  |
              | (ClickHouse/    |
              |  Redshift/BQ)   |
              | Curated Zone    |
              +-----------------+
                        |
           +------------+------------+------------+
           |            |            |            |
           v            v            v            v
    +----------+  +----------+  +----------+  +----------+
    |   BI     |  |    ML    |  | Alerting |  |   API    |
    | Superset |  | Models   |  | Grafana  |  | FastAPI  |
    +----------+  +----------+  +----------+  +----------+
```

### 7.2 Flux de donnees typique

| Etape | Description | Outil |
|-------|-------------|-------|
| 1. **Ingestion** | Collecte depuis compteurs, API | Kafka, Airbyte |
| 2. **Stockage Raw** | Donnees brutes, immutable | S3, PostgreSQL |
| 3. **Transformation** | Nettoyage, agregation | dbt, Spark |
| 4. **Validation** | Tests qualite | Great Expectations |
| 5. **Stockage Curated** | Donnees pretes pour analytics | ClickHouse |
| 6. **Analytics** | Dashboards, rapports | Superset, Grafana |
| 7. **ML** | Prediction, detection | Python, XGBoost |

### 7.3 Schema de donnees typique

#### Table : meter_readings (Fait)

| Colonne | Type | Description |
|---------|------|-------------|
| reading_id | BIGINT | ID unique |
| meter_id | VARCHAR | ID compteur |
| timestamp | TIMESTAMP | Date/heure lecture |
| active_energy_kwh | DECIMAL | Energie active |
| reactive_energy_kvarh | DECIMAL | Energie reactive |
| voltage | DECIMAL | Tension |
| current | DECIMAL | Courant |
| power_factor | DECIMAL | Facteur de puissance |
| quality_flag | INT | Qualite de la mesure |

#### Table : meters (Dimension)

| Colonne | Type | Description |
|---------|------|-------------|
| meter_id | VARCHAR | ID unique |
| customer_id | VARCHAR | ID client |
| installation_date | DATE | Date installation |
| meter_type | VARCHAR | Type (monophase, triphase) |
| location_lat | DECIMAL | Latitude |
| location_lon | DECIMAL | Longitude |
| transformer_id | VARCHAR | Transformateur associe |
| tariff_code | VARCHAR | Code tarifaire |

#### Table : customers (Dimension)

| Colonne | Type | Description |
|---------|------|-------------|
| customer_id | VARCHAR | ID unique |
| customer_type | VARCHAR | Residentiel, commercial, industriel |
| contract_power_kw | DECIMAL | Puissance souscrite |
| address | VARCHAR | Adresse |
| segment | VARCHAR | Segment marketing |

---

## 8. USE CASES DATA ENGINEERING

### 8.1 Detection de fraude (Notre focus)

#### Probleme
Identifier les clients qui volent de l'electricite parmi des millions.

#### Approche ML

```
Donnees historiques (consommation, paiements, profil)
        |
        v
Feature Engineering
        |
        +-- Ratio consommation actuelle/historique
        +-- Ecart avec voisins similaires
        +-- Volatilite de consommation
        +-- Patterns horaires anormaux
        +-- Correlation meteo/consommation
        |
        v
Modele de classification (XGBoost, Random Forest)
        |
        v
Score de risque (0-100)
        |
        v
Priorisation inspections terrain
```

#### Features typiques

| Feature | Calcul | Indicateur |
|---------|--------|------------|
| consumption_ratio | conso_actuelle / conso_historique | < 0.5 suspect |
| neighbor_deviation | conso / moyenne_voisins | > 2 std suspect |
| zero_consumption_days | count(jours avec 0 kWh) | > 5/mois suspect |
| night_consumption_ratio | conso_nuit / conso_total | Pattern anormal |
| payment_delay_avg | moyenne(jours retard paiement) | Correlation fraude |

### 8.2 Load Forecasting

#### Probleme
Predire la demande d'electricite pour les prochaines heures/jours.

#### Approche

```
Donnees historiques + Meteo + Calendrier
        |
        v
Feature Engineering
        |
        +-- Lag features (t-1, t-24, t-168)
        +-- Rolling averages (7j, 30j)
        +-- Variables calendrier (jour, mois, ferie)
        +-- Variables meteo (temp, humidite)
        |
        v
Modele Time Series (Prophet, LSTM, XGBoost)
        |
        v
Prediction horaire/journaliere
        |
        v
Optimisation dispatch centrales
```

### 8.3 Analyse de consommation

#### Probleme
Comprendre les patterns de consommation pour segmentation et tarification.

#### Approche

```
Donnees compteurs (time series)
        |
        v
Agregation (horaire, journaliere, mensuelle)
        |
        v
Clustering (K-means sur profils de charge)
        |
        v
Segments clients
        |
        +-- "Pic matin" (familles)
        +-- "Pic soir" (travailleurs)
        +-- "Constant" (commerces)
        +-- "Industriel" (usines)
        |
        v
Tarification differenciee / Marketing cible
```

### 8.4 Maintenance predictive

#### Probleme
Anticiper les pannes de transformateurs et equipements.

#### Approche

```
Donnees capteurs (temperature, charge, age)
        |
        v
Feature Engineering
        |
        +-- Heures de fonctionnement
        +-- Cycles de charge
        +-- Temperature max atteinte
        +-- Historique pannes
        |
        v
Modele de survie ou classification
        |
        v
Probabilite de panne (30, 60, 90 jours)
        |
        v
Planning maintenance preventive
```

---

## 9. KPIs ET METRIQUES DU SECTEUR

### 9.1 KPIs operationnels

| KPI | Formule | Cible |
|-----|---------|-------|
| **Pertes totales** | (Energie achetee - Energie vendue) / Energie achetee | < 10% |
| **SAIDI** | Duree moyenne interruption par client | < 100 min/an |
| **SAIFI** | Frequence moyenne interruption par client | < 1/an |
| **Disponibilite reseau** | Temps fonctionnement / Temps total | > 99.9% |
| **Taux de recouvrement** | Montant encaisse / Montant facture | > 95% |

### 9.2 KPIs smart metering

| KPI | Description | Cible |
|-----|-------------|-------|
| **Taux de telereleve** | Compteurs lus a distance / Total | > 99% |
| **Latence donnees** | Temps entre lecture et disponibilite | < 15 min |
| **Taux de donnees valides** | Lectures OK / Total lectures | > 99.5% |
| **Couverture AMI** | Compteurs smart / Total compteurs | > 80% |

### 9.3 KPIs analytics

| KPI | Description | Cible |
|-----|-------------|-------|
| **MAPE forecast** | Mean Absolute Percentage Error | < 5% |
| **Precision detection fraude** | Vrais positifs / Predictions positives | > 80% |
| **Recall detection fraude** | Vrais positifs / Fraudes reelles | > 70% |
| **Temps de detection anomalie** | Delai entre anomalie et alerte | < 24h |

### 9.4 KPIs financiers

| KPI | Formule | Interpretation |
|-----|---------|----------------|
| **Revenu par kWh** | CA / kWh vendus | Rentabilite |
| **Cout des pertes** | kWh perdus x Prix achat | Impact financier |
| **ROI smart metering** | (Economies - Investissement) / Investissement | > 15% |
| **Reduction NTL** | (NTL avant - NTL apres) / NTL avant | > 20% |

---

## 10. DATASETS DISPONIBLES

### 10.1 Datasets Kaggle

| Dataset | Description | Taille | Lien |
|---------|-------------|--------|------|
| **Smart Meter Electricity Consumption** ✅ | Donnees smart meter avec labels anomalies | Variable | [Kaggle](https://www.kaggle.com/datasets/ziya07/smart-meter-electricity-consumption-dataset) |
| **SmartMeter Energy Consumption Data** | Consommation Londres | Large | [Kaggle](https://www.kaggle.com/datasets/eyabaklouti/smartmeter-energy-consumption-data) |
| **Energy Consumption Time Series** | Time series energie | Moyen | [Kaggle](https://www.kaggle.com/datasets/vitthalmadane/energy-consumption-time-series-dataset) |

### 10.2 Dataset retenu : Smart Meter (Kaggle)

**Smart Meter Electricity Consumption Dataset**

| Attribut | Description |
|----------|-------------|
| Timestamp | Horodatage (30 min) |
| Electricity_Consumed | Consommation (kWh) |
| Temperature | Temperature exterieure (°C) |
| Humidity | Humidite relative (%) |
| Wind_Speed | Vitesse du vent (km/h) |
| Avg_Past_Consumption | Moyenne historique (kWh) |
| Anomaly_Label | Label: Normal / Anomaly |

**Caracteristiques :**
- Labels d'anomalies pre-etiquetes (Isolation Forest)
- Donnees meteo incluses (Temperature, Humidite, Vent)
- Frequence : 30 minutes (48 mesures/jour)
- Format CSV standard
- Licence CC0 Public Domain

### 10.3 Autres sources

| Source | Type | Acces |
|--------|------|-------|
| **London Smart Meter Data** | 5,567 menages, 2011-2014 | Open |
| **REDD Dataset** | Consommation disagregee | Academique |
| **UK-DALE** | 5 maisons UK | Academique |
| **Pecan Street** | Texas, USA | Inscription |
| **Open Power System Data** | Europe | Open |

---

## 11. TECHNOLOGIES ET OUTILS

### 11.1 Stack recommande pour le projet

| Couche | Outil | Justification |
|--------|-------|---------------|
| **Ingestion** | Python + Airflow | Flexibilite, orchestration |
| **Stockage Raw** | PostgreSQL | Robuste, SQL standard |
| **Transformation** | **dbt** | Standard industrie, tests integres |
| **Data Quality** | **Great Expectations** | Validation automatique |
| **Stockage Analytics** | ClickHouse | Performant pour time series |
| **Visualisation** | Superset | Open source, puissant |
| **Monitoring** | Grafana | Temps reel |
| **Conteneurisation** | Docker | Reproductibilite |

### 11.2 Pourquoi dbt ?

| Avantage | Description |
|----------|-------------|
| SQL-first | Transformations en SQL pur |
| Tests integres | `unique`, `not_null`, custom tests |
| Documentation auto | Schema, lineage |
| Modularite | Modeles reutilisables |
| Version control | Git-friendly |
| Standard industrie | Demande forte en 2026 |

### 11.3 Pourquoi Great Expectations ?

| Avantage | Description |
|----------|-------------|
| Data contracts | Definir attentes sur les donnees |
| Tests automatises | Valider a chaque run |
| Documentation | Data docs auto-generees |
| Integration | dbt, Airflow, etc. |
| Alertes | Notification si echec |

---

## 12. APPLICATION AU PROJET

### 12.1 Scope du projet

Notre projet **Energy IoT Pipeline** va :

1. **Ingerer** des donnees de consommation electrique (Smart Meter Dataset - Kaggle)
2. **Transformer** avec dbt (agregations, features)
3. **Valider** avec Great Expectations (qualite)
4. **Stocker** dans ClickHouse (analytics)
5. **Visualiser** avec Superset (dashboards)
6. **Predire** avec ML (anomalies, forecast)

### 12.2 Use cases implementes

| Use Case | Description | Complexite |
|----------|-------------|------------|
| **Agregation temporelle** | Minute → Heure → Jour → Mois | Moyenne |
| **Detection anomalies** | Identifier consommations anormales | Moyenne |
| **Profils de charge** | Clustering des patterns | Haute |
| **Dashboard KPIs** | Metriques operationnelles | Moyenne |

### 12.3 Architecture cible

```
[CSV Dataset]
      |
      v
[PostgreSQL - Raw]
      |
      v
[dbt - Transformations]
      |
      +-- staging models (cleaning)
      +-- intermediate models (features)
      +-- mart models (analytics-ready)
      |
      v
[Great Expectations - Validation]
      |
      v
[ClickHouse - Analytics]
      |
      v
[Superset - Dashboards]
      |
      v
[Airflow - Orchestration]
```

### 12.4 Deliverables

| Livrable | Description |
|----------|-------------|
| Pipeline dbt | Modeles de transformation documentes |
| Suite Great Expectations | Tests de qualite automatises |
| Dashboards Superset | KPIs energie visualises |
| Documentation | README, architecture, lineage |
| Docker Compose | Infrastructure complete |

---

## RESSOURCES COMPLEMENTAIRES

### Lectures recommandees
- [Data Pipelines for Energy Industry - Integrate.io](https://www.integrate.io/blog/data-pipelines-energy-industry/)
- [Smart Metering for Big Data Analytics - TEKTELIC](https://tektelic.com/expertise/how-to-use-smart-metering-for-big-data-analytics/)
- [Eneo Cameroun - SAS Case Study](https://www.sas.com/en_us/customers/eneo-fr-global.html)
- [M-Kopa - Microsoft Case Study](https://www.microsoft.com/africa/4afrika/mkopa.aspx)

### Tutoriels
- [dbt Fundamentals (gratuit)](https://courses.getdbt.com/)
- [Great Expectations Quickstart](https://docs.greatexpectations.io/docs/tutorials/quickstart/)
- [Time Series Forecasting with Prophet](https://facebook.github.io/prophet/docs/quick_start.html)

### Datasets
- [Smart Meter Dataset (Kaggle)](https://www.kaggle.com/datasets/ziya07/smart-meter-electricity-consumption-dataset)
- [Kaggle Energy Datasets](https://www.kaggle.com/search?q=energy+consumption)

---

*Document cree : 30 Janvier 2026*
*Projet : Energy IoT Pipeline*
*Auteur : Daniela Samo Chouake*
