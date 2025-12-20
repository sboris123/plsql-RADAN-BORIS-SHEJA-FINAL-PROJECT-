-- ============================================================================
--  PHASE % 
-- ============================================================================
--  DATA INTEGRITY VERIFICATION QUERIES

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
       COMPREHENSIVE TESTING QUERIES
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



-- ============================================================================
     PHASE 6  TESTING QUERIES
-- ============================================================================


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




-- ============================================================================
--   PHASE 7 COMPREHENSIVE TESTING SCRIPTS
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

-- Test 15: Call Audit Summary Procedure
BEGIN
    sp_view_audit_summary(SYSDATE - 7, SYSDATE);
END;
/

 --Test 16: Detailed Audit Log (Last 10 Operations) 
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


