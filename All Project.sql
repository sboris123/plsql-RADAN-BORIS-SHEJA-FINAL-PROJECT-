BEGIN
   FOR t IN (SELECT table_name FROM user_tables 
             WHERE table_name IN ('PAYMENT_TRANSACTIONS', 'CUSTOMER_FEEDBACK', 
                                  'ORDER_STATUS_HISTORY', 'INVENTORY_AUDIT', 
                                  'ORDER_ERROR_LOG', 'ORDERS', 'USER_SESSIONS', 
                                  'USER_ACCOUNTS', 'PRODUCTS', 'CUSTOMERS', 
                                  'SYSTEM_CONFIGURATION', 'AUDIT_TRAIL')) 
   LOOP
      EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
   END LOOP;
END;
/

-- Table 1: CUSTOMERS
CREATE TABLE CUSTOMERS (
    customer_id NUMBER(10) PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    address VARCHAR2(200),
    city VARCHAR2(50),
    country VARCHAR2(50) DEFAULT 'Rwanda',
    postal_code VARCHAR2(10),
    registration_date DATE DEFAULT SYSDATE NOT NULL,
    customer_status VARCHAR2(20) DEFAULT 'Active' CHECK (customer_status IN ('Active', 'Inactive', 'Suspended')),
    credit_limit NUMBER(10,2) DEFAULT 5000.00 CHECK (credit_limit >= 0),
    total_orders NUMBER(10) DEFAULT 0 CHECK (total_orders >= 0),
    CONSTRAINT chk_email_format CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'))
);


-- Table 2: PRODUCTS
CREATE TABLE PRODUCTS (
    product_id NUMBER(10) PRIMARY KEY,
    product_name VARCHAR2(100) NOT NULL,
    category VARCHAR2(50) NOT NULL,
    description VARCHAR2(500),
    unit_price NUMBER(10,2) NOT NULL CHECK (unit_price > 0),
    stock_quantity NUMBER(10) DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level NUMBER(10) DEFAULT 10 CHECK (reorder_level >= 0),
    supplier_name VARCHAR2(100),
    product_status VARCHAR2(20) DEFAULT 'Available' CHECK (product_status IN ('Available', 'Discontinued', 'Out of Stock')),
    created_date DATE DEFAULT SYSDATE NOT NULL,
    last_updated DATE DEFAULT SYSDATE
);

-- Table 3: USER_ACCOUNTS
CREATE TABLE USER_ACCOUNTS (
    user_id NUMBER(10) PRIMARY KEY,
    username VARCHAR2(50) UNIQUE NOT NULL,
    password_hash VARCHAR2(100) NOT NULL,
    full_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    role VARCHAR2(30) DEFAULT 'Sales' CHECK (role IN ('Admin', 'Sales', 'Manager', 'Warehouse', 'Customer Service')),
    account_status VARCHAR2(20) DEFAULT 'Active' CHECK (account_status IN ('Active', 'Inactive', 'Locked')),
    created_date DATE DEFAULT SYSDATE NOT NULL,
    last_login DATE,
    failed_login_attempts NUMBER(2) DEFAULT 0 CHECK (failed_login_attempts >= 0)
);

-- Table 4: ORDERS
CREATE TABLE ORDERS (
    order_id NUMBER(10) PRIMARY KEY,
    customer_id NUMBER(10) NOT NULL,
    product_id NUMBER(10) NOT NULL,
    user_id NUMBER(10),
    quantity NUMBER(10) NOT NULL CHECK (quantity > 0),
    unit_price NUMBER(10,2) NOT NULL CHECK (unit_price > 0),
    total_amount NUMBER(10,2) NOT NULL CHECK (total_amount > 0),
    order_date DATE DEFAULT SYSDATE NOT NULL,
    order_status VARCHAR2(30) DEFAULT 'Pending' CHECK (order_status IN ('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled')),
    shipping_address VARCHAR2(200),
    payment_status VARCHAR2(20) DEFAULT 'Pending' CHECK (payment_status IN ('Pending', 'Paid', 'Failed', 'Refunded')),
    notes VARCHAR2(500),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id),
    CONSTRAINT fk_orders_product FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES USER_ACCOUNTS(user_id)
);


-- Table 5: ORDER_ERROR_LOG
CREATE TABLE ORDER_ERROR_LOG (
    error_id NUMBER(10) PRIMARY KEY,
    customer_id NUMBER(10),
    product_id NUMBER(10),
    quantity NUMBER(10),
    error_message VARCHAR2(500) NOT NULL,
    error_date DATE DEFAULT SYSDATE NOT NULL,
    attempted_by NUMBER(10),
    error_type VARCHAR2(50) CHECK (error_type IN ('Invalid Customer', 'Invalid Product', 'Insufficient Stock', 'Invalid Quantity', 'Business Rule Violation', 'System Error')),
    CONSTRAINT fk_error_customer FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id) ON DELETE SET NULL,
    CONSTRAINT fk_error_product FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_error_user FOREIGN KEY (attempted_by) REFERENCES USER_ACCOUNTS(user_id) ON DELETE SET NULL
);

-- Table 6: USER_SESSIONS
CREATE TABLE USER_SESSIONS (
    session_id NUMBER(10) PRIMARY KEY,
    user_id NUMBER(10) NOT NULL,
    login_time TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    logout_time TIMESTAMP,
    ip_address VARCHAR2(45),
    session_status VARCHAR2(20) DEFAULT 'Active' CHECK (session_status IN ('Active', 'Expired', 'Terminated')),
    CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES USER_ACCOUNTS(user_id)
);

-- Table 7: ORDER_STATUS_HISTORY
CREATE TABLE ORDER_STATUS_HISTORY (
    history_id NUMBER(10) PRIMARY KEY,
    order_id NUMBER(10) NOT NULL,
    old_status VARCHAR2(30),
    new_status VARCHAR2(30) NOT NULL,
    changed_by NUMBER(10),
    change_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    remarks VARCHAR2(500),
    CONSTRAINT fk_history_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT fk_history_user FOREIGN KEY (changed_by) REFERENCES USER_ACCOUNTS(user_id) ON DELETE SET NULL
);

-- Table 8: CUSTOMER_FEEDBACK
CREATE TABLE CUSTOMER_FEEDBACK (
    feedback_id NUMBER(10) PRIMARY KEY,
    order_id NUMBER(10) NOT NULL,
    customer_id NUMBER(10) NOT NULL,
    rating NUMBER(2) CHECK (rating >= 1 AND rating <= 5),
    cust_comment VARCHAR2(1000),
    feedback_date DATE DEFAULT SYSDATE NOT NULL,
    response VARCHAR2(1000),
    responded_by NUMBER(10),
    response_date DATE,
    CONSTRAINT fk_feedback_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT fk_feedback_customer FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id),
    CONSTRAINT fk_feedback_responder FOREIGN KEY (responded_by) REFERENCES USER_ACCOUNTS(user_id) ON DELETE SET NULL
);

-- Table 9: INVENTORY_AUDIT
CREATE TABLE INVENTORY_AUDIT (
    audit_id NUMBER(10) PRIMARY KEY,
    product_id NUMBER(10) NOT NULL,
    transaction_type VARCHAR2(20) NOT NULL CHECK (transaction_type IN ('Addition', 'Deduction', 'Adjustment', 'Return', 'Damage')),
    quantity_change NUMBER(10) NOT NULL,
    old_quantity NUMBER(10) NOT NULL,
    new_quantity NUMBER(10) NOT NULL,
    audit_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    performed_by NUMBER(10),
    reason VARCHAR2(500),
    reference_order_id NUMBER(10),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id),
    CONSTRAINT fk_inventory_user FOREIGN KEY (performed_by) REFERENCES USER_ACCOUNTS(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_inventory_order FOREIGN KEY (reference_order_id) REFERENCES ORDERS(order_id) ON DELETE SET NULL
);

