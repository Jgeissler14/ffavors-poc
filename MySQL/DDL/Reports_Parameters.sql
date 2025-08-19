DROP TABLE IF EXISTS `Reports_Parameters`;
CREATE TABLE `Reports_Parameters` (
  `Param_ID` int NOT NULL AUTO_INCREMENT,
  `Report_ID` int NOT NULL,
  `Param_Name` varchar(45) DEFAULT NULL,
  `Display_Name` varchar(45) DEFAULT NULL,
  `Order` int DEFAULT NULL,
  `ParamType` varchar(45) DEFAULT NULL,
  `Required` tinyint DEFAULT NULL,
  `defaultValue` varchar(45) DEFAULT NULL,
  `sample` varchar(100) DEFAULT NULL,
  `ListTable` varchar(100) DEFAULT NULL,
  `ListValues` varchar(300) DEFAULT NULL,
  `minValue` varchar(45) DEFAULT NULL,
  `maxValue` varchar(45) DEFAULT NULL,
  `Length` int DEFAULT NULL,
  `Audit_User` varchar(15) DEFAULT NULL,
  `Trans_Date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Param_ID`),
  KEY `Reports_Param_Report_ID_FK` (`Report_ID`),
  CONSTRAINT `Reports_Param_Report_ID_FK` FOREIGN KEY (`Report_ID`) REFERENCES `Reports` (`Report_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
