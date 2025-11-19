CREATE ROLE marketing_user LOGIN PASSWORD 'marketing_user';
REVOKE ALL ON SCHEMA raw FROM marketing_user;
REVOKE ALL ON ALL TABLES IN SCHEMA raw FROM marketing_user;
GRANT USAGE ON SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity TO marketing_user;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity TO marketing_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity
GRANT SELECT ON TABLES TO marketing_user;

CREATE ROLE manager_lyon LOGIN PASSWORD 'manager_lyon';
GRANT USAGE ON SCHEMA analytics_LLODRA_BRAURE_gold_daily_activity TO manager_lyon;
GRANT SELECT ON analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary TO manager_lyon;
ALTER TABLE analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary ENABLE ROW LEVEL SECURITY;
CREATE POLICY lyon_only_policy
ON analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary
FOR SELECT
TO manager_lyon
USING (city_name = 'Lyon');

SET ROLE manager_lyon;
SELECT * FROM raw.user_accounts;
SELECT city_name, nombre_locations
FROM analytics_LLODRA_BRAURE_gold_daily_activity.cities_summary;
RESET ROLE;
