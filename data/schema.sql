CREATE TABLE users(
  id serial PRIMARY KEY,
  username varchar(50) NOT NULL UNIQUE,
  password text NOT NULL,
  first_name varchar(50) NOT NULL
);

CREATE TABLE inventories(
  id serial PRIMARY KEY,
  user_id int NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  name varchar(50) NOT NULL
);


CREATE TABLE lines(
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE inventories_lines(
  id serial PRIMARY KEY,
  inventory_id int NOT NULL REFERENCES inventories (id) ON DELETE CASCADE,
  line_id int NOT NULL REFERENCES lines (id)
);

CREATE TABLE colors(
  id serial PRIMARY KEY,
  inventory_id int NOT NULL REFERENCES inventories (id) ON DELETE CASCADE,
  line_id int NOT NULL REFERENCES lines (id),
  depth varchar(2) NOT NULL,
  tone varchar(2) NOT NULL,
  count int NOT NULL,
  CHECK (count >= 0)
);
