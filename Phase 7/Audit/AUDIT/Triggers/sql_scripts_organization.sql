-- ============================================================================
-- SQL SCRIPTS ORGANIZATION GUIDE
-- Automated Customer Order Validation System
-- Author: SHEJA RADAN BORIS (29096)
-- ============================================================================

-- ============================================================================
-- MASTER INSTALLATION SCRIPT (install_all.sql)
-- Execute this single file to install entire system
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
SET FEEDBACK ON;
SET ECHO ON;

PROMPT ========================================
PROMPT AUTOMATED CUSTOMER ORDER VALIDATION SYSTEM
PROMPT Complete Installation Script
PROMPT Author: SHEJA RADAN BORIS (29096)
PROMPT ========================================
PROMPT;

PROMPT Step 1 of 10: Creating Tables...
@@01_create_tables.sql
PROMPT ✓ Tables created successfully
PROMPT;

PROMPT Step 2 of 10: Creating Sequences...
@@02_create_sequences.sql
PROMPT ✓ Sequences created successfully
PROMPT;

PROMPT Step 3 of 10: Creating Indexes...
@@03_create_indexes.sql
PROMPT ✓ Indexes created successfully
PROMPT;

PROMPT Step 4 of 10: Inserting Sample Data...
PROMPT (This may take 2-3 minutes...)
@@04_insert_data.sql
PROMPT ✓ Sample data inserted successfully
PROMPT;

PROMPT Step 5 of 10: Creating Functions...
@@05_functions.sql
PROMPT ✓ Functions created successfully
PROMPT;

PROMPT Step 6 of 10: Creating Procedures...
@@06_procedures.sql
PROMPT ✓ Procedures created successfully
PROMPT;

PROMPT Step 7 of 10: Creating Packages...
@@07_packages.sql
PROMPT ✓ Packages created successfully
PROMPT;

PROMPT Step 8 of 10: Creating Triggers...
@@08_triggers.sql
PROMPT ✓ Triggers created successfully
PROMPT;

PROMPT Step 9 of 10: Creating Views...
@@09_views.sql
PROMPT ✓ Views created successfully
PROMPT;

PROMPT Step 10 of 10: Running Tests...
@@10_test_scripts.sql
PROMPT ✓ Tests completed
PROMPT;

PROMPT ========================================
PROMPT Installation Summary
PROMPT ========================================

SELECT 
    'TABLES' AS object_type,
    COUNT(*) AS count,
    'Expected: 14' AS expected
FROM USER_TABLES
UNION ALL
SELECT 
    'SEQUENCES',
    COUNT(*),
    'Expected: 14'
FROM USER_SEQUENCES
UNION ALL
SELECT 
    'INDEXES',
    COUNT(*),
    'Expected: 15+'
FROM USER_INDEXES WHERE TABLE_OWNER = USER
UNION ALL
SELECT 
    'FUNCTIONS',
    COUNT(*),
    'Expected: 5'
FROM USER_OBJECTS WHERE object_type = 'FUNCTION'
UNION ALL
SELECT 
    'PROCEDURES',
    COUNT(*),
    'Expected: 5'
FROM USER_OBJECTS WHERE object_type = 'PROCEDURE'
UNION ALL
SELECT 
    'PACKAGES',
    COUNT(*),
    'Expected: 1'
FROM USER_OBJECTS WHERE object_type = 'PACKAGE'
UNION ALL
SELECT 
    'TRIGGERS',
    COUNT(*),
    'Expected: 9'
FROM USER_TRIGGERS WHERE STATUS = 'ENABLED'
UNION ALL
SELECT 
    'VIEWS',
    COUNT(*),
    'Expected: 4'
FROM USER_VIEWS;

PROMPT;
PROMPT Check for any INVALID objects:
SELECT object_type, object_name, status 
FROM USER_OBJECTS 
WHERE status = 'INVALID'
ORDER BY object_type, object_name;

