-- 顧客テーブル
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50) DEFAULT '日本'
);

-- 注文テーブル
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    order_date DATE NOT NULL,
    amount DECIMAL(12,2),
    status VARCHAR(20) DEFAULT 'pending'
);

-- サンプルデータ投入
INSERT INTO customers (name, email, city) VALUES
('田中太郎', 'tanaka@example.com', '東京'),
('鈴木花子', 'suzuki@example.com', '大阪'),
('佐藤一郎', 'sato@example.com', '名古屋'),
('山田美咲', 'yamada@example.com', '福岡'),
('渡辺健太', 'watanabe@example.com', '札幌');

-- 注文データ（各顧客に複数注文）
INSERT INTO orders (customer_id, order_date, amount, status)
SELECT
    (random() * 4 + 1)::int,
    CURRENT_DATE - (random() * 365)::int,
    (random() * 100000 + 1000)::decimal(12,2),
    CASE WHEN random() > 0.3 THEN 'completed' ELSE 'pending' END
FROM generate_series(1, 1000);
