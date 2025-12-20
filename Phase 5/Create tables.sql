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
