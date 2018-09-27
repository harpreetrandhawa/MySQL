SELECT 
    t.item_id,
    t.order_nr,
    t.sku,
    t.bids,
    t.item_name,
    t.Super_Category,
    CAST(DATE(t.ExportableDateTime) AS CHAR (100)) AS ExportableDateTime,
    CAST(t.Hours_Since AS CHAR (100)) AS Hours_Since,
    CAST(DATE(t.shipping_date) AS CHAR (100)) AS shipping_date,
    t.type,
    t.po_number,
    t.Status,
    t.Action,
    t.is_restricted,
    t.vendor_code,
    REPLACE(IFNULL(seller_details.registered_name,
                'Not Required'),
        ',',
        '') AS vendor_name,
    t.TP_Price,
    IF(t.vendor_code = 'Find Seller',
        'Not Assigned',
        am_vendor_mapping.owner) AS owner,
    CAST(DATE(t.max_shipping_date) AS CHAR (100)) AS max_shipping_date
FROM
    (SELECT 
        CONCAT(indexer.db, indexer.id_sales_order_item) AS item_id,
            indexer.order_nr,
            indexer.sku,
            indexer.bids,
            CONCAT('"', REPLACE(REPLACE(REPLACE(REPLACE(indexer.item_name, '"', '\''), ',', ' '), ',', ' '), '
            ', ' '), '"') AS item_name,
            CASE
                WHEN MID(indexer.sku, 6, 2) = 'NM' THEN 'Fashion - Namshi'
                ELSE LEFT(REPLACE(REPLACE(indexer.category_list, 'Root Category | ', ''), ' | ', '|'), LOCATE('|', REPLACE(REPLACE(indexer.category_list, 'Root Category | ', ''), ' | ', '|')) - 1)
            END AS Super_Category,
            Exportable.occured_at AS ExportableDateTime,
            DATE(DATE(Exportable.occured_at) + IF(indexer.db = 'SA', indexer.seller_shipping_time_max_sa, indexer.seller_shipping_time_max_ae)) AS shipping_date,
            (TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) / 60) AS Hours_Since,
            IF(MID(indexer.sku, 6, 2) = 'NM', 'Namshi', 'Wadi') AS type,
            erp.po_number,
            CASE
                WHEN
                    erp.arrivel_datetime <> 'No'
                        OR erp.pick_registered = 'Yes'
                THEN
                    'Arrived'
                WHEN
                    erp.pick_line = 'Yes'
                        AND erp.location_code = 'DXB'
                THEN
                    'DXB Inventory pickup'
                WHEN
                    erp.pick_line = 'Yes'
                        AND erp.location_code = 'KSA'
                THEN
                    'KSA Inventory pickup'
                WHEN erp.sales_order_item_id IS NULL THEN 'Not in ERP'
                WHEN
                    erp.arrivel_datetime = 'No'
                        AND erp.po_number <> 'No'
                THEN
                    'PO Created'
                WHEN
                    erp.po_number = 'No'
                        AND erp.pick_line = 'No'
                        AND erp.pick_registered = 'No'
                THEN
                    'TP Confirmation'
            END AS Status,
            CASE
                WHEN MID(indexer.sku, 6, 2) = 'NM' THEN 'Namshi order'
                WHEN indexer.bob_item_status = 'confirmation_pending' THEN 'confirmation_pending'
                WHEN indexer.bob_item_status = 'shipped' THEN 'shipped'
                WHEN erp.pick_line = 'Yes' THEN 'Inventory Pickup'
                WHEN
                    erp.arrivel_datetime = 'No'
                        AND erp.po_number <> 'No'
                        AND erp.pick_registered = 'No'
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) > 2160
                THEN
                    'Handover priority 1'
                WHEN
                    erp.arrivel_datetime = 'No'
                        AND erp.po_number <> 'No'
                        AND erp.pick_registered = 'No'
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) <= 2160
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) > 1440
                THEN
                    'Handover priority 2'
                WHEN
                    erp.arrivel_datetime = 'No'
                        AND erp.po_number <> 'No'
                        AND erp.pick_registered = 'No'
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) <= 1440
                THEN
                    'Handover priority 3'
                WHEN
                    erp.sales_order_item_id IS NULL
                        OR erp.arrivel_datetime <> 'No'
                        OR erp.pick_registered = 'Yes'
                THEN
                    'No Action'
                WHEN
                    erp.po_number = 'No'
                        AND erp.pick_line = 'No'
                        AND erp.pick_registered = 'No'
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) > 3600
                THEN
                    'Hunting'
                WHEN
                    erp.po_number = 'No'
                        AND erp.pick_line = 'No'
                        AND erp.pick_registered = 'No'
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) <= 3600
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) > 2160
                THEN
                    'TP confirmation priority 1'
                WHEN
                    erp.po_number = 'No'
                        AND erp.pick_line = 'No'
                        AND erp.pick_registered = 'No'
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) <= 2160
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) > 1440
                THEN
                    'TP confirmation priority 2'
                WHEN
                    erp.po_number = 'No'
                        AND erp.pick_line = 'No'
                        AND erp.pick_registered = 'No'
                        AND TIMESTAMPDIFF(MINUTE, Exportable.occured_at, DATE_ADD(NOW(), INTERVAL 4 HOUR)) <= 1440
                THEN
                    'TP confirmation priority 3'
            END AS Action,
            REPLACE(REPLACE(REPLACE(REPLACE(seller_details.registered_name, '"', '\''), ',', ' '), ',', ' '), '
            ', ' ') AS vendor_name,
            CASE
                WHEN
                    erp.po_number = 'No'
                        AND erp.pick_line = 'No'
                        AND erp.pick_registered = 'No'
                THEN
                    CASE
                        WHEN
                            restricted.bids IS NOT NULL
                                AND indexer.db = 'SA'
                        THEN
                            IFNULL(REPLACE(REPLACE(REPLACE(first_KSA_vendor.TP, ',', ''), '
                            ', ''), '', ''), '0')
                        WHEN
                            indexer.db = 'AE'
                        THEN
                            IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.TP, ',', ''), '
                            ', ''), '', ''), '0')
                        ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.TP, ',', ''), '
                        ', ''), '', ''), '0')
                    END
                ELSE indexer.transfer_price
            END AS TP_Price,
            CASE
                WHEN restricted.bids IS NOT NULL THEN IF(indexer.db = 'SA', 'KSA Restricted', 'DXB Restricted')
                ELSE 'No'
            END AS is_restricted,
            CASE
                WHEN
                    erp.po_number = 'No'
                        AND erp.pick_line = 'No'
                        AND erp.pick_registered = 'No'
                THEN
                    CASE
                        WHEN
                            restricted.bids IS NOT NULL
                                AND indexer.db = 'SA'
                        THEN
                            IFNULL(REPLACE(REPLACE(REPLACE(first_KSA_vendor.vendor_code, ',', ''), '
                            ', ''), '', ''), 'Find Seller')
                        WHEN
                            indexer.db = 'AE'
                        THEN
                            IFNULL(REPLACE(REPLACE(REPLACE(first_UAE_vendor.vendor_code, ',', ''), '
                            ', ''), '', ''), 'Find Seller')
                        ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.vendor_code, ',', ''), '
                        ', ''), '', ''), 'Find Seller')
                    END
                ELSE erp.vendor_code
            END AS vendor_code,
            DATE_ADD(DATE(DATE_ADD(DATE(Exportable.occured_at), INTERVAL IF(indexer.db = 'SA', seller_shipping_time_max_sa, seller_shipping_time_max_ae) DAY)), INTERVAL (FLOOR((IF(indexer.db = 'SA', indexer.seller_shipping_time_max_sa, indexer.seller_shipping_time_max_ae) + DAYOFWEEK(DATE(DATE(Exportable.occured_at + INTERVAL 1 DAY) - INTERVAL 6 DAY))) / 7)) + 1 DAY) AS max_shipping_date,
            IF(indexer.db = 'SA', FLOOR((indexer.seller_shipping_time_max_sa + DAYOFWEEK((DATE(date(Exportable.occured_at) + INTERVAL 1 DAY) - 6))) / 7), FLOOR((indexer.seller_shipping_time_max_sa + DAYOFWEEK((DATE(date(Exportable.occured_at) + INTERVAL 1 DAY) - 6))) / 7)) AS friday_nr
    FROM
        reporting.wadi_indexer AS indexer
    LEFT OUTER JOIN (SELECT 
        db, item_id, MIN(occured_at) AS occured_at
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
    WHERE
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
            OR indexer.bob_item_status = 'exportable') AS t
        LEFT OUTER JOIN
    (SELECT 
        vendor_name,
            registered_name,
            MAX(procurement_distribution) AS owner
    FROM
        reporting.am_vendor_mapping
    GROUP BY 1) AS am_vendor_mapping ON am_vendor_mapping.vendor_name COLLATE utf8_unicode_ci = t.vendor_code
        LEFT OUTER JOIN
    (SELECT 
        seller_code, registered_name
    FROM
        seller_details
    GROUP BY 1) AS seller_details ON seller_details.seller_code = t.vendor_code
WHERE
    t.Status IN ('TP Confirmation' , 'PO Created',
        'Arrived',
        'KSA Inventory pickup',
        'DXB Inventory pickup')
        AND t.max_shipping_date <= CURDATE()
        AND t.bids != 'W1315999999'