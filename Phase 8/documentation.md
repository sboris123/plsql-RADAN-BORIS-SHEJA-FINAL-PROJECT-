#  Documentation Package

---

## 1. INSTALLATION GUIDE (installation_guide.md)

# Installation Guide
## Automated Customer Order Validation System



---

## Prerequisites

### System Requirements
- **Operating System:** Windows 11
- **RAM:** 16GB
- **Disk Space:** 250GB
- **Database:** Oracle Database 21c
- **Client:** Oracle SQL Developer

### User Permissions Required
- CREATE TABLE
- CREATE SEQUENCE
- CREATE PROCEDURE
- CREATE FUNCTION
- CREATE TRIGGER
- CREATE VIEW
- INSERT, UPDATE, DELETE on own schema
- EXECUTE on DBMS packages

---



### Step 2: Database Connection Setup

#### Option A: Using SQL Developer

1. **Open SQL Developer**
2. **Create New Connection**
   - Connection Name: DB
   - Username: `system`
   - Password: `1234`
   - Hostname: `localhost`
   - Port: `1521`
   - Service Name: `tue_29096_boris_acovs_db`
3. **Test Connection** - Click "Test" button
4. **Save & Connect**

#### Option B: Using SQL*Plus

```bash

 local installation
sqlplus username/password
```

### Step 3: Verify Database Access

```sql
-- Check current user
SELECT USER FROM DUAL;

-- Check available privileges
SELECT * FROM USER_SYS_PRIVS;

-- Check tablespace quota
SELECT tablespace_name, bytes/1024/1024 AS MB_USED, max_bytes/1024/1024 AS MB_QUOTA
FROM USER_TS_QUOTAS;
```

**Expected Results:**
- User should match your login
- Should have CREATE TABLE, CREATE PROCEDURE privileges
- Should have at least 500MB quota available

### Step 4: Execute Installation Scripts

**IMPORTANT:** Execute scripts in the exact order shown below.

#### 4.1 Create Tables

