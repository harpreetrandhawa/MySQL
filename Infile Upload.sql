LOAD DATA LOCAL INFILE 'C:\\Users\\randh\\Downloads\\table_update.csv' INTO TABLE hk_db.seller_churn
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:\\Users\\randh\\Downloads\\Seller_Mapping.csv' INTO TABLE hk_db.am_mapping
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES ;