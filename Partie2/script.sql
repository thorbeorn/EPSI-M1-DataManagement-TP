SET timezone = 'Europe/Paris';

--------- raw
SELECT * FROM raw.bike_rentals;
SELECT * FROM raw.user_accounts;
SELECT * FROM raw.subscriptions;
SELECT * FROM raw.bikes;
SELECT * FROM raw.bike_stations;
SELECT * FROM raw.cities;

--------- silver
CREATE SCHEMA analytics_LLODRA_BRAURE
--
CREATE TABLE IF NOT EXISTS analytics_LLODRA_BRAURE.bike_rentals
(
    rental_id serial NOT NULL,
    bike_id serial,
    user_id uuid,
    start_station_id character varying(10) COLLATE pg_catalog."default",
    end_station_id character varying(10) COLLATE pg_catalog."default",
    start_t timestamp with time zone,
    end_t timestamp with time zone,
    CONSTRAINT bike_rentals_pkey PRIMARY KEY (rental_id)
)
TABLESPACE pg_default;
ALTER TABLE IF EXISTS analytics_LLODRA_BRAURE.bike_rentals
    OWNER to postgres;
--
CREATE TABLE IF NOT EXISTS analytics_LLODRA_BRAURE.user_accounts
(
    user_id uuid NOT NULL,
    first_name character varying(100) COLLATE pg_catalog."default",
    last_name character varying(100) COLLATE pg_catalog."default",
    email character varying(150) COLLATE pg_catalog."default",
    birthdate date,
    registration_date date,
    subscription_id character varying(20) COLLATE pg_catalog."default",
    CONSTRAINT user_accounts_pkey PRIMARY KEY (user_id)
)
TABLESPACE pg_default;
ALTER TABLE IF EXISTS analytics_LLODRA_BRAURE.user_accounts
    OWNER to postgres;
--
CREATE TABLE IF NOT EXISTS analytics_LLODRA_BRAURE.subscriptions
(
    subscription_id character varying(20) COLLATE pg_catalog."default" NOT NULL,
    subscription_type character varying(100) COLLATE pg_catalog."default",
    price_eur numeric(5,2),
    CONSTRAINT subscriptions_pkey PRIMARY KEY (subscription_id)
)
TABLESPACE pg_default;
ALTER TABLE IF EXISTS analytics_LLODRA_BRAURE.subscriptions
    OWNER to postgres;
--
CREATE TABLE IF NOT EXISTS analytics_LLODRA_BRAURE.bikes
(
    bike_id serial NOT NULL,
    bike_type character varying(50) COLLATE pg_catalog."default",
    model_name character varying(100) COLLATE pg_catalog."default",
    commissioning_date date,
    status character varying(50) COLLATE pg_catalog."default",
    CONSTRAINT bikes_pkey PRIMARY KEY (bike_id)
)
TABLESPACE pg_default;
ALTER TABLE IF EXISTS analytics_LLODRA_BRAURE.bikes
    OWNER to postgres;
--
CREATE TABLE IF NOT EXISTS analytics_LLODRA_BRAURE.bike_stations
(
    station_id character varying(10) COLLATE pg_catalog."default" NOT NULL,
    station_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    latitude numeric(9,6),
    longitude numeric(9,6),
    capacity integer,
    city_id serial,
    CONSTRAINT bike_stations_pkey PRIMARY KEY (station_id)
)
TABLESPACE pg_default;
ALTER TABLE IF EXISTS analytics_LLODRA_BRAURE.bike_stations
    OWNER to postgres;
--
CREATE TABLE IF NOT EXISTS analytics_LLODRA_BRAURE.cities
(
    city_id serial NOT NULL,
    city_name character varying(100) COLLATE pg_catalog."default",
    region character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT cities_pkey PRIMARY KEY (city_id)
)
TABLESPACE pg_default;
ALTER TABLE IF EXISTS analytics_LLODRA_BRAURE.cities
    OWNER to postgres;

INSERT INTO analytics_LLODRA_BRAURE.cities
SELECT DISTINCT * 
FROM raw.cities
WHERE
	city_id IS NOT NULL
	AND city_name IS NOT NULL
	AND region IS NOT NULL;
	
INSERT INTO analytics_LLODRA_BRAURE.bike_stations
SELECT DISTINCT
    station_id,
    station_name,
    latitude::numeric(9,6),
    longitude::numeric(9,6),
    capacity
FROM raw.bike_stations
WHERE 
	station_id IS NOT NULL
	AND station_id ~ '^sta_[0-9]+$'
	--
	AND station_name IS NOT NULL
	--
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
    AND latitude  ~ '^[+-]?[0-9]+(\.[0-9]+)?$'
    AND longitude ~ '^[+-]?[0-9]+(\.[0-9]+)?$'
    AND (latitude::numeric) BETWEEN -90 AND 90
    AND (longitude::numeric) BETWEEN -180 AND 180
	--
	AND capacity IS NOT NULL;

