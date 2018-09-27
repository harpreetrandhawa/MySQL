SELECT
  CONCAT(wadi_indexer.db, wadi_indexer.id_sales_order_item) as item_id
    ,date_add(exported_at, interval 4 hour) as exported_at
    ,bob_item_status
    ,date_add(po_created_at,interval 4 hour) as po_created_at
    ,date_add(arrived_at,interval 4 hour) as arrived_at
    ,shipping_location
    ,CASE
      WHEN wadi_catalog.category = 'Mobiles and Tablets' THEN 'Mobiles & Tablets'
      ELSE replace(replace(replace(replace(replace(replace(ltrim(rtrim(ifnull(wadi_catalog.super_category,substring_index(substring_index(category_list,'|',1),'|',-1)))),'\n',''),'\r',''),'/',' '),'''',''),',',' '),' and ',' & ')
    END as super_category
    ,cancellation_reason_code
    ,CASE 
    WHEN bob_item_status='canceled' 
      AND (cancellation_reason_code = 'C4' OR (timestampdiff(day,exported_at, canceled.occured_at) >= if(wadi_indexer.db='SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) + if(wadi_indexer.db='SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) - ( 6 * ( if(wadi_indexer.db='SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) DIV 7) + MID('0123345501223445011233450012234500123455011234450', 7 * WEEKDAY(date_add(exported_at,interval 4 hour)) + WEEKDAY(date_add(exported_at,interval 4 hour) + interval if(wadi_indexer.db='SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) day ) + 1, 1) ) )) 
      
      THEN 1
     
      ELSE 0 
  END as OOS
    ,CASE 
    WHEN bob_item_status='canceled' 
    AND (cancellation_reason_code <> 'C4' AND (timestampdiff(day,exported_at, canceled.occured_at) < if(wadi_indexer.db='SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) + if(wadi_indexer.db='SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) - ( 6 * ( if(wadi_indexer.db='SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) DIV 7) + MID('0123345501223445011233450012234500123455011234450', 7 * WEEKDAY(date_add(exported_at,interval 4 hour)) + WEEKDAY(date_add(exported_at,interval 4 hour) + interval if(wadi_indexer.db='SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) day ) + 1, 1) ) )) 
    
    THEN 1
    
    ELSE 0 
  END as Cust_cancellation
    ,date_add(shipped_at, interval 4 hour) as shipped_at
    ,canceled.occured_at as bob_canceled_at
    ,wadi_indexer.bids
    ,wadi_indexer.sku
    ,vendor_id
    ,replace(replace(replace(wadi_indexer.vendor_name, ',', ''), '\r', ''), '\n', '') as vendor_name
    ,CASE 
    WHEN shipped_at IS NOT NULL AND arrived_at IS NULL THEN 1 
      WHEN ois.pick_line = 'Yes' THEN 1
      WHEN wadi_indexer.stock_type = 'Stock' THEN 1
      ELSE 0 
  END AS shipped_from_inventory
  ,CASE
    WHEN wadi_indexer.vendor_code ='V00013' THEN 'Namshi'
    WHEN vendor_id in ('V00378','SV00336','V00937','SV00772','SV00758','SV00604','SV00605','V00921','V00487','V00895','V00894') THEN 'Intl'
    WHEN LEFT(vendor_id,1) = 'V' THEN 'Wadi'
    WHEN LEFT(vendor_id,2) = 'SV' THEN 'Saudi'
	WHEN vendor_ranking.vendor_code in ('V00378','SV00336','V00937','SV00772','SV00758','SV00604','SV00605','V00921','V00487','V00895','V00894') then 'Intl'
    WHEN LEFT(vendor_ranking.vendor_code, 2) = 'SV' then 'Saudi'
    WHEN shipping_location = 'KSA' then 'Saudi'
 ELSE 'Wadi' 
  END AS vendor
    ,replace(replace(replace(
  CASE 
    WHEN mid(wadi_indexer.sku,6,2) = 'NM' THEN 'Namshi'
      WHEN vendor_id in ('V00378','SV00336','V00937','SV00772','SV00758','SV00604','SV00605','V00921','V00487','V00895','V00894') then 'Intl'
      WHEN vendor_ranking.vendor_code in ('V00378','SV00336','V00937','SV00772','SV00758','SV00604','SV00605','V00921','V00487','V00895','V00894') then 'Intl'
      ELSE IFNULL(IFNULL((SELECT procurement_distribution FROM erp.am_vendor_mapping where wadi_indexer.vendor_id = am_vendor_mapping.vendor_name), vendor_ranking.procurement_owner),'Unassigned') 
    END
  , ',', ''), '\r', ''), '\n', '') as owner
  
FROM 
  buy_sell.wadi_indexer 
    LEFT OUTER JOIN erp.order_item_status as ois on CONCAT(buy_sell.wadi_indexer.db,wadi_indexer.id_sales_order_item) = ois.sales_order_item_id
  
    LEFT JOIN catalog.category_mappings as wadi_catalog
    on wadi_indexer.category_level_1 = wadi_catalog.category_level_1
    and wadi_indexer.category_level_2 = wadi_catalog.category_level_2
    and wadi_indexer.category_level_3 = wadi_catalog.category_level_3
    and wadi_indexer.category_level_4 = wadi_catalog.category_level_4

  
  LEFT OUTER JOIN
    (SELECT
      db, item_id, occured_at
    FROM
      buy_sell.status_cache
    WHERE
      status = 'canceled'
      and occured_at > curdate() - interval 35 day
  ) as canceled on canceled.db = wadi_indexer.db and canceled.item_id = wadi_indexer.id_sales_order_item
  
    LEFT OUTER JOIN
    (SELECT
      wadi_sku_num, vendor_code, procurement_owner
    FROM
      wadi_retail.vendor_ranking
  WHERE
    rank = 1
    and wadi_sku_num in (select bids from buy_sell.wadi_indexer where ordered_at > curdate() - interval 35 day)) as vendor_ranking on vendor_ranking.wadi_sku_num = wadi_indexer.bids
  
WHERE
  exported_at + interval 4 hour >= curdate() - interval day(curdate() - interval 1 day) day
    OR arrived_at + interval 4 hour >= curdate() - interval day(curdate() - interval 1 day) day
    OR shipped_at + interval 4 hour >= curdate() - interval day(curdate() - interval 1 day) day 
    OR exported_at + interval 4 hour > curdate() - interval 15 day