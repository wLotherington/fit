CREATE TABLE users (
  id serial PRIMARY KEY,
  name text NOT NULL CHECK (LENGTH(name) > 0)
);

CREATE TABLE workouts (
  id serial PRIMARY KEY,
  name text NOT NULL CHECK (LENGTH(name) > 0),
  notes text,
  last_completed date,
  last_trained date
);

CREATE TABLE exercises (
  id serial PRIMARY KEY,
  name text NOT NULL CHECK (LENGTH(name) > 0),
  notes text,
  sets integer NOT NULL CHECK (sets > 0),
  reps integer NOT NULL CHECK (reps > 0),
  initial_weight integer NOT NULL CHECK (initial_weight > 0)
);

CREATE TABLE sets (
  id serial PRIMARY KEY,
  reps integer NOT NULL CHECK (reps > 0),
  weight integer NOT NULL CHECK (weight > 0),
  day date NOT NULL DEFAULT NOW(),
  notes text,
  exercise_id integer NOT NULL REFERENCES exercises(id) ON DELETE CASCADE
);

CREATE TABLE health_stats (
  id serial PRIMARY KEY,
  day date NOT NULL DEFAULT NOW(),
  weight numeric(4,1) CHECK (weight > 0),
  body_fat numeric(3,1) CHECK (body_fat > 0),
  user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE users_workouts (
  id serial PRIMARY KEY,
  user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workout_id integer NOT NULL REFERENCES workouts(id) ON DELETE CASCADE
);

CREATE TABLE workouts_exercises (
  id serial PRIMARY KEY,
  workout_id integer NOT NULL REFERENCES workouts(id),
  exercise_id integer NOT NULL REFERENCES exercises(id)
);

-- CREATE FAKE DATA
INSERT INTO users (name) VALUES
  ('Will'),
  ('Madeline');

INSERT INTO workouts (name, notes) VALUES
  ('workout 1', 'legs'),
  ('workout 2', 'back');

INSERT INTO exercises (name, notes, sets, reps, initial_weight) VALUES
  ('squat', 'straight back', 4, 8, 100),
  ('deadlift', 'this is hard', 4, 8, 100),
  ('bench', 'something', 3, 10, 120);

-- INSERT INTO sets (reps, weight, day, notes, )

-- INSERT INTO health_stats
-- INSERT INTO users_workouts
-- INSERT INTO workouts_exercises

-- DROP ALL TABLES
-- DROP TABLE users CASCADE;
-- DROP TABLE workouts CASCADE;
-- DROP TABLE exercises CASCADE;
-- DROP TABLE sets;
-- DROP TABLE health_stats;
-- DROP TABLE users_workouts;
-- DROP TABLE workouts_exercises;