INSERT INTO analytics_LLODRA_BRAURE.subscriptions
select DISTINCT LOWER(subscription_id), subscription_type, price_eur
from raw.subscriptions
WHERE 
	subscription_id IS NOT NULL
	AND subscription_id ~ '^(sub|SUB)_[0-9]+$'
	--
	AND subscription_type IS NOT NULL
	AND price_eur IS NOT NULL;

INSERT INTO analytics_LLODRA_BRAURE.bikes
SELECT DISTINCT * 
FROM raw.bikes
WHERE
	bike_id IS NOT NULL
	AND bike_type IS NOT NULL
	AND model_name IS NOT NULL
	AND commissioning_date IS NOT NULL
    --
	AND status IS NOT NULL
	AND status NOT LIKE '%in_maintenance%'
	AND status NOT LIKE '%retired%';

INSERT INTO analytics_LLODRA_BRAURE.user_accounts
SELECT DISTINCT 
	ru.user_id, 
	ru.first_name, 
	ru.last_name, 
	ru.email, 
	CASE 
        WHEN ru.birthdate ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN TO_DATE(ru.birthdate, 'DD/MM/YYYY')
        ELSE ru.birthdate::date
    END AS birthdate, 
	CASE 
        WHEN ru.registration_date ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN TO_DATE(ru.registration_date, 'DD/MM/YYYY')
        ELSE ru.registration_date::date
    END AS registration_date,
	LOWER(ru.subscription_id)
FROM raw.user_accounts ru
WHERE 
    EXISTS (
        SELECT 1
        FROM analytics_LLODRA_BRAURE.subscriptions su
        WHERE su.subscription_id = LOWER(ru.subscription_id)
    )
	AND user_id IS NOT NULL
	AND ru.birthdate IS NOT NULL
    AND ru.registration_date IS NOT NULL
    AND ru.subscription_id IS NOT NULL
    AND (ru.first_name IS NOT NULL OR ru.last_name IS NOT NULL OR ru.email IS NOT NULL)
    AND ru.subscription_id ~ '^(sub|SUB)_[0-9]+$';

INSERT INTO analytics_LLODRA_BRAURE.bike_rentals
SELECT 
	rb.rental_id,
	rb.bike_id,
	rb.user_id,
	rb.start_station_id,
	rb.end_station_id,
	CASE 
        WHEN rb.start_t ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN TO_TIMESTAMP(rb.start_t, 'DD/MM/YYYY')
        ELSE rb.start_t::timestamp
    END AS start_t, 
	CASE 
        WHEN rb.end_t ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN TO_TIMESTAMP(rb.end_t, 'DD/MM/YYYY')
        ELSE rb.end_t::timestamp
    END AS end_t
FROM raw.bike_rentals rb
WHERE
	rb.rental_id IS NOT NULL
	AND rb.bike_id IS NOT NULL
	AND rb.user_id IS NOT NULL
	AND rb.start_station_id IS NOT NULL
	AND rb.start_station_id ~ '^sta_[0-9]+$'
	AND rb.end_station_id IS NOT NULL
	AND rb.end_station_id ~ '^sta_[0-9]+$'
	AND rb.start_t IS NOT NULL
	AND rb.end_t IS NOT NULL
	AND EXISTS (
        SELECT 1
        FROM analytics_LLODRA_BRAURE.bikes ab
        WHERE ab.bike_id = rb.bike_id
    )
	AND EXISTS (
        SELECT 1
        FROM analytics_LLODRA_BRAURE.user_accounts au
        WHERE au.user_id = rb.user_id
    )
	AND EXISTS (
        SELECT 1
        FROM analytics_LLODRA_BRAURE.bike_stations abi
        WHERE abi.station_id = rb.start_station_id
    )
	AND EXISTS (
        SELECT 1
        FROM analytics_LLODRA_BRAURE.bike_stations abi
        WHERE abi.station_id = rb.end_station_id
    )
	AND (
        CASE 
            WHEN rb.start_t ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4} ' 
                THEN TO_TIMESTAMP(rb.start_t, 'DD/MM/YYYY HH24:MI:SS')
            ELSE rb.start_t::timestamp
        END
    ) > '1900-01-01'::timestamp
    
    AND
    -- end_t > start_t
    (
        CASE 
            WHEN rb.end_t ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4} ' 
                THEN TO_TIMESTAMP(rb.end_t, 'DD/MM/YYYY HH24:MI:SS')
            ELSE rb.end_t::timestamp
        END
    ) >
    (
        CASE 
            WHEN rb.start_t ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4} ' 
                THEN TO_TIMESTAMP(rb.start_t, 'DD/MM/YYYY HH24:MI:SS')
            ELSE rb.start_t::timestamp
        END
    )

    AND
    -- écart < 10 ans
    AGE(
        CASE 
            WHEN rb.end_t ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4} ' 
                THEN TO_TIMESTAMP(rb.end_t, 'DD/MM/YYYY HH24:MI:SS')
            ELSE rb.end_t::timestamp
        END,
        CASE 
            WHEN rb.start_t ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4} ' 
                THEN TO_TIMESTAMP(rb.start_t, 'DD/MM/YYYY HH24:MI:SS')
            ELSE rb.start_t::timestamp
        END
    ) < INTERVAL '10 years';

