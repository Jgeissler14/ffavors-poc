-- Reports
CALL `ffavors_integ`.`sp_Menus_Insert`(1, 'Reports', null, null, null, 'KDInitialLoad');
set @ParentMenuID = (Select Menu_ID from Menus where Menu_Name='Reports');
CALL `ffavors_integ`.`sp_Menus_Insert`(1, 'List', @ParentMenuID, 'rpt-lst', null, 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Insert`(1, 'Admin', @ParentMenuID, null, null, 'KDInitialLoad');
-- Menus
CALL `ffavors_integ`.`sp_Menus_Insert`(1, 'Menus', null, null, null, 'KDInitialLoad');
set @ParentMenuID = (Select Menu_ID from Menus where Menu_Name='Menus');
CALL `ffavors_integ`.`sp_Menus_Insert`(1, 'Admin', @ParentMenuID, null, null, 'KDInitialLoad');

-- Set Roles outside 99
set @MenuID = (Select Menu_ID from Menus where Menu_Name='Reports');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '05', 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '06', 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '07', 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '09', 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '11', 'KDInitialLoad');

set @MenuID = (Select Menu_ID from Menus where Menu_Name='List');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '05', 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '06', 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '07', 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '09', 'KDInitialLoad');
CALL `ffavors_integ`.`sp_Menus_Roles_Insert`(@MenuID, 1, '11', 'KDInitialLoad');
