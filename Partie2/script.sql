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
    birthdate timestamp with time zone,
    registration_date timestamp with time zone,
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
    station_name character varying(255) COLLATE pg_catalog."default",
    latitude numeric(3,4),
    longitude numeric(3,4),
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
    forecast_time timestamp with time zone,
    temperature_celsius numeric(4,1),
    precipitation_mm numeric(4,1),
    CONSTRAINT weather_forecast_hourly_pkey PRIMARY KEY (forecast_id)
)
TABLESPACE pg_default;
ALTER TABLE IF EXISTS analytics_LLODRA_BRAURE.weather_forecast_hourly
    OWNER to postgres;