--------- gold
CREATE SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity;
CREATE TABLE analytics_LLODRA_BRAURE_gold_daily_activity.rental_summary AS
SELECT 
    CONCAT(
        LOWER(LEFT(abuac.first_name, 1)), 
        REPEAT('x', LENGTH(abuac.first_name) - 1),
        ' ',
        LOWER(LEFT(abuac.last_name, 1)), 
        REPEAT('x', LENGTH(abuac.last_name) - 1)
    ) AS full_name,
    EXTRACT(YEAR FROM AGE(abuac.birthdate)) AS age,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, abuac.registration_date)) AS inscription_years,
    absub.subscription_type, 
    absub.price_eur,
    abikes.bike_type, 
    abikes.model_name, 
    abikes.commissioning_date,
    abstat_start.station_name AS start_station_name, 
    abcitie_start.city_name AS start_city, 
    abcitie_start.region AS start_region,
    EXTRACT(EPOCH FROM (abrent.end_t - abrent.start_t)) / 60 AS ride_minutes,
    abstat_end.station_name AS end_station_name, 
    abcitie_end.city_name AS end_city, 
    abcitie_end.region AS end_region

FROM analytics_LLODRA_BRAURE.bike_rentals abrent
INNER JOIN analytics_LLODRA_BRAURE.user_accounts abuac
    ON abrent.user_id = abuac.user_id
INNER JOIN analytics_LLODRA_BRAURE.subscriptions absub
    ON abuac.subscription_id = absub.subscription_id
INNER JOIN analytics_LLODRA_BRAURE.bikes abikes
    ON abrent.bike_id = abikes.bike_id
INNER JOIN analytics_LLODRA_BRAURE.bike_stations abstat_start
    ON abrent.start_station_id = abstat_start.station_id
INNER JOIN analytics_LLODRA_BRAURE.cities abcitie_start
    ON abstat_start.city_id = abcitie_start.city_id
INNER JOIN analytics_LLODRA_BRAURE.bike_stations abstat_end
    ON abrent.end_station_id = abstat_end.station_id
INNER JOIN analytics_LLODRA_BRAURE.cities abcitie_end
    ON abstat_end.city_id = abcitie_end.city_id;

CREATE TABLE analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary AS
WITH abo_top AS (
    SELECT
        c.city_name,
        s.subscription_id,
        s.subscription_type,
        s.price_eur,
        COUNT(*) AS nb_ventes,
        ROW_NUMBER() OVER (
            PARTITION BY c.city_name
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM analytics_LLODRA_BRAURE.bike_rentals br
    JOIN analytics_LLODRA_BRAURE.user_accounts ua
        ON br.user_id = ua.user_id
    JOIN analytics_LLODRA_BRAURE.subscriptions s
        ON ua.subscription_id = s.subscription_id
    JOIN analytics_LLODRA_BRAURE.bike_stations bs
        ON br.start_station_id = bs.station_id
    JOIN analytics_LLODRA_BRAURE.cities c
        ON bs.city_id = c.city_id
    GROUP BY c.city_name, s.subscription_id, s.subscription_type, s.price_eur
),
abo_bottom AS (
    SELECT
        c.city_name,
        s.subscription_id,
        s.subscription_type,
        s.price_eur,
        COUNT(*) AS nb_ventes,
        ROW_NUMBER() OVER (
            PARTITION BY c.city_name
            ORDER BY COUNT(*) ASC
        ) AS rn
    FROM analytics_LLODRA_BRAURE.bike_rentals br
    JOIN analytics_LLODRA_BRAURE.user_accounts ua
        ON br.user_id = ua.user_id
    JOIN analytics_LLODRA_BRAURE.subscriptions s
        ON ua.subscription_id = s.subscription_id
    JOIN analytics_LLODRA_BRAURE.bike_stations bs
        ON br.start_station_id = bs.station_id
    JOIN analytics_LLODRA_BRAURE.cities c
        ON bs.city_id = c.city_id
    GROUP BY c.city_name, s.subscription_id, s.subscription_type, s.price_eur
),
bike_top AS (
    SELECT
        c.city_name,
        b.bike_type,
        COUNT(*) AS nb_usages,
        ROW_NUMBER() OVER (
            PARTITION BY c.city_name
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM analytics_LLODRA_BRAURE.bike_rentals br
    JOIN analytics_LLODRA_BRAURE.bikes b
        ON br.bike_id = b.bike_id
    JOIN analytics_LLODRA_BRAURE.bike_stations bs
        ON br.start_station_id = bs.station_id
    JOIN analytics_LLODRA_BRAURE.cities c
        ON bs.city_id = c.city_id
    GROUP BY c.city_name, b.bike_type
),
bike_bottom AS (
    SELECT
        c.city_name,
        b.bike_type,
        COUNT(*) AS nb_usages,
        ROW_NUMBER() OVER (
            PARTITION BY c.city_name
            ORDER BY COUNT(*) ASC
        ) AS rn
    FROM analytics_LLODRA_BRAURE.bike_rentals br
    JOIN analytics_LLODRA_BRAURE.bikes b
        ON br.bike_id = b.bike_id
    JOIN analytics_LLODRA_BRAURE.bike_stations bs
        ON br.start_station_id = bs.station_id
    JOIN analytics_LLODRA_BRAURE.cities c
        ON bs.city_id = c.city_id
    GROUP BY c.city_name, b.bike_type
),
model_top AS (
    SELECT
        c.city_name,
        b.model_name,
        COUNT(*) AS nb_usages,
        ROW_NUMBER() OVER (
            PARTITION BY c.city_name
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM analytics_LLODRA_BRAURE.bike_rentals br
    JOIN analytics_LLODRA_BRAURE.bikes b
        ON br.bike_id = b.bike_id
    JOIN analytics_LLODRA_BRAURE.bike_stations bs
        ON br.start_station_id = bs.station_id
    JOIN analytics_LLODRA_BRAURE.cities c
        ON bs.city_id = c.city_id
    GROUP BY c.city_name, b.model_name
),
model_bottom AS (
    SELECT
        c.city_name,
        b.model_name,
        COUNT(*) AS nb_usages,
        ROW_NUMBER() OVER (
            PARTITION BY c.city_name
            ORDER BY COUNT(*) ASC
        ) AS rn
    FROM analytics_LLODRA_BRAURE.bike_rentals br
    JOIN analytics_LLODRA_BRAURE.bikes b
        ON br.bike_id = b.bike_id
    JOIN analytics_LLODRA_BRAURE.bike_stations bs
        ON br.start_station_id = bs.station_id
    JOIN analytics_LLODRA_BRAURE.cities c
        ON bs.city_id = c.city_id
    GROUP BY c.city_name, b.model_name
)
SELECT 
    abcitie_start.city_name,
    abcitie_start.region,

    COUNT(abstat_start.station_id) AS nombre_stations,
    STRING_AGG(abstat_start.station_name, ', ' ORDER BY abstat_start.station_name) AS liste_stations,

    COUNT(abrent.rental_id) AS nombre_locations,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, abuac.birthdate))))::int AS age_moyen,
	ROUND(AVG(EXTRACT(EPOCH FROM abrent.end_t - abrent.start_t) / 60)) AS duree_moyenne_minutes,

	COUNT(DISTINCT CASE WHEN abstat_start.city_id = abcitie_start.city_id THEN abrent.rental_id END) AS nb_depart,
	COUNT(DISTINCT CASE WHEN abstat_end.city_id = abcitie_end.city_id THEN abrent.rental_id END) AS nb_arrivee,
	COUNT(DISTINCT abuac.user_id) AS nb_utilisateurs_uniques,

    at.subscription_type AS type_abonnement_top,
    at.price_eur AS prix_abonnement_top,
    at.nb_ventes AS ventes_abonnement_top,

    ab.subscription_type AS type_abonnement_moins_vendu,
    ab.price_eur AS prix_abonnement_moins_vendu,
    ab.nb_ventes AS ventes_abonnement_moins_vendu,

    bt.bike_type AS bike_type_plus_utilise,
    bt.nb_usages AS nb_usages_plus_utilise,

    bb.bike_type AS bike_type_moins_utilise,
    bb.nb_usages AS nb_usages_moins_utilise,

    mt.model_name AS model_plus_utilise,
    mt.nb_usages AS nb_usages_model_plus,

    mb.model_name AS model_moins_utilise,
    mb.nb_usages AS nb_usages_model_moins

FROM analytics_LLODRA_BRAURE.bike_rentals abrent
JOIN analytics_LLODRA_BRAURE.user_accounts abuac
    ON abrent.user_id = abuac.user_id
JOIN analytics_LLODRA_BRAURE.subscriptions absub
    ON abuac.subscription_id = absub.subscription_id
