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




