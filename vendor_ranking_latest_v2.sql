DELIMITER $$
create procedure pricing.calc_vendor_ranking()

BEGIN

# drop table if exists wadi_retail.vendor_ranking;
insert into wadi_retail.vendor_ranking(vendor_code,bids,TP,in_stock,location,days,ffc,registered_name,model_number,payment_terms,procurement_owner,rank,uae_rank,ksa_rank)
(SELECT
        t1.seller_code
        ,t1.bids
        ,TP
        ,in_stock
        ,location
        ,days
        ,ffc
        ,registered_name
        ,model_number 
        ,payment_terms
        ,procurement_owner
        ,(CASE t1.bids
                WHEN @bidsType
                THEN @curRow := @curRow + 1
                ELSE @curRow := 1 AND @bidsType := t1.bids
        END) + 1 AS rank
        ,IF(location = 'UAE'
                ,(CASE t1.bids
                        WHEN @bidsTypeuae
                        THEN @curRowuae := @curRowuae + 1
                        ELSE @curRowuae := 1 AND @bidsTypeuae := t1.bids
                END) + 1
                ,0
        ) as uae_rank
        ,IF(location = 'KSA'
                ,(CASE t1.bids
                        WHEN @bidsTypeksa
                        THEN @curRowksa := @curRowksa + 1
                        ELSE @curRowksa := 1 AND @bidsTypeksa := t1.bids
                END) + 1
                ,0
        ) as ksa_rank
FROM
        (SELECT
                onboarding.seller_code #1
                ,onboarding.bids  #2
                ,tp as TP #3
                ,if(onboarding.inventory = 0, 0, 1) as in_stock #4
                ,onboarding.location#5
                ,case
                        when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) >= 10 then 2
                        when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) > 0 then
                        case
                                when onboarding.location = 'KSA' then 2
                                else 1
                        end
                        else 0
                end as days #6
                ,tp*if(onboarding.location = 'KSA', 0.98, 1) + ifnull(ffc_subcat.total_ffc,ifnull(ffc_supercat.total_ffc,0)) +
                case
                        when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) >= 10 then -30
                        when (left(payment_terms,locate('+',payment_terms)-1))/2 + (right(payment_terms,length(payment_terms)-locate('+',payment_terms))) > 0 then 0
                        else 30
                end
                as TP_and_ffc_and_seller_priority #7
                ,ifnull(ffc_subcat.total_ffc,ifnull(ffc_supercat.total_ffc,0)) as ffc #8
                ,registered_name #9
                ,onboarding.model_number #10
                ,payment_terms #11
                ,procurement_owner #12
FROM
                wadi_retail.onboarding
                LEFT OUTER JOIN pricing.catalog on catalog.bids = onboarding.bids
                LEFT OUTER JOIN
                (SELECT
                        shipping_location
                        ,super_category
                        ,sub_category_1
                        ,nmv_ffc  as total_ffc
                FROM
                        wadi_retail.ffc
                GROUP BY
                        1,2,3) as ffc_subcat 
                        on catalog.super_category = ffc_subcat.super_category
                        and catalog.sub_category_1	 = ffc_subcat.sub_category_1
                        and ffc_subcat.shipping_location = IF(onboarding.location = 'UAE', 'DXB', 'KSA')

                LEFT OUTER JOIN
                (SELECT
                        shipping_location
                        ,super_category
                        ,nmv_ffc as total_ffc
                FROM
                        wadi_retail.ffc
                GROUP BY
                        1,2) as ffc_supercat 
                        on catalog.super_category = ffc_supercat.super_category
                        and ffc_supercat.shipping_location = IF(onboarding.location = 'UAE', 'DXB', 'KSA')

                LEFT OUTER JOIN
(SELECT
                        seller_details.seller_code
                        ,MAX(replace(replace(registered_name, '\n', ''), '\r', '')) as registered_name
                        ,MAX(contact_no) as contact_no
                        ,MAX(payment_terms) as payment_terms
                        ,MAX(REPLACE(pickup_address,',',';')) as pickup_address
                FROM
                        wadi_retail.seller_details
                GROUP BY
                        1) as seller_details on onboarding.seller_code = seller_details.seller_code

                LEFT OUTER JOIN
                (SELECT
                        vendor_name
                        ,replace(replace(procurement_distribution, '\n', ''), '\r', '') as procurement_owner
                FROM
                        wadi_retail.am_vendor_mapping
                ) as am_vendor_mapping on am_vendor_mapping.vendor_name = onboarding.seller_code
        
        ORDER BY
                2
                ,4 desc
                ,7 asc
                ,5 asc
        ) t1, (SELECT @curRow := 0, @bidsType := '') r, (SELECT @curRowuae := 0, @bidsTypeuae := '') ruae, (SELECT @curRowksa := 0, @bidsTypeksa := '') rksa)
        ON duplicate key update TP=values(TP),in_stock = values(in_stock),location = values(location),days =values(days),ffc=values(ffc),registered_name = values(registered_name)
        ,model_number = values(model_number)
        ,payment_terms = values(payment_terms)
        ,procurement_owner = values(procurement_owner)
        ,rank =values(rank)
        ,uae_rank=values(uae_rank)
        ,ksa_rank = values(ksa_rank);
        
        
END $$
DELIMITER ;