JOIN analytics_LLODRA_BRAURE.bikes abikes
    ON abrent.bike_id = abikes.bike_id
JOIN analytics_LLODRA_BRAURE.bike_stations abstat_start
    ON abrent.start_station_id = abstat_start.station_id
JOIN analytics_LLODRA_BRAURE.cities abcitie_start
    ON abstat_start.city_id = abcitie_start.city_id
JOIN analytics_LLODRA_BRAURE.bike_stations abstat_end
    ON abrent.end_station_id = abstat_end.station_id
JOIN analytics_LLODRA_BRAURE.cities abcitie_end
    ON abstat_end.city_id = abcitie_end.city_id

LEFT JOIN abo_top at
    ON at.city_name = abcitie_start.city_name AND at.rn = 1
LEFT JOIN abo_bottom ab
    ON ab.city_name = abcitie_start.city_name AND ab.rn = 1
LEFT JOIN bike_top bt
    ON bt.city_name = abcitie_start.city_name AND bt.rn = 1
LEFT JOIN bike_bottom bb
    ON bb.city_name = abcitie_start.city_name AND bb.rn = 1
LEFT JOIN model_top mt
    ON mt.city_name = abcitie_start.city_name AND mt.rn = 1
LEFT JOIN model_bottom mb
    ON mb.city_name = abcitie_start.city_name AND mb.rn = 1

GROUP BY 
    abcitie_start.city_name,
    abcitie_start.region,
    at.subscription_id, at.subscription_type, at.price_eur, at.nb_ventes,
    ab.subscription_id, ab.subscription_type, ab.price_eur, ab.nb_ventes,
    bt.bike_type, bt.nb_usages,
    bb.bike_type, bb.nb_usages,
    mt.model_name, mt.nb_usages,
    mb.model_name, mb.nb_usages

ORDER BY abcitie_start.city_name;

CREATE TABLE analytics_LLODRA_BRAURE_gold_daily_activity.station_summary AS
SELECT 
    s.station_name,
	s.latitude,
	s.longitude,
    c.city_name,
    s.capacity AS capacite_station,
    COALESCE(departs.nb_departs, 0) AS nombre_departs,
    COALESCE(arrivees.nb_arrivees, 0) AS nombre_arrivees,
    COALESCE(departs.nb_departs, 0) + COALESCE(arrivees.nb_arrivees, 0) AS total_mouvements,
    COALESCE(departs.nb_departs, 0) - COALESCE(arrivees.nb_arrivees, 0) AS solde_velos,
    CASE 
        WHEN s.capacity > 0 THEN 
            ROUND((COALESCE(departs.nb_departs, 0) - COALESCE(arrivees.nb_arrivees, 0))::numeric / s.capacity * 100, 2)
        ELSE NULL 
    END AS taux_desequilibre_pct,
    CASE 
        WHEN COALESCE(departs.nb_departs, 0) - COALESCE(arrivees.nb_arrivees, 0) > s.capacity * 0.5 THEN 'DEFICIT CRITIQUE'
        WHEN COALESCE(departs.nb_departs, 0) - COALESCE(arrivees.nb_arrivees, 0) > s.capacity * 0.2 THEN 'DEFICIT MODERE'
        WHEN COALESCE(departs.nb_departs, 0) - COALESCE(arrivees.nb_arrivees, 0) < -s.capacity * 0.5 THEN 'SURPLUS CRITIQUE'
        WHEN COALESCE(departs.nb_departs, 0) - COALESCE(arrivees.nb_arrivees, 0) < -s.capacity * 0.2 THEN 'SURPLUS MODERE'
        ELSE 'EQUILIBRE'
    END AS statut_station,
    ROUND(COALESCE(stats_temps.temps_moyen_minutes, 0), 2) AS temps_moyen_location_min,
    COALESCE(stats_users.nb_utilisateurs_uniques, 0) AS nb_utilisateurs_uniques,
    type_plus.bike_type AS type_velo_plus_utilise,
    type_plus.nb_locations AS nb_locations_type_plus,
    model_plus.model_name AS modele_plus_utilise,
    model_plus.nb_locations AS nb_locations_modele_plus,
    type_moins.bike_type AS type_velo_moins_utilise,
    type_moins.nb_locations AS nb_locations_type_moins,
    model_moins.model_name AS modele_moins_utilise,
    model_moins.nb_locations AS nb_locations_modele_moins
FROM analytics_LLODRA_BRAURE.bike_stations s
JOIN analytics_LLODRA_BRAURE.cities c
    ON s.city_id = c.city_id
