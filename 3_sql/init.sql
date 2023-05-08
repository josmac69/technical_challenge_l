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
(1002313003, true, '2018-07-10'),
(1002313002, false, '2018-07-10');

INSERT INTO public.products (product_id, category_id, price) VALUES
(1002313003, 1, 10),
(1002313002, 2, 15);

INSERT INTO public.purchases (product_id, user_id, date) VALUES
(1002313003, 1003431, '2018-07-10'),
(1002313002, 1003432, '2018-07-11');
