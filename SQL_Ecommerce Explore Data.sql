-- Query 1
SELECT 
  FORMAT_DATE('%Y%m',PARSE_DATE('%Y%m%d',date)) AS month
  ,SUM(totals.visits) AS total_visit
  ,SUM(totals.pageviews) AS total_pageview
  ,SUM(totals.transactions) AS total_transaction
FROM 
  `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month;

-- Query 2
SELECT 
  trafficSource.source AS source
  ,SUM(totals.visits) AS total_visit
  ,SUM (totals.bounces) AS total_no_of_bounce
  ,ROUND((SUM(totals.bounces)/SUM(totals.visits)) * 100, 3) AS bounce_rate
FROM 
  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visit DESC;

-- Query 3
With 
  month_type AS (
    SELECT 
      FORMAT_DATE('%Y%m',PARSE_DATE('%Y%m%d',date)) AS time
      ,trafficSource.source AS source
      ,ROUND(SUM(products.productRevenue)/1000000,4) AS revenue
      ,'Month' AS time_type
    FROM 
      `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`, 
    UNNEST (hits) AS hits,
    UNNEST (hits.product) AS products
    WHERE products.productRevenue IS NOT NULL
    GROUP BY source, time)

  ,week_type AS (
    SELECT 
      FORMAT_DATE('%Y%W',PARSE_DATE('%Y%m%d',date)) AS time
      ,trafficSource.source AS source
      ,ROUND(SUM(products.productRevenue)/1000000,4) AS revenue
      ,'Week' AS time_type
    FROM 
      `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`, 
    UNNEST (hits) AS hits,
    UNNEST (hits.product) AS products
    WHERE products.productRevenue IS NOT NULL
    GROUP BY source, time)

SELECT 
  time_type
  ,time
  ,source
  ,revenue
FROM month_type
UNION ALL
SELECT
  time_type
  ,time
  ,source
  ,revenue
FROM week_type
ORDER BY revenue DESC;

-- Query 4 
WITH 
purchaser_data AS (
  SELECT
      FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
      SUM(totals.pageviews) / COUNT(DISTINCT fullvisitorid) AS avg_pageviews_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) hits,
    UNNEST(product) product
  WHERE _table_suffix BETWEEN '0601' AND '0731'
    AND totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
  GROUP BY month
),
non_purchaser_data AS (
  SELECT
      FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
      SUM(totals.pageviews) / COUNT(DISTINCT fullvisitorid) AS avg_pageviews_non_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) hits,
    UNNEST(product) product
  WHERE _table_suffix BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    AND product.productRevenue IS NULL
  GROUP BY month
)
SELECT
    pd.*,
    avg_pageviews_non_purchase
FROM purchaser_data pd
FULL JOIN non_purchaser_data USING(month)
ORDER BY pd.month;

-- Query 5
SELECT
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    SUM(totals.transactions) / COUNT(DISTINCT fullvisitorid) AS Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) hits,
    UNNEST(product) product
WHERE totals.transactions >= 1
AND product.productRevenue IS NOT NULL
GROUP BY month;

-- Query 6
SELECT
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    ((SUM(product.productRevenue)/SUM(totals.visits))/POWER(10,6)) AS avg_revenue_by_user_per_visit
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) hits,
    UNNEST(product) product
WHERE product.productRevenue IS NOT NULL
AND totals.transactions >= 1
GROUP BY month;

-- Query 7 
WITH 
  purchaser_YTB AS (
    SELECT 
        fullVisitorId
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE  
        product.v2ProductName = "YouTube Men's Vintage Henley"
        AND product.productRevenue IS NOT NULL
        AND totals.transactions IS NOT NULL)

SELECT 
    product.v2ProductName AS Product_Name,
    SUM(product.productQuantity) AS product_Quantity
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST(hits) AS hits,
UNNEST(hits.product) AS product
WHERE 
    product.v2ProductName <> "YouTube Men's Vintage Henley"
    AND fullVisitorId IN (SELECT fullVisitorId FROM purchaser_YTB)
    AND product.productRevenue IS NOT NULL
    AND totals.transactions IS NOT NULL
GROUP BY Product_Name
ORDER BY product_Quantity DESC;

-- Query 8
WITH product_data AS (
    SELECT
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
        COUNT(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) AS num_product_view,
        COUNT(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) AS num_add_to_cart,
        COUNT(CASE WHEN eCommerceAction.action_type = '6' AND product.productRevenue IS NOT NULL THEN product.v2ProductName END) AS num_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
         UNNEST(hits) AS hits,
         UNNEST(hits.product) AS product
    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
          AND eCommerceAction.action_type IN ('2', '3', '6')
    GROUP BY month
    ORDER BY month
)

SELECT
    *,
    ROUND(num_add_to_cart / num_product_view * 100, 2) AS add_to_cart_rate,
    ROUND(num_purchase / num_product_view * 100, 2) AS purchase_rate
FROM product_data;
