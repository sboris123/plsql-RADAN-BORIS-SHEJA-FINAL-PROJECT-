# Logical Data Model Design (3NF)
## Automated Customer Order Validation System
**Normalization Level:** Third Normal Form (3NF)  
**Modeling Approach:** Entity-Relationship (ER) Model  
**Date:** December 2025

---

## Table of Contents
1. [Entity-Relationship Model](#entity-relationship-model)
2. [Normalization Process](#normalization-process)
3. [Detailed Entity Specifications](#detailed-entity-specifications)
4. [Relationship Matrix](#relationship-matrix)
5. [BI Dimensional Model](#bi-dimensional-model)
6. [Constraints & Business Rules](#constraints--business-rules)
7. [Assumptions & Design Decisions](#assumptions--design-decisions)

---

## Entity-Relationship Model

### ER Diagram (Crow's Foot Notation)
![Er diagram](https://github.com/sboris123/plsql-RADAN-BORIS-SHEJA-FINAL-PROJECT-/blob/e4a986b35dc6ccef28ddfdc63ea379ffe870c58c/phase%203/er%20diagram.png)
```

LEGEND:
PK = Primary Key
FK = Foreign Key
UK = Unique Key
(opt) = Optional/Nullable Foreign Key
──── = One to Many (1:*)
──┤├─ = Many to Many (*:*)
```

### Cardinality Definitions

| Relationship | Entity A | Cardinality | Entity B | Description |
|--------------|----------|-------------|----------|-------------|
| Places | CUSTOMERS | 1:M | ORDERS | One customer places many orders |
| References | PRODUCTS | 1:M | ORDERS | One product appears in many orders |
| Processes | USER_ACCOUNTS | 1:M | ORDERS | One user processes many orders |
| Tracks | ORDERS | 1:M | ORDER_STATUS_HISTORY | One order has many status changes |
| Has Feedback | ORDERS | 1:1 | CUSTOMER_FEEDBACK | One order may have one feedback |
| Has Payment | ORDERS | 1:M | PAYMENT_TRANSACTIONS | One order may have multiple payment attempts |
| Audits | PRODUCTS | 1:M | INVENTORY_AUDIT | One product has many audit entries |
| Logs | USER_ACCOUNTS | 1:M | USER_SESSIONS | One user has many sessions |
| Creates | USER_ACCOUNTS | 1:M | PUBLIC_HOLIDAYS | One admin creates many holidays |

---

## Normalization Process

### Initial Unnormalized Form (UNF)

**Original "Order" Document:**
```
Order Document {
    OrderID: 4001
    OrderDate: 2024-12-01
    CustomerName: "John Smith"
    CustomerEmail: "john@email.com"
    CustomerPhone: "+250781234567"
    CustomerAddress: "Kigali, Rwanda"
    CustomerCreditLimit: 10000
    
    Products: [
        {ProductID: 2001, ProductName: "Laptop", Price: 500000, Quantity: 2},
        {ProductID: 2005, ProductName: "Mouse", Price: 5000, Quantity: 3}
    ]
    
    TotalAmount: 1015000
    Status: "Pending"
    PaymentMethod: "Credit Card"
    ProcessedBy: "sales1"
    ProcessedByName: "Marie Uwase"
    ProcessedByEmail: "marie@company.com"
}
```

**Problems with UNF:**
- ❌ Repeating groups (multiple products per order)
- ❌ Multi-valued attributes (Products array)
- ❌ Data redundancy (customer info repeated in every order)
- ❌ Update anomalies (changing customer email requires updating all orders)
- ❌ Insertion anomalies (can't add customer without order)
- ❌ Deletion anomalies (deleting all orders loses customer data)

---

### First Normal Form (1NF)

**Goal:** Eliminate repeating groups and ensure atomic values

**1NF Transformation:**

**Table: ORDERS_1NF**
| order_id | order_date | customer_name | customer_email | customer_phone | customer_address | customer_credit | product_id | product_name | price | quantity | total | status | payment_method | processed_by | processed_name |
|----------|------------|---------------|----------------|----------------|------------------|-----------------|------------|--------------|-------|----------|-------|--------|----------------|--------------|----------------|
| 4001 | 2024-12-01 | John Smith | john@email.com | +250781234567 | Kigali, Rwanda | 10000 | 2001 | Laptop | 500000 | 2 | 1000000 | Pending | Credit Card | sales1 | Marie Uwase |
| 4001 | 2024-12-01 | John Smith | john@email.com | +250781234567 | Kigali, Rwanda | 10000 | 2005 | Mouse | 5000 | 3 | 15000 | Pending | Credit Card | sales1 | Marie Uwase |

**Achieved:**
- ✅ All attributes are atomic (single-valued)
- ✅ No repeating groups
- ✅ Each row is unique (composite key: order_id + product_id)

**Problems Remaining:**
- ❌ Massive data redundancy (customer info repeated for each product)
- ❌ Partial dependencies exist
- ❌ Update anomalies persist

**Primary Key in 1NF:** (order_id, product_id)

---

### Second Normal Form (2NF)

**Goal:** Eliminate partial dependencies (non-key attributes depending on part of composite key)

**Analysis of Dependencies:**

**Partial Dependencies Found:**
1. `customer_name, customer_email, customer_phone, customer_address, customer_credit` → depends only on `order_id`
2. `order_date, status, payment_method, processed_by, processed_name` → depends only on `order_id`
3. `product_name, price` → depends only on `product_id`

**2NF Transformation:**

**Table 1: ORDERS_2NF**
| PK: order_id | order_date | customer_name | customer_email | customer_phone | customer_address | customer_credit | status | payment_method | processed_by | processed_name |
|--------------|------------|---------------|----------------|----------------|------------------|-----------------|--------|----------------|--------------|----------------|
| 4001 | 2024-12-01 | John Smith | john@email.com | +250781234567 | Kigali, Rwanda | 10000 | Pending | Credit Card | sales1 | Marie Uwase |

**Table 2: ORDER_ITEMS_2NF**
| PK: order_id | PK: product_id | quantity | line_total |
|--------------|----------------|----------|------------|
| 4001 | 2001 | 2 | 1000000 |
| 4001 | 2005 | 3 | 15000 |

**Table 3: PRODUCTS_2NF**
| PK: product_id | product_name | price |
|----------------|--------------|-------|
| 2001 | Laptop | 500000 |
| 2005 | Mouse | 5000 |

**Achieved:**
- ✅ All non-key attributes depend on the entire primary key
- ✅ No partial dependencies
- ✅ Reduced redundancy

**Problems Remaining:**
- ❌ Transitive dependencies exist
- ❌ Customer data still redundant in ORDERS table
- ❌ User data (processed_name) dependent on processed_by, not order_id

---

### Third Normal Form (3NF)

**Goal:** Eliminate transitive dependencies (non-key attributes depending on other non-key attributes)

**Analysis of Transitive Dependencies:**

**Found in ORDERS_2NF:**
1. `customer_name, customer_email, customer_phone, customer_address, customer_credit` → depends on `customer_id` (implied), not directly on `order_id`
   - Transitive: order_id → customer_id → customer_name, etc.
   
2. `processed_name` → depends on `processed_by` (user), not on `order_id`
   - Transitive: order_id → processed_by → processed_name

**3NF Transformation:**

**Table 1: CUSTOMERS (3NF)**
```
PK: customer_id
Attributes:
  - first_name
  - last_name
  - email (UNIQUE)
  - phone
  - address
  - city
  - country
  - postal_code
  - registration_date
  - customer_status
  - credit_limit
  - total_orders
```

**Table 2: PRODUCTS (3NF)**
```
PK: product_id
Attributes:
  - product_name
  - category
  - description
  - unit_price
  - stock_quantity
  - reorder_level
  - supplier_name
  - product_status
  - created_date
  - last_updated
```

**Table 3: USER_ACCOUNTS (3NF)**
```
PK: user_id
Attributes:
  - username (UNIQUE)
  - password_hash
  - full_name
  - email (UNIQUE)
  - role
  - account_status
  - created_date
  - last_login
  - failed_login_attempts
```

**Table 4: ORDERS (3NF)**
```
PK: order_id
FK: customer_id → CUSTOMERS(customer_id)
FK: product_id → PRODUCTS(product_id)
FK: user_id → USER_ACCOUNTS(user_id)
Attributes:
  - quantity
  - unit_price
  - total_amount
  - order_date
  - order_status
  - shipping_address
  - payment_status
  - notes
```

**Achieved:**
- ✅ All non-key attributes depend ONLY on the primary key
- ✅ No transitive dependencies
- ✅ Minimal redundancy
- ✅ Update, insertion, deletion anomalies eliminated
- ✅ Each table represents a single entity

**Design Decision:** We kept Orders simple with direct product reference (one product per order) instead of creating ORDER_ITEMS because:
1. Business requirement: Each order line is treated as a separate order
2. Simplifies inventory tracking (one-to-one with product)
3. Easier audit trail
4. If multiple products needed, customer places multiple orders

---

### Normalization Justification

#### Why 3NF is Optimal for This System

**Advantages:**
1. **Data Integrity:** Each fact stored once, updates propagate correctly
2. **Scalability:** Easy to add new customers, products, orders
3. **Maintenance:** Changes to customer info don't require touching orders
4. **Query Performance:** Well-indexed foreign keys enable efficient joins
5. **Business Logic:** Clear separation of concerns (customers ≠ orders ≠ products)

**Why Not Denormalize?**
- Read-heavy operations benefit from joins (indexed properly)
- Oracle's query optimizer handles joins efficiently
- Data consistency is more important than marginal read performance
- Audit requirements demand normalized structure

**Why Not Go to BCNF/4NF/5NF?**
- 3NF satisfies all functional dependencies
- No multi-valued dependencies exist
- Further normalization would over-complicate without benefit
- Performance would degrade unnecessarily

---

## Detailed Entity Specifications

### Core Transactional Entities

#### 1. CUSTOMERS (Dimension)

**Purpose:** Store customer master data  
**Type:** Dimension Table (Slowly Changing Dimension Type 2)

| Attribute | Data Type | Constraints | Description | Sample Value |
|-----------|-----------|-------------|-------------|--------------|
| customer_id | NUMBER(10) | PK, NOT NULL | Unique identifier | 1001 |
| first_name | VARCHAR2(50) | NOT NULL | Customer first name | John |
| last_name | VARCHAR2(50) | NOT NULL | Customer last name | Smith |
| email | VARCHAR2(100) | UK, NOT NULL, CHECK (email format) | Email address | john@email.com |
| phone | VARCHAR2(20) | NULL | Contact number | +250781234567 |
| address | VARCHAR2(200) | NULL | Street address | KG 123 St |
| city | VARCHAR2(50) | NULL | City | Kigali |
| country | VARCHAR2(50) | DEFAULT 'Rwanda' | Country | Rwanda |
| postal_code | VARCHAR2(10) | NULL | Postal code | 00100 |
| registration_date | DATE | DEFAULT SYSDATE, NOT NULL | Registration date | 2024-01-15 |
| customer_status | VARCHAR2(20) | DEFAULT 'Active', CHECK (IN list) | Account status | Active |
| credit_limit | NUMBER(10,2) | DEFAULT 5000, CHECK (>= 0) | Credit limit in RWF | 10000.00 |
| total_orders | NUMBER(10) | DEFAULT 0, CHECK (>= 0) | Lifetime orders | 25 |

**Functional Dependencies:**
- customer_id → {first_name, last_name, email, phone, address, city, country, postal_code, registration_date, customer_status, credit_limit, total_orders}
- email → customer_id (unique constraint)

**Business Rules:**
1. Email must be unique and valid format
2. Credit limit cannot be negative
3. Only 'Active' customers can place orders
4. customer_status ∈ {'Active', 'Inactive', 'Suspended'}

---

#### 2. PRODUCTS (Dimension)

**Purpose:** Store product catalog and inventory  
**Type:** Dimension Table (Slowly Changing Dimension Type 2)

| Attribute | Data Type | Constraints | Description | Sample Value |
|-----------|-----------|-------------|-------------|--------------|
| product_id | NUMBER(10) | PK, NOT NULL | Unique identifier | 2001 |
| product_name | VARCHAR2(100) | NOT NULL | Product name | Premium Laptop |
| category | VARCHAR2(50) | NOT NULL | Product category | Electronics |
| description | VARCHAR2(500) | NULL | Product description | High-quality laptop... |
| unit_price | NUMBER(10,2) | NOT NULL, CHECK (> 0) | Price per unit | 500000.00 |
| stock_quantity | NUMBER(10) | DEFAULT 0, CHECK (>= 0) | Current stock | 150 |
| reorder_level | NUMBER(10) | DEFAULT 10, CHECK (>= 0) | Min stock threshold | 20 |
| supplier_name | VARCHAR2(100) | NULL | Supplier | Tech Suppliers Ltd |
| product_status | VARCHAR2(20) | DEFAULT 'Available', CHECK (IN list) | Availability | Available |
| created_date | DATE | DEFAULT SYSDATE, NOT NULL | Creation date | 2024-01-01 |
| last_updated | DATE | DEFAULT SYSDATE | Last update | 2024-12-01 |

**Functional Dependencies:**
- product_id → {product_name, category, description, unit_price, stock_quantity, reorder_level, supplier_name, product_status, created_date, last_updated}

**Business Rules:**
1. unit_price must be positive
2. stock_quantity cannot be negative
3. product_status ∈ {'Available', 'Discontinued', 'Out of Stock'}
4. When stock_quantity = 0, product_status auto-updates to 'Out of Stock'

---

#### 3. USER_ACCOUNTS (Dimension)

**Purpose:** Store system user information  
**Type:** Dimension Table

| Attribute | Data Type | Constraints | Description | Sample Value |
|-----------|-----------|-------------|-------------|--------------|
| user_id | NUMBER(10) | PK, NOT NULL | Unique identifier | 3001 |
| username | VARCHAR2(50) | UK, NOT NULL | Login username | sales1 |
| password_hash | VARCHAR2(100) | NOT NULL | Hashed password | $2a$10$... |
| full_name | VARCHAR2(100) | NOT NULL | Full name | Marie Uwase |
| email | VARCHAR2(100) | UK, NOT NULL | Email address | marie@company.com |
| role | VARCHAR2(30) | DEFAULT 'Sales', CHECK (IN list) | User role | Sales |
| account_status | VARCHAR2(20) | DEFAULT 'Active', CHECK (IN list) | Account status | Active |
| created_date | DATE | DEFAULT SYSDATE, NOT NULL | Creation date | 2024-01-01 |
| last_login | DATE | NULL | Last login | 2024-12-01 10:30 |
| failed_login_attempts | NUMBER(2) | DEFAULT 0, CHECK (>= 0) | Failed logins | 0 |

**Functional Dependencies:**
- user_id → {username, password_hash, full_name, email, role, account_status, created_date, last_login, failed_login_attempts}
- username → user_id
- email → user_id

**Business Rules:**
1. username and email must be unique
2. role ∈ {'Admin', 'Sales', 'Manager', 'Warehouse', 'Customer Service'}
3. account_status ∈ {'Active', 'Inactive', 'Locked'}
4. Account locks after 3 failed login attempts

---

#### 4. ORDERS (Fact Table)

**Purpose:** Store order transactions  
**Type:** Fact Table (Transaction Grain)

| Attribute | Data Type | Constraints | Description | Sample Value |
|-----------|-----------|-------------|-------------|--------------|
| order_id | NUMBER(10) | PK, NOT NULL | Unique identifier | 4001 |
| customer_id | NUMBER(10) | FK, NOT NULL | References customer | 1001 |
| product_id | NUMBER(10) | FK, NOT NULL | References product | 2001 |
| user_id | NUMBER(10) | FK, NULL | User who processed | 3001 |
| quantity | NUMBER(10) | NOT NULL, CHECK (> 0) | Quantity ordered | 2 |
| unit_price | NUMBER(10,2) | NOT NULL, CHECK (> 0) | Price at order time | 500000.00 |
| total_amount | NUMBER(10,2) | NOT NULL, CHECK (> 0) | Total = qty × price | 1000000.00 |
| order_date | DATE | DEFAULT SYSDATE, NOT NULL | Order timestamp | 2024-12-01 14:30 |
| order_status | VARCHAR2(30) | DEFAULT 'Pending', CHECK (IN list) | Current status | Pending |
| shipping_address | VARCHAR2(200) | NULL | Delivery address | KG 123 St, Kigali |
| payment_status | VARCHAR2(20) | DEFAULT 'Pending', CHECK (IN list) | Payment status | Pending |
| notes | VARCHAR2(500) | NULL | Additional notes | Rush order |

**Functional Dependencies:**
- order_id → {customer_id, product_id, user_id, quantity, unit_price, total_amount, order_date, order_status, shipping_address, payment_status, notes}

**Business Rules:**
1. customer_id must exist in CUSTOMERS
2. product_id must exist in PRODUCTS
3. total_amount = quantity × unit_price
4. order_status ∈ {'Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'}
5. payment_status ∈ {'Pending', 'Paid', 'Failed', 'Refunded'}
6. Cannot delete orders (set status to 'Cancelled')

---

### Audit & Control Tables

#### 5. ORDER_ERROR_LOG

**Purpose:** Track failed order attempts  
**Type:** Audit Table

| Attribute | Data Type | Constraints | Description |
|-----------|-----------|-------------|-------------|
| error_id | NUMBER(10) | PK | Unique error ID |
| customer_id | NUMBER(10) | FK (NULL OK) | Customer attempted |
| product_id | NUMBER(10) | FK (NULL OK) | Product attempted |
| quantity | NUMBER(10) | NULL | Quantity attempted |
| error_message | VARCHAR2(500) | NOT NULL | Error description |
| error_date | DATE | DEFAULT SYSDATE | When error occurred |
| attempted_by | NUMBER(10) | FK (NULL OK) | User who attempted |
| error_type | VARCHAR2(50) | CHECK (IN list) | Error category |

**Purpose:** Enables error analysis, troubleshooting, and system improvement

---

#### 6. ORDER_STATUS_HISTORY

**Purpose:** Complete audit trail of status changes  
**Type:** Historical/Tracking Table

| Attribute | Data Type | Constraints | Description |
|-----------|-----------|-------------|-------------|
| history_id | NUMBER(10) | PK | Unique history ID |
| order_id | NUMBER(10) | FK, NOT NULL | Order being tracked |
| old_status | VARCHAR2(30) | NULL | Previous status |
| new_status | VARCHAR2(30) | NOT NULL | New status |
| changed_by | NUMBER(10) | FK (NULL OK) | Who made change |
| change_date | TIMESTAMP | DEFAULT SYSTIMESTAMP | When changed |
| remarks | VARCHAR2(500) | NULL | Change notes |

**Purpose:** Provides complete timeline of order lifecycle for auditing and customer service

---

#### 7. OPERATION_AUDIT_LOG

**Purpose:** Track all DML operations with security context  
**Type:** Security Audit Table

| Attribute | Data Type | Constraints | Description |
|-----------|-----------|-------------|-------------|
| audit_log_id | NUMBER(10) | PK | Unique audit ID |
| operation_type | VARCHAR2(20) | NOT NULL, CHECK | INSERT/UPDATE/DELETE |
| table_name | VARCHAR2(50) | NOT NULL | Table affected |
| operation_date | TIMESTAMP | DEFAULT SYSTIMESTAMP | When operation occurred |
| operation_day | VARCHAR2(20) | NULL | Day of week |
| is_weekend | CHAR(1) | CHECK (Y/N) | Weekend flag |
| is_holiday | CHAR(1) | CHECK (Y/N) | Holiday flag |
| holiday_name | VARCHAR2(100) | NULL | Holiday name if applicable |
| operation_status | VARCHAR2(20) | CHECK (IN list) | ALLOWED/DENIED/ERROR |
| denial_reason | VARCHAR2(500) | NULL | Why denied |
| user_session | VARCHAR2(100) | NULL | DB session user |
| os_user | VARCHAR2(100) | NULL | OS user |
| machine_name | VARCHAR2(100) | NULL | Client machine |
| ip_address | VARCHAR2(45) | NULL | IP address |
| record_id | NUMBER(10) | NULL | Affected record ID |
| old_values | CLOB | NULL | Before values |
| new_values | CLOB | NULL | After values |
| error_message | VARCHAR2(4000) | NULL | Error if occurred |

**Purpose:** Complete security audit trail for compliance, forensics, and business rule enforcement

---

## Relationship Matrix

### Entity Relationship Summary

| Parent Entity | Child Entity | Relationship Type | Cardinality | FK Column | Cascade Rule |
|---------------|--------------|-------------------|-------------|-----------|--------------|
| CUSTOMERS | ORDERS | Identifying | 1:M | customer_id | RESTRICT |
| PRODUCTS | ORDERS | Identifying | 1:M | product_id | RESTRICT |
| USER_ACCOUNTS | ORDERS | Non-identifying | 1:M | user_id | SET NULL |
| ORDERS | ORDER_STATUS_HISTORY | Identifying | 1:M | order_id | CASCADE |
| ORDERS | CUSTOMER_FEEDBACK | Identifying | 1:1 | order_id | CASCADE |
| ORDERS | PAYMENT_TRANSACTIONS | Identifying | 1:M | order_id | CASCADE |
| PRODUCTS | INVENTORY_AUDIT | Identifying | 1:M | product_id | RESTRICT |
| USER_ACCOUNTS | USER_SESSIONS | Identifying | 1:M | user_id | CASCADE |
| USER_ACCOUNTS | PUBLIC_HOLIDAYS | Non-identifying | 1:M | created_by | SET NULL |
| CUSTOMERS | ORDER_ERROR_LOG | Non-identifying | 1:M | customer_id | SET NULL |
| PRODUCTS | ORDER_ERROR_LOG | Non-identifying | 1:M | product_id | SET NULL |
| USER_ACCOUNTS | ORDER_ERROR_LOG | Non-identifying | 1:M | attempted_by | SET NULL |

### Referential Integrity Rules

**DELETE Rules:**
- **RESTRICT:** Cannot delete parent if children exist (CUSTOMERS, PRODUCTS with active ORDERS)
- **CASCADE:** Delete children when parent deleted (ORDER → ORDER_STATUS_HISTORY)
- **SET NULL:** Set FK to NULL when parent deleted (USER deleted → ORDERS.user_id = NULL)

**UPDATE Rules:**
- **CASCADE:** Primary key updates propagate to foreign keys (though discouraged)
- **RESTRICT:** Primary key updates blocked if children exist (preferred approach)

---

## BI Dimensional Model

### Star Schema Design for Analytics

```
                    ┌──────────────────┐
                    │  DIM_CUSTOMER    │
                    ├──────────────────┤
                    │ PK customer_key  │
                    │    customer_id   │
                    │    name          │
                    │    city          │
                    │    country       │
                    │    status        │
                    │    credit_limit  │
                    │    segment       │◄──────┐
                    └──────────────────┘       │
                                               │
┌──────────────────┐                          │
│  DIM_PRODUCT     │                          │
├──────────────────┤                          │
│ PK product_key   │                          │
│    product_id    │                          │
│    product_name  │                          │
│    category      │                          │
│    unit_price    │                          │
│    supplier      │◄────────┐                │
└──────────────────┘         │                │
                             │                │
┌──────────────────┐         │                │
│  DIM_USER        │         │                │
├──────────────────┤         │                │
│ PK user_key      │         │                │
│    user_id       │         │                │
│    username      │         │                │
│    full_name     │         │      ┌─────────▼──────────┐
│    role          │◄────────┼──────│   FACT_ORDERS      │
│    department    │         │      ├────────────────────┤
└──────────────────┘         │      │ PK order_key       │
                             │      │ FK customer_key    │
┌──────────────────┐         │      │ FK product_key     │
│  DIM_DATE        │         │      │ FK user_key        │
├──────────────────┤         │      │ FK date_key        │
│ PK date_key      │         └──────┤    quantity        │
│    date          │                │    unit_price      │
│    day           │◄───────────────┤    total_amount    │
│    week          │                │    tax_amount      │
│    month         │                │    order_status    │
│    quarter       │                │    payment_status  │
│    year          │                │    processing_time │
│    is_weekend    │                └────────────────────┘
│    is_holiday    │
│    fiscal_period │
└──────────────────┘
```

### Fact Table: FACT_ORDERS

**Grain:** One row per order (transaction-level)  
**Type:** Transaction Fact Table

**Measures (Additive):**
- quantity (SUM, AVG, MIN, MAX)
- unit_price (AVG, MIN, MAX)
- total_amount (SUM, AVG, MIN, MAX)
- tax_amount (SUM, AVG)

**Measures (Semi-Additive):**
- processing_time (AVG across time, not across customers)

**Measures (Non-Additive):**
- order_status (COUNT, distribution)
- payment_status (COUNT, distribution)

**Degenerate Dimensions:**
- order_id (transaction identifier, no dimension table needed)
- shipping_address (captured in fact, too variable for dimension)

### Dimension Tables

#### DIM_CUSTOMER (Slowly Changing Dimension Type 2)

**Attributes:**
- customer_key (surrogate key)
- customer_id (business key)
- customer_name (first + last)
- email
- city
- country
- customer_status
- credit_limit
- customer_segment (derived: VIP, Regular, New)
- effective_date (SCD Type 2)
- expiry_date (SCD Type 2)
- is_current (SCD Type 2)

**SCD Type 2 Example:**
```
customer_key | customer_id | name        | status   | effective_date | expiry_date | is_current
1001         | C001        | John Smith  | Active   | 2024-01-01     | 2024-06-30  | N
1002         | C001        | John Smith  | Suspended| 2024-07-01     | 9999-12-31  | Y
```

**Why SCD Type 2?**
- Historical analysis: "How many orders did we have from suspended customers?"
- Trend analysis: "When did customer status changes affect order volume?"
- Audit requirements: "What was the customer's status when order was placed?"

#### DIM_PRODUCT (Slowly Changing Dimension Type 2)

**Attributes:**
- product_key (surrogate key)
- product_id (business key)
- product_name
- category
- subcategory (derived)
- unit_price
- supplier_name
- product_status
- effective_date (SCD Type 2)
- expiry_date (SCD Type 2)
- is_current (SCD Type 2)

**SCD Type 2 for Price Changes:**
```
product_key | product_id | product_name | unit_price | effective_date | is_current
2001        | P001       | Laptop       | 500000     | 2024-01-01     | N
2002        | P001       | Laptop       | 550000     | 2024-06-01     | Y
```

**Why Track Price History?**
- Price impact analysis: "Did price increase affect sales volume?"
- Margin analysis: "What was our margin at time of sale?"
- Competitive analysis: "How did our pricing evolve?"

#### DIM_DATE (Time Dimension)

**Attributes:**
- date_key (YYYYMMDD format: 20241201)
- full_date
- day_of_week (Monday, Tuesday, etc.)
- day_of_month (1-31)
- day_of_year (1-366)
- week_of_year (1-53)
- month_number (1-12)
- month_name (January, etc.)
- quarter (Q1, Q2, Q3, Q4)
- year (2024)
- is_weekend (Y/N)
- is_holiday (Y/N)
- holiday_name
- fiscal_period
- fiscal_year

**Why Pre-Build Date Dimension?**
- Fast date-based queries (no date functions needed)
- Consistent fiscal period handling
- Easy filtering (last quarter, weekdays only, etc.)
- Holiday analysis built-in

#### DIM_USER (Slowly Changing Dimension Type 1)

**Attributes:**
- user_key (surrogate key)
- user_id (business key)
- username
- full_name
- role
- department (derived from role)
- account_status
- hire_date

**SCD Type 1 (Overwrite):**
- User role changes overwrite previous value
- No history needed for user attributes
- Focus is on current state for reporting

### Aggregation Tables (For Performance)

#### AGG_DAILY_SALES

```sql
CREATE TABLE AGG_DAILY_SALES (
    date_key NUMBER(8),
    customer_key NUMBER(10),
    product_key NUMBER(10),
    order_count NUMBER(10),
    total_quantity NUMBER(10),
    total_revenue NUMBER(12,2),
    avg_order_value NUMBER(10,2),
    PRIMARY KEY (date_key, customer_key, product_key)
);
```

**Purpose:** Speed up daily/monthly reports without scanning all orders

#### AGG_MONTHLY_PRODUCT_SALES

```sql
CREATE TABLE AGG_MONTHLY_PRODUCT_SALES (
    year_month VARCHAR2(7), -- YYYY-MM
    product_key NUMBER(10),
    category VARCHAR2(50),
    total_orders NUMBER(10),
    total_quantity NUMBER(10),
    total_revenue NUMBER(12,2),
    avg_price NUMBER(10,2),
    PRIMARY KEY (year_month, product_key)
);
```

**Purpose:** Monthly product performance without full scan

---

## Constraints & Business Rules

### Primary Key Constraints

| Table | Primary Key | Type | Justification |
|-------|-------------|------|---------------|
| CUSTOMERS | customer_id | Natural | Sequential, meaningful, stable |
| PRODUCTS | product_id | Natural | Sequential, meaningful, stable |
| USER_ACCOUNTS | user_id | Natural | Sequential, stable |
| ORDERS | order_id | Natural | Sequential, unique per transaction |
| ORDER_ERROR_LOG | error_id | Surrogate | High volume, simple key |
| USER_SESSIONS | session_id | Surrogate | Temporary data, simple key |
| ORDER_STATUS_HISTORY | history_id | Surrogate | High volume, timeline data |
| CUSTOMER_FEEDBACK | feedback_id | Surrogate | Simple, optional feature |
| INVENTORY_AUDIT | audit_id | Surrogate | High volume audit data |
| PAYMENT_TRANSACTIONS | transaction_id | Surrogate | High volume, complex |
| SYSTEM_CONFIGURATION | config_id | Surrogate | Small, config data |
| AUDIT_TRAIL | audit_id | Surrogate | High volume audit |
| PUBLIC_HOLIDAYS | holiday_id | Surrogate | Small reference table |
| OPERATION_AUDIT_LOG | audit_log_id | Surrogate | Very high volume |

### Foreign Key Constraints

#### Strong Foreign Keys (NOT NULL)
```sql
-- Order must have customer
ALTER TABLE ORDERS ADD CONSTRAINT fk_orders_customer 
    FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id);

-- Order must have product
ALTER TABLE ORDERS ADD CONSTRAINT fk_orders_product 
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id);

-- Status history must have order
ALTER TABLE ORDER_STATUS_HISTORY ADD CONSTRAINT fk_history_order 
    FOREIGN KEY (order_id) REFERENCES ORDERS(order_id);
```

#### Weak Foreign Keys (NULL OK)
```sql
-- Order may have user (system can place orders)
ALTER TABLE ORDERS ADD CONSTRAINT fk_orders_user 
    FOREIGN KEY (user_id) REFERENCES USER_ACCOUNTS(user_id) 
    ON DELETE SET NULL;

-- Error log may have customer (error might be before customer verified)
ALTER TABLE ORDER_ERROR_LOG ADD CONSTRAINT fk_error_customer 
    FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id) 
    ON DELETE SET NULL;
```

### Unique Constraints

```sql
-- Email must be unique
ALTER TABLE CUSTOMERS ADD CONSTRAINT uk_customer_email UNIQUE (email);

-- Username must be unique
ALTER TABLE USER_ACCOUNTS ADD CONSTRAINT uk_user_username UNIQUE (username);

-- Payment reference must be unique
ALTER TABLE PAYMENT_TRANSACTIONS ADD CONSTRAINT uk_payment_ref UNIQUE (payment_reference);

-- Holiday date must be unique
ALTER TABLE PUBLIC_HOLIDAYS ADD CONSTRAINT uk_holiday_date UNIQUE (holiday_date);

-- Config key must be unique
ALTER TABLE SYSTEM_CONFIGURATION ADD CONSTRAINT uk_config_key UNIQUE (config_key);
```

### Check Constraints

```sql
-- Customer status must be valid
ALTER TABLE CUSTOMERS ADD CONSTRAINT chk_customer_status 
    CHECK (customer_status IN ('Active', 'Inactive', 'Suspended'));

-- Credit limit must be non-negative
ALTER TABLE CUSTOMERS ADD CONSTRAINT chk_credit_limit 
    CHECK (credit_limit >= 0);

-- Email format validation
ALTER TABLE CUSTOMERS ADD CONSTRAINT chk_email_format 
    CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}));

-- Price must be positive
ALTER TABLE PRODUCTS ADD CONSTRAINT chk_unit_price 
    CHECK (unit_price > 0);

-- Stock cannot be negative
ALTER TABLE PRODUCTS ADD CONSTRAINT chk_stock_quantity 
    CHECK (stock_quantity >= 0);

-- Quantity must be positive
ALTER TABLE ORDERS ADD CONSTRAINT chk_order_quantity 
    CHECK (quantity > 0);

-- Total must match calculation (enforced by trigger)
ALTER TABLE ORDERS ADD CONSTRAINT chk_total_amount 
    CHECK (total_amount > 0);

-- Rating must be 1-5
ALTER TABLE CUSTOMER_FEEDBACK ADD CONSTRAINT chk_rating 
    CHECK (rating BETWEEN 1 AND 5);

-- Weekend flag must be Y or N
ALTER TABLE OPERATION_AUDIT_LOG ADD CONSTRAINT chk_is_weekend 
    CHECK (is_weekend IN ('Y', 'N'));

-- Operation status must be valid
ALTER TABLE OPERATION_AUDIT_LOG ADD CONSTRAINT chk_operation_status 
    CHECK (operation_status IN ('ALLOWED', 'DENIED', 'ERROR'));
```

### Default Constraints

```sql
-- Customer defaults
customer_status DEFAULT 'Active'
credit_limit DEFAULT 5000
total_orders DEFAULT 0
country DEFAULT 'Rwanda'
registration_date DEFAULT SYSDATE

-- Product defaults
stock_quantity DEFAULT 0
reorder_level DEFAULT 10
product_status DEFAULT 'Available'
created_date DEFAULT SYSDATE
last_updated DEFAULT SYSDATE

-- User defaults
role DEFAULT 'Sales'
account_status DEFAULT 'Active'
failed_login_attempts DEFAULT 0
created_date DEFAULT SYSDATE

-- Order defaults
order_status DEFAULT 'Pending'
payment_status DEFAULT 'Pending'
order_date DEFAULT SYSDATE

-- Audit defaults
operation_date DEFAULT SYSTIMESTAMP
```

### Computed Constraints (Enforced by Triggers)

```sql
-- Total amount = quantity × unit_price
-- Enforced by: Before INSERT/UPDATE trigger on ORDERS

-- Stock status = 'Out of Stock' when quantity = 0
-- Enforced by: After UPDATE trigger on PRODUCTS

-- total_orders increments when order placed
-- Enforced by: After INSERT trigger on ORDERS
```

---

## Assumptions & Design Decisions

### Business Assumptions

1. **Order Granularity**
   - **Assumption:** Each order contains one product type
   - **Justification:** Simplifies inventory tracking and audit
   - **Alternative:** Could create ORDER_ITEMS for multi-product orders
   - **Decision:** Current design adequate for MVP, can extend later

2. **Customer Identification**
   - **Assumption:** Email uniquely identifies customers
   - **Justification:** Modern e-commerce standard
   - **Risk:** Customer may want multiple accounts
   - **Mitigation:** Business rule enforces one account per email

3. **Price History**
   - **Assumption:** unit_price in ORDERS captures price at transaction time
   - **Justification:** Historical accuracy for auditing
   - **Alternative:** Could store only product_id and join to PRODUCTS
   - **Decision:** Store price to handle price changes without SCD complexity

4. **Order Lifecycle**
   - **Assumption:** Orders progress: Pending → Confirmed → Processing → Shipped → Delivered
   - **Justification:** Standard e-commerce workflow
   - **Tracking:** ORDER_STATUS_HISTORY captures all transitions

5. **Credit Management**
   - **Assumption:** Credit limit applies to pending orders only
   - **Justification:** Paid orders don't consume credit
   - **Calculation:** Available Credit = Limit - Sum(Pending Orders)

6. **Inventory Management**
   - **Assumption:** Stock deducted immediately when order placed
   - **Justification:** Reserves inventory for customer
   - **Recovery:** Stock restored if order cancelled

7. **User Roles**
   - **Assumption:** Each user has single role
   - **Justification:** RBAC (Role-Based Access Control)
   - **Alternative:** Could implement many-to-many users-to-roles
   - **Decision:** Single role sufficient for current requirements

8. **Holiday Management**
   - **Assumption:** Only admins can add holidays
   - **Justification:** Security and data integrity
   - **Scope:** Rwanda public holidays plus test holidays

### Technical Assumptions

9. **Primary Key Strategy**
   - **Decision:** Use NUMBER(10) sequences for all PKs
   - **Justification:** 
     - Predictable, sequential
     - Efficient indexing
     - Easy to implement
   - **Alternative:** Could use GUIDs/UUIDs
   - **Tradeoff:** Sequences vs distributed systems

10. **Cascading Deletes**
    - **Decision:** Minimize CASCADE, prefer RESTRICT or SET NULL
    - **Justification:**
      - Prevents accidental data loss
      - Explicit delete required for audit trail
      - Better control over data lifecycle
    - **Exception:** ORDER → ORDER_STATUS_HISTORY (cascade makes sense)

11. **Timestamp Precision**
    - **Decision:** Use TIMESTAMP for audit logs, DATE for business data
    - **Justification:**
      - Audit needs millisecond precision
      - Business dates don't need time portion
      - Performance consideration

12. **Denormalization Decisions**
    - **Decision:** Minimal denormalization (only total_orders in CUSTOMERS)
    - **Justification:**
      - Maintain data integrity
      - Accept join cost for data consistency
      - Indexes mitigate performance impact
    - **Exception:** total_orders cached for quick dashboard queries

13. **Audit Approach**
    - **Decision:** Separate audit tables (not audit columns in main tables)
    - **Justification:**
      - Cleaner separation of concerns
      - Easier to query audit data
      - Doesn't bloat transactional tables
    - **Types:** 
      - OPERATION_AUDIT_LOG (security)
      - ORDER_STATUS_HISTORY (business)
      - INVENTORY_AUDIT (operational)

14. **NULL Handling**
    - **Decision:** Allow NULLs for optional attributes only
    - **Justification:**
      - NOT NULL for critical business data
      - NULL OK for supplementary info (notes, remarks)
      - Foreign keys: NULL if optional relationship

15. **String Lengths**
    - **Decision:** VARCHAR2 with specific lengths
    - **Justification:**
      - 50: Names (first, last)
      - 100: Long names, email
      - 200: Addresses
      - 500: Comments, descriptions
      - 4000: Error messages
      - CLOB: JSON audit data

### Data Quality Assumptions

16. **Data Validation**
    - **Assumption:** All validation done at database level
    - **Justification:**
      - Single source of truth
      - Prevents bad data regardless of entry point
      - Consistent enforcement
    - **Layers:**
      - CHECK constraints (format, ranges)
      - Triggers (business logic)
      - Procedures (complex validation)

17. **Reference Data**
    - **Assumption:** Reference data pre-loaded (holidays, config)
    - **Justification:**
      - System cannot function without baseline data
      - Admin responsibility to maintain
    - **Examples:**
      - PUBLIC_HOLIDAYS: Rwanda holidays
      - SYSTEM_CONFIGURATION: Tax rate, limits

18. **Data Retention**
    - **Assumption:** No automatic deletion of historical data
    - **Justification:**
      - Audit requirements
      - Regulatory compliance
      - Business analytics
    - **Exception:** Old sessions may be archived

### Performance Assumptions

19. **Index Strategy**
    - **Decision:** Index all foreign keys and frequently queried columns
    - **Justification:**
      - Join performance critical
      - Read-heavy workload
    - **Indexes Created:**
      - All PKs (automatic)
      - All FKs (manual)
      - Unique constraints (automatic)
      - Status columns (manual)
      - Date columns (manual)

20. **Query Patterns**
    - **Assumption:** More reads than writes (80/20 rule)
    - **Justification:**
      - Orders queried frequently
      - Orders placed less frequently
    - **Optimization:**
      - Indexed for reads
      - Minimal triggers to speed writes

21. **Scalability Target**
    - **Assumption:** Support 1000+ orders per day
    - **Justification:**
      - Estimated business growth
      - Current design handles 10x easily
    - **Capacity:**
      - 365,000 orders/year
      - ~5 years = 2 million orders (still manageable)

---

## BI Considerations Summary

### Fact vs Dimension Classification

**Fact Tables (Transaction Data):**
- ORDERS - Core fact table (transaction grain)
- PAYMENT_TRANSACTIONS - Payment facts
- INVENTORY_AUDIT - Inventory movement facts
- ORDER_ERROR_LOG - Error facts (for quality analysis)

**Dimension Tables (Descriptive Data):**
- CUSTOMERS - Who bought
- PRODUCTS - What was bought
- USER_ACCOUNTS - Who processed
- DIM_DATE - When (built separately)

**Audit/History Tables:**
- ORDER_STATUS_HISTORY - Order lifecycle tracking
- OPERATION_AUDIT_LOG - Security audit
- AUDIT_TRAIL - General audit

### Slowly Changing Dimensions (SCD)

| Dimension | SCD Type | Reason |
|-----------|----------|--------|
| CUSTOMERS | Type 2 | Track status changes (Active → Suspended) |
| PRODUCTS | Type 2 | Track price changes over time |
| USER_ACCOUNTS | Type 1 | Current state only, history not needed |
| DIM_DATE | Type 0 | Static, never changes |

### Aggregation Levels

**Level 1 (Most Detailed):**
- Order-level (ORDERS table)
- Individual transactions

**Level 2 (Daily):**
- AGG_DAILY_SALES
- Daily summaries by customer/product

**Level 3 (Monthly):**
- AGG_MONTHLY_PRODUCT_SALES
- Monthly summaries by product/category

**Level 4 (Yearly):**
- AGG_YEARLY_CATEGORY
- Annual summaries by category

### Audit Trail Design

**Security Audit:**
- OPERATION_AUDIT_LOG
- Who did what, when, from where
- Captures allowed and denied operations

**Business Audit:**
- ORDER_STATUS_HISTORY
- Complete order lifecycle
- Every status change recorded

**Data Audit:**
- AUDIT_TRAIL
- Generic audit for all tables
- Before/after values in JSON

**Operational Audit:**
- INVENTORY_AUDIT
- Stock movements
- Reconciliation support

---

## Normalization Benefits Summary

### Data Integrity
- ✅ No update anomalies (change customer email once)
- ✅ No insertion anomalies (add customer without order)
- ✅ No deletion anomalies (delete order keeps customer)
- ✅ Single source of truth for each fact

### Maintenance
- ✅ Easy to add new entities (add USER_ROLES table)
- ✅ Easy to modify attributes (add customer_tier)
- ✅ Clear ownership (customer data in CUSTOMERS only)

### Query Flexibility
- ✅ Join any entities as needed
- ✅ Filter on any attribute independently
- ✅ Aggregate at any level

### Storage Efficiency
- ✅ Minimal redundancy
- ✅ Predictable growth
- ✅ Efficient indexing

---

**Document Version:** 1.0  
**Normalization Level:** Third Normal Form (3NF)  
**Reviewed By:** SHEJA RADAN BORIS (29096)  
**Date:** December 2024  
**Status:** Final
