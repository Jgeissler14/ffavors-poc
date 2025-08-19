-- customer
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS904A','Embedded','FFAVS904A - DETAIL USAGE','FFAVS904A.trdp',null,null,'kdItitalLoad','02');
set @ReportID = (Select Report_ID from Reports where Report_Name='FFAVS904A');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'BEGDT', 'Begin Date', '1', 'date', '1', '01/01/2025', '01/01/2022', '12/31/2030', '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'ENDDT', 'End Date', '2', 'date', '2', '01/01/2025', '01/01/2022', '12/31/2030', '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'VAR1', 'State or District Code:', '3', 'string', '1', '10', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'LOCALONLY', 'Enter Y or N for Local:', '4', 'string', '1', '1', 'kdItitalLoad');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS905A','Embedded','FFAVS905A - SUMMARY USAGE','FFAVS905A.trdp',null,null,'kdItitalLoad','02');
set @ReportID = (Select Report_ID from Reports where Report_Name='FFAVS905A');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'BEGDT', 'Begin Date', '1', 'date', '1', '01/01/2025', '01/01/2022', '12/31/2030', '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'ENDDT', 'End Date', '2', 'date', '1', '01/01/2025', '01/01/2022', '12/31/2030', '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`, `Trans_Date`) 
VALUES (@ReportID, 'VAR1', 'State or District Code:', '3', 'string', '1', '10', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`, `Trans_Date`) 
VALUES (@ReportID, 'LOCALONLY', 'Enter Y or N for Local:', '4', 'string', '1', '1', 'kdItitalLoad');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS905B','Embedded','FFAVS905B - SUMMARY USAGE BY RDD','FFAVS905B.trdp',null,null,'kdItitalLoad','02');
set @ReportID = (Select Report_ID from Reports where Report_Name='FFAVS905B');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'BEGDT', 'Begin Date', '1', 'date', '1', '01/01/2025', '01/01/2022', '12/31/2030', '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'ENDDT', 'End Date', '2', 'date', '1', '01/01/2025', '01/01/2022', '12/31/2030', '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'VAR1', 'State or District Code:', '3', 'string', '1', '10', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'LOCALONLY', 'Enter Y or N for Local:', '4', 'string', '1', '1', 'kdItitalLoad');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS9056','Embedded','FFAVS9056 - SUMMARY USAGE BY DISTRICT','FFAVS9056.trdp',null,null,'kdItitalLoad','02');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS906A','Embedded','FFAVS906A - BUDGET DOLLARS','FFAVS906A.trdp',null,null,'kdItitalLoad','02');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS906B','Embedded','FFAVS906B - BUDGET DOLLARS','FFAVS906B.trdp',null,null,'kdItitalLoad','02');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS906C','Embedded','FFAVS906C - BUDGET DOLLARS','FFAVS906C.trdp',null,null,'kdItitalLoad','02');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS907','Embedded','FFAVS907 - USER LISTING','FFAVS907.trdp',null,null,'kdItitalLoad','02');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS912','Embedded','FFAVS912 - CATALOG REPORT','FFAVS912.trdp',null,null,'kdItitalLoad','01');
set @ReportID = (Select Report_ID from Reports where Report_Name='FFAVS912');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'CONTRNUM', 'Contract BPA Number', '1', 'string', '1', 'DS096', NULL, NULL, '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'PIIN_YR', 'Contract PIIN Year', '2', 'integer', '1', NULL, NULL, NULL, NULL, 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'EFFDATE', 'Effective Date', '3', 'object', '1', NULL, NULL, NULL, NULL, 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'WHERE1', 'Where Statement', '4', 'object', '0', NULL, NULL, NULL, NULL, 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'SORT1', 'Sort Statement', '5', 'object', '0', NULL, NULL, NULL, NULL, 'kdItitalLoad');



CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS915','Embedded','FFAVS915 - CUSTOMER CATALOG','FFAVS915.trdp',null,null,'kdItitalLoad','02');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS921','Embedded','FFAVS921 - DELIVERY DAY','FFAVS921.trdp',null,null,'kdItitalLoad','02');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS930','Embedded','FFAVS930 - ORGANIZATION - POC LISTING ','FFAVS930.trdp',null,null,'kdItitalLoad','02');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS931','Embedded','FFAVS931 - ORGANIZATION - POC LISTING ','FFAVS931.trdp',null,null,'kdItitalLoad','02');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS933A','Embedded','FFAVS933A - FDPIR CATALOG REPORT','FFAVS933A.trdp',null,null,'kdItitalLoad','02');
set @ReportID = (Select Report_ID from Reports where Report_Name='FFAVS933A');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'programID', 'Program:', '1', 'string', '1', '6', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'Sort1', 'Column to Sort:', '2', 'string', '1', '10', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'Dir1', 'Direction of Sort:', '3', 'string', '1', '4', 'kdItitalLoad');

-- vendor
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS908A','Embedded','FFAVS908A - VENDOR DETAIL','FFAVS908A.trdp',null,null,'kdItitalLoad','01');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS909A','Embedded','FFAVS909A - VENDOR SUMMARY','FFAVS909A.trdp',null,null,'kdItitalLoad','01');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS910','Embedded','FFAVS910 - ORDERS SUMMARY BY ITEM REPORT','FFAVS910.trdp',null,null,'kdItitalLoad','01');
set @ReportID = (Select Report_ID from Reports where Report_Name='FFAVS910');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'CONTRNUM', 'Contract BPA Number', '1', 'string', '1', 'DS096', NULL, NULL, '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'PIIN_YR', 'Contract PIIN Year', '2', 'integer', '1', NULL, NULL, NULL, NULL, 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'JULDATE', 'JULIAN Date', '3', 'object', '1', NULL, NULL, NULL, NULL, 'kdItitalLoad');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS911','Embedded','FFAVS911 - VENDOR FINAL BUY REPORT','FFAVS911.trdp',null,null,'kdItitalLoad','01');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS911A','Embedded','FFAVS911A - VENDOR FINAL BUY NO HEADERS REPORT','FFAVS911A.trdp',null,null,'kdItitalLoad','01');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS912A','Embedded','FFAVS912 - VENDOR CATALOG REPORT','FFAVS912.trdp',null,null,'kdItitalLoad','01');
set @ReportID = (Select Report_ID from Reports where Report_Name='FFAVS912A');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'CONTRNUM', 'Contract BPA Number', '1', 'string', '1', 'DS096', NULL, NULL, '8', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'PIIN_YR', 'Contract PIIN Year', '2', 'integer', '1', NULL, NULL, NULL, NULL, 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'EFFDATE', 'Effective Date', '3', 'object', '1', NULL, NULL, NULL, NULL, 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'WHERE1', 'Where Statement', '4', 'object', '1', NULL, NULL, NULL, NULL, 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `sample`, `minValue`, `maxValue`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'SORT1', 'Sort Statement', '5', 'object', '1', NULL, NULL, NULL, NULL, 'kdItitalLoad');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS913','Embedded','FFAVS913 - SEARCH CATALOG REPORT','FFAVS913.trdp',null,null,'kdItitalLoad','01');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS914','Embedded','FFAVS914 - BASELINE CATALOG REPORT','FFAVS914.trdp',null,null,'kdItitalLoad','01');
CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS922','Embedded','FFAVS922 - VENDOR DELIVERY DAY','FFAVS922.trdp',null,null,'kdItitalLoad','01');

CALL `ffavors_integ`.`sp_Reports_Insert`(1,'FFAVS933','Embedded','FFAVS933 - FDPIR CATALOG REPORT','FFAVS933.trdp',null,null,'kdItitalLoad','01');
set @ReportID = (Select Report_ID from Reports where Report_Name='FFAVS933');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'programID', 'Program:', '1', 'string', '1', '6', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'Sort1', 'Column to Sort:', '2', 'string', '1', '10', 'kdItitalLoad');
INSERT INTO `ffavors_integ`.`Reports_Parameters` (`Report_ID`, `Param_Name`, `Display_Name`, `Order`, `ParamType`, `Required`, `Length`, `Audit_User`) 
VALUES (@ReportID, 'Dir1', 'Direction of Sort:', '3', 'string', '1', '4', 'kdItitalLoad');
