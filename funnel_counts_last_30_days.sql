SELECT *
FROM `project-e2907289-8297-4648-9aa.sales_project.user events`
LIMIT 1000;

-- define sales funnel and different stages

WITH funnel_stages AS (

  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase

  FROM `project-e2907289-8297-4648-9aa.sales_project.user events`

  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
)

SELECT *
FROM funnel_stages;

-- conversion rates through the funnel 

WITH funnel_stages AS (

  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase

  FROM `project-e2907289-8297-4648-9aa.sales_project.user events`

  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
)

SELECT

  stage_1_views,
  stage_2_cart,
  ROUND(stage_2_cart * 100 / stage_1_views) AS view_to_cart_rate,

  stage_3_checkout,
  ROUND(stage_3_checkout * 100 / stage_2_cart) AS cart_checkout_rate,

  stage_4_payment,
  ROUND(stage_4_payment * 100 / stage_3_checkout) AS checkout_to_payment_rate,

  stage_5_purchase,
  ROUND(stage_5_purchase * 100 / stage_4_payment) AS payment_to_purchase_rate,

  ROUND(stage_5_purchase * 100 / stage_1_views) AS overall_conversion_rate

FROM funnel_stages;


  -- funnel by source

  WITH source_funnel AS (
  SELECT
    traffic_source,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases
  FROM `project-e2907289-8297-4648-9aa.sales_project.user events`
  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  GROUP BY traffic_source
)

SELECT
  traffic_source,
  views,
  carts,
  purchases,
  ROUND(carts * 100.0 / views, 1) AS cart_conversion_rate,
  ROUND(purchases * 100.0 / views, 1) AS purchase_conversion_rate,
  ROUND(purchases * 100.0 / carts, 1) AS cart_to_purchase_conversion_rate
FROM source_funnel
ORDER BY purchases DESC;

-- time to conversion analysis

 WITH user_journey AS (
  SELECT
    user_id,
    MIN(CASE WHEN event_type = 'page_view' THEN event_date END) AS view_time,
    MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
    MIN(CASE WHEN event_type = 'purchase' THEN event_date END) AS purchase_time
  FROM `project-e2907289-8297-4648-9aa.sales_project.user events`
  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  GROUP BY user_id
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)

SELECT
 COUNT(*) AS converted_users,
 ROUND(AVG(TIMESTAMP_DIFF(cart_time, view_time, MINUTE)),2) AS avg_view_to_cart_minutes,
 ROUND(AVG(TIMESTAMP_DIFF(purchase_time, view_time, MINUTE)),2) AS avg_cart_to_purchase_minutes,
 ROUND(AVG(TIMESTAMP_DIFF(purchase_time, view_time, MINUTE)),2) AS avg_total_journey_minutes,
FROM user_journey;

-- revenue funnel analysis

WITH funnel_revenue AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_buyers,
    SUM(CASE WHEN event_type = 'purchase' THEN amount END) AS total_revenue,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS total_orders
  FROM `project-e2907289-8297-4648-9aa.sales_project.user events`
  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
)

SELECT
  total_visitors,
  total_buyers,
  total_orders,
  ROUND(total_revenue, 2) AS total_revenue,
  ROUND(total_revenue / NULLIF(total_orders, 0), 2) AS avg_order_value,
  ROUND(total_revenue / NULLIF(total_buyers, 0), 2) AS revenue_per_buyer,
  ROUND(total_revenue / NULLIF(total_visitors, 0), 2) AS revenue_per_visitor
  
FROM funnel_revenue;