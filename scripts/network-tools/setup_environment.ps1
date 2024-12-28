# Create initial project structure and database
$ErrorActionPreference = "Stop"

# Create project directories
$dirs = @(
    ".\IntegratedSearch",
    ".\IntegratedSearch\Database",
    ".\IntegratedSearch\Services",
    ".\IntegratedSearch\UI",
    ".\IntegratedSearch\Logs"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force
}

# Initialize PostgreSQL database
$env:PGPASSWORD = "RoulApp3567!"
$psql = "C:/Program Files/PostgreSQL/17/bin/psql.exe"

# Create database and schema
$sql = @"
CREATE DATABASE username_db;
\c username_db

CREATE SCHEMA IF NOT EXISTS integrated_search;

CREATE TABLE integrated_search.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE integrated_search.platform_accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES integrated_search.users(id),
    platform VARCHAR(100) NOT NULL,
    account_url TEXT,
    username VARCHAR(255),
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE integrated_search.bookmarks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES integrated_search.users(id),
    url TEXT NOT NULL,
    title VARCHAR(500),
    description TEXT,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON integrated_search.users(username);
CREATE INDEX idx_platform_accounts_username ON integrated_search.platform_accounts(username);
CREATE INDEX idx_bookmarks_url ON integrated_search.bookmarks(url);
"@

$sql | & $psql -U postgres -h localhost 