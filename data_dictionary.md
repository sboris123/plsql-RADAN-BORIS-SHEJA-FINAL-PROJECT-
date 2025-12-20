# Data Dictionary - Automated Customer Order Validation System

**Project:** Order Validation System  
**Author:** SHEJA RADAN BORIS (29096)  
**Database:** Oracle 19c  
**Last Updated:** December 2024

---

## Table of Contents

1. [CUSTOMERS](#1-customers)
2. [PRODUCTS](#2-products)
3. [USER_ACCOUNTS](#3-user_accounts)
4. [ORDERS](#4-orders)
5. [ORDER_ERROR_LOG](#5-order_error_log)
6. [USER_SESSIONS](#6-user_sessions)
7. [ORDER_STATUS_HISTORY](#7-order_status_history)
8. [CUSTOMER_FEEDBACK](#8-customer_feedback)
9. [INVENTORY_AUDIT](#9-inventory_audit)
10. [PAYMENT_TRANSACTIONS](#10-payment_transactions)
11. [SYSTEM_CONFIGURATION](#11-system_configuration)
12. [AUDIT_TRAIL](#12-audit_trail)
13. [PUBLIC_HOLIDAYS](#13-public_holidays)
14. [OPERATION_AUDIT_LOG](#14-operation_audit_log)

---

## 1. CUSTOMERS

**Purpose:** Stores customer information and manages customer accounts for the e-commerce platform.

**Estimated Rows:** 200+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| customer_id | NUMBER(10) | PK, NOT NULL | Unique customer identifier | 1001, 1002, 1003 |
| first_name | VARCHAR2(50) | NOT NULL | Customer first name | James, Mary, John |
| last_name | VARCHAR2(50) | NOT NULL | Customer last name | Smith, Johnson, Williams |
| email | VARCHAR2(100) | UNIQUE, NOT NULL, CHECK (email format) | Customer email address | john.smith@email.com |
| phone | VARCHAR2(20) | NULL | Contact phone number | +250781234567 |
| address | VARCHAR2(200) | NULL | Street address | Street 15, Building 3 |
| city | VARCHAR2(50) | NULL | City of residence | Kigali, Musanze, Rubavu |
| country | VARCHAR2(50) | DEFAULT 'Rwanda' | Country | Rwanda, Kenya, Uganda |
| postal_code | VARCHAR2(10) | NULL | Postal/ZIP code | 00100, 00200 |
| registration_date | DATE | DEFAULT SYSDATE, NOT NULL | Account creation date | 2024-01-15 |
| customer_status | VARCHAR2(20) | DEFAULT 'Active', CHECK (Active/Inactive/Suspended) | Account status | Active, Suspended |
| credit_limit | NUMBER(10,2) | DEFAULT 5000, CHECK (>= 0) | Maximum credit allowed | 5000.00, 10000.00 |
| total_orders | NUMBER(10) | DEFAULT 0, CHECK (>= 0) | Lifetime order count | 0, 15, 42 |

**Indexes:**
- `idx_customer_email` on email
- `idx_customer_status` on customer_status
- `idx_customer_country` on country

**Business Rules:**
- Email must be unique and follow standard email format
- Credit limit cannot be negative
- Default credit limit is 5000 RWF
- Only Active customers can place orders

---

## 2. PRODUCTS

**Purpose:** Manages product catalog including inventory levels and pricing.

**Estimated Rows:** 150+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| product_id | NUMBER(10) | PK, NOT NULL | Unique product identifier | 2001, 2002, 2003 |
| product_name | VARCHAR2(100) | NOT NULL | Product name/title | Premium Electronics Item 1 |
| category | VARCHAR2(50) | NOT NULL | Product category | Electronics, Clothing, Food |
| description | VARCHAR2(500) | NULL | Detailed product description | High quality product... |
| unit_price | NUMBER(10,2) | NOT NULL, CHECK (> 0) | Price per unit in RWF | 1500.00, 25000.00 |
| stock_quantity | NUMBER(10) | DEFAULT 0, CHECK (>= 0) | Available inventory count | 0, 50, 1000 |
| reorder_level | NUMBER(10) | DEFAULT 10, CHECK (>= 0) | Minimum stock before reorder | 10, 20, 50 |
| supplier_name | VARCHAR2(100) | NULL | Supplier/vendor name | Supplier 1, Supplier 2 |
| product_status | VARCHAR2(20) | DEFAULT 'Available', CHECK (Available/Discontinued/Out of Stock) | Product availability | Available, Out of Stock |
| created_date | DATE | DEFAULT SYSDATE, NOT NULL | Product creation date | 2024-01-01 |
| last_updated | DATE | DEFAULT SYSDATE | Last modification date | 2024-11-20 |

**Indexes:**
- `idx_product_category` on category
- `idx_product_status` on product_status
- `idx_product_stock` on stock_quantity

**Business Rules:**
- Unit price must be positive
- Stock quantity cannot be negative
- Product status auto-updates to 'Out of Stock' when quantity = 0
- Only 'Available' products can be ordered

---

## 3. USER_ACCOUNTS

**Purpose:** Manages system users who process orders and perform system operations.

**Estimated Rows:** 47+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| user_id | NUMBER(10) | PK, NOT NULL | Unique user identifier | 3001, 3002, 3003 |
| username | VARCHAR2(50) | UNIQUE, NOT NULL | Login username | admin1, sales1, manager1 |
| password_hash | VARCHAR2(100) | NOT NULL | Hashed password | hash_admin1 |
| full_name | VARCHAR2(100) | NOT NULL | User full name | John Administrator |
| email | VARCHAR2(100) | UNIQUE, NOT NULL | User email | john.admin@company.com |
| role | VARCHAR2(30) | DEFAULT 'Sales', CHECK (Admin/Sales/Manager/Warehouse/Customer Service) | User role/permission | Admin, Sales, Manager |
| account_status | VARCHAR2(20) | DEFAULT 'Active', CHECK (Active/Inactive/Locked) | Account status | Active, Locked |
| created_date | DATE | DEFAULT SYSDATE, NOT NULL | Account creation date | 2024-01-01 |
| last_login | DATE | NULL | Last successful login | 2024-12-04 10:30:00 |
| failed_login_attempts | NUMBER(2) | DEFAULT 0, CHECK (>= 0) | Failed login counter | 0, 1, 3 |

**Indexes:**
- None (small table, PK and unique constraints sufficient)

**Business Rules:**
- Username and email must be unique
- Account locks after 3 failed login attempts
- Only Active users can perform operations
- Different roles have different permissions

---

## 4. ORDERS

**Purpose:** Core transaction table storing all customer orders.

**Estimated Rows:** 500+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| order_id | NUMBER(10) | PK, NOT NULL | Unique order identifier | 4001, 4002, 4003 |
| customer_id | NUMBER(10) | FK (CUSTOMERS), NOT NULL | Customer placing order | 1001, 1025, 1150 |
| product_id | NUMBER(10) | FK (PRODUCTS), NOT NULL | Product ordered | 2001, 2050, 2100 |
| user_id | NUMBER(10) | FK (USER_ACCOUNTS), NULL | User processing order | 3001, 3005, 3010 |
| quantity | NUMBER(10) | NOT NULL, CHECK (> 0) | Quantity ordered | 1, 5, 10 |
| unit_price | NUMBER(10,2) | NOT NULL, CHECK (> 0) | Price at time of order | 1500.00, 25000.00 |
| total_amount | NUMBER(10,2) | NOT NULL, CHECK (> 0) | Total order value | 7500.00, 125000.00 |
| order_date | DATE | DEFAULT SYSDATE, NOT NULL | Order creation timestamp | 2024-11-15 14:30:00 |
| order_status | VARCHAR2(30) | DEFAULT 'Pending', CHECK (Pending/Confirmed/Processing/Shipped/Delivered/Cancelled) | Current order status | Pending, Delivered |
| shipping_address | VARCHAR2(200) | NULL | Delivery address | Shipping address for order 1 |
| payment_status | VARCHAR2(20) | DEFAULT 'Pending', CHECK (Pending/Paid/Failed/Refunded) | Payment status | Pending, Paid |
| notes | VARCHAR2(500) | NULL | Additional order notes | Rush order, Gift wrap |

**Indexes:**
- `idx_order_customer` on customer_id
- `idx_order_product` on product_id
- `idx_order_date` on order_date
- `idx_order_status` on order_status

**Business Rules:**
- Total amount = quantity × unit_price
- Cannot delete orders (status changes to Cancelled instead)
- Stock deducted when order placed, restored if cancelled
- Triggers enforce weekday/holiday restrictions on DML

---

## 5. ORDER_ERROR_LOG

**Purpose:** Captures failed order attempts for troubleshooting and analysis.

**Estimated Rows:** 100+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| error_id | NUMBER(10) | PK, NOT NULL | Unique error log identifier | 5001, 5002, 5003 |
| customer_id | NUMBER(10) | FK (CUSTOMERS), NULL | Customer who attempted order | 1001, 1050, NULL |
| product_id | NUMBER(10) | FK (PRODUCTS), NULL | Product involved in error | 2001, 2050, NULL |
| quantity | NUMBER(10) | NULL | Attempted quantity | 1000, -5, 0 |
| error_message | VARCHAR2(500) | NOT NULL | Description of error | Invalid or inactive customer |
| error_date | DATE | DEFAULT SYSDATE, NOT NULL | When error occurred | 2024-11-20 10:15:30 |
| attempted_by | NUMBER(10) | FK (USER_ACCOUNTS), NULL | User who attempted operation | 3005, 3010 |
| error_type | VARCHAR2(50) | CHECK (Invalid Customer/Invalid Product/Insufficient Stock/Invalid Quantity/Business Rule Violation/System Error) | Error category | Insufficient Stock |

**Indexes:**
- `idx_error_date` on error_date
- `idx_error_type` on error_type

**Business Rules:**
- All failed order attempts must be logged
- Error messages must be clear and actionable
- Used for analytics and system improvement

---

## 6. USER_SESSIONS

**Purpose:** Tracks user login sessions for security and monitoring.

**Estimated Rows:** 300+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| session_id | NUMBER(10) | PK, NOT NULL | Unique session identifier | 6001, 6002, 6003 |
| user_id | NUMBER(10) | FK (USER_ACCOUNTS), NOT NULL | User who logged in | 3001, 3005, 3010 |
| login_time | TIMESTAMP | DEFAULT SYSTIMESTAMP, NOT NULL | Login timestamp | 2024-11-20 08:00:00.123 |
| logout_time | TIMESTAMP | NULL | Logout timestamp | 2024-11-20 17:30:00.456 |
| ip_address | VARCHAR2(45) | NULL | Client IP address | 192.168.1.100, 10.0.0.50 |
| session_status | VARCHAR2(20) | DEFAULT 'Active', CHECK (Active/Expired/Terminated) | Session state | Active, Expired |

**Indexes:**
- `idx_session_user` on user_id
- `idx_session_status` on session_status

**Business Rules:**
- Session timeout after 30 minutes of inactivity
- Multiple concurrent sessions allowed per user
- Used for security auditing and access control

---

## 7. ORDER_STATUS_HISTORY

**Purpose:** Maintains complete history of all order status changes.

**Estimated Rows:** 800+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| history_id | NUMBER(10) | PK, NOT NULL | Unique history record ID | 7001, 7002, 7003 |
| order_id | NUMBER(10) | FK (ORDERS), NOT NULL | Order being tracked | 4001, 4050, 4100 |
| old_status | VARCHAR2(30) | NULL | Previous status | Pending, Processing |
| new_status | VARCHAR2(30) | NOT NULL | New status | Confirmed, Shipped |
| changed_by | NUMBER(10) | FK (USER_ACCOUNTS), NULL | User who made change | 3005, 3010, 3015 |
| change_date | TIMESTAMP | DEFAULT SYSTIMESTAMP, NOT NULL | When change occurred | 2024-11-20 14:30:00.789 |
| remarks | VARCHAR2(500) | NULL | Additional comments | Order created, Payment received |

**Indexes:**
- None (relatively small table)

**Business Rules:**
- Every status change must be logged
- Provides complete audit trail for orders
- old_status is NULL for initial order creation

---

## 8. CUSTOMER_FEEDBACK

**Purpose:** Collects and manages customer feedback on delivered orders.

**Estimated Rows:** 200+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| feedback_id | NUMBER(10) | PK, NOT NULL | Unique feedback identifier | 8001, 8002, 8003 |
| order_id | NUMBER(10) | FK (ORDERS), NOT NULL | Order being reviewed | 4001, 4050, 4100 |
| customer_id | NUMBER(10) | FK (CUSTOMERS), NOT NULL | Customer providing feedback | 1001, 1025, 1050 |
| rating | NUMBER(1) | CHECK (BETWEEN 1 AND 5) | Star rating 1-5 | 1, 3, 5 |
| comment | VARCHAR2(1000) | NULL | Customer comments | Excellent service! |
| feedback_date | DATE | DEFAULT SYSDATE, NOT NULL | Feedback submission date | 2024-11-25 |
| response | VARCHAR2(1000) | NULL | Company response | Thank you for feedback |
| responded_by | NUMBER(10) | FK (USER_ACCOUNTS), NULL | User who responded | 3020, 3025 |
| response_date | DATE | NULL | Response timestamp | 2024-11-26 |

**Indexes:**
- None (small table)

**Business Rules:**
- Rating must be 1-5 stars
- Feedback only for Delivered or Cancelled orders
- Customer must own the order being reviewed

---

## 9. INVENTORY_AUDIT

**Purpose:** Tracks all inventory movements and stock adjustments.

**Estimated Rows:** 400+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| audit_id | NUMBER(10) | PK, NOT NULL | Unique audit record ID | 9001, 9002, 9003 |
| product_id | NUMBER(10) | FK (PRODUCTS), NOT NULL | Product being adjusted | 2001, 2050, 2100 |
| transaction_type | VARCHAR2(20) | NOT NULL, CHECK (Addition/Deduction/Adjustment/Return/Damage) | Type of inventory change | Addition, Deduction |
| quantity_change | NUMBER(10) | NOT NULL | Quantity added/removed | -5, +100, +10 |
| old_quantity | NUMBER(10) | NOT NULL | Stock before change | 50, 100, 0 |
| new_quantity | NUMBER(10) | NOT NULL | Stock after change | 45, 200, 10 |
| audit_date | TIMESTAMP | DEFAULT SYSTIMESTAMP, NOT NULL | When change occurred | 2024-11-20 16:45:00.123 |
| performed_by | NUMBER(10) | FK (USER_ACCOUNTS), NULL | User who made change | 3025, 3030 |
| reason | VARCHAR2(500) | NULL | Reason for change | Order placed, Stock damaged |
| reference_order_id | NUMBER(10) | FK (ORDERS), NULL | Related order if applicable | 4001, 4050, NULL |

**Indexes:**
- None (managed by warehouse team)

**Business Rules:**
- Every stock change must be audited
- new_quantity = old_quantity + quantity_change
- Negative quantity_change for deductions
- Critical for inventory reconciliation

---

## 10. PAYMENT_TRANSACTIONS

**Purpose:** Records all payment transactions and financial operations.

**Estimated Rows:** 450+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| transaction_id | NUMBER(10) | PK, NOT NULL | Unique transaction ID | 10001, 10002, 10003 |
| order_id | NUMBER(10) | FK (ORDERS), NOT NULL | Order being paid | 4001, 4050, 4100 |
| payment_method | VARCHAR2(30) | CHECK (Credit Card/Debit Card/Mobile Money/Bank Transfer/Cash/PayPal) | Payment type | Credit Card, Mobile Money |
| amount | NUMBER(10,2) | NOT NULL, CHECK (> 0) | Payment amount in RWF | 118000.00, 75000.00 |
| transaction_date | TIMESTAMP | DEFAULT SYSTIMESTAMP, NOT NULL | Transaction timestamp | 2024-11-20 10:30:00.456 |
| transaction_status | VARCHAR2(20) | DEFAULT 'Pending', CHECK (Pending/Completed/Failed/Refunded) | Transaction outcome | Completed, Failed |
| payment_reference | VARCHAR2(100) | UNIQUE | Unique payment reference | PAY2024120400012345 |
| gateway_response | VARCHAR2(500) | NULL | Payment gateway message | Payment successful |
| processed_by | NUMBER(10) | FK (USER_ACCOUNTS), NULL | User who processed | 3010, 3015 |

**Indexes:**
- `idx_payment_order` on order_id
- `idx_payment_status` on transaction_status

**Business Rules:**
- Amount must match order total
- Payment reference must be unique
- Failed payments are logged for reconciliation
- All financial transactions audited

---

## 11. SYSTEM_CONFIGURATION

**Purpose:** Stores system-wide settings and business rules.

**Estimated Rows:** 20+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| config_id | NUMBER(10) | PK, NOT NULL | Unique config identifier | 11001, 11002, 11003 |
| config_key | VARCHAR2(100) | UNIQUE, NOT NULL | Configuration parameter name | TAX_RATE, CURRENCY |
| config_value | VARCHAR2(500) | NOT NULL | Configuration value | 0.18, RWF, 1000 |
| description | VARCHAR2(500) | NULL | What the config does | VAT tax rate (18%) |
| data_type | VARCHAR2(20) | CHECK (String/Number/Boolean/Date) | Value data type | Number, String |
| last_updated | TIMESTAMP | DEFAULT SYSTIMESTAMP, NOT NULL | Last modification time | 2024-11-20 |
| updated_by | NUMBER(10) | FK (USER_ACCOUNTS), NULL | Who updated config | 3001, 3002 |

**Indexes:**
- None (very small table)

**Business Rules:**
- config_key must be unique
- Only administrators can modify
- Used by procedures to get business rules
- Changes are audited

**Common Configurations:**
- MIN_STOCK_THRESHOLD: 10
- MAX_ORDER_QUANTITY: 1000
- TAX_RATE: 0.18
- CURRENCY: RWF
- AUTO_APPROVE_THRESHOLD: 5000
- SESSION_TIMEOUT_MINUTES: 30
- MAX_FAILED_LOGINS: 3

---

## 12. AUDIT_TRAIL

**Purpose:** General-purpose audit log for all table changes.

**Estimated Rows:** 300+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| audit_id | NUMBER(10) | PK, NOT NULL | Unique audit identifier | 12001, 12002, 12003 |
| table_name | VARCHAR2(50) | NOT NULL | Table being modified | CUSTOMERS, PRODUCTS |
| operation | VARCHAR2(10) | CHECK (INSERT/UPDATE/DELETE) | Type of operation | INSERT, UPDATE |
| record_id | NUMBER(10) | NOT NULL | ID of affected record | 1001, 2050, 4100 |
| old_values | CLOB | NULL | JSON of old values | {"status":"Active"} |
| new_values | CLOB | NULL | JSON of new values | {"status":"Suspended"} |
| performed_by | NUMBER(10) | FK (USER_ACCOUNTS), NULL | User who made change | 3001, 3005 |
| operation_date | TIMESTAMP | DEFAULT SYSTIMESTAMP, NOT NULL | When change occurred | 2024-11-20 15:00:00.789 |
| ip_address | VARCHAR2(45) | NULL | Client IP address | 192.168.1.50 |

**Indexes:**
- None (general audit table)

**Business Rules:**
- All critical table changes logged
- Old and new values stored as JSON
- Used for compliance and recovery
- IP address captured for security

---

## 13. PUBLIC_HOLIDAYS

**Purpose:** Manages public holidays for business rule enforcement.

**Estimated Rows:** 20+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| holiday_id | NUMBER(10) | PK, NOT NULL | Unique holiday identifier | 1, 2, 3 |
| holiday_date | DATE | NOT NULL, UNIQUE | Date of holiday | 2025-01-01, 2025-07-04 |
| holiday_name | VARCHAR2(100) | NOT NULL | Name of holiday | New Year Day, Independence Day |
| holiday_type | VARCHAR2(50) | CHECK (National/Religious/Cultural/Bank Holiday) | Holiday category | National, Religious |
| is_recurring | CHAR(1) | DEFAULT 'N', CHECK (Y/N) | Repeats annually | Y, N |
| created_date | DATE | DEFAULT SYSDATE | When holiday added | 2024-11-01 |
| created_by | NUMBER(10) | FK (USER_ACCOUNTS), NULL | Admin who added | 3001, 3002 |

**Indexes:**
- `idx_holiday_date` on holiday_date

**Business Rules:**
- Holiday date must be unique
- Used by triggers to block operations
- Rwanda national holidays pre-loaded
- Only admins can manage holidays

---

## 14. OPERATION_AUDIT_LOG

**Purpose:** Comprehensive audit log for all DML operations with restriction enforcement.

**Estimated Rows:** 500+

| Column Name | Data Type | Constraints | Purpose | Sample Values |
|-------------|-----------|-------------|---------|---------------|
| audit_log_id | NUMBER(10) | PK, NOT NULL | Unique audit log identifier | 1, 2, 3 |
| operation_type | VARCHAR2(20) | NOT NULL, CHECK (INSERT/UPDATE/DELETE) | DML operation type | INSERT, UPDATE |
| table_name | VARCHAR2(50) | NOT NULL | Table being accessed | ORDERS, PRODUCTS |
| operation_date | TIMESTAMP | DEFAULT SYSTIMESTAMP, NOT NULL | Operation timestamp | 2024-11-20 10:30:00.123 |
| operation_day | VARCHAR2(20) | NULL | Day of week | MONDAY, SATURDAY |
| is_weekend | CHAR(1) | CHECK (Y/N) | Weekend flag | Y, N |
| is_holiday | CHAR(1) | CHECK (Y/N) | Holiday flag | Y, N |
| holiday_name | VARCHAR2(100) | NULL | Holiday name if applicable | Independence Day, NULL |
| operation_status | VARCHAR2(20) | CHECK (ALLOWED/DENIED/ERROR) | Operation outcome | ALLOWED, DENIED |
| denial_reason | VARCHAR2(500) | NULL | Why operation was denied | Cannot perform INSERT on WEEKDAYS |
| user_session | VARCHAR2(100) | NULL | Database session user | SYSTEM, HR_USER |
| os_user | VARCHAR2(100) | NULL | Operating system user | administrator, boris |
| machine_name | VARCHAR2(100) | NULL | Client machine hostname | DESKTOP-ABC123 |
| ip_address | VARCHAR2(45) | NULL | Client IP address | 192.168.1.100 |
| record_id | NUMBER(10) | NULL | ID of affected record | 4001, 2050 |
| old_values | CLOB | NULL | Previous data values | Customer: 1001, Product: 2001 |
| new_values | CLOB | NULL | New data values | Order created: Customer=1001 |
| error_message | VARCHAR2(4000) | NULL | System error if occurred | ORA-01722: invalid number |

**Indexes:**
- `idx_audit_operation_date` on operation_date
- `idx_audit_table_name` on table_name
- `idx_audit_status` on operation_status
- `idx_audit_user` on user_session

**Business Rules:**
- Every DML operation attempt logged
- DENIED status requires denial_reason
- Captures complete user context
- Critical for security compliance
- Used to enforce weekday/holiday restrictions

---

## Sequences

| Sequence Name | Starting Value | Increment | Used For |
|---------------|----------------|-----------|----------|
| seq_customer | 1001 | 1 | CUSTOMERS.customer_id |
| seq_product | 2001 | 1 | PRODUCTS.product_id |
| seq_user | 3001 | 1 | USER_ACCOUNTS.user_id |
| seq_order | 4001 | 1 | ORDERS.order_id |
| seq_error | 5001 | 1 | ORDER_ERROR_LOG.error_id |
| seq_session | 6001 | 1 | USER_SESSIONS.session_id |
| seq_history | 7001 | 1 | ORDER_STATUS_HISTORY.history_id |
| seq_feedback | 8001 | 1 | CUSTOMER_FEEDBACK.feedback_id |
| seq_inventory_audit | 9001 | 1 | INVENTORY_AUDIT.audit_id |
| seq_payment | 10001 | 1 | PAYMENT_TRANSACTIONS.transaction_id |
| seq_config | 11001 | 1 | SYSTEM_CONFIGURATION.config_id |
| seq_audit_trail | 12001 | 1 | AUDIT_TRAIL.audit_id |
| seq_holiday | 1 | 1 | PUBLIC_HOLIDAYS.holiday_id |
| seq_audit_log | 1 | 1 | OPERATION_AUDIT_LOG.audit_log_id |

---

## Entity Relationships

### One-to-Many Relationships

1. **CUSTOMERS → ORDERS** (One customer can have many orders)
2. **PRODUCTS → ORDERS** (One product can appear in many orders)
3. **USER_ACCOUNTS → ORDERS** (One user can process many orders)
4. **ORDERS → ORDER_STATUS_HISTORY** (One order has many status changes)
5. **ORDERS → CUSTOMER_FEEDBACK** (One order can have feedback)
6. **ORDERS → PAYMENT_TRANSACTIONS** (One order can have multiple payment attempts)
7. **PRODUCTS → INVENTORY_AUDIT** (One product has many inventory changes)
8. **USER_ACCOUNTS → USER_SESSIONS** (One user has many sessions)

### Optional Relationships (NULL Foreign Keys)

- ORDER_ERROR_LOG.customer_id (error may not have valid customer)
- ORDER_ERROR_LOG.product_id (error may not have valid product)
- Most audit tables have NULL user_id (system operations)

---

## Data Volume Summary

| Table | Estimated Rows | Growth Rate | Criticality |
|-------|----------------|-------------|-------------|
| CUSTOMERS | 200+ | Low | High |
| PRODUCTS | 150+ | Low | High |
| USER_ACCOUNTS | 47+ | Very Low | High |
| ORDERS | 500+ | High | Critical |
| ORDER_ERROR_LOG | 100+ | Medium | Medium |
| USER_SESSIONS | 300+ | High | Low |
| ORDER_STATUS_HISTORY | 800+ | High | High |
| CUSTOMER_FEEDBACK | 200+ | Medium | Medium |
| INVENTORY_AUDIT | 400+ | High | High |
| PAYMENT_TRANSACTIONS | 450+ | High | Critical |
| SYSTEM_CONFIGURATION | 20+ | Very Low | High |
| AUDIT_TRAIL | 300+ | Medium | Medium |
| PUBLIC_HOLIDAYS | 20+ | Very Low | High |
| OPERATION_AUDIT_LOG | 500+ | Very High | Critical |

**Total Records:** 3,500+  
**Database Size:** ~150 MB  
**Expected Daily Growth:** 100-200 records

---

## Backup and Recovery Recommendations

1. **Daily Backups:** ORDERS, PAYMENT_TRANSACTIONS, OPERATION_AUDIT_LOG
2. **Weekly Backups:** All tables
3. **Retention Period:** 90 days for audit logs, 1 year for transactions
4. **Recovery Point Objective (RPO):** 24 hours
5. **Recovery Time Objective (RTO):** 4 hours

---
