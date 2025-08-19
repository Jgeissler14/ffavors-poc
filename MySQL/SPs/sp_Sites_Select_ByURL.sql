Drop PROCEDURE IF EXISTS `sp_Sites_Select_ByURL`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Sites_Select_ByURL`(in_URL varchar(100))
BEGIN
SELECT *
FROM `ffavors_integ`.`Sites`
where site_URL = in_URL;
END