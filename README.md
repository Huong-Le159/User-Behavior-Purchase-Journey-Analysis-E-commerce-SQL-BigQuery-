# 🧠 User Behavior & Purchase Journey Analysis | E-commerce | SQL (BigQuery)
<img width="1564" height="868" alt="image" src="https://github.com/user-attachments/assets/43f522a5-9d7a-4a3e-b120-d0f8f15f6a06" />

**Author:** Huong Le  | 
**Date:** February 2025  |
**Tools Used:** BigQuery (Google Standard SQL)  

## Table of Contents

1. [📌 Background & Project Overview](#-background--project-overview)
2. [❓ Business Questions](#-business-questions)
3. [📁 Dataset Description](#-dataset-description)
4. [🧠 Analysis & Insights](#-analysis--insights)
5. [📊 Key Findings Summary](#-key-findings-summary)
6. [🧭 Recommendations](#-recommendations)
7. [🛠️ Tools & Skills Demonstrated](#️-tools--skills-demonstrated)
---

## 📌 Background & Project Overview

Modern e-commerce platforms rely heavily on **user behavior analytics** to improve conversion, optimize marketing spend, and understand how customers move through the digital purchase journey.

This project analyzes the **Google Analytics Sample Dataset (2017)** using **BigQuery SQL** to uncover insights on:

- Web traffic trends  
- Traffic source quality  
- Revenue drivers  
- User behavior differences (purchasers vs non-purchasers)  
- Cross-sell patterns  
- E-commerce funnel performance  

The objective is to demonstrate **end-to-end analytics thinking** — from business questions → data exploration → insights → business recommendations.

---

## ❓ Business Questions

This analysis is built around eight real-world e-commerce questions:

1. **Traffic Trend:**  
   How do visits, pageviews, and transactions change over time?

2. **Channel Quality:**  
   Which traffic sources drive meaningful engagement vs. high bounce?

3. **Revenue Drivers:**  
   Which sources contribute the most revenue at monthly and weekly levels?

4. **Purchaser vs. Non-Purchaser Behavior:**  
   Do buyers consume more content (pageviews) than non-buyers?

5. **Revenue Efficiency:**  
   What is the average revenue per user per visit?

6. **Repeat Purchase Behavior:**  
   How many transactions do users typically make?

7. **Cross-Sell Opportunities:**  
   If a customer buys Product X, what other products do they buy?

8. **Funnel Performance:**  
   What percentage of users progress from product view → add to cart → purchase?

---

## 📁 Dataset Description

The project uses the public dataset:

Table structure includes:

- Session-level fields  
- User identifiers (`fullVisitorId`)  
- Traffic source  
- Device and geo info  
- Pageviews, visits, bounces  
- E-commerce fields (hits, products, revenue, transactions)  
- Nested arrays: `hits`, `hits.product`, `hits.eCommerceAction`

Date Ranges Used:

| Query | Date Range | Purpose |
|-------|------------|---------|
| Q1 | 2017-01 → 2017-03 | Traffic trends |
| Q2 | July 2017 | Channel quality |
| Q3 | June 2017 | Revenue (month vs week) |
| Q4 | Jun–Jul 2017 | Purchaser vs non-purchaser |
| Q5–6 | July 2017 | Revenue metrics |
| Q7 | July 2017 | Cross-sell |
| Q8 | Jan–Mar 2017 | Funnel analysis |

---

## 🧠 Analysis & Insights

### **🔎 A. Traffic Trends (Jan–Mar 2017)**  
```sql
SELECT 
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  SUM(totals.visits) AS total_visit,
  SUM(totals.pageviews) AS total_pageview,
  SUM(totals.transactions) AS total_transaction
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month;
```
<img width="730" height="148" alt="image" src="https://github.com/user-attachments/assets/647c1f47-1826-4199-a88f-c27a2236d19d" />

**Insights:**
- Visits ranged from **62k–70k**, with the highest volume in **March**.  
- Transactions grew significantly in March → **strong end-of-quarter demand**.  
- Pageviews remained stable but transactions increased faster → **improved conversion efficiency**.

---

### **🔎 B. Channel Quality (July 2017)**  
```sql
SELECT 
  trafficSource.source AS source,
  SUM(totals.visits) AS total_visit,
  SUM(totals.bounces) AS total_no_of_bounce,
  ROUND((SUM(totals.bounces) / SUM(totals.visits)) * 100, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visit DESC;
```
Top traffic sources:

| Source | Total Visits | Bounce Rate |
|--------|--------------|-------------|
| google | 38k | ~51.6% |
| (direct) | 19k | ~43.3% |
| youtube.com | 6k | ~66.7% |

**Insights:**
- Google and direct traffic drive **the highest volume** and **stronger engagement**.  
- Some referral channels (e.g., YouTube) show **high bounce**, suggesting mismatch between intent and landing pages.

---

### **🔎 C. Revenue by Source (June 2017)**  
```sql
WITH month_type AS (
  SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    ROUND(SUM(products.productRevenue) / 1000000, 4) AS revenue,
    'Month' AS time_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`, 
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS products
  WHERE products.productRevenue IS NOT NULL
  GROUP BY source, time
),
week_type AS (
  SELECT 
    FORMAT_DATE('%Y%W', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    ROUND(SUM(products.productRevenue) / 1000000, 4) AS revenue,
    'Week' AS time_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`, 
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS products
  WHERE products.productRevenue IS NOT NULL
  GROUP BY source, time
)
SELECT time_type, time, source, revenue
FROM month_type
UNION ALL
SELECT time_type, time, source, revenue
FROM week_type
ORDER BY revenue DESC;
```
<img width="751" height="211" alt="image" src="https://github.com/user-attachments/assets/e578221d-7553-4272-838e-f33c8d50c4e1" />

**Insight:**  
- Weekly and monthly views reveal **revenue spikes** from search and direct channels.  
- Some weekly peaks disappear in monthly aggregation → indicating **campaign bursts**. 
Therefore, Marketing teams should analyze revenue **weekly**, not just monthly, to detect short-term lifts from campaigns.

---

### **🔎 D. Purchasers vs Non-Purchasers (June–July 2017)**  
```sql
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
```
| Group | Avg Pageviews / User (June) | Avg Pageviews / User (July) |
|-------|-----------------------------|------------------------------|
| Purchasers | 94 | 124 |
| Non-Purchasers | 317 | 334 |

**Insights:**
- Non-purchasers view **3× more pages**, suggesting difficulty finding relevant products or browsing without intent.  
- Purchasers’ pageviews increased from June to July → stronger engagement from buying users.

---

### **🔎 E. Transaction Behavior (July 2017)**  
```sql
SELECT
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    SUM(totals.transactions) / COUNT(DISTINCT fullvisitorid) AS Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) hits,
    UNNEST(product) product
WHERE totals.transactions >= 1
AND product.productRevenue IS NOT NULL
GROUP BY month;
```
**Insight:**  
- Average transactions per purchasing user shows **light buyers**—most users purchase once.  
- Opportunity exists to **increase repeat purchases** via loyalty or remarketing.

---

### **🔎 F. Revenue Efficiency (July 2017)**  
```sql
SELECT
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    ((SUM(product.productRevenue)/SUM(totals.visits))/POWER(10,6)) AS avg_revenue_by_user_per_visit
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) hits,
    UNNEST(product) product
WHERE product.productRevenue IS NOT NULL
AND totals.transactions >= 1
GROUP BY month;
```
Avg Revenue per User per Visit (Purchasers): **~$43.86**

This shows strong **monetization efficiency** among buying sessions.

---

### **🔎 G. Cross-Sell Behavior**
```sql
WITH Purchasers AS (
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.*`, UNNEST(hits) AS hits, UNNEST(hits.product) AS product
  WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
)
SELECT
  product.v2ProductName AS product_name,
  COUNT(*) AS purchase_count
FROM `bigquery-public-data.google_analytics_sample.*`, UNNEST(hits) AS hits, UNNEST(hits.product) AS product
WHERE fullVisitorId IN (SELECT fullVisitorId FROM Purchasers)
AND product.v2ProductName <> "YouTube Men's Vintage Henley"
GROUP BY product_name
ORDER BY purchase_count DESC;
```
Buyers of **“YouTube Men's Vintage Henley”** also purchase:

- Google Sunglasses  
- Google Apparel (Men’s & Women’s tees)  
- YouTube fleece hoodies  
- Accessories  
- Lip balm  

**Insight:**  
Cross-sell opportunities exist between **YouTube merchandise and Google apparel**.

---

### **🔎 H. Funnel Conversion (Jan–Mar 2017)**
```sql
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
```
| Month | View → Add (%) | View → Purchase (%) |
|-------|----------------|----------------------|
| Jan | 28.47% | 8.31% |
| Feb | 34.25% | 9.59% |
| Mar | 37.29% | 12.64% |

**Insight:**  
Funnel improved each month → users increasingly completing purchases.

---

## 📊 Key Findings Summary

- **Traffic increased** and conversion efficiency improved by March 2017.  
- **Google & direct traffic** are top-performing channels with lower bounce rates.  
- **Purchasers are more efficient**, needing fewer pageviews to convert.  
- **Non-purchasers show high browsing volume**, signaling UX or product relevance improvements needed.  
- **Strong cross-sell relationships** exist within Google & YouTube apparel.  
- **Funnel conversion improved** across all stages from Jan → Mar.  
- **Revenue spikes weekly**, meaning campaign or promotion effects are short-term but strong.

---

## 🧭 Recommendations

### **1. Improve Product Discovery**
- Non-purchasers browse heavily → Simplify navigation & highlight bestsellers.

### **2. Strengthen Weekly Marketing Campaigns**
- Weekly revenue spikes show **campaign impact** → Continue targeted ads.

### **3. Expand Cross-Sell Bundles**
- Bundle **YouTube + Google apparel** items (shirts + accessories).

### **4. Boost Returning Purchases**
- Launch loyalty program or remarketing emails to increase repeat buys.

### **5. Continue Optimizing Funnel**
- The funnel is improving → Analyze March’s tactics and replicate them.

---

## 🛠️ Tools & Skills Demonstrated

- SQL (BigQuery Standard SQL)  
- E-commerce analytics  
- Funnel analysis  
- Behavioral segmentation  
- Cross-sell analytics  
- Business storytelling  
- Report writing  

---