-- Table 10: PAYMENT_TRANSACTIONS
CREATE TABLE PAYMENT_TRANSACTIONS (
    transaction_id NUMBER(10) PRIMARY KEY,
    order_id NUMBER(10) NOT NULL,
    payment_method VARCHAR2(30) CHECK (payment_method IN ('Credit Card', 'Debit Card', 'Mobile Money', 'Bank Transfer', 'Cash', 'PayPal')),
    amount NUMBER(10,2) NOT NULL CHECK (amount > 0),
    transaction_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    transaction_status VARCHAR2(20) DEFAULT 'Pending' CHECK (transaction_status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    payment_reference VARCHAR2(100) UNIQUE,
    gateway_response VARCHAR2(500),
    processed_by NUMBER(10),
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT fk_payment_user FOREIGN KEY (processed_by) REFERENCES USER_ACCOUNTS(user_id) ON DELETE SET NULL
);

-- Table 11: SYSTEM_CONFIGURATION
CREATE TABLE SYSTEM_CONFIGURATION (
    config_id NUMBER(10) PRIMARY KEY,
    config_key VARCHAR2(100) UNIQUE NOT NULL,
    config_value VARCHAR2(500) NOT NULL,
    description VARCHAR2(500),
    data_type VARCHAR2(20) CHECK (data_type IN ('String', 'Number', 'Boolean', 'Date')),
    last_updated TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by NUMBER(10),
    CONSTRAINT fk_config_user FOREIGN KEY (updated_by) REFERENCES USER_ACCOUNTS(user_id) ON DELETE SET NULL
);

-- Table 12: AUDIT_TRAIL
CREATE TABLE AUDIT_TRAIL (
    audit_id NUMBER(10) PRIMARY KEY,
    table_name VARCHAR2(50) NOT NULL,
    operation VARCHAR2(10) CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id NUMBER(10) NOT NULL,
    old_values CLOB,
    new_values CLOB,
    performed_by NUMBER(10),
    operation_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    ip_address VARCHAR2(45),
    CONSTRAINT fk_audit_user FOREIGN KEY (performed_by) REFERENCES USER_ACCOUNTS(user_id) ON DELETE SET NULL
);



-- SECTION 3: CREATE INDEXES FOR PERFORMANCE


-- Customer Indexes
CREATE INDEX idx_customer_email ON CUSTOMERS(email);
CREATE INDEX idx_customer_status ON CUSTOMERS(customer_status);
CREATE INDEX idx_customer_country ON CUSTOMERS(country);

-- Product Indexes
CREATE INDEX idx_product_category ON PRODUCTS(category);
CREATE INDEX idx_product_status ON PRODUCTS(product_status);
CREATE INDEX idx_product_stock ON PRODUCTS(stock_quantity);

-- Order Indexes
CREATE INDEX idx_order_customer ON ORDERS(customer_id);
CREATE INDEX idx_order_product ON ORDERS(product_id);
CREATE INDEX idx_order_date ON ORDERS(order_date);
CREATE INDEX idx_order_status ON ORDERS(order_status);

-- Error Log Indexes
CREATE INDEX idx_error_date ON ORDER_ERROR_LOG(error_date);
CREATE INDEX idx_error_type ON ORDER_ERROR_LOG(error_type);

-- Session Indexes
CREATE INDEX idx_session_user ON USER_SESSIONS(user_id);
CREATE INDEX idx_session_status ON USER_SESSIONS(session_status);

-- Payment Indexes
CREATE INDEX idx_payment_order ON PAYMENT_TRANSACTIONS(order_id);
CREATE INDEX idx_payment_status ON PAYMENT_TRANSACTIONS(transaction_status);

-- ============================================================================
-- SECTION 4: CREATE SEQUENCES FOR PRIMARY KEYS
-- ============================================================================

CREATE SEQUENCE seq_customer START WITH 1001 INCREMENT BY 1;
CREATE SEQUENCE seq_product START WITH 2001 INCREMENT BY 1;
CREATE SEQUENCE seq_user START WITH 3001 INCREMENT BY 1;
CREATE SEQUENCE seq_order START WITH 4001 INCREMENT BY 1;
CREATE SEQUENCE seq_error START WITH 5001 INCREMENT BY 1;
CREATE SEQUENCE seq_session START WITH 6001 INCREMENT BY 1;
CREATE SEQUENCE seq_history START WITH 7001 INCREMENT BY 1;
CREATE SEQUENCE seq_feedback START WITH 8001 INCREMENT BY 1;
CREATE SEQUENCE seq_inventory_audit START WITH 9001 INCREMENT BY 1;
CREATE SEQUENCE seq_payment START WITH 10001 INCREMENT BY 1;
CREATE SEQUENCE seq_config START WITH 11001 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_trail START WITH 12001 INCREMENT BY 1;


-- SECTION 5: INSERT REALISTIC TEST DATA


-- Insert USER_ACCOUNTS (Must be first due to FK dependencies)
BEGIN
    -- Admins
    INSERT INTO USER_ACCOUNTS VALUES (seq_user.NEXTVAL, 'admin1', 'hash_admin1', 'John Administrator', 'john.admin@company.com', 'Admin', 'Active', SYSDATE-365, SYSDATE-1, 0);
    INSERT INTO USER_ACCOUNTS VALUES (seq_user.NEXTVAL, 'admin2', 'hash_admin2', 'Sarah Johnson', 'sarah.admin@company.com', 'Admin', 'Active', SYSDATE-300, SYSDATE-2, 0);
    
    -- Managers
    INSERT INTO USER_ACCOUNTS VALUES (seq_user.NEXTVAL, 'manager1', 'hash_mgr1', 'Michael Brown', 'michael.brown@company.com', 'Manager', 'Active', SYSDATE-250, SYSDATE-3, 0);
    INSERT INTO USER_ACCOUNTS VALUES (seq_user.NEXTVAL, 'manager2', 'hash_mgr2', 'Emily Davis', 'emily.davis@company.com', 'Manager', 'Active', SYSDATE-200, SYSDATE-5, 0);
    
    -- Sales Team
    FOR i IN 1..30 LOOP
        INSERT INTO USER_ACCOUNTS VALUES (
            seq_user.NEXTVAL, 
            'sales' || i, 
            'hash_sales' || i, 
            'Sales Person ' || i, 
            'sales' || i || '@company.com', 
            'Sales', 
            CASE WHEN MOD(i, 15) = 0 THEN 'Inactive' ELSE 'Active' END,
            SYSDATE - (365 - i*10),
            SYSDATE - MOD(i, 7),
            0
        );
    END LOOP;
    
    -- Warehouse Staff
    FOR i IN 1..20 LOOP
        INSERT INTO USER_ACCOUNTS VALUES (
            seq_user.NEXTVAL, 
            'warehouse' || i, 
            'hash_wh' || i, 
            'Warehouse Staff ' || i, 
            'warehouse' || i || '@company.com', 
            'Warehouse', 
            'Active',
            SYSDATE - (200 - i*15),
            SYSDATE - MOD(i, 5),
            0
        );
    END LOOP;
    
    -- Customer Service
    FOR i IN 1..45 LOOP
        INSERT INTO USER_ACCOUNTS VALUES (
            seq_user.NEXTVAL, 
            'cs' || i, 
            'hash_cs' || i, 
            'Customer Service ' || i, 
            'cs' || i || '@company.com', 
            'Customer Service', 
            CASE WHEN i = 10 THEN 'Locked' ELSE 'Active' END,
            SYSDATE - (180 - i*8),
            SYSDATE - MOD(i, 4),
            CASE WHEN i = 10 THEN 3 ELSE 0 END
        );
    END LOOP;
    
    COMMIT;
END;
/

-- Insert CUSTOMERS (300 customers)
DECLARE
    v_first_names SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen');
    v_last_names SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee');
    v_cities SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Kigali', 'Musanze', 'Rubavu', 'Huye', 'Nyanza', 'Rwamagana', 'Muhanga', 'Rusizi', 'Karongi', 'Nyagatare');
    v_countries SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Rwanda', 'Kenya', 'Uganda', 'Tanzania', 'Burundi');
BEGIN
    FOR i IN 1..300 LOOP
        INSERT INTO CUSTOMERS VALUES (
            seq_customer.NEXTVAL,
            v_first_names(MOD(i, 20) + 1),
            v_last_names(MOD(i, 20) + 1),
            LOWER(v_first_names(MOD(i, 20) + 1) || '.' || v_last_names(MOD(i, 20) + 1) || i || '@email.com'),
            '+25078' || LPAD(TO_CHAR(i*1234), 7, '0'),
            'Street ' || i || ', Building ' || MOD(i, 50),
            v_cities(MOD(i, 10) + 1),
            v_countries(MOD(i, 5) + 1),
            LPAD(TO_CHAR(i*100), 5, '0'),
            SYSDATE - (500 - i),
            CASE WHEN MOD(i, 25) = 0 THEN 'Suspended' WHEN MOD(i, 30) = 0 THEN 'Inactive' ELSE 'Active' END,
            CASE WHEN MOD(i, 3) = 0 THEN 10000 WHEN MOD(i, 5) = 0 THEN 20000 ELSE 5000 END,
            TRUNC(DBMS_RANDOM.VALUE(0, 50))
        );
    END LOOP;
    COMMIT;
END;
/
-- Insert PRODUCTS (150 products)
DECLARE
    v_categories SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Electronics', 'Clothing', 'Food & Beverages', 'Home & Garden', 'Sports', 'Books', 'Toys', 'Beauty', 'Automotive', 'Office Supplies');
    v_product_names SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Premium', 'Standard', 'Economy', 'Deluxe', 'Basic', 'Professional', 'Ultra', 'Mega', 'Super', 'Classic');
    v_product_id NUMBER;
BEGIN
    FOR i IN 1..150 LOOP
        v_product_id := seq_product.NEXTVAL;
        
        INSERT INTO PRODUCTS (
            product_id,
            product_name,
            category,
            description,
            unit_price,
            stock_quantity,
            reorder_level,
            supplier_name,
            product_status,
            created_date,
            last_updated
        ) VALUES (
            v_product_id,
            v_product_names(MOD(i, 10) + 1) || ' ' || v_categories(MOD(i, 10) + 1) || ' Item ' || i,
            v_categories(MOD(i, 10) + 1),
            'High quality product for ' || v_categories(MOD(i, 10) + 1) || ' category. Item code: PRD' || i,
            ROUND(DBMS_RANDOM.VALUE(10, 5000), 2),
            CASE 
                WHEN MOD(i, 15) = 0 THEN 0 
                WHEN MOD(i, 20) = 0 THEN TRUNC(DBMS_RANDOM.VALUE(1, 5))
                ELSE TRUNC(DBMS_RANDOM.VALUE(50, 1000))
            END,
            CASE WHEN MOD(i, 3) = 0 THEN 20 ELSE 10 END,
            'Supplier ' || TO_CHAR(MOD(i, 30) + 1),
            CASE 
                WHEN MOD(i, 15) = 0 THEN 'Out of Stock'
                WHEN MOD(i, 25) = 0 THEN 'Discontinued'
                ELSE 'Available'
            END,
            SYSDATE - (400 - i),
            SYSDATE - MOD(i, 30)
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully inserted 150 products');
END;
/
select * from products;
-- Insert SYSTEM_CONFIGURATION
BEGIN
    INSERT INTO SYSTEM_CONFIGURATION VALUES (seq_config.NEXTVAL, 'MIN_STOCK_THRESHOLD', '10', 'Minimum stock before reorder alert', 'Number', SYSTIMESTAMP, 3001);
    INSERT INTO SYSTEM_CONFIGURATION VALUES (seq_config.NEXTVAL, 'MAX_ORDER_QUANTITY', '1000', 'Maximum quantity per order', 'Number', SYSTIMESTAMP, 3001);
    INSERT INTO SYSTEM_CONFIGURATION VALUES (seq_config.NEXTVAL, 'TAX_RATE', '0.18', 'VAT tax rate (18%)', 'Number', SYSTIMESTAMP, 3001);
    INSERT INTO SYSTEM_CONFIGURATION VALUES (seq_config.NEXTVAL, 'CURRENCY', 'RWF', 'System currency', 'String', SYSTIMESTAMP, 3001);
    INSERT INTO SYSTEM_CONFIGURATION VALUES (seq_config.NEXTVAL, 'AUTO_APPROVE_THRESHOLD', '5000', 'Auto-approve orders below this amount', 'Number', SYSTIMESTAMP, 3001);
    INSERT INTO SYSTEM_CONFIGURATION VALUES (seq_config.NEXTVAL, 'SESSION_TIMEOUT_MINUTES', '30', 'User session timeout', 'Number', SYSTIMESTAMP, 3001);
    INSERT INTO SYSTEM_CONFIGURATION VALUES (seq_config.NEXTVAL, 'MAX_FAILED_LOGINS', '3', 'Max failed login attempts', 'Number', SYSTIMESTAMP, 3001);
    INSERT INTO SYSTEM_CONFIGURATION VALUES (seq_config.NEXTVAL, 'ENABLE_EMAIL_NOTIFICATIONS', 'true', 'Send email notifications', 'Boolean', SYSTIMESTAMP, 3001);
    COMMIT;
END;
/

-- Insert ORDERS (500 orders with various statuses)
DECLARE
    v_customer_id NUMBER;
    v_product_id NUMBER;
    v_user_id NUMBER;
    v_quantity NUMBER;
    v_unit_price NUMBER;
    v_statuses SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled');
    v_payment_statuses SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Pending', 'Paid', 'Failed', 'Refunded');
BEGIN
    FOR i IN 1..500 LOOP
        -- Random customer (from first 200)
        SELECT customer_id INTO v_customer_id FROM (SELECT customer_id FROM CUSTOMERS ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        
        -- Random product (from first 150)
        SELECT product_id, unit_price INTO v_product_id, v_unit_price FROM (SELECT product_id, unit_price FROM PRODUCTS WHERE product_status = 'Available' ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        
        -- Random user
        SELECT user_id INTO v_user_id FROM (SELECT user_id FROM USER_ACCOUNTS WHERE account_status = 'Active' ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        
        v_quantity := TRUNC(DBMS_RANDOM.VALUE(1, 20));
        
        INSERT INTO ORDERS VALUES (
            seq_order.NEXTVAL,
            v_customer_id,
            v_product_id,
            v_user_id,
            v_quantity,
            v_unit_price,
            v_quantity * v_unit_price,
            SYSDATE - (300 - TRUNC(i/2)),
            v_statuses(MOD(i, 6) + 1),
            'Shipping address for order ' || i,
            v_payment_statuses(MOD(i, 4) + 1),
            CASE WHEN MOD(i, 10) = 0 THEN 'Rush order' ELSE NULL END
        );
    END LOOP;
    COMMIT;
END;

-- Insert ORDER_ERROR_LOG (100 error records)
DECLARE
    v_error_types SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Invalid Customer', 'Invalid Product', 'Insufficient Stock', 'Invalid Quantity', 'Business Rule Violation', 'System Error');
    v_customer_id NUMBER;
    v_product_id NUMBER;
    v_user_id NUMBER;
BEGIN
    FOR i IN 1..100 LOOP
        SELECT customer_id INTO v_customer_id FROM (SELECT customer_id FROM CUSTOMERS ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        SELECT product_id INTO v_product_id FROM (SELECT product_id FROM PRODUCTS ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        SELECT user_id INTO v_user_id FROM (SELECT user_id FROM USER_ACCOUNTS ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        
        INSERT INTO ORDER_ERROR_LOG VALUES (
            seq_error.NEXTVAL,
            CASE WHEN MOD(i, 10) = 0 THEN NULL ELSE v_customer_id END,
            CASE WHEN MOD(i, 8) = 0 THEN NULL ELSE v_product_id END,
            CASE WHEN MOD(i, 5) = 0 THEN -5 ELSE TRUNC(DBMS_RANDOM.VALUE(1, 100)) END,
            'Error: ' || v_error_types(MOD(i, 6) + 1) || ' - Attempt #' || i,
            SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 200)),
            v_user_id,
            v_error_types(MOD(i, 6) + 1)
        );
    END LOOP;
    COMMIT;
END;
/

-- Insert USER_SESSIONS (300 session records)
DECLARE
    v_user_id NUMBER;
    v_login_time TIMESTAMP;
    v_logout_time TIMESTAMP;
BEGIN
    FOR i IN 1..300 LOOP
        SELECT user_id INTO v_user_id FROM (SELECT user_id FROM USER_ACCOUNTS ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        
        v_login_time := SYSTIMESTAMP - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1, 180)), 'DAY') - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(0, 24)), 'HOUR');
        v_logout_time := CASE WHEN MOD(i, 10) = 0 THEN NULL ELSE v_login_time + NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1, 480)), 'MINUTE') END;
        
        INSERT INTO USER_SESSIONS VALUES (
            seq_session.NEXTVAL,
            v_user_id,
            v_login_time,
            v_logout_time,
            '192.168.' || TRUNC(DBMS_RANDOM.VALUE(1, 255)) || '.' || TRUNC(DBMS_RANDOM.VALUE(1, 255)),
            CASE WHEN v_logout_time IS NULL THEN 'Active' WHEN MOD(i, 20) = 0 THEN 'Terminated' ELSE 'Expired' END        );
    END LOOP;
    COMMIT;
END;
/

-- Insert ORDER_STATUS_HISTORY (800 history records)
DECLARE
    v_order_id NUMBER;
    v_user_id NUMBER;
    v_statuses SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled');
BEGIN
    FOR ord IN (SELECT order_id, order_date FROM ORDERS ORDER BY order_id) LOOP
        -- Initial status
        INSERT INTO ORDER_STATUS_HISTORY VALUES (
            seq_history.NEXTVAL,
            ord.order_id,
            NULL,
            'Pending',
            (SELECT user_id FROM (SELECT user_id FROM USER_ACCOUNTS WHERE account_status = 'Active' ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1),
            ord.order_date,
            'Order created'
        );
        
        -- Random status changes (1-3 changes per order)
        FOR i IN 1..TRUNC(DBMS_RANDOM.VALUE(1, 4)) LOOP
            SELECT user_id INTO v_user_id FROM (SELECT user_id FROM USER_ACCOUNTS WHERE account_status = 'Active' ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
            
            INSERT INTO ORDER_STATUS_HISTORY VALUES (
                seq_history.NEXTVAL,
                ord.order_id,
                v_statuses(i),
                v_statuses(i + 1),
                v_user_id,
                ord.order_date + (i * 0.5),
                'Status updated to ' || v_statuses(i + 1)
            );
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- Insert CUSTOMER_FEEDBACK (200 feedback records)
DECLARE
    v_order_id NUMBER;
    v_customer_id NUMBER;
    v_user_id NUMBER;
    v_comments SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'Excellent service, very satisfied!',
        'Good product quality, fast delivery',
        'Product arrived damaged, disappointed',
        'Average experience, nothing special',
        'Outstanding customer support',
        'Delivery was delayed but product is good',
        'Not what I expected, quality issues',
        'Highly recommend this seller!',
        'Product exactly as described',
        'Poor packaging, item was damaged'
    );
BEGIN
    FOR i IN 1..200 LOOP
        SELECT order_id, customer_id INTO v_order_id, v_customer_id 
        FROM (SELECT order_id, customer_id FROM ORDERS WHERE order_status IN ('Delivered', 'Cancelled') ORDER BY DBMS_RANDOM.VALUE) 
        WHERE ROWNUM = 1;
        
        INSERT INTO CUSTOMER_FEEDBACK VALUES (
            seq_feedback.NEXTVAL,
            v_order_id,
            v_customer_id,
            TRUNC(DBMS_RANDOM.VALUE(1, 6)),
            v_comments(MOD(i, 10) + 1),
            SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 100)),
            CASE WHEN MOD(i, 3) = 0 THEN 'Thank you for your feedback. We appreciate your business!' ELSE NULL END,
            CASE WHEN MOD(i, 3) = 0 THEN (SELECT user_id FROM (SELECT user_id FROM USER_ACCOUNTS WHERE role = 'Customer Service' ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1) ELSE NULL END,
            CASE WHEN MOD(i, 3) = 0 THEN SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 50)) ELSE NULL END
        );
    END LOOP;
    COMMIT;
END;
/

-- Insert INVENTORY_AUDIT (400 audit records)
DECLARE
    v_product_id NUMBER;
    v_user_id NUMBER;
    v_order_id NUMBER;
    v_trans_types SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Addition', 'Deduction', 'Adjustment', 'Return', 'Damage');
    v_old_qty NUMBER;
    v_qty_change NUMBER;
BEGIN
    FOR i IN 1..400 LOOP
        SELECT product_id, stock_quantity INTO v_product_id, v_old_qty 
        FROM (SELECT product_id, stock_quantity FROM PRODUCTS ORDER BY DBMS_RANDOM.VALUE) 
        WHERE ROWNUM = 1;
        
        SELECT user_id INTO v_user_id 
        FROM (SELECT user_id FROM USER_ACCOUNTS WHERE role IN ('Warehouse', 'Manager') ORDER BY DBMS_RANDOM.VALUE) 
        WHERE ROWNUM = 1;
        
        v_qty_change := CASE 
            WHEN v_trans_types(MOD(i, 5) + 1) = 'Addition' THEN TRUNC(DBMS_RANDOM.VALUE(50, 200))
            WHEN v_trans_types(MOD(i, 5) + 1) = 'Deduction' THEN -TRUNC(DBMS_RANDOM.VALUE(1, 30))
            WHEN v_trans_types(MOD(i, 5) + 1) = 'Return' THEN TRUNC(DBMS_RANDOM.VALUE(1, 10))
            WHEN v_trans_types(MOD(i, 5) + 1) = 'Damage' THEN -TRUNC(DBMS_RANDOM.VALUE(1, 5))
            ELSE TRUNC(DBMS_RANDOM.VALUE(-10, 10))
        END;
        
        INSERT INTO INVENTORY_AUDIT VALUES (
            seq_inventory_audit.NEXTVAL,
            v_product_id,
            v_trans_types(MOD(i, 5) + 1),
            v_qty_change,
            v_old_qty,
            v_old_qty + v_qty_change,
            SYSTIMESTAMP - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1, 180)), 'DAY'),
            v_user_id,
            'Inventory ' || v_trans_types(MOD(i, 5) + 1) || ' - Batch ' || i,
            CASE WHEN MOD(i, 5) = 0 THEN (SELECT order_id FROM (SELECT order_id FROM ORDERS ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1) ELSE NULL END
        );
    END LOOP;
    COMMIT;
END;
/

-- Insert PAYMENT_TRANSACTIONS (450 payment records)
DECLARE
    v_order_id NUMBER;
    v_user_id NUMBER;
    v_amount NUMBER;
    v_methods SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Credit Card', 'Debit Card', 'Mobile Money', 'Bank Transfer', 'Cash', 'PayPal');
    v_statuses SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Pending', 'Completed', 'Failed', 'Refunded');
BEGIN
    FOR i IN 1..450 LOOP
        SELECT order_id, total_amount INTO v_order_id, v_amount 
        FROM (SELECT order_id, total_amount FROM ORDERS ORDER BY DBMS_RANDOM.VALUE) 
        WHERE ROWNUM = 1;
        
        SELECT user_id INTO v_user_id 
        FROM (SELECT user_id FROM USER_ACCOUNTS WHERE role IN ('Sales', 'Manager') ORDER BY DBMS_RANDOM.VALUE) 
        WHERE ROWNUM = 1;
        
        INSERT INTO PAYMENT_TRANSACTIONS VALUES (
            seq_payment.NEXTVAL,
            v_order_id,
            v_methods(MOD(i, 6) + 1),
            v_amount,
            SYSTIMESTAMP - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1, 150)), 'DAY'),
            v_statuses(MOD(i, 4) + 1),
            'REF' || LPAD(i, 8, '0') || TO_CHAR(SYSDATE, 'YYYYMMDD'),
            CASE WHEN MOD(i, 4) = 2 THEN 'Payment failed: Insufficient funds' WHEN MOD(i, 4) = 0 THEN 'Transaction successful' ELSE NULL END,
            v_user_id
        );
    END LOOP;
    COMMIT;
END;
/

-- Insert AUDIT_TRAIL (300 audit records)
DECLARE
    v_user_id NUMBER;
    v_tables SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('ORDERS', 'CUSTOMERS', 'PRODUCTS', 'USER_ACCOUNTS', 'PAYMENTS');
    v_operations SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('INSERT', 'UPDATE', 'DELETE');
