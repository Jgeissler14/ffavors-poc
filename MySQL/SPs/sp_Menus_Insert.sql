Drop procedure if exists `sp_Menus_Insert`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Menus_Insert`(In_Site_ID Int, In_Menu_Name varchar(20), In_Parent_ID int, In_URL varchar(250),In_HelpText varchar(2000), In_Audit_User varchar(20))
BEGIN
Start transaction;
	Insert Menus (Menu_Name, ParentID, URL, HelpText, Audit_User)
	Values (In_Menu_Name, In_Parent_ID, In_URL, In_HelpText, In_Audit_User);
    set @Menu_ID = last_insert_id();
    call sp_Menus_Roles_Insert(@Menu_ID, in_site_id, '99', in_Audit_User);
Commit;
END