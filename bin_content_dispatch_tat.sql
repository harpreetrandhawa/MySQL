Select bids,
round(if(dxb_inventory-avg_dxb<3,3,dxb_inventory-avg_dxb),1)proxy_dxb,
round(if(ksa_inventory-avg_ksa<3,3,ksa_inventory-avg_ksa),1)proxy_ksa,
is_restricted

from
		(SELECT bin.bids,
		sum(if(location='DXB',quantity,0))dxb_inventory,
		sum(if(location='KSA',quantity,0))ksa_inventory,
		sales.avg_dxb,
		sales.avg_ksa,
		sales.is_restricted

		FROM nm_sourcing.replica_bin_content bin
		 left join 
			(select sku,
				avg(dxb)*0.1 as avg_dxb,
				avg(ksa)*0.1 as avg_ksa,
				is_restricted
				from (Select sku,
					sum(if(location = 'DXB',1,0))dxb,
					sum(if(location = 'KSA',1,0))ksa,
					date(shipped_at + interval 4 hour)shipped_at,
					if(ri.bids is null,0,1)is_restricted

					from sales_order_item_erp erp
					
					left join
					restricted_items ri on ri.bids = erp.sku

					where date(shipped_at + interval 4 hour) >= (curdate() - interval 7 day)
					group by date(shipped_at + interval 4 hour),sku)sales group by sku)sales on sales.sku = bin.bids

		group by bids having avg_dxb is not null)main ;



