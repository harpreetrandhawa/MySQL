select concat(db,item_id)item_id, 
order_nr, 
bob_item_status, 
ordered_at, 
exported_at, 
sku, 
bids, 
ascii(item_name)item_name, 
brand, 
unit_price, 
paid_price, 
cancellation_reason_code, 
case 
	when category_level_1 in ('home_entertainment','computers_laptops_and_storage','cameras_and_photography','gaming','automotive','security_devices') then 'Electronics'
    when category_level_1 in ('bags_wallets_and_belts','beauty_and_personal_care','clothing','eyewear_and_sunglasses','footwear','jewellery','watches') then 'Fashion'
    when category_level_1 in ('home_and_kitchen','office_stationery_supplies','accessories') then 'Home, Kitchen and Automotive'
    when category_level_1 in ('toys','luggage_and_travel_gear','sports_and_fitness','health_and_nutrition','baby_care','books','school_supplies') then 'Lifestyle'
    when category_level_1 in ('mobiles_and_accessories') then 'Mobiles'
END super_category, 
category_level_1, 
category_level_2, 
category_level_3, 
category_level_4, 
vendor_code,
if(db='AE',(select short_code from sc_live_ae.seller where src_id = wadi_indexer.vendor_code),
(select short_code from sc_live_sa.seller where src_id = wadi_indexer.vendor_code))short_code

from wadi_indexer where exported_at >= '2018-08-25'
and wadi_indexer.vendor_warehouse_country not in  ('CN','HK','AF') and wadi_indexer.vendor_code not in ('1290','6797','6818')
 and wadi_indexer.category_level_1 not in ( 'daily_needs','seller_accessories');