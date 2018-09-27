SELECT 
    UCASE(CONCAT(ind.db, ind.id_sales_order_item)) item_id,
    erp.canceled_at,
    ind.updated_at
FROM
    sales_order_item_custom AS ind
        LEFT JOIN
    replica_sales_order_item_erp erp ON concat(ucase(ind.db),ind.id_sales_order_item) = erp.item_id
WHERE
    ind.updated_at >= '"""+str(dater)+"""'
        AND ind.status = 'canceled';