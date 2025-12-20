# Logical Data Model Design (3NF)
## Automated Customer Order Validation System

**Author:** SHEJA RADAN BORIS (29096)  
**Normalization Level:** Third Normal Form (3NF)  
**Modeling Approach:** Entity-Relationship (ER) Model  
**Date:** December 2024

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

```
┌──────────────────┐                    ┌──────────────────┐
│   CUSTOMERS      │                    │   USER_ACCOUNTS  │
├──────────────────┤                    ├──────────────────┤
│ PK customer_id   │──────┐      ┌──────│ PK user_id       │
│    first_name    │      │      │      │    username      │
│    last_name     │      │      │      │    password_hash │
│    email  (UK)   │      │      │      │    full_name     │
│    phone         │      │      │      │    email  (UK)   │
│    address       │      │      │      │    role          │
│    city          │      │      │      │    account_status│
│    country       │      │      │      │    created_date  │
│    postal_code   │      │      │      │    last_login    │
│    registration  │      │      │      │    failed_logins │
│    customer_stat │      │      │      └──────────────────┘
│    credit_limit  │      │      │               │
│    total_orders  │      │      │               │ processes
└──────────────────┘      │      │               │ 0..*
         │                │      │               │
         │ places         │      │               ▼
         │ 1..*           │      │      ┌──────────────────┐
         │                │      │      │     ORDERS       │
         │                │      └──────├──────────────────┤
         │                │      FK     │ PK order_id      │
         │                └────────────→│ FK customer_id   │
         │                       FK     │ FK product_id    │
         └─────────────────────────────→│ FK user_id       │
                                1..*    │    quantity      │
┌──────────────────┐                    │    unit_price    │
│    PRODUCTS      │                    │    total_amount  │
├──────────────────┤                    │    order_date    │
│ PK product_id    │──────┐             │    order_status  │
│    product_name  │      │             │    shipping_addr │
│    category      │      │             │    payment_status│
│    description   │      │ referenced  │    notes         │
│    unit_price    │      │ in          └──────────────────┘
│    stock_quantity│      │ 1..*                │
│    reorder_level │      │                     │
│    supplier_name │      │                     │
│    product_status│      └─────────────────────┘
│    created_date  │
│    last_updated  │
└──────────────────┘

┌──────────────────────┐             ┌──────────────────────┐
│ ORDER_ERROR_LOG      │             │ ORDER_STATUS_HISTORY │
├──────────────────────┤             ├──────────────────────┤
│ PK error_id          │             │ PK history_id        │
│ FK customer_id (opt) │             │ FK order_id          │
│ FK product_id (opt)  │             │ FK changed_by        │
│ FK attempted_by      │             │    old_status        │
│    quantity          │             │    new_status        │
│    error_message     │             │    change_date       │
│    error_date        │             │    remarks           │
│    error_type        │             └──────────────────────┘
└──────────────────────┘                      │
                                              │ tracks
                                              │ 1..*
                                              │
┌──────────────────────┐             ┌───────▼──────────────┐
│ CUSTOMER_FEEDBACK    │             │ PAYMENT_TRANSACTIONS │
├──────────────────────┤             ├──────────────────────┤
│ PK feedback_id       │             │ PK transaction_id    │
│ FK order_id          │◄────────────│ FK order_id          │
│ FK customer_id       │    has      │ FK processed_by      │
│ FK responded_by      │    0..1     │    payment_method    │
│    rating            │             │    amount            │
│    comment           │             │    transaction_date  │
│    feedback_date     │             │    transaction_stat  │
│    response          │             │    payment_reference │
│    response_date     │             │    gateway_response  │
└──────────────────────┘             └──────────────────────┘

┌──────────────────────┐             ┌──────────────────────┐
│ INVENTORY_AUDIT      │             │ USER_SESSIONS        │
├──────────────────────┤             ├──────────────────────┤
│ PK audit_id          │             │ PK session_id        │
│ FK product_id        │             │ FK user_id           │
│ FK performed_by      │             │    login_time        │
│ FK reference_order   │             │    logout_time       │
│    transaction_type  │             │    ip_address        │
│    quantity_change   │             │    session_status    │
│    old_quantity      │             └──────────────────────┘
│    new_quantity      │
│    audit_date        │             ┌──────────────────────┐
│    reason            │             │ SYSTEM_CONFIGURATION │
└──────────────────────┘             ├──────────────────────┤
                                     │ PK config_id         │
┌──────────────────────┐             │    config_key (UK)   │
│ PUBLIC_HOLIDAYS      │             │    config_value      │
├──────────────────────┤             │    description       │
│ PK holiday_id        │             │    data_type         │
│ FK created_by        │             │    last_updated      │
│    holiday_date (UK) │             │ FK updated_by        │
│    holiday_name      │             └──────────────────────┘
│    holiday_type      │
│    is_recurring      │             ┌──────────────────────┐
│    created_date      │             │ AUDIT_TRAIL          │
└──────────────────────┘             ├──────────────────────┤
                                     │ PK audit_id          │
┌──────────────────────┐             │ FK performed_by      │
│ OPERATION_AUDIT_LOG  │             │    table_name        │
├──────────────────────┤             │    operation         │
│ PK audit_log_id      │             │    record_id         │
│    operation_type    │             │    old_values        │
│    table_name        │             │    new_values        │
│    operation_date    │             │    operation_date    │
│    operation_day     │             │    ip_address        │
│    is_weekend        │             └──────────────────────┘
│    is_holiday        │
│    holiday_name      │
│    operation_status  │
│    denial_reason     │
│    user_session      │
│    os_user           │
│    machine_name      │
│    ip_address        │
│    record_id         │
│    old_values        │
│    new_values        │
│    error_message     │
└──────────────────────┘

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
- **