LEFT JOIN (
    SELECT 
        start_station_id,
        COUNT(rental_id) AS nb_departs
    FROM analytics_LLODRA_BRAURE.bike_rentals
    GROUP BY start_station_id
) departs ON s.station_id = departs.start_station_id
LEFT JOIN (
    SELECT 
        end_station_id,
        COUNT(rental_id) AS nb_arrivees
    FROM analytics_LLODRA_BRAURE.bike_rentals
    GROUP BY end_station_id
) arrivees ON s.station_id = arrivees.end_station_id
LEFT JOIN (
    SELECT 
        start_station_id,
        AVG(EXTRACT(EPOCH FROM (end_t - start_t)) / 60) AS temps_moyen_minutes,
        COUNT(DISTINCT user_id) AS nb_utilisateurs_uniques
    FROM analytics_LLODRA_BRAURE.bike_rentals
    WHERE end_t IS NOT NULL AND start_t IS NOT NULL
    GROUP BY start_station_id
) stats_temps ON s.station_id = stats_temps.start_station_id
LEFT JOIN (
    SELECT 
        start_station_id,
        COUNT(DISTINCT user_id) AS nb_utilisateurs_uniques
    FROM analytics_LLODRA_BRAURE.bike_rentals
    GROUP BY start_station_id
) stats_users ON s.station_id = stats_users.start_station_id
LEFT JOIN LATERAL (
    SELECT 
        b.bike_type,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE r.start_station_id = s.station_id
    GROUP BY b.bike_type
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1
) type_plus ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.model_name,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE r.start_station_id = s.station_id
    GROUP BY b.model_name
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1
) model_plus ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.bike_type,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE r.start_station_id = s.station_id
    GROUP BY b.bike_type
    ORDER BY COUNT(r.rental_id) ASC
    LIMIT 1
) type_moins ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.model_name,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE r.start_station_id = s.station_id
    GROUP BY b.model_name
    ORDER BY COUNT(r.rental_id) ASC
    LIMIT 1
) model_moins ON TRUE
ORDER BY total_mouvements DESC;

CREATE TABLE analytics_LLODRA_BRAURE_gold_daily_activity.bikes_summary AS
SELECT 
    b.bike_id,
    b.bike_type AS type_velo,
    b.model_name AS modele,
    b.status AS statut,
    b.commissioning_date AS date_mise_en_service,
    COALESCE(stats.nb_utilisations, 0) AS nb_total_utilisations,
    ROUND(COALESCE(stats.temps_moyen_minutes, 0), 2) AS temps_moyen_utilisation_min,
    last_station.station_name AS station_actuelle,
    last_city.city_name AS ville_actuelle,
    stats.derniere_location AS date_derniere_location,
    stats.nb_utilisateurs_uniques AS nb_utilisateurs_uniques,
    CASE 
        WHEN total_locations.total > 0 THEN 
            ROUND((COALESCE(stats.nb_utilisations, 0)::numeric / total_locations.total * 100), 2)
        ELSE 0 
    END AS pourcentage_utilisation,
    ROUND(COALESCE(stats.age_moyen_utilisateurs, 0), 1) AS age_moyen_utilisateurs
FROM analytics_LLODRA_BRAURE.bikes b
LEFT JOIN (
    SELECT 
        r.bike_id,
        COUNT(r.rental_id) AS nb_utilisations,
        AVG(EXTRACT(EPOCH FROM (r.end_t - r.start_t)) / 60) AS temps_moyen_minutes,
        MAX(r.end_t) AS derniere_location,
        AVG(EXTRACT(YEAR FROM AGE(r.start_t, ua.birthdate))) AS age_moyen_utilisateurs,
        COUNT(DISTINCT r.user_id) AS nb_utilisateurs_uniques
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    LEFT JOIN analytics_LLODRA_BRAURE.user_accounts ua ON r.user_id = ua.user_id
    WHERE r.end_t IS NOT NULL AND r.start_t IS NOT NULL
    GROUP BY r.bike_id
) stats ON b.bike_id = stats.bike_id
LEFT JOIN LATERAL (
    SELECT 
        r.end_station_id,
        r.end_t
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    WHERE r.bike_id = b.bike_id 
      AND r.end_t IS NOT NULL
    ORDER BY r.end_t DESC
    LIMIT 1
) last_rental ON TRUE
LEFT JOIN analytics_LLODRA_BRAURE.bike_stations last_station 
    ON last_rental.end_station_id = last_station.station_id
LEFT JOIN analytics_LLODRA_BRAURE.cities last_city 
    ON last_station.city_id = last_city.city_id
CROSS JOIN (
    SELECT COUNT(rental_id) AS total
    FROM analytics_LLODRA_BRAURE.bike_rentals
) total_locations
ORDER BY nb_total_utilisations DESC;

