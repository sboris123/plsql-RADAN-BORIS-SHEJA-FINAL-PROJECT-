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




-- AUDIT TRIGGERS

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
