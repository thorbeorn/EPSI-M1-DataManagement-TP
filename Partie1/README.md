## 💻 Accès aux Services

Une fois les conteneurs démarrés, suivez ces étapes pour vous connecter.

## 1. Accès à pgAdmin (Exploration SQL)

1.  Ouvrez votre navigateur et allez sur : `http://localhost:5050`.
2.  Connectez-vous à pgAdmin avec :
    * **Email :** `pgadmin@pgadmin.org`
    * **Mot de passe :** `pgadmin`
3.  Développez le serveur `epsi_server`. Il vous demandera le mot de passe de la *base de données* :
    * **Mot de passe :** `postgres`
4.  Vous pouvez maintenant naviguer dans `Bases de données` -> `postgres` -> `Schémas` -> `raw` pour voir les 26 tables.

## 2. Séléction des tables 
1. Ouvrez le document "catalogue_donnees.yml"

> Le fichier `catalogue_donnees.yml` sert de documentation de secours pour le TP.

* Il liste les 26 tables réparties par **domaines métier** (Finance, Support, Logistique, etc.).
* Il documente les colonnes des tables principales.

*Naviguez dans le catalogue et identifiez les tables qui semblent pertinentes*

2. Naviguer dans chaque table sur pgAdmin dans > "nom de la table" > Properties > Columns et récupere le type de chaque coloumn