PROMPT;
PROMPT ========================================
PROMPT Installation Complete!
PROMPT ========================================
PROMPT Next Steps:
PROMPT 1. Review test results above
PROMPT 2. Check for any INVALID objects
PROMPT 3. Run: @verify_installation.sql
PROMPT 4. Start using the system!
PROMPT ========================================

-- ============================================================================
-- VERIFICATION SCRIPT (verify_installation.sql)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT ========================================
PROMPT System Verification Script
PROMPT ========================================
PROMPT;

-- Check 1: Object Counts
PROMPT Check 1: Database Objects
PROMPT --------------------------
DECLARE
    v_tables NUMBER;
    v_sequences NUMBER;
    v_functions NUMBER;
    v_procedures NUMBER;
    v_packages NUMBER;
    v_triggers NUMBER;
    v_views NUMBER;
    v_pass NUMBER := 0;
    v_fail NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_tables FROM USER_TABLES;
    SELECT COUNT(*) INTO v_sequences FROM USER_SEQUENCES;
    SELECT COUNT(*) INTO v_functions FROM USER_OBJECTS WHERE object_type = 'FUNCTION';
    SELECT COUNT(*) INTO v_procedures FROM USER_OBJECTS WHERE object_type = 'PROCEDURE';
    SELECT COUNT(*) INTO v_packages FROM USER_OBJECTS WHERE object_type = 'PACKAGE';
    SELECT COUNT(*) INTO v_triggers FROM USER_TRIGGERS WHERE STATUS = 'ENABLED';
    SELECT COUNT(*) INTO v_views FROM USER_VIEWS;
    
    DBMS_OUTPUT.PUT_LINE('Tables: ' || v_tables || ' (Expected: 14) - ' || 
                        CASE WHEN v_tables = 14 THEN '✓ PASS' ELSE '✗ FAIL' END);
    IF v_tables = 14 THEN v_pass := v_pass + 1; ELSE v_fail := v_fail + 1; END IF;
    
    DBMS_OUTPUT.PUT_LINE('Sequences: ' || v_sequences || ' (Expected: 14) - ' || 
                        CASE WHEN v_sequences = 14 THEN '✓ PASS' ELSE '✗ FAIL' END);
    IF v_sequences = 14 THEN v_pass := v_pass + 1; ELSE v_fail := v_fail + 1; END IF;
    
    DBMS_OUTPUT.PUT_LINE('Functions: ' || v_functions || ' (Expected: 5) - ' || 
                        CASE WHEN v_functions = 5 THEN '✓ PASS' ELSE '✗ FAIL' END);
    IF v_functions = 5 THEN v_pass := v_pass + 1; ELSE v_fail := v_fail + 1; END IF;
    
    DBMS_OUTPUT.PUT_LINE('Procedures: ' || v_procedures || ' (Expected: 5) - ' || 
                        CASE WHEN v_procedures = 5 THEN '✓ PASS' ELSE '✗ FAIL' END);
    IF v_procedures = 5 THEN v_pass := v_pass + 1; ELSE v_fail := v_fail + 1; END IF;
    
    DBMS_OUTPUT.PUT_LINE('Packages: ' || v_packages || ' (Expected: 1) - ' || 
                        CASE WHEN v_packages = 1 THEN '✓ PASS' ELSE '✗ FAIL' END);
    IF v_packages = 1 THEN v_pass := v_pass + 1; ELSE v_fail := v_fail + 1; END IF;
    
    DBMS_OUTPUT.PUT_LINE('Triggers: ' || v_triggers || ' (Expected: 9) - ' || 
                        CASE WHEN v_triggers = 9 THEN '✓ PASS' ELSE '✗ FAIL' END);
    IF v_triggers = 9 THEN v_pass := v_pass + 1; ELSE v_fail := v_fail + 1; END IF;
    
    DBMS_OUTPUT.PUT_LINE('Views: ' || v_views || ' (Expected: 4) - ' || 
                        CASE WHEN v_views = 4 THEN '✓ PASS' ELSE '✗ FAIL' END);
    IF v_views = 4 THEN v_pass := v_pass + 1; ELSE v_fail := v_fail + 1; END IF;
    
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('Summary: ' || v_pass || ' passed, ' || v_fail || ' failed');
END;
/

