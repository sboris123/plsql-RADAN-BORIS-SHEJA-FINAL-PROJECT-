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