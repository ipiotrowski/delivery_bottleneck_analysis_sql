-- Create the three working schemas: raw -> staging -> marts.

CREATE SCHEMA IF NOT EXISTS olist_raw
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

CREATE SCHEMA IF NOT EXISTS olist_staging
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

CREATE SCHEMA IF NOT EXISTS olist_marts
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;
