SELECT 
    ai.bids,
    ai.serial_number,
    sn.document_no,
    REPLACE(REPLACE(REPLACE(wc.product_name, ',', ''),'',''),'','') product_name,
    ai.bin_code,
    ai.cost_per_unit,
    ai.expected_cost,
    sn.vendor_no,
    sn.vendor_name,
    owner.procurement_distribution,
    dam.remarks AS customer_issue,
    dam.Remark1 AS wh_remarks,
    dam.reason_code
FROM
    replica_ageing_inventory ai
        LEFT JOIN
    my_procurement.damagetype dam ON dam.serial_number = ai.serial_number
        LEFT JOIN
    (SELECT 
        *
    FROM
        my_procurement.sor_report
    WHERE
        location_code = 'DXB'
            AND transaction_type = 'Purchase') sn ON sn.serial_no = ai.serial_number
        LEFT JOIN
    wadi_catalog wc ON wc.bids = ai.bids
        LEFT JOIN
    replica_am_vendor_mapping owner ON sn.vendor_no = owner.vendor_name
WHERE
    bin_code LIKE '%SOURCING%'
        AND ai.location_code = 'DXB';