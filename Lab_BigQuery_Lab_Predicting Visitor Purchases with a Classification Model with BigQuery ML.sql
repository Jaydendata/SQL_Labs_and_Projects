'''
In SQL BigQuery, data-to-insights Project: https://console.cloud.google.com/bigquery?p=data-to-insights&d=ecommerce&t=web_analytics&page=table
standard SQL

PART 1: Data Exploration
'''
-- Question ONE: What's the % of purchase (converstion rate) out of total visitors?

WITH
  visitors AS(
  SELECT
    COUNT(DISTINCT fullVisitorId) AS total_visitors
  FROM
    `data-to-insights.ecommerce.web_analytics` ),
  purchasers AS(
  SELECT
    COUNT(DISTINCT fullVisitorId) AS total_purchasers
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.transactions IS NOT NULL )
SELECT
  total_visitors,
  total_purchasers,
  total_purchasers / total_visitors AS conversion_rate
FROM
  visitors,
  purchasers
  
  
 '''
 Output: total visitors (741721), total purchases (20015), conversion rate: 2.69%
 '''
 
 -- Question 2: What the the top 5 selling products?
 
 SELECT
  p.v2ProductName,
  p.v2ProductCategory,
  SUM(p.productQuantity) AS units_sold,
  ROUND(SUM(p.localProductRevenue/1000000),2) AS revenue
FROM
  `data-to-insights.ecommerce.web_analytics`,
  UNNEST(hits) AS h,
  UNNEST(h.product) AS p
GROUP BY
  1,
  2
ORDER BY
  revenue DESC
