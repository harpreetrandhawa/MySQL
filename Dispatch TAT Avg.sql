Select sku,
round((avg(TAT_7days_Hour)*0.4 + avg(ifnull(TAT_1days_Hour,0))*0.6)+
((avg(TAT_7days_Hour)*0.4 + avg(ifnull(TAT_1days_Hour,0))*0.6)*0.1),2)avg_buf_tat from

(Select t.sku,
(timestampdiff(minute,(exported_at + interval 4 hour),(arrived_at + interval 4 hour)))/60 -
(floor((dayofweek(date(exported_at + interval 4 hour)- interval 6 day)+timestampdiff(day,date(exported_at + interval 4 hour),date(arrived_at + interval 4 hour)))/7))*24 as TAT_7days_Hour,
t1.TAT_1days_Hour
from sales_order_item_erp t
LEFT OUTER JOIN
(
	Select sku,
	(timestampdiff(minute,(exported_at + interval 4 hour),(arrived_at + interval 4 hour)))/60 -
	(floor((dayofweek(date(exported_at + interval 4 hour)- interval 6 day)+timestampdiff(day,date(exported_at + interval 4 hour),date(arrived_at + interval 4 hour)))/7))*24 as TAT_1days_Hour
	from sales_order_item_erp
	where (date(arrived_at + interval 4 hour) = curdate()- interval 1 day) 
	and (arrived_at < canceled_at or canceled_at is null)
	and sku in ('W1315283166','W1315318388','W1315291919','W1315385335','W1315283167','W1315101263','W1315380815','W1315392227','W1315461885','W1315338125','W1315395915','W1315557368','W1315380809','W1315380804','W1315380816','W1315151746','W1315485416','W1315380805','W1315380800','W1315512706','W1315380798','W1315380807','W1315151712','W1315380806','W1315380802','W1315199279','W1315171873','W1315382786','W1315461890','W1315380799','W1315380810','W1315557363','W1315401731','W1315268522','W1315358895','W1315578372','W1315560474','W1315529860','W1315380811','W1315395621','W1315380808','W1315461889','W1315290540','W1315370530','W1315392222','W1315392224','W1315370787','W1315395620','W1315151727','W1315197451','W1315392217','W1315465952','W1315452754','W1315400182','W1315575322','W1315501040','W1315557362','W1315401730','W1315392219','W1315380801','W1315395917','W1315267050','W1315328019','W1315136737','W1315358897','W1315419139','W1315395379','W1315395380','W1315395369','W1315419140','W1315300656','W1315395328','W1315395381','W1315395331','W1315283235','W1315395392','W1315365983','W1315242866','W1315395386','W1315395390','W1315395378','W1315303083','W1315124620','W1315146248','W1315300202','W1315146247','W1315263250','W1315264156','W1315169459','W1315159577','W1315300203','W1315131388','W1315401213','W1315146249','W1315328356','W1315264159','W1315263249','W1315162044','W1315164363','W1315367231','W1315181496','W1315104381','W1315300662','W1315227527','W1315258101','W1315302008','W1315395364','W1315194980','W1315511142','W1315194812','W1315395365','W1315125159','W1315347195','W1315400098','W1315141203','W1315258103','W1315395878','W1315146245','W1315242879','W1315283214','W1315100786','W1315113643','W1315100728','W1315111906','W1315104971','W1315147444','W1315100760','W1315141207','W1315111903','W1315100753','W1315124138','W1315111905','W1315109594','W1315100736','W1315158182','W1315109491','W1315109620','W1315146998','W1315100751','W1315124118','W1315111667','W1315109595','W1315105046','W1315114075','W1315100762','W1315100735','W1315124136','W1315114072','W1315100782','W1315299986','W1315264141','W1315367371','W1315328588','W1315328589','W1315575441','W1315367386','W1315401218','W1315198190','W1315347056','W1315337295','W1315367384','W1315154327','W1315289979','W1315360069','W1315338001','W1315367374','W1315509985','W1315328595','W1315328561','W1315152419','W1315264142','W1315148874','W1315367373','W1315509985','W1315367383','W1315147903','W1315362048','W1315360068','W1315398058','W1315328565','W1315337994','W1315367379','W1315203373','W1315213844','W1315398058','W1315337991','W1315398060','W1315268629','W1315328542','W1315228759','W1315588387','W1315268599','W1315328560','W1315367385','W1315515350','W1315268657','W1315396845','W1315163975','W1315328562','W1315300208','W1315277003','W1315362047','W1315289985','W1315588389','W1315328566','W1315173751','W1315300655','W1315463897','W1315399004','W1315317532','W1315160314','W1315173752','W1315286952','W1315181212','W1315470860','W1315160343','W1315160320','W1315160315','W1315160316','W1315317524','W1315337538','W1315317534','W1315461537','W1315463124','W1315160318','W1315242862','W1315373805','W1315337452','W1315317536','W1315160319','W1315360521','W1315125643','W1315284228','W1315224265','W1315310207','W1315160321','W1315462035','W1315125678','W1315317533','W1315517780','W1315337327','W1315463898','W1315360520','W1315317535','W1315463117','W1315463110','W1315317538','W1315111768','W1315500149','W1315286962','W1315160317','W1315395332','W1315337535','W1315461556','W1315463895','W1315517783','W1315319134','W1315160336','W1315492457','W1315383541','W1315470846','W1315125673','W1315152204','W1315517786','W1315339042','W1315101318','W1315427115','W1315196185','W1315363913','W1315402045','W1315341056','W1315373474','W1315318841','W1315347379','W1315317531','W1315373608','W1315383338','W1315402046','W1315391717','W1315347378','W1315280340','W1315280140','W1315463141','W1315284261','W1315234917','W1315339429','W1315373473','W1315339442','W1315116697','W1315383532','W1315309752','W1315289957','W1315289958','W1315391720','W1315339428','W1315463114','W1315347375','W1315373476','W1315347377','W1315373622','W1315347374','W1315463128','W1315300013','W1315393303','W1315116744','W1315147633','W1315300012','W1315116723','W1315452757','W1315463132','W1315380851','W1315173807','W1315380855','W1315339440','W1315284260','W1315463116','W1315147635','W1315309755','W1315367238','W1315162424','W1315373615','W1315452761','W1315579819','W1315116726','W1315162441','W1315337585','W1315371141','W1315236020','W1315284160','W1315107914','W1315337598','W1315267089','W1315362066','W1315284266','W1315284269','W1315337599','W1315107915','W1315163528','W1315122226','W1315362057','W1315337586','W1315337596','W1315284161','W1315337474','W1315337418','W1315362071','W1315505894','W1315267090','W1315284168','W1315116751','W1315284159','W1315466017','W1315284217','W1315284158','W1315337597','W1315203120','W1315419130','W1315419131','W1315465433','W1315465480','W1315292914','W1315322313','W1315322312','W1315203123','W1315203118','W1315203108','W1315310187','W1315310188','W1315108835','W1315277116','W1315293466','W1315277067','W1315108832','W1315155717','W1315346399','W1315395634','W1315293479','W1315277066','W1315452695','W1315326239','W1315293467','W1315198661','W1315452539','W1315452671','W1315366947','W1315360001','W1315293483','W1315293484','W1315310181','W1315366962','W1315310186','W1315108941','W1315310190','W1315395633','W1315293449','W1315452573','W1315452672','W1315147817','W1315465139','W1315359734','W1315293480','W1315283257','W1315302022','W1315266874','W1315328649','W1315283168','W1315328406','W1315283247','W1315384648','W1315463165','W1315461988','W1315463173','W1315395366','W1315395992','W1315300663','W1315463839','W1315242875','W1315300812','W1315367236','W1315367235','W1315367234','W1315463852','W1315283248','W1315463855','W1315428036','W1315283250','W1315464848','W1315463842','W1315463843','W1315302528','W1315366196','W1315302527','W1315394834','W1315237395','W1315367683','W1315380154','W1315380156','W1315181296','W1315181295','W1315302536','W1315286846','W1315339023','W1315380155','W1315380152','W1315367682','W1315380157','W1315328972','W1315302537','W1315328995','W1315328606','W1315354519','W1315461995','W1315462022','W1315308263','W1315328994','W1315205853','W1315328605','W1315462007','W1315380153','W1315462005','W1315462012','W1315293139','W1315338981','W1315394835','W1315302538','W1315363911','W1315283517','W1315107320','W1315462003','W1315367681','W1315284299','W1315235279','W1315506657','W1315341048','W1315328607','W1315465623','W1315462017','W1315328604','W1315148046','W1315363894','W1315237394','W1315287122','W1315341054','W1315339024','W1315235272','W1315341050','W1315400099','W1315283879','W1315462011','W1315290267','W1315303084','W1315347204','W1315471591','W1315337325','W1315293140','W1315506656','W1315109134','W1315373502','W1315263548','W1315328494','W1315328651','W1315235281','W1315280372','W1315462006','W1315328997','W1315283904','W1315487227','W1315328600','W1315283932','W1315544221','W1315283828','W1315328998','W1315574940','W1315328959','W1315302532','W1315470844','W1315528342','W1315462014','W1315283856','W1315235278','W1315471561','W1315373504','W1315461994','W1315302533','W1315373637','W1315371130','W1315339021','W1315181281','W1315471592','W1315513287','W1315373640','W1315391722','W1315383540','W1315471557','W1315373641','W1315462033','W1315341049','W1315544216','W1315341051','W1315471555','W1315341053','W1315419137','W1315235276','W1315341055','W1315135382','W1315181297','W1315462010','W1315227727','W1315373642','W1315302535','W1315339022','W1315462004','W1315574936','W1315339025','W1315339003','W1315293160','W1315290958','W1315338996','W1315310523','W1315339018','W1315329000','W1315393378','W1315471588','W1315528383','W1315574939','W1315198058','W1315462013','W1315201529','W1315283873','W1315384639','W1315302529','W1315328602','W1315471553','W1315574944','W1315579859','W1315393393','W1315283889','W1315360009','W1315100122','W1315517772','W1315338141','W1315100123','W1315517776','W1315364591','W1315338140','W1315329023','W1315100136','W1315139151','W1315338155','W1315395406','W1315100126','W1315364587','W1315435009','W1315338143','W1315338154','W1315517778','W1315338157','W1315100125','W1315364588','W1315338156','W1315216289','W1315338132','W1315338158','W1315100116','W1315100117','W1315314859','W1315384649','W1315395405','W1315422268','W1315512906','W1315329020','W1315338146','W1315192096','W1315518771','W1315243019','W1315338131','W1315338151','W1315230549','W1315100119','W1315581482','W1315396566','W1315611513','W1315518769','W1315468982','W1315150963','W1315384651','W1315338144','W1315216290','W1315360823','W1315338145','W1315499162','W1315147455','W1315243021','W1315248425','W1315365285','W1315518759','W1315192095','W1315338135','W1315517774','W1315338153','W1315365287','W1315395404','W1315283787','W1315384656','W1315165801','W1315329016','W1315421620','W1315197986','W1315114008','W1315338134','W1315338147','W1315154986','W1315338152','W1315230546','W1315154992','W1315468987','W1315154995','W1315384655','W1315468981','W1315293085','W1315310968','W1315100135','W1315421632','W1315435010','W1315154989','W1315338137','W1315100124','W1315396567','W1315120722','W1315192182','W1315398756','W1315396582','W1315518762','W1315395921','W1315513180','W1315100118','W1315469040','W1315338138','W1315100115','W1315338812','W1315468984','W1315365286','W1315471604','W1315499068','W1315293084','W1315396687','W1315328121','W1315338149','W1315469039','W1315401232','W1315100495','W1315277108','W1315518772','W1315283789','W1315100544','W1315396580','W1315338150','W1315468983','W1315293083','W1315360822','W1315329009','W1315611510','W1315338187','W1315196075','W1315100121','W1315396688','W1315329012','W1315149533','W1315100558','W1315421629','W1315283788','W1315373374','W1315512907','W1315125719','W1315384654','W1315426797','W1315469041','W1315513182','W1315614016','W1315242378','W1315518443','W1315156250','W1315371048','W1315216285','W1315308897','W1315370326','W1315242382','W1315242381','W1315156251','W1315136941','W1315512904','W1315518449','W1315312289','W1315373335','W1315518445','W1315171402','W1315137185','W1315385595','W1315150975','W1315159557','W1315156249','W1315373346','W1315518444','W1315171401','W1315100221','W1315371052','W1315317548','W1315159559','W1315156252','W1315242380','W1315337512','W1315373334','W1315242392','W1315242397','W1315317547','W1315373333','W1315159558','W1315373353','W1315371049','W1315242393','W1315156255','W1315150974','W1315290977','W1315518450','W1315518451','W1315585593')
	)t1 on t.sku = t1.sku

where (date(arrived_at + interval 4 hour) between curdate()- interval 7 day and curdate()- interval 1 day) 
and (arrived_at < canceled_at or canceled_at is null)
and t.sku in ('W1315283166','W1315318388','W1315291919','W1315385335','W1315283167','W1315101263','W1315380815','W1315392227','W1315461885','W1315338125','W1315395915','W1315557368','W1315380809','W1315380804','W1315380816','W1315151746','W1315485416','W1315380805','W1315380800','W1315512706','W1315380798','W1315380807','W1315151712','W1315380806','W1315380802','W1315199279','W1315171873','W1315382786','W1315461890','W1315380799','W1315380810','W1315557363','W1315401731','W1315268522','W1315358895','W1315578372','W1315560474','W1315529860','W1315380811','W1315395621','W1315380808','W1315461889','W1315290540','W1315370530','W1315392222','W1315392224','W1315370787','W1315395620','W1315151727','W1315197451','W1315392217','W1315465952','W1315452754','W1315400182','W1315575322','W1315501040','W1315557362','W1315401730','W1315392219','W1315380801','W1315395917','W1315267050','W1315328019','W1315136737','W1315358897','W1315419139','W1315395379','W1315395380','W1315395369','W1315419140','W1315300656','W1315395328','W1315395381','W1315395331','W1315283235','W1315395392','W1315365983','W1315242866','W1315395386','W1315395390','W1315395378','W1315303083','W1315124620','W1315146248','W1315300202','W1315146247','W1315263250','W1315264156','W1315169459','W1315159577','W1315300203','W1315131388','W1315401213','W1315146249','W1315328356','W1315264159','W1315263249','W1315162044','W1315164363','W1315367231','W1315181496','W1315104381','W1315300662','W1315227527','W1315258101','W1315302008','W1315395364','W1315194980','W1315511142','W1315194812','W1315395365','W1315125159','W1315347195','W1315400098','W1315141203','W1315258103','W1315395878','W1315146245','W1315242879','W1315283214','W1315100786','W1315113643','W1315100728','W1315111906','W1315104971','W1315147444','W1315100760','W1315141207','W1315111903','W1315100753','W1315124138','W1315111905','W1315109594','W1315100736','W1315158182','W1315109491','W1315109620','W1315146998','W1315100751','W1315124118','W1315111667','W1315109595','W1315105046','W1315114075','W1315100762','W1315100735','W1315124136','W1315114072','W1315100782','W1315299986','W1315264141','W1315367371','W1315328588','W1315328589','W1315575441','W1315367386','W1315401218','W1315198190','W1315347056','W1315337295','W1315367384','W1315154327','W1315289979','W1315360069','W1315338001','W1315367374','W1315509985','W1315328595','W1315328561','W1315152419','W1315264142','W1315148874','W1315367373','W1315509985','W1315367383','W1315147903','W1315362048','W1315360068','W1315398058','W1315328565','W1315337994','W1315367379','W1315203373','W1315213844','W1315398058','W1315337991','W1315398060','W1315268629','W1315328542','W1315228759','W1315588387','W1315268599','W1315328560','W1315367385','W1315515350','W1315268657','W1315396845','W1315163975','W1315328562','W1315300208','W1315277003','W1315362047','W1315289985','W1315588389','W1315328566','W1315173751','W1315300655','W1315463897','W1315399004','W1315317532','W1315160314','W1315173752','W1315286952','W1315181212','W1315470860','W1315160343','W1315160320','W1315160315','W1315160316','W1315317524','W1315337538','W1315317534','W1315461537','W1315463124','W1315160318','W1315242862','W1315373805','W1315337452','W1315317536','W1315160319','W1315360521','W1315125643','W1315284228','W1315224265','W1315310207','W1315160321','W1315462035','W1315125678','W1315317533','W1315517780','W1315337327','W1315463898','W1315360520','W1315317535','W1315463117','W1315463110','W1315317538','W1315111768','W1315500149','W1315286962','W1315160317','W1315395332','W1315337535','W1315461556','W1315463895','W1315517783','W1315319134','W1315160336','W1315492457','W1315383541','W1315470846','W1315125673','W1315152204','W1315517786','W1315339042','W1315101318','W1315427115','W1315196185','W1315363913','W1315402045','W1315341056','W1315373474','W1315318841','W1315347379','W1315317531','W1315373608','W1315383338','W1315402046','W1315391717','W1315347378','W1315280340','W1315280140','W1315463141','W1315284261','W1315234917','W1315339429','W1315373473','W1315339442','W1315116697','W1315383532','W1315309752','W1315289957','W1315289958','W1315391720','W1315339428','W1315463114','W1315347375','W1315373476','W1315347377','W1315373622','W1315347374','W1315463128','W1315300013','W1315393303','W1315116744','W1315147633','W1315300012','W1315116723','W1315452757','W1315463132','W1315380851','W1315173807','W1315380855','W1315339440','W1315284260','W1315463116','W1315147635','W1315309755','W1315367238','W1315162424','W1315373615','W1315452761','W1315579819','W1315116726','W1315162441','W1315337585','W1315371141','W1315236020','W1315284160','W1315107914','W1315337598','W1315267089','W1315362066','W1315284266','W1315284269','W1315337599','W1315107915','W1315163528','W1315122226','W1315362057','W1315337586','W1315337596','W1315284161','W1315337474','W1315337418','W1315362071','W1315505894','W1315267090','W1315284168','W1315116751','W1315284159','W1315466017','W1315284217','W1315284158','W1315337597','W1315203120','W1315419130','W1315419131','W1315465433','W1315465480','W1315292914','W1315322313','W1315322312','W1315203123','W1315203118','W1315203108','W1315310187','W1315310188','W1315108835','W1315277116','W1315293466','W1315277067','W1315108832','W1315155717','W1315346399','W1315395634','W1315293479','W1315277066','W1315452695','W1315326239','W1315293467','W1315198661','W1315452539','W1315452671','W1315366947','W1315360001','W1315293483','W1315293484','W1315310181','W1315366962','W1315310186','W1315108941','W1315310190','W1315395633','W1315293449','W1315452573','W1315452672','W1315147817','W1315465139','W1315359734','W1315293480','W1315283257','W1315302022','W1315266874','W1315328649','W1315283168','W1315328406','W1315283247','W1315384648','W1315463165','W1315461988','W1315463173','W1315395366','W1315395992','W1315300663','W1315463839','W1315242875','W1315300812','W1315367236','W1315367235','W1315367234','W1315463852','W1315283248','W1315463855','W1315428036','W1315283250','W1315464848','W1315463842','W1315463843','W1315302528','W1315366196','W1315302527','W1315394834','W1315237395','W1315367683','W1315380154','W1315380156','W1315181296','W1315181295','W1315302536','W1315286846','W1315339023','W1315380155','W1315380152','W1315367682','W1315380157','W1315328972','W1315302537','W1315328995','W1315328606','W1315354519','W1315461995','W1315462022','W1315308263','W1315328994','W1315205853','W1315328605','W1315462007','W1315380153','W1315462005','W1315462012','W1315293139','W1315338981','W1315394835','W1315302538','W1315363911','W1315283517','W1315107320','W1315462003','W1315367681','W1315284299','W1315235279','W1315506657','W1315341048','W1315328607','W1315465623','W1315462017','W1315328604','W1315148046','W1315363894','W1315237394','W1315287122','W1315341054','W1315339024','W1315235272','W1315341050','W1315400099','W1315283879','W1315462011','W1315290267','W1315303084','W1315347204','W1315471591','W1315337325','W1315293140','W1315506656','W1315109134','W1315373502','W1315263548','W1315328494','W1315328651','W1315235281','W1315280372','W1315462006','W1315328997','W1315283904','W1315487227','W1315328600','W1315283932','W1315544221','W1315283828','W1315328998','W1315574940','W1315328959','W1315302532','W1315470844','W1315528342','W1315462014','W1315283856','W1315235278','W1315471561','W1315373504','W1315461994','W1315302533','W1315373637','W1315371130','W1315339021','W1315181281','W1315471592','W1315513287','W1315373640','W1315391722','W1315383540','W1315471557','W1315373641','W1315462033','W1315341049','W1315544216','W1315341051','W1315471555','W1315341053','W1315419137','W1315235276','W1315341055','W1315135382','W1315181297','W1315462010','W1315227727','W1315373642','W1315302535','W1315339022','W1315462004','W1315574936','W1315339025','W1315339003','W1315293160','W1315290958','W1315338996','W1315310523','W1315339018','W1315329000','W1315393378','W1315471588','W1315528383','W1315574939','W1315198058','W1315462013','W1315201529','W1315283873','W1315384639','W1315302529','W1315328602','W1315471553','W1315574944','W1315579859','W1315393393','W1315283889','W1315360009','W1315100122','W1315517772','W1315338141','W1315100123','W1315517776','W1315364591','W1315338140','W1315329023','W1315100136','W1315139151','W1315338155','W1315395406','W1315100126','W1315364587','W1315435009','W1315338143','W1315338154','W1315517778','W1315338157','W1315100125','W1315364588','W1315338156','W1315216289','W1315338132','W1315338158','W1315100116','W1315100117','W1315314859','W1315384649','W1315395405','W1315422268','W1315512906','W1315329020','W1315338146','W1315192096','W1315518771','W1315243019','W1315338131','W1315338151','W1315230549','W1315100119','W1315581482','W1315396566','W1315611513','W1315518769','W1315468982','W1315150963','W1315384651','W1315338144','W1315216290','W1315360823','W1315338145','W1315499162','W1315147455','W1315243021','W1315248425','W1315365285','W1315518759','W1315192095','W1315338135','W1315517774','W1315338153','W1315365287','W1315395404','W1315283787','W1315384656','W1315165801','W1315329016','W1315421620','W1315197986','W1315114008','W1315338134','W1315338147','W1315154986','W1315338152','W1315230546','W1315154992','W1315468987','W1315154995','W1315384655','W1315468981','W1315293085','W1315310968','W1315100135','W1315421632','W1315435010','W1315154989','W1315338137','W1315100124','W1315396567','W1315120722','W1315192182','W1315398756','W1315396582','W1315518762','W1315395921','W1315513180','W1315100118','W1315469040','W1315338138','W1315100115','W1315338812','W1315468984','W1315365286','W1315471604','W1315499068','W1315293084','W1315396687','W1315328121','W1315338149','W1315469039','W1315401232','W1315100495','W1315277108','W1315518772','W1315283789','W1315100544','W1315396580','W1315338150','W1315468983','W1315293083','W1315360822','W1315329009','W1315611510','W1315338187','W1315196075','W1315100121','W1315396688','W1315329012','W1315149533','W1315100558','W1315421629','W1315283788','W1315373374','W1315512907','W1315125719','W1315384654','W1315426797','W1315469041','W1315513182','W1315614016','W1315242378','W1315518443','W1315156250','W1315371048','W1315216285','W1315308897','W1315370326','W1315242382','W1315242381','W1315156251','W1315136941','W1315512904','W1315518449','W1315312289','W1315373335','W1315518445','W1315171402','W1315137185','W1315385595','W1315150975','W1315159557','W1315156249','W1315373346','W1315518444','W1315171401','W1315100221','W1315371052','W1315317548','W1315159559','W1315156252','W1315242380','W1315337512','W1315373334','W1315242392','W1315242397','W1315317547','W1315373333','W1315159558','W1315373353','W1315371049','W1315242393','W1315156255','W1315150974','W1315290977','W1315518450','W1315518451','W1315585593')
)main group by sku;
