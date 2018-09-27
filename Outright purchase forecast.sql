Select indexer.bids,indexer.item_name, count(indexer.bids) as item_sell,ai.dxb_inventory,ai.ksa_inventory,
first_KSA_vendor.vendor_code as ksa_vendor_code,first_KSA_vendor.seller_name as ksa_vendor_code,first_KSA_vendor.TP as ksa_vendor_tp,
first_UAE_vendor.vendor_code as uae_vendor_code,first_UAE_vendor.seller_name as uae_vendor_code,first_UAE_vendor.TP as uae_vendor_tp
from wadi_indexer as indexer
LEFT OUTER JOIN
(select bids, sum(if(location_code= 'DXB',1,0)) as dxb_inventory,sum(if(location_code= 'KSA',1,0)) as ksa_inventory 
from ageing_inventory where bin_type_code = 'PUTPICK' group by 1) as ai on ai.bids = indexer.bids

LEFT OUTER JOIN
    (select
        t1.vendor_code
        ,seller_name
        ,wadi_sku_num
        ,TP
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
        ,(case when vendor_location = 'UAE' then 1 else 0.96 end) * cast(seller_tp as signed) as TP_check
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
    (select
        t1.vendor_code
        ,seller_name
        ,wadi_sku_num
        ,model_no
        ,TP
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
,(case when vendor_location = 'UAE' then 1 else 0.96 end) * cast(seller_tp as signed) as TP_check
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
        
where date(ordered_at) >= date(curdate())- interval 30 day and exported_at is not null  group by 1 order by 3 desc limit 50;
