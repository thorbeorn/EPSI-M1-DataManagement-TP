# ✅ Simulation d’audit : rôle *marketing_user*

Votre administrateur a créé un rôle (utilisateur) : **marketing_user**.
La question porte sur ce qui doit se passer si cet utilisateur tente d’accéder à différentes tables selon les bonnes pratiques de gouvernance des données (accès par couche RAW → SILVER → GOLD).

---

# 1️⃣ Cas n°1

### ❓ *Si marketing_user exécute :*

```sql
SELECT * FROM raw.user_accounts;
```

### ✅ **Ce qui doit se passer (réponse correcte)**

👉 **L’accès doit être refusé.**

### 📌 Raison

* Le schéma **raw** contient des données **brutes, sensibles, non nettoyées**.
* Par principe, **aucun utilisateur métier** (dont le service marketing) ne doit accéder au RAW.
* Seuls les rôles techniques (ETL/ingénierie) peuvent le lire.

### 🔒 Résultat attendu

PostgreSQL renverra :

```
ERROR:  permission denied for table user_accounts
```

---

# 2️⃣ Cas n°2

### ❓ *Si marketing_user exécute :*

```sql
SELECT * FROM analytics_LLODRA_BRAURE.gold_daily_activity;
```

*(ou toute table Gold telle que : cities_summary, bikes_summary, etc.)*

### ✅ **Ce qui doit se passer (réponse correcte)**

👉 **L’accès doit être autorisé**, *à condition que le DBA ait attribué les permissions de lecture sur la couche GOLD.*

### 📌 Raison

* La couche **Gold** contient des données **agrégées, anonymisées, et prêtes pour l’analyse métier**.
* Ces tables sont faites pour les équipes business comme le **marketing, finance, direction**.
* Elles ne révèlent aucun identifiant direct (données anonymisées dans le script).

### 🟢 Résultat attendu

La requête **doit fonctionner** et renvoyer les données agrégées.

---

# 🧩 Récapitulatif

| Action                                                   | Résultat attendu | Justification                                               |
| -------------------------------------------------------- | ---------------- | ----------------------------------------------------------- |
| `SELECT * FROM raw.user_accounts;`                       | ❌ **Refusé**     | Données sensibles, couche RAW interdite aux métiers         |
| `SELECT * FROM analytics_LLODRA_BRAURE.gold_daily_activity;` | ✅ **Autorisé**   | Données agrégées, anonymisées, destinées aux équipes métier |


---

# 📘 DESCRIPTION DU SQL – Configuration des rôles et permissions

Pour mettre en place les règles de sécurité décrites ci-dessus, le DBA doit exécuter les commandes suivantes.

---

# 🔐 1. Création et configuration du rôle *marketing_user*

## 1.1. Empêcher l’accès au schéma RAW

```sql
REVOKE ALL ON SCHEMA raw FROM marketing_user;
REVOKE ALL ON ALL TABLES IN SCHEMA raw FROM marketing_user;
```

Ces commandes garantissent que *marketing_user* ne peut ni lister ni consulter les tables RAW.

---

## 1.2. Donner l’accès *lecture seule* aux tables GOLD

### Donner accès au schéma GOLD

```sql
GRANT USAGE ON SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity TO marketing_user;
```

### Donner lecture sur toutes les tables GOLD

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity TO marketing_user;
```

### (Optionnel mais recommandé)

Ce qui permet d’obtenir automatiquement l’accès aux futures tables GOLD :

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity
GRANT SELECT ON TABLES TO marketing_user;
```

---

# 🛡️ 2. Mise en place de la Row-Level Security (RLS) pour *manager_lyon*

## 2.1. Création du rôle

```sql
CREATE ROLE manager_lyon LOGIN PASSWORD 'motdepasse_secure';
```

---

## 2.2. Donner l’accès uniquement au schéma GOLD

```sql
GRANT USAGE ON SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity TO manager_lyon;
```

### Donner accès à la table qui sera filtrée (ex : cities_summary)

```sql
GRANT SELECT ON analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary TO manager_lyon;
```

---

## 2.3. Activer la Row-Level Security sur la table

```sql
ALTER TABLE analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary
ENABLE ROW LEVEL SECURITY;
```

---

## 2.4. Créer la politique RLS : accès uniquement aux lignes associées à “Lyon”

```sql
CREATE POLICY lyon_only_policy
ON analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary
FOR SELECT
TO manager_lyon
USING (city_name = 'Lyon');
```

---

# 🧪 TESTS À EFFECTUER POUR VÉRIFIER LES RÔLES

## 🔎 Test 1 : Vérifier que *marketing_user* ne peut pas accéder au RAW

```sql
SET ROLE marketing_user;
SELECT * FROM raw.user_accounts;
```

Résultat attendu :

```
ERROR: permission denied for table user_accounts
```

---

## 🔎 Test 2 : Vérifier que *marketing_user* peut accéder à la couche GOLD

```sql
SELECT * FROM analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary;
```

Résultat attendu :

✔ La requête fonctionne
✔ Les données agrégées s’affichent

---

## 🔎 Test 3 : Vérifier que *manager_lyon* peut se connecter

```sql
SET ROLE manager_lyon;
```

---

## 🔎 Test 4 : Vérifier que *manager_lyon* ne voit QUE la ville de Lyon

```sql
SELECT city_name, nombre_locations
FROM analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary;
```

Résultat attendu :

| city_name |
| --------- |
| **Lyon**  |
| **Lyon**  |
| **Lyon**  |

➡️ Aucune autre ville ne doit apparaître.

---

## 🔎 Test 5 : Vérifier que *manager_lyon* ne voit pas les tables RAW

```sql
SELECT * FROM raw.user_accounts;
```

Résultat attendu :

```
ERROR: permission denied
```

---

## 🔎 Test 6 : Sortir du rôle

```sql
RESET ROLE;
```

---