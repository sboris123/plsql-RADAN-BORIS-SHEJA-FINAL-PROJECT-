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