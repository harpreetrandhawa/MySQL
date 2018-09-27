select 
	 cc.bids
	,sku_config
	,ifnull(wc.sup_category,LTRIM(RTRIM(substring_index(substring_index(replace(replace(replace(replace(cc.categories,'Root Category | ',''),',',''),'\n',''),'\r',''),'|',1),'|',-1)))) AS super_category
	,ifnull(wc.category,LTRIM(RTRIM(substring_index(substring_index(replace(replace(replace(replace(cc.categories,'Root Category | ',''),',',''),'\n',''),'\r',''),'|',2),'|',-1)))) AS category
	,ifnull(wc.sub_category_1,LTRIM(RTRIM(substring_index(substring_index(replace(replace(replace(replace(cc.categories,'Root Category | ',''),',',''),'\n',''),'\r',''),'|',3),'|',-1)))) AS sub_cat_1
	,pet_approved
	,sum(case 
		when 
			pet_approved = 1
			and config_status = 'active'
			and simple_status = 'active'
			and source_status = 'active'
			and pet_status = 'creation,edited,images'
			and shop_visibility_ae = 1
			and (price_ae > 0 and price_ae <> 91919191)
			and supplier = 989
		then 1
		else 0
	end )as live_ae
	,sum(case 
		when 
			pet_approved = 1
			and config_status = 'active'
			and simple_status = 'active'
			and source_status = 'active'
			and pet_status = 'creation,edited,images'
			and shop_visibility_sa = 1
			and (price_sa > 0 and price_sa <> 91919191)
			and supplier = 989
		then 1
		else 0
	end )as live_sa
	,sum(case 
		when 
			pet_approved = 1
			and config_status = 'active' 
			and simple_status = 'active'
			and source_status = 'active'
			and pet_status = 'creation,edited,images'
			and shop_visibility_ae = 1
			and (price_ae > 0 and price_ae <> 91919191)
			and supplier = 991
		then 1
		else 0
	end) as live_wh_ae
	,sum(case 
		when 
			pet_approved = 1
			and config_status = 'active' 
			and simple_status = 'active'
			and source_status = 'active'
			and pet_status = 'creation,edited,images'
			and shop_visibility_sa = 1
			and (price_sa > 0 and price_sa <> 91919191)
			and supplier = 991
		then 1
		else 0
	end) as live_wh_sa
from 
	reporting.catalog_cache cc
left join reporting.wadi_catalog wc on cc.bids = wc.bids
where 
		(left(cc.bids,1) = 'W' and right(bids,1) = 'J')
		and cc.config_status <> 'deleted'
group by 1
