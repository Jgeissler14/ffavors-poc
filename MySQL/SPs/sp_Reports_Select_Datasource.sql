Drop PROCEDURE IF EXISTS `sp_Reports_Select_DataSource`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Reports_Select_DataSource`(in_report_name varchar(20))
BEGIN
SELECT r.Report_ID,
    r.Report_Name,
    r.Report_Title,
    r.File_Name,
    r.Data_Source_Type,
    r.Data_Source,
    r.TransDate,
    r.Audit_User
FROM ffavors_integ.Reports r 
where r.Report_Name = in_report_name;

SELECT rp.Param_ID,
    rp.Report_ID,
    rp.Param_Name,
    rp.Order,
    rp.ParamType,
    rp.defaultValue,
    rp.sample,
    rp.ListTable,
    rp.ListValues,
    rp.minValue,
    rp.maxValue,
    rp.Length,
    rp.TransDate,
    rp.defaultValue paramValues
FROM ffavors_integ.Reports r 
	inner join Reports_Parameters rp ON r.Report_ID = rp.Report_ID
where r.Report_Name = in_report_name
Order by rp.Order;
END