BEGIN
    FOR i IN 1..300 LOOP
        SELECT user_id INTO v_user_id 
        FROM (SELECT user_id FROM USER_ACCOUNTS ORDER BY DBMS_RANDOM.VALUE) 
        WHERE ROWNUM = 1;
        
        INSERT INTO AUDIT_TRAIL VALUES (
            seq_audit_trail.NEXTVAL,
            v_tables(MOD(i, 5) + 1),
            v_operations(MOD(i, 3) + 1),
            1000 + i,
            CASE WHEN MOD(i, 3) != 0 THEN '{"old_value": "previous data"}' ELSE NULL END,
            '{"new_value": "updated data"}',
            v_user_id,
            SYSTIMESTAMP - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1, 120)), 'DAY'),
            '192.168.' || TRUNC(DBMS_RANDOM.VALUE(1, 255)) || '.' || TRUNC(DBMS_RANDOM.VALUE(1, 255))        );    END LOOP;
    COMMIT;   END;
/

-- ============================================================================
-- SECTION 6: DATA INTEGRITY VERIFICATION QUERIES
-- ============================================================================

PROMPT ===== DATA INTEGRITY VERIFICATION =====
PROMPT;

PROMPT 1. Table Row Counts:
SELECT 'CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM CUSTOMERS
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS
UNION ALL
SELECT 'USER_ACCOUNTS', COUNT(*) FROM USER_ACCOUNTS
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS
UNION ALL
SELECT 'ORDER_ERROR_LOG', COUNT(*) FROM ORDER_ERROR_LOG
UNION ALL
SELECT 'USER_SESSIONS', COUNT(*) FROM USER_SESSIONS
UNION ALL
SELECT 'ORDER_STATUS_HISTORY', COUNT(*) FROM ORDER_STATUS_HISTORY
UNION ALL
SELECT 'CUSTOMER_FEEDBACK', COUNT(*) FROM CUSTOMER_FEEDBACK
UNION ALL
SELECT 'INVENTORY_AUDIT', COUNT(*) FROM INVENTORY_AUDIT
UNION ALL
SELECT 'PAYMENT_TRANSACTIONS', COUNT(*) FROM PAYMENT_TRANSACTIONS
UNION ALL
SELECT 'SYSTEM_CONFIGURATION', COUNT(*) FROM SYSTEM_CONFIGURATION
UNION ALL
SELECT 'AUDIT_TRAIL', COUNT(*) FROM AUDIT_TRAIL;

PROMPT;
PROMPT 2. Foreign Key Integrity Check - Orders:
SELECT 
    o.order_id,
    o.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.product_id,
    p.product_name,
    o.user_id,
    u.username
FROM ORDERS o
JOIN CUSTOMERS c ON o.customer_id = c.customer_id
JOIN PRODUCTS p ON o.product_id = p.product_id
LEFT JOIN USER_ACCOUNTS u ON o.user_id = u.user_id
WHERE ROWNUM <= 10;

PROMPT;
PROMPT 3. Constraint Validation - Check Constraints:
SELECT 
    customer_id,
    first_name,
    email,
    customer_status,
    credit_limit
FROM CUSTOMERS
WHERE customer_status NOT IN ('Active', 'Inactive', 'Suspended')
   OR credit_limit < 0
     OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');


PROMPT;
PROMPT 4. Data Completeness - NOT NULL Verification:
SELECT 
    'CUSTOMERS' AS table_name,
    COUNT(CASE WHEN first_name IS NULL THEN 1 END) AS null_first_names,
    COUNT(CASE WHEN last_name IS NULL THEN 1 END) AS null_last_names,
    COUNT(CASE WHEN email IS NULL THEN 1 END) AS null_emails
FROM CUSTOMERS
UNION ALL
SELECT 
    'PRODUCTS',
    COUNT(CASE WHEN product_name IS NULL THEN 1 END),
    COUNT(CASE WHEN category IS NULL THEN 1 END),
    COUNT(CASE WHEN unit_price IS NULL THEN 1 END)
FROM PRODUCTS;

PROMPT;
PROMPT 5. Referential Integrity - Orphaned Records Check:
SELECT 'Orphaned Orders (Invalid Customer)' AS check_type, COUNT(*) AS count
FROM ORDERS o
WHERE NOT EXISTS (SELECT 1 FROM CUSTOMERS c WHERE c.customer_id = o.customer_id)
UNION ALL
SELECT 'Orphaned Orders (Invalid Product)', COUNT(*)
FROM ORDERS o
WHERE NOT EXISTS (SELECT 1 FROM PRODUCTS p WHERE p.product_id = o.product_id);






-- ============================================================================
-- SECTION 7: COMPREHENSIVE TESTING QUERIES
-- ============================================================================


PROMPT Query 1: All Active Customers
SELECT customer_id, first_name, last_name, email, city, customer_status
FROM CUSTOMERS
WHERE customer_status = 'Active'
ORDER BY registration_date DESC
FETCH FIRST 14 ROWS ONLY;

PROMPT;
PROMPT Query 2: Available Products with Stock
SELECT product_id, product_name, category, unit_price, stock_quantity, product_status
FROM PRODUCTS
WHERE product_status = 'Available' AND stock_quantity > 0
ORDER BY stock_quantity DESC
FETCH FIRST 14 ROWS ONLY;

PROMPT;
PROMPT Query 3: Recent Orders
SELECT order_id, customer_id, product_id, quantity, total_amount, order_status, order_date
FROM ORDERS
ORDER BY order_date DESC
FETCH FIRST 13 ROWS ONLY;

PROMPT;
PROMPT Query 4: Active User Sessions
SELECT s.session_id, u.username, u.role, s.login_time, s.ip_address, s.session_status
FROM USER_SESSIONS s
JOIN USER_ACCOUNTS u ON s.user_id = u.user_id
WHERE s.session_status = 'Active'
ORDER BY s.login_time DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT;
PROMPT === B. JOIN QUERIES (Multi-Table) ===
PROMPT;

PROMPT Query 5: Order Details with Customer and Product Information
SELECT 
    o.order_id,
    o.order_date,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email AS customer_email,
    c.city,
    p.product_name,
    p.category,
    o.quantity,
    o.unit_price,
    o.total_amount,
    o.order_status,
    o.payment_status
FROM ORDERS o
JOIN CUSTOMERS c ON o.customer_id = c.customer_id
JOIN PRODUCTS p ON o.product_id = p.product_id
ORDER BY o.order_date DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT;
PROMPT Query 6: Customer Feedback with Order Details
SELECT 
    f.feedback_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    p.product_name,
    f.rating,
    f.cust_comment,
    f.feedback_date,
    f.response,
    u.full_name AS responded_by
FROM CUSTOMER_FEEDBACK f
JOIN CUSTOMERS c ON f.customer_id = c.customer_id
JOIN ORDERS o ON f.order_id = o.order_id
JOIN PRODUCTS p ON o.product_id = p.product_id
LEFT JOIN USER_ACCOUNTS u ON f.responded_by = u.user_id
ORDER BY f.feedback_date DESC
FETCH FIRST 15 ROWS ONLY;

PROMPT;
PROMPT Query 7: Payment Transaction Details
SELECT 
    pt.transaction_id,
    pt.transaction_date,
    o.order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    pt.payment_method,
    pt.amount,
    pt.transaction_status,
    pt.payment_reference,
    u.full_name AS processed_by
FROM PAYMENT_TRANSACTIONS pt
JOIN ORDERS o ON pt.order_id = o.order_id
JOIN CUSTOMERS c ON o.customer_id = c.customer_id
LEFT JOIN USER_ACCOUNTS u ON pt.processed_by = u.user_id
ORDER BY pt.transaction_date DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT;
PROMPT Query 8: Inventory Changes with Product Details
SELECT 
    ia.audit_id,
    p.product_name,
    p.category,
    ia.transaction_type,
    ia.quantity_change,
    ia.old_quantity,
    ia.new_quantity,
    ia.audit_date,
    u.full_name AS performed_by,
    ia.reason
FROM INVENTORY_AUDIT ia
JOIN PRODUCTS p ON ia.product_id = p.product_id
LEFT JOIN USER_ACCOUNTS u ON ia.performed_by = u.user_id
ORDER BY ia.audit_date DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT;
PROMPT === C. AGGREGATION QUERIES (GROUP BY) ===
PROMPT;

PROMPT Query 9: Sales Summary by Product Category
SELECT 
    p.category,
    COUNT(o.order_id) AS total_orders,
    SUM(o.quantity) AS total_quantity_sold,
    SUM(o.total_amount) AS total_revenue,
    AVG(o.total_amount) AS avg_order_value,
    MIN(o.total_amount) AS min_order_value,
    MAX(o.total_amount) AS max_order_value
FROM ORDERS o
JOIN PRODUCTS p ON o.product_id = p.product_id
WHERE o.order_status != 'Cancelled'
GROUP BY p.category
ORDER BY total_revenue DESC;

PROMPT;
PROMPT Query 10: Customer Order Statistics
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.city,
    c.country,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    AVG(o.total_amount) AS avg_order_value,
    MAX(o.order_date) AS last_order_date
FROM CUSTOMERS c
LEFT JOIN ORDERS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.country
HAVING COUNT(o.order_id) > 0
ORDER BY total_spent DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT;
PROMPT Query 11: Order Status Distribution
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    SUM(total_amount) AS total_amount,
    AVG(total_amount) AS avg_amount
FROM ORDERS
GROUP BY order_status
ORDER BY order_count DESC;

PROMPT;
PROMPT Query 12: Monthly Sales Trends
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    COUNT(order_id) AS total_orders,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM ORDERS
WHERE order_status NOT IN ('Cancelled')
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT;
PROMPT Query 13: User Performance by Role
SELECT 
    u.role,
    COUNT(DISTINCT u.user_id) AS user_count,
    COUNT(o.order_id) AS orders_processed,
    SUM(o.total_amount) AS total_revenue_processed,
    AVG(o.total_amount) AS avg_order_value
FROM USER_ACCOUNTS u
LEFT JOIN ORDERS o ON u.user_id = o.user_id
WHERE u.account_status = 'Active'
GROUP BY u.role
ORDER BY orders_processed DESC;

PROMPT;
PROMPT Query 14: Error Analysis by Type
SELECT 
    error_type,
    COUNT(*) AS error_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    MIN(error_date) AS first_occurrence,
    MAX(error_date) AS last_occurrence
FROM ORDER_ERROR_LOG
GROUP BY error_type
ORDER BY error_count DESC;

PROMPT;
PROMPT Query 15: Product Performance Analysis
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.stock_quantity,
    COUNT(o.order_id) AS times_ordered,
    SUM(o.quantity) AS total_quantity_sold,
    SUM(o.total_amount) AS total_revenue,
    AVG(f.rating) AS avg_rating,
    COUNT(f.feedback_id) AS feedback_count
FROM PRODUCTS p
LEFT JOIN ORDERS o ON p.product_id = o.product_id AND o.order_status != 'Cancelled'
LEFT JOIN CUSTOMER_FEEDBACK f ON o.order_id = f.order_id
GROUP BY p.product_id, p.product_name, p.category, p.stock_quantity
HAVING COUNT(o.order_id) > 0
ORDER BY total_revenue DESC
FETCH FIRST 20 ROWS ONLY;



PROMPT Query 16: Customers with Above Average Spending
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.city,
    total_spent
FROM CUSTOMERS c
JOIN (
    SELECT customer_id, SUM(total_amount) AS total_spent
    FROM ORDERS
    WHERE order_status != 'Cancelled'
    GROUP BY customer_id
) order_totals ON c.customer_id = order_totals.customer_id
WHERE total_spent > (
    SELECT AVG(total_spent)
    FROM (
        SELECT SUM(total_amount) AS total_spent
        FROM ORDERS
        WHERE order_status != 'Cancelled'
        GROUP BY customer_id
    )
)
ORDER BY total_spent DESC
FETCH FIRST 15 ROWS ONLY;

PROMPT;
PROMPT Query 17: Products Below Reorder Level
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.stock_quantity,
    p.reorder_level,
    p.supplier_name,
    (SELECT COUNT(*) FROM ORDERS o WHERE o.product_id = p.product_id AND o.order_status = 'Pending') AS pending_orders
FROM PRODUCTS p
WHERE p.stock_quantity < p.reorder_level
  AND p.product_status = 'Available'
ORDER BY (p.reorder_level - p.stock_quantity) DESC;

PROMPT;
PROMPT Query 18: Top 10 Products by Revenue
SELECT 
    product_id,
    product_name,
    category,
    total_revenue,
    order_count
FROM (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        SUM(o.total_amount) AS total_revenue,
        COUNT(o.order_id) AS order_count,
        RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS revenue_rank
    FROM PRODUCTS p
    JOIN ORDERS o ON p.product_id = o.product_id
    WHERE o.order_status != 'Cancelled'
    GROUP BY p.product_id, p.product_name, p.category
)
WHERE revenue_rank <= 10
ORDER BY revenue_rank;

PROMPT;
PROMPT Query 19: Customers Without Recent Orders
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.customer_status,
    c.registration_date,
    (SELECT MAX(order_date) FROM ORDERS WHERE customer_id = c.customer_id) AS last_order_date,
    TRUNC(SYSDATE - (SELECT MAX(order_date) FROM ORDERS WHERE customer_id = c.customer_id)) AS days_since_last_order
FROM CUSTOMERS c
WHERE c.customer_status = 'Active'
  AND EXISTS (SELECT 1 FROM ORDERS WHERE customer_id = c.customer_id)
  AND (SELECT MAX(order_date) FROM ORDERS WHERE customer_id = c.customer_id) < SYSDATE - 90
ORDER BY days_since_last_order DESC
FETCH FIRST 15 ROWS ONLY;

PROMPT;
PROMPT Query 20: Order Value Comparison to Category Average
SELECT 
    o.order_id,
    o.order_date,
    p.product_name,
    p.category,
    o.total_amount AS order_value,
    ROUND(AVG(o2.total_amount) OVER (PARTITION BY p.category), 2) AS category_avg_value,
    ROUND(o.total_amount - AVG(o2.total_amount) OVER (PARTITION BY p.category), 2) AS difference_from_avg,
    CASE 
        WHEN o.total_amount > AVG(o2.total_amount) OVER (PARTITION BY p.category) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance
FROM ORDERS o
JOIN PRODUCTS p ON o.product_id = p.product_id
JOIN ORDERS o2 ON o2.product_id IN (SELECT product_id FROM PRODUCTS WHERE category = p.category)
WHERE o.order_status != 'Cancelled'
ORDER BY o.order_date DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT;
PROMPT ===== DATABASE SETUP AND TESTING COMPLETE =====
PROMPT;
PROMPT Summary:
PROMPT - All 12 tables created with proper constraints
PROMPT - Primary keys, foreign keys, and check constraints enforced
PROMPT - Indexes created for performance optimization
PROMPT - 2500+ realistic test records inserted across all tables
PROMPT - 20 comprehensive test queries executed
PROMPT - Data integrity verified
PROMPT;
SET SERVEROUTPUT ON;
-- Create custom exceptions for business logic
CREATE OR REPLACE PACKAGE custom_exceptions AS
    -- Custom exception declarations
    invalid_customer_exception EXCEPTION;
    invalid_product_exception EXCEPTION;
    insufficient_stock_exception EXCEPTION;
    invalid_quantity_exception EXCEPTION;
    suspended_customer_exception EXCEPTION;
    inactive_user_exception EXCEPTION;
    payment_failed_exception EXCEPTION;
    
    -- Exception codes (for PRAGMA EXCEPTION_INIT if needed)
    PRAGMA EXCEPTION_INIT(invalid_customer_exception, -20001);
    PRAGMA EXCEPTION_INIT(invalid_product_exception, -20002);
    PRAGMA EXCEPTION_INIT(insufficient_stock_exception, -20003);
    PRAGMA EXCEPTION_INIT(invalid_quantity_exception, -20004);
    PRAGMA EXCEPTION_INIT(suspended_customer_exception, -20005);
END custom_exceptions;
/

-- Function 1: Validate Customer Status
-- Returns: TRUE if customer is valid and active, FALSE otherwise
CREATE OR REPLACE FUNCTION fn_validate_customer(
    p_customer_id IN NUMBER
) RETURN BOOLEAN
IS
    v_customer_status VARCHAR2(20);
    v_count NUMBER;
BEGIN
    -- Check if customer exists
    SELECT COUNT(*) INTO v_count
    FROM CUSTOMERS
    WHERE customer_id = p_customer_id;
    
    IF v_count = 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Check customer status
    SELECT customer_status INTO v_customer_status
    FROM CUSTOMERS
    WHERE customer_id = p_customer_id;
    
    -- Only active customers can place orders
    IF v_customer_status = 'Active' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in fn_validate_customer: ' || SQLERRM);
        RETURN FALSE;
