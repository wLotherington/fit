CREATE TABLE users (
  id serial PRIMARY KEY,
  name text NOT NULL
);

-- INSERT INTO users (name)
-- VALUES ('Will');

CREATE TABLE measurements (
  id serial PRIMARY KEY,
  day date NOT NULL DEFAULT now(),
  user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  weight numeric(5,1),
  body_fat numeric(3,1),
  notes text
);

-- INSERT INTO measurements (user_id, weight, body_fat, notes)
-- VALUES (1, 170, 15, 'I''m just guessing');
