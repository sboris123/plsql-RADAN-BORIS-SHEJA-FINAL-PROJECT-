-- Customer Indexes
CREATE INDEX idx_customer_email ON CUSTOMERS(email);
CREATE INDEX idx_customer_status ON CUSTOMERS(customer_status);
CREATE INDEX idx_customer_country ON CUSTOMERS(country);

-- Product Indexes
CREATE INDEX idx_product_category ON PRODUCTS(category);
CREATE INDEX idx_product_status ON PRODUCTS(product_status);
CREATE INDEX idx_product_stock ON PRODUCTS(stock_quantity);

-- Order Indexes
CREATE INDEX idx_order_customer ON ORDERS(customer_id);
CREATE INDEX idx_order_product ON ORDERS(product_id);
CREATE INDEX idx_order_date ON ORDERS(order_date);
CREATE INDEX idx_order_status ON ORDERS(order_status);

-- Error Log Indexes
CREATE INDEX idx_error_date ON ORDER_ERROR_LOG(error_date);
CREATE INDEX idx_error_type ON ORDER_ERROR_LOG(error_type);

-- Session Indexes
CREATE INDEX idx_session_user ON USER_SESSIONS(user_id);
CREATE INDEX idx_session_status ON USER_SESSIONS(session_status);

-- Payment Indexes
CREATE INDEX idx_payment_order ON PAYMENT_TRANSACTIONS(order_id);
CREATE INDEX idx_payment_status ON PAYMENT_TRANSACTIONS(transaction_status);

-- Create indexes for performance
CREATE INDEX idx_audit_operation_date ON OPERATION_AUDIT_LOG(operation_date);
CREATE INDEX idx_audit_table_name ON OPERATION_AUDIT_LOG(table_name);
CREATE INDEX idx_audit_status ON OPERATION_AUDIT_LOG(operation_status);
CREATE INDEX idx_audit_user ON OPERATION_AUDIT_LOG(user_session);

-- Create index on holiday date
CREATE INDEX idx_holiday_date ON PUBLIC_HOLIDAYS(holiday_date);
