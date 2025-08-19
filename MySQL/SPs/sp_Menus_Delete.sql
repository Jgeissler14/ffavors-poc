drop procedure if exists `sp_Menus_Delete`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Menus_Delete`(InMenu_ID int)
BEGIN
	START TRANSACTION;
	DELETE FROM `ffavors_integ`.`Menu_Roles` WHERE `Menu_ID`= InMenu_ID;
	Delete from `Menus` where `Menu_ID`= InMenu_ID;
    COMMIT;
END