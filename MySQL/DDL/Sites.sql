Drop table if exists `Sites`;
CREATE TABLE `Sites` (
  `Site_ID` int NOT NULL AUTO_INCREMENT,
  `Site_Name` varchar(10) DEFAULT NULL,
  `Title` varchar(100) DEFAULT NULL,
  `Site_url` varchar(100) DEFAULT NULL,
  `IconPath` varchar(250) DEFAULT NULL,
  `IconWidth` int DEFAULT NULL,
  `Audit_User` varchar(15) DEFAULT NULL,
  `Trans_Date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Site_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
