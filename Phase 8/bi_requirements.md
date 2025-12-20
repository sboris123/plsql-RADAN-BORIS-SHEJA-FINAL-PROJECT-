# Business Intelligence Requirements
## Automated Customer Order Validation System

**Project:** Order Validation System  
**Author:** SHEJA RADAN BORIS (29096)  
**Date:** December 2024

---

## Executive Summary

This document outlines the Business Intelligence (BI) requirements for the Automated Customer Order Validation System. The BI layer provides actionable insights to stakeholders across sales, operations, finance, and management teams to drive data-driven decision-making.

---

## 1. Stakeholders & Their Information Needs

### 1.1 Executive Management (CEO, CFO)
**Frequency:** Weekly/Monthly  
**Decision Type:** Strategic  

**Information Needs:**
- Overall business performance (revenue, orders, growth)
- Customer acquisition and retention metrics
- Top-performing products and categories
- Profitability trends
- Operational efficiency indicators
- Security and compliance status

### 1.2 Sales Management
**Frequency:** Daily/Weekly  
**Decision Type:** Tactical  

**Information Needs:**
- Daily sales performance
- Sales team productivity
- Customer ordering patterns
- Product popularity trends
- Order success/failure rates
- Customer credit utilization

### 1.3 Operations/Warehouse Management
**Frequency:** Daily  
**Decision Type:** Operational  

**Information Needs:**
- Current inventory levels
- Products below reorder level
- Stock movement trends
- Order fulfillment status
- Inventory accuracy
- Supplier performance

### 1.4 Finance Team
**Frequency:** Daily/Monthly  
**Decision Type:** Financial Control  

**Information Needs:**
- Revenue by period
- Payment collection rates
- Outstanding payments
- Transaction volumes
- Payment method preferences
- Financial reconciliation data

### 1.5 Customer Service Management
**Frequency:** Daily/Weekly  
**Decision Type:** Service Quality  

**Information Needs:**
- Customer satisfaction scores
- Feedback trends
- Common complaints
- Response times
- Order status inquiries
- Return/cancellation rates

### 1.6 IT/Security Management
**Frequency:** Daily  
**Decision Type:** Security & Compliance  

**Information Needs:**
- System audit logs
- Access violations
- Failed operation attempts
- User activity patterns
- Database restriction compliance
- Security incidents

---

## 2. Key Performance Indicators (KPIs)

### 2.1 Sales KPIs

| KPI | Formula | Target | Red Threshold | Data Source |
|-----|---------|--------|---------------|-------------|
| **Daily Revenue** | SUM(total_amount) WHERE order_date = TODAY | 5M RWF | < 3M RWF | ORDERS |
| **Order Success Rate** | (Successful Orders / Total Attempts) × 100 | 95% | < 85% | ORDERS, ORDER_ERROR_LOG |
| **Average Order Value (AOV)** | Total Revenue / Number of Orders | 85,000 RWF | < 50,000 RWF | ORDERS |
| **Orders Per Day** | COUNT(orders) per day | 50+ | < 30 | ORDERS |
| **Customer Retention Rate** | (Returning Customers / Total Customers) × 100 | 70% | < 50% | CUSTOMERS, ORDERS |
| **Revenue Growth Rate** | ((Current Period - Previous Period) / Previous Period) × 100 | 10% | < 0% | ORDERS |

### 2.2 Operational KPIs

| KPI | Formula | Target | Red Threshold | Data Source |
|-----|---------|--------|---------------|-------------|
| **Inventory Accuracy** | (Correct Stock Count / Total Items) × 100 | 99% | < 95% | PRODUCTS, INVENTORY_AUDIT |
| **Stock-Out Rate** | (Out of Stock Items / Total Items) × 100 | < 5% | > 10% | PRODUCTS |
| **Order Fulfillment Time** | AVG(Delivered Date - Order Date) | 3 days | > 7 days | ORDER_STATUS_HISTORY |
| **Products Below Reorder** | COUNT(products WHERE stock < reorder_level) | < 5 | > 15 | PRODUCTS |
| **Inventory Turnover** | Cost of Goods Sold / Average Inventory | 8× per year | < 4× | PRODUCTS, ORDERS |

### 2.3 Customer Service KPIs

| KPI | Formula | Target | Red Threshold | Data Source |
|-----|---------|--------|---------------|-------------|
| **Customer Satisfaction Score** | AVG(rating) | 4.0/5.0 | < 3.5 | CUSTOMER_FEEDBACK |
| **Feedback Response Rate** | (Responded Feedback / Total Feedback) × 100 | 90% | < 70% | CUSTOMER_FEEDBACK |
| **Order Cancellation Rate** | (Cancelled Orders / Total Orders) × 100 | < 5% | > 10% | ORDERS |
| **Customer Complaints** | COUNT(rating <= 2) | < 10 per week | > 25 per week | CUSTOMER_FEEDBACK |

### 2.4 Financial KPIs

| KPI | Formula | Target | Red Threshold | Data Source |
|-----|---------|--------|---------------|-------------|
| **Payment Collection Rate** | (Paid Orders / Total Orders) × 100 | 95% | < 80% | PAYMENT_TRANSACTIONS |
| **Payment Failure Rate** | (Failed Payments / Total Attempts) × 100 | < 3% | > 8% | PAYMENT_TRANSACTIONS |
| **Average Payment Time** | AVG(Payment Date - Order Date) | 1 day | > 5 days | ORDERS, PAYMENT_TRANSACTIONS |
| **Revenue by Payment Method** | SUM(amount) GROUP BY payment_method | Varies | N/A | PAYMENT_TRANSACTIONS |

### 2.5 Security & Compliance KPIs

| KPI | Formula | Target | Red Threshold | Data Source |
|-----|---------|--------|---------------|-------------|
| **Access Violation Rate** | (Denied Operations / Total Attempts) × 100 | Varies | > 15% | OPERATION_AUDIT_LOG |
| **Weekday Operation Attempts** | COUNT(denied WHERE is_weekend = 'N') | 0 | > 5 per week | OPERATION_AUDIT_LOG |
| **Audit Log Completeness** | (Logged Operations / Total Operations) × 100 | 100% | < 100% | OPERATION_AUDIT_LOG |
| **Failed Login Attempts** | COUNT(failed_login_attempts > 0) | < 5 per day | > 20 per day | USER_ACCOUNTS |

---

## 3. Required Dashboards

### 3.1 Executive Dashboard
**Users:** CEO, CFO, Senior Management  
**Refresh:** Daily  

**Components:**
1. **Revenue Card** - Current month revenue vs target
2. **Orders Card** - Total orders this month
3. **Growth Card** - Month-over-month growth %
4. **Customer Card** - Active customer count
5. **Revenue Trend Chart** - Line chart (last 12 months)
6. **Top 10 Customers** - Bar chart by spending
7. **Category Performance** - Pie chart by revenue
8. **Order Status Distribution** - Donut chart
9. **Key Metrics Table** - AOV, success rate, satisfaction
10. **Alerts Panel** - Critical issues requiring attention

**KPIs Displayed:**
- Daily/Monthly Revenue
- Order Success Rate
- Customer Satisfaction Score
- Average Order Value
- Revenue Growth Rate

### 3.2 Sales Performance Dashboard
**Users:** Sales Managers, Sales Team  
**Refresh:** Real-time  

**Components:**
1. **Today's Sales Card** - Revenue, orders, AOV
2. **Sales Target Progress** - Gauge chart
3. **Hourly Sales Trend** - Line chart
4. **Top Products Today** - Table with quantities
5. **Sales by User** - Bar chart showing team performance
6. **Customer Segments** - Breakdown by spending tier
7. **Order Success vs Failures** - Comparison chart
8. **Pending Orders** - Real-time count
9. **Recent Large Orders** - Table with details
10. **Sales Forecast** - Predictive trend line

**KPIs Displayed:**
- Orders Per Day
- Average Order Value
- Order Success Rate
- Sales Team Productivity
- Revenue by Category

### 3.3 Inventory Management Dashboard
**Users:** Warehouse Managers, Operations  
**Refresh:** Every hour  

**Components:**
1. **Low Stock Alert** - Products below reorder level
2. **Out of Stock Items** - Current count
3. **Stock Value** - Total inventory value
4. **Top Moving Products** - Items sold most
5. **Slow Moving Products** - Items with low turnover
6. **Stock Movement History** - Last 30 days
7. **Restock Schedule** - Upcoming reorders
8. **Inventory by Category** - Breakdown
9. **Recent Adjustments** - Audit log table
10. **Supplier Performance** - Delivery times

**KPIs Displayed:**
- Inventory Accuracy
- Stock-Out Rate
- Products Below Reorder
- Inventory Turnover
- Average Stock Level

### 3.4 Audit & Compliance Dashboard
**Users:** IT Managers, Security Team, Auditors  
**Refresh:** Real-time  

**Components:**
1. **Total Operations Card** - Today's activity
2. **Allowed vs Denied** - Comparison gauge
3. **Weekday Violations** - Attempts during restricted times
4. **Holiday Violations** - Attempts during holidays
5. **Operation Timeline** - Hour-by-hour activity
6. **User Activity Table** - Who did what and when
7. **Failed Operations** - Details with reasons
8. **Access by IP Address** - Geographic map
9. **Critical Alerts** - Security incidents
10. **Compliance Score** - Overall system compliance %

**KPIs Displayed:**
- Access Violation Rate
- Weekday Operation Attempts
- Audit Log Completeness
- Failed Login Attempts
- Security Incidents

