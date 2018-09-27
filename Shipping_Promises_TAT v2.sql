select t.item_id, t.order_nr, t.sku, t.bids, t.item_name, t.Super_Category, t.ExportableDateTime, 
t.Hours_Since,t.shipping_date, t.type, t.po_number, t.Status, t.Action, t.is_restricted, 
t.vendor_code,ifnull(seller_details.registered_name,'Not Required') as vendor_name,
IF(left(t.vendor_code,2) = 'SV','Saudi',if(t.vendor_code= 'Find Seller','Find Seller',am_vendor_mapping.owner)) as owner , t.TP_Price, t.max_shipping_date
From
(SELECT
    CONCAT(indexer.db,indexer.id_sales_order_item) as item_id
    ,indexer.order_nr
    ,indexer.sku
    ,indexer.bids
    ,CONCAT('"',REPLACE(REPLACE(REPLACE(REPLACE(indexer.item_name,'"',"'"),',',' '),',',' '),'\n',' '),'"') as item_name
    ,CASE
        WHEN mid(indexer.sku,6,2)='NM' THEN 'Fashion - Namshi'
        ELSE LEFT(REPLACE(REPLACE(indexer.category_list,'Root Category | ',''),' | ','|'),LOCATE('|',REPLACE(REPLACE(indexer.category_list,'Root Category | ',''),' | ','|'))-1)
    END AS Super_Category
    ,Exportable.occured_at AS ExportableDateTime
    ,date(date(date_add(indexer.exported_at,interval 4 hour))+ if(indexer.db='SA', indexer.seller_shipping_time_max_sa,indexer.seller_shipping_time_max_ae)) as shipping_date
    ,(TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR))/60) AS Hours_Since
    ,IF(mid(indexer.sku,6,2) = 'NM','Namshi','Wadi') AS type
    ,erp.po_number
    ,CASE
        WHEN erp.arrivel_datetime <>'No' OR erp.pick_registered = 'Yes' THEN 'Arrived'
        WHEN erp.pick_line = 'Yes' AND erp.location_code = 'DXB' THEN 'DXB Inventory pickup'
        WHEN erp.pick_line = 'Yes' AND erp.location_code = 'KSA' THEN 'KSA Inventory pickup'
        WHEN erp.sales_order_item_id IS NULL THEN 'Not in ERP'
        WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' THEN 'PO Created'
        WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'TP Confirmation'
    END AS Status
    ,CASE
        WHEN mid(indexer.sku,6,2)='NM' THEN 'Namshi order'
        WHEN indexer.bob_item_status='confirmation_pending' THEN 'confirmation_pending'
        WHEN indexer.bob_item_status='shipped' THEN 'shipped'
        WHEN erp.pick_line = 'Yes' THEN 'Inventory Pickup'
        WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'Handover priority 1'
        WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'Handover priority 2'
        WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'Handover priority 3'
        WHEN erp.sales_order_item_id IS NULL OR erp.arrivel_datetime <> 'No' OR erp.pick_registered = 'Yes' THEN 'No Action'
        WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 3600 THEN 'Hunting'
        WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 3600 AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'TP confirmation priority 1'
        WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'TP confirmation priority 2'
        WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'TP confirmation priority 3'
    END AS Action
    ,REPLACE(REPLACE(REPLACE(REPLACE(seller_details.registered_name,'"',"'"),',',' '),',',' '),'\n',' ') as vendor_name
    ,indexer.cost_sa as design_cost_sa
    ,indexer.cost_ae as design_cost_ae
    ,CASE
		WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No'   THEN 
        CASE
			WHEN restricted.bids IS NOT NULL AND indexer.db = 'SA'
			THEN IFNULL(REPLACE(REPLACE(REPLACE(first_KSA_vendor.TP,',',''),'\n',''),'\r',''),'0')
		
			WHEN indexer.db = 'AE'
			THEN IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.TP,',',''),'\n',''),'\r',''),'0')
			ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.TP,',',''),'\n',''),'\r',''),'0') 
	END
	ELSE indexer.transfer_price
    END as TP_Price
    ,CASE
        WHEN restricted.bids IS NOT NULL
        THEN 1
       
        ELSE 0
    END as is_restricted
   
    ,CASE
    WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No'   THEN CASE
			WHEN restricted.bids IS NOT NULL AND indexer.db = 'SA'
			THEN IFNULL(REPLACE(REPLACE(REPLACE(first_KSA_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find Seller')
		
			WHEN indexer.db = 'AE'
			THEN IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find Seller')
		
			ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find Seller')
		END
    else erp.vendor_code
    END as vendor_code
    
    , date(date_add(date(date_add(exported_at, interval 4 hour)), interval if(indexer.db = 'SA', indexer.seller_shipping_time_max_sa, indexer.seller_shipping_time_max_ae) day)) as max_shipping_date
    
    ,if(indexer.db = 'SA',floor((indexer.seller_shipping_time_max_sa+dayofweek((date(date_add(indexer.exported_at,interval 4 hour))-6)))/7),floor((indexer.seller_shipping_time_max_sa+dayofweek((date(date_add(indexer.exported_at,interval 4 hour))-6)))/7)) as friday_nr
    
    
FROM
    reporting.wadi_indexer as indexer
   
   
    LEFT OUTER JOIN
    (SELECT
        db,item_id,max(occured_at) as occured_at
    FROM
        reporting.status_cache
    WHERE
        status='exportable'
        and occured_at > CURDATE() - INTERVAL 60 DAY
    GROUP BY
        1,2) as Exportable on Exportable.db=indexer.db AND Exportable.item_id=indexer.id_sales_order_item
   
   
    LEFT OUTER JOIN
    reporting.order_item_status as erp ON erp.sales_order_item_id=CONCAT(indexer.db,indexer.id_sales_order_item)
   
   
   LEFT OUTER JOIN
    (select
        t1.vendor_code
        ,seller_name
        ,wadi_sku_num
        ,model_no
        ,TP
        ,stock
        ,vendor_location
        ,days
        ,payment_terms
        ,TP_check
        ,(CASE wadi_sku_num
WHEN @bidsType
THEN @curRow := @curRow + 1
 
ELSE @curRow := 1 AND @bidsType := wadi_sku_num END
        ) + 1 AS rank
    from
        (select
vendor_code
,wadi_sku_num

,cast(replace (seller_tp,',','') as signed) as TP
,case when seller_inventory <> '0' then 5 else 0 end as stock
,vendor_location
,case
    when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) >= 10 then 2
    when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) > 0 then 1
    else 0
end as days
,payment_terms
,case when vendor_location = 'UAE' then seller_tp else 0.96*seller_tp end as TP_check
,seller_details.registered_name as seller_name
,model_no
        from
reporting.onboarding
LEFT OUTER JOIN
(SELECT
    seller_code
    ,MAX(registered_name) as registered_name
    ,MAX(contact_no) as contact_no
    ,MAX(payment_terms) as payment_terms
    ,MAX(REPLACE(pickup_address,',',';')) as pickup_address
FROM
    reporting.seller_details
GROUP BY
    1) as seller_details on onboarding.vendor_code = seller_details.seller_code
        order by
2
,4 desc
,6 desc
,8 asc
,5
        ) t1 ,(SELECT @curRow := 0, @bidsType := '') r
    group by
        3
        ) as first_vendor on first_vendor.wadi_sku_num = indexer.bids
   
   
    LEFT OUTER JOIN
    (SELECT
        vendor_name
        ,MAX(procurement_distribution) as owner
    FROM
        reporting.am_vendor_mapping
    GROUP BY
        1
    ) as procurement_owner on procurement_owner.vendor_name = first_vendor.vendor_code
   
       
    LEFT OUTER JOIN
    (select
        t1.vendor_code
        ,seller_name
        ,wadi_sku_num
        ,TP
        ,stock
        ,vendor_location
        ,days
        ,payment_terms
        ,TP_check
       ,(CASE wadi_sku_num
          WHEN @bidsType
          THEN @curRow := @curRow + 1
          ELSE @curRow := 1 AND @bidsType := wadi_sku_num END
         ) + 1 AS rank
		,model_no
    from
        (select
        vendor_code
        ,wadi_sku_num
        ,cast(replace (seller_tp,',','') as signed) as TP
        ,case when seller_inventory <> '0' then 5 else 0 end as stock
        ,vendor_location
        ,case
when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) >= 10 then 2
when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) > 0 then 1
else 0
        end as days
        ,payment_terms
        ,case when vendor_location = 'UAE' then seller_tp else 0.96*seller_tp end as TP_check
        ,seller_details.registered_name as seller_name
        ,model_no
	from
        reporting.onboarding
        LEFT OUTER JOIN
        (SELECT
seller_code
,MAX(registered_name) as registered_name
,MAX(contact_no) as contact_no
,MAX(payment_terms) as payment_terms
,MAX(REPLACE(pickup_address,',',';')) as pickup_address
        FROM
reporting.seller_details
        GROUP BY
1) as seller_details on onboarding.vendor_code = seller_details.seller_code
    where
        vendor_location = 'KSA'
    order by
        2
        ,4 desc
        ,6 desc
        ,8 asc
        ,5
    ) t1 ,(SELECT @curRow := 0, @bidsType := '') r
    group by
        3
        ) as first_KSA_vendor on first_KSA_vendor.wadi_sku_num = indexer.bids
   
   
    LEFT OUTER JOIN
    (SELECT
        vendor_name
        ,MAX(procurement_distribution) as owner
    FROM
        reporting.am_vendor_mapping
    GROUP BY
        1
    ) as procurement_owner_2 on procurement_owner_2.vendor_name = first_KSA_vendor.vendor_code
   
   
   
    LEFT OUTER JOIN
    (select
        t1.vendor_code
        ,seller_name
        ,wadi_sku_num
        ,model_no
        ,TP
        ,stock
        ,vendor_location
        ,days
        ,payment_terms
        ,TP_check
       ,(CASE wadi_sku_num
          WHEN @bidsType
          THEN @curRow := @curRow + 1
          ELSE @curRow := 1 AND @bidsType := wadi_sku_num END
         ) + 1 AS rank
    from
        (select
vendor_code
,wadi_sku_num
,cast(replace (seller_tp,',','') as signed) as TP
,case when seller_inventory <> '0' then 5 else 0 end as stock
,vendor_location
,case
    when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) >= 10 then 2
    when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) > 0 then 1
    else 0
