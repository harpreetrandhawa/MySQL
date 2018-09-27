select round(((arrived_total-assigned_total)/assigned_total)*100,2)Percentage_difer from (SELECT 
    round(SUM(if(left(vendor_code,1)='S',assign_tp*0.98,assign_tp)),2) assigned_total,
    round(SUM(if(left(vendor_code,1)='S',arrived_tp*0.98,arrived_tp)),2) arrived_total
    
FROM
    tbl_seller_performance
WHERE
   DATE(arrived_at) >= date_format(now(),'%Y-%m-01') - interval 1 day
)t;