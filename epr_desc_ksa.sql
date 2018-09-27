SELECT discode, invoice_code, invoice_no, po_no, item_desc, qty, price, vm.vendor_code, vm.vendor_name, 
master_id, issue_subcat, dm.created_date,dm.loc,
(select remarks  from tbl_descrepancy_remarks where des_id = dm.id limit 1)remarks 
FROM tbl_descrepancy_master dm
left outer join
tbl_senitel_vendor_master vm on vm.vendor_id = dm.vendor_id 
where reason_code='11' and qty-recd_qty !=0 and dm.loc = 'KSA';


