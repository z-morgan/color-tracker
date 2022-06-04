-- database name: salon_inventory_db

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

INSERT INTO users (username, password, first_name)
VALUES ('johngalt', 'whoisjohngalt', 'John');

INSERT INTO inventories (user_id, name)
VALUES (1, 'John''s 1st Inventory');

INSERT INTO lines ( name)
VALUES ('Wella');

INSERT INTO inventories_lines (inventory_id, line_id)
VALUES (1, 1);

INSERT INTO colors (inventory_id, line_id, depth, tone, count)
VALUES (1, 1, '10', '22', 5), (1, 1, '4', '6', 5);