CREATE TABLE measurements (
  id serial PRIMARY KEY,
  day date NOT NULL DEFAULT now(),
  weight numeric(5,1),
  body_fat numeric(3,1)
);

CREATE TABLE workouts (
  id serial PRIMARY KEY,
  name text NOT NULL,
  time_created timestamp NOT NULL DEFAULT now(),
  last_completed date NOT NULL DEFAULT '0001-01-01',
  active boolean NOT NULL DEFAULT false
);

CREATE TABLE exercises (
  id serial PRIMARY KEY,
  name text NOT NULL,
  time_created timestamp NOT NULL DEFAULT now()
);

CREATE TABLE workouts_exercises (
  id serial PRIMARY KEY,
  workout_id integer NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  exercise_id integer NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  target_sets integer NOT NULL,
  target_reps integer NOT NULL,
  starting_weight numeric(5,2) NOT NULL
);

CREATE TABLE instances (
  id serial PRIMARY KEY,
  workout_exercise_id integer NOT NULL REFERENCES workouts_exercises(id),
  time_completed timestamp NOT NULL DEFAULT now(),
  completed_reps integer NOT NULL,
  lifted_weight numeric(5,2) NOT NULL
);

INSERT INTO measurements (weight, body_fat) VALUES
  (180, 15),
  (180, 12)
;

INSERT INTO workouts (name, active) VALUES
  ('first workout', true),
  ('second workout', true),
  ('third workout', false)
;

INSERT INTO exercises (name) VALUES
  ('test1'),
  ('test2'),
  ('test3'),
  ('test4')
;

INSERT INTO workouts_exercises (workout_id, exercise_id, target_sets, target_reps, starting_weight) VALUES
  (1, 1, 4, 5, 100),
  (1, 2, 4, 5, 100),
  (1, 3, 4, 5, 100),
  (2, 1, 4, 5, 100),
  (2, 2, 4, 5, 100),
  (2, 3, 4, 5, 100),
  (3, 1, 4, 5, 100),
  (3, 2, 4, 5, 100)
;

INSERT INTO instances (workout_exercise_id, completed_reps, lifted_weight) VALUES
  (1, 5, 100),
  (1, 5, 110),
  (1, 5, 120),
  (1, 5, 130),
  (2, 5, 140),
  (2, 5, 150),
  (2, 5, 160),
  (2, 5, 170),
  (3, 5, 100),
  (4, 5, 110),
  (5, 5, 120),
  (3, 5, 130),
  (3, 5, 140),
  (4, 5, 150),
  (5, 5, 160),
  (4, 5, 170)
;