PROMPT;
PROMPT Check 2: Data Volume
PROMPT ---------------------
SELECT 'CUSTOMERS' AS table_name, COUNT(*) AS row_count, 
       CASE WHEN COUNT(*) >= 200 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM CUSTOMERS
UNION ALL
SELECT 'PRODUCTS', COUNT(*), 
       CASE WHEN COUNT(*) >= 150 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM PRODUCTS
UNION ALL
SELECT 'USER_ACCOUNTS', COUNT(*), 
       CASE WHEN COUNT(*) >= 40 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM USER_ACCOUNTS
UNION ALL
SELECT 'ORDERS', COUNT(*), 
       CASE WHEN COUNT(*) >= 500 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM ORDERS;

PROMPT;
PROMPT Check 3: Object Status
PROMPT ----------------------
DECLARE
    v_invalid_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_invalid_count 
    FROM USER_OBJECTS 
    WHERE status = 'INVALID';
    
    IF v_invalid_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('All objects are VALID ✓ PASS');
    ELSE
        DBMS_OUTPUT.PUT_LINE(v_invalid_count || ' INVALID objects found ✗ FAIL');
        DBMS_OUTPUT.PUT_LINE('Run this query to see details:');
        DBMS_OUTPUT.PUT_LINE('SELECT object_type, object_name FROM USER_OBJECTS WHERE status = ''INVALID'';');
    END IF;
END;
/

PROMPT;
PROMPT Check 4: Foreign Key Integrity
PROMPT ------------------------------
DECLARE
    v_orphan_orders NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_orphan_orders
    FROM ORDERS o
    WHERE NOT EXISTS (SELECT 1 FROM CUSTOMERS c WHERE c.customer_id = o.customer_id)
       OR NOT EXISTS (SELECT 1 FROM PRODUCTS p WHERE p.product_id = o.product_id);
    
    IF v_orphan_orders = 0 THEN
        DBMS_OUTPUT.PUT_LINE('All foreign keys valid ✓ PASS');
    ELSE
        DBMS_OUTPUT.PUT_LINE(v_orphan_orders || ' orphaned records found ✗ FAIL');
    END IF;
END;
/

PROMPT;
PROMPT Check 5: Test Function Execution
PROMPT --------------------------------
DECLARE
    v_result BOOLEAN;
BEGIN
    v_result := fn_validate_customer(1001);
    IF v_result THEN
        DBMS_OUTPUT.PUT_LINE('fn_validate_customer works ✓ PASS');
    ELSE
        DBMS_OUTPUT.PUT_LINE('fn_validate_customer failed ✗ FAIL');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('fn_validate_customer error: ' || SQLERRM || ' ✗ FAIL');
END;
/

PROMPT;
PROMPT ========================================
PROMPT Verification Complete
PROMPT ========================================

-- ============================================================================
-- CLEANUP SCRIPT (99_cleanup.sql)
-- ============================================================================

SET SERVEROUTPUT ON;

PROMPT ========================================
PROMPT WARNING: This will delete ALL objects!
PROMPT ========================================
PROMPT;
PROMPT Press Ctrl+C to cancel, or
PAUSE Press Enter to continue...

PROMPT;
PROMPT Dropping all objects...
PROMPT;

-- Drop triggers first
PROMPT Dropping triggers...
BEGIN
    FOR t IN (SELECT trigger_name FROM USER_TRIGGERS) LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || t.trigger_name;
        DBMS_OUTPUT.PUT_LINE('Dropped trigger: ' || t.trigger_name);
    END LOOP;