LIMIT
  5;
  
 -- Question 3: How many visitors bought on subsequent visits to the website?
  --- visitors who bought on a return visit (could have bought on first as well

WITH
  all_visitor_stats AS (
  SELECT
    fullvisitorid, -- 741,721 unique visitors
  IF
    (COUNTIF(totals.transactions > 0
        AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
    `data-to-insights.ecommerce.web_analytics`
  GROUP BY
    fullvisitorid )
SELECT
  COUNT(DISTINCT fullvisitorid) AS total_visitors,
  will_buy_on_return_visit
FROM
  all_visitor_stats
GROUP BY
  will_buy_on_return_visit
  
'''
PART 2: Create Training set
Create a Machine Learning model in BigQuery to predict whether or not a new user is likely to purchase in the future. 

Need to test if the following two fields are good inputs for a classification model:
> totals.bounces (whether the visitor left the website immediately)
> totals.timeOnSite (how long the visitor was on our website)
'''

-- The features are bounces and time_on_site. The label is will_buy_on_return_visit

SELECT
  * EXCEPT(fullVisitorId)
FROM
  --features
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1)
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
ORDER BY time_on_site DESC
LIMIT 10;

'''
PART 3: Create a BigQuery dataset to store models (in BigQuery)

PART 4: Select a BigQuery ML model type and specify options
'''

-- Create the first ML model in BigQuery: Classification model. 

CREATE OR REPLACE MODEL `ecommerce.classification_model`
OPTIONS
(
model_type='logistic_reg',
labels = ['will_buy_on_return_visit']
)
AS
--standardSQL
SELECT
  * EXCEPT(fullVisitorId)
FROM
  --features
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430') -- train on first 9 months
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
;

-- Should not feed all data into the model, 
-- so use WHERE clause to filter and train on only the first 9 months of session data. 

'''
PART 5: Evaluate classification model performance
- roc_auc as a simple queryable field when evaluating the trained model.
- We can evaluate how well the model performs using ML.EVALUATE.
'''

SELECT
  roc_auc,
  CASE
    WHEN roc_auc > .9 THEN 'good'
    WHEN roc_auc > .8 THEN 'fair'
    WHEN roc_auc > .7 THEN 'not great'
  ELSE
  'poor'
  END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.classification_model,
    (
    SELECT
      * EXCEPT(fullVisitorId)
    FROM
      # features 
      (SELECT
      fullVisitorId,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site
      FROM
        `data-to-insights.ecommerce.web_analytics`
      WHERE
        totals.newVisits = 1
        AND date BETWEEN '20170501' AND '20170630') # evaluate on 2 months
    JOIN (
      SELECT
        fullvisitorid,
        IF (
          COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) 
          AS will_buy_on_return_visit
        FROM
          `data-to-insights.ecommerce.web_analytics`
        GROUP BY
          fullvisitorid)
        USING
        (fullVisitorId) 
));

-- Result: 0.72, not great. 


'''
PART 6: Improve model performance with feature engineering

To include more features:
- How far the visitor got in the checkout process on their first visit
- Where the visitor came from (traffic source: organic search, referring site etc.)
- Device category (mobile, tablet, desktop)
- Geographic information (country)

'''

CREATE OR REPLACE MODEL `ecommerce.classification_model_2` 
OPTIONS (model_type='logistic_reg',
    labels = ['will_buy_on_return_visit']) AS
WITH
  all_visitor_stats AS (
  SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
    `data-to-insights.ecommerce.web_analytics`
  GROUP BY
    fullvisitorid 
) 

-- ADD IN NEW features

SELECT
  * EXCEPT(unique_session_id)
FROM (
  SELECT
    CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
    -- labels 
    will_buy_on_return_visit,
    MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
    -- behavior on the site
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site,
    totals.pageviews,
    -- where the vistor came from
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    -- mobile or desktop 
    device.deviceCategory,
    -- geographic 
    IFNULL(geoNetwork.country, "") AS country
  FROM
    `data-to-insights.ecommerce.web_analytics`,
    UNNEST(hits) AS h
    JOIN all_visitor_stats USING (fullvisitorid)
  WHERE
    1=1 
    --only predict FOR NEW visits
    AND totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430' -- train 9 months
  GROUP BY
    unique_session_id,
    will_buy_on_return_visit,
    bounces,
    time_on_site,
    totals.pageviews,
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    device.deviceCategory,
    country 
);


-- Next evaluate the new model

  -- standardSQL
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > .9 THEN 'good'
    WHEN roc_auc > .8 THEN 'fair'
    WHEN roc_auc > .7 THEN 'not great'
  ELSE 'poor' 
  END AS model_quality
  
FROM
  ML.EVALUATE(MODEL ecommerce.classification_model_2,  (
      WITH all_visitor_stats AS (
      SELECT
        fullvisitorid,
        IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM
        `data-to-insights.ecommerce.web_analytics`
      GROUP BY
        fullvisitorid
        ) 
-- ADD IN NEW features
SELECT * EXCEPT(unique_session_id)
FROM (
    SELECT
    CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
    -- labels 
	will_buy_on_return_visit,
    MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
    -- behavior on the site
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site,
    totals.pageviews,
    -- where the visitors came from 
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    -- mobile or desktop
    device.deviceCategory,
    -- geographic 
    IFNULL(geoNetwork.country, "") AS country
    FROM
      `data-to-insights.ecommerce.web_analytics`,
      UNNEST(hits) AS h 
      JOIN all_visitor_stats USING (fullvisitorid)
      WHERE
        1=1 -- only predict for new visits
        AND totals.newVisits = 1
        AND date BETWEEN '20170501' AND '20170630' -- eval 2 months
      GROUP BY
        unique_session_id,
        will_buy_on_return_visit,
        bounces,
        time_on_site,
        totals.pageviews,
        trafficSource.source,
        trafficSource.medium,
        channelGrouping,
        device.deviceCategory,
        country 
        ) 
        ))
;


-- Result: 
--- roc_auc: 0.909, Model quality: good



'''
PART 7: Predict which new visitors will come back and purchase

Use the last 1 month data (out of the 12 months) from the dataset. 


'''

SELECT
  *
FROM
  ml.PREDICT(MODEL `ecommerce.classification_model_2`,
    (
    WITH
      all_visitor_stats AS (
      SELECT
        fullvisitorid,
        IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM
        `data-to-insights.ecommerce.web_analytics`
      GROUP BY
        fullvisitorid
        )
    SELECT
    CONCAT(fullvisitorid, '-',CAST(visitId AS STRING)) AS unique_session_id,
    -- labels 
    will_buy_on_return_visit,
    MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
    -- behavior on the site
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site,
    totals.pageviews,
    -- where the visitor came from
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    -- mobile or desktop
    device.deviceCategory,
    -- geographic 
    IFNULL(geoNetwork.country, "") AS country
    FROM
      `data-to-insights.ecommerce.web_analytics`,
      UNNEST(hits) AS h
    JOIN all_visitor_stats USING (fullvisitorid)
    WHERE
    --only predict for new visits
    totals.newVisits = 1
    AND date BETWEEN '20170701' AND '20170801' -- test 1 month
    GROUP BY
      unique_session_id,
      will_buy_on_return_visit,
      bounces,
      time_on_site,
      totals.pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      country ) )
ORDER BY
  predicted_will_buy_on_return_visit DESC
;

'''
Restuls:

- Of the top 6% of first-time visitors (sorted in decreasing order of predicted probability), 
more than 6% make a purchase in a later visit.
- These users represent nearly 50% of all first-time visitors who make a purchase in a later visit.
- Overall, only 0.7% of first-time visitors make a purchase in a later visit.
- Targeting the top 6% of first-time increases marketing ROI by 9x vs targeting them all!
'''
