CREATE TABLE analytics_LLODRA_BRAURE_gold_daily_activity.subscription_summary AS
SELECT 
    sub.subscription_type AS type_abonnement,
    sub.price_eur AS prix_euros,
    COALESCE(stats.nb_total_locations, 0) AS nb_total_locations,
    COALESCE(stats.nb_velos_utilises, 0) AS nb_velos_utilises,
    ROUND(COALESCE(stats.age_moyen, 0), 1) AS age_moyen_abonnes,
    COALESCE(stats.nb_utilisateurs_uniques, 0) AS nb_utilisateurs_uniques,
    ROUND(COALESCE(stats.temps_moyen_minutes, 0), 2) AS temps_moyen_location_min,
    type_plus.bike_type AS type_velo_plus_utilise,
    type_plus.nb_locations AS nb_locations_type_plus,
    type_moins.bike_type AS type_velo_moins_utilise,
    type_moins.nb_locations AS nb_locations_type_moins,
    model_plus.model_name AS modele_plus_utilise,
    model_plus.nb_locations AS nb_locations_modele_plus,
    model_moins.model_name AS modele_moins_utilise,
    model_moins.nb_locations AS nb_locations_modele_moins
FROM analytics_LLODRA_BRAURE.subscriptions sub
LEFT JOIN (
    SELECT 
        ua.subscription_id,
        COUNT(r.rental_id) AS nb_total_locations,
        COUNT(DISTINCT r.bike_id) AS nb_velos_utilises,
        AVG(EXTRACT(YEAR FROM AGE(r.start_t, ua.birthdate))) AS age_moyen,
        COUNT(DISTINCT ua.user_id) AS nb_utilisateurs_uniques,
        AVG(EXTRACT(EPOCH FROM (r.end_t - r.start_t)) / 60) AS temps_moyen_minutes
    FROM analytics_LLODRA_BRAURE.user_accounts ua
    JOIN analytics_LLODRA_BRAURE.bike_rentals r ON ua.user_id = r.user_id
    WHERE r.end_t IS NOT NULL AND r.start_t IS NOT NULL
    GROUP BY ua.subscription_id
) stats ON sub.subscription_id = stats.subscription_id
LEFT JOIN LATERAL (
    SELECT 
        b.bike_type,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.user_accounts ua
    JOIN analytics_LLODRA_BRAURE.bike_rentals r ON ua.user_id = r.user_id
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE ua.subscription_id = sub.subscription_id
    GROUP BY b.bike_type
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1
) type_plus ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.bike_type,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.user_accounts ua
    JOIN analytics_LLODRA_BRAURE.bike_rentals r ON ua.user_id = r.user_id
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE ua.subscription_id = sub.subscription_id
    GROUP BY b.bike_type
    ORDER BY COUNT(r.rental_id) ASC
    LIMIT 1
) type_moins ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.model_name,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.user_accounts ua
    JOIN analytics_LLODRA_BRAURE.bike_rentals r ON ua.user_id = r.user_id
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE ua.subscription_id = sub.subscription_id
    GROUP BY b.model_name
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1
) model_plus ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.model_name,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.user_accounts ua
    JOIN analytics_LLODRA_BRAURE.bike_rentals r ON ua.user_id = r.user_id
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE ua.subscription_id = sub.subscription_id
    GROUP BY b.model_name
    ORDER BY COUNT(r.rental_id) ASC
    LIMIT 1
) model_moins ON TRUE
ORDER BY nb_total_locations DESC;

CREATE TABLE analytics_LLODRA_BRAURE_gold_daily_activity.user_summary AS
SELECT 
    CONCAT(
        SUBSTRING(ua.first_name, 1, 1),
        REPEAT('x', LENGTH(ua.first_name) - 1),
        ' ',
        SUBSTRING(ua.last_name, 1, 1),
        REPEAT('x', LENGTH(ua.last_name) - 1)
    ) AS nom_anonymise,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, ua.birthdate)) AS age,
    CONCAT(sub.subscription_type, ' (', sub.price_eur, '€)') AS abonnement_et_prix,
    EXTRACT(DAY FROM AGE(CURRENT_DATE, ua.registration_date)) AS jours_inscription,
    ROUND(COALESCE(stats.temps_total_ride_minutes, 0), 2) AS temps_ride_total_min,
    ROUND(COALESCE(stats.temps_moyen_ride_minutes, 0), 2) AS temps_ride_moyen_min,
    COALESCE(stats.nb_total_locations, 0) AS nb_total_locations,
    type_plus.bike_type AS type_velo_plus_utilise,
    type_plus.nb_locations AS nb_locations_type_plus,
    type_moins.bike_type AS type_velo_moins_utilise,
    type_moins.nb_locations AS nb_locations_type_moins,
    model_plus.model_name AS modele_plus_utilise,
    model_plus.nb_locations AS nb_locations_modele_plus,
    model_moins.model_name AS modele_moins_utilise,
    model_moins.nb_locations AS nb_locations_modele_moins