END;
/

-- Drop views
PROMPT Dropping views...
BEGIN
    FOR v IN (SELECT view_name FROM USER_VIEWS) LOOP
        EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
        DBMS_OUTPUT.PUT_LINE('Dropped view: ' || v.view_name);
    END LOOP;
END;
/

-- Drop packages
PROMPT Dropping packages...
BEGIN
    FOR p IN (SELECT object_name FROM USER_OBJECTS WHERE object_type = 'PACKAGE') LOOP
        EXECUTE IMMEDIATE 'DROP PACKAGE ' || p.object_name;
        DBMS_OUTPUT.PUT_LINE('Dropped package: ' || p.object_name);
    END LOOP;
END;
/

-- Drop procedures
PROMPT Dropping procedures...
BEGIN
    FOR p IN (SELECT object_name FROM USER_OBJECTS WHERE object_type = 'PROCEDURE') LOOP
        EXECUTE IMMEDIATE 'DROP PROCEDURE ' || p.object_name;
        DBMS_OUTPUT.PUT_LINE('Dropped procedure: ' || p.object_name);
    END LOOP;
END;
/

-- Drop functions
PROMPT Dropping functions...
BEGIN
    FOR f IN (SELECT object_name FROM USER_OBJECTS WHERE object_type = 'FUNCTION') LOOP
        EXECUTE IMMEDIATE 'DROP FUNCTION ' || f.object_name;
        DBMS_OUTPUT.PUT_LINE('Dropped function: ' || f.object_name);
    END LOOP;
END;
/

-- Drop tables
PROMPT Dropping tables...
BEGIN
    FOR t IN (SELECT table_name FROM USER_TABLES) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
        DBMS_OUTPUT.PUT_LINE('Dropped table: ' || t.table_name);
    END LOOP;
END;
/

-- Drop sequences
PROMPT Dropping sequences...
BEGIN
    FOR s IN (SELECT sequence_name FROM USER_SEQUENCES) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
        DBMS_OUTPUT.PUT_LINE('Dropped sequence: ' || s.sequence_name);
    END LOOP;
END;
/

PROMPT;
PROMPT ========================================
PROMPT Cleanup Complete
PROMPT ========================================
PROMPT All objects have been removed.
PROMPT To reinstall: @install_all.sql
PROMPT ========================================

-- ============================================================================
-- QUICK START GUIDE (quick_start.sql)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT ========================================
PROMPT Quick Start Guide
PROMPT ========================================
PROMPT;
PROMPT This script demonstrates common operations
PROMPT;

