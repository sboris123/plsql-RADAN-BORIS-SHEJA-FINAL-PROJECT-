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
