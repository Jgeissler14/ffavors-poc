DROP TABLE IF EXISTS `Menus_Roles`;

CREATE TABLE `Menus_Roles` (
  `Menu_Roles_ID` int NOT NULL AUTO_INCREMENT,
  `Menu_ID` int DEFAULT NULL,
  `Site_ID` int DEFAULT NULL,
  `Role_ID` varchar(10) DEFAULT NULL,
  `Trans_Date` datetime DEFAULT CURRENT_TIMESTAMP,
  `Audit_User` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`Menu_Roles_ID`),
  KEY `Menu_Roles_Menu_ID_FK_idx` (`Menu_ID`),
  KEY `Menu_Roles_Site_ID_FK_idx` (`Site_ID`),
  CONSTRAINT `Menu_Roles_Menu_ID_FK` FOREIGN KEY (`Menu_ID`) REFERENCES `Menus` (`Menu_ID`),
  CONSTRAINT `Menu_Roles_Site_ID_FK` FOREIGN KEY (`Site_ID`) REFERENCES `Sites` (`Site_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=110 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


/* Roles
01	Produce Vendor
02	Customer
03	State Account Representative 
04	District Account Representative 
05	FNS SNAS
06	DLA TVLS
07	DLA Contracting Specialist
09	DLA Catalog Specialist
10	DLA Finance Specialist
11	FNS View Only
99  Tech-Admin
*/