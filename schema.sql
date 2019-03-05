CREATE TABLE measurements (
  id serial PRIMARY KEY,
  day date NOT NULL DEFAULT now(),
  weight numeric(5,1),
  body_fat numeric(3,1)
);

CREATE TABLE workouts (
  id serial PRIMARY KEY,
  name text NOT NULL,
  day_created date NOT NULL DEFAULT now(),
  last_completed date,
  active boolean NOT NULL DEFAULT false
);

CREATE TABLE exercises (
  id serial PRIMARY KEY,
  name text NOT NULL,
  sets integer NOT NULL,
  reps integer NOT NULL,
  weight integer NOT NULL
);

CREATE TABLE workouts_exercises (
  id serial PRIMARY KEY,
  workout_id integer NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  exercise_id integer NOT NULL REFERENCES exercises(id) ON DELETE CASCADE
);

-- INSERT INTO measurements (weight, body_fat) VALUES
--   (180, 15)
-- ;

-- INSERT INTO workouts (name, active) VALUES
--   ('first workout', true)
-- ;

-- INSERT INTO exercises (name, sets, reps, weight) VALUES
--   ('test', 4, 5, 100)
-- ;

-- INSERT INTO workouts_exercises (workout_id, exercise_id) VALUES
--   (1, 1)
-- ;