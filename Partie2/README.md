# 📘 README — Script de Pipeline SQL (Raw → Silver → Gold)

## 📄 Description générale

Ce script SQL met en place un pipeline de transformation de données pour un système de location de vélos.
Il orchestre :

1. **La création des schémas et tables analytics (Silver).**
2. **Le nettoyage, la validation et l’insertion des données issues du schéma `raw`.**
3. **La construction de tables agrégées avancées (Gold) regroupant statistiques et indicateurs clé** destinés à l’analyse quotidienne des activités.

Le pipeline suit une architecture **Raw → Silver → Gold** similaire aux approches Data Lake / Lakehouse modernes.

---

# 🏗️ 1. Structure du projet

## 📂 Schéma Raw

Source brute contenant les tables :

* `raw.bike_rentals`
* `raw.user_accounts`
* `raw.subscriptions`
* `raw.bikes`
* `raw.bike_stations`
* `raw.cities`

Ces tables ne sont pas modifiées dans ce script : elles servent d’inputs.

---

## 📂 Schéma Silver : `analytics_LLODRA_BRAURE`

Le script crée les tables nettoyées :

* `bike_rentals`
* `user_accounts`
* `subscriptions`
* `bikes`
* `bike_stations`
* `cities`

### 🔧 Principales opérations de nettoyage

* Vérification des formats d’ID (`sta_XXX`, `sub_XXX`, etc.).
* Validation de champs obligatoires.
* Transformation des dates (prise en charge des formats `DD/MM/YYYY`).
* Filtrage qualité :

  * vélos non retraités / hors maintenance.
  * coordonnées valides.
  * cohérence temporelle (start < end, durée < 10 ans).
* Normalisation (ex : `LOWER(subscription_id)`).

---

## 📂 Schéma Gold : `analytics_LLODRA_BRAURE_gold_daily_activity`

Des tables d’analyse complètes sont générées :

### 🟦 1. `rental_summary`

Table détaillée par **location**, avec :

* nom anonymisé de l’utilisateur,
* âge, ancienneté,
* type d’abonnement,
* caractéristiques du vélo,
* stations et villes de départ/arrivée,
* durée en minutes.

---

### 🟩 2. `cities_summary`

Table d’analyse par **ville**, contenant :

* nombre total de stations,
* durée moyenne des trajets,
* utilisateurs uniques,
* top / flop :

  * abonnements,
  * types de vélos,
  * modèles.

---

### 🟧 3. `station_summary`

Indicateurs par **station** :

* nombre de départs / arrivées,
* déséquilibre entre entrées/sorties,
* statut (équilibré / surplus / déficit),
* type et modèle de vélo les plus / moins utilisés,
* temps moyen de location.

---

### 🟪 4. `bikes_summary`

Vue complète par **vélo** :

* nombre total d’utilisations,
* temps moyen d’utilisation,
* dernière station connue,
* taux d’utilisation global,
* âge moyen des utilisateurs.

---

### 🟥 5. `subscription_summary`

Vue par **type d’abonnement** :

* total des locations,
* vélos différents utilisés,
* temps moyen / total des trajets,
* profils utilisateurs,
* top / flop vélos & modèles.

---

### 🟨 6. `user_summary`

Résumé par **utilisateur** :

* nom anonymisé,
* âge,
* abonnement,
* jours depuis inscription,
* statistiques d’utilisation,
* préférences : types et modèles les plus / moins utilisés.

---

### ⬛ 7. `global_summary`

Vue globale du système :

* nombre total d’utilisateurs, vélos, stations, villes,
* âge moyen,
* durée totale et moyenne des trajets,
* abonnement le plus vendu,
* prix moyen des abonnements.

---

# ⚙️ 2. Prérequis

* PostgreSQL (script compatible >= 12)
* Schéma `raw` déjà existant et alimenté
* Droits de création sur les schémas et tables

---

# 🚀 3. Déploiement

1. Placer le fichier `script.sql` dans votre environnement PostgreSQL.
2. Exécuter dans l’ordre le script complet depuis un client SQL :

   ```sql
   \i /path/to/script.sql
   ```
3. Les schémas *Silver* et *Gold* seront automatiquement créés et remplis.

---

# 🔍 4. Objectifs du pipeline

* Normaliser et fiabiliser les données brutes.
* Préparer des datasets prêts pour la BI / DataViz (Power BI, Tableau, Looker…).
* Générer des indicateurs complets pour :

  * l’analyse opérationnelle (stations, vélos),
  * l’étude clientèle,
  * la gestion d’offre (abonnements),
  * l’analyse multi-villes.

---

# 📝 5. Auteur(s)

Pipeline développé par **Llodra dylan & Braure axel**.