END fn_validate_customer;
/


-- Function 2: Check Product Availability
-- Returns: Available stock quantity, -1 if product doesn't exist or is unavailable
CREATE OR REPLACE FUNCTION fn_check_product_stock(
    p_product_id IN NUMBER
) RETURN NUMBER
IS
    v_stock_quantity NUMBER;
    v_product_status VARCHAR2(20);
BEGIN
    -- Get product stock and status
    SELECT stock_quantity, product_status 
    INTO v_stock_quantity, v_product_status
    FROM PRODUCTS
    WHERE product_id = p_product_id;
    
    -- Check if product is available
    IF v_product_status != 'Available' THEN
        RETURN -1;
    END IF;
    
    RETURN v_stock_quantity;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in fn_check_product_stock: ' || SQLERRM);
        RETURN -1;
END fn_check_product_stock;
/


-- Function 3: Calculate Order Total with Tax
-- Returns: Total amount including tax
CREATE OR REPLACE FUNCTION fn_calculate_order_total(
    p_unit_price IN NUMBER,
    p_quantity IN NUMBER,
    p_include_tax IN BOOLEAN DEFAULT TRUE
) RETURN NUMBER
IS
    v_subtotal NUMBER;
    v_tax_rate NUMBER;
    v_total NUMBER;
BEGIN
    -- Validate inputs
    IF p_unit_price <= 0 OR p_quantity <= 0 THEN
        RETURN 0;
    END IF;
    
    -- Calculate subtotal
    v_subtotal := p_unit_price * p_quantity;
    
    -- Get tax rate from configuration
    IF p_include_tax THEN
        BEGIN
            SELECT TO_NUMBER(config_value) INTO v_tax_rate
            FROM SYSTEM_CONFIGURATION
            WHERE config_key = 'TAX_RATE';
            
            v_total := v_subtotal + (v_subtotal * v_tax_rate);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Default tax rate if not configured
                v_total := v_subtotal + (v_subtotal * 0.18);
        END;
    ELSE
        v_total := v_subtotal;
    END IF;
    
    RETURN ROUND(v_total, 2);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in fn_calculate_order_total: ' || SQLERRM);
        RETURN 0;
END fn_calculate_order_total;
/


-- Function 4: Get Customer Credit Limit
-- Returns: Available credit limit for customer
CREATE OR REPLACE FUNCTION fn_get_customer_credit_limit(
    p_customer_id IN NUMBER
) RETURN NUMBER
IS
    v_credit_limit NUMBER;
    v_total_pending NUMBER := 0;
    v_available_credit NUMBER;
BEGIN
    -- Get customer's credit limit
    SELECT credit_limit INTO v_credit_limit
    FROM CUSTOMERS
    WHERE customer_id = p_customer_id;
    
    -- Calculate total pending orders
    BEGIN
        SELECT NVL(SUM(total_amount), 0) INTO v_total_pending
        FROM ORDERS
        WHERE customer_id = p_customer_id
          AND order_status IN ('Pending', 'Confirmed')
          AND payment_status = 'Pending';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_total_pending := 0;
    END;
    
    -- Calculate available credit
    v_available_credit := v_credit_limit - v_total_pending;
    
    RETURN v_available_credit;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in fn_get_customer_credit_limit: ' || SQLERRM);
        RETURN 0;
END fn_get_customer_credit_limit;
/

-- Function 5: Validate Order Quantity
-- Returns: TRUE if quantity is valid, FALSE otherwise
CREATE OR REPLACE FUNCTION fn_validate_quantity(
    p_quantity IN NUMBER,
    p_available_stock IN NUMBER
) RETURN BOOLEAN
IS
    v_max_order_qty NUMBER;
BEGIN
    -- Check if quantity is positive
    IF p_quantity <= 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Check if sufficient stock available
    IF p_quantity > p_available_stock THEN
        RETURN FALSE;
    END IF;
    
    -- Check against maximum order quantity configuration
    BEGIN
        SELECT TO_NUMBER(config_value) INTO v_max_order_qty
        FROM SYSTEM_CONFIGURATION
        WHERE config_key = 'MAX_ORDER_QUANTITY';
        
        IF p_quantity > v_max_order_qty THEN
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- No max limit configured, only check stock
            NULL;
    END;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in fn_validate_quantity: ' || SQLERRM);
        RETURN FALSE;
END fn_validate_quantity;
/

-- Procedure 1: Place New Order with Full Validation
CREATE OR REPLACE PROCEDURE sp_place_order(
    p_customer_id IN NUMBER,
    p_product_id IN NUMBER,
    p_quantity IN NUMBER,
    p_user_id IN NUMBER,
    p_order_id OUT NUMBER,
    p_status OUT VARCHAR2,
    p_message OUT VARCHAR2
)
IS
    v_stock_quantity NUMBER;
    v_unit_price NUMBER;
    v_total_amount NUMBER;
    v_customer_valid BOOLEAN;
    v_quantity_valid BOOLEAN;
    v_available_credit NUMBER;
    v_product_status VARCHAR2(20);
BEGIN
    -- Initialize output parameters
    p_order_id := NULL;
    p_status := 'FAILED';
    p_message := '';
    
    -- Step 1: Validate customer
    v_customer_valid := fn_validate_customer(p_customer_id);
    
    IF NOT v_customer_valid THEN
        p_message := 'Invalid or inactive customer';
        
        -- Log error
        INSERT INTO ORDER_ERROR_LOG(error_id, customer_id, product_id, quantity, 
                                     error_message, error_date, attempted_by, error_type)
        VALUES(seq_error.NEXTVAL, p_customer_id, p_product_id, p_quantity,
               p_message, SYSDATE, p_user_id, 'Invalid Customer');
        COMMIT;
        RETURN;
    END IF;
    
    -- Step 2: Check product availability
    v_stock_quantity := fn_check_product_stock(p_product_id);
    
    IF v_stock_quantity < 0 THEN
        p_message := 'Product not available or does not exist';
        
        INSERT INTO ORDER_ERROR_LOG(error_id, customer_id, product_id, quantity,
                                     error_message, error_date, attempted_by, error_type)
        VALUES(seq_error.NEXTVAL, p_customer_id, p_product_id, p_quantity,
               p_message, SYSDATE, p_user_id, 'Invalid Product');
        COMMIT;
        RETURN;
    END IF;
    
    -- Step 3: Validate quantity
    v_quantity_valid := fn_validate_quantity(p_quantity, v_stock_quantity);
    
    IF NOT v_quantity_valid THEN
        p_message := 'Invalid quantity or insufficient stock. Available: ' || v_stock_quantity;
        
        INSERT INTO ORDER_ERROR_LOG(error_id, customer_id, product_id, quantity,
                                     error_message, error_date, attempted_by, error_type)
        VALUES(seq_error.NEXTVAL, p_customer_id, p_product_id, p_quantity,
               p_message, SYSDATE, p_user_id, 'Insufficient Stock');
        COMMIT;
        RETURN;
    END IF;
    
    -- Step 4: Get product price
    SELECT unit_price INTO v_unit_price
    FROM PRODUCTS
    WHERE product_id = p_product_id;
    
    -- Step 5: Calculate total amount
    v_total_amount := fn_calculate_order_total(v_unit_price, p_quantity, TRUE);
    
    -- Step 6: Check customer credit limit
    v_available_credit := fn_get_customer_credit_limit(p_customer_id);
    
    IF v_total_amount > v_available_credit THEN
        p_message := 'Order exceeds available credit limit. Available: ' || v_available_credit;
        
        INSERT INTO ORDER_ERROR_LOG(error_id, customer_id, product_id, quantity,
                                     error_message, error_date, attempted_by, error_type)
        VALUES(seq_error.NEXTVAL, p_customer_id, p_product_id, p_quantity,
               p_message, SYSDATE, p_user_id, 'Business Rule Violation');
        COMMIT;
        RETURN;
    END IF;
    
    -- Step 7: Create the order
    INSERT INTO ORDERS(order_id, customer_id, product_id, user_id, quantity,
                      unit_price, total_amount, order_date, order_status, payment_status)
    VALUES(seq_order.NEXTVAL, p_customer_id, p_product_id, p_user_id, p_quantity,
           v_unit_price, v_total_amount, SYSDATE, 'Pending', 'Pending')
    RETURNING order_id INTO p_order_id;
    
    -- Step 8: Update product stock
    UPDATE PRODUCTS
    SET stock_quantity = stock_quantity - p_quantity,
        last_updated = SYSDATE
    WHERE product_id = p_product_id;
    
    -- Step 9: Log inventory change
    INSERT INTO INVENTORY_AUDIT(audit_id, product_id, transaction_type, quantity_change,
                                old_quantity, new_quantity, audit_date, performed_by,
                                reason, reference_order_id)
    VALUES(seq_inventory_audit.NEXTVAL, p_product_id, 'Deduction', -p_quantity,
           v_stock_quantity, v_stock_quantity - p_quantity, SYSTIMESTAMP, p_user_id,
           'Order placed', p_order_id);
    
    -- Step 10: Create status history
    INSERT INTO ORDER_STATUS_HISTORY(history_id, order_id, old_status, new_status,
                                     changed_by, change_date, remarks)
    VALUES(seq_history.NEXTVAL, p_order_id, NULL, 'Pending',
           p_user_id, SYSTIMESTAMP, 'Order created successfully');
    
    -- Step 11: Update customer total orders
    UPDATE CUSTOMERS
    SET total_orders = total_orders + 1
    WHERE customer_id = p_customer_id;
    
    COMMIT;
    
    p_status := 'SUCCESS';
    p_message := 'Order placed successfully. Order ID: ' || p_order_id;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_status := 'ERROR';
        p_message := 'System error: ' || SQLERRM;
        
        -- Log system error
        INSERT INTO ORDER_ERROR_LOG(error_id, customer_id, product_id, quantity,
                                     error_message, error_date, attempted_by, error_type)
        VALUES(seq_error.NEXTVAL, p_customer_id, p_product_id, p_quantity,
               p_message, SYSDATE, p_user_id, 'System Error');
        COMMIT;
END sp_place_order;
/
-- Procedure 2: Update Order Status
CREATE OR REPLACE PROCEDURE sp_update_order_status(
    p_order_id IN NUMBER,
    p_new_status IN VARCHAR2,
    p_user_id IN NUMBER,
    p_remarks IN VARCHAR2 DEFAULT NULL,
    p_status OUT VARCHAR2,
    p_message OUT VARCHAR2
)
IS
    v_old_status VARCHAR2(30);
    v_product_id NUMBER;
    v_quantity NUMBER;
    v_current_stock NUMBER;
BEGIN
    -- Get current order status
    BEGIN
        SELECT order_status, product_id, quantity 
        INTO v_old_status, v_product_id, v_quantity
        FROM ORDERS
        WHERE order_id = p_order_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_status := 'FAILED';
            p_message := 'Order not found';
            RETURN;
    END;
    
    -- Validate status transition
    IF v_old_status = p_new_status THEN
        p_status := 'FAILED';
        p_message := 'Order already has status: ' || p_new_status;
        RETURN;
    END IF;
    
    -- Update order status
    UPDATE ORDERS
    SET order_status = p_new_status
    WHERE order_id = p_order_id;
    
    -- If order is cancelled, restore stock
    IF p_new_status = 'Cancelled' AND v_old_status != 'Cancelled' THEN
        SELECT stock_quantity INTO v_current_stock
        FROM PRODUCTS
        WHERE product_id = v_product_id;
        
        UPDATE PRODUCTS
        SET stock_quantity = stock_quantity + v_quantity,
            last_updated = SYSDATE
        WHERE product_id = v_product_id;
        
        -- Log inventory restoration
        INSERT INTO INVENTORY_AUDIT(audit_id, product_id, transaction_type, quantity_change,
                                    old_quantity, new_quantity, audit_date, performed_by,
                                    reason, reference_order_id)
        VALUES(seq_inventory_audit.NEXTVAL, v_product_id, 'Return', v_quantity,
               v_current_stock, v_current_stock + v_quantity, SYSTIMESTAMP, p_user_id,
               'Order cancelled - stock restored', p_order_id);
    END IF;
    
    -- Log status change
    INSERT INTO ORDER_STATUS_HISTORY(history_id, order_id, old_status, new_status,
                                     changed_by, change_date, remarks)
    VALUES(seq_history.NEXTVAL, p_order_id, v_old_status, p_new_status,
           p_user_id, SYSTIMESTAMP, p_remarks);
    
    -- Log audit trail
    INSERT INTO AUDIT_TRAIL(audit_id, table_name, operation, record_id, old_values,
                           new_values, performed_by, operation_date)
    VALUES(seq_audit_trail.NEXTVAL, 'ORDERS', 'UPDATE', p_order_id,
           '{"status":"' || v_old_status || '"}',
           '{"status":"' || p_new_status || '"}',
           p_user_id, SYSTIMESTAMP);
    
    COMMIT;
    
    p_status := 'SUCCESS';
    p_message := 'Order status updated from ' || v_old_status || ' to ' || p_new_status;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_status := 'ERROR';
        p_message := 'Error updating order status: ' || SQLERRM;
END sp_update_order_status;
/


-- Procedure 3: Process Payment Transaction
CREATE OR REPLACE PROCEDURE sp_process_payment(
    p_order_id IN NUMBER,
    p_payment_method IN VARCHAR2,
    p_amount IN NUMBER,
    p_user_id IN NUMBER,
    p_transaction_id OUT NUMBER,
    p_status OUT VARCHAR2,
    p_message OUT VARCHAR2
)
IS
    v_order_total NUMBER;
    v_order_status VARCHAR2(30);
    v_payment_reference VARCHAR2(100);
BEGIN
    -- Validate order exists
    BEGIN
        SELECT total_amount, order_status INTO v_order_total, v_order_status
        FROM ORDERS
        WHERE order_id = p_order_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_status := 'FAILED';
            p_message := 'Order not found';
            RETURN;
    END;
    
    -- Validate amount matches order total
    IF p_amount != v_order_total THEN
        p_status := 'FAILED';
        p_message := 'Payment amount does not match order total';
        RETURN;
    END IF;
    
    -- Generate payment reference
    v_payment_reference := 'PAY' || TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(seq_payment.NEXTVAL, 8, '0');
    
    -- Create payment transaction
    INSERT INTO PAYMENT_TRANSACTIONS(transaction_id, order_id, payment_method, amount,
                                     transaction_date, transaction_status, payment_reference,
                                     gateway_response, processed_by)
    VALUES(seq_payment.NEXTVAL, p_order_id, p_payment_method, p_amount,
           SYSTIMESTAMP, 'Completed', v_payment_reference,
           'Payment processed successfully', p_user_id)
    RETURNING transaction_id INTO p_transaction_id;
    
    -- Update order payment status
    UPDATE ORDERS
    SET payment_status = 'Paid'
    WHERE order_id = p_order_id;
    
    -- If order is pending, move to confirmed
    IF v_order_status = 'Pending' THEN
        UPDATE ORDERS
        SET order_status = 'Confirmed'
        WHERE order_id = p_order_id;
        
        INSERT INTO ORDER_STATUS_HISTORY(history_id, order_id, old_status, new_status,
                                         changed_by, change_date, remarks)
        VALUES(seq_history.NEXTVAL, p_order_id, 'Pending', 'Confirmed',
               p_user_id, SYSTIMESTAMP, 'Payment received - order confirmed');
    END IF;
    
    COMMIT;
    
    p_status := 'SUCCESS';
    p_message := 'Payment processed. Reference: ' || v_payment_reference;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_status := 'ERROR';
        p_message := 'Payment processing error: ' || SQLERRM;
        
        -- Log failed payment
        INSERT INTO PAYMENT_TRANSACTIONS(transaction_id, order_id, payment_method, amount,
                                         transaction_date, transaction_status, payment_reference,
                                         gateway_response, processed_by)
        VALUES(seq_payment.NEXTVAL, p_order_id, p_payment_method, p_amount,
               SYSTIMESTAMP, 'Failed', 'FAIL' || seq_payment.CURRVAL,
               p_message, p_user_id);
        COMMIT;
END sp_process_payment;
/


