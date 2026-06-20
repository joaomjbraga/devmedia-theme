-- SQL example - E-commerce database queries
-- Database: PostgreSQL-compatible

-- ---------- Schema ----------

CREATE SCHEMA IF NOT EXISTS ecommerce;
SET search_path TO ecommerce;

-- Enums
CREATE TYPE user_role AS ENUM ('admin', 'customer', 'seller');
CREATE TYPE order_status AS ENUM ('pending', 'paid', 'shipped', 'delivered', 'cancelled');
CREATE TYPE payment_method AS ENUM ('credit_card', 'boleto', 'pix', 'paypal');

-- Tables
CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(150) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          user_role NOT NULL DEFAULT 'customer',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS categories (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    slug        VARCHAR(120) NOT NULL UNIQUE,
    description TEXT,
    parent_id   INTEGER REFERENCES categories(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(200) NOT NULL,
    slug          VARCHAR(220) NOT NULL UNIQUE,
    description   TEXT,
    price         DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    stock         INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id   INTEGER NOT NULL REFERENCES categories(id),
    seller_id     INTEGER NOT NULL REFERENCES users(id),
    active        BOOLEAN NOT NULL DEFAULT TRUE,
    rating        DECIMAL(2, 1) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id),
    status          order_status NOT NULL DEFAULT 'pending',
    total           DECIMAL(12, 2) NOT NULL,
    payment_method  payment_method,
    shipping_address TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  INTEGER NOT NULL REFERENCES products(id),
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    unit_price  DECIMAL(10, 2) NOT NULL,
    subtotal    DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- Indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_seller ON products(seller_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE UNIQUE INDEX idx_users_lower_email ON users(LOWER(email));

-- Full-text search
ALTER TABLE products ADD COLUMN IF NOT EXISTS search_vector tsvector
    GENERATED ALWAYS AS (
        to_tsvector('portuguese', coalesce(name, '') || ' ' || coalesce(description, ''))
    ) STORED;

CREATE INDEX idx_products_search ON products USING GIN(search_vector);

-- ---------- Functions ----------

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ---------- Views ----------

CREATE OR REPLACE VIEW active_products AS
SELECT
    p.id,
    p.name,
    p.slug,
    p.price,
    p.stock,
    p.rating,
    c.name AS category,
    u.name AS seller
FROM products p
JOIN categories c ON c.id = p.category_id
JOIN users u ON u.id = p.seller_id
WHERE p.active = TRUE AND p.stock > 0;

CREATE OR REPLACE VIEW order_summary AS
SELECT
    o.id,
    o.user_id,
    u.name AS customer,
    o.status,
    o.total,
    o.payment_method,
    COUNT(oi.id) AS items_count,
    o.created_at
FROM orders o
JOIN users u ON u.id = o.user_id
LEFT JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, u.name;

-- ---------- Queries ----------

-- 1. Best selling products
SELECT
    p.id,
    p.name,
    SUM(oi.quantity) AS total_sold,
    SUM(oi.subtotal) AS revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON o.id = oi.order_id
WHERE o.status NOT IN ('cancelled', 'pending')
  AND o.created_at >= NOW() - INTERVAL '30 days'
GROUP BY p.id, p.name
ORDER BY total_sold DESC
LIMIT 10;

-- 2. Customer lifetime value
SELECT
    u.id,
    u.name,
    u.email,
    COUNT(DISTINCT o.id) AS total_orders,
    SUM(o.total) AS total_spent,
    AVG(o.total) AS avg_order_value,
    MAX(o.created_at) AS last_order
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE u.role = 'customer'
  AND o.status = 'delivered'
GROUP BY u.id, u.name, u.email
HAVING SUM(o.total) > 100
ORDER BY total_spent DESC;

-- 3. Category revenue breakdown
SELECT
    c.name AS category,
    COUNT(DISTINCT o.id) AS orders,
    SUM(oi.subtotal) AS revenue,
    AVG(oi.subtotal) AS avg_ticket
FROM categories c
JOIN products p ON p.category_id = c.id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON o.id = oi.order_id
WHERE o.status = 'delivered'
GROUP BY c.name
ORDER BY revenue DESC;

-- 4. Pending orders (CTE example)
WITH pending_orders AS (
    SELECT
        o.id,
        o.created_at,
        u.name AS customer,
        u.email,
        EXTRACT(EPOCH FROM (NOW() - o.created_at)) / 3600 AS hours_pending
    FROM orders o
    JOIN users u ON u.id = o.user_id
    WHERE o.status = 'pending'
)
SELECT *
FROM pending_orders
WHERE hours_pending > 24
ORDER BY hours_pending DESC;

-- 5. Full-text search
SELECT
    id,
    name,
    ts_rank(search_vector, query) AS rank
FROM products, plainto_tsquery('portuguese', 'notebook gaming') AS query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;

-- 6. Monthly sales (window function)
SELECT
    DATE_TRUNC('month', o.created_at)::DATE AS month,
    COUNT(*) AS orders,
    SUM(o.total) AS revenue,
    LAG(SUM(o.total)) OVER (ORDER BY DATE_TRUNC('month', o.created_at)) AS prev_month,
    ROUND(
        (SUM(o.total) - LAG(SUM(o.total)) OVER (ORDER BY DATE_TRUNC('month', o.created_at)))
        / NULLIF(LAG(SUM(o.total)) OVER (ORDER BY DATE_TRUNC('month', o.created_at)), 0) * 100,
        2
    ) AS growth_pct
FROM orders o
WHERE o.status = 'delivered'
GROUP BY month
ORDER BY month DESC;

-- 7. Inventory alert
SELECT
    p.id,
    p.name,
    p.stock,
    p.rating,
    CASE
        WHEN p.stock = 0 THEN 'Out of stock'
        WHEN p.stock <= 5 THEN 'Critical'
        WHEN p.stock <= 20 THEN 'Low'
        ELSE 'OK'
    END AS stock_level
FROM products p
WHERE p.active = TRUE
ORDER BY p.stock ASC;

-- 8. Materialized view for dashboard
CREATE MATERIALIZED VIEW IF NOT EXISTS dashboard_metrics AS
SELECT
    (SELECT COUNT(*) FROM users WHERE role = 'customer') AS total_customers,
    (SELECT COUNT(*) FROM products WHERE active = TRUE) AS active_products,
    (SELECT COUNT(*) FROM orders WHERE created_at >= NOW() - INTERVAL '7 days') AS weekly_orders,
    (SELECT COALESCE(SUM(total), 0) FROM orders WHERE status = 'delivered') AS total_revenue,
    (SELECT COALESCE(AVG(total), 0) FROM orders WHERE status = 'delivered') AS avg_ticket;

REFRESH MATERIALIZED VIEW dashboard_metrics;
