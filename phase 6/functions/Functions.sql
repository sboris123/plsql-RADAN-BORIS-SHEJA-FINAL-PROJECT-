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
