Requêter les tables identifiées sur OpenMetadata :
▪ Métadonnée : trouvez-vous les mêmes informations ?
▪ Qualité : relevez-vous des problèmes qui seront à corriger ?


bike_rentals
Métadonnée sont les meme que dans la partie 1
Qualité:
rental_id -> BIGINT to SERIAL (1 to 2,147,483,647)
bike_id -> INTEGER to SERIAL (1 to 2,147,483,647), valeur non dans la FK
user_id -> valeur null
start_station_id -> la valeur ne correspon pas au standard sta_0000
end_station_id -> valeur null
start_t -> BIGINT to timestamp, valeur pas au format date
end_t -> BIGINT to timestamp, valeur pas au format date, valeur null

user_accounts
Métadonnée sont les meme que dans la partie 1
last_name -> valeur null
birthdate -> VARCHAR(50) to date
registration_date -> text to date, pas toute les date son au bon format
subscription_id -> VARCHAR(50) to VARCHAR(20), valeur null

subscriptions
Métadonnée sont les meme que dans la partie 1
subscription_id -> VARCHAR(50) to VARCHAR(20)
subscription_type -> valeur null
price_eur -> NUMERIC to money

bikes
Métadonnée sont les meme que dans la partie 1
bike_type -> valeur null

bike_stations
Métadonnée sont les meme que dans la partie 1
station_name -> valeur null
latitude -> text to numeric(9,6), valeur non comforme
longitude -> text to numeric(9,6), valeur non comforme
city_id -> BIGINT to SERIAL (1 to 2,147,483,647)

cities
Métadonnée sont les meme que dans la partie 1
city_id -> BIGINT to SERIAL (1 to 2,147,483,647)