end as days
,payment_terms
,case when vendor_location = 'UAE' then seller_tp else 0.96*seller_tp end as TP_check
,seller_details.registered_name as seller_name
,model_no
    from
        reporting.onboarding
        LEFT OUTER JOIN
        (SELECT
seller_code
,MAX(registered_name) as registered_name
,MAX(contact_no) as contact_no
,MAX(payment_terms) as payment_terms
,MAX(REPLACE(pickup_address,',',';')) as pickup_address
        FROM
reporting.seller_details
        GROUP BY
1) as seller_details on onboarding.vendor_code = seller_details.seller_code
    where
        vendor_location = 'UAE'
    order by
        2
        ,4 desc
        ,6 desc
        ,8 asc
        ,5
    ) t1 ,(SELECT @curRow := 0, @bidsType := '') r
    group by
        3
        ) as first_UAE_vendor on first_UAE_vendor.wadi_sku_num = indexer.bids
   
   
    LEFT OUTER JOIN
    (SELECT
        vendor_name
        ,MAX(procurement_distribution) as owner
    FROM
        reporting.am_vendor_mapping
    GROUP BY
        1
    ) as procurement_owner_3 on procurement_owner_3.vendor_name = first_UAE_vendor.vendor_code
   
   
    LEFT OUTER JOIN
    (SELECT
        seller_code
        ,MAX(registered_name) as registered_name
        ,MAX(contact_no) as contact_no
        ,MAX(payment_terms) as payment_terms
        ,MAX(REPLACE(pickup_address,',',';')) as pickup_address
    FROM
        reporting.seller_details
    GROUP BY
        1) as seller_details on erp.vendor_code = seller_details.seller_code
   
   
    LEFT OUTER JOIN
    (select
        bids
    from
        reporting.restricted_items
    group by
        1
    ) as restricted on restricted.bids = indexer.bids
   
               
               
