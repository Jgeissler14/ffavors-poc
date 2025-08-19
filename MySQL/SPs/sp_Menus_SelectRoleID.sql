DROP PROCEDURE IF EXISTS `sp_Menus_SelectbyRoleID`;

CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Menus_SelectbyRoleID`(in_site_ID int, in_Role_ID varchar(10))
BEGIN
IF in_site_id is null THEN SET in_site_id = 1; END IF;
Select cast(m.menu_id as char) as id , m.Menu_Name as text, cast(m.ParentID as char) as parent_id, m.URL as path, m.HelpText
from Menus m inner join Menu_Roles mr on m.Menu_ID = mr.Menu_ID
Where mr.Role_ID = in_role_ID and mr.site_id=in_site_ID
order by  m.menu_id, m.ParentID, m.order ;
END