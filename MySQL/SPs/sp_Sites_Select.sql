Drop PROCEDURE IF EXISTS `sp_Sites_Select`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Sites_Select`(in_site_id int)
BEGIN
SELECT *
FROM `ffavors_integ`.`Sites`
where Site_ID = in_site_id;
END