### 3.5 Customer Service Dashboard
**Users:** Customer Service Team  
**Refresh:** Every 30 minutes  

**Components:**
1. **Pending Feedback** - Unresponded reviews
2. **Average Rating Card** - Current satisfaction score
3. **Feedback Trend** - Rating over time
4. **Recent Feedback** - Latest customer comments
5. **Low-Rated Orders** - Orders with rating ≤ 2
6. **Response Time** - Average time to respond
7. **Common Issues** - Word cloud from comments
8. **Feedback by Product** - Category breakdown
9. **Customer Complaints** - Priority issues
10. **Service Team Performance** - Response rates

**KPIs Displayed:**
- Customer Satisfaction Score
- Feedback Response Rate
- Order Cancellation Rate
- Customer Complaints
- Response Time

### 3.6 Financial Dashboard
**Users:** Finance Team, Accountants  
**Refresh:** Daily  

**Components:**
1. **Revenue Card** - Today/Month/Year
2. **Outstanding Payments** - Unpaid orders
3. **Payment Method Distribution** - Pie chart
4. **Transaction Status** - Completed/Pending/Failed
5. **Daily Collections** - Bar chart by day
6. **Revenue by Category** - Breakdown
7. **Payment Trends** - Success rate over time
8. **Failed Transactions** - Details for reconciliation
9. **Top Customers by Revenue** - Table
10. **Financial Reconciliation** - Match orders to payments

**KPIs Displayed:**
- Payment Collection Rate
- Payment Failure Rate
- Average Payment Time
- Revenue by Payment Method
- Outstanding Amount

---

## 4. Analytical Queries

### 4.1 Customer Analytics

```sql
-- Customer Lifetime Value (CLV)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    AVG(o.total_amount) AS avg_order_value,
    MAX(o.order_date) AS last_order_date,
    ROUND((SYSDATE - MAX(o.order_date)), 0) AS days_since_last_order
FROM CUSTOMERS c
LEFT JOIN ORDERS o ON c.customer_id = o.customer_id
WHERE o.order_status != 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC;

-- Customer Segmentation (RFM Analysis)
SELECT 
    customer_id,
    customer_name,
    recency_score,
    frequency_score,
    monetary_score,
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 THEN 'Recent Customers'
        WHEN frequency_score >= 4 THEN 'Frequent Buyers'
        WHEN monetary_score >= 4 THEN 'Big Spenders'
        ELSE 'At Risk'
    END AS customer_segment
FROM (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        NTILE(5) OVER (ORDER BY MAX(o.order_date) DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY COUNT(o.order_id)) AS frequency_score,
        NTILE(5) OVER (ORDER BY SUM(o.total_amount)) AS monetary_score
    FROM CUSTOMERS c
    LEFT JOIN ORDERS o ON c.customer_id = o.customer_id
    WHERE o.order_status != 'Cancelled'
    GROUP BY c.customer_id, c.first_name, c.last_name
);
```

### 4.2 Product Performance Analytics

```sql
-- Product Performance with Trends
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(o.order_id) AS times_ordered,
    SUM(o.quantity) AS units_sold,
    SUM(o.total_amount) AS total_revenue,
    AVG(f.rating) AS avg_rating,
    p.stock_quantity AS current_stock,
    CASE 
        WHEN p.stock_quantity < p.reorder_level THEN 'REORDER'
        WHEN p.stock_quantity = 0 THEN 'OUT OF STOCK'
        ELSE 'OK'
    END AS stock_status
FROM PRODUCTS p
LEFT JOIN ORDERS o ON p.product_id = o.product_id AND o.order_status != 'Cancelled'
LEFT JOIN CUSTOMER_FEEDBACK f ON o.order_id = f.order_id
GROUP BY p.product_id, p.product_name, p.category, p.stock_quantity, p.reorder_level
ORDER BY total_revenue DESC;

-- Slow Moving Products (ABC Analysis)
SELECT 
    product_id,
    product_name,
    category,
    units_sold,
    total_revenue,
    revenue_rank,
    running_revenue_pct,
    CASE 
        WHEN running_revenue_pct <= 70 THEN 'A - Fast Moving'
        WHEN running_revenue_pct <= 90 THEN 'B - Moderate'
        ELSE 'C - Slow Moving'
    END AS movement_category
FROM (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        NVL(SUM(o.quantity), 0) AS units_sold,
        NVL(SUM(o.total_amount), 0) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY NVL(SUM(o.total_amount), 0) DESC) AS revenue_rank,
        ROUND(SUM(SUM(o.total_amount)) OVER (ORDER BY NVL(SUM(o.total_amount), 0) DESC) / 
              SUM(SUM(o.total_amount)) OVER () * 100, 2) AS running_revenue_pct
    FROM PRODUCTS p
    LEFT JOIN ORDERS o ON p.product_id = o.product_id
    WHERE o.order_status != 'Cancelled' OR o.order_id IS NULL
    GROUP BY p.product_id, p.product_name, p.category
);
```

