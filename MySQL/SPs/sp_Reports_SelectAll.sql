Drop PROCEDURE IF EXISTS `sp_Reports_SelectAll`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Reports_SelectAll`(in_site_id int, in_role_id varchar(6))
BEGIN
SELECT r.Report_ID,
    r.Report_Name,
    r.Report_Title,
    r.File_Name,
    r.TransDate,
    r.Audit_User
FROM ffavors_integ.Reports r 
	inner join Reports_Roles rr ON r.Report_ID = rr.Report_ID
where rr.role_id = in_role_id 
AND rr.site_id = in_site_id;

END