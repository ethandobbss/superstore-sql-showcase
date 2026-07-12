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
