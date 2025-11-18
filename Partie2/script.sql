SET timezone = 'Europe/Paris';

--------- raw
SELECT * FROM raw.bike_rentals;
SELECT * FROM raw.user_accounts;
SELECT * FROM raw.subscriptions;
SELECT * FROM raw.bikes;
SELECT * FROM raw.bike_stations;
SELECT * FROM raw.cities;
SELECT * FROM raw.weather_forecast_hourly;

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

--
CREATE TABLE IF NOT EXISTS analytics_LLODRA_BRAURE.weather_forecast_hourly
(
    forecast_id serial NOT NULL,
    city_id serial,
    forecast_time timestamp with time zone,
    temperature_celsius numeric(4,1),
    precipitation_mm numeric(4,1),
    CONSTRAINT weather_forecast_hourly_pkey PRIMARY KEY (forecast_id)
)
TABLESPACE pg_default;
ALTER TABLE IF EXISTS analytics_LLODRA_BRAURE.weather_forecast_hourly
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

INSERT INTO analytics_LLODRA_BRAURE.weather_forecast_hourly
SELECT DISTINCT *
FROM raw.weather_forecast_hourly wf
WHERE 
    wf.forecast_id IS NOT NULL
    AND wf.city_id IS NOT NULL
    AND wf.forecast_time IS NOT NULL
    --
    AND wf.temperature_celsius IS NOT NULL
    AND wf.temperature_celsius BETWEEN -50 AND 60
    --
    AND wf.precipitation_mm IS NOT NULL
    AND wf.precipitation_mm BETWEEN 0 AND 10000
    AND EXISTS (
        SELECT 1
        FROM analytics_LLODRA_BRAURE.cities c
        WHERE c.city_id = wf.city_id
    );

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