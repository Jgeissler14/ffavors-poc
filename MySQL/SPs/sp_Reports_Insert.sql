Drop PROCEDURE IF EXISTS `sp_Reports_Insert`;
CREATE DEFINER=`favI-adm`@`%` PROCEDURE `sp_Reports_Insert`(in_site_id int, in_report_name varchar(20), in_report_type varchar(20),  in_report_title varchar(200), in_file_name varchar(200), in_data_source_type VARCHAR(45),in_data_source varchar(10000), in_audit_user varchar(15), in_role_id varchar(10))
BEGIN
    START TRANSACTION;
	INSERT INTO `ffavors_integ`.`Reports`
	(`Report_Name`,
    `Report_Type`,
	`Report_Title`,
	`File_Name`,
	`Data_Source_Type`,
	`Data_Source`,
	`Audit_User`)
	VALUES
	(in_report_name,
    in_report_type,
	in_report_title,
	in_file_name,
	in_data_source_type,
	in_data_source,
	in_audit_user);
    set @ReportID =last_insert_id();
	if not in_role_id is null then
		INSERT INTO `ffavors_integ`.`Reports_Roles`
		(`Site_ID`,
		`Report_ID`,
		`Role_ID`,
		`Audit_User`)
		VALUES
		(in_site_id ,
		@ReportID,
		in_role_id,
		in_audit_user
		);
	elseif in_site_id=1 and in_report_type='Repository' then
		INSERT INTO `ffavors_integ`.`Reports_Roles`
		(`Site_ID`,
		`Report_ID`,
		`Role_ID`,
		`Audit_User`)
		VALUES
		(in_site_id ,
		@ReportID,
		"05",
		in_audit_user
		);
		INSERT INTO `ffavors_integ`.`Reports_Roles`
		(`Site_ID`,
		`Report_ID`,
		`Role_ID`,
		`Audit_User`)
		VALUES
		(in_site_id ,
		@ReportID,
		"06",
		in_audit_user
		);
        INSERT INTO `ffavors_integ`.`Reports_Roles`
		(`Site_ID`,
		`Report_ID`,
		`Role_ID`,
		`Audit_User`)
		VALUES
		(in_site_id ,
		@ReportID,
		"07",
		in_audit_user
		);
        INSERT INTO `ffavors_integ`.`Reports_Roles`
		(`Site_ID`,
		`Report_ID`,
		`Role_ID`,
		`Audit_User`)
		VALUES
		(in_site_id ,
		@ReportID,
		"09",
		in_audit_user
		);
		INSERT INTO `ffavors_integ`.`Reports_Roles`
		(`Site_ID`,
		`Report_ID`,
		`Role_ID`,
		`Audit_User`)
		VALUES
		(in_site_id ,
		@ReportID,
		"11",
		in_audit_user
		);
	end if;
	COMMIT;
END