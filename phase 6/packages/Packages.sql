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