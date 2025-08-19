DROP TABLE `ffavors_integ`.`Reports_Scheduler`;

CREATE TABLE IF NOT EXISTS `ffavors_integ`.`Reports_Scheduler` (
  `Reports_Sched_ID` INT NOT NULL AUTO_INCREMENT,
  `Report_ID` INT NULL DEFAULT NULL,
  `Param_ID` INT NULL DEFAULT NULL,
  `App_ID` INT NULL DEFAULT NULL,
  `Next_Run_Day` VARCHAR(20) NULL DEFAULT NULL,
  `Requestor` VARCHAR(50) NULL DEFAULT NULL,
  `Next_Run_Date_Time` DATETIME,
  `Last_Run_Date_Time` DATETIME,
  `Auto_Sched` VARCHAR(1) NULL DEFAULT 'Y',
  `TransDate` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Reports_Sched_ID`));


ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci

