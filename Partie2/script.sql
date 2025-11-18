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
CREATE SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity
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
