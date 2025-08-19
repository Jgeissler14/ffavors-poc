CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Report_Parameters_Insert`(
in_Report_ID int, in_Param_Name  varchar(45), in_Display_Name varchar(45), in_Order int, in_ParamType varchar(45),
in_Required boolean, in_defaultValue varchar(45),in_sample varchar(100), in_ListTable varchar(100), in_ListValues varchar(300),
in_minValue varchar(45),in_maxValue  varchar(45), in_Length int,in_Audit_User varchar(15))
BEGIN
INSERT INTO `ffavors_integ`.`Reports_Parameters`
(`Report_ID`,
`Param_Name`,
`Display_Name`,
`Order`,
`ParamType`,
`Required`,
`defaultValue`,
`sample`,
`ListTable`,
`ListValues`,
`minValue`,
`maxValue`,
`Length`,
`Audit_User`)
VALUES
(in_Report_ID,
in_Param_Name,
in_Display_Name,
in_Order,
in_ParamType,
in_Required,
in_defaultValue,
in_sample,
in_ListTable,
in_ListValues,
in_minValue,
in_maxValue,
in_Length,
in_Audit_User);
END