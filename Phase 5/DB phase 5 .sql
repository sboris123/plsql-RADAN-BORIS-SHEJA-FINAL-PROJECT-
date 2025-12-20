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




SELECT CUSTOMERS, COUNT(*) as row_count 
FROM (
  SELECT 'CUSTOMERS' as table_name FROM CUSTOMERS
  UNION ALL SELECT 'PRODUCTS' FROM PRODUCTS
  UNION ALL SELECT 'ORDERS' FROM ORDERS
) 
GROUP BY CUSTOMERS;




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
