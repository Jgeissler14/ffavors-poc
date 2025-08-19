DROP TABLE `ffavors_integ`.`Reports_Sched_Param`;

CREATE TABLE IF NOT EXISTS `ffavors_integ`.`Reports_Sched_Param` (
  `Reports_Sched_Param_ID` INT NOT NULL AUTO_INCREMENT,
  `Report_ID` INT NULL DEFAULT NULL,
  `Param_ID` INT NULL DEFAULT NULL,
  `Param_Value VARCHAR(200) NULL DEFAULT NULL,
  `TransDate` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Reports_Sched_Param_ID`));

ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci