## **📌 Partie 1 — Découverte et Compréhension des Données**

### **Tables identifiées comme pertinentes**

---

## **1. bike_rentals** — *Table de faits principale*

### **Schéma**
| Colonne          | Type            | Clé / Référence               |
| ---------------- | --------------- | ----------------------------- |
| rental_id        | BIGINT (int64)  | PK                            |
| bike_id          | INTEGER (int32) | FK → bikes.bike_id            |
| user_id          | UUID            | FK → user_accounts.user_id    |
| start_station_id | VARCHAR(10)     | FK → bike_stations.station_id |
| end_station_id   | VARCHAR(10)     | FK → bike_stations.station_id |
| start_t          | text            | —                             |
| end_t            | text            | —                             |

### **Documentation**

Historique complet des trajets effectués par les utilisateurs sur le service VéloCity.
Chaque ligne représente un trajet. Table centrale pour les analyses de fréquentation.

Elle est indispensable pour calculer toutes les métriques demandées :

* Nombre total de locations
* Durée des trajets
* Utilisateurs uniques
* Analyse vélo/station/ville

### **Type**
Table de fait

### **Owner**
Données du support client

---

## **2. user_accounts** — *Dimension utilisateur*

### **Schéma**
| Colonne           | Type         | Clé / Référence                    |
| ----------------- | ------------ | ---------------------------------- |
| user_id           | UUID         | PK                                 |
| first_name        | VARCHAR(100) | —                                  |
| last_name         | VARCHAR(100) | —                                  |
| email             | VARCHAR(150) | —                                  |
| birthdate         | VARCHAR(50)  | —                                  |
| registration_date | text         | —                                  |
| subscription_id   | VARCHAR(50)  | FK → subscriptions.subscription_id |

### **Documentation**
Liste des clients de VéloCity, incluant informations personnelles et type d'abonnement.

Contient les informations personnelles anonymisées des clients.
Nécessaire pour :

* calculer l’âge des utilisateurs
* déterminer leur abonnement
* compter les utilisateurs uniques

### **Type**
Table de Dimension

### **Owner**
Données du support client

---

## **3. subscriptions** — *Dimension abonnement*

### **Schéma**
| Colonne           | Type            | Clé / Référence |
| ----------------- | --------------- | --------------- |
| subscription_id   | VARCHAR(50)     | PK              |
| subscription_type | VARCHAR(100)    | —               |
| price_eur         | NUMERIC (float) | —               |

### **Documentation**
Référentiel des abonnements disponibles (Mensuel, Annuel, Étudiant).

Détail des types d'abonnements.
Utile pour répondre à :

* type d’abonnement pris

### **Type**
Table de Dimension

### **Owner**
Comptable: Données de facturation client

---

## **4. bikes** — *Dimension vélo*

### **Schéma**
| Colonne            | Type            | Clé / Référence |
| ------------------ | --------------- | --------------- |
| bike_id            | INTEGER (int32) | PK              |
| bike_type          | VARCHAR(50)     | —               |
| model_name         | VARCHAR(100)    | —               |
| commissioning_date | date            | —               |
| status             | VARCHAR(50)     | —               |

### **Documentation**
Inventaire complet de la flotte de vélos : type, modèle, date de mise en service, statut opérationnel.

Référentiel de la flotte VéloCity (vélo mécanique/électrique)
Utile pour :
* les vélos les plus utilisés
* analyser par type de vélo
* filtrer les vélos hors-service en Silver

### **Type**
Table de Dimension

### **Owner**
Pole Logistics & Maintenance

---

## **5. bike_stations** — *Dimension station*

### **Schéma**
| Colonne      | Type            | Clé / Référence     |
| ------------ | --------------- | ------------------- |
| station_id   | VARCHAR(10)     | PK                  |
| station_name | VARCHAR(255)    | —                   |
| latitude     | text            | —                   |
| longitude    | text            | —                   |
| capacity     | INTEGER (int32) | —                   |
| city_id      | INTEGER (int32) | FK → cities.city_id |

### **Documentation**
Référentiel des stations physiques du réseau VéloCity, incluant géolocalisation et capacité.

Nécessaire pour :

* analyses par station
* rattacher les stations à une ville

### **Type**
Table de Dimension

### **Owner**
Pole Logistics & Maintenance

---

## **6. cities** — *Dimension géographique*

### **Schéma**
| Colonne   | Type            | Clé / Référence |
| --------- | --------------- | --------------- |
| city_id   | INTEGER (int32) | PK              |
| city_name | VARCHAR(100)    | —               |
| region    | VARCHAR(100)    | —               |

### **Documentation**
Liste des villes couvertes par le service (ex : Paris, Lyon, Marseille…).

Permet de répondre au besoin métier :

* habitude par ville

### **Type**
Table de Dimension

### **Owner**
Service Marketing

---

# 📌 Conclusion

Ces 7 tables couvrent entièrement les besoins du Dashboard Marketing demandé par la direction :

| Besoin métier           | Table utilisée                   |
| ----------------------- | -------------------------------- |
| Nombre de locations     | bike_rentals                     |
| Durée moyenne           | bike_rentals                     |
| Vélos les plus utilisés | bike_rentals + bikes             |
| Analyse par ville       | bike_rentals + stations + cities |
| Type d’abonnement       | user_accounts + subscriptions    |
| Âge des utilisateurs    | user_accounts                    |