```sql
-- In SQL Developer or SQL*Plus

```
- [create_tables.sql](https://github.com/sboris123/plsql-RADAN-BORIS-SHEJA-FINAL-PROJECT-/blob/4b80a62893f855b2fcaaabd7c7aa0057905d523d/Phase%205/Create%20tables.sql)
**Verification:**
```sql
SELECT COUNT(*) AS table_count FROM USER_TABLES;
-- Expected: 14 tables
```

#### 4.2 Create Sequences

```sql
@database/scripts/02_create_sequences.sql
```

**Verification:**
```sql
SELECT COUNT(*) AS sequence_count FROM USER_SEQUENCES;
-- Expected: 14 sequences
```

#### 4.3 Create Indexes

```sql
@database/scripts/03_create_indexes.sql
```

**Verification:**
```sql
SELECT COUNT(*) AS index_count FROM USER_INDEXES WHERE TABLE_OWNER = USER;
-- Expected: 15+ indexes (excluding PK indexes)
```

#### 4.4 Insert Sample Data

```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
@database/scripts/04_insert_data.sql
```

**Verification:**
```sql
SELECT 'CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM CUSTOMERS
UNION ALL SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS
UNION ALL SELECT 'USER_ACCOUNTS', COUNT(*) FROM USER_ACCOUNTS
UNION ALL SELECT 'ORDERS', COUNT(*) FROM ORDERS;

-- Expected: 
-- CUSTOMERS: 200
-- PRODUCTS: 150
-- USER_ACCOUNTS: 47
-- ORDERS: 500
```

#### 4.5 Create Functions

```sql
@database/scripts/05_functions.sql
```

**Verification:**
```sql
SELECT object_name, status FROM USER_OBJECTS 
WHERE object_type = 'FUNCTION' 
ORDER BY object_name;

-- Expected: 5 functions, all with status 'VALID'
```

#### 4.6 Create Procedures

```sql
@database/scripts/06_procedures.sql
```

**Verification:**
```sql
SELECT object_name, status FROM USER_OBJECTS 
WHERE object_type = 'PROCEDURE' 
ORDER BY object_name;

-- Expected: 5 procedures, all with status 'VALID'
```

#### 4.7 Create Packages

```sql
@database/scripts/07_packages.sql
```

**Verification:**
```sql
SELECT object_name, object_type, status FROM USER_OBJECTS 
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
ORDER BY object_type, object_name;

-- Expected: 1 package spec + 1 package body, both 'VALID'
```

#### 4.8 Create Triggers

```sql
@database/scripts/08_triggers.sql
```

**Verification:**
```sql
SELECT trigger_name, status, triggering_event, table_name 
FROM USER_TRIGGERS 
ORDER BY trigger_name;

-- Expected: 9 triggers, all with status 'ENABLED'
```

#### 4.9 Create Views

```sql
@database/scripts/09_views.sql
```

**Verification:**
```sql
SELECT view_name FROM USER_VIEWS ORDER BY view_name;

-- Expected: 4 views
```

### Step 5: Run Tests

```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
@database/scripts/10_test_scripts.sql
```

**Expected Output:**
- All tests should display "✓ PASS" or "✓ SUCCESS"
- No errors should be raised
- Audit logs should show operation attempts

### Step 6: Verify Installation

```sql
-- Complete system check
SELECT 
    (SELECT COUNT(*) FROM USER_TABLES) AS tables,
    (SELECT COUNT(*) FROM USER_SEQUENCES) AS sequences,
    (SELECT COUNT(*) FROM USER_INDEXES WHERE TABLE_OWNER = USER) AS indexes,
    (SELECT COUNT(*) FROM USER_OBJECTS WHERE object_type = 'FUNCTION') AS functions,
    (SELECT COUNT(*) FROM USER_OBJECTS WHERE object_type = 'PROCEDURE') AS procedures,
    (SELECT COUNT(*) FROM USER_OBJECTS WHERE object_type = 'PACKAGE') AS packages,
    (SELECT COUNT(*) FROM USER_TRIGGERS WHERE STATUS = 'ENABLED') AS triggers,
    (SELECT COUNT(*) FROM USER_VIEWS) AS views
FROM DUAL;

-- Expected:
-- TABLES: 14
-- SEQUENCES: 14
-- INDEXES: 15+
-- FUNCTIONS: 5
-- PROCEDURES: 5
-- PACKAGES: 1
-- TRIGGERS: 9
-- VIEWS: 4
```

---

## Post-Installation Configuration

### 1. Add Public Holidays

```sql
DECLARE
    v_status VARCHAR2(100);
    v_message VARCHAR2(500);
BEGIN
    -- Add your country's holidays
    sp_add_public_holiday(
        p_holiday_date => DATE '2025-01-01',
        p_holiday_name => 'New Year Day',
        p_holiday_type => 'National',
        p_is_recurring => 'Y',
        p_created_by => 3001, -- Admin user ID
        p_status => v_status,
        p_message => v_message
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Message: ' || v_message);
END;
/
```

### 2. Configure System Settings

```sql
-- Update system configuration values
UPDATE SYSTEM_CONFIGURATION 
SET config_value = '0.18' 
WHERE config_key = 'TAX_RATE';

UPDATE SYSTEM_CONFIGURATION 
SET config_value = '1000' 
WHERE config_key = 'MAX_ORDER_QUANTITY';

COMMIT;
```

### 3. Create Additional Users (Optional)

```sql
INSERT INTO USER_ACCOUNTS (
    user_id, username, password_hash, full_name, 
    email, role, account_status
) VALUES (
    seq_user.NEXTVAL,
    'your_username',
    'your_hashed_password',
    'Your Full Name',
    'your.email@company.com',
    'Sales',
    'Active'
);

COMMIT;
```

---

## Uninstallation

### Option 1: Drop All Objects

```sql
@database/scripts/99_cleanup.sql
```

### Option 2: Manual Cleanup

```sql
-- Drop triggers
BEGIN
    FOR t IN (SELECT trigger_name FROM USER_TRIGGERS) LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || t.trigger_name;
    END LOOP;
END;
/

-- Drop views
BEGIN
    FOR v IN (SELECT view_name FROM USER_VIEWS) LOOP
        EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
    END LOOP;
END;
/

-- Drop packages
BEGIN
    FOR p IN (SELECT object_name FROM USER_OBJECTS WHERE object_type = 'PACKAGE') LOOP
        EXECUTE IMMEDIATE 'DROP PACKAGE ' || p.object_name;
    END LOOP;
END;
/

-- Drop procedures
BEGIN
    FOR p IN (SELECT object_name FROM USER_OBJECTS WHERE object_type = 'PROCEDURE') LOOP
        EXECUTE IMMEDIATE 'DROP PROCEDURE ' || p.object_name;
    END LOOP;
END;
/

-- Drop functions
BEGIN
    FOR f IN (SELECT object_name FROM USER_OBJECTS WHERE object_type = 'FUNCTION') LOOP
        EXECUTE IMMEDIATE 'DROP FUNCTION ' || f.object_name;
    END LOOP;
END;
/

-- Drop sequences
BEGIN
    FOR s IN (SELECT sequence_name FROM USER_SEQUENCES) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- Drop tables
BEGIN
    FOR t IN (SELECT table_name FROM USER_TABLES) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
END;
/
```

---

## Troubleshooting Installation Issues

### Issue 1: ORA-01031: insufficient privileges

**Cause:** User lacks required permissions

**Solution:**
```sql
-- Connect as SYSDBA
GRANT CREATE TABLE TO your_username;
GRANT CREATE SEQUENCE TO your_username;
GRANT CREATE PROCEDURE TO your_username;
GRANT CREATE TRIGGER TO your_username;
GRANT CREATE VIEW TO your_username;
GRANT UNLIMITED TABLESPACE TO your_username;
```

### Issue 2: ORA-00942: table or view does not exist

**Cause:** Tables not created or wrong schema

**Solution:**
```sql
-- Check current schema
SELECT USER FROM DUAL;

-- Check if tables exist
SELECT COUNT(*) FROM USER_TABLES;

-- If zero, run table creation script again
@database/scripts/01_create_tables.sql
```

### Issue 3: ORA-04098: trigger is invalid and failed re-validation

**Cause:** Trigger references objects that don't exist

**Solution:**
```sql
-- Check trigger errors
SELECT * FROM USER_ERRORS WHERE type = 'TRIGGER';

-- Recompile triggers
ALTER TRIGGER trigger_name COMPILE;

-- Or recompile all
BEGIN
    FOR t IN (SELECT trigger_name FROM USER_TRIGGERS) LOOP
        EXECUTE IMMEDIATE 'ALTER TRIGGER ' || t.trigger_name || ' COMPILE';
    END LOOP;
END;
/
```

### Issue 4: Script runs but no output visible

**Cause:** SERVEROUTPUT not enabled

**Solution:**
```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
-- Then re-run your script
```

### Issue 5: ORA-01653: unable to extend table

**Cause:** Insufficient tablespace quota

**Solution:**
```sql
-- Check quota
SELECT * FROM USER_TS_QUOTAS;

-- As DBA, increase quota
ALTER USER your_username QUOTA UNLIMITED ON USERS;
```

---

## Verification Checklist

- [ ] All 14 tables created
- [ ] All 14 sequences created
- [ ] All indexes created (15+)
- [ ] Sample data loaded (3500+ records)
- [ ] 5 functions compiled successfully
- [ ] 5 procedures compiled successfully
- [ ] 1 package created with body
- [ ] 9 triggers enabled
- [ ] 4 BI views created
- [ ] All test scripts pass
- [ ] No INVALID objects in USER_OBJECTS
- [ ] Audit logs are recording operations

**Check for INVALID objects:**
```sql
SELECT object_type, object_name, status 
FROM USER_OBJECTS 
WHERE status = 'INVALID';

-- Should return no rows
```

---

## Next Steps

After successful installation:

1. **Review User Guide** - Learn how to use the system
2. **Run Sample Queries** - Try example queries in `queries/` folder
3. **Explore Dashboards** - Review BI dashboard specs
4. **Customize Configuration** - Adjust settings for your needs
5. **Add Your Data** - Start using the system with real data

---

## Support & Contact

**Author:** SHEJA RADAN BORIS  
**Student ID:** 29096  
**Email:** boris.sheja@student.auca.ac.rw  
**GitHub:** https://github.com/shejaradan/order-validation-system

**Report Issues:**
- Create GitHub Issue: https://github.com/shejaradan/order-validation-system/issues
- Email with "Order System Issue" in subject line

---

## Troubleshooting Guide (troubleshooting.md)

# Troubleshooting Guide
## Common Issues and Solutions

---

## Database Connection Issues

### Problem: Cannot connect to Oracle database

**Symptoms:**
- "ORA-12154: TNS:could not resolve the connect identifier specified"
- "ORA-12541: TNS:no listener"

**Solutions:**

1. **Check TNS Names**
```bash
# Windows
echo %ORACLE_HOME%\network\admin\tnsnames.ora

# Linux/Mac
echo $ORACLE_HOME/network/admin/tnsnames.ora

# Verify entry exists for your database
```

2. **Test TNS Ping**
```bash
tnsping ORCL
```

3. **Check Listener Status**
```bash
lsnrctl status
```

4. **Restart Listener**
```bash
lsnrctl stop
lsnrctl start
```

5. **Try Direct Connection**
```sql
sqlplus username/password@//hostname:1521/service_name
```

---

## Compilation Errors

### Problem: Procedures/Functions show INVALID status

**Check Errors:**
```sql
SELECT * FROM USER_ERRORS 
WHERE name = 'YOUR_PROCEDURE_NAME'
ORDER BY sequence;
```

**Common Causes & Solutions:**

1. **Missing Dependencies**
```sql
-- Check what the object depends on
SELECT * FROM USER_DEPENDENCIES 
WHERE name = 'YOUR_PROCEDURE_NAME';

-- Ensure all referenced objects exist and are valid
```

2. **Syntax Errors**
- Review error message line/column
- Check for missing semicolons
- Verify keyword spelling
- Ensure proper quote matching

3. **Recompile Object**
```sql
ALTER PROCEDURE procedure_name COMPILE;
ALTER FUNCTION function_name COMPILE;
ALTER PACKAGE package_name COMPILE;
ALTER TRIGGER trigger_name COMPILE;
```

4. **Recompile All Invalid Objects**
```sql
BEGIN
    DBMS_UTILITY.COMPILE_SCHEMA(
        schema => USER,
        compile_all => FALSE  -- Only invalid objects
    );
END;
/
```

---

## Data Issues

### Problem: No data returned from queries

**Diagnosis:**
```sql
-- Check if tables have data
SELECT table_name, num_rows 
FROM USER_TABLES 
ORDER BY table_name;

-- If num_rows is null, gather statistics
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(USER);
END;
/
```

**Solutions:**

1. **Verify Data Exists**
```sql
SELECT COUNT(*) FROM CUSTOMERS;
SELECT COUNT(*) FROM PRODUCTS;
SELECT COUNT(*) FROM ORDERS;
```

2. **Check Filters**
- Remove WHERE clauses temporarily
- Check date formats
- Verify status values match exactly

3. **Re-insert Data**
```sql
-- If needed, truncate and reload
TRUNCATE TABLE CUSTOMERS CASCADE;
@database/scripts/04_insert_data.sql
```

---

## Trigger Issues

### Problem: Trigger blocking operations unexpectedly

**Symptoms:**
- "OPERATION DENIED: Cannot perform INSERT on WEEKDAYS"
- Operations blocked even on weekends

**Diagnosis:**
```sql
-- Check current day
SELECT 
    SYSDATE AS current_date,
    TO_CHAR(SYSDATE, 'DAY') AS day_name,
    TO_CHAR(SYSDATE, 'D') AS day_number,
    CASE 
        WHEN TO_CHAR(SYSDATE, 'D') BETWEEN 2 AND 6 THEN 'WEEKDAY'
        ELSE 'WEEKEND'
    END AS day_type
FROM DUAL;

-- Check if today is a holiday
SELECT * FROM PUBLIC_HOLIDAYS 
WHERE TRUNC(holiday_date) = TRUNC(SYSDATE);

-- Check trigger status
SELECT trigger_name, status, trigger_type, triggering_event, table_name
FROM USER_TRIGGERS
WHERE table_name = 'ORDERS';
```

**Solutions:**

1. **Temporarily Disable Trigger**
```sql
ALTER TRIGGER trg_orders_insert_restriction DISABLE;

-- Perform your operation

ALTER TRIGGER trg_orders_insert_restriction ENABLE;
```

2. **Check Date/Time Settings**
```sql
-- Verify session date
SELECT SYSDATE FROM DUAL;

-- If incorrect, check NLS settings
SELECT * FROM NLS_SESSION_PARAMETERS;
```

3. **Review Holiday Table**
```sql
-- Check for test holidays
SELECT * FROM PUBLIC_HOLIDAYS 
WHERE holiday_date >= SYSDATE - 7
ORDER BY holiday_date;

-- Delete test holidays if needed
DELETE FROM PUBLIC_HOLIDAYS 
WHERE holiday_name LIKE 'Test%';
COMMIT;
```

---

## Performance Issues

### Problem: Queries running slowly

**Diagnosis:**
```sql
-- Check execution plan
EXPLAIN PLAN FOR
SELECT * FROM ORDERS o
JOIN CUSTOMERS c ON o.customer_id = c.customer_id;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Check table statistics
SELECT table_name, num_rows, last_analyzed 
FROM USER_TABLES;

-- Check index usage
SELECT index_name, table_name, uniqueness, status 
FROM USER_INDEXES;
```

**Solutions:**

1. **Gather Fresh Statistics**
```sql
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'ORDERS',
        cascade => TRUE
    );
END;
/
```

2. **Add Missing Indexes**
```sql
-- Example: If queries on order_date are slow
CREATE INDEX idx_orders_date ON ORDERS(order_date);
```

3. **Optimize Query**
```sql
-- Use specific columns instead of SELECT *
-- Add appropriate WHERE clauses
-- Use FETCH FIRST n ROWS instead of ROWNUM
```

---

## Audit Log Issues

### Problem: Audit logs not being created

**Diagnosis:**
```sql
-- Check if audit table exists
SELECT COUNT(*) FROM OPERATION_AUDIT_LOG;

-- Check if triggers are enabled
SELECT trigger_name, status 
FROM USER_TRIGGERS 
WHERE trigger_name LIKE '%AUDIT%';

-- Try manual insert
DECLARE
    v_result NUMBER;
BEGIN
    v_result := fn_log_operation_audit(
        p_operation_type => 'INSERT',
        p_table_name => 'TEST',
        p_operation_status => 'ALLOWED'
    );
    
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_result);
END;
/
```

**Solutions:**

1. **Enable Triggers**
```sql
ALTER TRIGGER trg_orders_insert_restriction ENABLE;
```

2. **Check Autonomous Transaction**
```sql
-- Verify function has PRAGMA AUTONOMOUS_TRANSACTION
SELECT text FROM USER_SOURCE 
WHERE name = 'FN_LOG_OPERATION_AUDIT'
AND text LIKE '%PRAGMA%';
```

3. **Grant Necessary Privileges**
```sql
-- As SYSDBA if needed
GRANT EXECUTE ON DBMS_UTILITY TO your_username;
```

---

## Sequence Issues

### Problem: "Sequence does not exist" error

**Diagnosis:**
```sql
-- Check if sequences exist
SELECT sequence_name, last_number 
FROM USER_SEQUENCES 
ORDER BY sequence_name;

-- Check sequence current value
SELECT seq_order.NEXTVAL FROM DUAL;
```

**Solutions:**

1. **Create Missing Sequence**
```sql
CREATE SEQUENCE seq_order START WITH 4001 INCREMENT BY 1;
```

2. **Reset Sequence**
```sql
-- Drop and recreate
DROP SEQUENCE seq_order;
CREATE SEQUENCE seq_order START WITH 4001 INCREMENT BY 1;
```

---

## Package Issues

### Problem: Package body and specification out of sync

**Symptoms:**
- "PLS-00304: cannot compile body without its specification"
- Package shows as INVALID

**Solutions:**

1. **Recompile Specification First**
```sql
ALTER PACKAGE pkg_order_management COMPILE SPECIFICATION;
ALTER PACKAGE pkg_order_management COMPILE BODY;
```

2. **Check for Mismatches**
```sql
-- Compare spec and body
SELECT text FROM USER_SOURCE 
WHERE name = 'PKG_ORDER_MANAGEMENT' 
AND type = 'PACKAGE'
ORDER BY line;

SELECT text FROM USER_SOURCE 
WHERE name = 'PKG_ORDER_MANAGEMENT' 
AND type = 'PACKAGE BODY'
ORDER BY line;
```

3. **Recreate Package**
```sql
DROP PACKAGE pkg_order_management;
@database/scripts/07_packages.sql
```

---

## Common Error Codes

| Error Code | Meaning | Quick Fix |
|------------|---------|-----------|
| ORA-00001 | Unique constraint violated | Check for duplicate values |
| ORA-00904 | Invalid identifier | Column name misspelled |
| ORA-00942 | Table/view does not exist | Check schema and table name |
| ORA-01400 | Cannot insert NULL | Column requires NOT NULL |
| ORA-01722 | Invalid number | Data type mismatch |
| ORA-02291 | Integrity constraint violated (FK) | Referenced record doesn't exist |
| ORA-04091 | Mutating table | Use compound trigger or autonomous transaction |
| ORA-06502 | Numeric or value error | Data too large for variable |
| ORA-20001+ | Application error | Custom error from triggers/procedures |

---

## Best Practices to Avoid Issues

1. **Always Set SERVEROUTPUT ON**
```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
```

2. **Use BEGIN-END for Testing**
```sql
BEGIN
    -- Your test code here
    NULL;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
```

3. **Check Object Status Regularly**
```sql
-- Daily health check
SELECT object_type, COUNT(*) AS count, 
       SUM(CASE WHEN status='VALID' THEN 1 ELSE 0 END) AS valid,
       SUM(CASE WHEN status='INVALID' THEN 1 ELSE 0 END) AS invalid
FROM USER_OBJECTS
GROUP BY object_type
ORDER BY object_type;
```

4. **Keep Backups**
```sql
-- Export schema before major changes
expdp username/password DIRECTORY=backup_dir DUMPFILE=backup.dmp
```

5. **Test on Sample Data First**
- Always test procedures on small datasets
- Use ROLLBACK during testing
- Only COMMIT when verified

---

## Getting Help

If you continue to experience issues:

1. **Check Error Messages**
   - Copy full error text
   - Note the error code (ORA-xxxxx)

2. **Review Logs**
```sql
SELECT * FROM OPERATION_AUDIT_LOG 
WHERE operation_status = 'ERROR'
ORDER BY operation_date DESC
FETCH FIRST 10 ROWS ONLY;
```

3. **Gather Diagnostics**
```sql
-- Run full system check
@database/scripts/system_health_check.sql
```

4. **Contact Support**
   - Email: boris.sheja@student.auca.ac.rw
   - GitHub Issues: https://github.com/shejaradan/order-validation-system/issues
   - Include: Error message, what you were doing, Oracle version

---

**Last Updated:** December 2024  
**Version:** 1.0