PROMPT Example 1: Place an Order
PROMPT -------------------------
DECLARE
    v_order_id NUMBER;
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Placing order for customer 1001...');
    
    sp_place_order(
        p_customer_id => 1001,
        p_product_id => 2001,
        p_quantity => 2,
        p_user_id => 3001,
        p_order_id => v_order_id,
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
    IF v_status = 'SUCCESS' THEN
        DBMS_OUTPUT.PUT_LINE('Order ID: ' || v_order_id);
    END IF;
    DBMS_OUTPUT.PUT_LINE(' ');
END;
/

PROMPT Example 2: View Top Customers
PROMPT -----------------------------
SELECT 
    customer_name,
    city,
    total_spent,
    order_count,
    spending_rank
FROM vw_customer_rankings
WHERE ROWNUM <= 5
ORDER BY spending_rank;

PROMPT;
PROMPT Example 3: Check Low Stock Products
PROMPT -----------------------------------
SELECT 
    product_id,
    product_name,
    category,
    stock_quantity,
    reorder_level
FROM PRODUCTS
WHERE stock_quantity < reorder_level
ORDER BY stock_quantity;

PROMPT;
PROMPT Example 4: View Recent Audit Log
PROMPT --------------------------------
SELECT 
    audit_log_id,
    operation_type,
    table_name,
    operation_status,
    TO_CHAR(operation_date, 'DD-MON-YY HH24:MI:SS') AS operation_time
FROM OPERATION_AUDIT_LOG
ORDER BY operation_date DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT;
PROMPT ========================================
PROMPT Quick Start Complete
PROMPT ========================================
PROMPT For more examples, see:
PROMPT - queries/data_retrieval.sql
PROMPT - queries/analytics_queries.sql
PROMPT - documentation/user_guide.md
PROMPT ========================================

-- ============================================================================
-- SYSTEM HEALTH CHECK (system_health_check.sql)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT ========================================
PROMPT System Health Check
PROMPT ========================================
PROMPT;

PROMPT 1. Object Status Summary
PROMPT ------------------------
SELECT 
    object_type,
    COUNT(*) AS total,
    SUM(CASE WHEN status = 'VALID' THEN 1 ELSE 0 END) AS valid,
    SUM(CASE WHEN status = 'INVALID' THEN 1 ELSE 0 END) AS invalid
FROM USER_OBJECTS
WHERE object_type IN ('FUNCTION', 'PROCEDURE', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'VIEW')
GROUP BY object_type
ORDER BY object_type;

PROMPT;
PROMPT 2. Table Space Usage
PROMPT --------------------
SELECT 
    segment_name AS table_name,
    ROUND(bytes/1024/1024, 2) AS size_mb
FROM USER_SEGMENTS
WHERE segment_type = 'TABLE'
ORDER BY bytes DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT;
PROMPT 3. Index Status
PROMPT ---------------
SELECT 
    index_name,
    table_name,
    status,
    uniqueness
FROM USER_INDEXES
WHERE status != 'VALID'
ORDER BY table_name, index_name;

PROMPT;
PROMPT 4. Recent Errors
PROMPT ----------------
SELECT 
    table_name,
    error_type,
    COUNT(*) AS error_count,
    MAX(error_date) AS last_error
FROM ORDER_ERROR_LOG
WHERE error_date >= SYSDATE - 7
GROUP BY table_name, error_type
ORDER BY error_count DESC;

PROMPT;
PROMPT 5. Trigger Status
PROMPT -----------------
SELECT 
    trigger_name,
    status,
    trigger_type,
    triggering_event,
    table_name
FROM USER_TRIGGERS
ORDER BY table_name, trigger_name;

PROMPT;
PROMPT 6. Active Sessions (if applicable)
PROMPT ----------------------------------
SELECT 
    COUNT(*) AS active_sessions,
    COUNT(DISTINCT user_id) AS unique_users
FROM USER_SESSIONS
WHERE session_status = 'Active';

PROMPT;
PROMPT 7. Data Growth (Last 7 Days)
PROMPT -----------------------------
DECLARE
    v_new_orders NUMBER;
    v_new_customers NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_new_orders 
    FROM ORDERS 
    WHERE order_date >= SYSDATE - 7;
    
    SELECT COUNT(*) INTO v_new_customers 
    FROM CUSTOMERS 
    WHERE registration_date >= SYSDATE - 7;
    
    DBMS_OUTPUT.PUT_LINE('New Orders (7 days): ' || v_new_orders);
    DBMS_OUTPUT.PUT_LINE('New Customers (7 days): ' || v_new_customers);
END;
/

PROMPT;
PROMPT 8. Compliance Check
PROMPT -------------------
DECLARE
    v_weekday_violations NUMBER;
    v_holiday_violations NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_weekday_violations
    FROM OPERATION_AUDIT_LOG
    WHERE is_weekend = 'N' 
      AND operation_status = 'DENIED'
      AND operation_date >= SYSDATE - 30;
    
    SELECT COUNT(*) INTO v_holiday_violations
    FROM OPERATION_AUDIT_LOG
    WHERE is_holiday = 'Y' 
      AND operation_status = 'DENIED'
      AND operation_date >= SYSDATE - 30;
    
    DBMS_OUTPUT.PUT_LINE('Weekday Violations (30 days): ' || v_weekday_violations);
    DBMS_OUTPUT.PUT_LINE('Holiday Violations (30 days): ' || v_holiday_violations);
    
    IF v_weekday_violations + v_holiday_violations = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Status: ✓ COMPLIANT');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Status: ⚠ VIOLATIONS DETECTED');
    END IF;
