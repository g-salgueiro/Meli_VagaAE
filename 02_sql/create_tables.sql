USE `meli-ae`

/*Removendo eventuais tabelas existentes no DB. 
Por existirem FKs, desabilito FKC para evitar conflito de dependências*/

SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS DeliveryTracking;
DROP TABLE IF EXISTS Carrier;
DROP TABLE IF EXISTS FinancialTransaction;
DROP TABLE IF EXISTS PaymentMethod;
DROP TABLE IF EXISTS ItemHistory;
DROP TABLE IF EXISTS Sale;
DROP TABLE IF EXISTS Post;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS Customer;

SET FOREIGN_KEY_CHECKS=1;

/*
Criação das tabelas
*/

-- Customer: cria a tabela de clientes e vendedores (com um campo booleano para diferenciar entre eles).
CREATE TABLE Customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    customer_address TEXT,
    birth_date DATE,
    customer_phone VARCHAR(20),
    is_seller BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Category: cria a tabela de categorias e hierarquias.
CREATE TABLE Category (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(255) NOT NULL UNIQUE, -- Nome único para evitar duplicidades
    parent_id INT,
    hierarchy_path VARCHAR(512), -- Aumentado para hierarquias longas
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES Category(category_id)
);

/*
Separei 'Post' (o anúncio) de 'Product' (o item vendido), porque assim podemos rastrear 
o mesmo item sendo vendido para mais de um vendedor
*/

-- Product: armazena informações genéricas do produto. 
CREATE TABLE Product (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(255) NOT NULL,
    product_description TEXT,
    category_id INT NOT NULL,
    product_brand VARCHAR(100),
    product_model VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES Category(category_id)
);

-- Post: representa o anúncio de um vendedor específico para um produto
CREATE TABLE Post (
    post_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    seller_id INT NOT NULL,
    post_price DECIMAL(10, 2) NOT NULL CHECK (post_price > 0),
    post_status ENUM('active', 'inactive') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES Product(product_id),
    FOREIGN KEY (seller_id) REFERENCES Customer(customer_id)
);

-- Sale: registra transações ligadas ao anúncio específico (item_id)
CREATE TABLE Sale (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    buyer_id INT NOT NULL,
    post_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price > 0),
    sale_total DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    sale_date DATE DEFAULT (CURRENT_DATE),
    sale_status ENUM('pending', 'completed', 'cancelled', 'refunded') NOT NULL,
    FOREIGN KEY (buyer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (post_id) REFERENCES Post(post_id)
);

-- ItemHistory: cria tabela de histórico
CREATE TABLE ItemHistory (
    post_id INT NOT NULL,
    snapshot_date DATE NOT NULL,
    post_price DECIMAL(10, 2) NOT NULL,
    post_status ENUM('active', 'inactive') NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, snapshot_date),
    FOREIGN KEY (post_id) REFERENCES Post(post_id)
);

/*
Criação das tabelas adicionais - úteis ao Meli
*/

-- PaymentMethod: identifica os métodos de pagamento dos clientes
/*
Aqui seria possível usar outras tabelas dimensão para rastrear o status do pagamento.
Contudo, em prol do escopo, o desenvolvimento foi preterido.
*/

CREATE TABLE PaymentMethod (
    payment_method_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    payment_type ENUM('credit_card', 'debit_card', 'mercado_pago', 'bank_transfer') NOT NULL,
    payment_token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

-- FinancialTransaction: lista as transações financeiras das vendas
CREATE TABLE FinancialTransaction (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    sale_id INT NOT NULL,
    payment_method_id INT NOT NULL,
    transaction_amount DECIMAL(10, 2) NOT NULL,
    transaction_status ENUM('pending', 'completed', 'failed', 'refunded') NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES Sale(sale_id),
    FOREIGN KEY (payment_method_id) REFERENCES PaymentMethod(payment_method_id)
);

-- Carrier: armazena as transportadoras parceiras
CREATE TABLE Carrier (
    carrier_id INT PRIMARY KEY AUTO_INCREMENT,
    carrier_name VARCHAR(255) NOT NULL UNIQUE,
    service_type VARCHAR(100) NOT NULL,
    shipping_cost DECIMAL(10, 2) NOT NULL,
    estimated_delivery_days INT NOT NULL
);

-- DeliveryTracking: faz o rastreamento de entregas
/*
Aqui seria possível usar outras tabelas dimensão para rastrear o status da entrega.
Contudo, em prol do escopo, o desenvolvimento foi preterido.
*/

CREATE TABLE DeliveryTracking (
    tracking_id INT PRIMARY KEY AUTO_INCREMENT,
    sale_id INT NOT NULL,
    carrier_id INT NOT NULL,
    tracking_number VARCHAR(255) NOT NULL UNIQUE,
    delivery_status ENUM('processing', 'shipped', 'in_transit', 'delivered', 'delayed') NOT NULL,
    shipping_date DATE,
    estimated_delivery DATE,
    actual_delivery DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES Sale(sale_id),
    FOREIGN KEY (carrier_id) REFERENCES Carrier(carrier_id)
);


