drop procedure if exists `sp_Reports_Select`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Reports_Select`(in_site_id int, in_role_id varchar(6), in_report_name varchar(20))
BEGIN
SELECT r.Report_ID,
    r.Report_Name,
    r.Report_Title,
    r.File_Name,
    case when r.Data_Source_Type='SQL' then r.Report_Name else  r.Data_Source END Data_Source,
    r.Data_Source_Type
FROM ffavors_integ.Reports r 
	inner join Reports_Roles rr ON r.Report_ID = rr.Report_ID
where r.Report_Name = in_report_name
AND rr.role_id = in_role_id 
AND rr.site_id = in_site_id;

SELECT rp.Param_ID,
    rp.Report_ID,
    rp.Param_Name,
    rp.Display_Name,
    rp.Order,
    rp.ParamType,
    rp.defaultValue,
    rp.sample,
    rp.ListTable,
    rp.ListValues,
    rp.minValue,
    rp.maxValue,
    rp.Length,
    rp.defaultValue paramValues
FROM ffavors_integ.Reports r 
	inner join Reports_Parameters rp ON r.Report_ID = rp.Report_ID
    inner join Reports_Roles rr ON r.Report_ID = rr.Report_ID
where r.Report_Name = in_report_name
AND rr.role_id = in_role_id
AND rr.site_id = in_site_id
Order by rp.Order;

SELECT rr.Site_ID,
		rr.Report_ID,
	   rr.Role_ID
FROM ffavors_integ.Reports r 
	inner join Reports_Parameters rp ON r.Report_ID = rp.Report_ID
    inner join Reports_Roles rr ON r.Report_ID = rr.Report_ID
where r.Report_Name = in_report_name
AND rr.role_id = in_role_id
AND rr.site_id = in_site_id
Order by rp.Order;
END