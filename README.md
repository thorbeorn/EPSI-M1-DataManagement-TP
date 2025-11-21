Voici un **README complet**, clair, structuré, prêt à être déposé dans un dépôt GitHub**.
Je l’ai rédigé de manière professionnelle, en respectant les standards habituels pour un projet Data Engineering / Data Analytics.
Il inclut :
✔ Explication du TP
✔ Architecture Raw → Silver → Gold
✔ Détails par partie (OpenMetadata, PostgreSQL, Metabase, Sécurité)
✔ Instructions d’exécution
✔ Livrables
✔ Crédits

---

# 🚲 **TP – Cycle de vie de la donnée : de la source au Dashboard**

### **Projet : VéloCity — Pipeline & Dashboard Analytics**

---

## 📌 **Description**

Ce projet simule un workflow complet de Data Engineering et Data Analytics pour l’entreprise fictive **VéloCity**, un service de vélos en libre-service.
L’objectif consiste à :

1. **Explorer et comprendre les données brutes** via OpenMetadata
2. **Construire un modèle analytique propre** en PostgreSQL selon l’architecture **Médaillon (Raw → Silver → Gold)**
3. **Créer un Dashboard Marketing** dans Metabase
4. **Mettre en place la gouvernance et la sécurité des données**, via le principe du moindre privilège

---

## 🛠️ **Technologies utilisées**

| Outil / Technologie | Utilisation                                      |
| ------------------- | ------------------------------------------------ |
| **OpenMetadata**    | Catalogue, documentation, découverte des sources |
| **PostgreSQL**      | Stockage, transformations Raw → Silver → Gold    |
| **pgAdmin**         | Connexion et requêtes SQL                        |
| **Metabase**        | Dashboard & visualisation                        |
| **Docker**          | Déploiement de l’environnement (OpenMetadata)    |

---

# 📂 **Architecture du projet**

```
                          OpenMetadata
                                │
                    ┌───────────┴───────────┐
                    │ Analyse & Documentation │
                    └───────────┬───────────┘
                                │
                            PostgreSQL
          ┌──────────────────────┼─────────────────────────┐
          │                      │                         │
        RAW                   SILVER                     GOLD
 (Données brutes)    (Nettoyage, typage, règles)   (Tables métier prêtes BI)
          │                      │                         │
          └──────────────────────┴───────────────┐
                                                  │
                                             Metabase
                                         (Dashboard final)
```

---

# 📘 **Partie 1 — Découverte et Compréhension (OpenMetadata)**

Vous trouverez dans le livrable **Partie 1** :
✔ Liste des tables identifiées
✔ Schémas, documentation & data profiling
✔ Classification tables de faits / dimensions
✔ Justification du choix des sources

Tables retenues :

| Table           | Type      | Rôle                            |
| --------------- | --------- | ------------------------------- |
| `bike_rentals`  | Fait      | Table centrale pour les trajets |
| `user_accounts` | Dimension | Infos utilisateurs / abonnement |
| `subscriptions` | Dimension | Types d’abonnements             |
| `bikes`         | Dimension | Infos sur la flotte             |
| `bike_stations` | Dimension | Réseau de stations              |
| `cities`        | Dimension | Localisation (ville / région)   |

Ces tables couvrent tous les besoins analytiques du Marketing.

---

# 🏗️ **Partie 2 — Modélisation & Pipeline SQL (PostgreSQL)**

## 🎯 Objectifs

* Créer un schéma analytique :
  `analytics_nom1_nom2`
* Construire :

  * **Silver** → tables nettoyées
  * **Gold** → tables agrégées

## 📄 Contenu du script SQL fourni

Le fichier **script.sql** contient :

### 1️⃣ Création des schémas

```sql
CREATE SCHEMA analytics_nom1_nom2;
```

### 2️⃣ Transformation **Silver**

💡 Nettoyages réalisés :

* Conversion des dates `text` → `timestamp`
* Calcul de `duration_minutes`
* Filtrage des trajets < 2 minutes (tests)
* Standardisation des ID / formats
* Suppression valeurs aberrantes (cohérence temporelle)
* Normalisation des abonnements

Chaque table Raw → Silver possède sa requête INSERT avec correction.

### 3️⃣ Construction **Gold**

Création de la table centrale :

`analytics_nom1_nom2.gold_daily_activity`

Elle contient :

* `total_rentals`
* `average_duration_minutes`
* `unique_users`
* Par jour, ville, station, type de vélo, type d’abonnement

---

# 📊 **Partie 3 — Dashboard Metabase**

Un Dashboard intitulé :

## **📈 “Suivi Activité VéloCity”**

contient :

### 1. Courbe : Évolution du nombre de locations

* X : jour
* Y : total_rentals

### 2. Bar chart : Top 3 des villes

* tri décroissant sur total_rentals

### 3. KPI : durée moyenne par ville

* average_duration_minutes

📎 *Capture d’écran fournie dans le livrable Partie 3.*

---

# 🔐 **Partie 4 — Sécurité & Gouvernance**

Objectif : appliquer le **principe du moindre privilège**.

## 🔒 Rôle : `marketing_user`

### Accès attendus

| Schéma | Accès           | Raison                                  |
| ------ | --------------- | --------------------------------------- |
| raw    | ❌ Interdit      | Données sensibles                       |
| silver | ❌ Interdit      | Données semi-clean mais non anonymisées |
| gold   | ✅ Lecture seule | Données propres, anonymisées, prêtes BI |

### Script SQL inclus dans le livrable :

```sql
REVOKE ALL ON SCHEMA raw FROM marketing_user;
REVOKE ALL ON ALL TABLES IN SCHEMA raw FROM marketing_user;

GRANT USAGE ON SCHEMA analytics_nom1_nom2 TO marketing_user;
GRANT SELECT ON analytics_nom1_nom2.gold_daily_activity TO marketing_user;
```

---

## 🔒 RLS : rôle *manager_lyon*

Objectif : ne voir que les données de **Lyon**.

Extrait du script :

```sql
CREATE ROLE manager_lyon LOGIN;

GRANT USAGE ON SCHEMA analytics_nom1_nom2 TO manager_lyon;
GRANT SELECT ON analytics_nom1_nom2.gold_daily_activity TO manager_lyon;

ALTER TABLE analytics_nom1_nom2.gold_daily_activity
ENABLE ROW LEVEL SECURITY;

CREATE POLICY city_lyon_policy
ON analytics_nom1_nom2.gold_daily_activity
FOR SELECT
TO manager_lyon
USING (city_name = 'Lyon');
```

---

# 📦 **Livrables**

| Partie   | Livrable               | Format             |
| -------- | ---------------------- | ------------------ |
| Partie 1 | Analyse OpenMetadata   | Markdown / PDF     |
| Partie 2 | Script complet SQL     | `.sql`             |
| Partie 3 | Dashboard Metabase     | Capture d’écran    |
| Partie 4 | GRANT / REVOKE (+ RLS) | Dans le script SQL |

---

# 👥 **Auteurs**

👤 **Llodra Dylan**
👤 **Braure Axel**