-- Procedure 4: Add Customer Feedback
CREATE OR REPLACE PROCEDURE sp_add_customer_feedback(
    p_order_id IN NUMBER,
    p_customer_id IN NUMBER,
    p_rating IN NUMBER,
    p_comment IN VARCHAR2,
    p_feedback_id OUT NUMBER,
    p_status OUT VARCHAR2,
    p_message OUT VARCHAR2
)
IS
    v_order_customer_id NUMBER;
    v_order_status VARCHAR2(30);
BEGIN
    -- Validate order belongs to customer
    BEGIN
        SELECT customer_id, order_status INTO v_order_customer_id, v_order_status
        FROM ORDERS
        WHERE order_id = p_order_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_status := 'FAILED';
            p_message := 'Order not found';
            RETURN;
    END;
    
    IF v_order_customer_id != p_customer_id THEN
        p_status := 'FAILED';
        p_message := 'Order does not belong to this customer';
        RETURN;
    END IF;
    
    -- Check if order is delivered or cancelled
    IF v_order_status NOT IN ('Delivered', 'Cancelled') THEN
        p_status := 'FAILED';
        p_message := 'Feedback can only be given for delivered or cancelled orders';
        RETURN;
    END IF;
    
    -- Validate rating
    IF p_rating < 1 OR p_rating > 5 THEN
        p_status := 'FAILED';
        p_message := 'Rating must be between 1 and 5';
        RETURN;
    END IF;
    
    -- Insert feedback
    INSERT INTO CUSTOMER_FEEDBACK(feedback_id, order_id, customer_id, rating,
                                  cust_comment, feedback_date)
    VALUES(seq_feedback.NEXTVAL, p_order_id, p_customer_id, p_rating,
           p_comment, SYSDATE)
    RETURNING feedback_id INTO p_feedback_id;
    
    COMMIT;
    
    p_status := 'SUCCESS';
    p_message := 'Feedback submitted successfully';
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_status := 'ERROR';
        p_message := 'Error submitting feedback: ' || SQLERRM;
END sp_add_customer_feedback;
/


-- Procedure 5: Restock Product (Bulk Operation with Cursor)
CREATE OR REPLACE PROCEDURE sp_restock_products(
    p_user_id IN NUMBER,
    p_restock_quantity IN NUMBER DEFAULT 100,
    p_products_restocked OUT NUMBER,
    p_status OUT VARCHAR2,
    p_message OUT VARCHAR2
)
IS
    -- Cursor to find products below reorder level
    CURSOR c_low_stock IS
        SELECT product_id, product_name, stock_quantity, reorder_level
        FROM PRODUCTS
        WHERE stock_quantity < reorder_level
          AND product_status = 'Available'
        FOR UPDATE;
    
    v_old_stock NUMBER;
    v_new_stock NUMBER;
    v_count NUMBER := 0;
BEGIN
    -- Process each low stock product
    FOR product_rec IN c_low_stock LOOP
        v_old_stock := product_rec.stock_quantity;
        v_new_stock := v_old_stock + p_restock_quantity;
        
        -- Update stock
        UPDATE PRODUCTS
        SET stock_quantity = v_new_stock,
            last_updated = SYSDATE
        WHERE CURRENT OF c_low_stock;
        
        -- Log inventory audit
        INSERT INTO INVENTORY_AUDIT(audit_id, product_id, transaction_type, quantity_change,
                                    old_quantity, new_quantity, audit_date, performed_by, reason)
        VALUES(seq_inventory_audit.NEXTVAL, product_rec.product_id, 'Addition', p_restock_quantity,
               v_old_stock, v_new_stock, SYSTIMESTAMP, p_user_id,
               'Automatic restock - below reorder level');
        
        v_count := v_count + 1;
    END LOOP;
    
    COMMIT;
    
    p_products_restocked := v_count;
    p_status := 'SUCCESS';
    p_message := v_count || ' product(s) restocked successfully';
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_status := 'ERROR';
        p_message := 'Error restocking products: ' || SQLERRM;
        p_products_restocked := 0;
END sp_restock_products;
/




CREATE OR REPLACE PACKAGE pkg_order_management AS
    -- Type declaration (assumed RECORD for get_order_details; adjust if OBJECT)
    TYPE t_order_summary IS RECORD (
        order_id ORDERS.order_id%TYPE,
        order_date ORDERS.order_date%TYPE,
        customer_name VARCHAR2(100),  -- Concatenated first + last name
        product_name PRODUCTS.product_name%TYPE,
        quantity ORDERS.quantity%TYPE,
        total_amount ORDERS.total_amount%TYPE,
        order_status ORDERS.order_status%TYPE
    );

    -- Procedure to validate and place order
    PROCEDURE validate_and_place_order(
        p_customer_id IN NUMBER,
        p_product_id IN NUMBER,
        p_quantity IN NUMBER,
        p_user_id IN NUMBER,
        p_order_id OUT NUMBER,
        p_status OUT VARCHAR2,
        p_message OUT VARCHAR2
    );

    -- Procedure to cancel order
    PROCEDURE cancel_order(
        p_order_id IN NUMBER,
        p_user_id IN NUMBER,
        p_reason IN VARCHAR2,
        p_status OUT VARCHAR2,
        p_message OUT VARCHAR2
    );

    -- Procedure to generate sales report
    PROCEDURE generate_sales_report(
        p_start_date IN DATE,
        p_end_date IN DATE,
        p_user_id IN NUMBER
    );

    -- Function to get customer order count
    FUNCTION get_customer_order_count(
        p_customer_id IN NUMBER
    ) RETURN NUMBER;

    -- Function to get product revenue
    FUNCTION get_product_revenue(
        p_product_id IN NUMBER,
        p_start_date IN DATE DEFAULT NULL,
        p_end_date IN DATE DEFAULT NULL
    ) RETURN NUMBER;

    -- Function to get order details
    FUNCTION get_order_details(
        p_order_id IN NUMBER
    ) RETURN t_order_summary;

END pkg_order_management;
/

