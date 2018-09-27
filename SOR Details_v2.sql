SELECT 
    sor.item_no,
    wc.product_name,
    wc.model_no,
    wc.size,
    sor.Stock_on_start,
    sor.Item_purchased,
    sor.Item_Returned,
    sor.Sold,
    sor.Customer_Returned,
    sor.Current_Inventory,
    IFNULL(CASE
                WHEN
                    sor.unit_cost = '0'
                THEN
                    IF(ai.cost_per_unit = '0',
                        sor.Sales * ai.expected_cost,
                        sor.Sales * ai.cost_per_unit)
                ELSE sor.Sales * sor.unit_cost
            END,
            '') AS Sale_Value,
    IFNULL(CASE
                WHEN
                    sor.unit_cost = '0'
                THEN
                    IF(ai.cost_per_unit = '0',
                        sor.Current_Inventory * ai.expected_cost,
                        sor.Current_Inventory * ai.cost_per_unit)
                ELSE sor.Current_Inventory * sor.unit_cost
            END,
            '') AS Stock_Value
FROM
    (SELECT 
        item_no,
            SUM(IF(DATE(posting_date) <= DATE(NOW()) - INTERVAL 15 DAY, quantity, 0)) AS Stock_on_start,
            SUM(IF(DATE(posting_date) > DATE(NOW()) - INTERVAL 15 DAY
                AND transaction_type = 'Purchase'
                AND quantity = 1, 1, 0)) AS Item_purchased,
            SUM(IF(DATE(posting_date) > DATE(NOW()) - INTERVAL 15 DAY
                AND transaction_type = 'Sales'
                AND quantity = - 1, 1, 0)) AS Sold,
            SUM(IF(DATE(posting_date) > DATE(NOW()) - INTERVAL 15 DAY
                AND transaction_type = 'Purchase'
                AND quantity = - 1, 1, 0)) AS Item_Returned,
            SUM(IF(DATE(posting_date) > DATE(NOW()) - INTERVAL 15 DAY
                AND transaction_type = 'Sales'
                AND quantity = - 1, 1, 0)) AS Sales,
            SUM(IF(DATE(posting_date) > DATE(NOW()) - INTERVAL 15 DAY
                AND transaction_type = 'Sales'
                AND quantity = 1, 1, 0)) AS Customer_Returned,
            SUM(quantity) AS Current_Inventory,
            unit_cost
    FROM
        sor_report t
    WHERE
        vendor_no = 'SV00290'
    GROUP BY 1) sor
        LEFT OUTER JOIN
    (SELECT 
        bids, product_name, model_no, size
    FROM
        wadi_catalog) wc ON sor.item_no = wc.bids
        LEFT OUTER JOIN
    (SELECT 
        bids, cost_per_unit, expected_cost
    FROM
        ageing_inventory) ai ON sor.item_no = ai.bids
GROUP BY 1;


select sor.item_no,wc.product_name,wc.model_no,wc.size,sor.Stock_on_start,sor.Item_purchased,sor.Item_Returned,sor.Sold,sor.Customer_Returned,sor.Current_Inventory,ifnull(case when sor.unit_cost = '0' then if(ai.cost_per_unit = '0',sor.Sales*ai.expected_cost,sor.Sales*ai.cost_per_unit) ELSE sor.Sales* sor.unit_cost end,'') as Sale_Value,ifnull(case when sor.unit_cost = '0' then if(ai.cost_per_unit = '0',sor.Current_Inventory*ai.expected_cost,sor.Current_Inventory*ai.cost_per_unit) ELSE sor.Current_Inventory* sor.unit_cost end,'') as Stock_Value from (select item_no,sum(if(date(posting_date)<= date(now()) - interval 15 day,quantity,0)) as Stock_on_start,sum(if(date(posting_date)> date(now()) - interval 15 day and transaction_type ='Purchase' and quantity = 1,1,0)) as Item_purchased,sum(if(date(posting_date)> date(now()) - interval 15 day and transaction_type ='Sales' and quantity = -1,1,0)) as Sold,sum(if(date(posting_date)> date(now()) - interval 15 day and transaction_type ='Sales' and quantity = 1,1,0)) as
 Item_Returned,sum(if(date(posting_date)> date(now()) - interval 15 day and transaction_type ='Sales',quantity,0)) * -1 as Sales,sum(if(date(posting_date)> date(now()) - interval 15 day and transaction_type ='Sales' and quantity = 1,1,0)) as Customer_Returned,sum(quantity) as Current_Inventory,unit_cost from sor_report t where vendor_no = 'SV00028' group by 1) sor LEFT OUTER JOIN (select bids,product_name,model_no,size from wadi_catalog) wc on sor.item_no  = wc.bids LEFT OUTER JOIN (select bids,cost_per_unit,expected_cost from ageing_inventory) ai on sor.item_no  = ai.bids group by 1;
;