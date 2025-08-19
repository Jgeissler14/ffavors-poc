Drop PROCEDURE IF EXISTS `sp_Menus_Roles_Insert`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Menus_Roles_Insert`(in_Menu_ID int, in_site_id int, in_Roles_id varchar(10), in_Audit_User varchar(15))
BEGIN
INSERT INTO `ffavors_integ`.`Menus_Roles`
(
`Menu_ID`,
`Site_ID`,
`Role_ID`,
`Audit_User`)
VALUES
(in_Menu_ID,
in_Site_ID,
in_Roles_ID,
in_Audit_User);
END