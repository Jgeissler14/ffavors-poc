DROP TABLE IF EXISTS `Reports`;
CREATE TABLE `Reports` (
  `Report_ID` int NOT NULL AUTO_INCREMENT,
  `Report_Name` varchar(20) NOT NULL,
  `Report_Type` varchar(10) DEFAULT NULL,
  `Report_Title` varchar(200) DEFAULT NULL,
  `File_Name` varchar(200) DEFAULT NULL,
  `Data_Source_Type` varchar(45) DEFAULT NULL,
  `Data_Source` varchar(10000) DEFAULT NULL,
  `Trans_Date` datetime DEFAULT CURRENT_TIMESTAMP,
  `Audit_User` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`Report_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