END;
/

PROMPT;
PROMPT ========================================
PROMPT Health Check Complete
PROMPT ========================================

-- ============================================================================
-- SAMPLE QUERIES SCRIPT (sample_queries.sql)
-- ============================================================================

-- Query Set 1: Basic Data Retrieval
-- ---------------------------------

-- All active customers
SELECT customer_id, first_name, last_name, email, city, customer_status
FROM CUSTOMERS
WHERE customer_status = 'Active'
ORDER BY registration_date DESC
FETCH FIRST 20 ROWS ONLY;

-- Available products with stock
SELECT product_id, product_name, category, unit_price, stock_quantity
FROM PRODUCTS
WHERE product_status = 'Available' AND stock_quantity > 0
ORDER BY category, product_name;

-- Recent orders
SELECT 
    o.order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    p.product_name,
    o.quantity,
    o.total_amount,
    o.order_status,
    o.order_date
FROM ORDERS o
JOIN CUSTOMERS c ON o.customer_id = c.customer_id
JOIN PRODUCTS p ON o.product_id = p.product_id
ORDER BY o.order_date DESC
FETCH FIRST 25 ROWS ONLY;

-- Query Set 2: Business Analytics
-- -------------------------------

-- Top 10 best-selling products
SELECT 
    p.product_name,
    p.category,
    COUNT(o.order_id) AS times_ordered,
    SUM(o.quantity) AS units_sold,
    SUM(o.total_amount) AS total_revenue
FROM PRODUCTS p
LEFT JOIN ORDERS o ON p.product_id = o.product_id
WHERE o.order_status != 'Cancelled' OR o.order_id IS NULL
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

-- Customer lifetime value
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    AVG(o.total_amount) AS avg_order_value
FROM CUSTOMERS c
LEFT JOIN ORDERS o ON c.customer_id = o.customer_id
WHERE o.order_status != 'Cancelled' OR o.order_id IS NULL
GROUP BY c.customer_id, c.first_name, c.last_name, c.city
HAVING COUNT(o.order_id) > 0
ORDER BY lifetime_value DESC
FETCH FIRST 15 ROWS ONLY;

-- Monthly revenue trend
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS monthly_revenue,
    AVG(total_amount) AS avg_order_value
FROM ORDERS
WHERE order_status != 'Cancelled'
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month DESC
FETCH FIRST 12 ROWS ONLY;

-- Query Set 3: Operational Reports
-- --------------------------------

-- Low stock alert
SELECT 
    product_id,
    product_name,
    category,
    stock_quantity,
    reorder_level,
    reorder_level - stock_quantity AS deficit
FROM PRODUCTS
WHERE stock_quantity < reorder_level
ORDER BY deficit DESC;

-- Order status breakdown
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage,
    SUM(total_amount) AS total_value
FROM ORDERS
GROUP BY order_status
ORDER BY order_count DESC;

-- Pending orders awaiting fulfillment
SELECT 
    o.order_id,
    c.first_name || ' ' || c.last_name AS customer,
    p.product_name,
    o.quantity,
    o.total_amount,
    o.order_date,
    TRUNC(SYSDATE - o.order_date) AS days_pending
FROM ORDERS o
JOIN CUSTOMERS c ON o.customer_id = c.customer_id
JOIN PRODUCTS p ON o.product_id = p.product_id
WHERE o.order_status IN ('Pending', 'Confirmed')
ORDER BY o.order_date;

PROMPT;
PROMPT ========================================
PROMPT Sample queries execution complete
PROMPT ========================================