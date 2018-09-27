select t.*,  CONCAT(ROUND((arrived_total - assigned_total) / assigned_total * 100,2),'%') Percent_differ from (SELECT 
    case when category in ('Electronics','cameras and photography','Home Entertainment','Computers Laptops And Storage') then 'Electronics'
			when category in ('Beauty, Personal Care and Fragrances','Health, Nutrition and Sports','Beauty & Health','Beauty And Personal Care') then 'Beauty & Health'
			when category in ('Fashion','Jewellery','Eyewear And Sunglasses','Clothing','Bags Wallets And Belts') then 'Fashion'
			when category in ('Daily Needs') then 'Grocery'
            when category in ('Toys, Kids and Baby','toys','Baby Care') then 'Toys, Kids and Baby'
		Else category
       end as Category,
    round(SUM(if(left(vendor_code,1)='S',assign_tp*0.98,assign_tp)),2) assigned_total,
    round(SUM(if(left(vendor_code,1)='S',arrived_tp*0.98,arrived_tp)),2) arrived_total
    FROM
    tbl_seller_performance
WHERE
    left(vendor_code,1)='S' and DATE(arrived_at) = CURDATE() - interval 1 day
GROUP BY 1
Having category !="")t;


