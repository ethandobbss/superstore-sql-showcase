-- Here I am creating more manageable tables that I will divide the columns from the raw dataset (data/Superstore.csv) into. 

CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    customer_name TEXT,
    segment TEXT
);

CREATE TABLE products (
    product_id TEXT PRIMARY KEY,
    product_name TEXT,
    category TEXT,
    sub_category TEXT
);

CREATE TABLE locations (
    location_id INTEGER PRIMARY KEY AUTOINCREMENT,
    city TEXT,
    state TEXT,
    region TEXT,
    postal_code TEXT,
    country TEXT
);

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT,
    order_date TEXT,
    ship_date TEXT,
    ship_mode TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    row_id INTEGER PRIMARY KEY,
    order_id TEXT,
    product_id TEXT,
    location_id INTEGER,
    sales REAL,
    quantity INTEGER,
    discount REAL,
    profit REAL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (location_id) REFERENCES locations(location_id)
);


-- Next I'm going to populate the dimension-style tables.

INSERT INTO customers (customer_id, customer_name, segment)
SELECT DISTINCT "Customer ID", "Customer Name", "Segment"
FROM "Sample - Superstore";

INSERT INTO products (product_id, product_name, category, sub_category)
SELECT DISTINCT "Product ID", "Product Name", "Category", "Sub-Category"
FROM "Sample - Superstore";

-- When running that most recent query, it returned an error. I then used the following query to diagnose it:

SELECT "Product ID", COUNT(DISTINCT "Product Name") AS name_variants
FROM "Sample - Superstore"
GROUP BY "Product ID"
HAVING name_variants > 1;

-- This revealed slighly different naming conventions, so I had to adjust my next query accordingly.

INSERT INTO products (product_id, product_name, category, sub_category)
SELECT "Product ID", MIN("Product Name"), "Category", "Sub-Category"
FROM "Sample - Superstore"
GROUP BY "Product ID", "Category", "Sub-Category";

-- Next, I am creating the remaining dimension tables.

INSERT INTO locations (city, state, region, postal_code, country)
SELECT DISTINCT "City", "State", "Region", "Postal Code", "Country"
FROM "Sample - Superstore";

INSERT INTO orders (order_id, customer_id, order_date, ship_date, ship_mode)
SELECT DISTINCT "Order ID", "Customer ID", "Order Date", "Ship Date", "Ship Mode"
FROM "Sample - Superstore";

INSERT INTO order_items (row_id, order_id, product_id, location_id, sales, quantity, discount, profit)
SELECT
    s."Row ID",
    s."Order ID",
    s."Product ID",
    l.location_id,
    s."Sales",
    s."Quantity",
    s."Discount",
    s."Profit"
FROM "Sample - Superstore" s
JOIN locations l
    ON s."City" = l.city
    AND s."State" = l.state
    AND s."Postal Code" = l.postal_code;


-- My schema is now complete. I'll now execute SQL queries to analyze the data

-- Total sales and profit by category

SELECT
    p.category,
    ROUND(SUM(oi.sales), 2) AS total_sales,
    ROUND(SUM(oi.profit), 2) AS total_profit
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sales DESC;


-- Each sale along with the name and category of the product that was sold, limited to 20 results in descending order.

SELECT
    oi.row_id,
    oi.sales,
    p.product_name,
    p.category
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
ORDER BY oi.sales DESC LIMIT 20;

-- Show products with sales below the overall average.

SELECT
    oi.row_id,
    oi.sales,
    p.product_name
FROM order_items oi
LEFT JOIN products p
ON oi.product_id = p.product_id
WHERE oi.sales < (SELECT avg(sales) FROM order_items) ORDER BY oi.sales DESC LIMIT 10;


-- Find customers whose most recent order resulted in a net loss (negative profit).
-- Uses a CTE to first identify each customer's latest order, then checks its profitability.
WITH latest_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        RANK() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC) AS rnk
    FROM orders o
)
SELECT
    c.customer_name,
    lo.order_id,
    ROUND(SUM(oi.profit), 2) AS order_profit
FROM latest_orders lo
JOIN order_items oi ON lo.order_id = oi.order_id
JOIN customers c ON lo.customer_id = c.customer_id
WHERE lo.rnk = 1
GROUP BY lo.customer_id, lo.order_id
HAVING order_profit < 0
ORDER BY order_profit ASC;