FROM analytics_LLODRA_BRAURE.user_accounts ua
LEFT JOIN analytics_LLODRA_BRAURE.subscriptions sub 
    ON ua.subscription_id = sub.subscription_id
LEFT JOIN (
    SELECT 
        r.user_id,
        COUNT(r.rental_id) AS nb_total_locations,
        SUM(EXTRACT(EPOCH FROM (r.end_t - r.start_t)) / 60) AS temps_total_ride_minutes,
        AVG(EXTRACT(EPOCH FROM (r.end_t - r.start_t)) / 60) AS temps_moyen_ride_minutes
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    WHERE r.end_t IS NOT NULL AND r.start_t IS NOT NULL
    GROUP BY r.user_id
) stats ON ua.user_id = stats.user_id
LEFT JOIN LATERAL (
    SELECT 
        b.bike_type,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE r.user_id = ua.user_id
    GROUP BY b.bike_type
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1
) type_plus ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.bike_type,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE r.user_id = ua.user_id
    GROUP BY b.bike_type
    ORDER BY COUNT(r.rental_id) ASC
    LIMIT 1
) type_moins ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.model_name,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE r.user_id = ua.user_id
    GROUP BY b.model_name
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1
) model_plus ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        b.model_name,
        COUNT(r.rental_id) AS nb_locations
    FROM analytics_LLODRA_BRAURE.bike_rentals r
    JOIN analytics_LLODRA_BRAURE.bikes b ON r.bike_id = b.bike_id
    WHERE r.user_id = ua.user_id
    GROUP BY b.model_name
    ORDER BY COUNT(r.rental_id) ASC
    LIMIT 1
) model_moins ON TRUE
ORDER BY nb_total_locations DESC;

CREATE TABLE analytics_LLODRA_BRAURE_gold_daily_activity.global_summary AS
SELECT 
    (SELECT COUNT(*) FROM analytics_LLODRA_BRAURE.user_accounts) AS nb_total_utilisateurs,
    ROUND(COALESCE((
        SELECT SUM(EXTRACT(EPOCH FROM (end_t - start_t)) / 60)
        FROM analytics_LLODRA_BRAURE.bike_rentals
        WHERE end_t IS NOT NULL AND start_t IS NOT NULL
    ), 0), 2) AS temps_ride_total_minutes,
    ROUND(COALESCE((
        SELECT AVG(EXTRACT(EPOCH FROM (end_t - start_t)) / 60)
        FROM analytics_LLODRA_BRAURE.bike_rentals
        WHERE end_t IS NOT NULL AND start_t IS NOT NULL
    ), 0), 2) AS temps_ride_moyen_minutes,
    (SELECT COUNT(*) FROM analytics_LLODRA_BRAURE.bike_rentals) AS nb_total_locations,
    (SELECT COUNT(DISTINCT bike_type) FROM analytics_LLODRA_BRAURE.bikes) AS nb_types_velo_differents,
    (SELECT COUNT(DISTINCT model_name) FROM analytics_LLODRA_BRAURE.bikes) AS nb_modeles_differents,
    (SELECT COUNT(*) FROM analytics_LLODRA_BRAURE.bikes) AS nb_total_velos,
    (SELECT COUNT(*) FROM analytics_LLODRA_BRAURE.bike_stations) AS nb_total_stations,
    (SELECT COUNT(*) FROM analytics_LLODRA_BRAURE.cities) AS nb_villes_implementation,
    (SELECT COUNT(DISTINCT region) FROM analytics_LLODRA_BRAURE.cities) AS nb_regions,
    ROUND(COALESCE((
        SELECT AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate)))
        FROM analytics_LLODRA_BRAURE.user_accounts
        WHERE birthdate IS NOT NULL
    ), 0), 1) AS age_moyen_utilisateurs,
    (SELECT sub.subscription_type
     FROM analytics_LLODRA_BRAURE.subscriptions sub
     JOIN analytics_LLODRA_BRAURE.user_accounts ua ON sub.subscription_id = ua.subscription_id
     GROUP BY sub.subscription_type
     ORDER BY COUNT(ua.user_id) DESC
     LIMIT 1) AS abonnement_plus_vendu,
    (SELECT COUNT(ua.user_id)
     FROM analytics_LLODRA_BRAURE.subscriptions sub
     JOIN analytics_LLODRA_BRAURE.user_accounts ua ON sub.subscription_id = ua.subscription_id
     GROUP BY sub.subscription_type
     ORDER BY COUNT(ua.user_id) DESC
     LIMIT 1) AS nb_ventes_abonnement_plus_vendu,
    ROUND(COALESCE((
        SELECT AVG(price_eur)
        FROM analytics_LLODRA_BRAURE.subscriptions
    ), 0), 2) AS prix_moyen_abonnements;