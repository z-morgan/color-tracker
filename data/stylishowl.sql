DELETE FROM users WHERE id = 999999;

DELETE FROM lines WHERE id = 999999 OR id = 999998;

INSERT INTO users (id, username, password, first_name)
VALUES (999999, 'stylishowl', '$2a$12$SmJQN5GEoz/4ceGhMKhGpuKJ1l0194Hczs.DZrRX5IgkNtG3Xk5C.', 'Stylish Owl');

INSERT INTO inventories (id, user_id, name)
VALUES (999999, 999999, 'Stylish Stuff'), (999998, 999999, 'More Stylish Stuff');

INSERT INTO lines (id, name)
VALUES (999998, 'Super Stylish'), (999999, 'Extra Stylish');

INSERT INTO inventories_lines (id, inventory_id, line_id)
VALUES (999990, 999999, 999998), (999991, 999999, 999999);

INSERT INTO colors (id, inventory_id, line_id, depth, tone, count)
VALUES (999990, 999999, 999998, '1', '2', 4),
(999991, 999999, 999998, '2', '3', 5),
(999992, 999999, 999998, '3', '1', 2),
(999993, 999999, 999998, '5', '22', 2),
(999994, 999999, 999998, '5', '21', 5),
(999995, 999999, 999998, '5', '2', 1),
(999996, 999999, 999998, '8', '9', 2),
(999997, 999999, 999998, '11', '4', 3),
(999998, 999999, 999998, '8', '3', 1),
(999999, 999999, 999999, '3', '5', 2),
(999980, 999999, 999999, '5', '6', 3),
(999981, 999999, 999999, '9', '3', 5),
(999982, 999999, 999999, '10', '42', 6);