### 4.3 Time-Series Analytics

```sql
-- Daily Sales Trends with Moving Averages
SELECT 
    order_date,
    daily_orders,
    daily_revenue,
    AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7day,
    AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS ma_30day,
    daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY order_date) AS revenue_change,
    ROUND(((daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY order_date)) / 
           NULLIF(LAG(daily_revenue, 1) OVER (ORDER BY order_date), 0)) * 100, 2) AS pct_change
FROM (
    SELECT 
        TRUNC(order_date) AS order_date,
        COUNT(*) AS daily_orders,
        SUM(total_amount) AS daily_revenue
    FROM ORDERS
    WHERE order_status != 'Cancelled'
    GROUP BY TRUNC(order_date)
)
ORDER BY order_date DESC;

-- Peak Hours Analysis
SELECT 
    EXTRACT(HOUR FROM order_date) AS order_hour,
    COUNT(*) AS order_count,
    SUM(total_amount) AS hour_revenue,
    AVG(total_amount) AS avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM ORDERS
WHERE order_status != 'Cancelled'
  AND order_date >= SYSDATE - 30
GROUP BY EXTRACT(HOUR FROM order_date)
ORDER BY order_hour;
```

### 4.4 Cohort Analysis

```sql
-- Monthly Cohort Retention
SELECT 
    cohort_month,
    months_since_first_order,
    customer_count,
    ROUND(customer_count * 100.0 / FIRST_VALUE(customer_count) OVER (PARTITION BY cohort_month ORDER BY months_since_first_order), 2) AS retention_rate
FROM (
    SELECT 
        TO_CHAR(first_order_date, 'YYYY-MM') AS cohort_month,
        FLOOR(MONTHS_BETWEEN(order_date, first_order_date)) AS months_since_first_order,
        COUNT(DISTINCT customer_id) AS customer_count
    FROM (
        SELECT 
            o.customer_id,
            o.order_date,
            MIN(o.order_date) OVER (PARTITION BY o.customer_id) AS first_order_date
        FROM ORDERS o
        WHERE o.order_status != 'Cancelled'
    )
    GROUP BY TO_CHAR(first_order_date, 'YYYY-MM'), FLOOR(MONTHS_BETWEEN(order_date, first_order_date))
)
ORDER BY cohort_month, months_since_first_order;
```

---

## 5. Reporting Schedule

| Report Name | Frequency | Recipients | Delivery Method | Time |
|-------------|-----------|------------|-----------------|------|
| Executive Summary | Weekly | CEO, CFO | Email PDF | Monday 8 AM |
| Sales Performance | Daily | Sales Managers | Dashboard + Email | 7 AM |
| Inventory Status | Daily | Warehouse Manager | Dashboard | 6 AM |
| Financial Reconciliation | Daily | Finance Team | Dashboard | 5 PM |
| Customer Feedback | Weekly | CS Manager | Email Excel | Friday 4 PM |
| Audit Compliance | Daily | IT Manager | Dashboard + Email | 9 AM |
| Monthly Performance | Monthly | All Stakeholders | PowerPoint | 1st of Month |

---

## 6. Data Refresh Strategy

| Data Source | Refresh Frequency | Method | Duration |
|-------------|-------------------|--------|----------|
| ORDERS | Real-time | Materialized View | Instant |
| CUSTOMERS | Daily | Scheduled Job | 5 min |
| PRODUCTS | Hourly | Scheduled Job | 2 min |
| AUDIT_LOGS | Real-time | Direct Query | Instant |
| AGGREGATIONS | Every 15 min | Materialized View | 10 min |

---

## 7. BI Tool Recommendations

### Recommended Tools:
1. **Oracle Analytics Cloud (OAC)** - Native Oracle integration
2. **Power BI** - Cost-effective, powerful visualizations
3. **Tableau** - Advanced analytics capabilities
4. **Custom Web Dashboard** - Built with JavaScript (Chart.js, D3.js)

### Tool Selection Criteria:
- Oracle database connectivity
- Real-time data refresh capability
- User-friendly interface
- Mobile accessibility
- Cost within budget
- Scalability

---

## 8. Success Metrics for BI Implementation

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Dashboard Adoption Rate | 80% of users | User login tracking |
| Decision Response Time | < 24 hours | Survey feedback |
| Data Accuracy | 99%+ | Data validation |
| User Satisfaction | 4.0/5.0 | User surveys |
| Report Delivery Success | 98%+ | Automated monitoring |

---

**Document Version:** 1.0  
**Prepared By:** SHEJA RADAN BORIS (29096)  
**Approved By:** [Advisor Name]  
**Date:** December 2024