WHERE
    indexer.bob_item_status='exported'
    AND 
    curdate() >= (date(date_add(date(date_add(exported_at, interval 4 hour)), interval if(indexer.db = 'SA', indexer.seller_shipping_time_max_sa, indexer.seller_shipping_time_max_ae) day))
  + floor((if(indexer.db ='SA',indexer.seller_shipping_time_max_sa,indexer.seller_shipping_time_max_ae)+dayofweek((date(date_add(indexer.exported_at,interval 4 hour))-6)))/7))
    
    OR indexer.bob_item_status='exportable'
	AND 
    curdate() >= (date(date_add(date(date_add(exported_at, interval 4 hour)), interval if(indexer.db = 'SA', indexer.seller_shipping_time_max_sa, indexer.seller_shipping_time_max_ae) day))
  + floor((if(indexer.db ='SA',indexer.seller_shipping_time_max_sa,indexer.seller_shipping_time_max_ae)+dayofweek((date(date_add(indexer.exported_at,interval 4 hour))-6)))/7))
) as t 

 LEFT OUTER JOIN
    (SELECT
        vendor_name
        ,registered_name
        ,MAX(procurement_distribution) as owner
    FROM
        reporting.am_vendor_mapping
    GROUP BY
        1
    ) as am_vendor_mapping on am_vendor_mapping.vendor_name COLLATE utf8_unicode_ci = t.vendor_code
    
    LEFT OUTER JOIN
    (select seller_code,registered_name from seller_details group by 1) as seller_details ON seller_details.seller_code=t.vendor_code

   where t.Status  in ('TP Confirmation','PO Created')