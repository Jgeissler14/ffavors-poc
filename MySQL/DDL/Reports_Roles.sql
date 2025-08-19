DROP TABLE IF EXISTS `Reports_Roles`;
CREATE TABLE `Reports_Roles` (
  `Site_ID` int NOT NULL,
  `Report_ID` int NOT NULL,
  `Role_ID` varchar(10) NOT NULL,
  `Audit_User` varchar(15) DEFAULT NULL,
  `Trans_Date` datetime DEFAULT (now()),
  PRIMARY KEY (`Site_ID`,`Report_ID`,`Role_ID`),
  KEY `Report_Roles_Report_FK_idx` (`Report_ID`),
  CONSTRAINT `Report_Roles_Report_ID_FK` FOREIGN KEY (`Report_ID`) REFERENCES `Reports` (`Report_ID`),
  CONSTRAINT `Report_Roles_Report_Site_ID_FK` FOREIGN KEY (`Site_ID`) REFERENCES `Sites` (`Site_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
