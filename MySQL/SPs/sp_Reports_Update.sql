Drop PROCEDURE IF EXISTS `sp_Reports_Update`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Reports_Update`(in_report_id int,in_report_name varchar(20), in_report_title varchar(200), in_file_name varchar(200), in_data_source_type VARCHAR(45),in_data_source varchar(10000), in_audituser varchar(10), in_transdate datetime)
BEGIN
UPDATE `ffavors_integ`.`Reports`
SET
`Report_Name` = in_report_name,
`Report_Title` = in_report_title,
`File_Name` = in_file_name,
`Data_Source_Type` = in_data_source_type,
`Data_Source` = in_data_source,
`TransDate` = in_transdate,
`Audit_User` = in_audit_user
WHERE `Report_ID` = in_report_id;

END