INSERT REALISTIC TEST DATA


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
