DROP SCHEMA IF EXISTS marketplace CASCADE;
CREATE SCHEMA marketplace;

CREATE TABLE marketplace.users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(16) NOT NULL UNIQUE,
    registration_dttm TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_users_email CHECK (email ~ '^[A-Za-z0-9._%+]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_users_phone CHECK (phone ~ '^\+[0-9]{11,15}$')
);

CREATE TABLE marketplace.pickup_points (
    point_id INT PRIMARY KEY,
    address VARCHAR(255) NOT NULL UNIQUE,
    working_hours VARCHAR(100) NOT NULL,
);

CREATE TABLE marketplace.sellers (
   seller_id INT PRIMARY KEY,
   company_name VARCHAR(255) NOT NULL UNIQUE,
   inn VARCHAR(12) NOT NULL UNIQUE,
   rating NUMERIC(3, 2),
   CONSTRAINT chk_sellers_inn CHECK (inn ~ '^[0-9]{10}$|^[0-9]{12}$'),
   CONSTRAINT chk_sellers_rating CHECK (rating BETWEEN 0 AND 5)
);

CREATE TABLE marketplace.categories (
    category_id INT PRIMARY KEY,
    parent_category_id INT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id) REFERENCES marketplace.categories (category_id) ON DELETE SET NULL
);

CREATE TABLE marketplace.products (
    product_id INT PRIMARY KEY,
	  category_id INT NOT NULL,
	  title VARCHAR(255) NOT NULL,
	  description TEXT,
	  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES marketplace.categories (category_id) ON DELETE RESTRICT
);

CREATE TABLE marketplace.offers (
	  offer_id INT PRIMARY KEY,
	  product_id INT NOT NULL,
	  seller_id INT NOT NULL,
	  price NUMERIC(10, 2) NOT NULL,
	  stock_quantity INT NOT NULL,
    CONSTRAINT uq_offers_product_seller UNIQUE (product_id, seller_id),
    CONSTRAINT chk_offers_price CHECK (price >= 0),
    CONSTRAINT chk_offers_stock CHECK (stock_quantity >= 0), 
    CONSTRAINT fk_offers_product FOREIGN KEY (product_id) REFERENCES marketplace.products (product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_offers_seller FOREIGN KEY (seller_id) REFERENCES marketplace.sellers (seller_id) ON DELETE RESTRICT
);

CREATE TABLE marketplace.cart_items (
	  user_id INT NOT NULL,
	  offer_id INT NOT NULL,
	  quantity INT NOT NULL,
    CONSTRAINT pk_cart_items PRIMARY KEY (user_id, offer_id),
    CONSTRAINT chk_cart_items_quantity CHECK (quantity > 0),
    CONSTRAINT fk_cart_items_user FOREIGN KEY (user_id) REFERENCES marketplace.users (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_offer FOREIGN KEY (offer_id) REFERENCES marketplace.offers (offer_id) ON DELETE CASCADE
);

CREATE TABLE marketplace.orders (
	  order_id INT PRIMARY KEY,
    user_id INT NOT NULL,
	  order_dttm TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	  total_cost NUMERIC(10, 2) NOT NULL,
	  status VARCHAR(20) NOT NULL,
    CONSTRAINT chk_orders_total_cost CHECK (total_cost >= 0),
    CONSTRAINT chk_orders_status CHECK (status IN ('created', 'paid', 'assembling', 'shipped', 'delivered', 'cancelled')),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES marketplace.users (user_id) ON DELETE RESTRICT
);

CREATE TABLE marketplace.order_items (
	  order_id INT NOT NULL,
	  offer_id INT NOT NULL,
	  quantity INT NOT NULL,
	  price_at_purchase NUMERIC(10, 2) NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, offer_id),
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price CHECK (price_at_purchase >= 0),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES marketplace.orders (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_offer FOREIGN KEY (offer_id) REFERENCES marketplace.offers (offer_id) ON DELETE RESTRICT
);

CREATE TABLE marketplace.payments (
	  payment_id INT PRIMARY KEY,
	  order_id INT NOT NULL UNIQUE,
	  payment_dttm TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	  payment_method VARCHAR(20) NOT NULL,
	  status VARCHAR(20) NOT NULL,
	  CONSTRAINT chk_payments_method CHECK (payment_method IN ('card', 'sbp', 'cash')),
	  CONSTRAINT chk_payments_status CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
	  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES marketplace.orders (order_id) ON DELETE CASCADE
);

CREATE TABLE marketplace.deliveries (
	  delivery_id INT PRIMARY KEY,
	  order_id INT NOT NULL UNIQUE,
	  point_id INT NOT NULL,
	  tracking_number VARCHAR(50) UNIQUE,
	  estimated_dt DATE NOT NULL,
	  delivery_status VARCHAR(20) NOT NULL,
	  CONSTRAINT chk_deliveries_status CHECK (delivery_status IN ('preparing', 'in_transit', 'arrived', 'received', 'returned')),
	  CONSTRAINT fk_deliveries_order FOREIGN KEY (order_id) REFERENCES marketplace.orders (order_id) ON DELETE CASCADE,
	  CONSTRAINT fk_deliveries_point FOREIGN KEY (point_id) REFERENCES marketplace.pickup_points (point_id) ON DELETE RESTRICT
);

CREATE TABLE marketplace.reviews (
	  review_id INT PRIMARY KEY,
	  user_id INT NOT NULL,
	  offer_id INT NOT NULL,
	  rating INT NOT NULL,
	  comment_text TEXT,
	  created_dttm TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	  CONSTRAINT uq_reviews_user_offer UNIQUE (user_id, offer_id),
	  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
	  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES marketplace.users (user_id) ON DELETE CASCADE,
	  CONSTRAINT fk_reviews_offer FOREIGN KEY (offer_id) REFERENCES marketplace.offers (offer_id) ON DELETE CASCADE
);