CREATE OR REPLACE PACKAGE BODY pkg_order_management AS

    -- Private procedure: Log package activity
    PROCEDURE log_activity(
        p_activity VARCHAR2,
        p_user_id NUMBER,
        p_details VARCHAR2 DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO AUDIT_TRAIL(audit_id, table_name, operation, record_id,
                               new_values, performed_by, operation_date)
        VALUES(seq_audit_trail.NEXTVAL, 'PACKAGE_ACTIVITY', 'INFO', p_user_id,
               p_activity || ': ' || p_details, p_user_id, SYSTIMESTAMP);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Silent fail for logging
    END log_activity;

    -- Public procedure implementation
    PROCEDURE validate_and_place_order(
        p_customer_id IN NUMBER,
        p_product_id IN NUMBER,
        p_quantity IN NUMBER,
        p_user_id IN NUMBER,
        p_order_id OUT NUMBER,
        p_status OUT VARCHAR2,
        p_message OUT VARCHAR2
    ) IS
    BEGIN
        log_activity('ORDER_PLACEMENT_ATTEMPT', p_user_id, 
                    'Customer: ' || p_customer_id || ', Product: ' || p_product_id);
        
        -- Call the standalone procedure
        sp_place_order(p_customer_id, p_product_id, p_quantity, p_user_id,
                      p_order_id, p_status, p_message);
        
        log_activity('ORDER_PLACEMENT_RESULT', p_user_id, 
                    'Status: ' || p_status || ', Order ID: ' || p_order_id);
    END validate_and_place_order;
    
    PROCEDURE cancel_order(
        p_order_id IN NUMBER,
        p_user_id IN NUMBER,
        p_reason IN VARCHAR2,
        p_status OUT VARCHAR2,
        p_message OUT VARCHAR2
    ) IS
    BEGIN
        log_activity('ORDER_CANCELLATION_ATTEMPT', p_user_id, 'Order: ' || p_order_id);
        
        sp_update_order_status(p_order_id, 'Cancelled', p_user_id, 
                              p_reason, p_status, p_message);
        
        log_activity('ORDER_CANCELLATION_RESULT', p_user_id, 'Status: ' || p_status);
    END cancel_order;
    
    PROCEDURE generate_sales_report(
        p_start_date IN DATE,
        p_end_date IN DATE,
        p_user_id IN NUMBER
    ) IS
        CURSOR c_sales IS
            SELECT 
                p.category,
                COUNT(o.order_id) AS order_count,
                SUM(o.quantity) AS total_quantity,
                SUM(o.total_amount) AS total_revenue
            FROM ORDERS o
            JOIN PRODUCTS p ON o.product_id = p.product_id
            WHERE o.order_date BETWEEN p_start_date AND p_end_date
              AND o.order_status != 'Cancelled'
            GROUP BY p.category
            ORDER BY total_revenue DESC;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== SALES REPORT ===');
        DBMS_OUTPUT.PUT_LINE('Period: ' || TO_CHAR(p_start_date, 'DD-MON-YYYY') || 
                           ' to ' || TO_CHAR(p_end_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('-----------------------------------');
        
        FOR sales_rec IN c_sales LOOP
            DBMS_OUTPUT.PUT_LINE('Category: ' || sales_rec.category);
            DBMS_OUTPUT.PUT_LINE('  Orders: ' || sales_rec.order_count);
            DBMS_OUTPUT.PUT_LINE('  Quantity: ' || sales_rec.total_quantity);
            DBMS_OUTPUT.PUT_LINE('  Revenue: ' || TO_CHAR(sales_rec.total_revenue, '999,999,999.99'));
            DBMS_OUTPUT.PUT_LINE('-----------------------------------');
        END LOOP;
        
        log_activity('SALES_REPORT_GENERATED', p_user_id, 
                    'Date range: ' || p_start_date || ' to ' || p_end_date);
    END generate_sales_report;
    
    -- Function implementations
    FUNCTION get_customer_order_count(
        p_customer_id IN NUMBER
    ) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM ORDERS
        WHERE customer_id = p_customer_id
          AND order_status != 'Cancelled';
        
        RETURN v_count;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_customer_order_count;
    
    FUNCTION get_product_revenue(
        p_product_id IN NUMBER,
        p_start_date IN DATE DEFAULT NULL,
        p_end_date IN DATE DEFAULT NULL
    ) RETURN NUMBER IS
        v_revenue NUMBER;
    BEGIN
        IF p_start_date IS NULL THEN
            SELECT NVL(SUM(total_amount), 0)
            INTO v_revenue
            FROM ORDERS
            WHERE product_id = p_product_id
              AND order_status != 'Cancelled';
        ELSE
            SELECT NVL(SUM(total_amount), 0)
            INTO v_revenue
            FROM ORDERS
            WHERE product_id = p_product_id
              AND order_status != 'Cancelled'
              AND order_date BETWEEN p_start_date AND NVL(p_end_date, SYSDATE);
        END IF;
        
        RETURN v_revenue;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_product_revenue;
    
    FUNCTION get_order_details(
        p_order_id IN NUMBER
    ) RETURN t_order_summary IS
        v_order t_order_summary;
    BEGIN
        SELECT 
            o.order_id,
            o.order_date,
            c.first_name || ' ' || c.last_name,
            p.product_name,
            o.quantity,
            o.total_amount,
            o.order_status
        INTO v_order
        FROM ORDERS o
        JOIN CUSTOMERS c ON o.customer_id = c.customer_id
        JOIN PRODUCTS p ON o.product_id = p.product_id
        WHERE o.order_id = p_order_id;
        
        RETURN v_order;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_order.order_id := -1;
            RETURN v_order;
        WHEN OTHERS THEN
            v_order.order_id := -999;
            RETURN v_order;
    END get_order_details;
    
END pkg_order_management;
/


-- View 1: Customer Ranking by Total Spending
CREATE OR REPLACE VIEW vw_customer_rankings AS
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.city,
    c.country,
    NVL(SUM(o.total_amount), 0) AS total_spent,
    COUNT(o.order_id) AS order_count,
    ROW_NUMBER() OVER (ORDER BY NVL(SUM(o.total_amount), 0) DESC) AS spending_rank,
    RANK() OVER (ORDER BY NVL(SUM(o.total_amount), 0) DESC) AS spending_rank_with_ties,
    DENSE_RANK() OVER (ORDER BY NVL(SUM(o.total_amount), 0) DESC) AS dense_rank,
    PERCENT_RANK() OVER (ORDER BY NVL(SUM(o.total_amount), 0) DESC) AS percentile
FROM CUSTOMERS c
LEFT JOIN ORDERS o ON c.customer_id = o.customer_id AND o.order_status != 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.country;



-- View 2: Product Performance with Lag/Lead
CREATE OR REPLACE VIEW vw_product_performance_trends AS
SELECT 
    product_id,
    product_name,
    category,
    order_month,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (PARTITION BY product_id ORDER BY order_month) AS prev_month_revenue,
    LEAD(monthly_revenue, 1) OVER (PARTITION BY product_id ORDER BY order_month) AS next_month_revenue,
    monthly_revenue - LAG(monthly_revenue, 1) OVER (PARTITION BY product_id ORDER BY order_month) AS revenue_change,
    ROUND(((monthly_revenue - LAG(monthly_revenue, 1) OVER (PARTITION BY product_id ORDER BY order_month)) / 
           NULLIF(LAG(monthly_revenue, 1) OVER (PARTITION BY product_id ORDER BY order_month), 0)) * 100, 2) AS pct_change
FROM (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        TO_CHAR(o.order_date, 'YYYY-MM') AS order_month,
        SUM(o.total_amount) AS monthly_revenue
    FROM PRODUCTS p
    JOIN ORDERS o ON p.product_id = o.product_id
    WHERE o.order_status != 'Cancelled'
    GROUP BY p.product_id, p.product_name, p.category, TO_CHAR(o.order_date, 'YYYY-MM')
);


-- View 3: Top Products per Category
CREATE OR REPLACE VIEW vw_top_products_by_category AS
SELECT category,
       product_id,
       product_name,
       category_revenue,
       rank_in_category,
       total_category_revenue,
       ROUND(100.0 * category_revenue / total_category_revenue, 2) AS pct_of_category
FROM (
    SELECT p.category,
           p.product_id,
           p.product_name,
           NVL(SUM(o.total_amount), 0)                                   AS category_revenue,
           ROW_NUMBER() OVER (PARTITION BY p.category 
                               ORDER BY NVL(SUM(o.total_amount), 0) DESC) AS rank_in_category,
           SUM(NVL(SUM(o.total_amount), 0)) OVER (PARTITION BY p.category) AS total_category_revenue
    FROM PRODUCTS p
    LEFT JOIN ORDERS o 
           ON p.product_id = o.product_id 
          AND o.order_status != 'Cancelled'
    GROUP BY p.category, p.product_id, p.product_name
)
WHERE rank_in_category <= 5;


-- View 4: Running Total of Orders
CREATE OR REPLACE VIEW vw_cumulative_sales AS
SELECT 
    order_date,
    order_count,
    daily_revenue,
    SUM(order_count) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_orders,
    SUM(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue,
    AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7days
FROM (
    SELECT 
        TRUNC(order_date) AS order_date,
        COUNT(*) AS order_count,
        SUM(total_amount) AS daily_revenue
    FROM ORDERS
    WHERE order_status != 'Cancelled'
    GROUP BY TRUNC(order_date)
);

-- Procedure with Explicit Cursor and Bulk Collect
CREATE OR REPLACE PROCEDURE sp_bulk_update_customer_totals IS
    -- Cursor for customer order aggregates
    CURSOR c_customer_stats IS
        SELECT 
            customer_id,
            COUNT(*) AS order_count,
            SUM(total_amount) AS total_spent
        FROM ORDERS
        WHERE order_status != 'Cancelled'
        GROUP BY customer_id;
    
    TYPE t_customer_stats IS TABLE OF c_customer_stats%ROWTYPE;
    v_customer_stats t_customer_stats;
    
    v_rows_updated NUMBER := 0;
BEGIN
    -- Bulk collect all customer statistics
    OPEN c_customer_stats;
    FETCH c_customer_stats BULK COLLECT INTO v_customer_stats;
    CLOSE c_customer_stats;
    
    -- Process in bulk
    FORALL i IN 1..v_customer_stats.COUNT
        UPDATE CUSTOMERS
        SET total_orders = v_customer_stats(i).order_count
        WHERE customer_id = v_customer_stats(i).customer_id;
    
    v_rows_updated := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Updated ' || v_rows_updated || ' customer records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in bulk update: ' || SQLERRM);
END sp_bulk_update_customer_totals;
/

-- Trigger 1: Auto-update product status based on stock
CREATE OR REPLACE TRIGGER trg_update_product_status
BEFORE UPDATE OF stock_quantity ON PRODUCTS
FOR EACH ROW
BEGIN
    IF :NEW.stock_quantity = 0 THEN
        :NEW.product_status := 'Out of Stock';
    ELSIF :NEW.stock_quantity > 0 AND :OLD.product_status = 'Out of Stock' THEN
        :NEW.product_status := 'Available';
    END IF;
    
    :NEW.last_updated := SYSDATE;
END;
/




-- Trigger 2: Prevent order modification after delivery
CREATE OR REPLACE TRIGGER trg_prevent_delivered_order_update
BEFORE UPDATE ON ORDERS
FOR EACH ROW
DECLARE
    v_error_msg VARCHAR2(200);
BEGIN
    IF :OLD.order_status = 'Delivered' AND :NEW.order_status != :OLD.order_status THEN
        v_error_msg := 'Cannot modify delivered orders';
        RAISE_APPLICATION_ERROR(-20100, v_error_msg);
    END IF;
END;
/





-- Trigger 3: Audit trail for customer changes
CREATE OR REPLACE TRIGGER trg_audit_customer_changes
AFTER UPDATE ON CUSTOMERS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_TRAIL(audit_id, table_name, operation, record_id, old_values, new_values, operation_date)
    VALUES(
        seq_audit_trail.NEXTVAL,
        'CUSTOMERS',
        'UPDATE',
        :NEW.customer_id,
        '{"status":"' || :OLD.customer_status || '","credit_limit":' || :OLD.credit_limit || '}',
        '{"status":"' || :NEW.customer_status || '","credit_limit":' || :NEW.credit_limit || '}',
        SYSTIMESTAMP
    );
END;
/

-- Test 1: Validate Customer Function
DECLARE
    v_result BOOLEAN;
    v_customer_id NUMBER := 1001; -- Should exist from earlier data
BEGIN
    v_result := fn_validate_customer(v_customer_id);
    
    IF v_result THEN
        DBMS_OUTPUT.PUT_LINE('✓ Customer ' || v_customer_id || ' is valid and active');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ Customer ' || v_customer_id || ' is invalid or inactive');
    END IF;
    
    -- Test with non-existent customer
    v_customer_id := 99999;
    v_result := fn_validate_customer(v_customer_id);
    
    IF NOT v_result THEN
        DBMS_OUTPUT.PUT_LINE('✓ Correctly identified invalid customer ' || v_customer_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ Failed to identify invalid customer');
    END IF;
END;
/


--Test 2: Product Stock Check Function 
DECLARE
    v_stock NUMBER;
    v_product_id NUMBER;
BEGIN
    -- Get a valid product
    SELECT product_id INTO v_product_id 
    FROM PRODUCTS 
    WHERE product_status = 'Available' AND ROWNUM = 1;
    
    v_stock := fn_check_product_stock(v_product_id);
    
    IF v_stock >= 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ Product ' || v_product_id || ' has stock: ' || v_stock);
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ Product stock check failed');
    END IF;
    
    -- Test with invalid product
    v_stock := fn_check_product_stock(99999);
    IF v_stock = -1 THEN
        DBMS_OUTPUT.PUT_LINE('✓ Correctly identified invalid product');
    END IF;
END;
/


 --Test 3: Calculate Order Total Function
DECLARE
    v_total NUMBER;
BEGIN
    v_total := fn_calculate_order_total(100, 5, TRUE);
    DBMS_OUTPUT.PUT_LINE('✓ Order total with tax: ' || v_total);
    
    v_total := fn_calculate_order_total(100, 5, FALSE);
    DBMS_OUTPUT.PUT_LINE('✓ Order total without tax: ' || v_total);
    
    -- Test edge case: negative quantity
    v_total := fn_calculate_order_total(100, -5, TRUE);
    IF v_total = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ Correctly handled negative quantity');
    END IF;
END;
/
--Test 4: Place Order Procedure (Success Case)
DECLARE
    v_customer_id NUMBER;
    v_product_id NUMBER;
    v_user_id NUMBER;
    v_order_id NUMBER;
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    -- Get valid test data
    SELECT customer_id INTO v_customer_id 
    FROM CUSTOMERS 
    WHERE customer_status = 'Active' AND ROWNUM = 1;
    
    SELECT product_id INTO v_product_id 
    FROM PRODUCTS 
    WHERE product_status = 'Available' AND stock_quantity > 10 AND ROWNUM = 1;
    
    SELECT user_id INTO v_user_id 
    FROM USER_ACCOUNTS 
    WHERE account_status = 'Active' AND role = 'Sales' AND ROWNUM = 1;
    
    -- Place order
    sp_place_order(
        p_customer_id => v_customer_id,
        p_product_id => v_product_id,
        p_quantity => 2,
        p_user_id => v_user_id,
        p_order_id => v_order_id,
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    
    IF v_status = 'SUCCESS' THEN
        DBMS_OUTPUT.PUT_LINE('✓ Order placed successfully. Order ID: ' || v_order_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ Order placement failed');
    END IF;
END;
/


--Test 5: Place Order Procedure (Insufficient Stock)
DECLARE
    v_customer_id NUMBER;
    v_product_id NUMBER;
    v_user_id NUMBER;
    v_order_id NUMBER;
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    SELECT customer_id INTO v_customer_id FROM CUSTOMERS WHERE ROWNUM = 1;
    SELECT product_id INTO v_product_id FROM PRODUCTS WHERE stock_quantity < 5 AND ROWNUM = 1;
    SELECT user_id INTO v_user_id FROM USER_ACCOUNTS WHERE ROWNUM = 1;
    
    -- Try to order more than available stock
    sp_place_order(
        p_customer_id => v_customer_id,
        p_product_id => v_product_id,
        p_quantity => 1000,
        p_user_id => v_user_id,
        p_order_id => v_order_id,
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    
    IF v_status = 'FAILED' AND v_message LIKE '%insufficient stock%' THEN
        DBMS_OUTPUT.PUT_LINE('✓ Correctly rejected order with insufficient stock');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ Failed to catch insufficient stock');
    END IF;
END;
/

--Test 6: Update Order Status Procedure 
DECLARE
    v_order_id NUMBER;
    v_user_id NUMBER;
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    -- Get a pending order
    SELECT order_id INTO v_order_id 
    FROM ORDERS 
    WHERE order_status = 'Pending' AND ROWNUM = 1;
    
    SELECT user_id INTO v_user_id 
    FROM USER_ACCOUNTS 
    WHERE role = 'Manager' AND ROWNUM = 1;
    
    -- Update status
    sp_update_order_status(
        p_order_id => v_order_id,
        p_new_status => 'Processing',
        p_user_id => v_user_id,
        p_remarks => 'Test status update',
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    
    IF v_status = 'SUCCESS' THEN
        DBMS_OUTPUT.PUT_LINE('✓ Order status updated successfully');
    END IF;
END;
/



-- Test 7: Process Payment Procedure
DECLARE
    v_order_id NUMBER;
    v_user_id NUMBER;
    v_amount NUMBER;
    v_transaction_id NUMBER;
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    -- Get an order with pending payment
    SELECT order_id, total_amount INTO v_order_id, v_amount
    FROM ORDERS 
    WHERE payment_status = 'Pending' AND ROWNUM = 1;
    
    SELECT user_id INTO v_user_id FROM USER_ACCOUNTS WHERE ROWNUM = 1;
    
    -- Process payment
    sp_process_payment(
        p_order_id => v_order_id,
        p_payment_method => 'Credit Card',
        p_amount => v_amount,
        p_user_id => v_user_id,
        p_transaction_id => v_transaction_id,
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    
    IF v_status = 'SUCCESS' THEN
        DBMS_OUTPUT.PUT_LINE('✓ Payment processed. Transaction ID: ' || v_transaction_id);
    END IF;
END;
/


--Test 8: Add Customer Feedback Procedure 
DECLARE
    v_order_id NUMBER;
    v_customer_id NUMBER;
    v_feedback_id NUMBER;
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    -- Get a delivered order
    SELECT o.order_id, o.customer_id INTO v_order_id, v_customer_id
    FROM ORDERS o
    WHERE o.order_status = 'Delivered' 
      AND NOT EXISTS (SELECT 1 FROM CUSTOMER_FEEDBACK WHERE order_id = o.order_id)
      AND ROWNUM = 1;
    
    -- Add feedback
    sp_add_customer_feedback(
        p_order_id => v_order_id,
        p_customer_id => v_customer_id,
        p_rating => 5,
        p_comment => 'Excellent service and product quality!',
        p_feedback_id => v_feedback_id,
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    
    IF v_status = 'SUCCESS' THEN
        DBMS_OUTPUT.PUT_LINE('✓ Feedback added. Feedback ID: ' || v_feedback_id);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('⚠ No delivered orders available for feedback test');
END;


-- Test 9: Restock Products Procedure
DECLARE
    v_user_id NUMBER;
    v_products_restocked NUMBER;
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    SELECT user_id INTO v_user_id 
    FROM USER_ACCOUNTS 
    WHERE role = 'Warehouse' AND ROWNUM = 1;
    
    sp_restock_products(
        p_user_id => v_user_id,
        p_restock_quantity => 50,
        p_products_restocked => v_products_restocked,
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    DBMS_OUTPUT.PUT_LINE('✓ Products restocked: ' || v_products_restocked);
END;
/

--Test 10: Package Functions
DECLARE
    v_customer_id NUMBER;
    v_order_count NUMBER;
    v_product_id NUMBER;
    v_revenue NUMBER;
BEGIN
    -- Test get_customer_order_count
    SELECT customer_id INTO v_customer_id FROM CUSTOMERS WHERE ROWNUM = 1;
    v_order_count := pkg_order_management.get_customer_order_count(v_customer_id);
    DBMS_OUTPUT.PUT_LINE('✓ Customer ' || v_customer_id || ' has ' || v_order_count || ' orders');
    
    -- Test get_product_revenue
    SELECT product_id INTO v_product_id FROM PRODUCTS WHERE ROWNUM = 1;
    v_revenue := pkg_order_management.get_product_revenue(v_product_id);
    DBMS_OUTPUT.PUT_LINE('✓ Product ' || v_product_id || ' revenue: ' || v_revenue);
END;
/


 --Test 11: Window Functions - Top Customers
SELECT 
    customer_name,
    city,
    total_spent,
    spending_rank,
    ROUND(percentile * 100, 2) || '%' AS percentile_rank
FROM vw_customer_rankings
WHERE ROWNUM <= 10
ORDER BY spending_rank;

-- Test 12: Window Functions - Product Trends
SELECT 
    product_name,
    order_month,
    monthly_revenue,
    prev_month_revenue,
    revenue_change,
    pct_change || '%' AS growth_rate
FROM vw_product_performance_trends
WHERE prev_month_revenue IS NOT NULL
ORDER BY product_id, order_month DESC
FETCH FIRST 9 ROWS ONLY;







 --Test 13: Bulk Operations Performance Test
BEGIN
    sp_bulk_update_customer_totals;
END;




DECLARE
    v_order_id NUMBER;
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    sp_place_order(
        p_customer_id => 1001,
        p_product_id => 20,
        p_quantity => 5,
        p_user_id => 3001,
        p_order_id => v_order_id,
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    DBMS_OUTPUT.PUT_LINE('Order ID: ' || v_order_id);
END;
/
SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PUBLIC_HOLIDAYS CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


-- Create Public Holidays table
CREATE TABLE PUBLIC_HOLIDAYS (
    holiday_id NUMBER(10) PRIMARY KEY,
    holiday_date DATE NOT NULL UNIQUE,
    holiday_name VARCHAR2(100) NOT NULL,
    holiday_type VARCHAR2(50) CHECK (holiday_type IN ('National', 'Religious', 'Cultural', 'Bank Holiday')),
    is_recurring CHAR(1) DEFAULT 'N' CHECK (is_recurring IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    created_by NUMBER(10),
    CONSTRAINT fk_holiday_creator FOREIGN KEY (created_by) REFERENCES USER_ACCOUNTS(user_id) ON DELETE SET NULL
);


-- Create sequence for holiday IDs
CREATE SEQUENCE seq_holiday START WITH 1 INCREMENT BY 1;

-- Create index on holiday date
CREATE INDEX idx_holiday_date ON PUBLIC_HOLIDAYS(holiday_date);

-- Insert Rwanda public holidays and sample holidays for testing
INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-01-01', 'New Year Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-02-01', 'National Heroes Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-04-07', 'Genocide Memorial Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-05-01', 'Labour Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-07-01', 'Independence Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-07-04', 'Liberation Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-08-15', 'Assumption Day', 'Religious', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-12-25', 'Christmas Day', 'Religious', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2024-12-26', 'Boxing Day', 'National', 'Y');

-- Add holidays for 2025
INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-01-01', 'New Year Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-02-01', 'National Heroes Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-04-07', 'Genocide Memorial Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-05-01', 'Labour Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-07-01', 'Independence Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-07-04', 'Liberation Day', 'National', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-08-15', 'Assumption Day', 'Religious', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-12-25', 'Christmas Day', 'Religious', 'Y');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, DATE '2025-12-26', 'Boxing Day', 'National', 'Y');

-- Add some test holidays for the upcoming month (for testing purposes)
INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, TRUNC(SYSDATE + 5), 'Test Holiday 1', 'National', 'N');

INSERT INTO PUBLIC_HOLIDAYS (holiday_id, holiday_date, holiday_name, holiday_type, is_recurring)
VALUES (seq_holiday.NEXTVAL, TRUNC(SYSDATE + 15), 'Test Holiday 2', 'National', 'N');

COMMIT;

-- Drop existing audit table if exists
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE OPERATION_AUDIT_LOG CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE OPERATION_AUDIT_LOG (
    audit_log_id NUMBER(10) PRIMARY KEY,
    operation_type VARCHAR2(20) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    table_name VARCHAR2(50) NOT NULL,
    operation_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    operation_day VARCHAR2(20),
    is_weekend CHAR(1) CHECK (is_weekend IN ('Y', 'N')),
    is_holiday CHAR(1) CHECK (is_holiday IN ('Y', 'N')),
    holiday_name VARCHAR2(100),
    operation_status VARCHAR2(20) CHECK (operation_status IN ('ALLOWED', 'DENIED', 'ERROR')),
    denial_reason VARCHAR2(500),
    user_session VARCHAR2(100),
    os_user VARCHAR2(100),
    machine_name VARCHAR2(100),
    ip_address VARCHAR2(45),
    record_id NUMBER(10),
    old_values CLOB,
    new_values CLOB,
    error_message VARCHAR2(4000),
    CONSTRAINT chk_status_reason CHECK (
        (operation_status = 'DENIED' AND denial_reason IS NOT NULL) OR
        (operation_status != 'DENIED')
    )
);

-- Create sequence for audit log IDs
CREATE SEQUENCE seq_audit_log START WITH 1 INCREMENT BY 1;

-- Create indexes for performance
CREATE INDEX idx_audit_operation_date ON OPERATION_AUDIT_LOG(operation_date);
CREATE INDEX idx_audit_table_name ON OPERATION_AUDIT_LOG(table_name);
CREATE INDEX idx_audit_status ON OPERATION_AUDIT_LOG(operation_status);
CREATE INDEX idx_audit_user ON OPERATION_AUDIT_LOG(user_session);

--  AUDIT LOGGING FUNCTION
-- Function to log all operations (ALLOWED, DENIED, or ERROR)
CREATE OR REPLACE FUNCTION fn_log_operation_audit(
    p_operation_type IN VARCHAR2,
    p_table_name IN VARCHAR2,
    p_operation_status IN VARCHAR2,
    p_denial_reason IN VARCHAR2 DEFAULT NULL,
    p_record_id IN NUMBER DEFAULT NULL,
    p_old_values IN CLOB DEFAULT NULL,
    p_new_values IN CLOB DEFAULT NULL,
    p_error_message IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
    v_audit_log_id NUMBER;
    v_operation_day VARCHAR2(20);
    v_is_weekend CHAR(1);
    v_is_holiday CHAR(1) := 'N';
    v_holiday_name VARCHAR2(100) := NULL;
    v_day_number NUMBER;
BEGIN
    -- Determine day of week
    v_day_number := TO_CHAR(SYSDATE, 'D'); -- 1=Sunday, 7=Saturday
    v_operation_day := TO_CHAR(SYSDATE, 'DAY');
    
    -- Check if weekend (Saturday=7, Sunday=1)
    IF v_day_number IN (1, 7) THEN
        v_is_weekend := 'Y';
    ELSE
        v_is_weekend := 'N';
    END IF;
    
    -- Check if today is a holiday
    BEGIN
        SELECT 'Y', holiday_name
        INTO v_is_holiday, v_holiday_name
        FROM PUBLIC_HOLIDAYS
        WHERE TRUNC(holiday_date) = TRUNC(SYSDATE)
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_is_holiday := 'N';
    END;
    
    -- Insert audit log
    INSERT INTO OPERATION_AUDIT_LOG (
        audit_log_id, operation_type, table_name, operation_date,
        operation_day, is_weekend, is_holiday, holiday_name,
        operation_status, denial_reason, user_session, os_user,
        machine_name, ip_address, record_id, old_values,
        new_values, error_message
    ) VALUES (
        seq_audit_log.NEXTVAL, p_operation_type, p_table_name, SYSTIMESTAMP,
        TRIM(v_operation_day), v_is_weekend, v_is_holiday, v_holiday_name,
        p_operation_status, p_denial_reason, SYS_CONTEXT('USERENV', 'SESSION_USER'),
        SYS_CONTEXT('USERENV', 'OS_USER'), SYS_CONTEXT('USERENV', 'HOST'),
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'), p_record_id, p_old_values,
        p_new_values, p_error_message
    ) RETURNING audit_log_id INTO v_audit_log_id;
    
    COMMIT;
    RETURN v_audit_log_id;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RETURN -1;   
        END fn_log_operation_audit;
/

-- RESTRICTION CHECK FUNCTION
--Function to check if operation is allowed based on business rules
CREATE OR REPLACE FUNCTION fn_check_operation_restriction(
    p_operation_type IN VARCHAR2,
    p_table_name IN VARCHAR2,
    p_check_upcoming_month IN CHAR DEFAULT 'Y'
) RETURN VARCHAR2
IS
    v_day_number NUMBER;
    v_is_holiday NUMBER;
    v_holiday_name VARCHAR2(100);
    v_error_message VARCHAR2(500);
BEGIN
    -- Get day of week (1=Sunday, 2=Monday, ... 7=Saturday)
    v_day_number := TO_CHAR(SYSDATE, 'D');
    
    -- RULE 1: Check if today is a WEEKDAY (Monday-Friday)
    -- In Oracle: Monday=2, Tuesday=3, Wednesday=4, Thursday=5, Friday=6
    IF v_day_number BETWEEN 2 AND 6 THEN
        v_error_message := 'OPERATION DENIED: Cannot perform ' || p_operation_type || 
                          ' on ' || p_table_name || ' during WEEKDAYS (Monday-Friday). ' ||
                          'Today is ' || TO_CHAR(SYSDATE, 'DAY') || '. ' ||
                          'Operations are only allowed on WEEKENDS (Saturday-Sunday).';
        RETURN v_error_message;
    END IF;
    
    -- RULE 2: Check if today is a PUBLIC HOLIDAY
    BEGIN
        SELECT COUNT(*), MAX(holiday_name)
        INTO v_is_holiday, v_holiday_name
        FROM PUBLIC_HOLIDAYS
        WHERE TRUNC(holiday_date) = TRUNC(SYSDATE);
        
        IF v_is_holiday > 0 THEN
            v_error_message := 'OPERATION DENIED: Cannot perform ' || p_operation_type || 
                              ' on ' || p_table_name || ' during PUBLIC HOLIDAYS. ' ||
                              'Today is "' || v_holiday_name || '". ' ||
                              'Operations are only allowed on non-holiday WEEKENDS.';
            RETURN v_error_message;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- If holiday check fails, continue
    END;
    
    -- RULE 3: Check upcoming month holidays (optional check)
    IF p_check_upcoming_month = 'Y' THEN
        BEGIN
            SELECT COUNT(*), MAX(holiday_name)
            INTO v_is_holiday, v_holiday_name
            FROM PUBLIC_HOLIDAYS
            WHERE holiday_date BETWEEN TRUNC(SYSDATE) AND ADD_MONTHS(TRUNC(SYSDATE), 1)
              AND TRUNC(holiday_date) = TRUNC(SYSDATE);
            
            IF v_is_holiday > 0 THEN
                v_error_message := 'OPERATION DENIED: Cannot perform ' || p_operation_type || 
                                  ' on ' || p_table_name || ' during PUBLIC HOLIDAYS (upcoming month). ' ||
                                  'Today is "' || v_holiday_name || '".';
                RETURN v_error_message;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END IF;
    
    -- If all checks pass, operation is ALLOWED
    RETURN 'ALLOWED';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END fn_check_operation_restriction;
/






-- SIMPLE TRIGGERS WITH RESTRICTION LOGIC
-- Trigger 1: ORDERS Table - INSERT Restriction
CREATE OR REPLACE TRIGGER trg_orders_insert_restriction
BEFORE INSERT ON ORDERS
FOR EACH ROW
DECLARE
    v_restriction_result VARCHAR2(500);
    v_audit_log_id NUMBER;
BEGIN
    -- Check if operation is allowed
    v_restriction_result := fn_check_operation_restriction('INSERT', 'ORDERS', 'Y');
    
    -- If operation is not allowed, log and raise error
    IF v_restriction_result != 'ALLOWED' THEN
        -- Log the DENIED attempt
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'INSERT',
            p_table_name => 'ORDERS',
            p_operation_status => 'DENIED',
            p_denial_reason => v_restriction_result,
            p_record_id => NULL,
            p_new_values => 'Customer: ' || :NEW.customer_id || ', Product: ' || :NEW.product_id
        );
        
        -- Raise application error
        RAISE_APPLICATION_ERROR(-20001, v_restriction_result);
    END IF;
    
    -- If allowed, log successful operation
    v_audit_log_id := fn_log_operation_audit(
        p_operation_type => 'INSERT',
        p_table_name => 'ORDERS',
        p_operation_status => 'ALLOWED',
        p_record_id => :NEW.order_id,
        p_new_values => 'Order created: Customer=' || :NEW.customer_id || 
                       ', Product=' || :NEW.product_id || ', Qty=' || :NEW.quantity
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'INSERT',
            p_table_name => 'ORDERS',
            p_operation_status => 'ERROR',
            p_error_message => SQLERRM
        );        RAISE;  END;
/

-- Trigger 2: ORDERS Table - UPDATE Restriction
CREATE OR REPLACE TRIGGER trg_orders_update_restriction
BEFORE UPDATE ON ORDERS
FOR EACH ROW
DECLARE
    v_restriction_result VARCHAR2(500);
    v_audit_log_id NUMBER;
    v_old_values VARCHAR2(4000);
    v_new_values VARCHAR2(4000);
BEGIN
    -- Check if operation is allowed
    v_restriction_result := fn_check_operation_restriction('UPDATE', 'ORDERS', 'Y');
    
    -- Prepare old and new values
    v_old_values := 'Status=' || :OLD.order_status || ', PaymentStatus=' || :OLD.payment_status;
    v_new_values := 'Status=' || :NEW.order_status || ', PaymentStatus=' || :NEW.payment_status;
    
    -- If operation is not allowed, log and raise error
    IF v_restriction_result != 'ALLOWED' THEN
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'UPDATE',
            p_table_name => 'ORDERS',
            p_operation_status => 'DENIED',
            p_denial_reason => v_restriction_result,
            p_record_id => :OLD.order_id,
            p_old_values => v_old_values,
            p_new_values => v_new_values
        );
        
        RAISE_APPLICATION_ERROR(-20002, v_restriction_result);
    END IF;
    
    -- If allowed, log successful operation
    v_audit_log_id := fn_log_operation_audit(
        p_operation_type => 'UPDATE',
        p_table_name => 'ORDERS',
        p_operation_status => 'ALLOWED',
        p_record_id => :OLD.order_id,
        p_old_values => v_old_values,
        p_new_values => v_new_values
    );
    
EXCEPTION
    WHEN OTHERS THEN
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'UPDATE',
            p_table_name => 'ORDERS',
            p_operation_status => 'ERROR',
            p_record_id => :OLD.order_id,
            p_error_message => SQLERRM
        );
        RAISE;
END;
/

-- Trigger 3: ORDERS Table - DELETE Restriction
CREATE OR REPLACE TRIGGER trg_orders_delete_restriction
BEFORE DELETE ON ORDERS
FOR EACH ROW
DECLARE
    v_restriction_result VARCHAR2(500);
    v_audit_log_id NUMBER;
    v_old_values VARCHAR2(4000);
BEGIN
    -- Check if operation is allowed
    v_restriction_result := fn_check_operation_restriction('DELETE', 'ORDERS', 'Y');
    
    v_old_values := 'Order_ID=' || :OLD.order_id || ', Customer=' || :OLD.customer_id || 
                   ', Status=' || :OLD.order_status;
    
    IF v_restriction_result != 'ALLOWED' THEN
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'DELETE',
            p_table_name => 'ORDERS',
            p_operation_status => 'DENIED',
            p_denial_reason => v_restriction_result,
            p_record_id => :OLD.order_id,
            p_old_values => v_old_values
        );
        
        RAISE_APPLICATION_ERROR(-20003, v_restriction_result);
    END IF;
    
    v_audit_log_id := fn_log_operation_audit(
        p_operation_type => 'DELETE',
        p_table_name => 'ORDERS',
        p_operation_status => 'ALLOWED',
        p_record_id => :OLD.order_id,
        p_old_values => v_old_values
    );
    
EXCEPTION
    WHEN OTHERS THEN
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'DELETE',
            p_table_name => 'ORDERS',
            p_operation_status => 'ERROR',
            p_record_id => :OLD.order_id,
            p_error_message => SQLERRM
        );    
        RAISE;       
        END;
/

-- Trigger 4: PRODUCTS Table - INSERT Restriction
CREATE OR REPLACE TRIGGER trg_products_insert_restriction
BEFORE INSERT ON PRODUCTS
FOR EACH ROW
DECLARE
    v_restriction_result VARCHAR2(500);
    v_audit_log_id NUMBER;
BEGIN
    v_restriction_result := fn_check_operation_restriction('INSERT', 'PRODUCTS', 'Y');
    
    IF v_restriction_result != 'ALLOWED' THEN
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'INSERT',
            p_table_name => 'PRODUCTS',
            p_operation_status => 'DENIED',
            p_denial_reason => v_restriction_result,
            p_new_values => 'Product: ' || :NEW.product_name
        );
        
        RAISE_APPLICATION_ERROR(-20004, v_restriction_result);
    END IF;
    
    v_audit_log_id := fn_log_operation_audit(
        p_operation_type => 'INSERT',
        p_table_name => 'PRODUCTS',
        p_operation_status => 'ALLOWED',
        p_record_id => :NEW.product_id,
        p_new_values => 'Product added: ' || :NEW.product_name
    );
END;
/

-- Trigger 5: PRODUCTS Table - UPDATE Restriction
CREATE OR REPLACE TRIGGER trg_products_update_restriction
BEFORE UPDATE ON PRODUCTS
FOR EACH ROW
DECLARE
    v_restriction_result VARCHAR2(500);
    v_audit_log_id NUMBER;
BEGIN
    v_restriction_result := fn_check_operation_restriction('UPDATE', 'PRODUCTS', 'Y');
    
    IF v_restriction_result != 'ALLOWED' THEN
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'UPDATE',
            p_table_name => 'PRODUCTS',
            p_operation_status => 'DENIED',
            p_denial_reason => v_restriction_result,
            p_record_id => :OLD.product_id
        );
        
        RAISE_APPLICATION_ERROR(-20005, v_restriction_result);
    END IF;
    
    v_audit_log_id := fn_log_operation_audit(
        p_operation_type => 'UPDATE',
        p_table_name => 'PRODUCTS',
        p_operation_status => 'ALLOWED',
        p_record_id => :OLD.product_id,
        p_old_values => 'Stock=' || :OLD.stock_quantity,
        p_new_values => 'Stock=' || :NEW.stock_quantity
    );
END;
/

-- Trigger 6: PRODUCTS Table - DELETE Restriction
CREATE OR REPLACE TRIGGER trg_products_delete_restriction
BEFORE DELETE ON PRODUCTS
FOR EACH ROW
DECLARE
    v_restriction_result VARCHAR2(500);
    v_audit_log_id NUMBER;
BEGIN
    v_restriction_result := fn_check_operation_restriction('DELETE', 'PRODUCTS', 'Y');
    
    IF v_restriction_result != 'ALLOWED' THEN
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => 'DELETE',
            p_table_name => 'PRODUCTS',
            p_operation_status => 'DENIED',
            p_denial_reason => v_restriction_result,
            p_record_id => :OLD.product_id
        );
        
        RAISE_APPLICATION_ERROR(-20006, v_restriction_result);
    END IF;
    
    v_audit_log_id := fn_log_operation_audit(
        p_operation_type => 'DELETE',
        p_table_name => 'PRODUCTS',
        p_operation_status => 'ALLOWED',
        p_record_id => :OLD.product_id,
        p_old_values => 'Product deleted: ' || :OLD.product_name
    );
END;
/
-- COMPOUND TRIGGER FOR CUSTOMERS TABLE
CREATE OR REPLACE TRIGGER trg_customers_compound_restriction
FOR INSERT OR UPDATE OR DELETE ON CUSTOMERS
COMPOUND TRIGGER
    
    -- Global variables accessible across all timing points
    TYPE t_customer_changes IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    g_customer_ids t_customer_changes;
    g_operation_count NUMBER := 0;
    v_restriction_result VARCHAR2(500);
    
    -- BEFORE STATEMENT: Check restriction once for entire statement
    BEFORE STATEMENT IS
    BEGIN
        v_restriction_result := fn_check_operation_restriction(
            CASE 
                WHEN INSERTING THEN 'INSERT'
                WHEN UPDATING THEN 'UPDATE'
                WHEN DELETING THEN 'DELETE'
            END,
            'CUSTOMERS',
            'Y'
        );
        
        IF v_restriction_result != 'ALLOWED' THEN
            RAISE_APPLICATION_ERROR(-20007, v_restriction_result);
        END IF;
        
        g_operation_count := 0;
    END BEFORE STATEMENT;
    
    -- BEFORE EACH ROW: Track each row operation
    BEFORE EACH ROW IS
    BEGIN
        g_operation_count := g_operation_count + 1;
        
        IF INSERTING THEN
            g_customer_ids(g_operation_count) := :NEW.customer_id;
        ELSIF UPDATING OR DELETING THEN
            g_customer_ids(g_operation_count) := :OLD.customer_id;
        END IF;
    END BEFORE EACH ROW;
    
    -- AFTER EACH ROW: Log individual row changes
    AFTER EACH ROW IS
        v_audit_log_id NUMBER;
        v_operation VARCHAR2(20);
    BEGIN
        v_operation := CASE 
            WHEN INSERTING THEN 'INSERT'
            WHEN UPDATING THEN 'UPDATE'
            WHEN DELETING THEN 'DELETE'
        END;
        
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => v_operation,
            p_table_name => 'CUSTOMERS',
            p_operation_status => 'ALLOWED',
            p_record_id => CASE 
                WHEN INSERTING THEN :NEW.customer_id
                ELSE :OLD.customer_id
            END,
            p_old_values => CASE 
                WHEN UPDATING OR DELETING THEN 
                    'Name=' || :OLD.first_name || ' ' || :OLD.last_name
                ELSE NULL
            END,
            p_new_values => CASE 
                WHEN INSERTING OR UPDATING THEN 
                    'Name=' || :NEW.first_name || ' ' || :NEW.last_name
                ELSE NULL
            END
        );
    END AFTER EACH ROW;
    
    -- AFTER STATEMENT: Summary logging
    AFTER STATEMENT IS
        v_audit_log_id NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Compound trigger completed: ' || g_operation_count || ' row(s) affected');
        
        -- Log summary
        v_audit_log_id := fn_log_operation_audit(
            p_operation_type => CASE 
                WHEN INSERTING THEN 'INSERT'
                WHEN UPDATING THEN 'UPDATE'
                WHEN DELETING THEN 'DELETE'
            END,
            p_table_name => 'CUSTOMERS',
            p_operation_status => 'ALLOWED',
            p_new_values => 'Bulk operation: ' || g_operation_count || ' rows affected'
        );
    END AFTER STATEMENT;
    
END trg_customers_compound_restriction;
/

-- UTILITY PROCEDURES
-- Procedure to add public holidays
CREATE OR REPLACE PROCEDURE sp_add_public_holiday(
    p_holiday_date IN DATE,
    p_holiday_name IN VARCHAR2,
    p_holiday_type IN VARCHAR2 DEFAULT 'National',
    p_is_recurring IN CHAR DEFAULT 'Y',
    p_created_by IN NUMBER,
    p_status OUT VARCHAR2,
    p_message OUT VARCHAR2
)
IS
    v_count NUMBER;
BEGIN
    -- Check if holiday already exists
    SELECT COUNT(*) INTO v_count
    FROM PUBLIC_HOLIDAYS
    WHERE TRUNC(holiday_date) = TRUNC(p_holiday_date);
    
    IF v_count > 0 THEN
        p_status := 'FAILED';
        p_message := 'Holiday already exists for this date';
        RETURN;
    END IF;
    
    -- Insert new holiday
    INSERT INTO PUBLIC_HOLIDAYS(holiday_id, holiday_date, holiday_name, 
                                holiday_type, is_recurring, created_by)
    VALUES(seq_holiday.NEXTVAL, TRUNC(p_holiday_date), p_holiday_name,
           p_holiday_type, p_is_recurring, p_created_by);
    
    COMMIT;
    
    p_status := 'SUCCESS';
    p_message := 'Holiday added successfully';
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_status := 'ERROR';
        p_message := 'Error adding holiday: ' || SQLERRM;
END sp_add_public_holiday;
/

-- Procedure to view audit log summary
CREATE OR REPLACE PROCEDURE sp_view_audit_summary(
    p_start_date IN DATE DEFAULT SYSDATE - 30,
    p_end_date IN DATE DEFAULT SYSDATE
)
IS
    CURSOR c_audit_summary IS
        SELECT 
            table_name,
            operation_type,
            operation_status,
            COUNT(*) AS operation_count,
            MIN(operation_date) AS first_operation,
            MAX(operation_date) AS last_operation
        FROM OPERATION_AUDIT_LOG
        WHERE operation_date BETWEEN p_start_date AND p_end_date
        GROUP BY table_name, operation_type, operation_status
        ORDER BY table_name, operation_type, operation_status;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== AUDIT LOG SUMMARY ===');
    DBMS_OUTPUT.PUT_LINE('Period: ' || TO_CHAR(p_start_date, 'DD-MON-YYYY') || 
                        ' to ' || TO_CHAR(p_end_date, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    FOR rec IN c_audit_summary LOOP
        DBMS_OUTPUT.PUT_LINE('Table: ' || rec.table_name);
        DBMS_OUTPUT.PUT_LINE('  Operation: ' || rec.operation_type);
        DBMS_OUTPUT.PUT_LINE('  Status: ' || rec.operation_status);
        DBMS_OUTPUT.PUT_LINE('  Count: ' || rec.operation_count);
        DBMS_OUTPUT.PUT_LINE('  First: ' || TO_CHAR(rec.first_operation, 'DD-MON-YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('  Last: ' || TO_CHAR(rec.last_operation, 'DD-MON-YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
END sp_view_audit_summary;
/


-- ============================================================================
-- SECTION 8: COMPREHENSIVE TESTING SCRIPTS
-- ===========================================================================



-- Test 1: Check Current Day Status
PROMPT  Test 1: Current Day Status 
DECLARE
    v_day_name VARCHAR2(20);
    v_day_number NUMBER;
    v_is_weekday BOOLEAN;
    v_is_weekend BOOLEAN;
    v_is_holiday NUMBER;
    v_holiday_name VARCHAR2(100);
BEGIN
    v_day_number := TO_CHAR(SYSDATE, 'D');
    v_day_name := TRIM(TO_CHAR(SYSDATE, 'DAY'));
    
    v_is_weekday := v_day_number BETWEEN 2 AND 6;
    v_is_weekend := v_day_number IN (1, 7);
    
    DBMS_OUTPUT.PUT_LINE('Today: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Day: ' || v_day_name);
    DBMS_OUTPUT.PUT_LINE('Day Number: ' || v_day_number);
    DBMS_OUTPUT.PUT_LINE('Is Weekday (Mon-Fri): ' || CASE WHEN v_is_weekday THEN 'YES' ELSE 'NO' END);
    DBMS_OUTPUT.PUT_LINE('Is Weekend (Sat-Sun): ' || CASE WHEN v_is_weekend THEN 'YES' ELSE 'NO' END);
    
    -- Check for holiday
    BEGIN
        SELECT COUNT(*), MAX(holiday_name)
        INTO v_is_holiday, v_holiday_name
        FROM PUBLIC_HOLIDAYS
        WHERE TRUNC(holiday_date) = TRUNC(SYSDATE);
        
        IF v_is_holiday > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Is Holiday: YES - "' || v_holiday_name || '"');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Is Holiday: NO');
        END IF;
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('BUSINESS RULE: Operations are ONLY allowed on WEEKENDS (NOT holidays)');
    
    IF v_is_weekday THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED RESULT: All DML operations should be DENIED (Weekday)');
    ELSIF v_is_holiday > 0 THEN
        DBMS_OUTPUT.PUT_LINE('EXPECTED RESULT: All DML operations should be DENIED (Holiday)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('EXPECTED RESULT: All DML operations should be ALLOWED (Weekend, Non-Holiday)');
    END IF;
END;
/

--Test 2: View Upcoming Holidays 
SELECT 
    holiday_date,
    TO_CHAR(holiday_date, 'DAY') AS day_of_week,
    holiday_name,
    holiday_type
FROM PUBLIC_HOLIDAYS
WHERE holiday_date BETWEEN TRUNC(SYSDATE) AND ADD_MONTHS(TRUNC(SYSDATE), 1)
ORDER BY holiday_date;

-- Test 3: Test INSERT on ORDERS (Will DENY on Weekday, ALLOW on Weekend) 
DECLARE
    v_customer_id NUMBER;
    v_product_id NUMBER;
    v_user_id NUMBER;
BEGIN
    -- Get test data
    SELECT customer_id INTO v_customer_id FROM CUSTOMERS WHERE ROWNUM = 1;
    SELECT product_id INTO v_product_id FROM PRODUCTS WHERE stock_quantity > 10 AND ROWNUM = 1;
    SELECT user_id INTO v_user_id FROM USER_ACCOUNTS WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Attempting to INSERT into ORDERS table...');
    
    BEGIN
        INSERT INTO ORDERS(order_id, customer_id, product_id, user_id, quantity,
                          unit_price, total_amount, order_date, order_status, payment_status)
        VALUES(seq_order.NEXTVAL, v_customer_id, v_product_id, v_user_id, 1,
               100, 100, SYSDATE, 'Pending', 'Pending');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✓ INSERT ALLOWED - Operation completed successfully');
        DBMS_OUTPUT.PUT_LINE('  This means today is a WEEKEND and NOT a holiday');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('✗ INSERT DENIED');
            DBMS_OUTPUT.PUT_LINE('  Reason: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('  This means today is either a WEEKDAY or a HOLIDAY');
    END;
END;
/

--Test 4: Test UPDATE on ORDERS
DECLARE
    v_order_id NUMBER;
BEGIN
    SELECT order_id INTO v_order_id FROM ORDERS WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Attempting to UPDATE ORDERS table...');
    
    BEGIN
        UPDATE ORDERS
        SET order_status = 'Processing'
        WHERE order_id = v_order_id;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✓ UPDATE ALLOWED - Operation completed successfully');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('✗ UPDATE DENIED');
            DBMS_OUTPUT.PUT_LINE('  Reason: ' || SQLERRM);
    END;
END;
/

-- Test 5: Test DELETE on ORDERS
DECLARE
    v_order_id NUMBER;
BEGIN
    -- Get an order to test delete (we'll rollback anyway)
    SELECT order_id INTO v_order_id FROM ORDERS WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Attempting to DELETE from ORDERS table...');
    
    BEGIN
        DELETE FROM ORDERS WHERE order_id = v_order_id;
        
        ROLLBACK; -- Always rollback to keep data
        DBMS_OUTPUT.PUT_LINE('✓ DELETE ALLOWED - Operation completed successfully (rolled back)');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('✗ DELETE DENIED');
            DBMS_OUTPUT.PUT_LINE('  Reason: ' || SQLERRM);
    END;
END;
/

--Test 6: Test INSERT on PRODUCTS 
BEGIN
    DBMS_OUTPUT.PUT_LINE('Attempting to INSERT into PRODUCTS table...');
    
    BEGIN
        INSERT INTO PRODUCTS(product_id, product_name, category, unit_price, stock_quantity)
        VALUES(seq_product.NEXTVAL, 'Test Product', 'Test Category', 50, 100);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✓ INSERT ALLOWED on PRODUCTS');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('✗ INSERT DENIED on PRODUCTS');
            DBMS_OUTPUT.PUT_LINE('  Reason: ' || SQLERRM);
    END;
END;
/

-- Test 7: Test Compound Trigger on CUSTOMERS (Bulk Operation)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Attempting bulk INSERT into CUSTOMERS table...');
    
    BEGIN
        INSERT INTO CUSTOMERS(customer_id, first_name, last_name, email, customer_status)
        VALUES(seq_customer.NEXTVAL, 'Test', 'Customer1', 'test1@test.com', 'Active');
        
        INSERT INTO CUSTOMERS(customer_id, first_name, last_name, email, customer_status)
        VALUES(seq_customer.NEXTVAL, 'Test', 'Customer2', 'test2@test.com', 'Active');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✓ BULK INSERT ALLOWED on CUSTOMERS (Compound Trigger)');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('✗ BULK INSERT DENIED on CUSTOMERS');
            DBMS_OUTPUT.PUT_LINE('  Reason: ' || SQLERRM);
    END;
END;
/

--Test 8: Add Test Holiday for Tomorrow (Admin Function) 
DECLARE
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
    v_user_id NUMBER;
    v_tomorrow DATE := TRUNC(SYSDATE) + 1;
BEGIN
    SELECT user_id INTO v_user_id FROM USER_ACCOUNTS WHERE role = 'Admin' AND ROWNUM = 1;
    
    sp_add_public_holiday(
        p_holiday_date => v_tomorrow,
        p_holiday_name => 'Test Holiday - Tomorrow',
        p_holiday_type => 'National',
        p_is_recurring => 'N',
        p_created_by => v_user_id,
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Note: Holiday might already exist or other error: ' || SQLERRM);
END;
/
 
-- Test 9: View Recent Audit Log Entries 
SELECT 
    audit_log_id,
    operation_type,
    table_name,
    TO_CHAR(operation_date, 'DD-MON-YYYY HH24:MI:SS') AS operation_time,
    TRIM(operation_day) AS day_name,
    is_weekend,
    is_holiday,
    operation_status,
    SUBSTR(denial_reason, 1, 80) AS denial_reason_short,
    user_session
FROM OPERATION_AUDIT_LOG
ORDER BY operation_date DESC
FETCH FIRST 20 ROWS ONLY;

-- Test 10: Audit Summary by Status 
SELECT 
    operation_status,
    COUNT(*) AS total_operations,
    SUM(CASE WHEN operation_type = 'INSERT' THEN 1 ELSE 0 END) AS inserts,
    SUM(CASE WHEN operation_type = 'UPDATE' THEN 1 ELSE 0 END) AS updates,
    SUM(CASE WHEN operation_type = 'DELETE' THEN 1 ELSE 0 END) AS deletes
FROM OPERATION_AUDIT_LOG
GROUP BY operation_status
ORDER BY operation_status;

-- Test 11: Audit Summary by Table 
SELECT 
    table_name,
    operation_type,
    COUNT(*) AS operation_count,
    SUM(CASE WHEN operation_status = 'ALLOWED' THEN 1 ELSE 0 END) AS allowed,
    SUM(CASE WHEN operation_status = 'DENIED' THEN 1 ELSE 0 END) AS denied,
    SUM(CASE WHEN operation_status = 'ERROR' THEN 1 ELSE 0 END) AS errors
FROM OPERATION_AUDIT_LOG
GROUP BY table_name, operation_type
ORDER BY table_name, operation_type;

-- Test 12: Weekend vs Weekday Operations 
SELECT 
    is_weekend,
    CASE is_weekend 
        WHEN 'Y' THEN 'WEEKEND (Sat/Sun)'
        ELSE 'WEEKDAY (Mon-Fri)'
    END AS day_type,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN operation_status = 'ALLOWED' THEN 1 ELSE 0 END) AS allowed,
    SUM(CASE WHEN operation_status = 'DENIED' THEN 1 ELSE 0 END) AS denied,
    ROUND(SUM(CASE WHEN operation_status = 'ALLOWED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate
FROM OPERATION_AUDIT_LOG
GROUP BY is_weekend
ORDER BY is_weekend DESC;

-- Test 13: Holiday Operations 
SELECT 
    is_holiday,
    holiday_name,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN operation_status = 'DENIED' THEN 1 ELSE 0 END) AS denied_count
FROM OPERATION_AUDIT_LOG
WHERE is_holiday = 'Y'
GROUP BY is_holiday, holiday_name
ORDER BY holiday_name;

--Test 14: Denied Operations Analysis
SELECT 
    table_name,
    operation_type,
    COUNT(*) AS denied_count,
    MIN(operation_date) AS first_denial,
    MAX(operation_date) AS last_denial,
    SUBSTR(MAX(denial_reason), 1, 100) AS sample_reason
FROM OPERATION_AUDIT_LOG
WHERE operation_status = 'DENIED'
GROUP BY table_name, operation_type
ORDER BY denied_count DESC;









-- Test 16: Call Audit Summary Procedure
BEGIN
    sp_view_audit_summary(SYSDATE - 7, SYSDATE);
END;
/

 --Test 17: Detailed Audit Log (Last 10 Operations) 
SELECT 
    audit_log_id,
    operation_type || ' on ' || table_name AS operation,
    TO_CHAR(operation_date, 'DD-MON HH24:MI:SS') AS when_attempted,
    operation_status,
    CASE 
        WHEN operation_status = 'DENIED' THEN denial_reason
        WHEN operation_status = 'ERROR' THEN error_message
        ELSE 'Successful'
    END AS result,
    user_session AS who_attempted,
    ip_address
FROM OPERATION_AUDIT_LOG
ORDER BY operation_date DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT;
PROMPT ===== TESTING COMPLETE =====
PROMPT;
PROMPT KEY VALIDATION POINTS:
PROMPT ✓ Holiday management table created with test data
PROMPT ✓ Comprehensive audit log table captures all attempts
PROMPT ✓ Audit logging function records user info and context
PROMPT ✓ Restriction check function validates business rules
PROMPT ✓ Simple triggers protect ORDERS and PRODUCTS tables
PROMPT ✓ Compound trigger protects CUSTOMERS with bulk operations
PROMPT ✓ Weekday operations are DENIED
PROMPT ✓ Weekend operations are ALLOWED (if not holiday)
PROMPT ✓ Holiday operations are DENIED
PROMPT ✓ Clear error messages provided
PROMPT ✓ User information properly captured
PROMPT ✓ All denied attempts logged in audit table
PROMPT;
PROMPT BUSINESS RULE ENFORCEMENT:
PROMPT → Employees CANNOT INSERT/UPDATE/DELETE on:
PROMPT   • WEEKDAYS (Monday-Friday) - DENIED
PROMPT   • PUBLIC HOLIDAYS (upcoming month) - DENIED
PROMPT → Operations ONLY allowed on:
PROMPT   • WEEKENDS (Saturday-Sunday) - ALLOWED
PROMPT   • Non-Holiday Weekends - ALLOWED
PROMPT;
PROMPT RECOMMENDATION FOR LIVE TESTING:
PROMPT 1. Run tests on different days (Weekday vs Weekend)
PROMPT 2. Add test holidays and verify blocking
PROMPT 3. Review audit logs after each test
PROMPT 4. Verify error messages are user-friendly
PROMPT 5. Check that all user context is captured
PROMPT;




select * from customers;