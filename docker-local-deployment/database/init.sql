-- SQL script to initialize the database schema
-- This script creates the 'goals' table if it does not already exist
CREATE TABLE IF NOT EXISTS goals (
  id SERIAL PRIMARY KEY,
  goal_name TEXT NOT NULL
);