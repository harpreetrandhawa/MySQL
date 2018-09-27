Select * from 
(SELECT
    CONCAT(indexer.db,indexer.id_sales_order_item) as item_id
    ,indexer.order_nr
    ,indexer.sku
    ,indexer.bids
    ,CONCAT('"',REPLACE(REPLACE(REPLACE(REPLACE(indexer.item_name,'"',"'"),',',' '),',',' '),'\n',' '),'"') as item_name
    ,CASE
        WHEN restricted.bids IS NOT NULL AND indexer.db = 'SA'
        THEN IFNULL(REPLACE(REPLACE(REPLACE(first_KSA_vendor.model_no,',',''),'\n',''),'\r',''),'')
       
        WHEN indexer.db = 'AE'
        THEN IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.model_no,',',''),'\n',''),'\r',''),'')
       
        ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.model_no,',',''),'\n',''),'\r',''),'')
    END as model_no
    ,indexer.unit_price
    ,CASE
        WHEN mid(indexer.sku,6,2)='NM' THEN 'Fashion - Namshi'
        ELSE LEFT(REPLACE(REPLACE(indexer.category_list,'Root Category | ',''),' | ','|'),LOCATE('|',REPLACE(REPLACE(indexer.category_list,'Root Category | ',''),' | ','|'))-1)
    END AS Super_Category
    ,(TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR))/60) AS Hours_Since
    ,IF(mid(indexer.sku,6,2) = 'NM','Namshi','Wadi') AS type
    ,indexer.db as order_location
    ,erp.po_number
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
    ,CASE WHEN erp.vendor_code is NULL OR erp.vendor_code = "None" THEN
			CASE
				WHEN restricted.bids IS NOT NULL AND indexer.db = 'SA'
				THEN IFNULL(REPLACE(REPLACE(REPLACE(first_KSA_vendor.vendor_code,',',''),'\n',''),'\r',''),'')
       
				WHEN indexer.db = 'AE'
				THEN IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.vendor_code,',',''),'\n',''),'\r',''),'')
       
				ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.vendor_code,',',''),'\n',''),'\r',''),'')
			END
		ELSE erp.vendor_code END as vendor_code
    , CASE WHEN seller_details.registered_name is NULL THEN
			CASE
			WHEN restricted.bids IS NOT NULL AND indexer.db = 'SA'
			THEN IFNULL(REPLACE(REPLACE(REPLACE(first_KSA_vendor.seller_name,',',''),'\n',''),'\r',''),'')
       
			WHEN indexer.db = 'AE'
			THEN IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.seller_name,',',''),'\n',''),'\r',''),'')
       
			ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.seller_name,',',''),'\n',''),'\r',''),'')
			END
		ELSE REPLACE(REPLACE(REPLACE(REPLACE(seller_details.registered_name,'"',"'"),',',' '),',',' '),'\n',' ') END as vendor_name
    ,CASE WHEN indexer.transfer_price is NULL OR indexer.transfer_price = 0 THEN
			CASE
				WHEN restricted.bids IS NOT NULL AND indexer.db = 'SA'
				THEN IFNULL(REPLACE(REPLACE(REPLACE(first_KSA_vendor.TP,',',''),'\n',''),'\r',''),'')
       
				WHEN indexer.db = 'AE'
				THEN IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.TP,',',''),'\n',''),'\r',''),'')
				ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.TP,',',''),'\n',''),'\r',''),'')
				END
			ELSE indexer.transfer_price END as transfer_price
	,CASE
        WHEN restricted.bids IS NOT NULL
        THEN 1
       
        ELSE 0
    END as is_restricted
   
    ,IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.vendor_code,',',''),'\n',''),'\r',''),'') as uae_vendor
    ,IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.seller_name,',',''),'\n',''),'\r',''),'') as uae_vendor_name
    ,IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.TP,',',''),'\n',''),'\r',''),'') as uae_vendor_TP
	,IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.stock,',',''),'\n',''),'\r',''),'') as uae_vendor_stock
FROM
    reporting.wadi_indexer as indexer
