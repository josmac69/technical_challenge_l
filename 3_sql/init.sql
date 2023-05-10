-- code for postgresql database creation and tables creation

-- Create tables
CREATE TABLE IF NOT EXISTS public.impressions (
    product_id INT,
    click BOOLEAN,
    date DATE
);

CREATE TABLE IF NOT EXISTS public.products (
    product_id INT,
    category_id INT,
    price INT
);

CREATE TABLE IF NOT EXISTS public.purchases (
    product_id INT,
    user_id INT,
    date DATE
);

-- Insert data
INSERT INTO public.impressions (product_id, click, date) VALUES
(1002313001, (SELECT floor(random()*2)::int)::boolean, '2018-07-10'),
(1002313002, (SELECT floor(random()*2)::int)::boolean, '2018-07-10'),
(1002313003, (SELECT floor(random()*2)::int)::boolean, '2018-07-10'),
(1002313004, (SELECT floor(random()*2)::int)::boolean, '2018-07-10'),
(1002313005, (SELECT floor(random()*2)::int)::boolean, '2018-07-10'),
(1002313006, (SELECT floor(random()*2)::int)::boolean, '2018-07-11'),
(1002313007, (SELECT floor(random()*2)::int)::boolean, '2018-07-11'),
(1002313008, (SELECT floor(random()*2)::int)::boolean, '2018-07-11'),
(1002313009, (SELECT floor(random()*2)::int)::boolean, '2018-07-11'),
(1002313001, (SELECT floor(random()*2)::int)::boolean, '2018-07-12'),
(1002313002, (SELECT floor(random()*2)::int)::boolean, '2018-07-12'),
(1002313003, (SELECT floor(random()*2)::int)::boolean, '2018-07-12'),
(1002313004, (SELECT floor(random()*2)::int)::boolean, '2018-07-12'),
(1002313005, (SELECT floor(random()*2)::int)::boolean, '2018-07-12'),
(1002313006, (SELECT floor(random()*2)::int)::boolean, '2018-07-13'),
(1002313007, (SELECT floor(random()*2)::int)::boolean, '2018-07-13'),
(1002313008, (SELECT floor(random()*2)::int)::boolean, '2018-07-13'),
(1002313009, (SELECT floor(random()*2)::int)::boolean, '2018-07-13'),
(1002313001, (SELECT floor(random()*2)::int)::boolean, '2018-07-14'),
(1002313002, (SELECT floor(random()*2)::int)::boolean, '2018-07-14'),
(1002313003, (SELECT floor(random()*2)::int)::boolean, '2018-07-14'),
(1002313004, (SELECT floor(random()*2)::int)::boolean, '2018-07-14'),
(1002313005, (SELECT floor(random()*2)::int)::boolean, '2018-07-14'),
(1002313006, (SELECT floor(random()*2)::int)::boolean, '2018-07-15'),
(1002313007, (SELECT floor(random()*2)::int)::boolean, '2018-07-15'),
(1002313008, (SELECT floor(random()*2)::int)::boolean, '2018-07-15'),
(1002313009, (SELECT floor(random()*2)::int)::boolean, '2018-07-15'),
(1002313001, (SELECT floor(random()*2)::int)::boolean, '2018-07-16'),
(1002313002, (SELECT floor(random()*2)::int)::boolean, '2018-07-16'),
(1002313003, (SELECT floor(random()*2)::int)::boolean, '2018-07-16'),
(1002313004, (SELECT floor(random()*2)::int)::boolean, '2018-07-16'),
(1002313005, (SELECT floor(random()*2)::int)::boolean, '2018-07-16'),
(1002313006, (SELECT floor(random()*2)::int)::boolean, '2018-07-17'),
(1002313007, (SELECT floor(random()*2)::int)::boolean, '2018-07-17'),
(1002313008, (SELECT floor(random()*2)::int)::boolean, '2018-07-17'),
(1002313009, (SELECT floor(random()*2)::int)::boolean, '2018-07-17');

INSERT INTO public.products (product_id, category_id, price) VALUES
(1002313001, 3, 3),
(1002313002, 4, 7),
(1002313003, 1, 10),
(1002313004, 1, 5),
(1002313005, 2, 30),
(1002313006, 1, 20),
(1002313007, 2, 35),
(1002313008, 1, 15),
(1002313009, 2, 40);

INSERT INTO public.purchases (product_id, user_id, date) VALUES
(1002313003, 1003431, '2018-07-10'),
(1002313002, 1003432, '2018-07-11'),
(1002313004, 1003433, '2018-07-12'),
(1002313005, 1003434, '2018-07-13'),
(1002313006, 1003435, '2018-07-14'),
(1002313007, 1003436, '2018-07-15'),
(1002313008, 1003437, '2018-07-16'),
(1002313009, 1003438, '2018-07-17');
