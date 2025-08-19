DROP TABLE IF EXISTS `Menus`;

CREATE TABLE `Menus` (
  `Menu_ID` int NOT NULL AUTO_INCREMENT,
  `Menu_Name` varchar(20) DEFAULT NULL,
  `Order` int DEFAULT '1',
  `ParentID` int DEFAULT NULL,
  `URL` varchar(250) DEFAULT NULL,
  `HelpText` varchar(2000) DEFAULT NULL,
  `Audit_User` varchar(15) DEFAULT NULL,
  `Trans_Date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Menu_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