LEFT OUTER JOIN (SELECT 
        db, item_id, MAX(occured_at) AS occured_at
    FROM
        reporting.status_cache
    WHERE
        status = 'exportable'
            AND occured_at > CURDATE() - INTERVAL 60 DAY
    GROUP BY 1 , 2) AS Exportable ON Exportable.db = indexer.db
        AND Exportable.item_id = indexer.id_sales_order_item
    LEFT OUTER JOIN reporting.order_item_status AS erp ON erp.sales_order_item_id = CONCAT(indexer.db, indexer.id_sales_order_item)
    LEFT OUTER JOIN (SELECT 
        t1.vendor_code,
            seller_name,
            wadi_sku_num,
            model_no,
            TP,
            stock,
            vendor_location,
            days,
            payment_terms,
            TP_check,
            (CASE wadi_sku_num
                WHEN @bidsType THEN @curRow:=@curRow + 1
                ELSE @curRow:=1 AND @bidsType:=wadi_sku_num
            END) + 1 AS rank
    FROM
        (SELECT 
        vendor_code,
            wadi_sku_num,
            CAST(REPLACE(seller_tp, ',', '') AS SIGNED) AS TP,
            CASE
                WHEN seller_inventory <> '0' THEN 5
                ELSE 0
            END AS stock,
            vendor_location,
            CASE
                WHEN (LEFT(payment_terms, LOCATE('+', payment_terms) - 1)) / 2 + (RIGHT(payment_terms, LENGTH(payment_terms) - LOCATE('+', payment_terms))) >= 10 THEN 2
                WHEN (LEFT(payment_terms, LOCATE('+', payment_terms) - 1)) / 2 + (RIGHT(payment_terms, LENGTH(payment_terms) - LOCATE('+', payment_terms))) > 0 THEN 1
                ELSE 0
            END AS days,
            payment_terms,
            (CASE
                WHEN vendor_location = 'UAE' THEN 1
                ELSE 0.96
            END) * CAST(seller_tp AS SIGNED) AS TP_check,
            seller_details.registered_name AS seller_name,
            model_no
    FROM
        reporting.onboarding
    LEFT OUTER JOIN (SELECT 
        seller_code,
            MAX(registered_name) AS registered_name,
            MAX(contact_no) AS contact_no,
            MAX(payment_terms) AS payment_terms,
            MAX(REPLACE(pickup_address, ',', ';')) AS pickup_address
    FROM
        reporting.seller_details
    GROUP BY 1) AS seller_details ON onboarding.vendor_code = seller_details.seller_code
    ORDER BY 2 , 4 DESC , 6 DESC , 8 ASC , 5) t1, (SELECT @curRow:=0, @bidsType:='') r
    GROUP BY 3) AS first_vendor ON first_vendor.wadi_sku_num = indexer.bids
    LEFT OUTER JOIN (SELECT 
        vendor_name, MAX(procurement_distribution) AS owner
    FROM
        reporting.am_vendor_mapping
    GROUP BY 1) AS procurement_owner ON procurement_owner.vendor_name = first_vendor.vendor_code
    LEFT OUTER JOIN (SELECT 
        t1.vendor_code,
            seller_name,
            wadi_sku_num,
            TP,
            stock,
            vendor_location,
            days,
            payment_terms,
            TP_check,
            (CASE wadi_sku_num
                WHEN @bidsType THEN @curRow:=@curRow + 1
                ELSE @curRow:=1 AND @bidsType:=wadi_sku_num
            END) + 1 AS rank,
            model_no
    FROM
        (SELECT 
        vendor_code,
            wadi_sku_num,
            CAST(REPLACE(seller_tp, ',', '') AS SIGNED) AS TP,
            CASE
                WHEN seller_inventory <> '0' THEN 5
                ELSE 0
            END AS stock,
            vendor_location,
            CASE
                WHEN (LEFT(payment_terms, LOCATE('+', payment_terms) - 1)) / 2 + (RIGHT(payment_terms, LENGTH(payment_terms) - LOCATE('+', payment_terms))) >= 10 THEN 2
                WHEN (LEFT(payment_terms, LOCATE('+', payment_terms) - 1)) / 2 + (RIGHT(payment_terms, LENGTH(payment_terms) - LOCATE('+', payment_terms))) > 0 THEN 1
                ELSE 0
            END AS days,
            payment_terms,
            (CASE
                WHEN vendor_location = 'UAE' THEN 1
                ELSE 0.96
            END) * CAST(seller_tp AS SIGNED) AS TP_check,
            seller_details.registered_name AS seller_name,
            model_no
    FROM
        reporting.onboarding
    LEFT OUTER JOIN (SELECT 
        seller_code,
            MAX(registered_name) AS registered_name,
            MAX(contact_no) AS contact_no,
            MAX(payment_terms) AS payment_terms,
            MAX(REPLACE(pickup_address, ',', ';')) AS pickup_address
    FROM
        reporting.seller_details
    GROUP BY 1) AS seller_details ON onboarding.vendor_code = seller_details.seller_code
    WHERE
        vendor_location = 'KSA'
    ORDER BY 2 , 4 DESC , 6 DESC , 8 ASC , 5) t1, (SELECT @curRow:=0, @bidsType:='') r
    GROUP BY 3) AS first_KSA_vendor ON first_KSA_vendor.wadi_sku_num = indexer.bids
    LEFT OUTER JOIN (SELECT 
        vendor_name, MAX(procurement_distribution) AS owner
    FROM
        reporting.am_vendor_mapping
    GROUP BY 1) AS procurement_owner_2 ON procurement_owner_2.vendor_name = first_KSA_vendor.vendor_code
    LEFT OUTER JOIN (SELECT 
        t1.vendor_code,
            seller_name,
            wadi_sku_num,
            model_no,
            TP,
            stock,
            vendor_location,
            days,
            payment_terms,
            TP_check,
            (CASE wadi_sku_num
                WHEN @bidsType THEN @curRow:=@curRow + 1
                ELSE @curRow:=1 AND @bidsType:=wadi_sku_num
            END) + 1 AS rank
    FROM
        (SELECT 
        vendor_code,
            wadi_sku_num,
            CAST(REPLACE(seller_tp, ',', '') AS SIGNED) AS TP,
            CASE
                WHEN seller_inventory <> '0' THEN 5
                ELSE 0
            END AS stock,
            vendor_location,
            CASE
                WHEN (LEFT(payment_terms, LOCATE('+', payment_terms) - 1)) / 2 + (RIGHT(payment_terms, LENGTH(payment_terms) - LOCATE('+', payment_terms))) >= 10 THEN 2
                WHEN (LEFT(payment_terms, LOCATE('+', payment_terms) - 1)) / 2 + (RIGHT(payment_terms, LENGTH(payment_terms) - LOCATE('+', payment_terms))) > 0 THEN 1
                ELSE 0
            END AS days,
            payment_terms,
            (CASE
                WHEN vendor_location = 'UAE' THEN 1
                ELSE 0.96
            END) * CAST(seller_tp AS SIGNED) AS TP_check,
            seller_details.registered_name AS seller_name,
            model_no
    FROM
        reporting.onboarding
    LEFT OUTER JOIN (SELECT 
        seller_code,
            MAX(registered_name) AS registered_name,
            MAX(contact_no) AS contact_no,
            MAX(payment_terms) AS payment_terms,
            MAX(REPLACE(pickup_address, ',', ';')) AS pickup_address
    FROM
        reporting.seller_details
    GROUP BY 1) AS seller_details ON onboarding.vendor_code = seller_details.seller_code
    WHERE seller_inventory <> '0' and
        vendor_location = 'UAE'
    ORDER BY 2 , 4 DESC , 6 DESC , 8 ASC , 5) t1, (SELECT @curRow:=0, @bidsType:='') r
    GROUP BY 3) AS first_UAE_vendor ON first_UAE_vendor.wadi_sku_num = indexer.bids
    LEFT OUTER JOIN (SELECT 
        vendor_name, MAX(procurement_distribution) AS owner
    FROM
        reporting.am_vendor_mapping
    GROUP BY 1) AS procurement_owner_3 ON procurement_owner_3.vendor_name = first_UAE_vendor.vendor_code
    LEFT OUTER JOIN (SELECT 
        seller_code,
            MAX(registered_name) AS registered_name,
            MAX(contact_no) AS contact_no,
            MAX(payment_terms) AS payment_terms,
            MAX(REPLACE(pickup_address, ',', ';')) AS pickup_address
    FROM
        reporting.seller_details
    GROUP BY 1) AS seller_details ON erp.vendor_code = seller_details.seller_code
    LEFT OUTER JOIN (SELECT 
        bids
    FROM
        reporting.restricted_items
    GROUP BY 1) AS restricted ON restricted.bids = indexer.bids
    WHERE
        indexer.bob_item_status = 'exported'
            OR indexer.bob_item_status = 'exportable') as TP
Where Action in ('Handover priority 1','Handover priority 2','Handover priority 3','Hunting','TP confirmation priority 1','TP confirmation priority 2','TP confirmation priority 3')
and is_restricted = 0
and left(vendor_code,2) = 'SV'
and left(uae_vendor,1) = 'V'